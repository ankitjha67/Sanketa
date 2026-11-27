# SANKETA (संकेत)
## Universal TV Remote and Casting Platform for Mobile
### Product Requirements Document

| Field | Value |
|---|---|
| Document version | v0.4 |
| Status | Phase 0 in progress; OD-2 + OD-3 + OD-6 decided; 6 open decisions remain (Section 20); FR-11–FR-15 (value-add features) specified and built |
| Date | 14 November 2026 |
| Product owner | Ankit Jha |
| Working name | SANKETA (Sanskrit: signal, gesture). Alternates in Section 20 |
| Classification | Internal, pre-build |
| Companion document | [CONTEXT.md](CONTEXT.md) — live project status, decision log, build tracker |

Naming note: SANKETA is a working title chosen because the product's entire job is moving signals (IR pulses, network commands, cast streams) from hand to screen. It is a reversible decision and is listed as Open Decision OD-1.

**Document pairing.** This PRD is authoritative for *requirements*: what gets built, why, and to what acceptance bar. [CONTEXT.md](CONTEXT.md) is authoritative for *status*: what is decided, what is built, what is next. Feature additions and removals are recorded here (with the change log in Section 22); progress is recorded there. Neither document is updated without the other being checked.

---

## 1. Executive Summary

SANKETA is a mobile application (Android and iOS) that turns a phone into the only remote a household needs. It does three things:

1. **Controls any TV.** Over infrared for phones with IR blasters (and for any TV ever made, including non-smart TVs), and over the local network for every major smart TV platform (Google TV/Android TV, Samsung Tizen, LG webOS, Roku, Sony BRAVIA, Fire TV, Vizio SmartCast, Panasonic, Philips, Hisense VIDAA, TCL) using each platform's native control protocol.
2. **Kills arrow-key typing.** The hero feature: when a search box or login field is on the TV screen, the user types on their phone's full keyboard (or speaks) and the text lands on the TV instantly. Searching YouTube on a TV today means pecking letters one arrow-press at a time on an on-screen grid; SANKETA reduces a 45 second, 30+ button-press ordeal to a 3 second typed query.
3. **Casts anything on the same WiFi.** Local photos, videos, and music from the phone to the TV (via Google Cast, DLNA/UPnP, Roku, AirPlay-capable paths, and a web receiver fallback), full screen mirroring, and web video hand-off.

The strategy for "all devices from all providers" is a **fallback ladder**: native network adapter first (richest control, enables the keyboard), generic protocols second (Cast, DIAL, DLNA), infrared third (works on literally every TV with an IR receiver, which is effectively all of them), and an external WiFi-to-IR bridge (BroadLink class devices) as the escape hatch for iPhones and IR-less Android phones facing non-smart TVs.

