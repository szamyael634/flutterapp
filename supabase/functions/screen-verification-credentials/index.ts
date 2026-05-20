import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { createAdminClient, requireUser } from '../_shared/supabase.ts';

function serializeValue(value: unknown): string {
  if (Array.isArray(value)) {
    return `[${value.map(serializeValue).join(', ')}]`;
  }

  if (value && typeof value === 'object') {
    return `{${Object.entries(value as Record<string, unknown>)
      .map(([key, nested]) => `${key}: ${serializeValue(nested)}`)
      .join(', ')}}`;
  }

  return JSON.stringify(value);
}

async function createVeryfiSignature(
  clientSecret: string,
  payload: Record<string, unknown>,
  timestamp: number,
): Promise<string> {
  const payloadString = [
    `timestamp:${timestamp}`,
    ...Object.entries(payload).map(
      ([key, value]) => `${key}:${serializeValue(value)}`,
    ),
  ].join(',');

  const key = new TextEncoder().encode(clientSecret);
  const message = new TextEncoder().encode(payloadString);
  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    key,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('HMAC', cryptoKey, message);
  const bytes = new Uint8Array(signature);

  let binary = '';
  for (const currentByte of bytes) {
    binary += String.fromCharCode(currentByte);
  }

  return btoa(binary);
}

function normalize(value: string | null | undefined): string {
  return (value ?? '').toLowerCase().replace(/[^a-z0-9]/g, '');
}

function walkStrings(value: unknown, collector: string[]) {
  if (value == null) {
    return;
  }

  if (typeof value === 'string' || typeof value === 'number') {
    collector.push(String(value));
    return;
  }

  if (Array.isArray(value)) {
    for (const entry of value) {
      walkStrings(entry, collector);
    }
    return;
  }

  if (typeof value === 'object') {
    for (const entry of Object.values(value as Record<string, unknown>)) {
      walkStrings(entry, collector);
    }
  }
}

function collectCandidateStrings(payload: Record<string, unknown>): string[] {
  const values: string[] = [];
  walkStrings(payload, values);
  return values;
}

function pickPreferredString(
  payload: Record<string, unknown>,
  keys: string[],
): string | null {
  for (const key of keys) {
    const value = payload[key];
    if (typeof value === 'string' && value.trim().length > 0) {
      return value.trim();
    }
  }

  return null;
}

function compareScreening(
  payload: Record<string, unknown>,
  claimedFullName: string,
  claimedCredentialNumber: string,
) {
  const allText = collectCandidateStrings(payload).map(normalize).join(' ');
  const normalizedName = normalize(claimedFullName);
  const normalizedCredential = normalize(claimedCredentialNumber);

  const nameMatched =
    normalizedName.length === 0 || allText.includes(normalizedName);
  const credentialMatched =
    normalizedCredential.length === 0 ||
    allText.includes(normalizedCredential);

  const extractedFullName = pickPreferredString(payload, [
    'bill_to_name',
    'customer_name',
    'name',
    'vendor_name',
    'document_title',
  ]);
  const extractedCredentialNumber = pickPreferredString(payload, [
    'document_reference_number',
    'invoice_number',
    'account_number',
    'card_number',
    'abn_number',
  ]);

  let screeningStatus = 'mismatch';
  let screeningScore = 0;
  let screeningNotes =
    'Unable to match the claimed credential fields with the uploaded document.';

  if (nameMatched && credentialMatched) {
    screeningStatus = 'matched';
    screeningScore = 100;
    screeningNotes =
      'Veryfi OCR matched the claimed holder name and credential number.';
  } else if (nameMatched || credentialMatched) {
    screeningStatus = 'partial_match';
    screeningScore = 60;
    screeningNotes =
      'Veryfi OCR matched part of the claimed credential data. Manual review is recommended.';
  }

  return {
    screening_status: screeningStatus,
    screening_score: screeningScore,
    screening_notes: screeningNotes,
    name_matched: nameMatched,
    credential_matched: credentialMatched,
    extracted_full_name: extractedFullName,
    extracted_credential_number: extractedCredentialNumber,
  };
}

