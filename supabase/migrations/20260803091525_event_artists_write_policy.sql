-- Let the event's creator manage its lineup (add/remove artists on the event).
-- The public studio uses this to link a newly created event to the artist.

create policy manage_ea on event_artists for all
  using (
    exists (select 1 from events e where e.id = event_artists.event_id and e.created_by = auth.uid())
  )
  with check (
    exists (select 1 from events e where e.id = event_artists.event_id and e.created_by = auth.uid())
  );
