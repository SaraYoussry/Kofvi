-- ADHD Life Planner (kofvi.com/planner/adhd/): private file storage for photos, voice notes and certificates.
-- Run once in Supabase > SQL Editor. Planner data itself uses the existing planners table (product 'adhd-planner').

-- 1. A private bucket. Each account can only see its own folder: planner-files/<user id>/...
insert into storage.buckets (id, name, public, file_size_limit)
values ('planner-files', 'planner-files', false, 26214400)
on conflict (id) do nothing;

drop policy if exists "Planner files: read own" on storage.objects;
drop policy if exists "Planner files: add own" on storage.objects;
drop policy if exists "Planner files: change own" on storage.objects;
drop policy if exists "Planner files: remove own" on storage.objects;
create policy "Planner files: read own" on storage.objects for select to authenticated
  using (bucket_id = 'planner-files' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Planner files: add own" on storage.objects for insert to authenticated
  with check (bucket_id = 'planner-files' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Planner files: change own" on storage.objects for update to authenticated
  using (bucket_id = 'planner-files' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "Planner files: remove own" on storage.objects for delete to authenticated
  using (bucket_id = 'planner-files' and (storage.foldername(name))[1] = auth.uid()::text);

-- 2. The Etsy access code is added separately (not stored in this public repo):
-- insert into public.access_codes (code, product, note) values ('KOFVI-ADHD-....', 'adhd-planner', 'ADHD Life Planner Etsy PDF');
