# Sanketa Feature Research — TV Speed-Up & Ad Reduction

> Synthesized from 8 open-source repos (2026-11-14)

---

## Repos Analyzed

| # | Repo | Stars | What it does |
|---|------|-------|-------------|
| 1 | **tv-town-launcher** | ~1k | Android TV launcher with "Speed Up Your TV" one-press debloat |
| 2 | **LibreTV** | ~2k | HLS player with ad-segment filtering and multi-source aggregation |
| 3 | **cleanyourtv** | ~5k | ADB debloat tool with per-model disable lists for 100+ TV models |
| 4 | **TVAPP** | ~1k | Curated Android TV app directory with IPTV source lists |
| 5 | **my-tv** | 32k | Ad-free IPTV player for Android TV, install-and-use |
| 6 | **iptv-org/iptv** | 144k | Largest public IPTV channel collection (M3U, organized by country) |
| 7 | **Free-TV/IPTV** | 22k | Free-to-air channel playlists for 100+ countries |
| 8 | **awesome-iptv** | 13k | Curated resource index — players, tools, EPG sources per platform |

---

## Recommended Features (by priority)

### F1. "Speed Up Your TV" — ADB Debloat Tool

**Source:** tv-town-launcher (CleanupActivity), cleanyourtv (disable.sh/restore.sh)

**What it does:**
- One-tap disables bloatware, ad services, telemetry, and sponsored rows on the TV
- Uses `pm disable-user --user 0 <package>` — nothing uninstalled, fully reversible
- Per-brand safe lists: cleanyourtv ships 45 Xiaomi lists, 23 Philips, 17 Skyworth, 16 Hisense, 12 TCL, plus Sony, Samsung, LG, Haier, Vizio, etc.
- One button restores everything (`pm enable`)
- Samsung/LG/Roku ad tracking can be disabled via remote settings (no ADB needed)

**Why it fits Sanketa perfectly:**
- Sanketa already establishes an ADB-level connection for Android TV pairing
- Aligns with our "zero third-party ads" philosophy
- Reversible approach is safe — user can undo instantly
- Per-model lists cover every TV brand Sanketa supports
- Runs entirely on-device, no server calls

**Implementation plan:**
1. Bundle cleanyourtv's tested per-model debloat lists as a JSON asset (brand → package list)
2. New `DebloatService` in `sanketa_core` that runs `pm disable-user` / `pm enable` via ADB shell
3. UI: "Speed Up" card on Devices screen with brand auto-detect, toggle switches per category (ads, telemetry, bloat), and one-tap restore
4. `tools/audit.py` logic (discover voice/ACR/telemetry candidates) can be ported to Dart for auto-detection

**Effort:** Medium (2-3 weeks)
**Risk:** Low — `pm disable-user` is user-scoped and fully reversible

---

### F2. Free TV — Built-in IPTV/M3U Player

**Source:** iptv-org/iptv (channel database), Free-TV/IPTV (free-to-air lists), my-tv (player UX), awesome-iptv (EPG sources)

**What it does:**
- M3U/M3U8 playlist parser with XMLTV EPG (Electronic Program Guide)
- Pre-loaded with free-to-air channels organized by country (India, US, UK, etc.)
- Channel grid with logos, categories, and live EPG data
- User can add custom M3U playlist URLs
- Source health monitoring — auto-disable dead channels, show uptime badges
- Favorite channels and recently watched

**Why it fits Sanketa:**
- Free-to-air channels are legally broadcast public content — no DRM circumvention
- iptv-org community maintains the world's largest channel database (144k stars)
- India-specific channels from Free-TV/IPTV cover DD National, regional channels
- Entirely client-side — no Sanketa server needed
- Massive differentiation from basic remote apps

**Implementation plan:**
1. New `sanketa_iptv` package: M3U parser, XMLTV EPG parser, HLS player integration
2. Bundle country playlists from Free-TV as default sources (just M3U URLs, not streams)
3. EPG data fetched directly from iptv-org/epg endpoints (public, no auth)
4. New "Live TV" tab in app shell alongside Remote, Search, Cast, Devices
5. Cast integration — stream to TV via DLNA/Cast adapter

**Effort:** Large (4-6 weeks)
**Risk:** Low — we're linking to public streams, not hosting content

---

### F3. HLS Ad-Segment Filtering

**Source:** LibreTV (ad segment detection), my-tv (clean playback)

**What it does:**
- When playing IPTV streams via HLS, detect ad segments by analyzing:
  - Discontinuity tags in HLS manifests (`#EXT-X-DISCONTINUITY`)
  - SCTE-35 markers (ad insertion cues in broadcast streams)
  - Segment duration anomalies (ads are often 15/30/60s blocks)
- Auto-skip detected ad segments with visual progress bar markers
- Configurable: auto-skip, show skip button, or do nothing

