-- Transactional email notifications via pg_net + Resend.
-- The Resend API key is stored in Vault (name 'resend_api_key'), set out-of-band
-- (never committed). Both triggers are fire-and-forget: if email fails, the
-- underlying insert still succeeds.

create extension if not exists pg_net;
create extension if not exists supabase_vault;

-- low-level sender: POST one email to Resend, reading the key from Vault
create or replace function public._send_email(p_to text, p_subject text, p_html text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare k text;
begin
  select decrypted_secret into k from vault.decrypted_secrets where name = 'resend_api_key';
  if k is null or p_to is null then return; end if;
  perform net.http_post(
    url     := 'https://api.resend.com/emails',
    headers := jsonb_build_object('Authorization', 'Bearer ' || k, 'Content-Type', 'application/json'),
    body    := jsonb_build_object(
                 'from', 'Livez <no-reply@livez.art>',
                 'to', jsonb_build_array(p_to),
                 'subject', p_subject,
                 'html', p_html)
  );
end;
$$;
revoke all on function public._send_email(text, text, text) from public, anon, authenticated;

-- 1) A co-artist was invited (pending) → email them to accept/decline
create or replace function public._notify_coartist_invite()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare v_owner uuid; v_email text; v_name text; v_title text; v_when text; v_venue text;
begin
  if new.status is distinct from 'pending' then return new; end if;
  select owner_id, name into v_owner, v_name from artists where id = new.artist_id;
  if v_owner is null then return new; end if;                 -- unclaimed / seed artist
  select email into v_email from auth.users where id = v_owner;
  if v_email is null then return new; end if;
  select title,
         to_char(starts_at at time zone 'Europe/Lisbon', 'Dy DD Mon · HH24:MI'),
         nullif(concat_ws(' · ', venue, city), '')
    into v_title, v_when, v_venue
    from events where id = new.event_id;
  perform public._send_email(
    v_email,
    'You were added to a show on Livez',
    '<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:520px;margin:0 auto;color:#1a1a1f">'
      || '<div style="font-weight:800;font-size:20px;margin-bottom:16px">🎭 Livez</div>'
      || '<p style="font-size:16px">Hi ' || coalesce(v_name, 'there') || ', you were added to a show:</p>'
      || '<div style="border:1px solid #e5e3df;border-radius:14px;padding:16px 18px;margin:14px 0">'
      || '<div style="font-weight:800;font-size:18px">' || coalesce(v_title, 'A show') || '</div>'
      || '<div style="color:#6f6d78;font-size:14px">' || coalesce(v_when, '') || coalesce(' · ' || v_venue, '') || '</div></div>'
      || '<p style="font-size:15px">It won''t show on your page until you accept it.</p>'
      || '<a href="https://livez.art/studio.html" style="display:inline-block;background:#ff5638;color:#fff;text-decoration:none;font-weight:700;padding:12px 22px;border-radius:12px">Review in your Studio →</a>'
      || '</div>'
  );
  return new;
end;
$$;

drop trigger if exists trg_coartist_invite on event_artists;
create trigger trg_coartist_invite after insert on event_artists
  for each row execute function public._notify_coartist_invite();

-- 2) A new artist page was created → email the admin
create or replace function public._notify_admin_signup()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public._send_email(
    'ruicarest@gmail.com',
    'New Livez signup: ' || coalesce(new.name, new.handle),
    '<div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#1a1a1f">'
      || '<p style="font-size:16px">🎭 New artist just joined Livez:</p>'
      || '<p style="font-size:18px;font-weight:800;margin:4px 0">' || coalesce(new.name, '(no name)') || '</p>'
      || '<a href="https://livez.art/' || new.handle || '">livez.art/' || new.handle || '</a>'
      || '</div>'
  );
  return new;
end;
$$;

drop trigger if exists trg_admin_signup on artists;
create trigger trg_admin_signup after insert on artists
  for each row execute function public._notify_admin_signup();
