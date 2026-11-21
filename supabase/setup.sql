-- Lightweight app: its own tables, separate from FloorPlanGuy's
create table if not exists lw_docs (
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  id text not null,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);
create table if not exists lw_crew (
  user_id uuid primary key default auth.uid() references auth.users on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now()
);
create table if not exists lw_pics (
  id text primary key,
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  path text not null,
  caption text default '',
  ts bigint not null
);
alter table lw_docs enable row level security;
alter table lw_crew enable row level security;
alter table lw_pics enable row level security;

drop policy if exists "own docs" on lw_docs;
create policy "own docs" on lw_docs for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "crew read" on lw_crew;
create policy "crew read" on lw_crew for select to authenticated using (true);
drop policy if exists "crew write own" on lw_crew;
create policy "crew write own" on lw_crew for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "pics read" on lw_pics;
create policy "pics read" on lw_pics for select to authenticated using (true);
drop policy if exists "pics write own" on lw_pics;
create policy "pics write own" on lw_pics for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

insert into storage.buckets (id, name, public) values ('lw-photos', 'lw-photos', true) on conflict (id) do nothing;
drop policy if exists "lw photos upload own" on storage.objects;
create policy "lw photos upload own" on storage.objects for insert to authenticated with check (bucket_id = 'lw-photos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "lw photos delete own" on storage.objects;
create policy "lw photos delete own" on storage.objects for delete to authenticated using (bucket_id = 'lw-photos' and (storage.foldername(name))[1] = auth.uid()::text);

do $$ begin
  begin alter publication supabase_realtime add table lw_crew; exception when others then null; end;
  begin alter publication supabase_realtime add table lw_pics; exception when others then null; end;
end $$;
