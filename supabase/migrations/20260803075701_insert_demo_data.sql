-- Cartaz — demo data (matches the prototype in index.html)
-- No auth users yet, so owner_id / created_by stay null.

-- === Artists ===
insert into artists (id, handle, name, bio, city, facets) values
  ('a0000000-0000-4000-8000-000000000001', 'migueltavares', 'Miguel Tavares',
   'Comedian and improviser in Lisbon. One person, three stages — every date in one place.',
   'Lisbon', '{standup,improv,theatre}'),
  ('a0000000-0000-4000-8000-000000000002', 'ritasalgado',  'Rita Salgado',  'Improviser & standup.', 'Lisbon', '{improv,standup}'),
  ('a0000000-0000-4000-8000-000000000003', 'joaopedro',    'João Pedro',    'Improv troupe regular.', 'Lisbon', '{improv}'),
  ('a0000000-0000-4000-8000-000000000004', 'anacosta',     'Ana Costa',     'Improviser, Porto scene.', 'Porto',  '{improv}');

-- === Events ===
insert into events (id, title, kind, venue, city, starts_at, ticket_url, ticket_status, price_cents) values
  ('e0000000-0000-4000-8000-000000000001', 'Open Mic Comedy Night',              'standup', 'Comedy Lounge',        'Lisbon', '2026-07-17 21:00:00+01', 'https://example.com/tickets/e1', 'live', 800),
  ('e0000000-0000-4000-8000-000000000002', 'The Improbables — Improv Match',     'improv',  'Teatro do Bairro',     'Lisbon', '2026-07-19 21:30:00+01', 'https://example.com/tickets/e2', 'live', 1200),
  ('e0000000-0000-4000-8000-000000000003', 'Work in Progress — new material',    'standup', 'Musicbox',             'Lisbon', '2026-07-24 21:00:00+01', 'https://example.com/tickets/e3', 'live', 600),
  ('e0000000-0000-4000-8000-000000000004', '"Family Lunch" — Premiere',          'theatre', 'Teatro Maria Matos',   'Lisbon', '2026-08-02 21:30:00+01', null,                               'soon', null),
  ('e0000000-0000-4000-8000-000000000005', 'Improv by Candlelight (Porto)',      'improv',  'Teatro Sá da Bandeira', 'Porto', '2026-08-09 21:30:00+01', 'https://example.com/tickets/e5', 'live', 1200),
  ('e0000000-0000-4000-8000-000000000006', 'Summer Special — 45 min solo',       'standup', 'Casino Estoril',       'Cascais','2026-08-23 22:00:00+01', 'https://example.com/tickets/e6', 'sold', null),
  ('e0000000-0000-4000-8000-000000000101', 'The Improbables — Season Finale',    'improv',  'Teatro do Bairro',     'Lisbon', '2026-06-28 21:30:00+01', null,                               'live', 1200),
  ('e0000000-0000-4000-8000-000000000102', 'Porto Comedy Gala',                  'standup', 'Coliseu',              'Porto',  '2026-06-14 21:00:00+01', null,                               'live', 1000);

-- === Collaborative links (N artists per event) ===
-- Miguel is on all of his shows
insert into event_artists (event_id, artist_id, role, can_edit) values
  ('e0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'headliner', true),
  ('e0000000-0000-4000-8000-000000000003', 'a0000000-0000-4000-8000-000000000001', 'headliner', true),
  ('e0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-000000000001', 'cast',      true),
  ('e0000000-0000-4000-8000-000000000006', 'a0000000-0000-4000-8000-000000000001', 'headliner', true),
  ('e0000000-0000-4000-8000-000000000102', 'a0000000-0000-4000-8000-000000000001', 'guest',     false);

-- Shared event e2: Miguel + Rita + João + Ana
insert into event_artists (event_id, artist_id, role, can_edit) values
  ('e0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'host',  true),
  ('e0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002', 'cast',  true),
  ('e0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000003', 'cast',  false),
  ('e0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000004', 'cast',  false);

-- Shared event e5 (Porto): Miguel + Ana + Rita
insert into event_artists (event_id, artist_id, role, can_edit) values
  ('e0000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000001', 'cast', true),
  ('e0000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000004', 'host', true),
  ('e0000000-0000-4000-8000-000000000005', 'a0000000-0000-4000-8000-000000000002', 'cast', false);

-- Past shared event p1: Miguel + Rita
insert into event_artists (event_id, artist_id, role, can_edit) values
  ('e0000000-0000-4000-8000-000000000101', 'a0000000-0000-4000-8000-000000000001', 'cast', true),
  ('e0000000-0000-4000-8000-000000000101', 'a0000000-0000-4000-8000-000000000002', 'cast', false);

-- === A couple of followers for realism ===
insert into follows (artist_id, email) values
  ('a0000000-0000-4000-8000-000000000001', 'fan1@example.com'),
  ('a0000000-0000-4000-8000-000000000001', 'fan2@example.com');
