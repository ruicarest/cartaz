-- Co-artist invitations need acceptance before the show appears on their page.
-- 'accepted' default so all existing links (incl. seed data + each creator's
-- own link) stay visible; new co-artist invites are inserted as 'pending'.
alter table event_artists add column if not exists status text not null default 'accepted';

-- An artist may ACCEPT (update) or DECLINE (delete) their OWN participation.
-- (Inserting links stays creator-only via the existing manage_ea policy, so
--  nobody can add themselves to someone else's show.)
create policy accept_own_ea on event_artists for update
  using ( exists (select 1 from artists a where a.id = event_artists.artist_id and a.owner_id = auth.uid()) )
  with check ( exists (select 1 from artists a where a.id = event_artists.artist_id and a.owner_id = auth.uid()) );

create policy decline_own_ea on event_artists for delete
  using ( exists (select 1 from artists a where a.id = event_artists.artist_id and a.owner_id = auth.uid()) );

-- Public view: only accepted participations count.
create or replace view artist_events as
  select a.handle, a.name as artist_name, e.*
  from events e
  join event_artists ea on ea.event_id = e.id
  join artists a        on a.id = ea.artist_id
  where ea.status = 'accepted';
