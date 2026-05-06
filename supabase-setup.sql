-- AxMedia Primary Tracker — Supabase setup
-- ---------------------------------------------------------------
-- Run this once in your Supabase project's SQL Editor.
-- Creates the roster table, opens public anon read/write, and
-- turns on realtime so multiple browsers stay in sync.
-- ---------------------------------------------------------------

create table if not exists roster (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  state       text not null,
  office      text not null,
  district    text default '',
  source      text default 'manual',  -- 'auto' (NBC match) or 'manual'
  created_at  timestamptz default now()
);

-- Row Level Security: required when anon role accesses the table
alter table roster enable row level security;

-- Open writes — anyone with the URL can read/add/remove.
-- Tighten these later if you want auth-gated edits.
create policy "Public read"   on roster for select to anon using (true);
create policy "Public insert" on roster for insert to anon with check (true);
create policy "Public delete" on roster for delete to anon using (true);

-- Realtime broadcast so other open tabs see changes immediately
alter publication supabase_realtime add table roster;
