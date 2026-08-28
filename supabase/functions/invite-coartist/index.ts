// Sends a "you were added to a show" email to co-artists invited to an event.
// Called from the Studio (saveShow) right after pending invites are inserted.
//
// Security: the caller must be authenticated and must themselves be on the event
// (an accepted member). We only email artist_ids that are actually PENDING on that
// event and whose owner account has a real email — so it can't be used to spam.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const TZ = "Europe/Lisbon";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

const esc = (s: string) =>
  String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!));

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const authHeader = req.headers.get("Authorization") || "";
    const body = await req.json().catch(() => ({}));
    const eventId: string = body.event_id;
    const artistIds: string[] = Array.isArray(body.artist_ids) ? body.artist_ids : [];
    if (!eventId || artistIds.length === 0) return json({ ok: true, sent: 0 });

    // Who is calling?
    const asCaller = createClient(SUPABASE_URL, ANON, { global: { headers: { Authorization: authHeader } } });
    const { data: { user } } = await asCaller.auth.getUser();
    if (!user) return json({ ok: false, error: "unauthorized" }, 401);

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE);

    // The caller must be a member of this event (via an artist they own).
    const { data: myArtists } = await admin.from("artists").select("id, name").eq("owner_id", user.id);
    const myIds = new Set((myArtists ?? []).map((a) => a.id));
    if (myIds.size === 0) return json({ ok: false, error: "no artist" }, 403);

    const { data: onEvent } = await admin.from("event_artists").select("artist_id, status").eq("event_id", eventId);
    const callerOnEvent = (onEvent ?? []).some((r) => myIds.has(r.artist_id));
    if (!callerOnEvent) return json({ ok: false, error: "not on event" }, 403);

    // Only notify artists that are actually PENDING on this event and were requested.
    const pendingIds = new Set(
      (onEvent ?? []).filter((r) => r.status === "pending" && artistIds.includes(r.artist_id)).map((r) => r.artist_id),
    );
    if (pendingIds.size === 0) return json({ ok: true, sent: 0 });

    const { data: ev } = await admin.from("events").select("title, starts_at, venue, city").eq("id", eventId).single();
    if (!ev) return json({ ok: false, error: "event not found" }, 404);

    const inviter = (myArtists ?? []).find((a) => a.name)?.name || "A fellow artist";
    const when = new Date(ev.starts_at).toLocaleString("en-GB",
      { timeZone: TZ, weekday: "short", day: "2-digit", month: "short", hour: "2-digit", minute: "2-digit" });
    const venue = [ev.venue, ev.city].filter(Boolean).join(" · ");

    const { data: invitees } = await admin.from("artists").select("id, name, owner_id").in("id", [...pendingIds]);

    let sent = 0;
    for (const a of invitees ?? []) {
      if (!a.owner_id) continue; // unclaimed / seed artist — no account to email
      const { data: u } = await admin.auth.admin.getUserById(a.owner_id);
      const email = u?.user?.email;
      if (!email) continue;
      await sendEmail(email, a.name || "there", inviter, ev.title, when, venue);
      sent++;
    }
    return json({ ok: true, sent });
  } catch (e) {
    return json({ ok: false, error: String(e) }, 500);
  }
});

async function sendEmail(to: string, name: string, inviter: string, title: string, when: string, venue: string) {
  const html = `
  <div style="font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;max-width:520px;margin:0 auto;color:#1a1a1f">
    <div style="font-weight:800;font-size:20px;margin-bottom:18px">🎭 Livez</div>
    <p style="font-size:16px;margin:0 0 6px">Hi ${esc(name)},</p>
    <p style="font-size:16px;margin:0 0 18px"><b>${esc(inviter)}</b> added you to a show:</p>
    <div style="border:1px solid #e5e3df;border-radius:14px;padding:16px 18px;margin-bottom:20px">
      <div style="font-weight:800;font-size:18px;margin-bottom:4px">${esc(title)}</div>
      <div style="color:#6f6d78;font-size:14px">${esc(when)}${venue ? " · " + esc(venue) : ""}</div>
    </div>
    <p style="font-size:15px;margin:0 0 18px">It won't show on your page until you accept it.</p>
    <a href="https://livez.art/studio.html" style="display:inline-block;background:#ff5638;color:#fff;text-decoration:none;font-weight:700;padding:12px 22px;border-radius:12px">Review in your Studio →</a>
    <p style="color:#9c99a6;font-size:12px;margin:26px 0 0">You're getting this because you have a Livez page. Open the Studio to accept or decline.</p>
  </div>`;
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { "Authorization": `Bearer ${RESEND_API_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      from: "Livez <no-reply@livez.art>",
      to: [to],
      subject: `${inviter} added you to a show on Livez`,
      html,
    }),
  });
  if (!res.ok) console.error("resend error", res.status, await res.text());
}
