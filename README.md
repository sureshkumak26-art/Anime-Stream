# ANIME STREAM

A responsive anime discovery and authorized episode publishing site built with React + Vite.

## Features
- Anime catalog, search, genres, popularity/trending/top-rated sorting from AniList
- Anime details, posters, synopsis, and AniList-listed streaming provider links
- Browser-local watchlist
- Secure Supabase Auth admin sign-in with a database-backed admin allowlist
- Admin can import AniList-listed provider links and publish external-hosted MP4/HLS URLs
- Public episode catalog reads only published records; admins manage episodes through RLS
- Responsive dark theme

## Run locally
```bash
npm install
npm run dev
```

## Configure the secure admin backend
1. Create a Supabase project at https://supabase.com/dashboard.
2. In Supabase **SQL Editor**, run the complete `supabase/schema.sql` file from this repository.
3. In Supabase **Authentication → Users**, create/invite your own admin user. Disable public sign-ups if you do not need public account creation.
4. Copy that user's UUID from Authentication → Users. In SQL Editor, run:
   ```sql
   insert into public.admin_users(user_id) values ('PASTE-YOUR-ADMIN-USER-UUID');
   ```
   Only add trusted administrator UUIDs. Do not expose service-role keys.
5. In Cloudflare, open the `anime-stream` Worker project's **Build settings / environment variables** and add:
   - `VITE_SUPABASE_URL` = your Supabase Project URL
   - `VITE_SUPABASE_ANON_KEY` = your Supabase publishable key (or legacy anon key)
6. Trigger a new deployment. These `VITE_` values are embedded at build time; do not add the Supabase service-role key to Vite variables or browser code.
7. Open the site → **Admin** → sign in with the admin user you created.

The SQL schema enables row-level security. Visitors can read only published episodes. Only users explicitly present in `admin_users` can publish, edit, or delete. The browser key is a public/publishable key; authorization is enforced by Supabase Auth and RLS, not by hiding the Admin button.

## Publishing workflow
- **Official provider links:** Admin → Import official episode links → search the anime → Import links. The site stores the provider URLs and Watch buttons open the provider's own page.
- **Your licensed files:** Upload your video to an external video host first. Copy its direct HTTPS MP4/HLS playback URL, then Admin → Publish licensed episode. Confirm distribution rights before publishing. The file remains hosted by your provider; this app stores the playback URL and plays it on the anime page.
- External video hosts differ. Direct MP4 works in most browsers; HLS playback depends on browser support or a compatible player. Provider watch-page URLs should be added as provider links, not direct video URLs.

## Automation boundaries
AniList metadata and listed streaming links can be discovered automatically when the catalog loads. AniList does not provide video files or rights to redistribute them. External-host video uploads and recurring provider-specific imports require the chosen host's upload/API credentials and a scheduled server-side job; no host has been selected or connected yet. Never scrape or rehost unauthorized copyrighted episodes.

## Build and deploy
```bash
npm run build
```
Cloudflare Worker deploys from the connected GitHub branch after each push. The current deployment uses the Vite build output in `dist`.
