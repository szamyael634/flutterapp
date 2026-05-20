import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { createAdminClient } from '../_shared/supabase.ts';

serve(async (request) => {
  const corsResponse = handleCors(request);
  if (corsResponse) {
    return corsResponse;
  }

  try {
    const supabase = createAdminClient();
    const { data: expiredCount, error: expireError } = await supabase.rpc(
      'disable_expired_products',
    );

    if (expireError) {
      throw new Error(expireError.message);
    }

    const { data: refreshedCount, error: refreshError } = await supabase.rpc(
      'refresh_all_product_recommendations',
    );

    if (refreshError) {
      throw new Error(refreshError.message);
    }

    return new Response(
      JSON.stringify({
        expired_count: expiredCount,
        refreshed_count: refreshedCount,
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
        error: error instanceof Error ? error.message : 'Unknown expiration error.',
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
