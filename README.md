# ANIME STREAM

A responsive anime discovery and authorized episode publishing site built with React + Vite.

## Features
- Anime catalog, search, genres, popularity/trending/top-rated sorting from AniList
- Anime details, posters, synopsis, and AniList-listed streaming provider links
- Browser-local watchlist
- Secure Supabase Auth admin sign-in with a database-backed admin allowlist
- Admin can import AniList-listed provider links and upload licensed video files directly to Vimeo using resumable TUS uploads
- Vimeo upload sessions are created by an authenticated Cloudflare Worker; the Vimeo token never reaches the browser
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
6. In Cloudflare Worker **Settings → Variables and Secrets**, add runtime variables `SUPABASE_URL` (same project URL) and `SUPABASE_ANON_KEY` (same publishable/anon key). These are used by the Worker to verify the Supabase session and admin role. Do not use a service-role key.
7. Add `VIMEO_ACCESS_TOKEN` as an encrypted Worker **Secret** on the `anime-stream` Worker. The Vimeo token must have `upload` and `edit` scopes, and the Vimeo app/account must have API upload access enabled. Never add it as a `VITE_` variable or commit it.
8. Keep `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in the Cloudflare build environment so the browser Admin login can connect to Supabase.
9. Trigger a new deployment. The `wrangler.jsonc` config routes `/api/*` to the Worker and serves the Vite `dist` assets for all other paths.
10. Open the site → **Admin** → sign in with the admin user you created.

The SQL schema enables row-level security. Visitors can read only published episodes. Only users explicitly present in `admin_users` can publish, edit, or delete. The browser key is a public/publishable key; authorization is enforced by Supabase Auth and RLS, not by hiding the Admin button.

## Publishing workflow
- **Official provider links:** Admin → Import official episode links → search the anime → Import links. The site stores the provider URLs and Watch buttons open the provider's own page.
- **Your licensed files:** In Admin → Publish licensed episode, select a video file and confirm that you own or have distribution rights. Choose **Upload file to Vimeo & publish**. The browser uploads the file directly to Vimeo in resumable chunks; the Cloudflare Worker only creates the authenticated Vimeo upload session. The app stores the Vimeo player embed URL and plays it in an iframe.
- External video hosts differ. Direct MP4 works in most browsers; HLS playback depends on browser support or a compatible player. Provider watch-page URLs should be added as provider links, not direct video URLs.

## Automation boundaries
AniList metadata and listed streaming links can be discovered automatically when the catalog loads. AniList does not provide video files or rights to redistribute them. Vimeo uploads are manual admin actions; scheduled imports and automatic episode discovery are not enabled yet. Never scrape or rehost unauthorized copyrighted episodes.

## Build and deploy
```bash
npm run build
```
Cloudflare Worker deploys from the connected GitHub branch after each push. The current deployment uses the Vite build output in `dist`.

## Premium OTT blueprint (in progress)

The `feature/premium-ott-blueprint` branch adds:
- First-launch profile picker and profile-specific local watchlists.
- An additive Supabase migration for account-owned profiles, watch progress, saved anime, anime catalog metadata, and multiple episode servers.
- Admin controls to add/remove multiple HTTPS embed servers for each published episode.
- Viewer-side server choices, with iframe embeds and direct MP4/HLS playback handling.

### Apply the OTT database migration
After the original `supabase/schema.sql` has been applied, run the complete `supabase/premium_ott_migration.sql` file in Supabase SQL Editor. This adds the new tables and row-level security policies without dropping the existing episode publishing setup.

### Current implementation boundaries
- Profile selection and per-profile My List are currently stored in the browser on that device. The new Supabase profile/watch-progress tables are ready for account-linked synchronization, but end-user account sign-in and cross-device sync still need to be wired into the app.
- The current public catalog continues to use AniList metadata. The new admin-managed anime catalog table is a backend foundation; full catalog CRUD and merging it into discovery are still pending.
- Streaming server URLs must be authorized HTTPS embed URLs or direct video URLs you own or have permission to distribute. Some third-party hosts may block iframe embedding or fullscreen; the player cannot override restrictions imposed by those hosts.
- No unauthorized scraping, copying, or automatic redistribution of copyrighted episodes is included.
