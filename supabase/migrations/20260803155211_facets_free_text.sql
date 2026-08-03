-- Facets become free-form {icon, label} objects so artists can add custom
-- disciplines with their own emoji. Convert existing enum-array facets in place.
-- (A subquery isn't allowed directly in ALTER ... USING, so wrap it in a function.)
alter table artists alter column facets drop default;

create or replace function _facets_to_json(f event_kind[]) returns jsonb
language sql immutable as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'icon', case x::text
              when 'standup' then '🎤'
              when 'improv'  then '🎭'
              when 'theatre' then '🎬'
              when 'music'   then '🎵'
              else '✨'
            end,
    'label', initcap(x::text)
  )), '[]'::jsonb)
  from unnest(f) as x
$$;

alter table artists alter column facets type jsonb using _facets_to_json(facets);
alter table artists alter column facets set default '[]'::jsonb;

drop function _facets_to_json(event_kind[]);
