# AxMedia Primary Tracker

Personal dashboard for tracking the 2026 primary calendar with urgency-based flagging tied to flighting and optimization windows. Surfaces upcoming primaries for client candidates and color-codes them by how close the race is. Roster is shared across all users via Supabase — anyone with the URL can view and edit, with changes syncing in real time.

## Live tracker

Hosted via GitHub Pages. Open `index.html` directly for solo offline use, or visit the published Pages URL for the live shared experience.

## Project layout

```
.
├── index.html             # the entire app (HTML + CSS + JS in one file)
├── config.js              # Supabase URL + anon key (commit this)
├── supabase-setup.sql     # one-time schema setup, run in Supabase SQL Editor
├── data/
│   └── roster.json        # legacy seed file — no longer the source of truth
└── README.md
```

## Urgency tiers

| Tier | Window | Treatment |
|------|--------|-----------|
| INCREASE IMPRESSIONS | exactly 11 days out | Red flashing alert at top — action prompt, not a status |
| Urgent · GOTV | ≤14 days | Red badge |
| Final flight | 15–30 days | Orange badge |
| Planning | 31–60 days | Yellow badge |
| Future | 60+ days | Neutral badge |

The 11-day flag is the "ramp impressions for final stretch" trigger and lights up the top alert bar whenever a client primary lands on that window.

## How the shared roster works

The roster lives in a `roster` table in Supabase. The page connects on load, fetches the current roster, and subscribes to realtime changes. When anyone adds or removes a candidate, every other open browser updates within a second or two.

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
