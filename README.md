# AxMedia Primary Tracker

Personal dashboard for tracking the 2026 primary calendar with urgency-based flagging tied to flighting and optimization windows. Surfaces upcoming primaries for client candidates and color-codes them by how close the race is. Roster is shared across all users via Supabase — anyone with the URL can view and edit, with changes syncing in real time.

## Live tracker

Hosted via GitHub Pages. Open `index.html` directly for solo offline use, or visit the published Pages URL for the live shared experience.

## Project layout

```
.
├── index.html                          # the entire app (HTML + CSS + JS in one file)
├── config.js                           # Supabase URL + anon key (commit this)
├── supabase-setup.sql                  # canonical fresh-install schema
├── migration-001-edits-and-runoffs.sql # upgrade for an existing v1 project
├── data/
│   └── roster.json                     # legacy seed file — no longer the source of truth
└── README.md
```

## Urgency tiers

| Tier | Window | Treatment |
|------|--------|-----------|
| INCREASE IMPRESSIONS | exactly 11 days out | Red flashing alert at top — action prompt, not a status |
| Urgent · GOTV | ≤14 days | Red badge |
| Gain Steam | 15–30 days | Orange badge |
| Saturation | 31–60 days | Yellow badge |
| Awareness | 60+ days | Neutral badge |

The 11-day flag is the "ramp impressions for final stretch" trigger and lights up the top alert bar whenever a client primary lands on that window.

## Roster columns

Each row on the client roster panel shows:
- **Tier** — urgency badge based on days-until the next upcoming election in the state (primary or confirmed runoff). Roster rows tagged with a small `runoff` badge when the next election is a runoff.
- **Date / Day** — the next election date for that state.
- **Candidate** — the name (with `auto`/`manual` source tag).
- **Race** — `{State} · {Office} [· {District}]`. Editable via the Edit button.
- **NBC Race Notes** — condensed reference text from the curated NBC calendar (truncated to 2 lines, full text on hover). Read-only.
- **Custom Notes** — per-client annotation. Editable via the Edit button; useful for buy details, optimization decisions, internal context.

## Runoffs

Runoffs are user-added events. When a state confirms a runoff (e.g. Texas's late-May runoff after no candidate clears 50%), use the **Add Runoff** form to enter the date, state, offices, and optional notes. Runoffs:
- Appear in the full calendar table with a `runoff` badge.
- Replace the original primary as the countdown target on roster rows once the primary has passed.
- Fire the same 11-day INCREASE IMPRESSIONS alert as primaries.

## How the shared roster works

The roster lives in a `roster` table in Supabase. The page connects on load, fetches the current roster, and subscribes to realtime changes. When anyone adds, removes, or edits a candidate, every other open browser updates within a second or two. Runoffs in the `events` table sync the same way.

If the browser can't reach Supabase (offline, project paused, etc.), the page falls back to a localStorage cache so it still renders something useful. Adds/removes are blocked until the connection returns.

The status line under the action buttons shows connection state:
- Green (●) — Live · syncing across all browsers
- Orange (●) — Offline / misconfigured / showing cached roster

## First-time setup

### 1. Create the Supabase backend

1. Sign in at [supabase.com](https://supabase.com) (link with GitHub if not already)
2. New Project → name it whatever, pick a region close to you
3. Once provisioned, open **SQL Editor** → **New query**
4. Paste the contents of `supabase-setup.sql` and run it
5. Open **Settings → API**, copy the **Project URL** and **anon / public key**

### Upgrading an existing project

If your Supabase project was set up with the original v1 schema (no `custom_notes` column, no `events` table), run the contents of `migration-001-edits-and-runoffs.sql` in the SQL Editor. The migration is idempotent — safe to run more than once.

### 2. Configure the page

Open `config.js` and replace the two placeholders:

```js
window.SUPABASE_CONFIG = {
  url:     'https://YOUR-PROJECT-REF.supabase.co',
  anonKey: 'eyJhbGc...'
};
```

The anon key is meant to be public — Supabase Row Level Security policies (set up by `supabase-setup.sql`) control what it can actually do. Commit `config.js` to the repo.

### 3. Deploy

Push the repo to GitHub. Settings → Pages → Source: `main` branch, root → published at `https://<username>.github.io/<repo>/`.

## Updating the calendar

The 2026 primary calendar is hardcoded as a `PRIMARIES` array near the top of the `<script>` block in `index.html`. Each entry:

```js
{
  date: '2026-06-02',
  state: 'California',
  offices: ['Governor', 'U.S. House', 'State Legislature'],
  notes: 'Open governor (Newsom term-limited). Top-two jungle primary.',
  candidates: ['Katie Porter', 'Antonio Villaraigosa']  // names NBC flagged
}
```

When NBC updates the calendar mid-cycle (rare), edit this array directly. For the 2027 off-year or 2028 cycle, replace it wholesale.

## Local development

No build step. Open `index.html` directly in a browser, or serve the folder with any static server:

```bash
python3 -m http.server 8000
# then visit http://localhost:8000
```

The Supabase fetch works either way (it's a CDN call, not a same-origin file fetch).

## Backups

The **Backup JSON** button downloads a snapshot of the current roster as `roster-backup-YYYY-MM-DD.json`. Useful before doing anything risky, or for archiving cycle-end state. Backup files are gitignored by default — drop them somewhere outside the repo or commit explicitly if you want them tracked.

## Tightening access later

If "anyone with the URL can edit" stops being acceptable, tighten the RLS policies in Supabase:

```sql
-- Drop public-write policies
drop policy "Public insert" on roster;
drop policy "Public delete" on roster;

-- Replace with auth-gated equivalents (requires sign-in flow in the page)
create policy "Auth insert" on roster for insert to authenticated with check (true);
create policy "Auth delete" on roster for delete to authenticated using (true);
```

Auth UI in the page is a separate change — flag me when you want it.

## Testing tier transitions

Append `?today=YYYY-MM-DD` to the URL to override the date used for tier calculations. Useful for verifying that the 11-day INCREASE IMPRESSIONS flag fires correctly without changing the system clock.

```
index.html?today=2026-06-09
```

## Out of scope (v1)

No Monday.com, PipeDrive, or Grapeseed data integration. No budget or IO metadata. No filters/search. No mobile layout. No auth — anyone with the URL can edit.
