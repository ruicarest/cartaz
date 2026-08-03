-- Alternative to a ticket link: a free-text booking note (e.g. "Book with me").
alter table events add column if not exists booking_note text;

-- Public bucket for artist profile photos.
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Anyone can read avatars; each user manages files under their own uid folder.
create policy "avatars public read" on storage.objects
  for select using ( bucket_id = 'avatars' );

create policy "avatars insert own" on storage.objects
  for insert with check (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars update own" on storage.objects
  for update using (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars delete own" on storage.objects
  for delete using (
    bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text
  );
