-- Cartaz — initial schema
-- Link-in-bio for live comedy & theatre artists.
-- Core idea: an event belongs to MANY artists (event_artists), so one edit
-- propagates to every artist's page. Fans follow by contact (no account);
-- only artists authenticate to edit.

-- === Enums ===
create type event_kind    as enum ('standup', 'improv', 'theatre', 'music', 'other');
create type ticket_status as enum ('live', 'soon', 'sold', 'free');

-- === Artists (each owned by an authenticated user) ===
create table artists (
  id         uuid primary key default gen_random_uuid(),
  owner_id   uuid references auth.users(id) on delete set null,
  handle     text unique not null,                 -- cartaz.pt/<handle>
  name       text not null,
  bio        text,
  city       text,
  avatar_url text,
  facets     event_kind[] not null default '{}',   -- profile chips
  created_at timestamptz not null default now()
);

-- === Events (a single show) ===
create table events (
  id            uuid primary key default gen_random_uuid(),
  title         text not null,
  kind          event_kind not null default 'standup',
  venue         text,
  city          text,
  starts_at     timestamptz not null,
  ticket_url    text,
  ticket_status ticket_status not null default 'live',
  price_cents   int,
  currency      text not null default 'EUR',
  created_by    uuid references auth.users(id) on delete set null,
  created_at    timestamptz not null default now()
);
create index events_starts_at_idx on events (starts_at);

-- === Collaborative link: N artists per event ===
create table event_artists (
  event_id  uuid references events(id)  on delete cascade,
  artist_id uuid references artists(id) on delete cascade,
  role      text,                                  -- headliner / host / guest
  can_edit  boolean not null default false,        -- co-organiser may edit
  primary key (event_id, artist_id)
);
create index event_artists_artist_idx on event_artists (artist_id);

-- === Fans follow artists (contact-based, no account required) ===
create table follows (
  id         uuid primary key default gen_random_uuid(),
  artist_id  uuid references artists(id) on delete cascade,
  email      text,
  push_token text,
  fan_id     uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (artist_id, email)
);
create index follows_artist_idx on follows (artist_id);

-- === Per-event reminder (the "bell") ===
create table event_reminders (
  id          uuid primary key default gen_random_uuid(),
  event_id    uuid references events(id) on delete cascade,
  email       text,
  push_token  text,
  fan_id      uuid references auth.users(id) on delete cascade,
  notified_at timestamptz,                          -- null = not yet notified
  created_at  timestamptz not null default now(),
  unique (event_id, email)
);

-- === Outbound send log (dedupe for the scheduler) ===
create table notifications (
  id         uuid primary key default gen_random_uuid(),
  channel    text not null,                         -- 'email' | 'push'
  to_email   text,
  event_id   uuid references events(id)  on delete set null,
  artist_id  uuid references artists(id) on delete set null,
  kind       text not null,                         -- 'new_event' | 'reminder_24h'
  sent_at    timestamptz not null default now()
);

-- === Row-Level Security ===
alter table artists         enable row level security;
alter table events          enable row level security;
alter table event_artists   enable row level security;
alter table follows         enable row level security;
alter table event_reminders enable row level security;

-- Public read: profiles and events render for everyone
create policy read_artists on artists       for select using (true);
create policy read_events  on events        for select using (true);
create policy read_ea      on event_artists for select using (true);

-- Artists manage their own persona
create policy write_own_artist on artists for all
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- Only the creator manages their events
create policy write_own_events on events for all
  using (created_by = auth.uid())
  with check (created_by = auth.uid());

-- Anyone can follow / set a reminder (insert only)
create policy follow_insert   on follows         for insert with check (true);
create policy reminder_insert on event_reminders for insert with check (true);

-- === Convenience view: an artist's shows ===
create view artist_events as
  select a.handle, a.name as artist_name, e.*
  from events e
  join event_artists ea on ea.event_id = e.id
  join artists a        on a.id = ea.artist_id;
