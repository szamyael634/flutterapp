import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { createAdminClient, requireUser } from '../_shared/supabase.ts';

type CheckoutItem = {
  product_id: string;
  quantity: number;
};

serve(async (request) => {
  const corsResponse = handleCors(request);
  if (corsResponse) {
    return corsResponse;
  }

  try {
    const user = await requireUser(request);
    const supabase = createAdminClient();
    const body = await request.json();

    const buyerId = body.buyer_id as string;
    const paymentMethod = (body.payment_method as string | undefined) ?? 'cod';
    const deliveryAddress = (body.delivery_address as string | undefined) ?? '';
    const notes = (body.notes as string | undefined) ?? null;
    const items = (body.items as CheckoutItem[] | undefined) ?? [];

    if (buyerId !== user.id) {
      throw new Error('Buyer mismatch.');
    }

    if (items.isEmpty) {
      throw new Error('Cart is empty.');
    }

    const productIds = items.map((item) => item.product_id);
    const { data: products, error: productError } = await supabase
      .from('products')
      .select('id, store_id, name, quantity, current_price, listing_status, discount_percent')
      .in('id', productIds);

    if (productError || !products || products.length != items.length) {
      throw new Error(productError?.message ?? 'Unable to load products.');
    }

    const storeIds = [...new Set(products.map((product) => product.store_id))];
    if (storeIds.length != 1) {
      throw new Error('MVP checkout only supports one store per order.');
    }

    let subtotal = 0;
    const lineItems = items.map((item) => {
      const product = products.find((entry) => entry.id === item.product_id);
      if (!product) {
        throw new Error(`Product ${item.product_id} was not found.`);
      }

      if (!['active', 'near_expiry', 'flash_sale'].includes(product.listing_status)) {
        throw new Error(`${product.name} is no longer available.`);
      }

      if (product.quantity < item.quantity) {
        throw new Error(`${product.name} does not have enough stock.`);
      }

      const total = Number(product.current_price) * item.quantity;
      subtotal += total;

      return {
        product,
        quantity: item.quantity,
        unit_price: Number(product.current_price).toFixed(2),
        total_price: total.toFixed(2),
      };
    });

    const storeId = storeIds[0];
    const deliveryFee = subtotal >= 500 ? 0 : 49;
    const totalAmount = subtotal + deliveryFee;

    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert({
        buyer_id: buyerId,
        store_id: storeId,
        total_amount: totalAmount.toFixed(2),
        delivery_fee: deliveryFee.toFixed(2),
        status: paymentMethod === 'cod' ? 'placed' : 'pending_payment',
        payment_method: paymentMethod,
        payment_status: paymentMethod === 'cod' ? 'pending' : 'awaiting_payment',
        delivery_address: deliveryAddress,
        notes,
      })
      .select()
      .single();

    if (orderError || !order) {
      throw new Error(orderError?.message ?? 'Unable to create order.');
    }

    const orderItemsPayload = lineItems.map((item) => ({
      order_id: order.id,
      product_id: item.product.id,
      quantity: item.quantity,
      unit_price: item.unit_price,
      total_price: item.total_price,
    }));

    const { error: itemError } = await supabase
      .from('order_items')
      .insert(orderItemsPayload);

    if (itemError) {
      throw new Error(itemError.message);
    }

    await supabase.from('order_status_history').insert({
      order_id: order.id,
      status: order.status,
      notes: paymentMethod === 'cod'
        ? 'Order placed with cash on delivery.'
        : 'Order is awaiting PayMongo payment completion.',
    });

    const { data: store } = await supabase
      .from('stores')
      .select('address')
      .eq('id', storeId)
      .single();

    await supabase.from('deliveries').insert({
      order_id: order.id,
      pickup_address: store?.address ?? 'Seller store address unavailable',
      dropoff_address: deliveryAddress,
      status: 'unassigned',
    });

    for (const item of lineItems) {
      await supabase
        .from('products')
        .update({ quantity: item.product.quantity - item.quantity })
        .eq('id', item.product.id);

      await supabase.rpc('sync_product_recommendation', {
        p_product_id: item.product.id,
      });
    }

    await supabase
      .from('cart_items')
      .delete()
      .eq('buyer_id', buyerId)
      .in('product_id', productIds);

    const commissionRate =
      paymentMethod === 'cod'
        ? Number(
            (
              await supabase.rpc('calculate_commission_rate', {
                p_listing_status: products[0].listing_status,
                p_discount_percent: products[0].discount_percent,
                p_recommendation_accepted: products[0].discount_percent > 0,
              })
            ).data ?? 10,
          )
        : 10;
    const commissionAmount = Number(((subtotal * commissionRate) / 100).toFixed(2));

    await supabase.from('commission_records').insert({
      order_id: order.id,
      store_id: storeId,
      base_rate: 10,
      applied_rate: commissionRate,
      amount: commissionAmount,
      is_reduced: commissionRate < 10,
      reason: commissionRate < 10 ? 'near_expiry_discount' : 'standard',
    });

    let checkoutUrl: string | null = null;
    let paymentReference: string | null = null;
    let paymentStatus = paymentMethod === 'cod' ? 'pending' : 'awaiting_payment';
    let paymentPayload: Record<string, unknown> = {};

    if (paymentMethod === 'paymongo') {
      const payMongoSecretKey = Deno.env.get('PAYMONGO_SECRET_KEY');
      const appBaseUrl =
        Deno.env.get('APP_BASE_URL') ?? 'https://example.com/payment-result';

      if (!payMongoSecretKey) {
        throw new Error('Missing PAYMONGO_SECRET_KEY secret.');
      }

      const authToken = btoa(`${payMongoSecretKey}:`);
      const payMongoResponse = await fetch(
        'https://api.paymongo.com/v1/checkout_sessions',
        {
          method: 'POST',
          headers: {
            Authorization: `Basic ${authToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            data: {
              attributes: {
                send_email_receipt: true,
                show_description: true,
                show_line_items: true,
                description: `Mama's Kitchen order ${order.order_number}`,
                line_items: lineItems.map((item) => ({
                  currency: 'PHP',
                  amount: Math.round(Number(item.unit_price) * 100),
                  name: item.product.name,
                  quantity: item.quantity,
                })),
                payment_method_types: ['gcash', 'maya', 'card'],
                success_url: `${appBaseUrl}?order=${order.id}&status=success`,
                cancel_url: `${appBaseUrl}?order=${order.id}&status=cancelled`,
                metadata: {
                  order_id: order.id,
                  buyer_id: buyerId,
                },
              },
            },
          }),
        },
      );

      const payMongoData = await payMongoResponse.json();
      if (!payMongoResponse.ok) {
        throw new Error(
          payMongoData?.errors?.[0]?.detail ??
            'Unable to create PayMongo checkout session.',
        );
      }

      checkoutUrl =
        payMongoData.data.attributes.checkout_url ?? null;
      paymentReference = payMongoData.data.id ?? null;
      paymentStatus = 'awaiting_payment';
      paymentPayload = payMongoData;
    }

    await supabase.from('payments').insert({
      order_id: order.id,
      provider: paymentMethod === 'paymongo' ? 'paymongo' : 'cod',
      provider_reference: paymentReference,
      payment_method: paymentMethod,
      amount: totalAmount.toFixed(2),
      status: paymentStatus,
      checkout_url: checkoutUrl,
      payload: paymentPayload,
    });

    await supabase.from('notifications').insert([
      {
        user_id: buyerId,
        title: 'Order created',
        body:
          paymentMethod === 'cod'
            ? `Your order ${order.order_number} has been placed.`
            : `Your order ${order.order_number} is awaiting PayMongo payment.`,
        type: 'order',
        metadata: { order_id: order.id },
      },
    ]);

    return new Response(
      JSON.stringify({
        order_id: order.id,
        payment_method: paymentMethod,
        checkout_url: checkoutUrl,
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
        error: error instanceof Error ? error.message : 'Unknown checkout error.',
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
