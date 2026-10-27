-- Pegar en Supabase → SQL Editor → Run.
-- Cada usuario solo puede ver y modificar sus propios escaneos (RLS).

create table if not exists public.scans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  motorcycle jsonb not null,
  expenses jsonb not null,
  created_at timestamptz not null default now()
);

create index if not exists scans_user_created_idx
  on public.scans (user_id, created_at desc);

alter table public.scans enable row level security;

create policy "scans_select_own" on public.scans
  for select to authenticated using (user_id = auth.uid());

create policy "scans_insert_own" on public.scans
  for insert to authenticated with check (user_id = auth.uid());

create policy "scans_update_own" on public.scans
  for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "scans_delete_own" on public.scans
  for delete to authenticated using (user_id = auth.uid());
