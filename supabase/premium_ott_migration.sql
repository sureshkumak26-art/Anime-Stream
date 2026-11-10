-- ANIME STREAM premium OTT expansion (additive migration)
-- Apply after supabase/schema.sql in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.anime_catalog (
  id uuid primary key default gen_random_uuid(),
  anilist_id bigint unique,
  title text not null,
  description text,
  poster_url text,
  banner_url text,
  rating numeric(4,2),
  release_year integer,
  language text[] not null default '{}',
  genres text[] not null default '{}',
  status text not null default 'unknown' check (status in ('ongoing','completed','upcoming','unknown')),
  studio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.episodes add column if not exists anime_catalog_id uuid references public.anime_catalog(id) on delete cascade;
alter table public.episodes add column if not exists release_date date;

create table if not exists public.episode_servers (
  id uuid primary key default gen_random_uuid(),
  episode_id uuid not null references public.episodes(id) on delete cascade,
  server_name text not null,
  embed_url text not null check (embed_url ~ '^https://'),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create index if not exists episode_servers_episode_idx on public.episode_servers(episode_id, sort_order);

create table if not exists public.user_profiles (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 32),
  avatar_key text not null default 'violet',
  is_kids_profile boolean not null default false,
  created_at timestamptz not null default now(),
  unique(owner_user_id, display_name)
);
create index if not exists user_profiles_owner_idx on public.user_profiles(owner_user_id);

create table if not exists public.watch_progress (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.user_profiles(id) on delete cascade,
  episode_id uuid not null references public.episodes(id) on delete cascade,
  position_seconds integer not null default 0 check (position_seconds >= 0),
  duration_seconds integer not null default 0 check (duration_seconds >= 0),
  completed boolean not null default false,
  updated_at timestamptz not null default now(),
  unique(profile_id, episode_id)
);
create index if not exists watch_progress_profile_updated_idx on public.watch_progress(profile_id, updated_at desc);

create table if not exists public.profile_anime_list (
  profile_id uuid not null references public.user_profiles(id) on delete cascade,
  anime_id uuid not null references public.anime_catalog(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(profile_id, anime_id)
);

alter table public.anime_catalog enable row level security;
alter table public.episode_servers enable row level security;
alter table public.user_profiles enable row level security;
alter table public.watch_progress enable row level security;
alter table public.profile_anime_list enable row level security;

drop policy if exists "Public can read anime catalog" on public.anime_catalog;
create policy "Public can read anime catalog" on public.anime_catalog
for select to anon, authenticated using (true);
drop policy if exists "Admins manage anime catalog" on public.anime_catalog;
create policy "Admins manage anime catalog" on public.anime_catalog
for all to authenticated
using (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())))
with check (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));

drop policy if exists "Public can read active episode servers" on public.episode_servers;
create policy "Public can read active episode servers" on public.episode_servers
for select to anon, authenticated using (
  is_active and exists(select 1 from public.episodes e where e.id=episode_id and e.status='published')
);
drop policy if exists "Admins manage episode servers" on public.episode_servers;
create policy "Admins manage episode servers" on public.episode_servers
for all to authenticated
using (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())))
with check (exists(select 1 from public.admin_users a where a.user_id=(select auth.uid())));

drop policy if exists "Users manage own profiles" on public.user_profiles;
create policy "Users manage own profiles" on public.user_profiles
for all to authenticated
using (owner_user_id=(select auth.uid()))
with check (owner_user_id=(select auth.uid()));

drop policy if exists "Users manage own watch progress" on public.watch_progress;
create policy "Users manage own watch progress" on public.watch_progress
for all to authenticated
using (exists(select 1 from public.user_profiles p where p.id=profile_id and p.owner_user_id=(select auth.uid())))
with check (exists(select 1 from public.user_profiles p where p.id=profile_id and p.owner_user_id=(select auth.uid())));

drop policy if exists "Users manage own anime list" on public.profile_anime_list;
create policy "Users manage own anime list" on public.profile_anime_list
for all to authenticated
using (exists(select 1 from public.user_profiles p where p.id=profile_id and p.owner_user_id=(select auth.uid())))
with check (exists(select 1 from public.user_profiles p where p.id=profile_id and p.owner_user_id=(select auth.uid())));

grant select on public.anime_catalog to anon, authenticated;
grant select on public.episode_servers to anon, authenticated;
grant all on public.anime_catalog, public.episode_servers, public.user_profiles, public.watch_progress, public.profile_anime_list to authenticated;
