import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';

import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { createAdminClient, requireUser } from '../_shared/supabase.ts';

type JsonMap = Record<string, unknown>;

function jsonResponse(payload: JsonMap, status = 200) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  });
}

function slugify(input: string) {
  return input
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

async function assertAdmin(userId: string) {
  const supabase = createAdminClient();
  const { data: profile, error } = await supabase
    .from('profiles')
    .select('role, approval_status')
    .eq('id', userId)
    .single();

  if (error || !profile) {
    throw new Error('Unable to load admin profile.');
  }

  if (
    profile.role !== 'admin' ||
    profile.approval_status !== 'approved'
  ) {
    throw new Error('Admin access is required.');
  }
}

async function countRows(
  supabase: ReturnType<typeof createAdminClient>,
  table: string,
  filter?: (query: any) => any,
) {
  let query = supabase.from(table).select('id', { count: 'exact', head: true });
  if (filter) {
    query = filter(query);
  }
  const { count, error } = await query;
  if (error) {
    throw new Error(error.message);
  }
  return count ?? 0;
}

async function fetchDashboard() {
  const supabase = createAdminClient();

  const [
    totalUsers,
    activeSellers,
    completedDeliveries,
    totalStores,
    pendingApprovals,
    reducedCommissionOrders,
  ] = await Promise.all([
    countRows(supabase, 'profiles'),
    countRows(
      supabase,
      'profiles',
      (query) => query.eq('role', 'seller').eq('approval_status', 'approved'),
    ),
    countRows(
      supabase,
      'deliveries',
      (query) => query.eq('status', 'completed'),
    ),
    countRows(supabase, 'stores'),
    countRows(
      supabase,
      'profiles',
      (query) =>
        query
          .in('role', ['seller', 'rider'])
          .eq('approval_status', 'pending'),
    ),
    countRows(
      supabase,
      'commission_records',
      (query) => query.eq('is_reduced', true),
    ),
  ]);

  const { data: deliveredOrders, error: deliveredOrdersError } = await supabase
    .from('orders')
    .select('id, total_amount, payment_method, payment_status, order_number, status, created_at')
    .eq('status', 'delivered')
    .order('created_at', { ascending: false })
    .limit(6);

  if (deliveredOrdersError) {
    throw new Error(deliveredOrdersError.message);
  }

  const { data: reducedCommissions, error: commissionError } = await supabase
    .from('commission_records')
    .select('amount, is_reduced');

  if (commissionError) {
    throw new Error(commissionError.message);
  }

  const { data: pendingVerifications, error: verificationError } = await supabase
    .from('seller_verification_documents')
    .select('id')
    .eq('verification_status', 'pending');

  if (verificationError) {
    throw new Error(verificationError.message);
  }

  const totalSales = (deliveredOrders ?? []).reduce(
    (sum, order) => sum + Number(order.total_amount ?? 0),
    0,
  );

  const reducedCommissionSavings = (reducedCommissions ?? [])
    .filter((item) => item.is_reduced)
    .reduce((sum, item) => sum + Number(item.amount ?? 0), 0);

  return {
    metrics: {
      total_users: totalUsers,
      active_sellers: activeSellers,
      completed_deliveries: completedDeliveries,
      total_stores: totalStores,
      total_sales: totalSales,
      pending_approvals: pendingApprovals,
      reduced_commission_orders: reducedCommissionOrders,
      estimated_food_saved: reducedCommissionOrders,
      reduced_commission_value: reducedCommissionSavings,
      pending_verifications: pendingVerifications?.length ?? 0,
    },
    recent_orders: deliveredOrders ?? [],
  };
}

async function fetchUsers() {
  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from('profiles')
    .select('id, email, full_name, phone, role, approval_status, created_at')
    .order('created_at', { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  return { users: data ?? [] };
}

async function updateUserStatus(body: JsonMap) {
  const supabase = createAdminClient();
  const userId = body.user_id?.toString();
  const approvalStatus = body.approval_status?.toString();
  const reviewNotes = body.review_notes?.toString() ?? '';

  if (!userId || !approvalStatus) {
    throw new Error('user_id and approval_status are required.');
  }

  const { data: updated, error } = await supabase
    .from('profiles')
    .update({ approval_status: approvalStatus })
    .eq('id', userId)
    .select('id, email, full_name, phone, role, approval_status, created_at')
    .single();

  if (error || !updated) {
    throw new Error(error?.message ?? 'Unable to update user status.');
  }

  await supabase.from('notifications').insert({
    user_id: userId,
    title: 'Account status updated',
    body: reviewNotes.isEmpty
      ? `Your ${updated.role} account is now ${approvalStatus}.`
      : reviewNotes,
    type: 'admin_review',
    metadata: {
      approval_status: approvalStatus,
    },
  });

  return { user: updated };
}

async function fetchVerifications() {
  const supabase = createAdminClient();
  const { data: documents, error } = await supabase
    .from('seller_verification_documents')
    .select(
      'id, seller_id, document_type, file_path, claimed_full_name, claimed_credential_number, extracted_full_name, extracted_credential_number, screening_status, screening_score, screening_notes, verification_status, review_notes, created_at',
    )
    .order('created_at', { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  const sellerIds = [...new Set((documents ?? []).map((item) => item.seller_id))];
  let profileMap = new Map<string, { full_name: string; email: string; role: string }>();

  if (sellerIds.length > 0) {
    const { data: profiles, error: profileError } = await supabase
      .from('profiles')
      .select('id, full_name, email, role')
      .in('id', sellerIds);

    if (profileError) {
      throw new Error(profileError.message);
    }

    profileMap = new Map(
      (profiles ?? []).map((profile) => [
        profile.id as string,
        {
          full_name: (profile.full_name as string | null) ?? '',
          email: (profile.email as string | null) ?? '',
          role: (profile.role as string | null) ?? '',
        },
      ]),
    );
  }

  return {
    verifications: (documents ?? []).map((document) => ({
      ...document,
      seller_name: profileMap.get(document.seller_id)?.full_name ?? 'Unknown seller',
      seller_email: profileMap.get(document.seller_id)?.email ?? '',
      seller_role: profileMap.get(document.seller_id)?.role ?? '',
    })),
  };
}

async function reviewVerification(body: JsonMap) {
  const supabase = createAdminClient();
  const documentId = body.document_id?.toString();
  const verificationStatus = body.verification_status?.toString();
  const reviewNotes = body.review_notes?.toString() ?? '';

  if (!documentId || !verificationStatus) {
    throw new Error('document_id and verification_status are required.');
  }

  const { data: document, error: fetchError } = await supabase
    .from('seller_verification_documents')
    .select('id, seller_id, document_type')
    .eq('id', documentId)
    .single();

  if (fetchError || !document) {
    throw new Error(fetchError?.message ?? 'Unable to load verification record.');
  }

  const { data: updated, error } = await supabase
    .from('seller_verification_documents')
    .update({
      verification_status: verificationStatus,
      review_notes: reviewNotes,
    })
    .eq('id', documentId)
    .select(
      'id, seller_id, document_type, file_path, claimed_full_name, claimed_credential_number, extracted_full_name, extracted_credential_number, screening_status, screening_score, screening_notes, verification_status, review_notes, created_at',
    )
    .single();

  if (error || !updated) {
    throw new Error(error?.message ?? 'Unable to update verification.');
  }

  await supabase
    .from('profiles')
    .update({ approval_status: verificationStatus })
    .eq('id', document.seller_id);

  await supabase.from('notifications').insert({
    user_id: document.seller_id,
    title: 'Verification reviewed',
    body: reviewNotes.isEmpty
      ? `Your ${document.document_type.replaceAll('_', ' ')} review is now ${verificationStatus}.`
      : reviewNotes,
    type: 'verification',
    metadata: {
      verification_status: verificationStatus,
      document_id: documentId,
    },
  });

  return { verification: updated };
}

async function fetchCategories() {
  const supabase = createAdminClient();
  const { data, error } = await supabase
    .from('categories')
    .select('id, name, slug, description, is_active, sort_order, created_at, updated_at')
    .order('sort_order')
    .order('name');

  if (error) {
    throw new Error(error.message);
  }

  return { categories: data ?? [] };
}

async function saveCategory(body: JsonMap) {
  const supabase = createAdminClient();
  const categoryId = body.id?.toString();
  const name = body.name?.toString().trim();
  const description = body.description?.toString().trim() ?? '';
  const isActive = body.is_active == null ? true : body.is_active == true;
  const sortOrder = Number.parseInt(body.sort_order?.toString() ?? '0', 10) || 0;

  if (name == null || name.isEmpty) {
    throw new Error('Category name is required.');
  }

  const payload = {
    if (categoryId != null && categoryId.isNotEmpty) 'id': categoryId,
    'name': name,
    'slug': slugify(name),
    'description': description,
    'is_active': isActive,
    'sort_order': sortOrder,
  };

  const result = categoryId == null || categoryId.isEmpty
      ? await supabase
          .from('categories')
          .insert(payload)
          .select('id, name, slug, description, is_active, sort_order, created_at, updated_at')
          .single()
      : await supabase
          .from('categories')
          .update(payload)
          .eq('id', categoryId)
          .select('id, name, slug, description, is_active, sort_order, created_at, updated_at')
          .single();

  if (result.error || result.data == null) {
    throw new Error(result.error?.message ?? 'Unable to save category.');
  }

  return { category: result.data };
}

async function toggleCategory(body: JsonMap) {
  const supabase = createAdminClient();
  const categoryId = body.id?.toString();
  const isActive = body.is_active == true;

  if (categoryId == null || categoryId.isEmpty) {
    throw new Error('Category id is required.');
  }

  const { data, error } = await supabase
    .from('categories')
    .update({ is_active: isActive })
    .eq('id', categoryId)
    .select('id, name, slug, description, is_active, sort_order, created_at, updated_at')
    .single();

  if (error || !data) {
    throw new Error(error?.message ?? 'Unable to update category.');
  }

  return { category: data };
}

serve(async (request) => {
  const corsResponse = handleCors(request);
  if (corsResponse) {
    return corsResponse;
  }

  try {
    const user = await requireUser(request);
    await assertAdmin(user.id);

    const body: JsonMap = request.method == 'GET' ? {} : await request.json();
    const action = body.action?.toString() ?? 'dashboard';

    switch (action) {
      case 'dashboard':
        return jsonResponse(await fetchDashboard());
      case 'list_users':
        return jsonResponse(await fetchUsers());
      case 'update_user_status':
        return jsonResponse(await updateUserStatus(body));
      case 'list_verifications':
        return jsonResponse(await fetchVerifications());
      case 'review_verification':
        return jsonResponse(await reviewVerification(body));
      case 'list_categories':
        return jsonResponse(await fetchCategories());
      case 'save_category':
        return jsonResponse(await saveCategory(body));
      case 'toggle_category':
        return jsonResponse(await toggleCategory(body));
      default:
        throw new Error(`Unsupported action: ${action}`);
    }
  } catch (error) {
    return jsonResponse(
      {
        error: error instanceof Error ? error.message : 'Unknown admin error.',
      },
      400,
    );
  }
});