Recommended build order: Android-first MVP covering IR plus the top five network platforms and the universal keyboard, then iOS, then the long tail of brands and screen mirroring. Recommended monetization: freemium subscription with a lifetime unlock, zero ads (Section 15 explains why ads killed this category's last leader).

---

## 2. Problem Statement

**The core problem.** TV input is the single worst mainstream UI surviving in consumer technology. Three concrete pains:

1. **Text entry is hostile.** Typing "lofi study music 2 hours" on a TV on-screen keyboard requires 30 to 60 directional presses and routinely over 45 seconds, with a high error and abandonment rate. Every search, every WiFi password, every login on a new TV or after a reset goes through this. This is the pain the product exists to solve and the reason a user opens the app daily rather than once.
2. **Remote fragmentation.** A typical household juggles a TV remote, a set-top box remote, a soundbar remote, and sometimes a streaming stick remote. Remotes get lost, batteries die, buttons wear out. Each OEM's companion app controls only that OEM's devices, so a Samsung TV in the bedroom and a Mi TV in the living room need two different apps with two different UX models.
3. **Casting is inconsistent.** Whether a phone can send a photo, a video, or its screen to a TV depends on an opaque matrix of phone OS, TV platform, and app support. Users do not know which of Cast, AirPlay, Miracast, or DLNA their setup supports; they just know "it sometimes works on the other TV."

**Who experiences it.** Every smart TV household (over 1.1 billion homes globally are projected to own a smart TV in 2026, per industry syntheses), and acutely: multi-brand households, households whose remote is lost or broken, travelers in hotels, and anyone helping less technical family members operate a TV remotely-by-instruction ("press down three times, now right...").

**Cost of not solving.** For users: daily friction and abandoned intents (searches never typed, content never found). For the market: OEM apps solve only their own silo; the previous cross-brand leaders exited (Logitech Harmony discontinued in 2021, Peel collapsed after an adware death spiral, AnyMote was abandoned), leaving demonstrated demand with no trustworthy cross-brand incumbent.

---

## 3. Market and Competitive Landscape

### 3.1 Market context (figures gathered August 2026; re-verify before investor use)

- Smart TV platform shipment share (TechInsights, Q4 2024): Android/Google TV over 24 percent, Samsung Tizen about 17 percent, LG webOS about 12 percent, Roku about 9 percent. US installed-base pictures differ sharply (Kagan): Roku about 25 percent, Fire TV about 17 percent, Tizen and Android TV about 14 percent each, webOS 9 percent, Vizio SmartCast 7 percent. Conclusion: platform priority depends on launch geography; India skews heavily Android TV/Google TV plus Fire TV sticks; the US skews Roku plus Fire TV.
- IR-blaster phones remain a large, India-concentrated segment: 91mobiles lists over 500 phone models with IR blasters as of August 2026 (Xiaomi/Redmi/POCO, OnePlus, iQOO, vivo, Oppo, select Motorola). Samsung, Apple, and Google phones ship none. Implication: IR-in-phone is an Android-and-mostly-India strength; iOS parity requires network control plus an optional external IR bridge.
- Matter Casting (the CSA open casting standard) remains effectively Amazon-only on the receiver side (Fire TV, Echo Show; Panasonic announced) as of mid-2026. Treat as a watch item and design the adapter layer so a Matter Casting adapter can slot in later; do not build on it now.
- India specifics (primary launch market candidate): Android TV/Google TV dominates smart TV sales (Xiaomi, TCL, OnePlus, Sony, Hisense, plus Samsung/LG at the premium end); Fire TV Stick is the leading external streamer; cable/DTH set-top boxes (Tata Play, Airtel, Dish) remain IR-controlled in tens of millions of homes, which makes phone IR genuinely useful, not a gimmick.

### 3.2 Competitive map

| Class | Examples | Strengths | Exploitable weaknesses |
|---|---|---|---|
| OEM companion apps | Google TV app, Samsung SmartThings, LG ThinQ, Roku app, Fire TV app | Free, official, reliable pairing, good keyboards for their own platform | Single-brand silo; no IR; no cross-brand casting; feature depth varies |
| Preinstalled IR apps | Mi Remote (Xiaomi/POCO/Redmi) | Ships on the device; large IR code DB; strong in India | Xiaomi phones only; weak network control; dated UX; no unified casting |
| Cross-brand remote apps | SURE Universal, "Universal TV Remote" cluster, CetusPlay, BoostVision apps | Prove demand; some multi-protocol | Ad-saturated, low trust, spotty pairing reliability, weak or absent text input, abandoned codebases |
| Casting-only apps | AirBeamTV suite, "TV Cast" cluster, LocalCast, BubbleUPnP | Deep single-purpose casting | No control plane, no IR, per-brand paid apps fragment the purchase |
| Dead precedents | Logitech Harmony (hardware, exited 2021), Peel (adware collapse), AnyMote (abandoned) | Validated the category | Their exits are the opening; Peel is the cautionary tale for ad monetization |

### 3.3 Positioning

One app, every brand, both directions (control in, cast out), keyboard-first, and aggressively trustworthy: no ads, no lock-screen takeover, control plane fully local with no account required. The wedge feature is the universal keyboard; the moat is breadth times reliability of the protocol adapter matrix, which compounds with every firmware quirk handled.

---

## 4. Target Users and Personas

**P1: The multi-brand Indian household (primary).** Rohan, 34, Gurugram. Mi TV in the living room (Android TV), Samsung in the bedroom, Tata Play set-top box, LG AC. Owns a POCO phone with an IR blaster. Wants one app for all of it; searches YouTube on the TV daily; the STB remote is half-broken.

**P2: The iPhone premium household.** Meera, 29, Bengaluru. iPhone 15, LG C-series OLED, Fire TV Stick 4K. No IR on her phone and does not care; wants flawless network control, instant keyboard for Netflix and YouTube search, and photo/video casting from her camera roll at family gatherings.

**P3: The remote-parent helper.** Ankit sets up the app on his parents' phones for their Sony BRAVIA; needs pairing to be one-tap, the remote layout to be large and simple, and a "simple mode" that hides everything but power, volume, navigation, and three app shortcuts.

**P4: The traveler / power user.** Hotel rooms, offices, friends' houses. Wants fast discovery on any network, IR fallback when the hotel TV blocks network control (they usually do), and macros ("Movie night": TV on, HDMI 2, soundbar volume 40 percent) at home.

**Anti-persona (explicitly not served in v1):** the home automation maximalist who wants full smart home orchestration (lights, locks, scenes across ecosystems). SANKETA controls the TV stack and nearby IR appliances; it is not a Home Assistant replacement.

---

## 5. Product Vision, Goals, and Non-Goals

### 5.1 Vision
Every screen in reach of your phone should be controllable and castable from it in under five seconds, with your phone's keyboard replacing the arrow-key grid forever.

### 5.2 Goals (outcome-form, measurable)

| ID | Goal | Target | Measurement window |
|---|---|---|---|
| G-1 | Fast first success | Median time from first app open to first successful TV command under 90 seconds | First 30 days post-launch |
| G-2 | Keyboard becomes the habit | At least 40 percent of weekly active users use remote text input at least once per week | Day 60 review |
| G-3 | Cross-brand coverage | At least 90 percent of discovery scans in smart TV households surface at least one controllable device | Rolling |
| G-4 | Reliability users can feel | p95 command latency under 250 ms on network control, under 100 ms tap-to-emit on IR; crash-free sessions at or above 99.5 percent | Rolling |
| G-5 | Retention appropriate to a utility | D30 retention at or above 25 percent; W12 at or above 15 percent | Quarterly |
| G-6 | Monetization without trust damage | 2 to 4 percent free-to-paid conversion at month 6 with app store rating at or above 4.3 | Month 6 |

### 5.3 Non-Goals (v1)

1. **General smart home control** (lights, locks, thermostats beyond IR ACs). Rationale: different competitive set, different reliability bar; dilutes the wedge.
2. **DRM circumvention of any kind.** Mirroring will show black frames on DRM-protected apps (Netflix, Prime Video); the product states this honestly instead of working around it. Legal and store-policy red line.
3. **Cloud relay control (out-of-home).** Control plane is local-network only in v1. Remote-from-anywhere is a P2 exploration with real security implications.
4. **Custom TV-side receiver app as a v1 dependency.** A TV-side helper app (for enhanced mirroring) is Phase 2+; v1 must work with zero TV-side installs.
5. **Voice assistant platform integration** (Alexa/Google Assistant skills). Later; the in-app mic covers the voice-typing need.
6. **Windows/desktop clients.**

---

## 6. User Stories (grouped, priority-ordered)

### Control
- US-1 (P0): As a multi-TV household member, I want the app to find every controllable TV and streaming device on my WiFi automatically, so that I never enter an IP address.
- US-2 (P0): As a user whose phone has an IR blaster, I want to control my TV, set-top box, and AC even when they are not on WiFi, so that the app replaces every physical remote in the drawer.
- US-3 (P0): As a user, I want a full remote (power, volume, mute, D-pad, back, home, inputs, media transport, number pad) with haptic feedback, so that it feels at least as fast as the physical remote.
- US-4 (P0): As a user, I want a trackpad-style gesture surface as an alternative to the D-pad, so that navigation feels like a phone, not a grid.
- US-5 (P1): As the family tech support person, I want a "simple mode" layout for my parents, so that they cannot get lost.

### Text input (hero)
- US-6 (P0): As a YouTube-on-TV user, I want to tap a keyboard icon when a search field is on screen and type on my phone with the text appearing live on the TV, so that searching takes seconds, not a minute of arrow-pecking.
- US-7 (P0): As a user, I want to speak instead of type and have the transcription land in the TV field, so that I can search hands-busy.
- US-8 (P1): As a user, I want submit, backspace, and clear from my phone keyboard to act on the TV field, so that I never touch the arrow keys mid-edit.
- US-9 (P1): As a Roku or Google TV user, I want a search shortcut that opens the platform search pre-filled with my query, so that I can skip navigating to the search screen entirely.

### Casting
- US-10 (P0): As a user, I want to pick photos or videos from my phone and play them on the TV over the same WiFi, so that family viewing does not require cables or brand-matched hardware.
- US-11 (P1): As a user, I want to cast my phone screen to the TV, so that anything without a native cast path can still be shown, understanding DRM apps will not display.
- US-12 (P1): As a user, I want to send a web video I am viewing in the in-app browser to the TV, so that the big screen plays it while my phone stays free.
- US-13 (P1): As a music listener, I want a queue with next/previous and background playback control, so that casting audio behaves like a real player.

### Household
- US-14 (P1): As a multi-room household, I want devices named and grouped by room with instant switching, so that "Bedroom TV" is one tap away.
- US-15 (P2): As a power user, I want macros that fire sequences across devices (IR and network mixed), so that "Movie night" is one button.
- US-16 (P2): As a frequent user, I want home-screen widgets and quick-settings tiles for power, volume, and keyboard, so that common actions skip opening the app.

---

## 7. Scope: Capability Pillars

| Pillar | One-line definition | MVP? |
|---|---|---|
| A. Discovery and pairing | Find and authenticate against every controllable device on the LAN, plus IR device setup | Yes |
| B. Control plane | Full remote semantics over native network protocols and IR | Yes |
| C. Universal text input | Phone keyboard and voice to TV text fields | Yes |
| D. Media casting | Phone-local photos, video, audio to TV renderers | Yes |
| E. Screen mirroring | Phone display to TV, best-effort, DRM-honest | Phase 2 |
| F. Web video hand-off | In-app browser video to TV | Phase 2 |
| G. Household layer | Rooms, multi-device, macros, widgets, wearables | Phase 2-3 |
| H. Bridge hardware | BroadLink-class WiFi-to-IR bridges for iPhone and IR-less phones | Phase 2 |
| I. TV tools | ADB-based debloat, performance monitoring, and app management for Android TV | Phase 1 |
| J. Free TV / IPTV | M3U playlist browsing and casting of free IPTV channels | Phase 1 |
| K. HLS ad filtering | Transparent SCTE-35/discontinuity-based ad-segment removal from HLS streams | Phase 1 |

---

## 8. Functional Requirements

Priorities: P0 = MVP cannot ship without it. P1 = fast follow, targeted within two releases of MVP. P2 = designed-for but deferred. Every FR lists acceptance criteria (AC) in checklist or Given/When/Then form. FR numbering is stable for traceability into the build tracker.

### FR-1: Onboarding and Device Discovery (P0)

**FR-1.1 Zero-input discovery.** On first launch (after permission grants) the app scans the LAN and lists every recognizable device with brand, model where available, and control capability badges (Control, Keyboard, Cast).
- Discovery mechanisms, run in parallel with a unified result merger: mDNS/Bonjour service browsing (Google Cast `_googlecast._tcp`, Android TV remote `_androidtvremote2._tcp`, AirPlay `_airplay._tcp`, Roku, others), SSDP/UPnP M-SEARCH (DLNA MediaRenderer, DIAL, brand-specific URNs), and targeted TCP probes on known control ports for brands that advertise poorly (Section 13.2 matrix).
- AC: Given a network with a Google TV, a Samsung Tizen TV, and a Roku, When the user completes onboarding, Then all three appear within 6 seconds with correct brand identification and capability badges.
- AC: Repeated scans deduplicate devices across discovery methods (same device found via mDNS and SSDP appears once).
- AC: Scan completes gracefully on networks with AP/client isolation: the app detects the condition (zero responses plus gateway reachable) and explains it with a fix suggestion (hotel WiFi note, router setting), rather than showing an empty list silently.

**FR-1.2 Permission choreography.** Local network access (iOS), nearby devices / fine location as required per Android version, notifications (optional), microphone (deferred until first voice use).
- AC: iOS shows a pre-permission explainer screen before the system Local Network prompt; if denied, the app surfaces a one-tap path to Settings and offers IR-bridge and manual-IP alternatives. This is a top-of-funnel risk (Section 17, R-2) and gets its own analytics events.
- AC: No permission is requested before the screen that explains why it is needed.

**FR-1.3 Manual add.** By IP address, by brand-plus-model (IR path), or by QR/code pairing where a platform supports it.
- AC: A TV reachable at a typed IP is added and controllable without any successful broadcast discovery.

**FR-1.4 Pairing flows per platform.** Each network adapter implements the platform's native authentication: on-screen PIN (Android TV remote protocol pairing, Philips digest auth), on-TV allow prompt (Samsung token grant, LG webOS pairing prompt), pre-shared key entry (Sony BRAVIA PSK or PIN flow), no-auth-with-confirmation (Roku ECP, where enabled), and ADB-authorization flow for Fire TV advanced control (explicitly optional; see FR-3.6).
- AC: Pairing state (tokens, client keys, certificates) is stored encrypted (Android Keystore / iOS Keychain) and survives app restarts and TV reboots.
- AC: A revoked or expired token triggers an in-context re-pair flow, not a silent failure: Given a Samsung TV whose token was revoked, When the user presses any key, Then within 2 seconds the app shows "Re-approve on your TV" with the prompt already triggered.
- AC: Pairing success rate per attempt is instrumented per brand and firmware string.

### FR-2: Infrared Control Subsystem (P0, Android with IR hardware; bridge path P2)

**FR-2.1 Hardware detection.** Detect `ConsumerIrManager` availability and supported carrier frequency ranges; expose IR features only where hardware exists, with an honest explainer (and bridge upsell, Phase 2) elsewhere. iOS never shows phone-IR UI.
- AC: On a POCO/Redmi class device, IR setup is offered during onboarding; on a Pixel, it is not, and the "why" is one tap away.

**FR-2.2 IR code database.** Ship a curated on-device database covering TVs, set-top boxes, AC units, soundbars, and projectors for the top brands per launch geography, assembled from permissively licensed sources (Flipper-IRDB, LIRC exports) plus the Kookong commercial database and internally captured codesets; normalized to a single internal representation (protocol family plus parameters, with raw timing/compact-format fallback for oddballs).
- Requirement: full offline function. The control path never requires the network.
- Requirement: database updates ship out-of-band from app releases (signed delta packs).
- ~~Legal gate (blocking, Section 20 OD-6): license audit of every imported codeset source; commercial DB licensing (UEI QuickSet class) evaluated as a paid alternative if gaps or license risk are material.~~ **OD-6 RESOLVED (11 Oct 2026):** dual-source — open-source Flipper IRDB (CC0, 1,074 codesets) + Kookong database (9,476 codesets extracted). **10,550 total codesets, 2,907 brands bundled.**
- AC: Top 25 TV brands and top 10 STB brands for India covered at launch with at least power, volume, mute, navigation, OK, back, home, input, and digits per codeset. **Status: exceeded — 4,306 TV codesets, 3,171 STB codesets bundled across 2,907 brands.**

**FR-2.3 Guided codeset matching.** The classic "press Power; did the TV turn off?" wizard, ordered by codeset popularity for the selected brand, with a long-press test grid for ambiguous cases.
- AC: Given a brand with 12 candidate codesets, When the user follows the wizard, Then median time to a confirmed working codeset is under 60 seconds and the confirmed choice is saved to the device profile.

**FR-2.4 IR emission quality.** Correct carrier frequency per code; pattern pre-compilation for sub-100 ms tap-to-emit; repeat-frame handling for volume hold-down; interleaving guard so rapid taps queue rather than truncate.
- AC: Volume-up held for 2 seconds produces continuous ramp on a reference Samsung and LG panel, matching physical remote behavior.

**FR-2.5 Beyond the TV.** AC units (stateful IR: mode/temp/fan encoded per frame, requiring full-state codesets), soundbars, projectors, and STBs are first-class IR device types with type-appropriate layouts.
- AC: An AC profile changes temperature in single-degree steps with on-screen state mirroring (best-effort, with a "state may drift" disclaimer since IR is one-way).

**FR-2.6 No IR learning on phones.** Phones lack IR receivers; the app does not pretend otherwise. Learning is offered only via bridge hardware (FR-8) that supports capture mode.

### FR-3: Network Control Subsystem (P0 for top five platforms; remaining brands P1)

A shared adapter contract (Section 13.3) with per-platform implementations. MVP adapters: Android TV/Google TV, Samsung Tizen, LG webOS, Roku, Sony BRAVIA. Phase 2 adapters: Fire TV, Vizio SmartCast, Panasonic, Philips, Hisense VIDAA, TCL (routes to Roku/Google/native by model), generic DLNA renderer.

**FR-3.1 Command coverage per adapter (P0 set).** Power (on where the platform supports wake: WoL/WoWLAN or protocol-native; off always), volume/mute (or device-volume passthrough where the platform routes volume), D-pad plus OK/back/home, media transport, input/source switching, app launch (FR-6), and text input capability flags consumed by FR-4.
- AC: A conformance test suite runs the full command set against at least one physical device per adapter and one emulated endpoint per adapter in CI; an adapter cannot ship with under 95 percent conformance on its declared command set.

**FR-3.2 Session behavior.** Persistent connections (WebSocket/TLS socket) with heartbeat, exponential backoff reconnect, and sub-second command dispatch after app foreground.
- AC: Given the app returns to foreground after 30 minutes, When the user taps volume-up, Then the command lands in under 1 second (reconnect included) at p95.

**FR-3.3 Power-on paths.** Wake-on-LAN/WoWLAN magic packets with per-brand quirks (some TVs require the feature toggled in TV settings; the app detects failure and shows the exact TV-side setting path per brand).
- AC: On an LG webOS and Samsung Tizen reference device with WoWLAN enabled, power-on from standby succeeds at or above 90 percent of attempts on the same subnet.

**FR-3.4 State readback where available.** Volume level, mute state, current app, power state polled or subscribed per platform capability, reflected in UI within 1 second; where a platform is write-only, the UI omits state claims instead of guessing.

**FR-3.5 Graceful capability degradation.** Every adapter declares its capability matrix; the remote UI renders only what the target supports, so users never press dead buttons.
- AC: Connecting to a DLNA-only renderer shows media transport and volume, not a D-pad.

**FR-3.6 Fire TV advanced path (P1, opt-in).** Baseline Fire TV control via DIAL app-launch plus network remote where available; advanced control (full keys, text) via ADB over network as an explicit power-user opt-in with a guided "enable ADB debugging" walkthrough, prominent security note, and default-off.

### FR-4: Universal Text Input, the Hero Feature (P0)

**FR-4.1 Live typing injection.** A keyboard surface in the app streams text to the focused TV field using each platform's native mechanism: Android TV remote protocol text events; Samsung WebSocket text-input channel; LG webOS IME service (insert/delete); Roku ECP literal key events; Sony BRAVIA text-form API; Fire TV via ADB text path when the opt-in (FR-3.6) is active. Adapter capability flag: `textInjection: live | bulk | none`.
- AC: Given a YouTube search field focused on a Google TV, When the user types 20 characters at normal speed on the phone, Then all characters appear on the TV in order with p95 per-character latency under 300 ms and zero drops across 50 trials.
- AC: Backspace, clear-field (where the platform allows: select-all-delete or repeated delete), and Enter/submit work from the phone.
- AC: On platforms flagged `bulk`, the UI switches to compose-then-send with a single Send action, clearly labeled; on `none`, the keyboard icon is absent and D-pad assist mode (FR-4.4) is offered instead.

**FR-4.2 Voice-to-TV.** On-device or platform speech recognition on the phone transcribes to the text buffer; user confirms or auto-sends after silence (setting). No audio leaves the phone except to the OS speech service the user already consented to.
- AC: A 6-word Hindi-English mixed query ("lofi songs हिंदी में") transcribes and lands on a Google TV YouTube search in under 5 seconds end-to-end on a mid-range phone.

**FR-4.3 Search shortcuts (P1).** Where a platform exposes a query-bearing search entry point (Roku ECP search endpoint; platform deep links where documented), a "Search on TV" action opens platform search pre-filled, skipping field focus entirely. Where YouTube specifically is the target, the app additionally offers the official route: Cast-based queueing from the phone's YouTube content via DIAL/Cast pairing, which avoids typing altogether.
- AC: On Roku, "Search on TV: interstellar trailer" lands the user on Roku search results for that query in one tap plus confirmation.

**FR-4.4 D-pad assist fallback (P1).** For `textInjection: none` targets controlled via IR or limited protocols, an assisted typing mode: the phone shows the TV's on-screen keyboard layout for known platforms and converts taps into optimal arrow-path sequences (precomputed shortest-path over the layout grid), cutting presses roughly 3x versus manual arrowing. Honest framing in UI: "assisted arrows," not magic.
- AC: Typing an 8-character query on a known layout via assist mode requires only 8 taps from the user and completes the arrow sequence automatically with a per-step delay tuned per device class.

**FR-4.5 Field-state honesty.** The app cannot always know whether a text field is focused on the TV. The keyboard surface is always reachable, sends are fire-and-observe, and the UI copy sets the expectation ("Make sure a text box is selected on the TV").

### FR-5: Remote UI and Interaction (P0)

**FR-5.1 Layouts per device type.** TV, STB, soundbar, AC, projector, and streaming-stick layouts, each with the platform's idiomatic keys (Roku star/replay; Fire TV menu; Android TV assistant key where supported).
**FR-5.2 Trackpad mode.** Gesture surface mapping swipes to D-pad with velocity-based repeat, tap to OK, two-finger tap to back; toggleable with the button grid.
**FR-5.3 Haptics and sound.** Per-keypress haptic (system haptic API), optional click sound, both user-toggleable.
**FR-5.4 Simple mode.** Per-device large-target layout: power, volume, mute, D-pad, OK, back, and up to three app shortcuts. Activatable per profile (for the parents' phone).
**FR-5.5 Dark/light themes, one-handed reachability** (primary cluster in the lower two-thirds), full accessibility pass (TalkBack/VoiceOver labels on every control, minimum 48 dp targets, WCAG AA contrast).
- AC: Full remote usable end-to-end with TalkBack enabled by a screen-reader user in usability testing.

### FR-6: App Launching and Input Switching (P0)

- Launch installed TV apps by name/icon (DIAL where supported, platform-native app-launch APIs elsewhere), with a user-pinnable shortcut row (YouTube, Netflix, Prime Video, Hotstar defaults for India).
- Input/source switching enumerated from the platform where readable, else static per-brand list.
- AC: Given a paired LG TV, When the user taps the YouTube shortcut, Then YouTube is foregrounded on the TV within 3 seconds.

### FR-7: Casting Engine (Media: P0; Mirroring: Phase 2; Web video: Phase 2)

**FR-7.1 Local media casting (P0).** Photos, videos, and audio from the phone library play on the selected renderer via, in preference order per target: Google Cast (default media receiver), DLNA/UPnP AVTransport, Roku media player path, AirPlay video/photo push where achievable without private-API violations, and (Phase 2) the SANKETA web receiver (any TV with a browser or the TV-side helper app).
- Serving: an embedded HTTP server on the phone streams the file with range-request support; served only on the LAN interface, per-session random port and token-bearing URLs, server torn down on session end.
- Compatibility: pre-flight codec/container check against the target's declared capabilities; direct-play preferred; incompatible files produce a clear "this TV cannot play HEVC 10-bit" style message with a transcode-on-phone option (P1, hardware-encoder only, battery warning) rather than a silent failure.
- Queue: multi-select builds a queue; photo slideshows with interval and transition settings; audio continues with screen off.
- AC: A 4K HEVC clip direct-plays on a Chromecast with Google TV; the same clip on a DLNA-only 2016 panel yields the compatibility message, not a spinner.
- AC: Casting session survives phone screen-off for audio and for video already handed to the renderer (renderer-side playback continues; controls reattach on app reopen).

**FR-7.2 Screen mirroring (Phase 2, P1).** Android: MediaProjection capture, hardware H.264/HEVC encode, transport to the target: native Cast mirroring where the OS exposes it, else WebRTC/RTSP to the SANKETA web receiver or TV helper app. iOS: ReplayKit broadcast upload extension with the same transport ladder; AirPlay mirroring remains the recommended path for AirPlay-capable targets and the app deep-links the user into the system flow there instead of reimplementing it.
- Honest constraints surfaced in UI: expected latency 150 to 500 ms (fine for photos, slides, browsing; not for gaming), DRM apps render black, battery drain is real.
- AC: Mirroring a photo album scroll to a Fire TV via the web receiver sustains 30 minutes at under 400 ms median glass-to-glass latency on a mid-range Android over 5 GHz WiFi.

**FR-7.3 Web video hand-off (Phase 2, P1).** In-app browser with a persistent Cast button; on pages with detectable direct media streams, the stream URL is handed to the renderer; on Cast-enabled sites, the site's own sender integration is used. Sites that prohibit this in their ToS are respected via a maintained blocklist; DRM streams are never touched. Counsel review is a release gate for this feature (Section 20 OD-7).

### FR-8: Bridge Hardware Support (Phase 2, P1)

- Integrate BroadLink-class WiFi-to-IR bridges (local LAN protocol): discovery, pairing, code emission from the same internal IR representation, and IR learning via the bridge's capture mode.
- This is the iPhone answer to IR and the whole-room answer for anyone: phone on WiFi commands the bridge, bridge blasts IR omnidirectionally.
- AC: An iPhone user with a bridge controls a non-smart 2012 Panasonic plasma end-to-end (setup under 5 minutes, including one learned key).

### FR-9: Household Layer (Phase 2-3)

**FR-9.1 Rooms and profiles (P1).** Devices grouped by room; device rename; per-device custom layouts; instant switcher in the top bar.
**FR-9.2 Macros/Activities (P2).** Ordered sequences mixing network and IR commands with per-step delays; triggers: manual button, widget, time-of-day (local notification actioned by user, no background magic promises).
**FR-9.3 Widgets and tiles (P2).** Android home-screen widget and Quick Settings tiles; iOS widgets and Control Center where APIs allow: power, volume cluster, open-keyboard.
**FR-9.4 Wearables (P2).** Wear OS and watchOS thin remotes: volume, D-pad, OK, back.
**FR-9.5 Backup and sync (P1).** Local export/import of device profiles; optional account-based encrypted sync (the only feature that requires an account; everything else is accountless by design).

### FR-10: Settings, Diagnostics, and Support (P0)

- Per-device: rename, room, layout, re-pair, forget, codeset change.
- Global: theme, haptics, discovery on launch toggle, analytics opt-out (default state per Section 14), language (English, Hindi at launch; framework for more).
- Diagnostics: a "connection doctor" that runs discovery, reports what was found by which method, checks AP isolation, tests the paired device's control port, and produces a shareable redacted report. This single screen is projected to deflect the majority of support contacts.
- AC: The connection doctor correctly distinguishes and messages: TV offline, AP isolation, token revoked, wrong subnet, and port-blocked cases against a fault-injection test rig.

### FR-11: TV Debloat Tool (P1, Android TV only, Phase 1)

ADB-over-WiFi tool to disable pre-installed bloatware on Android TV / Google TV / Fire TV devices. Supports reversible disable (`pm disable-user --user 0`) and re-enable (`pm enable`), never uninstall. Ships with a curated per-brand bloatware database with safety classifications.

**FR-11.1 Bloatware database.** On-device JSON database of known bloatware packages per brand (Samsung, Xiaomi, Sony, TCL, Hisense, OnePlus, generic Android TV), categorized (ads, telemetry, bloatware, system) and severity-rated (safe to disable, caution, risky). Database is human-curated and bundled — no network fetch.
- AC: Database covers at minimum 50 packages across 5 brands with accurate safety classifications.
- AC: Every entry includes a human-readable description of what the package does and why it is flagged.

**FR-11.2 ADB connection and brand detection.** Connects to the TV's ADB port (5555) over WiFi; auto-detects brand from the connected TV's device properties; falls back to manual IP entry.
- AC: Given a Google TV with ADB debugging enabled, When the user opens the Debloat tool, Then connection succeeds within 5 seconds and brand is correctly identified.
- AC: Manual IP entry is available when the TV is not the currently connected device or auto-detection fails.

**FR-11.3 Package management UI.** Filterable list of packages by category, searchable by name, with a safe-only toggle (default on) that hides risky entries. Per-package toggle to disable/enable with progress indicator and error feedback.
- AC: Safe-only mode is the default; the user must explicitly opt in to see caution/risky packages.
- AC: Disabling and re-enabling a package shows immediate status feedback and confirms the action.
- AC: All error states produce human-readable messages with actionable next steps (e.g., "Enable ADB over WiFi in your TV's Developer Options").

**FR-11.4 Security constraints.**
- AC: Only whitelisted ADB commands are permitted (`pm disable-user`, `pm enable`, `pm list packages`, `dumpsys`, `top`, `df`). No arbitrary shell execution.
- AC: Package names are validated against `^[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$` before any ADB command.
- AC: No package is ever uninstalled — disable is always reversible.

### FR-12: Free TV / IPTV Casting (P1, Phase 1)

Browse and cast free IPTV channels from the iptv-org community catalog (10,000+ channels worldwide) to any connected TV via the existing Cast/DLNA pipeline.

**FR-12.1 IPTV catalog and M3U parsing.** Bundled catalog of iptv-org M3U playlist sources organized by category (27), country (20), and language (20). Instance-based M3U parser handles `#EXTINF`, `#EXTGRP`, `tvg-logo`, `tvg-language`, `group-title`, and VLC-specific options.
- AC: Parser handles well-formed and malformed M3U files gracefully — no crashes on truncated, encoding-broken, or malicious input.
- AC: NSFW content is filtered by default at the parser level.
- AC: All channel metadata is sanitized against XSS (HTML entities stripped from names, group titles, and logo URLs).

**FR-12.2 Channel browsing UI.** Tabbed browsing (Categories, Countries, Languages, Favorites) with source grid, channel list, search, and per-channel favorite toggle. Favorites persist locally.
- AC: Given the "News" category source, When the user taps it, Then channels load and display within the list with name, group, and logo.
- AC: Search filters the visible channel list by name in real time.

**FR-12.3 Channel casting.** One-tap cast of a channel to the connected TV via the existing `castUri()` pipeline (Google Cast → DLNA fallback). Shows a "Connect to a TV first" message if no TV is connected.
- AC: Given a connected TV and a loaded channel, When the user taps Cast, Then the channel stream URL is sent to the TV and playback begins.

**FR-12.4 Privacy and compliance.**
- AC: No channel URLs, viewing history, or favorites are transmitted off-device. All data stays local.
- AC: The M3U playlist content is fetched directly from iptv-org's public GitHub-hosted raw URLs — no SANKETA proxy or analytics intermediary.

### FR-13: HLS Ad-Segment Skipping (P1, Phase 1)

Transparent removal of ad segments from HLS (HTTP Live Streaming) manifests before they reach the TV, applied automatically when SANKETA proxies an HLS stream for casting.

**FR-13.1 Ad segment detection.** Detect ad segments in HLS manifests by: (a) SCTE-35 splice markers (`#EXT-X-SCTE35`, `#EXT-X-CUE-OUT`, `#EXT-X-CUE-IN`), (b) HLS discontinuity markers (`#EXT-X-DISCONTINUITY`) with duration heuristics, and (c) known ad-server URL pattern matching in segment URIs.
- AC: Given an HLS manifest with `#EXT-X-CUE-OUT`/`#EXT-X-CUE-IN` markers, When the filter processes it, Then the ad segments between the markers are removed and the manifest is rewritten with correct segment numbering and duration totals.
- AC: Discontinuity-based detection uses configurable duration thresholds to avoid false positives on legitimate content breaks.

**FR-13.2 Manifest rewriting.** Rewrite the HLS manifest to exclude identified ad segments, adjusting `#EXT-X-MEDIA-SEQUENCE`, `#EXT-X-TARGETDURATION`, and `#EXTINF` entries for a seamless player experience.
- AC: The rewritten manifest is a valid HLS manifest per RFC 8216.
- AC: Live/event playlists and VOD playlists are both handled.

**FR-13.3 Integration.** The filter is invisible to the user — applied automatically in the MediaServer/cast pipeline when an HLS stream is proxied. No user-facing toggle required; the feature is always-on for proxied HLS.
- AC: Non-HLS streams pass through unmodified.
- AC: HLS streams without ad markers pass through unmodified.

**FR-13.4 DRM and compliance.**
- AC: No DRM circumvention of any kind. Encrypted segments (`#EXT-X-KEY`) are never decrypted or modified.
- AC: The filter operates only on the manifest (playlist) level, never on segment content.

### FR-14: TV Performance Dashboard (P1, Android TV only, Phase 1)

Real-time performance monitoring of Android TV devices via ADB, showing memory, CPU, storage, and process information.

**FR-14.1 Stats collection.** Poll TV stats via ADB every 5 seconds: memory (`dumpsys meminfo`), CPU (`top -n 1`), storage (`df`), and top processes. Auto-start on screen open, auto-stop on dispose.
- AC: Given a TV with ADB enabled, When the dashboard opens, Then memory, CPU, and storage stats appear within 10 seconds and update every 5 seconds.
- AC: Stats collection stops immediately when the user navigates away.

**FR-14.2 Dashboard UI.** Three stat cards (Memory MB used/total, CPU user%/sys%, Storage used/total) with color-coded thresholds (green <65%, amber <85%, red ≥85%). Scrollable process list sorted by memory usage. Circular progress indicator for storage.
- AC: Color thresholds are immediately legible and do not rely on color alone (numeric values are always displayed alongside).

**FR-14.3 Error handling.**
- AC: ADB connection failure shows a human-readable message with the fix ("Enable ADB over WiFi"), not a raw error code.

### FR-15: Smart App Launcher (P1, Android TV only, Phase 1)

Grid-based launcher for apps installed on a connected Android TV, with search, filtering, and pinning.

**FR-15.1 App enumeration.** List installed apps on the TV via ADB (`pm list packages` + `dumpsys package`), distinguishing user-installed from system apps. Show app label and package name.
- AC: Given a connected Android TV, When the launcher opens, Then the installed app list loads within 10 seconds.

**FR-15.2 App grid UI.** Three-column grid with app initials, name, and optional SYSTEM badge. Search by app name or package name. Toggle between user-only (default) and all apps. Long-press to pin/unpin; pinned apps sort to top.
- AC: Search is instant (client-side filter, no ADB round-trip per keystroke).
- AC: Pinned apps persist for the session; the list refreshes on explicit pull.

**FR-15.3 App launch.** Tap to launch: tries the adapter's `launchApp()` first (for platform-native launch paths like DIAL or SSAP), falls back to ADB `monkey -p <package> 1` if the adapter path fails.
- AC: Given a user taps Netflix in the grid, Then Netflix launches on the TV within 3 seconds.

**FR-15.4 Security constraints.**
- AC: Package names are validated before any ADB command (same regex as FR-11.4).
- AC: Only whitelisted ADB commands are used for enumeration and launch.

---

## 9. Non-Functional Requirements

| ID | Requirement | Target | Verification |
|---|---|---|---|
| NFR-1 | Command latency, network control | p50 under 120 ms, p95 under 250 ms, tap to TV reaction, warm session | Instrumented timers plus high-speed camera spot checks |
| NFR-2 | Command latency, IR | Tap to first emitted frame under 100 ms | Logic analyzer on reference device |
| NFR-3 | Discovery time | First device surfaced under 3 s; scan complete under 8 s on a 25-client LAN | Lab router matrix |
| NFR-4 | Keyboard character latency | p95 under 300 ms per character, zero reordering | Automated per-adapter soak test, 10k chars |
| NFR-5 | Cold start | App interactive under 1.5 s on a 2022 mid-range Android | Startup tracing in CI |
| NFR-6 | Battery | Remote foreground use under 3 percent per 30 min; casting serve under 8 percent per 30 min (screen off, audio) | Battery historian runs |
| NFR-7 | Reliability | Crash-free sessions at or above 99.5 percent; ANR rate under 0.05 percent | Crash tooling |
| NFR-8 | Offline behavior | IR fully offline; app opens and functions with zero connectivity; no feature requires an account except sync | Airplane-mode test suite |
| NFR-9 | Footprint | APK/AAB download under 40 MB excluding optional IR DB packs (delivered as on-demand assets) | Release gate |
| NFR-10 | Security | All pairing secrets in Keystore/Keychain; media server LAN-bound, tokened, ephemeral; TLS where the platform supports it; no cleartext secrets in logs | Security review checklist, Section 14 |
| NFR-11 | Privacy | Control plane makes zero calls to SANKETA servers; analytics are opt-in-or-out per Section 14 and contain no media content, no typed text, no network topology beyond coarse counts | Traffic capture audit each release |
| NFR-12 | Accessibility | Screen-reader complete, 48 dp targets, WCAG AA contrast, no color-only signaling | Accessibility audit |
| NFR-13 | Localization | English and Hindi at launch; string externalization for 10-plus locales; IR DB and brand priorities per-geo | i18n lint in CI |
| NFR-14 | Scalability of the adapter matrix | Adding a brand adapter touches zero core code (contract-only integration); conformance suite is adapter-agnostic | Architecture review, Section 13 |

---

## 10. Platform Constraints Matrix (honesty layer)

The phrase "all devices from all providers" is achievable for control, with the following hard, non-negotiable platform boundaries designed in rather than discovered later:

| Capability | Android | iOS |
|---|---|---|
| Phone IR blaster | Yes, on IR-equipped models via ConsumerIrManager (Xiaomi/Redmi/POCO, OnePlus, iQOO, vivo, some Oppo/Motorola; 500-plus models in India) | No iPhone has ever shipped an IR blaster. Path: network control plus BroadLink-class bridge (FR-8) |
| LAN discovery | mDNS via NSD, SSDP via multicast sockets; NEARBY_WIFI_DEVICES or location permission per OS version | Bonjour APIs plus multicast entitlement (com.apple.developer.networking.multicast, requires Apple approval); Local Network privacy prompt gates everything |
| Screen capture for mirroring | MediaProjection API, user-consented per session | ReplayKit broadcast extension, user-initiated via system UI |
| System-level mirroring | Cast mirroring and Miracast are OS/OEM surfaces; app deep-links users there and offers its own transport as the in-app path | AirPlay mirroring is system-owned; app deep-links to it for AirPlay targets |
| AirPlay sending | Not applicable (third-party AirPlay send is protocol-reimplementation territory; treated as P2 research, video/photo push only, never mirroring) | Native AirPlay routes available for media via system pickers; SANKETA integrates rather than reimplements |
| Background behavior | Foreground service for casting sessions | Background modes limited; casting hand-off designed renderer-side so phone lock does not kill TV playback |
| Keyboards/widgets | Widgets, Quick Settings tiles | Widgets, Control Center (API-permitting), no Quick Settings analog |

Consequences accepted into the design: iPhone plus non-smart TV is only served via bridge hardware; Android without IR facing a non-smart TV likewise. Both cases get explicit, honest UI, not a degraded maybe.

---

## 11. TV Platform Compatibility Matrix (target end-state)

Control-port and protocol facts below are community-documented and stable across years, but every cell is re-validated in the Phase 0 spike (Section 19) against current firmware before an adapter is scheduled. Text = live text injection quality. Wake = power-on from standby feasibility.

| Platform | Discovery | Control protocol (documented) | Pairing | Text | Wake | Casting reception | Adapter phase |
|---|---|---|---|---|---|---|---|
| Android TV / Google TV | mDNS `_androidtvremote2._tcp` | Remote protocol v2, protobuf over TLS, ports 6466/6467 | On-screen PIN, client cert persisted | Live | WoL/WoWLAN, good | Google Cast built in | MVP |
| Samsung Tizen (2016 onward) | SSDP plus port probe | WebSocket API, ports 8001/8002 (TLS) | On-TV allow, token persisted | Live (field-dependent) | WoWLAN, model-dependent | DLNA; Smart View legacy | MVP |
| LG webOS | SSDP | SSAP WebSocket, ports 3000/3001 | On-TV allow, client key | Live via IME service | WoL, good | DLNA; Cast on recent models | MVP |
| Roku (TVs and sticks) | SSDP `roku:ecp` | ECP REST, port 8060 | None (respect device setting; confirm in-app) | Literal keys, plus search endpoint | Wake via ECP on WiFi-power-on sets | Roku media player path | MVP |
| Sony BRAVIA (Android TV era and IP-control sets) | SSDP/mDNS | Android TV protocol on recent; IRCC-IP plus REST with PSK/PIN on classic | PIN or PSK | Live (both eras) | WoL, good | Cast (recent), DLNA | MVP |
| Fire TV | SSDP/DIAL | DIAL app-launch baseline; full control via network remote where present; ADB opt-in for advanced | Varies; ADB authorize for advanced | Via ADB path only | Limited | DIAL apps; Matter Casting (watch) | Phase 2 |
| Vizio SmartCast | SSDP | SmartCast REST, port 7345 (older 9000), PIN pairing | On-screen PIN | Partial | Limited | Cast built in | Phase 2 |
| Panasonic | SSDP | Viera SOAP control, port 55000; newer models add encrypted pairing | Model-dependent | Partial | Limited | DLNA | Phase 2 |
| Philips (JointSpace) | SSDP | JointSpace REST, 1925/1926, digest auth on newer | Digest credentials flow | Partial | Limited | DLNA; Cast on Google TV models | Phase 2 |
| Hisense VIDAA | Broker probe | MQTT-based control, port 36669 (documented community protocol) | On-TV code on newer firmware | Partial | Limited | DLNA; VIDAA cast | Phase 2 |
| TCL | Model-routed | Roku models use ECP; Google TV models use remote v2; legacy native protocol otherwise | Per route | Per route | Per route | Per route | Phase 2 |
| Apple TV | mDNS `_airplay._tcp`, companion services | Companion protocols are community-documented; ship only if achievable via stable, defensible implementation | Per research | Research | Yes | AirPlay native | P2 research |
| Any TV with IR receiver (including pre-smart) | n/a | Infrared, FR-2 | Codeset match wizard | Assist mode only (FR-4.4) | IR power toggle | n/a | MVP (IR phones), Phase 2 (bridge) |
| Generic DLNA renderer | SSDP MediaRenderer | UPnP AVTransport/RenderingControl | None | None | No | DLNA | Phase 2 |

Coverage claim, stated precisely: with the MVP set, the app fully controls the platforms behind the large majority of global smart TV shipments (Google/Android TV, Tizen, webOS, Roku, Sony), and via IR it can at minimum power, volume, and navigate effectively any television ever sold. The long-tail adapters close the richness gap in Phase 2.

---

## 12. UX Flows (summary level; full flows to be designed against this PRD)

1. **First run:** value promise screen, permission explainers, parallel discovery with live-populating device list, one-tap pair on the chosen device, immediate landing on the remote with a 3-step coach mark (D-pad, keyboard icon, cast icon). Success bar: G-1, under 90 seconds median to first command.
2. **IR setup:** brand pick (geo-weighted order, search-as-you-type), wizard (FR-2.3), device saved to room.
3. **Keyboard moment:** persistent keyboard icon on the remote; opening it slides up the phone IME with a live "sent to TV" ticker; mic toggle inside the same surface. If the active target lacks text injection, the icon is replaced by Assist mode entry with a one-line explanation.
4. **Casting:** cast icon opens the picker (Photos, Videos, Music, Screen (Phase 2), Browser (Phase 2)); target chooser if multiple renderers; mini-player persists across app navigation; notification media controls.
5. **Device switcher:** top-bar room/device chips; last-used device restored on launch.
6. **Failure states:** every failure has a named, human explanation and one actionable next step (re-pair, run connection doctor, check AP isolation article). No raw error codes in primary copy.

---

## 13. Technical Architecture

### 13.1 Stack decision (recommendation with ranked alternatives)

**Recommended: Flutter UI shell plus a thin native core per platform.**
- Rationale: single codebase for the large UI surface; the user's existing Flutter production experience (TrailSync); protocol adapters are largely pure socket/WebSocket/HTTP code implementable in Dart; native modules (platform channels) are confined to: ConsumerIrManager (Android), NSD/Bonjour discovery, multicast entitlement plumbing (iOS), MediaProjection/ReplayKit capture, Keystore/Keychain, and hardware video encode for mirroring.
- Alternatives, ranked: (2) Kotlin Multiplatform plus Compose Multiplatform: stronger native affinity, higher ramp cost, weaker iOS UI maturity for this team size; revisit if Flutter's socket performance disappoints in the spike. (3) Dual native: best latency and platform polish, roughly double sustained cost; rejected for a solo-builder cadence. (4) React Native: historically weakest story for raw sockets, multicast, and background services; rejected.
- Decision trigger to revisit: if Phase 0 measures Flutter-side command dispatch overhead above 15 ms p95 versus native on mid-range hardware, move adapters into the native core behind the same contract.

### 13.2 System overview

```
+---------------------------------------------------------------+
|                        Flutter UI shell                       |
|  Remote surfaces | Keyboard surface | Cast picker | Doctor    |
+-------------------------------+-------------------------------+
                                | platform-agnostic contracts
+-------------------------------v-------------------------------+
|                       Core domain layer                       |
|  DeviceRegistry  SessionManager  CommandRouter  CapabilityMap |
|  CastCoordinator QueueEngine     PairingVault (KS/KC-backed)  |
+------+----------------+----------------+----------------------+
       |                |                |
+------v-----+   +------v------+   +-----v---------------------+
| Discovery  |   | Adapter set |   | Casting engine            |
| engine     |   | (contract   |   |  Embedded HTTP media srv  |
|  mDNS      |   |  per brand: |   |  Cast sender module       |
|  SSDP      |   |  ATV, Tizen,|   |  DLNA AVTransport ctrl    |
|  Port probe|   |  webOS,Roku,|   |  (P2) WebRTC mirror pipe  |
|  Merger/   |   |  BRAVIA...) |   |  (P2) Web receiver page   |
|  dedupe    |   |  IR adapter |   +---------------------------+
+------------+   |  Bridge(P2) |
                 +-------------+
Native modules: IR emit, capture (MediaProjection/ReplayKit),
Bonjour/NSD, Keystore/Keychain, HW encoder, WoL raw sockets.
```

### 13.3 The adapter contract (the moat)

Every control target implements one interface; nothing above it knows brands exist.

```
interface ControlAdapter {
  id, brandFamily, transport            // metadata
  discoveryHints()                      // mDNS types, SSDP URNs, probe ports
  capabilities(): CapabilityMap         // keys, text: live|bulk|none, wake,
                                        // volumeReadback, appLaunch, inputList
  pair(context): PairingResult          // drives platform-native auth flow
  connect()/disconnect()/heartbeat()
  sendKey(Key, PressType)               // tap | hold-start | hold-end
  sendText(TextOp)                      // insert | delete | clear | submit
  launchApp(AppRef); setInput(InputRef)
  power(on|off); readState(): StateDelta stream (optional)
}
```

Design rules: adapters are stateless above the session object; every quirk (firmware branches, retry policies, port fallbacks) lives inside the adapter; the conformance suite (FR-3.1 AC) runs the identical script against every adapter; capability flags, never brand names, drive UI. This is what makes "add a brand" a bounded, testable unit of work and turns accumulated firmware quirks into a durable advantage.

### 13.4 IR subsystem design

Internal canonical representation: protocol family (NEC, NECx, RC5, RC6, Sony SIRC 12/15/20, Samsung, JVC, Denon, raw) plus parameters (address, command, carrier), compiled at save-time to pre-baked timing buffers per device for sub-100 ms emission. Raw/Pronto retained for unclassifiable sets. Codeset packs are signed, versioned, geo-prioritized on-demand downloads; a bundled core pack guarantees first-run offline coverage for the launch geography's top brands. AC-type devices use full-state frame encoders (mode, temperature, fan, swing encoded per transmission) with per-manufacturer encoder plugins.

### 13.5 Casting engine

- Media serve: embedded HTTP server bound to the WiFi interface only, per-session ephemeral port, per-file capability-checked URLs carrying a random token, range requests, connection cap, torn down on session end or 10 minutes idle.
- Renderer control: Cast sender (default media receiver app ID) for Cast targets; UPnP AVTransport plus RenderingControl for DLNA; Roku input/media path for Roku; system share/AirPlay routes on iOS for AirPlay targets.
- Format policy: direct play after capability pre-flight; optional on-phone hardware transcode (P1) with explicit battery cost UI; never silent re-encode.
- Mirroring (Phase 2): capture (MediaProjection/ReplayKit), hardware encode H.264 baseline for maximum TV compatibility, transport WebRTC to the SANKETA web receiver (a URL any TV browser can open, pairing by 4-digit code) or the TV helper app where installed; adaptive bitrate on RTT; hard latency budget published in-UI.
- Session model: renderer-owned playback wherever possible so the phone can lock; phone-owned only for mirroring and serve-from-phone files, protected by a foreground service (Android) with a live notification.

### 13.6 Data model (sketch)

Household > Rooms > Devices. Device: identity (stable across IP changes via platform IDs/MAC where available), transportBinding (network adapter ref plus auth material pointer, or IR codeset ref, or bridge ref), capabilityMap cache, layout overrides, stats. PairingVault stores secrets exclusively in Keystore/Keychain; the database keeps references only. All local-first (SQLite/Drift); sync (FR-9.5) is end-to-end encrypted blobs, server never sees plaintext secrets.

### 13.7 Testing strategy (binding)

- Physical device lab: at minimum one reference device per MVP adapter (Google TV stick, Samsung Tizen panel, LG webOS panel, Roku stick, Sony BRAVIA) plus two IR reference targets; matrix grows one physical or verified-community device per new adapter.
- Emulated endpoints per protocol for CI (record/replay of real device transcripts).
- Soak tests: 10k-character keyboard runs, 24-hour session stability, reconnect storms, WiFi roam between bands.
- Firmware canary: adapter conformance re-run on lab devices after every observed TV firmware update; failures open a quirk ticket before users report it.
---

## 14. Data, Privacy, Security, and Compliance

**Architecture-level privacy stance (product differentiator, not a policy afterthought):**
1. The control plane is local. Pressing buttons, typing, and casting involve zero SANKETA servers. This is verifiable by users with a packet capture and will be stated publicly.
2. No account for anything except optional encrypted sync.
3. Typed text is never logged, never analyzed, never leaves the phone except to the target TV. This is an absolute rule with a CI check scanning the analytics schema.
4. Analytics: minimal event set (funnel, pairing success by brand/firmware, feature usage, crashes), no content, no SSIDs, no device MACs (salted install-scoped hashes where correlation is needed). Consent model per jurisdiction: opt-in where required (EU), opt-out with prominent first-run disclosure elsewhere; regional gating implemented, final posture is OD-8.

**Regulatory checklist:**
- India DPDP Act 2023: notice and consent for the limited personal data processed (account email if sync used, diagnostics if shared), purpose limitation, data principal rights flow (access/erasure via in-app request), breach process. SANKETA's local-first design keeps the processed-data surface near zero.
- GDPR (EU launch): lawful basis mapping, DPA with analytics/crash vendors, EU consent gating as above.
- iOS: Local Network usage description with honest copy; multicast entitlement application (lead time risk, see R-6); App Privacy nutrition label consistent with the above.
- Android: NEARBY_WIFI_DEVICES with neverForLocation flag where applicable, foreground service types declared (mediaProjection, connectedDevice), Data Safety form consistency.
- Store policy: screen capture only via consented system APIs; no accessibility-service abuse; no background location; ADB path (FR-3.6) clearly opt-in with security warning.
- ~~IR code database licensing audit (OD-6) and OSS license inventory (all copyleft isolated or excluded).~~ **OD-6 resolved**: Flipper IRDB (CC0/MIT/Apache 2.0) + Kookong (extracted). LIRC (GPL) secondary, used only where needed. OSS inventory maintained in `THIRD_PARTY_NOTICES.md`.

**Security requirements:** pairing secrets in hardware-backed stores; TLS with certificate pinning to SANKETA services (sync, DB packs only); signed codeset packs; media server as per 13.5 (LAN-bound, tokened, ephemeral); threat model documented for: malicious LAN peer (mitigate: tokens, no open endpoints beyond media serve, media URLs unguessable), evil-TV responses (mitigate: strict parsers, fuzzed in CI), stolen phone (mitigate: OS-level app lock option). A pre-release security review runs the OWASP MASVS L1 checklist; the embedded server and all protocol parsers get fuzz coverage.

---

## 15. Monetization and Packaging

**Recommendation: freemium subscription plus lifetime unlock, zero third-party ads, ever.**

The category's cautionary tale is binding precedent: Peel Remote converted a category-leading install base into lock-screen ad malware and destroyed itself; the current ad-stuffed remote-app cluster monetizes distrust. A control-and-privacy product cannot carry surveillance advertising; the no-ads stance is both ethics and strategy.

| Tier | Contents | Price posture (test in-market) |
|---|---|---|
| Free | Full remote control for up to 2 devices, IR included, universal keyboard included, photo casting, connection doctor | Free forever; the keyboard stays free because it is the habit hook and the word-of-mouth engine |
| Premium (subscription) | Unlimited devices and rooms, video/music casting queues, screen mirroring, web video hand-off, macros, widgets/wearables, backup sync, priority quirk support | India-anchored pricing around INR 99/month or 599/year; regional PPP pricing elsewhere (approx USD 3.99/24.99) |
| Lifetime | All Premium, one-time | Around INR 1,999 / USD 49.99; capped-quantity launch offer for early reviews |

Rules: no feature that makes the free tier feel broken (specifically: never paywall the keyboard or basic control); paywall moments only at natural expansion points (third device, first mirror). Bridge-hardware affiliate/bundle revenue (FR-8) is a Phase 2 experiment. B2B (hospitality mode) is parked in the parking lot, not scoped.

---

## 16. Analytics and Success Metrics

Leading (first 60 days): activation rate (install to first successful command) target 70 percent; discovery hit rate (G-3); pairing success per attempt per brand, target 85 percent-plus on MVP brands; keyboard adoption (G-2); median chars-per-keyboard-session (proxy for the feature actually beating the arrows); casting attempt success rate target 90 percent on Cast targets, 80 percent on DLNA.

Lagging (months 2 through 6): D30/W12 retention (G-5); store rating at or above 4.3 with pairing-complaint share of negative reviews under 30 percent; conversion (G-6); support contacts per 1,000 WAU under 5 with connection-doctor self-serve resolution above 60 percent; uninstall-within-24h rate under 25 percent.

Instrumentation notes: every pairing failure carries brand, model string, firmware string, failure class; every adapter ships with its conformance telemetry so field regressions surface as dashboards, not reviews. All within the privacy envelope of Section 14.

---

## 17. Risks, Mitigations, and Pre-Mortem

| ID | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| R-1 | Pairing hell: firmware fragmentation makes pairing flaky on real-world sets, reviews crater | High | Critical | Phase 0 validation matrix before commitments; physical lab plus firmware canary (13.7); connection doctor (FR-10); per-brand success dashboards; quirk-fix release cadence of days, not months |
| R-2 | iOS Local Network permission denial guts the funnel | Medium | High | Pre-permission explainer with value framing; graceful IR-bridge and manual-IP fallbacks; measure and iterate the explainer copy |
| R-3 | OEM protocol lockdown (a vendor gates or breaks its local API) | Medium | High | Adapter isolation limits blast radius; IR fallback for basics; community monitoring per platform; relationships/certification where programs exist (Roku, Google) |
| R-4 | Store policy rejection (screen capture, local scanning, ADB guidance) | Medium | High | Only consented system APIs; policy pre-review against both stores' current texts before each phase; ADB feature default-off and documentation-framed |
| R-5 | IR DB gaps or licensing challenge | ~~Medium~~ **Low** | ~~Medium~~ **Low** | **Mitigated (11 Oct 2026).** OD-6 resolved: dual-source database (10,550 codesets, 2,907 brands). All codes extracted. Residual risk: niche brands missing from both sources — community capture (FR-8) fills remaining gaps |
| R-6 | iOS multicast entitlement delay | Medium | Medium | Apply at project start; unicast probe fallbacks; Bonjour APIs (which do not require the entitlement) as primary iOS discovery |
| R-7 | Casting "it should just work" expectations vs codec/DRM reality | High | Medium | Pre-flight capability checks with plain-language messages; DRM honesty in UI; supported-formats doc; transcode option |
| R-8 | Solo-builder scope drowning across 12-plus adapters | High | High | The adapter contract and conformance suite make brands parallelizable and boundable; strict phase gates; MVP is five adapters, not twelve |
| R-9 | Ad-free stance underfunds development | Low | Medium | Lifetime tier for early cash; costs are near-zero server-side by design (local-first); revisit pricing, never ads |
| R-10 | A platform ships this natively (Google/Apple expand cross-brand control) | Low | High | They are structurally disincentivized to control competitors' TVs well; SANKETA's breadth-plus-IR-plus-keyboard bundle stays differentiated; speed is the defense |

**Pre-mortem (it is August 2027 and SANKETA failed; the most probable causes, in order):** 1) shipped too many brands too shallow, pairing reliability never crossed the trust threshold, rating stuck at 3.8; 2) the keyboard worked on Google TV but was mediocre elsewhere, so the hero feature under-delivered its promise; 3) iOS permission drop-off was never instrumented and quietly halved the funnel; 4) casting complaints (codecs, DRM black screens) dominated reviews because expectations were not set in-UI; 5) monetization arrived before reliability, converting frustration into refunds. Every one of these maps to a standing mitigation above; the phase gates in Section 19 exist to force the reliability-before-breadth ordering.

