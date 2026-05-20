create extension if not exists pgcrypto;

create schema if not exists app_private;
revoke all on schema app_private from public;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'app_role') then
    create type public.app_role as enum ('buyer', 'seller', 'rider', 'admin');
  end if;

  if not exists (select 1 from pg_type where typname = 'approval_status') then
    create type public.approval_status as enum ('pending', 'approved', 'rejected', 'suspended');
  end if;

  if not exists (select 1 from pg_type where typname = 'product_listing_status') then
    create type public.product_listing_status as enum (
      'draft',
      'active',
      'near_expiry',
      'flash_sale',
      'expired',
      'disabled'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'order_status') then
    create type public.order_status as enum (
      'pending_payment',
      'placed',
      'seller_confirmed',
      'preparing',
      'ready_for_pickup',
      'out_for_delivery',
      'delivered',
      'cancelled',
      'refunded'
    );
  end if;

  if not exists (select 1 from pg_type where typname = 'delivery_status') then
    create type public.delivery_status as enum (
      'unassigned',
      'assigned',
      'picked_up',
      'near_dropoff',
      'completed',
      'failed'
    );
  end if;
end $$;

create or replace function app_private.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text not null default '',
  phone text,
  role public.app_role not null default 'buyer',
  approval_status public.approval_status not null default 'pending',
  avatar_url text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references public.profiles(id) on delete cascade,
  name text not null,
  description text not null default '',
  address text not null default '',
  is_open boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.seller_verification_documents (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete cascade,
  document_type text not null,
  file_path text not null,
  claimed_full_name text,
  claimed_credential_number text,
  extracted_full_name text,
  extracted_credential_number text,
  extracted_payload jsonb not null default '{}'::jsonb,
  screening_status text not null default 'pending',
  screening_score numeric(5,2),
  screening_notes text,
  veryfi_document_id text,
  screened_at timestamptz,
  verification_status public.approval_status not null default 'pending',
  review_notes text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null,
  description text not null default '',
  category text not null,
  original_price numeric(10,2) not null check (original_price >= 0),
  current_price numeric(10,2) not null check (current_price >= 0),
  quantity integer not null check (quantity >= 0),
  prepared_at timestamptz not null,
  expiration_at timestamptz not null,
  discount_percent integer not null default 0 check (discount_percent between 0 and 100),
  listing_status public.product_listing_status not null default 'draft',
  recommendation_status text not null default 'none',
  allergens text[] not null default '{}',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  image_url text not null,
  is_primary boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.product_recommendations (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null unique references public.products(id) on delete cascade,
  status text not null default 'none',
  suggested_discount_percent integer not null default 0,
  message text not null default '',
  apply_reduced_commission boolean not null default false,
  accepted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity integer not null default 1 check (quantity > 0),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (buyer_id, product_id)
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique default ('MK-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10))),
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete restrict,
  total_amount numeric(10,2) not null check (total_amount >= 0),
  delivery_fee numeric(10,2) not null default 0 check (delivery_fee >= 0),
  status public.order_status not null default 'pending_payment',
  payment_method text not null,
  payment_status text not null default 'pending',
  delivery_address text not null,
  notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  quantity integer not null check (quantity > 0),
  unit_price numeric(10,2) not null check (unit_price >= 0),
  total_price numeric(10,2) not null check (total_price >= 0),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  status public.order_status not null,
  notes text,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  provider text not null default 'paymongo',
  provider_reference text,
  payment_method text not null,
  amount numeric(10,2) not null check (amount >= 0),
  status text not null default 'pending',
  checkout_url text,
  payload jsonb not null default '{}'::jsonb,
  paid_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.deliveries (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  rider_id uuid references public.profiles(id) on delete set null,
  status public.delivery_status not null default 'unassigned',
  pickup_address text not null,
  dropoff_address text not null,
  eta_minutes integer,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null,
  target_id uuid not null,
  rating integer not null check (rating between 1 and 5),
  comment text,
  photo_urls text[] not null default '{}',
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null default 'system',
  metadata jsonb not null default '{}'::jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.commission_records (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  base_rate numeric(5,2) not null default 10.00,
  applied_rate numeric(5,2) not null,
  amount numeric(10,2) not null,
  is_reduced boolean not null default false,
  reason text not null default 'standard',
  created_at timestamptz not null default timezone('utc', now())
);

create or replace function app_private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  desired_role public.app_role;
  desired_status public.approval_status;
begin
  desired_role := coalesce((new.raw_user_meta_data ->> 'role')::public.app_role, 'buyer');
  desired_status := case
    when desired_role = 'buyer' then 'approved'::public.approval_status
    else 'pending'::public.approval_status
  end;

  insert into public.profiles (
    id,
    email,
    full_name,
    phone,
    role,
    approval_status
  )
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.raw_user_meta_data ->> 'phone',
    desired_role,
    desired_status
  )
  on conflict (id) do update
  set
    email = excluded.email,
    full_name = excluded.full_name,
    phone = excluded.phone,
    role = excluded.role,
    approval_status = excluded.approval_status,
    updated_at = timezone('utc', now());

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure app_private.handle_new_user();

create or replace function public.calculate_commission_rate(
  p_listing_status public.product_listing_status,
  p_discount_percent integer,
  p_recommendation_accepted boolean
)
returns numeric
language plpgsql
as $$
begin
  if p_recommendation_accepted and p_listing_status = 'flash_sale' then
    return 2.00;
  end if;

  if p_recommendation_accepted and p_listing_status = 'near_expiry' and p_discount_percent > 0 then
    return 5.00;
  end if;

  return 10.00;
end;
$$;

create or replace function public.product_recommendation_snapshot(
  p_expiration_at timestamptz
)
returns table (
  status text,
  suggested_discount_percent integer,
  message text,
  listing_status public.product_listing_status,
  apply_reduced_commission boolean
)
language plpgsql
as $$
declare
  hours_left numeric;
begin
  hours_left := extract(epoch from (p_expiration_at - timezone('utc', now()))) / 3600;

  if hours_left <= 0 then
    return query
    select
      'expired',
      0,
      'This product has expired and will be disabled automatically.',
      'expired'::public.product_listing_status,
      false;
  elsif hours_left <= 24 then
    return query
    select
      'flash_sale',
      30,
      'Product expires within 24 hours. Recommend a 30% flash sale and 2% commission.',
      'flash_sale'::public.product_listing_status,
      true;
  elsif hours_left <= 48 then
    return query
    select
      'near_expiry',
      20,
      'Product expires within 48 hours. Recommend a 20% discount and 5% commission.',
      'near_expiry'::public.product_listing_status,
      true;
  elsif hours_left <= 72 then
    return query
    select
      'near_expiry',
      10,
      'Product expires within 72 hours. Recommend a 10% discount and 5% commission.',
      'near_expiry'::public.product_listing_status,
      true;
  else
    return query
    select
      'none',
      0,
      'Product is outside the near-expiry window.',
      'active'::public.product_listing_status,
      false;
  end if;
end;
$$;

create or replace function public.sync_product_recommendation(p_product_id uuid)
returns void
language plpgsql
as $$
declare
  product_row public.products%rowtype;
  recommendation record;
begin
  select *
  into product_row
  from public.products
  where id = p_product_id;

  if not found then
    raise exception 'Product % not found', p_product_id;
  end if;

  select *
  into recommendation
  from public.product_recommendation_snapshot(product_row.expiration_at);

  update public.products
  set
    listing_status = case
      when recommendation.listing_status = 'expired' then 'expired'
      when product_row.listing_status = 'disabled' then 'disabled'
      else recommendation.listing_status
    end,
    recommendation_status = recommendation.status,
    updated_at = timezone('utc', now())
  where id = p_product_id;

  insert into public.product_recommendations (
    product_id,
    status,
    suggested_discount_percent,
    message,
    apply_reduced_commission,
    updated_at
  )
  values (
    p_product_id,
    recommendation.status,
    recommendation.suggested_discount_percent,
    recommendation.message,
    recommendation.apply_reduced_commission,
    timezone('utc', now())
  )
  on conflict (product_id) do update
  set
    status = excluded.status,
    suggested_discount_percent = excluded.suggested_discount_percent,
    message = excluded.message,
    apply_reduced_commission = excluded.apply_reduced_commission,
    updated_at = timezone('utc', now());
end;
$$;

create or replace function public.accept_product_recommendation(
  p_recommendation_id uuid,
  p_actor_id uuid
)
returns void
language plpgsql
as $$
declare
  recommendation_row public.product_recommendations%rowtype;
  product_row public.products%rowtype;
  store_owner uuid;
  new_price numeric(10,2);
begin
  select *
  into recommendation_row
  from public.product_recommendations
  where id = p_recommendation_id;

  if not found then
    raise exception 'Recommendation % not found', p_recommendation_id;
  end if;

  select *
  into product_row
  from public.products
  where id = recommendation_row.product_id;

  select owner_id
  into store_owner
  from public.stores
  where id = product_row.store_id;

  if store_owner is distinct from p_actor_id then
    raise exception 'Only the store owner can accept recommendations';
  end if;

  new_price := round((product_row.original_price * (100 - recommendation_row.suggested_discount_percent)) / 100.0, 2);

  update public.products
  set
    current_price = new_price,
    discount_percent = recommendation_row.suggested_discount_percent,
    listing_status = case
      when recommendation_row.status = 'flash_sale' then 'flash_sale'
      when recommendation_row.status = 'near_expiry' then 'near_expiry'
      else listing_status
    end,
    recommendation_status = recommendation_row.status,
    updated_at = timezone('utc', now())
  where id = product_row.id;

  update public.product_recommendations
  set
    accepted_at = timezone('utc', now()),
    updated_at = timezone('utc', now())
  where id = p_recommendation_id;

  insert into public.notifications (user_id, title, body, type)
  values (
    p_actor_id,
    'Recommendation applied',
    format('Discount applied to %s at %s%% off.', product_row.name, recommendation_row.suggested_discount_percent),
    'seller_recommendation'
  );
end;
$$;

create or replace function public.disable_expired_products()
returns integer
language plpgsql
as $$
declare
  affected_count integer;
begin
  update public.products
  set
    listing_status = 'expired',
    updated_at = timezone('utc', now())
  where expiration_at <= timezone('utc', now())
    and listing_status <> 'disabled';

  get diagnostics affected_count = row_count;

  update public.products
  set quantity = 0
  where expiration_at <= timezone('utc', now());

  return affected_count;
end;
$$;

create or replace function public.refresh_all_product_recommendations()
returns integer
language plpgsql
as $$
declare
  product_row record;
  refreshed integer := 0;
begin
  for product_row in
    select id from public.products where listing_status <> 'disabled'
  loop
    perform public.sync_product_recommendation(product_row.id);
    refreshed := refreshed + 1;
  end loop;

  return refreshed;
end;
$$;

create or replace function public.is_store_owner(store_uuid uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.stores
    where id = store_uuid
      and owner_id = auth.uid()
  );
$$;

create or replace function public.can_access_order(order_uuid uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.orders o
    left join public.stores s on s.id = o.store_id
    left join public.deliveries d on d.order_id = o.id
    where o.id = order_uuid
      and (
        o.buyer_id = auth.uid()
        or s.owner_id = auth.uid()
        or d.rider_id = auth.uid()
      )
  );
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute procedure app_private.set_updated_at();

drop trigger if exists stores_set_updated_at on public.stores;
create trigger stores_set_updated_at
before update on public.stores
for each row execute procedure app_private.set_updated_at();

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at
before update on public.products
for each row execute procedure app_private.set_updated_at();

drop trigger if exists product_recommendations_set_updated_at on public.product_recommendations;
create trigger product_recommendations_set_updated_at
before update on public.product_recommendations
for each row execute procedure app_private.set_updated_at();

drop trigger if exists cart_items_set_updated_at on public.cart_items;
create trigger cart_items_set_updated_at
before update on public.cart_items
for each row execute procedure app_private.set_updated_at();

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at
before update on public.orders
for each row execute procedure app_private.set_updated_at();

drop trigger if exists payments_set_updated_at on public.payments;
create trigger payments_set_updated_at
before update on public.payments
for each row execute procedure app_private.set_updated_at();

drop trigger if exists deliveries_set_updated_at on public.deliveries;
create trigger deliveries_set_updated_at
before update on public.deliveries
for each row execute procedure app_private.set_updated_at();

alter table public.profiles enable row level security;
alter table public.stores enable row level security;
alter table public.seller_verification_documents enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.product_recommendations enable row level security;
alter table public.cart_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_status_history enable row level security;
alter table public.payments enable row level security;
alter table public.deliveries enable row level security;
alter table public.reviews enable row level security;
alter table public.notifications enable row level security;
alter table public.commission_records enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
using (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
with check (auth.uid() = id);

drop policy if exists "stores_public_read" on public.stores;
create policy "stores_public_read"
on public.stores
for select
using (true);

drop policy if exists "stores_owner_manage" on public.stores;
create policy "stores_owner_manage"
on public.stores
for all
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists "seller_documents_owner_read" on public.seller_verification_documents;
create policy "seller_documents_owner_read"
on public.seller_verification_documents
for select
using (seller_id = auth.uid());

drop policy if exists "seller_documents_owner_insert" on public.seller_verification_documents;
create policy "seller_documents_owner_insert"
on public.seller_verification_documents
for insert
with check (seller_id = auth.uid());

drop policy if exists "products_marketplace_read" on public.products;
create policy "products_marketplace_read"
on public.products
for select
using (
  listing_status in ('active', 'near_expiry', 'flash_sale')
  or public.is_store_owner(store_id)
);

drop policy if exists "products_store_manage" on public.products;
create policy "products_store_manage"
on public.products
for all
using (public.is_store_owner(store_id))
with check (public.is_store_owner(store_id));

drop policy if exists "product_images_public_read" on public.product_images;
create policy "product_images_public_read"
on public.product_images
for select
using (true);

drop policy if exists "product_images_store_manage" on public.product_images;
create policy "product_images_store_manage"
on public.product_images
for all
using (
  exists (
    select 1
    from public.products p
    join public.stores s on s.id = p.store_id
    where p.id = product_images.product_id
      and s.owner_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.products p
    join public.stores s on s.id = p.store_id
    where p.id = product_images.product_id
      and s.owner_id = auth.uid()
  )
);

drop policy if exists "recommendations_seller_read" on public.product_recommendations;
create policy "recommendations_seller_read"
on public.product_recommendations
for select
using (
  exists (
    select 1
    from public.products p
    join public.stores s on s.id = p.store_id
    where p.id = product_recommendations.product_id
      and s.owner_id = auth.uid()
  )
);

drop policy if exists "cart_items_owner_manage" on public.cart_items;
create policy "cart_items_owner_manage"
on public.cart_items
for all
using (buyer_id = auth.uid())
with check (buyer_id = auth.uid());

drop policy if exists "orders_access" on public.orders;
create policy "orders_access"
on public.orders
for select
using (public.can_access_order(id));

drop policy if exists "orders_buyer_cancel" on public.orders;
create policy "orders_buyer_cancel"
on public.orders
for update
using (
  buyer_id = auth.uid()
  or exists (
    select 1
    from public.stores s
    where s.id = orders.store_id
      and s.owner_id = auth.uid()
  )
)
with check (
  buyer_id = auth.uid()
  or exists (
    select 1
    from public.stores s
    where s.id = orders.store_id
      and s.owner_id = auth.uid()
  )
);

drop policy if exists "order_items_access" on public.order_items;
create policy "order_items_access"
on public.order_items
for select
using (public.can_access_order(order_id));

drop policy if exists "order_history_access" on public.order_status_history;
create policy "order_history_access"
on public.order_status_history
for select
using (public.can_access_order(order_id));

drop policy if exists "payments_access" on public.payments;
create policy "payments_access"
on public.payments
for select
using (public.can_access_order(order_id));

drop policy if exists "deliveries_access" on public.deliveries;
create policy "deliveries_access"
on public.deliveries
for select
using (
  rider_id = auth.uid()
  or (
    status = 'unassigned'
    and exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role = 'rider'
        and approval_status = 'approved'
    )
  )
  or public.can_access_order(order_id)
);

drop policy if exists "deliveries_rider_manage" on public.deliveries;
create policy "deliveries_rider_manage"
on public.deliveries
for update
using (
  rider_id = auth.uid()
  or (
    rider_id is null
    and exists (
      select 1 from public.profiles
      where id = auth.uid()
        and role = 'rider'
        and approval_status = 'approved'
    )
  )
)
with check (
  rider_id = auth.uid()
  or rider_id is null
  or exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role = 'rider'
      and approval_status = 'approved'
  )
);

drop policy if exists "reviews_public_read" on public.reviews;
create policy "reviews_public_read"
on public.reviews
for select
using (true);

drop policy if exists "reviews_buyer_insert" on public.reviews;
create policy "reviews_buyer_insert"
on public.reviews
for insert
with check (
  author_id = auth.uid()
  and exists (
    select 1
    from public.orders o
    where o.id = reviews.order_id
      and o.buyer_id = auth.uid()
      and o.status = 'delivered'
  )
);

drop policy if exists "notifications_owner_read" on public.notifications;
create policy "notifications_owner_read"
on public.notifications
for select
using (user_id = auth.uid());

drop policy if exists "notifications_owner_update" on public.notifications;
create policy "notifications_owner_update"
on public.notifications
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "commission_records_seller_read" on public.commission_records;
create policy "commission_records_seller_read"
on public.commission_records
for select
using (
  exists (
    select 1 from public.stores s
    where s.id = commission_records.store_id
      and s.owner_id = auth.uid()
  )
);

insert into storage.buckets (id, name, public)
values
  ('product-images', 'product-images', true),
  ('verification-documents', 'verification-documents', false)
on conflict (id) do nothing;

drop policy if exists "product_images_bucket_public_read" on storage.objects;
create policy "product_images_bucket_public_read"
on storage.objects
for select
using (bucket_id = 'product-images');

drop policy if exists "product_images_bucket_authenticated_insert" on storage.objects;
create policy "product_images_bucket_authenticated_insert"
on storage.objects
for insert
with check (
  bucket_id = 'product-images'
  and auth.role() = 'authenticated'
);

drop policy if exists "product_images_bucket_authenticated_update" on storage.objects;
create policy "product_images_bucket_authenticated_update"
on storage.objects
for update
using (
  bucket_id = 'product-images'
  and auth.role() = 'authenticated'
)
with check (
  bucket_id = 'product-images'
  and auth.role() = 'authenticated'
);

drop policy if exists "verification_documents_owner_read" on storage.objects;
create policy "verification_documents_owner_read"
on storage.objects
for select
using (
  bucket_id = 'verification-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "verification_documents_owner_insert" on storage.objects;
create policy "verification_documents_owner_insert"
on storage.objects
for insert
with check (
  bucket_id = 'verification-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "verification_documents_owner_update" on storage.objects;
create policy "verification_documents_owner_update"
on storage.objects
for update
using (
  bucket_id = 'verification-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'verification-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);
