-- Write-only public endpoints for fans.
-- Fans must not be able to READ follows/reminders (emails are private), so we
-- can't insert-and-return through PostgREST. These SECURITY DEFINER functions
-- perform the insert and return nothing — no table read required, no email leak.

create or replace function public.follow_artist(p_artist uuid, p_email text)
returns void
language sql
security definer
set search_path = public
as $$
  insert into follows (artist_id, email)
  values (p_artist, lower(trim(p_email)))
  on conflict (artist_id, email) do nothing;
$$;

create or replace function public.remind_event(p_event uuid, p_email text)
returns void
language sql
security definer
set search_path = public
as $$
  insert into event_reminders (event_id, email)
  values (p_event, lower(trim(p_email)))
  on conflict (event_id, email) do nothing;
$$;

grant execute on function public.follow_artist(uuid, text) to anon, authenticated;
grant execute on function public.remind_event(uuid, text)  to anon, authenticated;