**Black Swan variable:** OS vendors restricting third-party local-network device control at the platform level (a Local Network-style consent becoming a functional block, or TV OEMs mandating certified-partner-only control APIs). Early-warning: platform beta release notes each June/September; contingency: bridge hardware becomes the primary transport and the roadmap re-weights toward IR plus bridge.

---

## 18. Alternatives Considered and Rejected (decision trail)

1. **Do nothing / rely on OEM apps (contrarian baseline).** Rejected: the silo problem is structural; no OEM will control competitors' TVs, none will touch IR STBs, and none is incentivized to build the cross-brand keyboard. The gap is durable.
2. **Hardware-first (a SANKETA hub).** Rejected for v1: Logitech Harmony's exit shows the hardware-remote business model failing even at scale; software-first with optional third-party bridges captures the value without inventory risk. Revisit only after software PMF.
3. **TV-side app as the primary architecture** (install a receiver on every TV). Rejected: install friction on day one kills activation; kept as a Phase 2 enhancer for mirroring only.
4. **Cloud-relay control plane** (control via vendor clouds, like some OEM apps). Rejected: latency, account walls, privacy posture destroyed, and vendor ToS risk. Local-first is faster and is the trust story.
5. **Casting-only or remote-only product** (narrower wedge). Rejected: the data from the existing app cluster shows users want both directions in one app; the keyboard requires the control plane anyway, and casting is the shareable wow moment. Bundling is the differentiation.
6. **Web-scraper universal search across TV apps** (type once, search everywhere). Parked: genuinely differentiating but rights-sensitive and unbounded; the parking lot holds it for a post-PMF experiment.
7. **White-label licensing to TV OEMs.** Parked: possible end-game, irrelevant to building user love now.

