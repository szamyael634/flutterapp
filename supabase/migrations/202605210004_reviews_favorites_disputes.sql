create table if not exists public.favorite_stores (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  created_at timestamptz not null default timezone('utc', now()),
  unique (buyer_id, store_id)
);

create table if not exists public.disputes (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'open',
  category text not null default 'general',
  title text not null,
  description text not null,
  resolution_notes text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

drop trigger if exists disputes_set_updated_at on public.disputes;
create trigger disputes_set_updated_at
before update on public.disputes
for each row execute procedure app_private.set_updated_at();

alter table public.favorite_stores enable row level security;
alter table public.disputes enable row level security;

drop policy if exists "favorite_stores_owner_manage" on public.favorite_stores;
create policy "favorite_stores_owner_manage"
on public.favorite_stores
for all
using (buyer_id = auth.uid())
with check (buyer_id = auth.uid());

drop policy if exists "disputes_access" on public.disputes;
create policy "disputes_access"
on public.disputes
for select
using (
  reporter_id = auth.uid()
  or public.can_access_order(order_id)
);

drop policy if exists "disputes_reporter_insert" on public.disputes;
create policy "disputes_reporter_insert"
on public.disputes
for insert
with check (
  reporter_id = auth.uid()
  and public.can_access_order(order_id)
);

grant select, insert, delete on public.favorite_stores to authenticated;
grant select, insert, update on public.disputes to authenticated;
grant select, insert on public.reviews to authenticated;
grant all privileges on public.favorite_stores to service_role;
grant all privileges on public.disputes to service_role;
grant all privileges on public.reviews to service_role;
