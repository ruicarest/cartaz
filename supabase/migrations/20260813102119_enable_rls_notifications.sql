-- Security fix: the notifications send-log (holds emails) was missing RLS,
-- so the public anon key could read/write it. It's written only by the
-- backend (service_role, which bypasses RLS), so enabling RLS with no
-- policies blocks all anon access and closes the hole.
alter table notifications enable row level security;