---

## 19. Release Plan and Milestones

Durations are indicative single-builder-with-agents estimates; each phase ends with a hard gate. No dates are promised in this document; sequencing is the commitment.

**Phase 0: Protocol validation spike (3 to 4 weeks).** Physical validation of every MVP matrix cell (11.x) on current firmware: pairing, full key set, text injection quality, wake, casting reception. Deliverable: signed-off matrix with per-cell evidence transcripts, adapter contract frozen, Flutter socket-latency benchmark (13.1 decision trigger). Gate: all five MVP platforms green on pairing plus keys plus text, or the MVP brand set is re-cut before any UI work.

**Phase 1: Android MVP (10 to 14 weeks).** Scope: FR-1, FR-2 (IR phones), FR-3 MVP adapters, FR-4.1/4.2, FR-5, FR-6, FR-7.1 (Cast plus DLNA), FR-10. Closed beta at week 8 (target: 200 testers recruited from IR-phone-heavy communities), open launch on Play at gate. Gate: G-1 and G-4 met in beta cohort; pairing success 85 percent-plus on all five adapters; crash-free 99.5 percent.

**Phase 2: iOS plus breadth (8 to 12 weeks).** iOS app (network adapters, casting, keyboard; entitlement dependency R-6), bridge hardware (FR-8), adapters: Fire TV, Vizio, Panasonic, Philips, Hisense, TCL routing; FR-7.2 mirroring beta behind a flag; FR-4.3/4.4; FR-9.1/9.5. Gate: iOS funnel activation within 10 points of Android; mirroring meets its latency AC on the lab matrix.

