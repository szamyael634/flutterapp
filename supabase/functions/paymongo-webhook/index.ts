import { createHmac, timingSafeEqual } from 'node:crypto';
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { createAdminClient } from '../_shared/supabase.ts';

function parseSignature(header: string) {
  const entries = header.split(',').map((part) => part.trim());
  const values = new Map<string, string>();

  for (const entry of entries) {
    const [key, value] = entry.split('=');
    if (key && value) {
      values.set(key, value);
    }
  }

  return values;
}

function verifySignature(
  rawBody: string,
  signatureHeader: string,
  secret: string,
): boolean {
  const parsed = parseSignature(signatureHeader);
  const timestamp = parsed.get('t');
  const testSignature = parsed.get('te');
  const liveSignature = parsed.get('li');

  if (!timestamp) {
    return false;
  }

  const expected = createHmac('sha256', secret)
    .update(`${timestamp}.${rawBody}`)
    .digest('hex');

  const provided = liveSignature && liveSignature.length > 0
    ? liveSignature
    : testSignature ?? '';

  if (expected.length !== provided.length) {
    return false;
  }

  return timingSafeEqual(
    new TextEncoder().encode(expected),
    new TextEncoder().encode(provided),
  );
}

serve(async (request) => {
  const corsResponse = handleCors(request);
  if (corsResponse) {
    return corsResponse;
  }

  try {
    const rawBody = await request.text();
    const signatureHeader = request.headers.get('Paymongo-Signature');
    const webhookSecret = Deno.env.get('PAYMONGO_WEBHOOK_SECRET');

    if (!signatureHeader || !webhookSecret) {
      throw new Error('Missing PayMongo webhook signature configuration.');
    }

    if (!verifySignature(rawBody, signatureHeader, webhookSecret)) {
      throw new Error('Invalid PayMongo webhook signature.');
    }

    const payload = JSON.parse(rawBody);
    const supabase = createAdminClient();

    const eventType = payload?.data?.attributes?.type as string | undefined;
    const eventData = payload?.data?.attributes?.data ?? {};
    const metadata = eventData?.attributes?.metadata ?? {};
    const orderId = metadata.order_id as string | undefined;
    const paymentReference =
      eventData?.id as string | undefined ?? payload?.data?.id as string | undefined;

    if (!orderId) {
      throw new Error('Webhook payload is missing metadata.order_id.');
    }

    if (eventType === 'checkout_session.payment.paid' || eventType === 'payment.paid') {
      await supabase
        .from('payments')
        .update({
          status: 'paid',
          provider_reference: paymentReference,
          payload,
          paid_at: new Date().toISOString(),
        })
        .eq('order_id', orderId);

      await supabase
        .from('orders')
        .update({
          status: 'placed',
          payment_status: 'paid',
        })
        .eq('id', orderId);

      await supabase.from('order_status_history').insert({
        order_id: orderId,
        status: 'placed',
        notes: 'PayMongo webhook marked this order as paid.',
      });
    } else if (
      eventType === 'checkout_session.payment.failed' ||
      eventType === 'payment.failed'
    ) {
      await supabase
        .from('payments')
        .update({
          status: 'failed',
          provider_reference: paymentReference,
          payload,
        })
        .eq('order_id', orderId);

      await supabase
        .from('orders')
        .update({
          payment_status: 'failed',
        })
        .eq('id', orderId);
    }

    return new Response(
      JSON.stringify({ ok: true }),
      {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Unknown webhook error.',
      }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      },
    );
  }
});
