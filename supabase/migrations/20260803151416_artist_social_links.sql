-- Public profile links (store the profile URL or a @handle).
alter table artists add column if not exists instagram text;
alter table artists add column if not exists youtube   text;
alter table artists add column if not exists tiktok    text;
alter table artists add column if not exists linkedin  text;
alter table artists add column if not exists website   text;
