import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { createAdminClient, requireUser } from '../_shared/supabase.ts';

serve(async (request) => {
  const corsResponse = handleCors(request);
  if (corsResponse) {
    return corsResponse;
  }

  try {
    const user = await requireUser(request);
    const supabase = createAdminClient();
    const body = await request.json();

    const recommendationId = body.recommendation_id as string | undefined;
    const productId = body.product_id as string | undefined;
    const action = (body.action as string | undefined) ?? 'refresh';

    if (action === 'accept') {
      if (!recommendationId) {
        throw new Error('recommendation_id is required for accept.');
      }

      const { error } = await supabase.rpc('accept_product_recommendation', {
        p_recommendation_id: recommendationId,
        p_actor_id: user.id,
      });

      if (error) {
        throw new Error(error.message);
      }

      return new Response(
        JSON.stringify({ ok: true, mode: 'accept' }),
        {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        },
      );
    }

    if (!productId) {
      const { data, error } = await supabase.rpc(
        'refresh_all_product_recommendations',
      );
      if (error) {
        throw new Error(error.message);
      }

      return new Response(
        JSON.stringify({ ok: true, refreshed: data }),
        {
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
          },
        },
      );
    }

    const { error } = await supabase.rpc('sync_product_recommendation', {
      p_product_id: productId,
    });

    if (error) {
      throw new Error(error.message);
    }

    return new Response(
      JSON.stringify({ ok: true, product_id: productId }),
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
        error:
          error instanceof Error
            ? error.message
            : 'Unknown recommendation error.',
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
