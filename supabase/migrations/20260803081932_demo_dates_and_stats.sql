-- Keep the demo fresh: anchor example event dates relative to now(),
-- and expose a public follower COUNT (without leaking fan emails).

-- === Re-anchor demo event dates ===
update events set starts_at = now() + interval '3 days'  where id = 'e0000000-0000-4000-8000-000000000001';
update events set starts_at = now() + interval '6 days'  where id = 'e0000000-0000-4000-8000-000000000002';
update events set starts_at = now() + interval '11 days' where id = 'e0000000-0000-4000-8000-000000000003';
update events set starts_at = now() + interval '18 days' where id = 'e0000000-0000-4000-8000-000000000004';
update events set starts_at = now() + interval '25 days' where id = 'e0000000-0000-4000-8000-000000000005';
update events set starts_at = now() + interval '39 days' where id = 'e0000000-0000-4000-8000-000000000006';
update events set starts_at = now() - interval '12 days' where id = 'e0000000-0000-4000-8000-000000000101';
update events set starts_at = now() - interval '26 days' where id = 'e0000000-0000-4000-8000-000000000102';

-- === Public follower count (aggregate only — emails stay private) ===
-- Security-definer view: runs as owner so it can read follows despite RLS,
-- but exposes nothing beyond artist_id + a count.
create or replace view artist_stats as
  select artist_id, count(*)::int as followers
  from follows
  group by artist_id;