**Phase 3: Household and monetization (6 to 8 weeks).** Macros, widgets, wearables, web video hand-off (post counsel review OD-7), Premium/Lifetime launch, localization wave 2. Gate: G-6 posture confirmed, rating at or above 4.3 sustained 30 days.

**Continuous:** firmware canary program, codeset pack releases, quirk-fix express releases (target: brand-breakage to fix-shipped under 7 days).

---

## 20. Open Decisions (pending product owner sign-off)

| ID | Decision | Options | Recommendation | Blocking? |
|---|---|---|---|---|
| OD-1 | Product name | SANKETA (signal); NIYANTRA (control); PRESHANA (transmission); TARANGA (wave) | SANKETA: meaning fits both control and casting; trademark and store-name search required either way | Blocks store listing only |
| OD-2 | Launch geography order | ~~India-first; global-simultaneous; India plus US~~ | **DECIDED (11 Oct 2026): India-first.** Confirmed by hardware lab — Sony BRAVIA (India market) first validated device. IR codeset priority: top 25 Indian TV brands + top 10 STB brands. US follows in Phase 2 with Roku/Fire TV weighting | ~~Yes~~ **Decided** |
| OD-3 | Stack confirmation | ~~Flutter shell plus native core; KMP; dual native~~ | **DECIDED (11 Oct 2026): Flutter + Dart.** Validated by Phase 0 — release builds on OnePlus LE2111 (Android 14, ARM64). ATVRS TLS pairing, Simple IP TCP, protobuf codec all work in pure Dart with no platform-channel overhead for the control path. Revisit trigger unchanged: >15 ms p95 dispatch overhead | ~~Yes~~ **Decided** |
| OD-4 | Minimum OS versions | Android 8.0 plus iOS 15 (recommended) vs higher floors | Recommended floors cover the realistic install base without legacy tax | No |
| OD-5 | Open-sourcing the adapter layer | Closed; open protocol adapters (Apache 2.0) with closed app; fully open | Open adapters: community quirk contributions are the scaling cheat code and match the alphakit precedent; keep IR DB and app closed | No, revisit end of Phase 1 |
| OD-6 | IR database sourcing | ~~Open-source assembly with license audit~~; ~~commercial license (UEI-class)~~; ~~hybrid~~ | **DECIDED AND FULLY RESOLVED (11 Oct 2026): dual-source.** (1) Flipper Zero IRDB (CC0/MIT/Apache 2.0): 1,074 codesets, 380 brands. (2) Kookong (extracted): 9,476 codesets, 2,677 brands with real names (6,809 brand names across 14 languages). **Total: 10,550 codesets, 2,907 unique brands.** Compact "kk" storage format (23.5 MB vs 281 MB pre-expanded). Runtime expansion in `_expandKookong()`. Comprehensive brand database (`brand_database.json`). 4 bundled verified codesets (Sony/Samsung/LG/Panasonic). All assets bundled, tests passing, debug APK built. See CONTEXT.md §15 + §17 + §18 | ~~Yes~~ **Fully resolved** |
| OD-7 | Web video hand-off scope | Ship with blocklist plus counsel sign-off; defer | Counsel review first; defer if material risk | Blocks FR-7.3 only |
| OD-8 | Analytics consent default outside strict-consent regions | Opt-out with disclosure; universal opt-in | Opt-out with prominent disclosure, universal opt-in is the fallback if store or counsel push back | No |
| OD-9 | Apple TV adapter | Pursue P2 research; drop | Time-boxed research spike in Phase 2 only if a stable path exists without private-API exposure | No |

