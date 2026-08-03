-- Keep storage bounded: images only, hard size cap per bucket
-- (client also downscales before upload, so real files are ~100-400KB).
update storage.buckets
  set file_size_limit = 2097152,  -- 2 MB
      allowed_mime_types = array['image/png','image/jpeg','image/webp','image/gif']
  where id = 'avatars';

-- Posters (event images)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('posters', 'posters', true, 3145728, array['image/png','image/jpeg','image/webp','image/gif'])
on conflict (id) do nothing;

create policy "posters public read" on storage.objects
  for select using ( bucket_id = 'posters' );
create policy "posters insert own" on storage.objects
  for insert with check ( bucket_id = 'posters' and (storage.foldername(name))[1] = auth.uid()::text );
create policy "posters update own" on storage.objects
  for update using ( bucket_id = 'posters' and (storage.foldername(name))[1] = auth.uid()::text );
create policy "posters delete own" on storage.objects
  for delete using ( bucket_id = 'posters' and (storage.foldername(name))[1] = auth.uid()::text );

-- Event poster image
alter table events add column if not exists image_url text;