serve(async (request) => {
  const corsResponse = handleCors(request);
  if (corsResponse) {
    return corsResponse;
  }

  try {
    const user = await requireUser(request);
    const supabase = createAdminClient();
    const body = await request.json();

    const filePath = (body.file_path as string | undefined)?.trim();
    const requestedDocumentType =
      (body.document_type as string | undefined)?.trim() ?? '';
    const documentType =
      requestedDocumentType.length > 0 ? requestedDocumentType : 'government_id';
    const claimedFullName =
      (body.claimed_full_name as string | undefined)?.trim() ?? '';
    const claimedCredentialNumber =
      (body.claimed_credential_number as string | undefined)?.trim() ?? '';

    if (!filePath) {
      throw new Error('file_path is required.');
    }

    const signedUrlResult = await supabase.storage
      .from('verification-documents')
      .createSignedUrl(filePath, 60 * 10);

    if (signedUrlResult.error || !signedUrlResult.data) {
      throw new Error(
        signedUrlResult.error?.message ?? 'Unable to sign document URL.',
      );
    }

    const veryfiPayload: Record<string, unknown> = {
      file_url: signedUrlResult.data.signedUrl,
      file_name: filePath.split('/').pop() ?? 'document',
      external_id: user.id,
      categories: [documentType],
    };

    const clientId = Deno.env.get('VERYFI_CLIENT_ID');
    const username = Deno.env.get('VERYFI_USERNAME');
    const apiKey = Deno.env.get('VERYFI_API_KEY');
    const clientSecret = Deno.env.get('VERYFI_CLIENT_SECRET');

    if (!clientId || !username || !apiKey || !clientSecret) {
      throw new Error(
        'Missing Veryfi secrets in Supabase Edge Function environment.',
      );
    }

    const timestamp = Date.now();
    const signature = await createVeryfiSignature(
      clientSecret,
      veryfiPayload,
      timestamp,
    );

    const veryfiResponse = await fetch(
      'https://api.veryfi.com/api/v8/partner/documents',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
          'CLIENT-ID': clientId,
          'AUTHORIZATION': `apikey ${username}:${apiKey}`,
          'X-VERYFI-REQUEST-TIMESTAMP': timestamp.toString(),
          'X-VERYFI-REQUEST-SIGNATURE': signature,
        },
        body: JSON.stringify(veryfiPayload),
      },
    );

    const veryfiData = await veryfiResponse.json();
    if (!veryfiResponse.ok) {
      throw new Error(
        veryfiData?.message?.toString() ??
          veryfiData?.detail?.toString() ??
          'Veryfi request failed.',
      );
    }

    const payload =
      typeof veryfiData?.data === 'object' && veryfiData.data !== null
        ? (veryfiData.data as Record<string, unknown>)
        : (veryfiData as Record<string, unknown>);

    const comparison = compareScreening(
      payload,
      claimedFullName,
      claimedCredentialNumber,
    );
    const verificationStatus =
      comparison.screening_status === 'matched' ? 'approved' : 'pending';

    const insertResult = await supabase
      .from('seller_verification_documents')
      .insert({
        seller_id: user.id,
        document_type: documentType,
        file_path: filePath,
        claimed_full_name: claimedFullName,
        claimed_credential_number: claimedCredentialNumber,
        extracted_full_name: comparison.extracted_full_name,
        extracted_credential_number: comparison.extracted_credential_number,
        extracted_payload: payload,
        screening_status: comparison.screening_status,
        screening_score: comparison.screening_score,
        screening_notes: comparison.screening_notes,
        veryfi_document_id:
          payload.id == null ? null : String(payload.id),
        screened_at: new Date().toISOString(),
        verification_status: verificationStatus,
      })
      .select()
      .single();

    if (insertResult.error || !insertResult.data) {
      throw new Error(
        insertResult.error?.message ??
          'Unable to save verification screening result.',
      );
    }

    await supabase.from('notifications').insert({
      user_id: user.id,
      title: 'Credential screening completed',
      body: comparison.screening_notes,
      type: 'credential_screening',
      metadata: {
        document_id: insertResult.data.id,
        screening_status: comparison.screening_status,
      },
    });

    return new Response(
      JSON.stringify({
        verification_document_id: insertResult.data.id,
        ...comparison,
      }),
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
        error: error instanceof Error ? error.message : String(error),
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