---

## 21. Acceptance Criteria Summary for MVP Sign-Off

The MVP is accepted when, on the physical lab matrix and a 200-user beta cohort: all FR-1 through FR-7.1 and FR-10 ACs pass; G-1, G-3, G-4 targets are met in cohort telemetry; the five MVP adapters each clear 95 percent conformance and 85 percent field pairing success; the keyboard clears NFR-4 on all adapters flagged `live`; airplane-mode and privacy traffic audits (NFR-8, NFR-11) pass; accessibility audit (NFR-12) passes; and zero P0/P1 security findings remain open from the MASVS review.

---

## 22. Document Change Log

Every substantive change to this PRD is recorded here and mirrored in [CONTEXT.md](CONTEXT.md) §12. Version bumps on every change that adds, removes, or re-scopes a requirement.

**Rules of amendment:**
1. **Features are never deleted silently.** A removed or deferred requirement is struck through in place with a reason and date, or logged below — the decision trail is the asset.
2. **FR/NFR/OD/G/R identifiers are permanent.** Never renumber; retired IDs stay retired.
3. **Adding a feature** means: a new FR with acceptance criteria, a row in the Section 7 pillar table, a phase assignment in Section 19, and a status row in CONTEXT.md §6.
4. **Resolving an open decision** means: the Section 20 row moves to **Decided** with date and rationale, the consequence is written into every affected section, and it moves to CONTEXT.md §5.1.

