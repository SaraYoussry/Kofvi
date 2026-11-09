-- Kofvi planners: one account, several planners. Each planner (product) is unlocked by its own access code.
-- Run once in Supabase > SQL Editor, after 20261109000000_planner_init.sql.

-- 1. Which planners each account has unlocked.
create table if not exists public.user_products (
  user_id    uuid not null references auth.users (id) on delete cascade,
  product    text not null,
  code       text,
  granted_at timestamptz not null default now(),
  primary key (user_id, product)
);

alter table public.user_products enable row level security;
drop policy if exists "Read own products" on public.user_products;
create policy "Read own products" on public.user_products for select to authenticated using (auth.uid() = user_id);
-- No insert/update policies: unlocking only happens through redeem_access_code() or the sign-up trigger.

-- 2. One saved plan per account AND planner.
alter table public.planners add column if not exists product text not null default 'social-media-planner';
alter table public.planners drop constraint if exists planners_pkey;
alter table public.planners add primary key (user_id, product);

drop policy if exists "Create own planner" on public.planners;
drop policy if exists "Update own planner" on public.planners;
create policy "Create own planner" on public.planners for insert to authenticated
  with check (auth.uid() = user_id and exists (select 1 from public.user_products up where up.user_id = auth.uid() and up.product = planners.product));
create policy "Update own planner" on public.planners for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id and exists (select 1 from public.user_products up where up.user_id = auth.uid() and up.product = planners.product));

-- 3. Which planner a code unlocks (null = not a valid code). Safe for the browser: reveals nothing else.
create or replace function public.code_product(p_code text)
returns text language sql stable security definer set search_path = public as $$
  select product from public.access_codes where upper(code) = upper(trim(p_code)) and active limit 1;
$$;
revoke all on function public.code_product(text) from public;
grant execute on function public.code_product(text) to anon, authenticated;

-- 4. Signed-in user enters a code -> that planner is unlocked. Returns the product, or null if the code is wrong.
create or replace function public.redeem_access_code(p_code text)
returns text language plpgsql security definer set search_path = public as $$
declare v_product text;
begin
  if auth.uid() is null then return null; end if;
  select product into v_product from public.access_codes where upper(code) = upper(trim(p_code)) and active limit 1;
  if v_product is null then return null; end if;
  insert into public.user_products (user_id, product, code) values (auth.uid(), v_product, upper(trim(p_code)))
  on conflict (user_id, product) do nothing;
  return v_product;
end;
$$;
revoke all on function public.redeem_access_code(text) from public;
grant execute on function public.redeem_access_code(text) to authenticated;

-- 5. New account created with a code -> unlock that code's planner straight away.
create or replace function public.grant_signup_product()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_code text := upper(trim(coalesce(new.raw_user_meta_data ->> 'access_code', '')));
        v_product text;
begin
  select product into v_product from public.access_codes where upper(code) = v_code and active limit 1;
  if v_product is not null then
    insert into public.user_products (user_id, product, code) values (new.id, v_product, v_code)
    on conflict (user_id, product) do nothing;
  end if;
  return new;
end;
$$;
drop trigger if exists grant_signup_product on auth.users;
create trigger grant_signup_product after insert on auth.users
  for each row execute function public.grant_signup_product();

-- 6. Accounts made before this migration keep their planner.
insert into public.user_products (user_id, product, code)
select u.id, ac.product, ac.code
from auth.users u
join public.access_codes ac on upper(ac.code) = upper(trim(coalesce(u.raw_user_meta_data ->> 'access_code', '')))
on conflict (user_id, product) do nothing;
