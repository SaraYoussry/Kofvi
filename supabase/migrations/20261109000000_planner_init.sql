-- Kofvi Social Media Planner: accounts, synced planner data, private photos, access codes.
-- Run once in Supabase > SQL Editor (or let the Supabase GitHub integration apply it).

-- 1. One planner per account. The whole plan is stored as JSON.
create table if not exists public.planners (
  user_id    uuid primary key references auth.users (id) on delete cascade,
  data       jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.planners enable row level security;

drop policy if exists "Read own planner"   on public.planners;
drop policy if exists "Create own planner" on public.planners;
drop policy if exists "Update own planner" on public.planners;
drop policy if exists "Delete own planner" on public.planners;

create policy "Read own planner"   on public.planners for select to authenticated using (auth.uid() = user_id);
create policy "Create own planner" on public.planners for insert to authenticated with check (auth.uid() = user_id);
create policy "Update own planner" on public.planners for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Delete own planner" on public.planners for delete to authenticated using (auth.uid() = user_id);

-- 2. Access codes. Buyers need a valid code (printed in the Etsy download PDF) to create an account.
--    No policies on purpose: the browser can never read this table, only check one code.
create table if not exists public.access_codes (
  code       text primary key,
  product    text not null default 'social-media-planner',
  active     boolean not null default true,
  note       text,
  created_at timestamptz not null default now()
);

alter table public.access_codes enable row level security;

create or replace function public.check_access_code(p_code text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.access_codes
    where upper(code) = upper(trim(p_code)) and active
  );
$$;

revoke all on function public.check_access_code(text) from public;
grant execute on function public.check_access_code(text) to anon, authenticated;

-- Block sign-ups that don't carry a valid code (enforced by the database, not just the app).
create or replace function public.enforce_access_code()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.access_codes
    where upper(code) = upper(trim(coalesce(new.raw_user_meta_data ->> 'access_code', '')))
      and active
  ) then
    raise exception 'A valid access code is needed to create a planner account';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_access_code on auth.users;
create trigger enforce_access_code
  before insert on auth.users
  for each row execute function public.enforce_access_code();

-- 3. Private photo storage. Each account can only touch files inside its own folder: <user id>/...
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', false, 5242880, array['image/webp', 'image/jpeg', 'image/png'])
on conflict (id) do nothing;

drop policy if exists "Read own photos"   on storage.objects;
drop policy if exists "Upload own photos" on storage.objects;
drop policy if exists "Update own photos" on storage.objects;
drop policy if exists "Delete own photos" on storage.objects;

create policy "Read own photos" on storage.objects for select to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Upload own photos" on storage.objects for insert to authenticated
  with check (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Update own photos" on storage.objects for update to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Delete own photos" on storage.objects for delete to authenticated
  using (bucket_id = 'photos' and (storage.foldername(name))[1] = auth.uid()::text);

-- 4. First access code. Change it any time: set active = false and insert a new one.
insert into public.access_codes (code, note)
values ('KOFVI-SOCIAL-2027', 'Social Media Planner, Etsy download PDF')
on conflict (code) do nothing;