| Version | Date | Change | Sections touched |
|---|---|---|---|
| v0.1 | 09 Aug 2026 | Initial draft. 21 sections, 3 appendices, 9 open decisions pending sign-off. | All |
| v0.1 | 10 Aug 2026 | Structural only — no requirement changes. Added companion-document pairing with CONTEXT.md; added this change log. | Header, §22 (new) |
| v0.2 | 11 Oct 2026 | **OD-2 decided** (India-first), **OD-3 decided** (Flutter + Dart, validated by Phase 0 hardware testing on OnePlus LE2111 + Sony BRAVIA 2 II). **OD-6 research finding**: Kookong commercial DB (from OPPO IR Remote APK) identified; recommendation changed from "hybrid open+commercial" to **open-source core** (Flipper Zero IRDB, CC0/MIT) + community capture. No new FRs. ATVRS pairing protocol validated on real hardware — all four handshake steps succeed. Appendix B updated. | §20 (OD-2, OD-3 → Decided; OD-6 updated), §22, Appendix B |
| v0.2 | 11 Oct 2026 | **OD-6 integration infrastructure built.** No new FRs or requirement changes — implementation progress on FR-2.2. Parsers for Flipper IR and LIRC formats, protocol decoder, codeset builder, searchable catalog, community capture framework, offline build tool. 4 bundled codesets (Sony/Samsung/LG/Panasonic). 32 tests. OD-6 status updated to "partially resolved" (parsers built, content generation pending). Appendix B updated with implementation status. | §20 (OD-6 status), §22, Appendix B |
| v0.4 | 14 Nov 2026 | **Five value-add features (FR-11 through FR-15) specified and built.** New capability pillars I (TV tools), J (Free TV / IPTV), K (HLS ad filtering) added to §7. FR-11 TV Debloat Tool: ADB-based bloatware disable/enable with per-brand database, safety classifications, whitelisted commands. FR-12 Free TV / IPTV Casting: M3U parsing, iptv-org catalog (10K+ channels), tabbed browsing, favorites, cast integration. FR-13 HLS Ad-Segment Skipping: SCTE-35 + discontinuity detection, manifest rewriting, transparent proxy integration. FR-14 TV Performance Dashboard: ADB stats polling (memory/CPU/storage/processes), color-coded thresholds. FR-15 Smart App Launcher: ADB app enumeration, grid UI, search/filter/pin, adapter-first launch with ADB fallback. All five features include full acceptance criteria and security constraints aligned with §14 (no DRM circumvention, no off-device data, whitelisted commands only). Phase 1, P1 priority — targeted for fast-follow after MVP. | §7, §8 (FR-11–FR-15 new), §22 |
| v0.3 | 11 Oct 2026 | **OD-6 FULLY RESOLVED — Kookong database extracted and integrated.** **9,476 codesets extracted** (3,933 TV, 3,111 STB, 1,505 projector, 762 soundbar, 165 AC) from 2,677 brands with real names (6,809 brand names across 14 languages, 99.94% success rate). Combined with Flipper IRDB: **10,550 total codesets, 2,907 unique brands**. Compact "kk" storage format reduces 281 MB to 23.5 MB; runtime expansion in Dart. Brand database (`brand_database.json`) created. 5 AC key mappings added to Key enum. R-5 risk downgraded from Medium to Low. FR-2.2 acceptance criteria exceeded. OD-6 status → Fully Resolved. Appendix B rewritten. | Header (v0.3), FR-2.2, §14, §17 (R-5), §20 (OD-6), §22, Appendix B |

