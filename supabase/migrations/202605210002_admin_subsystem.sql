create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text not null unique,
  description text not null default '',
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
      and approval_status = 'approved'
  );
$$;

drop trigger if exists categories_set_updated_at on public.categories;
create trigger categories_set_updated_at
before update on public.categories
for each row execute procedure app_private.set_updated_at();

alter table public.categories enable row level security;

drop policy if exists "categories_public_read" on public.categories;
create policy "categories_public_read"
on public.categories
for select
using (is_active or public.is_admin());

grant select on public.categories to anon, authenticated;

insert into public.categories (name, slug, description, sort_order)
values
  ('Bento Boxes', 'bento-boxes', 'Packed bento-style meal boxes.', 10),
  ('Meals', 'meals', 'Fresh cooked meals and viands.', 20),
  ('Snacks', 'snacks', 'Light meals, finger foods, and snacks.', 30),
  ('Desserts', 'desserts', 'Sweet treats and chilled desserts.', 40),
  ('Drinks', 'drinks', 'Beverages including juices and milk teas.', 50),
  ('Bakery Items', 'bakery-items', 'Bread, pastries, and baked goods.', 60),
  ('Frozen Foods', 'frozen-foods', 'Frozen ready-to-cook or ready-to-heat food.', 70),
  ('Ready-to-Eat Foods', 'ready-to-eat-foods', 'Grab-and-go prepared food items.', 80)
on conflict (slug) do nothing;
