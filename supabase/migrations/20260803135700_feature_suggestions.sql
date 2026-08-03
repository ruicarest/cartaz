-- Feature suggestions from the footer. Write-only from the public site.
create table feature_suggestions (
  id         uuid primary key default gen_random_uuid(),
  body       text not null,
  email      text,
  handle     text,               -- artist page it was sent from, if any
  created_at timestamptz not null default now()
);
alter table feature_suggestions enable row level security;
-- no direct table access; only the RPC below (SECURITY DEFINER) can insert.

create or replace function public.suggest_feature(p_body text, p_email text, p_handle text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(trim(p_body), '') = '' then return; end if;
  insert into feature_suggestions (body, email, handle)
  values (trim(p_body), nullif(trim(p_email), ''), nullif(trim(p_handle), ''));
end;
$$;

grant execute on function public.suggest_feature(text, text, text) to anon, authenticated;
