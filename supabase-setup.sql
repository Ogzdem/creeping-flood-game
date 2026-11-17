-- Creeping Flood: tables and security for feedback (only the admin can read it) and the shared ranking.
-- Run this once in Supabase: SQL Editor -> New query -> paste -> Run.
-- BEFORE running: replace ADMIN_EMAIL (3 places per table, search for it) with the email address of your admin login.

create table if not exists feedback (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  version text, kind text, map text, result text, rating int, difficulty text, score int,
  points jsonb, comment text, context jsonb,
  status text not null default 'new'
);
create table if not exists scores (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  version text, map text not null,
  initials text not null check (char_length(initials) between 1 and 3),
  score int not null check (score between 0 and 100000),
  play_seconds int
);

alter table feedback enable row level security;
alter table scores enable row level security;

-- everybody (the game) may add feedback and scores, within limits
create policy "send feedback" on feedback for insert to anon, authenticated
  with check (kind in ('feedback', 'level') and char_length(coalesce(comment, '')) < 3000 and char_length(coalesce(points::text, '')) < 6000);
create policy "send score" on scores for insert to anon, authenticated with check (true);

-- everybody may read the ranking
create policy "read ranking" on scores for select to anon, authenticated using (true);

-- only the admin reads, changes and deletes feedback, and removes scores
create policy "admin reads feedback" on feedback for select to authenticated using ((auth.jwt() ->> 'email') = 'Webboguz@gmail.com');
create policy "admin updates feedback" on feedback for update to authenticated using ((auth.jwt() ->> 'email') = 'Webboguz@gmail.com') with check ((auth.jwt() ->> 'email') = 'Webboguz@gmail.com');
create policy "admin deletes feedback" on feedback for delete to authenticated using ((auth.jwt() ->> 'email') = 'Webboguz@gmail.com');
create policy "admin deletes scores" on scores for delete to authenticated using ((auth.jwt() ->> 'email') = 'Webboguz@gmail.com');