**Why it fits Sanketa:**
- Operates at the HLS manifest level, not bypassing DRM
- Similar to browser ad-blocking — filtering publicly marked segments
- Dramatically improves free channel experience
- Runs locally on phone, no server involvement

**Implementation plan:**
1. Add to `sanketa_iptv` package: HLS manifest parser that reads SCTE-35 and discontinuity markers
2. Mark ad segments on the player timeline
3. Auto-skip or show "Skip Ad" button based on user preference
4. Ship as opt-in setting in IPTV player

**Effort:** Medium (2-3 weeks, after F2)
**Risk:** Medium — ad detection heuristics need tuning per source

---

### F4. TV Performance Dashboard

**Source:** cleanyourtv (tools/check.py, performance measurement)

**What it does:**
- Real-time TV health stats: CPU usage, memory pressure, running process count
- Key press latency measurement (how responsive is the TV?)
- Jank frame detection via `dumpsys gfxinfo`
- App cold-start time measurement
- Before/after comparison when running Speed Up (F1)
- Recommendations: "Your TV has 14 background processes using 80% RAM — Speed Up can free 40%"

**Why it fits Sanketa:**
- Uses data already available via ADB connection
- Provides tangible proof that Speed Up works
- Differentiates from every other remote app

**Implementation plan:**
1. `TvHealthService` in `sanketa_core` that queries `dumpsys meminfo`, `dumpsys cpuinfo`, `dumpsys gfxinfo`
2. Dashboard card on Devices screen showing key metrics
3. Before/after snapshots when running debloat

**Effort:** Small (1-2 weeks)
**Risk:** Low — read-only ADB commands

---

### F5. Continue Watching Aggregation

**Source:** tv-town-launcher (Continue Watching row)

**What it does:**
- Aggregate "continue watching" / "recently played" across streaming apps on the TV
- Show progress bars (how far through each show)
- One tap resumes in the correct app (Netflix, Prime, etc.)

**Why it fits Sanketa:**
- High user value — saves the "which app was I watching on?" friction
- Can be implemented via Android TV's `TvContractCompat` / `WatchNext` API
- No Sanketa server needed

**Implementation plan:**
1. Query `content://android.media.tv/watch_next_program` via ADB
2. Display as a card on the Remote screen
3. Deep-link to resume in the correct app

**Effort:** Medium (2-3 weeks)
**Risk:** Medium — requires Android TV content provider access, may not work on all brands

---

## Features NOT Recommended

These were found in the repos but violate Sanketa's PRD constraints:

| Feature | Why not |
|---------|---------|
| Custom launcher replacement | Too invasive, risk of bricking, requires system-level access |
| YouTube downloading (tv-town-launcher) | Copyright/DRM concern — PRD says "No DRM circumvention of any kind" |
| Third-party app sideloading repo (TVAPP) | Security risk, potential malware vector |
| Phone-as-game-controller (tv-town-launcher) | Out of scope for remote control, adds complexity |
| Music visualizer/karaoke (tv-town-launcher) | Feature creep, not core to TV control or speed-up |
| TVBox config import (LibreTV) | Primarily for piracy-adjacent content aggregation |

---

## Priority Roadmap

```
Phase 1 (Next 4 weeks):
  F1  Speed Up Your TV ← highest impact, builds on existing ADB
  F4  TV Performance Dashboard ← low effort, supports F1 story

Phase 2 (Weeks 5-10):
  F2  Free TV (IPTV Player) ← biggest feature, massive differentiation
  F3  HLS Ad Filtering ← enhances F2

Phase 3 (Weeks 11-14):
  F5  Continue Watching ← nice-to-have, brand-dependent
```

---

## Key Data Assets to Bundle

| Asset | Source | Size | Format |
|-------|--------|------|--------|
| Per-model debloat lists | cleanyourtv | ~200 KB | JSON (brand → packages) |
| Country IPTV playlists | Free-TV/IPTV | URLs only | M3U URLs in JSON catalog |
| EPG sources | iptv-org/epg | URLs only | XMLTV endpoint list |
| Channel database | iptv-org/database | ~500 KB | JSON (name, logo, country, language) |

---

## PRD Compliance Check

Every recommended feature passes all 10 PRD constraints:

- [x] Zero third-party ads — these features **remove** ads
- [x] No DRM circumvention — debloat uses standard Android APIs; IPTV uses free-to-air streams
- [x] Control plane makes zero calls to Sanketa servers — all processing is on-device
- [x] No account required — everything works without sign-in
- [x] No private-API use — `pm disable-user`, `dumpsys`, content providers are all public Android APIs
- [x] IR path works fully offline — these features are network-dependent but don't affect IR
- [x] Pairing secrets in hardware-backed stores — no new secrets introduced
- [x] No raw error codes — all failures get human explanations
- [x] Never paywall basic control — these are additive features
- [x] Typed text never logged — IPTV search is local only
