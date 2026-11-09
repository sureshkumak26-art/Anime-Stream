# ANIME STREAM

A responsive anime discovery frontend built with React + Vite.

## Features
- Anime catalog, search, genres, popularity/trending/top-rated sorting
- Anime detail pages with AniList metadata and posters
- Local watchlist saved in the browser
- Video player for user-supplied, authorized MP4/HLS URLs
- Responsive dark theme for mobile and desktop

## Run locally
```bash
npm install
npm run dev
```

## Build
```bash
npm run build
npm run preview
```

## Deploy free with Cloudflare Pages
1. Open https://dash.cloudflare.com/ and choose Workers & Pages.
2. Create application → Pages → Connect to Git.
3. Select `sureshkumak26-art/Anime-Stream` and branch `main`.
4. Framework preset: Vite. Build command: `npm run build`. Build output directory: `dist`.
5. Deploy. Later pushes to `main` trigger automatic deployments.

## Video and copyright
AniList supplies metadata and artwork references, not playable episode streams or streaming rights. The player accepts a URL entered by the site operator/user; only use videos you own or are licensed to distribute. This starter does not scrape third-party streaming sites or provide pirated episodes.

## Next steps
The current watchlist is browser-local. For accounts, synced watch progress, and a protected admin dashboard, configure a Supabase project and add server-side authorization before publishing admin features. Never commit API secrets or admin passwords to this repository.