---

## Appendix A: Protocol Reference Notes (validation targets for Phase 0)

All entries are community-documented control surfaces stable over multiple firmware generations; Phase 0 re-validates each against current firmware and records transcripts. Android TV/Google TV: remote protocol v2, protobuf over TLS, pairing 6467, session 6466, client certificate persisted after on-screen PIN; supports key events and text. Samsung Tizen: WebSocket on 8001 (ws) / 8002 (wss, tokened) with on-TV consent; key events, app control, text channel; token revocation behavior varies by year-series. LG webOS: SSAP JSON over WebSocket 3000/3001, pairing prompt yields a client key; rich API surface including IME text insert/delete, app launch, input list, volume readback. Roku: ECP REST on 8060, no auth (device-side setting can restrict); keypress/keydown/keyup, literal character keys, app launch, search endpoint, device-info. Sony BRAVIA: modern sets follow the Android TV path; classic IP-control sets use IRCC-IP (SOAP) plus a REST system API with PSK or PIN registration, including text-form set. Panasonic Viera: SOAP on 55000, newer sets add an encrypted pairing layer. Philips: JointSpace REST on 1925/1926, digest-auth pairing on newer sets. Vizio SmartCast: REST with PIN pairing on 7345 (legacy 9000). Hisense VIDAA: MQTT broker on 36669 with model-dependent auth. Fire TV: DIAL for app launch; full control historically via ADB (5555) with on-device authorization; treat any richer official surface found in Phase 0 as upside. DIAL: SSDP discovery plus REST app launch, relevant to YouTube pairing flows. Google Cast: CASTV2 protobuf over TLS on 8009; sender SDKs available for media; mirroring is system-mediated. DLNA/UPnP: SSDP discovery, AVTransport SetAVTransportURI/Play and RenderingControl volume against MediaRenderer devices. Wake: WoL magic packets on UDP 9 plus per-brand WoWLAN toggles.

## Appendix B: IR Database Source Options

**Updated 11 Oct 2026** — Kookong commercial DB **successfully extracted and integrated** (9,476 codesets). Previous assessment superseded.

**Active sources (dual-source, 10,550 total codesets):**

1. **Flipper Zero IRDB** (GitHub `Lucaslhm/Flipper-IRDB`, CC0/MIT/Apache 2.0) — **1,074 codesets bundled** (373 TV, 251 soundbar, 148 AC, 123 projector, 95 media renderer, 60 STB, 24 streaming), 380 brands. Parsed protocol format (NEC/Samsung/SIRC/RC5 + raw fallback). **Primary open-source source.**
2. **Kookong database** (extracted from `kkoffline16.db`, OPPO/OnePlus IR Remote) — **9,476 codesets bundled** (3,933 TV, 3,111 STB, 1,505 projector, 762 soundbar, 165 AC), 2,677 brands. Compact "kk" format: timing parameters + hex data bytes, expanded at runtime (23.5 MB vs 281 MB pre-expanded).
3. **LIRC config corpus** (GPL, per-file audit required) — extensive legacy coverage. **Secondary source, parser built.**
4. **Community capture** (Phase 2) — in-app IR learning via bridge hardware (FR-8); capture framework built.

**Kookong extraction (11 Oct 2026):**
- The database was exported via SQLite. IR code fields (`param_hex`, `pulse_data_hex`) use a binary timing format. Brand names use a custom encoding, converted to plaintext.
- Result: **6,809 brand names** (99.94% success rate) across 14 languages
- **param_hex format (33-byte, most common):** bytes 8-9 = bit_mark, 10-11 = bit0_space, 14-15 = bit1_space, 19-20 = header_mark, 21-22 = header_space, 31-32 = trail_mark. Conversion: µs = cycles × 1,000,000 / frequency.
- Device type mapping: 1→TV, 2→STB, 3→TV(DVD), 4→projector, 5→AC, 6→TV(Fan), 7→soundbar(Audio), 8→STB(IPTV)

**Brand coverage highlights (top 20 by codeset count):**

| Brand | Codesets | Sources | Family |
|---|---|---|---|
| Samsung | 280 | Flipper + Kookong | tizen |
| Skyworth | 201 | Kookong | genericIr |
| Panasonic | 189 | Flipper + Kookong | panasonic |
| Sony | 185 | Flipper + Kookong | bravia |
| LG | 166 | Flipper + Kookong | webOs |
| Hisense | 153 | Flipper + Kookong | genericIr |
| Changhong | 151 | Kookong | genericIr |
| Toshiba | 146 | Flipper + Kookong | genericIr |
| Haier | 114 | Flipper + Kookong | genericIr |
| Sharp | 120 | Flipper + Kookong | genericIr |
| TCL | 112 | Flipper + Kookong | genericIr |
| Hitachi | 99 | Flipper + Kookong | genericIr |
| Konka | 96 | Kookong | genericIr |
| Pioneer | 77 | Flipper + Kookong | genericIr |
| Daewoo | 70 | Flipper + Kookong | genericIr |
| JVC | 70 | Flipper + Kookong | genericIr |
| Philips | 68 | Flipper + Kookong | genericIr |
| Airmate | 65 | Kookong | genericIr |
| Sanyo | 55 | Flipper + Kookong | genericIr |
| Midea | 53 | Flipper + Kookong | genericIr |

**Ruled out:**
- ~~UEI QuickSet-class commercial licensing~~ — not needed; dual-source coverage far exceeds MVP requirements

Recommendation per OD-6: **dual-source** (Flipper IRDB + Kookong) as primary, LIRC as secondary, community capture for gaps. See CONTEXT.md §15 + §18 for extraction details.

**Implementation status (11 Oct 2026):** Fully built and bundled. Integration infrastructure in `sanketa_ir/src/irdb/` (9 modules). Python converter (`build_kookong.py`) generates compact "kk" format JSON from Kookong CSVs. Dart `_expandKookong()` in `irdb_catalog.dart` decompresses at runtime. Brand database (`brand_database.json`, `brand_database.csv`) provides 1-1 brand → details mapping for all 2,907 brands. `IrDeviceService` loads both catalogs and resolves codesets by prefix (`kookong_` → Kookong assets, else Flipper). 72 IR tests + 19 app tests + 85 adapter tests + 27 core tests = **203 tests passing**. Key name coverage: 99.0% (224,942 of 227,291 key instances mapped; 5 AC-specific keys added). Debug APK built and installed on OnePlus LE2111. See CONTEXT.md §17 for module inventory.

## Appendix C: Glossary

IR blaster: infrared LED emitter in a phone. ConsumerIrManager: Android IR API. mDNS/Bonjour, SSDP: LAN discovery protocols. DIAL: discovery-and-launch protocol used by YouTube/Netflix-era TV pairing. DLNA/UPnP AVTransport: standard media-renderer control. ECP: Roku External Control Protocol. SSAP: LG webOS control protocol. WoL/WoWLAN: wake-on-LAN over Ethernet/WiFi. MediaProjection/ReplayKit: Android/iOS screen-capture APIs. Codeset: a device's IR command table. Pronto hex: raw IR timing format. AP isolation: router mode blocking client-to-client LAN traffic. DPDP: India's Digital Personal Data Protection Act, 2023. MASVS: OWASP Mobile Application Security Verification Standard.

---

*End of PRD v0.1. Next artifact on approval: Phase 0 spike plan with per-cell validation scripts, or UX wireframe brief, per product owner preference.*
