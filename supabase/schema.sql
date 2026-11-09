-- ANIME STREAM episode publishing schema
-- Run in Supabase SQL Editor. RLS protects all records.
create extension if not exists pgcrypto;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;
drop policy if exists "Admins can read own admin role" on public.admin_users;
create policy "Admins can read own admin role" on public.admin_users
for select to authenticated using (user_id = (select auth.uid()));

create table if not exists public.episodes (
  id uuid primary key default gen_random_uuid(),
  anime_id bigint,
  anime_title text not null,
  episode_number integer not null check (episode_number > 0),
  episode_title text,
  source_type text not null check (source_type in ('external_video','provider_link')),
  video_url text not null check (video_url ~ '^https://'),
  provider_name text,
  status text not null default 'published' check (status in ('draft','published')),
  rights_confirmed boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists episodes_publication_idx on public.episodes(status, anime_id, episode_number);
alter table public.episodes enable row level security;
drop policy if exists "Public can read published episodes" on public.episodes;
create policy "Public can read published episodes" on public.episodes
for select to anon, authenticated using (
  status = 'published' or exists (
    select 1 from public.admin_users a where a.user_id = (select auth.uid())
  )
);
drop policy if exists "Admins can insert episodes" on public.episodes;
create policy "Admins can insert episodes" on public.episodes
for insert to authenticated with check (
  exists (select 1 from public.admin_users a where a.user_id = (select auth.uid()))
  and (source_type = 'provider_link' or rights_confirmed = true)
);
drop policy if exists "Admins can update episodes" on public.episodes;
create policy "Admins can update episodes" on public.episodes
for update to authenticated using (
  exists (select 1 from public.admin_users a where a.user_id = (select auth.uid()))
) with check (
  exists (select 1 from public.admin_users a where a.user_id = (select auth.uid()))
  and (source_type = 'provider_link' or rights_confirmed = true)
);
drop policy if exists "Admins can delete episodes" on public.episodes;
create policy "Admins can delete episodes" on public.episodes
for delete to authenticated using (
  exists (select 1 from public.admin_users a where a.user_id = (select auth.uid()))
);

-- After creating your first admin user in Supabase Authentication > Users,
-- replace the UUID below with that user's actual ID and run:
-- insert into public.admin_users(user_id) values ('YOUR-AUTH-USER-UUID');
