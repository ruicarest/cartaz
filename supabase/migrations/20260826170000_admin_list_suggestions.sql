-- Admin-only reader for feature suggestions.
-- The feature_suggestions table stays write-only at the RLS level; this
-- SECURITY DEFINER function lets a single admin account read them.
create or replace function public.admin_list_suggestions()
returns setof feature_suggestions
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(auth.jwt() ->> 'email', '') <> 'ruicarest@gmail.com' then
    raise exception 'not authorized';
  end if;
  return query select * from feature_suggestions order by created_at desc;
end;
$$;

revoke all on function public.admin_list_suggestions() from public, anon;
grant execute on function public.admin_list_suggestions() to authenticated;
