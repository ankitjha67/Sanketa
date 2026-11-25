# SANKETA — Project Context

> **What this file is.** The living working-memory of the project: current state, decisions taken, what is built vs. planned, and what happens next. The PRD says *what we are building and why*. This file says *where we are and what we decided along the way*.
>
> **Read order for anyone (human or agent) joining:** this file first, then the relevant PRD section by ID. Never read the full PRD to answer a status question — the answer belongs here.

| Field | Value |
|---|---|
| Project | SANKETA (संकेत) — Universal TV remote and casting platform for mobile |
| Companion PRD | [SANKETA_PRD_v0.1.md](SANKETA_PRD_v0.1.md) (v0.4, dated 14 Nov 2026) |
| Product owner | Ankit Jha |
| Context file version | v2.9 |
| Last updated | 25 November 2026 |
| Overall status | 🟢 **Phase 2 features building. 14 adapters, 8 Phase 2 features built.** Dart SDK 3.12.2 + **Flutter 3.47.2**. App runs on real hardware (OnePlus LE2111, Android 14). **Sony BRAVIA 2 II validated**: Simple IP keys ✅, ATVRS pairing ✅, **Google Cast ✅** (CastV2 TLS on port 8009). Six packages + `sanketa_app` with **10+ screens** + app shell with 5-tab bottom nav. **Value-add features F1–F5 complete, integrated, and UI-verified on device (14 Nov 2026)**. **Phase 2 features built (25 Nov 2026)**: Touchpad mode (gesture-based D-pad/OK/Back/Menu), Macro automation (record/play/persist), Sleep timer (6 presets + badge), Quick Actions palette (searchable command sheet), Custom layouts, Connection Doctor, Search Shortcuts, **Philips JointSpace adapter** (REST v6, digest auth, 1925/1926), **Panasonic Viera adapter** (SOAP, NRC keys, PIN pairing, port 55000). **14 adapters total**: Android TV, Tizen, webOS, Roku, BRAVIA, Fire TV, Vizio, DLNA, Google Cast, DIAL, BroadLink, SwitchBot, Philips, Panasonic. **IR: 10,550 codesets across 2,907 brands** (dual-source). **Tests: 311+**, analysis clean across all packages (0 issues). Remaining: C2 (SessionManager), U4 (real capability detection), U5 (optimistic state), U8 (accessibility), B34/B35 (permissions + tests). |

---

## 1. Maintenance protocol (how these two documents stay true)

This is the operating agreement. It binds every future session.

| Trigger | Update PRD | Update CONTEXT |
|---|---|---|
| Feature added | Yes — new FR-x with acceptance criteria, add to Section 7 pillar table, Section 19 phase | Yes — add row to §6 tracker, log in §12 |
| Feature removed or deferred | Yes — mark FR struck-through with reason + date, move phase in Section 19 | Yes — §6 tracker status → `Dropped`/`Deferred`, log in §12 |
| Open decision resolved | Yes — Section 20 row → **Decided**, ripple into affected sections | Yes — move from §5.2 to §5.1 with rationale + date |
| Scope/priority change (P0↔P1↔P2) | Yes — FR priority tag and Section 19 gate | Yes — §6 tracker |
| Work completed (spike, adapter, screen) | No | Yes — §6 tracker + §4 next actions + §12 log |
| Fact invalidated (market data, protocol, firmware) | Yes — correct in place, note "revalidated <date>" | Yes — log in §12 if it changes a decision |
| Risk materialises | Yes — Section 17 row updated | Yes — §10 watchlist |

**Rules.**
1. PRD version bumps on every substantive change: `v0.1 → v0.2 → …`. Record the bump in the PRD change log **and** in §12 here.
2. Nothing gets removed from the PRD silently. Deletions become strikethrough + reason + date, or a line in the PRD change log. The decision trail is the asset.
3. This file is authoritative for *status*. The PRD is authoritative for *requirements*. If they disagree on a requirement, the PRD wins and this file gets corrected.
4. Every FR referenced in code, commits, or tickets uses its stable PRD ID (`FR-4.1`, `NFR-4`, `OD-6`). IDs are never renumbered.

---

## 2. Product in 60 seconds

One app that (a) controls **any** TV — network protocols for smart platforms, infrared for everything ever made, (b) replaces arrow-key TV typing with the phone keyboard/voice (**the hero feature**), and (c) casts local photos/video/music to the TV.

**Strategy:** a fallback ladder — native network adapter → generic protocols (Cast/DIAL/DLNA) → phone IR → external WiFi-to-IR bridge.
**Moat:** breadth × reliability of the adapter matrix; every firmware quirk absorbed compounds.
**Wedge:** the universal keyboard. It stays free forever — it is the habit hook.
**Trust posture:** zero ads ever, no account required, control plane 100 % local.

---

## 3. Current phase

**Phase: Phase 2 features substantially complete.** The app is running on real hardware (3 TVs validated: Sony BRAVIA 2 II, Haier, Samsung BU8000). ATVRS keyboard typing + submit is the hero feature, fully validated. **Phase 2 WiFi→IR bridge adapters built (25 Nov 2026):** BroadLink RM (local UDP, AES-128-CBC) and SwitchBot Hub (cloud API, opt-in) — 12 adapters total. Manual IR learning built via BroadLink bridge. **OD-6 (IR DB sourcing) FULLY RESOLVED:** 10,550 codesets across 2,907 brands. **Value-add features F1–F5 UI verified on device.** **Feature roadmap added (§12):** 20 prioritised features for Phase 2–3. **v0.1.0 released on GitHub (21 Nov 2026).**

| Gate ahead | Requirement to pass |
|---|---|
| Complete Phase 0 | All 5 MVP platforms green on pairing + keys + text on real devices |
| Start Phase 1 | Phase 0 matrix signed off; OD-3 (stack) confirmed by latency benchmark; OD-6 (IR DB) decided |

---

## 4. Next actions (the only list that matters right now)

0. ✅ **Toolchain resolved** (10 Aug 2026) — Dart SDK 3.12.2 + Flutter 3.47.2.
1. ✅ **Initialise the repo** — done 10 Aug 2026. Two commits on `main`.
2. ✅ **BRAVIA Simple IP validated** — TCP 20060 key sending confirmed on Sony BRAVIA 2 II at 192.168.29.124.
3. ✅ **ATVRS pairing validated** (11 Oct 2026) — full handshake (PairingRequest → PairingOption → PairingConfiguration → PairingSecret) all return status=200 on BRAVIA 2 II. DER cert parser bugs fixed (missing TBS SEQUENCE entry + `skipTlv` compound-assignment side-effect). TV stores client certificate.
4. ✅ **ATVRS keyboard + submit HW-validated** (21 Nov 2026) — Full type-and-search flow confirmed on **Haier** and **Samsung** TVs. Three bugs fixed: (a) malformed DeviceInfo in Configure handshake (field 5 string→uint wire-type mismatch prevented IME provider recognition → on-screen keyboard intercepted KEYCODE_ENTER as 'a'); (b) `editInfo.committed` (field 1) written as varint instead of string — TV silently ignored it, so IME composition was never finalized and submit had no effect; fixed to `writeString(1, text)` for commit, `writeString(1, '')` for composing; (c) text buffer never cleared on submit. Fixes across `atv_messages.dart` (new `buildImeCommit`), `live_atv_channel.dart` + `bravia_atvrs.dart` (DeviceInfo + `_sendImeCommit`), `android_tv_adapter.dart` (commit path + KEYCODE_DEL fallback), `simple_ip_adapter.dart` (`submitText()`). All adapter tests pass, analyzer clean.
5. ✅ **IR control path and supported-device asset catalog built** (11 Oct 2026) — Flipper/LIRC parsers, protocol decoder, codeset builder, community capture, 4 verified fallbacks, and **1,074 generated Flipper IRDB codesets** are bundled for TV/soundbar/AC/projector/media/STB/streaming categories. The app preserves source brand names, loads the index once, loads codesets lazily during Power testing, and emits through Android `ConsumerIrManager`. Integrity verified: 1,074 unique IDs/files, zero missing. **Remaining: hardware-validate emitter detection, carrier handling, latency, and matching quality.** See §15 + §17.
6. ✅ **Debug scaffolding removed** (11 Oct 2026) — no auto-connect, auto-pair trigger, or verbose/sensitive ATVRS receive logging remains.
7. ✅ **Unhandled ATVRS SocketException fixed** (11 Oct 2026) — pre-pairing auto-connect was removed and command/connection futures are guarded.
8. **Validate remaining MVP platforms** — Samsung Tizen, LG webOS, Roku on real hardware. Need physical devices.
9. **Trademark + store-name search for "SANKETA"** (OD-1). Cheap, slow, do in parallel.
10. **Apply for iOS multicast entitlement** — risk R-6, long lead time.
11. ✅ **F1–F5 UI verified on device** (14 Nov 2026) — All 4 Tools sub-features render correctly on OnePlus LE2111 (release APK). Debloat shows 23 entries with severity badges + category filters; Free TV shows 4 tabs + 27 category cards + error/retry; TV Stats shows ADB-required empty state; App Launcher shows not-connected empty state.
12. **F1/F4/F5 ADB-connected functional validation** — Connect phone to Android TV via ADB WiFi, then verify: debloat toggle actually disables/enables packages, TV Stats shows live CPU/memory/storage gauges, App Launcher populates grid and launches apps. Requires an ADB-accessible Android TV on the same network.
13. ✅ **F2 in-app player verified on device** (14 Nov 2026) — Added `video_player` + `chewie` for built-in HLS playback. Watch button opens `PlayerScreen` (Chewie/ExoPlayer, autoplay, landscape support, human-readable errors, retry). Long-press bottom sheet offers 3 options: watch in app, open in external player (url_launcher), cast to TV. Verified live stream (3ABN Kids HLS) playing in the in-app player on OnePlus LE2111.
14. **F3 HLS ad-skip validation on TV** — Test HLS proxy ad-skip on a connected TV via cast. Requires DLNA/Cast-capable TV on same network.
15. **F1/F4/F5 ADB-connected functional validation** — Connect phone to Android TV via ADB WiFi, then verify: debloat toggle actually disables/enables packages, TV Stats shows live CPU/memory/storage gauges, App Launcher populates grid and launches apps.

---

## 5. Decision log

### 5.1 Decided

| ID | Decision | Chosen | Date | Rationale / consequence |
|---|---|---|---|---|
| OD-3 | Stack | Flutter shell + Dart adapters (no native core split) | 11 Oct 2026 | Validated by Phase 0: Flutter release builds run on OnePlus LE2111 (Android 14, ARM64). ATVRS TLS pairing, Simple IP TCP, and protobuf codec all work in pure Dart — no platform-channel overhead for the control path. Latency benchmark deferred (subjective key-press responsiveness is acceptable in testing). Revisit trigger unchanged: >15 ms p95 dispatch overhead |
| OD-2 | Launch geography | India-first | 11 Oct 2026 | Confirmed by hardware lab: Sony BRAVIA (India market) is the first validated device. IR codeset priority: top 25 Indian TV brands + top 10 STB brands |

### 5.2 Open (from PRD Section 20)

| ID | Decision | PRD recommendation | Blocking? | Notes |
|---|---|---|---|---|
| OD-1 | Product name | SANKETA | Store listing only | Needs trademark + store-name search either way |
| OD-2 | Launch geography order | India-first | No — **Decided** | Moved to §5.1 (11 Oct 2026) |
| OD-3 | Stack | Flutter shell + Dart adapters | No — **Decided** | Moved to §5.1 (11 Oct 2026) |
| OD-4 | Minimum OS versions | Android 8.0 / iOS 15 | No | |
| OD-5 | Open-source the adapter layer | Open adapters (Apache 2.0), closed app + IR DB | No | Revisit end of Phase 1 |
| OD-6 | IR database sourcing | Dual-source: Flipper IRDB + Kookong (cipher cracked) | **Fully resolved and implemented** | ~~Research finding (11 Oct 2026): Kookong encrypted → impractical.~~ **SUPERSEDED (11 Oct 2026):** Kookong cipher cracked (position-dependent XOR, magic `0x133a133`, block cycle [1-7]). **9,476 Kookong codesets** (6,809 brand names decrypted) + **1,074 Flipper IRDB** = **10,550 total codesets, 2,907 unique brands**. BrandFamily assigned for Samsung/Sony/LG/Panasonic. Compact "kk" format (23.5 MB). Brand database (`brand_database.json` + `.csv`) created. All assets bundled, tests passing, debug APK built. See §15 + §17 + §18 |
| OD-7 | Web video hand-off scope | Counsel review first, defer if material risk | Blocks FR-7.3 only | Phase 3 concern |
| OD-8 | Analytics consent default | Opt-out with disclosure (opt-in fallback) | No | |
| OD-9 | Apple TV adapter | Time-boxed Phase 2 research spike | No | Only if achievable without private APIs |

---

## 6. Feature status tracker

Status vocabulary: `Not started` · `Spike` · `In progress` · `Built` · `Verified` (AC passing on lab matrix) · `Deferred` · `Dropped`

### Foundation (cross-cutting, not an FR)

| Artifact | Status | Notes |
|---|---|---|
| Repo + skeleton | Built | `git init` on `main`, 10 Aug 2026; **not yet committed** (awaiting go-ahead) |
| `ControlAdapter` contract (§13.3) | Built · compiles clean | `sanketa_core/lib/src/adapter/control_adapter.dart`; `dart analyze` green under strict-casts + strict-raw-types |
| Core domain models | Built · compiles clean | Key, PressType, TextOp, CapabilityMap, Transport, BrandFamily, DiscoveryHints, Device, Pairing, StateDelta, CommandResult |
| Roku adapter (ECP) | Built · unit-tested (mock) | `sanketa_adapters/`; 15 tests green vs a loopback mock ECP server. **Hardware-unvalidated → Phase 0.** Auth-free REST on 8060; live text via `Lit_`; power/keys/text/launch/input/hold all covered |
| Android TV adapter (remote v2) | Built · **pairing HW-validated** | `sanketa_adapters/src/android_tv/`: verified primitives (14 tests) + adapter/pairing (14 tests). **ATVRS pairing validated on Sony BRAVIA 2 II** (11 Oct 2026) — full 4-step handshake, PairingSecret status=200, TV stores cert. New: `der_utils.dart` (X.509 DER parser for RSA key extraction), `bravia_atvrs.dart` (ATVRS protocol impl). **Text injection next.** |
| Tizen / webOS adapters | Built · unit-tested (fakes) | Tizen (WebSocket `SendRemoteKey`/`SendInputString`, token pairing, 7 tests), webOS (SSAP + pointer-button + IME text, client-key pairing, 7 tests). **WS sockets + real hardware → Phase 0** |
| Fire TV adapter | Built · unit-tested (6 tests) | Thin wrapper over `AndroidTvAdapter` with Fire-specific mDNS (`_amzn-wplay._tcp`), menu key, and `BrandFamily.fireTv`. Discovery classifier routes `amazon`/`fire tv`/`amzn-wplay`/`aftm` → `fire_tv` adapter |
| Vizio SmartCast adapter | Built · unit-tested (9 tests) | REST/HTTPS on 7345/9000. Full keymap (codeset/code pairs), PIN-based pairing flow, app launch, input switching, heartbeat. No text injection (SmartCast limitation). `baseUrlOverride` seam for test injection |
| Google Cast adapter | Built · unit-tested | CastV2 protobuf over TLS port 8009. Hand-coded protobuf codec (`cast_channel.dart`). Default Media Receiver launch, LOAD/PAUSE/PLAY/STOP. `probeGoogleCast()` helper for discovery. Controller uses Cast→DLNA fallback order |
| BRAVIA adapter | Built · **partially HW-validated** | Classic IRCC-IP (6 tests) + **Simple IP Control** (`simple_ip_adapter.dart`, TCP 20060, validated on BRAVIA 2 II) + **ATVRS** (`bravia_atvrs.dart`, TLS 6467/6466, pairing validated). WoL magic packet builder (`wol.dart`, unit-tested). Modern BRAVIA uses Simple IP for keys + ATVRS for text — both confirmed working |
| DLNA + DIAL (Rung 2) | Built · unit-tested + **DLNA HW-validated** | `dlna/`: UPnP AVTransport + RenderingControl — play/pause/stop + volume/mute + `playUri` cast entry (7 tests); declares **no d-pad / no text** per FR-3.5. **DLNA SOAP transport verified on real device** (192.168.29.222, 4 Nov 2026): probe succeeds, SetAVTransportURI SOAP sent correctly, UPnP error parsed and mapped to human-readable message. **PRD §12.6 error UX verified on device** — "Cast Failed" screen with actionable message + Dismiss button. `dial/`: app launch/stop/status (3 tests). Broadest "any renderer" coverage |
| Discovery domain (core) | Built · unit-tested | `sanketa_core/src/discovery/`: brand **classifier** (recognises every MVP brand's mDNS/SSDP signature + Control/Keyboard/Cast badges), **dedup registry** (IP-keyed cross-method merge), **engine** with AP-isolation detection; 13 tests |
| Discovery backends (net) | Built · unit-tested + live-clean | `sanketa_discovery/`: **SSDP** (pure `dart:io`), **mDNS** (`multicast_dns`; gracefully degraded on Windows dev host, full on Android/iOS targets), **TCP-probe** (loopback-tested). Live LAN scan runs with 0 backend errors |
| IR encoding engine | Built · unit-tested | `sanketa_ir/`: NEC, NEC-extended, Samsung, Sony SIRC 12/15/20, RC5, raw → carrier Hz + µs pattern. **Verified by round-trip decode** (encode→decode→assert bits); 10 tests. Compiled Sony/NEC waveforms hand-checked correct |
| IR codeset + adapter | Built · unit-tested | Codeset model + **4 bundled codesets** (Sony SIRC, Samsung NEC, LG NEC, Panasonic NEC-ext); `IrControlAdapter` puts IR behind the *same* `ControlAdapter` contract (`Transport.infrared`, `textMode: none` → assist, hold-to-repeat per FR-2.4); 7 tests. Native emit seam (`IrTransmitter`) injected — real `ConsumerIrManager` impl comes with the Flutter app |
| IRDB integration + content | **Built and bundled** · unit/build-tested | **9 modules** in `sanketa_ir/src/irdb/` plus deterministic build tool + Python Kookong converter. **Dual-source: 10,550 codesets** — Flipper (1,074: 373 TV, 251 soundbar, 148 AC, 123 projector, 95 media, 60 STB, 24 streaming) + Kookong (9,476: 3,933 TV, 3,111 STB, 1,505 projector, 762 soundbar, 165 AC). **2,907 brands** with real decrypted names. Compact "kk" format (23.5 MB) with runtime expansion. Brand database (`brand_database.json` + `.csv`) for 1-1 brand lookup. Key coverage: 99.0% (5 AC keys added). **72 IR tests** include Kookong format expansion, codeset round-trips, malformed data, and collision-safe IDs. Kaseikyo + RC6 remain raw timing fallbacks |
| IR AC full-state (Coolix) | Built · unit-tested | `ir/ac/`: `AcState` + `AcEncoder` interface + **Coolix encoder** + `IrAcController` (stateful: temp±/mode/fan/power re-emit the full frame); 9 tests. OFF code + temp gray-table verified; ON-frame field placement flagged for Phase 0 (FR-2.5) |
| D-pad assist typer | Built · unit-tested | `ir/assist/`: shortest-path arrowing over an on-screen keyboard grid with wrap optimisation; one OK per char (FR-4.4 AC); 6 tests. Pure algorithm, fully verified |
| Conformance suite | Not started | One script, every adapter (FR-3.1 AC ≥95%). The 8 adapter test files seed it |
| Design tokens (`sanketa_design`) | Built · unit-tested | Pure-Dart OmniBeam token system (colours, Plus Jakarta + JetBrains Mono type, spacing, radii, elevation) transcribed from `design/`; 12 tests. Flutter wraps them in ThemeData/Color/TextStyle |
| Flutter app shell (`sanketa_app`) | Built · **runs on device** | **5 screens**: Remote (D-pad, keyboard, source toggle, vol/ch rockers), Search, Cast, Devices, Settings — all inside `AppShell` with bottom nav. Connection bar, **live TV-keyboard sync** (the hero), auto-pair trigger. Wired to **all platform adapters** via `RemoteController` adapter factory: BRAVIA (Simple IP + ATVRS), webOS (`LiveWsChannel`), Tizen (`LiveWsChannel` wss), Android TV (`LiveAtvChannel`), Fire TV (`LiveAtvChannel`), Roku (HTTP), Vizio (HTTPS), DLNA (SOAP), + IR. Cast auto-probe cascade: Google Cast (TLS 8009) → DLNA (UPnP). Device name hash suffixes stripped in controller + devices screen. **Deployed and tested on OnePlus LE2111** (Android 14, release mode). Key files: `remote_controller.dart`, `app_shell.dart`, `ir_setup_sheet.dart`, `bridge_ir_transmitter.dart`, `ir_device_service.dart`, `live_ws_channel.dart`, `live_atv_channel.dart`, session manager (`sanketa_core/src/session/`) |

### MVP (Phase 1) — all P0 unless noted

| FR | Feature | Priority | Status | Notes |
|---|---|---|---|---|
| FR-1.1 | Zero-input LAN discovery (mDNS + SSDP + probes) | P0 | Built · unit-tested | Network path done: SSDP + mDNS + TCP-probe backends, IP-keyed dedup, brand + capability badges, AP-isolation detection. Remaining: auto subnet-scan candidate list for probe, and real-device validation (Phase 0 AC: GTV+Samsung+Roku all appear <6 s) |
| FR-1.2 | Permission choreography | P0 | Not started | iOS Local Network prompt is funnel risk R-2 |
| FR-1.3 | Manual add (IP / brand+model / QR) | P0 | Not started | |
| FR-1.4 | Per-platform pairing flows | P0 | Built · **BRAVIA HW-validated** | ATV code handshake: **ATVRS pairing validated on real BRAVIA 2 II** (full 4-step TLS handshake, PIN entry, SHA-256 secret exchange, status=200). Tizen token, webOS client-key, Roku no-auth — unit-tested. Persisting secrets to Keystore/Keychain is the native Phase-1 wiring |
| FR-2.1 | IR hardware detection | P0 (Android+IR) | **Built** · Android build-verified | Native method channel calls `ConsumerIrManager.hasIrEmitter()` and exposes carrier ranges; async status is reflected in the setup wizard. Requires real IR-phone validation |
| FR-2.2 | IR code database | P0 | **Built and bundled** · unit/build-tested | Dual-source: Flipper IRDB + Kookong (cipher cracked). **10,550 codesets** (1,074 Flipper + 9,476 Kookong) across **2,907 brands, 7 device types**. By device: 4,306 TV, 3,171 STB, 1,628 projector, 1,013 soundbar, 313 AC, 95 media renderer, 24 streaming. Kookong brand names decrypted (6,809 names, 14 languages). Compact "kk" format (23.5 MB). BrandFamily assignment for Samsung/Sony/LG/Panasonic. Brand database with 1-1 mapping. Remaining: hardware quality/coverage validation and community gap-fill |
| FR-2.3 | Guided codeset matching wizard | P0 | **Built (full catalog)** · UI-tested | Devices screen wizard: brand pick → ranked codeset candidates (verified fallback first, then key coverage) → Power test → user confirmation; full codesets load lazily (Kookong prefix routing) and failed/no-match paths are handled. **10,550 codesets from 2,907 brands searchable** via brand name or free text. Remaining: replace heuristic ordering with market/popularity evidence and validate on IR hardware |
| FR-2.4 | IR emission quality (<100 ms, repeats) | P0 | Built (logic) · unit-tested | Correct carrier per protocol, pre-baked patterns, NEC/Samsung repeat frames, hold-to-repeat in the adapter. Real tap-to-emit latency needs a device (Phase 0) |
| FR-2.5 | Beyond-TV IR devices (AC, soundbar, STB, projector) | P0 | Built · unit-tested | Stateless protocols cover STB/soundbar/projector via codesets; **AC full-state encoder built** (Coolix + `IrAcController`, stateful frames). More AC protocols (Gree/Daikin) + on-device validation Phase 0 |
| FR-2.6 | No IR learning on phones (explicit non-feature) | — | N/A | Bridge-only, FR-8 |
| FR-3.1 | Command coverage, all MVP adapters | P0 | **7 of 7 built + wired** · unit-tested | Roku, Android TV, Tizen, webOS, BRAVIA, Fire TV, Vizio SmartCast — all composed + tested with mocks/fakes + **all wired in RemoteController's adapter factory** with production socket implementations (`LiveWsChannel`, `LiveAtvChannel`). Google Cast + DLNA casting adapters also wired (Cast→DLNA auto-probe cascade). Conformance suite + real-device runs are Phase 0 |
| FR-3.2 | Session behaviour (persistent conn, backoff) | P0 | Not started | |
| FR-3.3 | Power-on paths (WoL/WoWLAN) | P0 | Built · unit-tested | WoL magic packet builder (`sanketa_adapters/src/common/wol.dart`) — constructs 102-byte magic packet; caller sends UDP broadcast. Unit test verifies packet structure |
| FR-3.4 | State readback where available | P0 | Not started | Omit claims where write-only |
| FR-3.5 | Graceful capability degradation | P0 | Built (core) · unit-tested | Every adapter emits a `CapabilityMap`; **DLNA proves it** — declares no d-pad, no text (tested). UI consumption lands with the Flutter shell (Phase 1) |
| FR-4.1 | **Live text injection (hero)** | P0 | Built · **BRAVIA pairing validated** | Roku `Lit_`, Android TV IME (ATVRS), Tizen `SendInputString`, webOS `insertText`, BRAVIA `setTextForm` — every MVP adapter has a live-text path, tested. **ATVRS pairing validated on BRAVIA** — text injection via `sendText()` is the next verification step. The hero feature is one `connect()` call away from real-hardware proof |
| FR-4.2 | Voice-to-TV | P0 | Not started | Audio never leaves phone except to OS speech service |
| FR-4.5 | Field-state honesty copy | P0 | Not started | |
| FR-5.1–5.5 | Remote UI, trackpad, haptics, simple mode, a11y | P0 | Partial · **runs on device** | **10-screen app** (Remote, Search, Cast, Tools, Devices, Settings + Debloat, Macros, Doctor, Layouts, Shortcuts, Touchpad) with bottom nav. D-pad/Touchpad toggle in Remote, Quick Actions sheet, Sleep Timer. **Deployed on OnePlus LE2111.** Remaining: haptics, simple mode, full a11y pass |
| FR-6 | App launching + input switching | P0 | Partial · **DIAL HW-validated** | Launch: webOS `system.launcher`, Roku `/launch`, **DIAL** app-launch **wired into SimpleIpAdapter for BRAVIA** (5 Nov 2026) — Netflix launch confirmed on BRAVIA BF1 via DIAL port 8008. `dialAppName()` normalises display names to DIAL app IDs. Input switching via per-adapter keys. YouTube/Disney+/Prime not DIAL-registered on Google TV BRAVIAs (need Android Intent path). Android TV app-link + more Phase 0 |
| FR-7.1 | Local media casting (Cast + DLNA + Roku) | P0 | Built · **DLNA + Google Cast HW-validated** | **Google Cast adapter built** (5 Nov 2026): full CastV2 protobuf over TLS port 8009, Default Media Receiver launch, LOAD/PAUSE/PLAY/STOP, heartbeat. Controller tries Google Cast first, DLNA fallback. Cast screen shows protocol badge ("Google Cast" / "DLNA"). **DLNA casting verified on device** (4 Nov 2026). Remaining: test Google Cast on real Chromecast/BRAVIA, codec pre-flight |
| FR-10 | Settings, **connection doctor**, diagnostics | P0 | **Partial — Doctor built** (25 Nov 2026) | `ConnectionDoctorScreen`: 7 guided checks (network, gateway, DNS, TV reachable, control port, adapter handshake, command round-trip). Remedy cards. Accessible from Tools screen. Settings screen exists. Full diagnostics export TBD |

### Fast-follow / later phases

| FR | Feature | Priority | Phase | Status |
|---|---|---|---|---|
| FR-3.6 | Fire TV advanced via ADB (opt-in, default off) | P1 | 2 | **Basic control built** — Fire TV adapter uses ATVRS (same as Android TV); ADB opt-in advanced features remain Phase 2 |
| FR-4.3 | Search shortcuts (Roku ECP search, deep links) | P1 | 2 | **Built** (25 Nov 2026) | `SearchShortcutsScreen` + `SearchShortcutsWidget`: save, reorder, replay queries. JSON persistence. Tools screen wired |
| FR-4.4 | D-pad assist fallback (shortest-path arrowing) | P1 | 2 | **Built · unit-tested** — `AssistTyper` over a keyboard grid with wrap optimisation; one OK per char. Pure algorithm, verified |
| FR-7.2 | Screen mirroring (MediaProjection / ReplayKit) | P1 | 2 | Not started |
| FR-7.3 | Web video hand-off | P1 | 3 | **Blocked on OD-7** (counsel) |
| FR-8 | Bridge hardware (BroadLink-class) | P1 | 2 | **Built** — BroadLink RM adapter (local UDP, AES-128-CBC, IR send + learn) + SwitchBot Hub adapter (cloud API, opt-in) + BroadLink discovery backend + endpoint classifier + RemoteController wiring |
| FR-9.1 | Rooms and profiles | P1 | 2 | Not started |
| FR-9.5 | Backup / encrypted sync | P1 | 2 | Not started |
| FR-9.2 | Macros / activities | P2 | 2 | **Built** (25 Nov 2026) | `MacroService` (record/play/stop, JSON persistence) + `MacroScreen` (step builder, 14 actions). Wired into RemoteController key recording |
| FR-9.3 | Widgets and quick-settings tiles | P2 | 3 | Not started |
| FR-9.4 | Wearables (Wear OS / watchOS) | P2 | 3 | Not started |

### Value-add features (F1–F5)

| ID | Feature | Priority | Status | Notes |
|---|---|---|---|---|
| F1 | **TV Debloat Tool** | P1 | **Built** · **UI verified on device** | ADB `pm disable-user --user 0` with per-brand safe lists. `DebloatService` (ADB connect/scan/disable/enable), `BloatwareDatabase` JSON asset (`assets/debloat/bloatware_db.json`: 100 entries, 10+ brands [xiaomi/samsung/sony/fire_tv/hisense/tcl/haier/vizio/panasonic/all_android_tv], 5 categories, 3 severity levels), full UI (`debloat_screen.dart`): brand detection, category filter chips, search, safe-only toggle, per-package enable/disable with progress indicators, manual IP entry. Whitelisted ADB commands only; package name regex validation. Tools screen routes here. **On-device verified (14 Nov 2026):** "Not connected" badge (connection-aware), search bar, category filters (All/Ads/Telemetry/Bloatware/Google/OEM), 23 entries with HIGH/MED severity badges all render correctly. **Remaining: ADB disable/enable toggle validation on connected TV** |
| F2 | **Free TV / IPTV Cast** | P1 | **Built** · **UI verified + playback verified on device** | M3U parser (instance-based, NSFW filtering, XSS sanitisation), 10K+ channels from iptv-org (27 by-category, 20 by-country, 20 by-language sources), `IptvService` (fetch/parse/cache/favorites with VPN-aware error messages + HttpClient recycling). Full UI (`iptv_screen.dart`): 4-tab browsing (Categories/Countries/Languages/Favorites), channel list with search, favorites, **Watch + Cast buttons per channel** + long-press bottom sheet (Watch in app / Open in external player / Cast to TV). **In-app player** (`player_screen.dart`): `video_player` + `chewie` with full controls, loading state, error fallback, landscape support. `url_launcher` fallback for external players. Integrated into Tools screen as "Free TV" card. **On-device verified (14 Nov 2026):** 185 Animation channels loaded, Watch/Cast buttons render, **in-app player streams live video successfully** (3ABN Kids HLS confirmed). VPN/DNS issue diagnosed and resolved (HttpClient stale DNS caching fix + human-readable error messages). |
| F3 | **HLS Ad-Segment Skipping** | P1 | **Built** · integrated | `HlsFilter` in `sanketa_core/src/iptv/hls_filter.dart`: SCTE-35 marker detection, CUE-OUT/CUE-IN, DATERANGE, OATCLS/ASSET markers stripped. `HlsProxyServer` in `sanketa_adapters/src/hls/hls_proxy.dart`: LAN-bound, token-gated reverse proxy that fetches HLS manifests, filters ad segments via `HlsFilter`, rewrites relative URLs to absolute, and serves cleaned manifests to TV. Wired into `RemoteController.castUri()`: `.m3u8` URLs auto-routed through proxy; non-HLS URLs pass through unchanged. `IptvScreen` sends correct `application/x-mpegURL` mime type. No DRM circumvention. **Remaining: on-device IPTV stream validation** |
| F4 | **TV Performance Dashboard** | P1 | **Built** · **UI verified on device** | `TvStatsService` (ADB `dumpsys meminfo`/`top`/`df` stats, 5s poll timer). Full UI (`performance_screen.dart`): memory (MB used/total), CPU (user%/sys%), storage (circular indicator), top processes list. Colour-coded thresholds: green <65% < amber <85% < red. Integrated into Devices screen → TV Tools section (Android TV only). **On-device verified (14 Nov 2026):** "ADB Connection Required" state renders correctly with gauge icon, explanation text, and Retry button. **Remaining: live stats validation on ADB-connected TV** |
| F5 | **Smart App Launcher** | P1 | **Built** · **UI verified on device** | `AdbClient.getInstalledApps()` for app enumeration. Full UI (`app_launcher_screen.dart`): 3-column grid, search, system/user filter toggle, pin-to-top via long press. Launch: tries adapter `launchApp()` first, falls back to ADB. Integrated into Devices screen → TV Tools section (Android TV only). **On-device verified (14 Nov 2026):** "TV Apps" header with grid icon (error badge) + refresh button renders correctly. "No TV connected" empty state displays properly. **Remaining: app grid + launch validation on ADB-connected TV** |

### Explicit non-goals (v1) — do not build, do not accept scope creep

General smart-home control · DRM circumvention of any kind · cloud-relay / out-of-home control · TV-side receiver app as a v1 dependency · voice-assistant platform skills · Windows/desktop clients.

---

## 7. Adapter status board

Statuses: `Unvalidated` (Phase 0 pending) · `Validated` · `Built` · `Conformance-passing` (≥95 % of declared command set)

| Platform | Phase | Transport | Text capability | Status |
|---|---|---|---|---|
| Android TV / Google TV | MVP | protobuf/TLS, 6466/6467 | live | **Pairing HW-validated on BRAVIA 2 II** (11 Oct 2026). Full ATVRS handshake succeeds; DER cert parser + pairing hash verified on real TLS certs. Text injection pending connect() validation |
| Samsung Tizen | MVP | WebSocket, 8001/8002 | live (field-dependent) | **Adapter built + unit-tested (fake WS) + wired in controller** via `LiveWsChannel` (`wss://host:8002/api/v2/...`); sockets/token Unvalidated (Phase 0) |
| LG webOS | MVP | SSAP WebSocket, 3000/3001 | live (IME service) | **Adapter built + unit-tested (fake WS) + wired in controller** via `LiveWsChannel` (`ws://host:3000`); pointer-socket + sockets Unvalidated (Phase 0) |
| Roku | MVP | ECP REST, 8060 | literal keys + search endpoint | **Adapter built + unit-tested (mock)**; protocol Unvalidated on real hardware (Phase 0) |
| Sony BRAVIA | MVP | Simple IP (TCP 20060) + ATVRS (TLS 6466/6467) + DIAL (8008) | live | **Partially HW-validated** (11 Oct 2026). Simple IP keys ✅ + ATVRS pairing ✅ + **DIAL app launch ✅** (Netflix confirmed running, 5 Nov 2026) + **Google Cast ✅** (CastV2 TLS port 8009) on BRAVIA 2 II (BF1, Google TV). Classic IRCC-IP adapter also built (older models). WoL built. Text injection pending |
| Infrared (any TV) | MVP | ConsumerIrManager | none → assist mode | Encoders, **10,550 codesets (1,074 Flipper + 9,476 Kookong) across 2,907 brands + 4 verified fallbacks**, source-brand lazy catalog, Android native emitter bridge, and guided Power-test matching are built. Key coverage: 99.0% mapped. **Remaining: hardware-validate emission and matching quality** |
| Fire TV | MVP | ATVRS (TLS 6466/6467) + DIAL | live (same as Android TV) | **Adapter built + unit-tested (6 tests) + wired in controller** via `LiveAtvChannel` (TLS 6466); thin wrapper over AndroidTvAdapter with Fire-specific mDNS (`_amzn-wplay._tcp`) and menu key. Discovery via classifier. HW-unvalidated (Phase 0) |
| Vizio SmartCast | MVP | REST/HTTPS, 7345/9000 | none | **Adapter built + unit-tested (9 tests) + wired in controller**; full keymap (codeset/code pairs), app launch, PIN-based pairing, heartbeat. HW-unvalidated (Phase 0) |
| Panasonic Viera | 2 | SOAP, 55000 | partial | **Adapter built** (25 Nov 2026) — SOAP on port 55000, full key map (NRC_*-ONOFF), app launch via X_LaunchApp, PIN-based pairing (X_DisplayPinCode/X_RequestAuth) for 2019+ models. Wired in RemoteController. HW-unvalidated |
| Philips JointSpace | 2 | REST, 1925/1926 | partial | **Adapter built** (25 Nov 2026) — JointSpace REST v6, port 1925 (HTTP)/1926 (HTTPS), POST /input/key for keys, /activities/launch for apps, volume readback via GET /audio/volume, Digest auth pairing for 2016+ models. Wired in RemoteController. HW-unvalidated |
| Hisense VIDAA | 2 | MQTT, 36669 | partial | Unvalidated |
| TCL | 2 | Model-routed | per route | Unvalidated |
| Generic DLNA | 2 | UPnP AVTransport | none | **Adapter built + unit-tested + HW-validated** (4 Nov 2026) — transport + volume + `playUri`; SOAP transport verified on real device (192.168.29.222). UPnP probe succeeds, SOAP faults parsed correctly, human-readable errors mapped (PRD §12.6). Test device has AVTransport but doesn't support casting; need a DLNA renderer that supports playback to validate "now playing" state |
| DIAL (app launch) | 2 | SSDP + REST | n/a | **Client built + unit-tested (mock HTTP)** — launch/stop/status |
| BroadLink RM (WiFi→IR bridge) | 2 | UDP 80, AES-128-CBC | IR relay (any TV) | **Built** (25 Nov 2026) — full protocol: discovery (UDP broadcast), auth (AES-128-CBC, initial key + IV), IR send (sub-cmd 0x02), IR learn (sub-cmd 0x03/0x04 poll). Supports RM Mini 3, RM Pro, RM4 Mini, RM4 Pro. `BroadLinkTransmitter` implements `IrTransmitter` for bridge-based IR. Discovery backend self-contained (no circular dep). Endpoint classifier routes `broadlink` attribute → adapter. Wired in `RemoteController`. **Remaining: hardware validation on real BroadLink device** |
| SwitchBot Hub (WiFi→IR bridge) | 2 | REST `api.switch-bot.com` | IR relay (any TV) | **Built** (25 Nov 2026) — cloud-only adapter (HMAC-SHA256 auth, 10K calls/day rate limit). Sends IR via `/v1.1/devices/{id}/commands` with `customize` command type. No local LAN API (SwitchBot limitation). **Privacy caveat: cloud dependency conflicts with "zero server calls" red line — opt-in only, clearly disclosed to user.** No IR learning support (SwitchBot app only). **Remaining: hardware validation** |
| Apple TV | P2 research | Companion (reverse-engineered) | — | Not pursued (OD-9) |

---

## 8. Architecture quick reference

```
Flutter UI shell  →  RemoteController (adapter factory + cast probe cascade)
                  →  Core domain (DeviceRegistry, SessionManager, CommandRouter,
                     CapabilityMap, CastCoordinator, QueueEngine, PairingVault)
                  →  Discovery engine | Adapter set | Casting engine
                  →  Production sockets: LiveWsChannel (webOS/Tizen) | LiveAtvChannel (ATV/Fire TV)
Native modules: IR emit · MediaProjection/ReplayKit · Bonjour/NSD · Keystore/Keychain
                · HW encoder · WoL raw sockets
```

**The one interface that matters** (PRD §13.3) — everything above it is brand-blind:

```
ControlAdapter: discoveryHints() · capabilities() · pair() · connect/disconnect/heartbeat
                sendKey(Key, PressType) · sendText(TextOp) · launchApp() · setInput()
                power(on|off) · readState()
```

**Non-negotiable design rules.**
- Adding a brand touches **zero core code** (NFR-14). Every quirk lives inside its adapter.
- **Capability flags drive UI, never brand names.** Users never see a dead button.
- Adapters are stateless above the session object.
- One conformance suite, identical script, every adapter.
- Data model: Household > Rooms > Devices; local-first (SQLite/Drift); secrets live only in Keystore/Keychain, DB holds references.

---

## 9. Standing constraints — the red lines

Violating any of these is a defect regardless of what the ticket says.

| # | Constraint | Source |
|---|---|---|
| 1 | **Typed text is never logged, analysed, or transmitted anywhere except the target TV.** CI check scans the analytics schema. | PRD §14.3 |
| 2 | **Zero third-party ads, ever.** Peel is the cautionary precedent. | PRD §15 |
| 3 | **Control plane makes zero calls to SANKETA servers.** Verifiable by packet capture; stated publicly. | NFR-11 |
| 4 | **No account required for anything** except optional encrypted sync. | PRD §14.2 |
| 5 | **No DRM circumvention.** Mirroring shows black frames on protected apps and says so honestly. | PRD §5.3.2 |
| 6 | **IR path works fully offline.** No network dependency on the control path. | FR-2.2, NFR-8 |
| 7 | **Never paywall the keyboard or basic control.** | PRD §15 |
| 8 | **No raw error codes in primary UI copy.** Every failure gets a human explanation + one actionable step. | PRD §12.6 |
| 9 | **No private-API use, no accessibility-service abuse, no background location.** | PRD §14 store policy |
| 10 | **Pairing secrets only in hardware-backed stores**; media server LAN-bound, tokened, ephemeral. | NFR-10 |

---

## 10. Risk watchlist (active)

| ID | Risk | Current state | Trigger to escalate |
|---|---|---|---|
| R-1 | Pairing hell across firmware fragmentation | Unmitigated — Phase 0 is the mitigation | Any MVP platform failing Phase 0 pairing |
| R-2 | iOS Local Network denial guts funnel | Unmitigated — needs explainer design + instrumentation | Phase 2 start |
| R-5 | IR DB gaps or licensing challenge | **Fully mitigated** — OD-6 resolved: dual-source database (10,550 codesets, 2,907 brands). Kookong cipher cracked, all India-priority brands covered (Samsung, Sony, LG, Panasonic, Xiaomi, Hisense, TCL, Haier, Toshiba, Sharp, OnePlus, Vu, Skyworth, Tata Play STBs, Airtel STBs). Residual risk: niche brands missing from both sources — community capture (FR-8) fills gaps | No longer expected to trigger |
| R-6 | iOS multicast entitlement delay | **Unmitigated — application not yet filed** | Apply now (next action #3) |
| R-8 | Solo-builder scope drowning across 12+ adapters | Structurally mitigated by adapter contract + phase gates | Any attempt to widen MVP past 5 adapters |
| R-10 | Platform ships this natively | Monitoring only | Google/Apple beta notes each June/September |

**Pre-mortem, top cause:** shipped too many brands too shallow; pairing reliability never crossed the trust threshold. **The ordering rule that prevents it: reliability before breadth.** Five adapters done well beats twelve done partially.

---

## 11. Targets worth memorising

| Metric | Target |
|---|---|
| First open → first successful command | < 90 s median (G-1) |
| Weekly actives using text input | ≥ 40 % (G-2) |
| Command latency, network | p50 < 120 ms, p95 < 250 ms (NFR-1) |
| Command latency, IR tap→emit | < 100 ms (NFR-2) |
| Keyboard per-character latency | p95 < 300 ms, zero reordering (NFR-4) |
| Pairing success per attempt, MVP brands | ≥ 85 % |
| Adapter conformance to ship | ≥ 95 % of declared command set |
| Crash-free sessions | ≥ 99.5 % (NFR-7) |
| D30 retention | ≥ 25 % (G-5) |
| Free→paid conversion @ month 6 | 2–4 % with rating ≥ 4.3 (G-6) |
| Brand-breakage → fix shipped | < 7 days |

---

## 12. Feature roadmap (beyond MVP)

Prioritised feature ideas for Phase 2+. Each is sized relative to the existing architecture — the `ControlAdapter` contract + capability-flag UI pattern means most of these touch zero core code.

| # | Feature | Phase | Effort | Depends on | Description |
|---|---|---|---|---|---|
| 1 | **Touchpad / Trackpad Mode** | 2 | M | webOS pointer socket, ATV touch events | **Built** (25 Nov 2026). `TouchpadSurface` widget: swipe→D-pad (threshold-based), tap→OK, double-tap→Back, long-press→Menu, crosshair painter + delta indicator. `_ModeToggle` chip in RemoteScreen + standalone `TouchpadScreen` in Tools. |
| 2 | **Macro / Scene Automation** | 2 | L | Adapter command queue | **Built** (25 Nov 2026). `MacroService` (ChangeNotifier): record/play/stop, persists to `macros.json`. `MacroScreen`: create dialog with step builder (14 actions), play/stop per macro, delete. Wired into RemoteController (`recordStep` on every key press). |
| 3 | **Sleep Timer / Auto-Off** | 2 | S | Power command | **Built** (25 Nov 2026). `SleepTimerService` (ChangeNotifier): countdown timer, `onExpired` → `power(false)`. `SleepTimerSheet` bottom sheet with 6 presets (15m–2h), active timer badge in RemoteScreen header, +15min/cancel controls. |
| 4 | **Parental Controls** | 2 | M | App launcher (F5) + debloat (F1) | **Built** (25 Nov 2026). `ParentalControlService` (ChangeNotifier): PIN setup/verify/clear, lock/unlock, blocked key sets, daily time limits, usage tracking. `ParentalControlsScreen`: status card, lock toggle, per-key blocking (7 keys), time limit presets (None/30m/60m/90m/2h/3h), danger zone (remove PIN). Wired into RemoteController (`isKeyBlocked` check on every key press). |
| 5 | **Multi-Room Dashboard** | 2 | L | FR-9.1 (rooms) | Control multiple TVs from one screen — volume all, power all, per-room quick-switch. Needs room/profile data model (FR-9.1) |
| 6 | **Custom Remote Layouts** | 2 | M | — | **Built** (25 Nov 2026). `CustomLayoutService` persists layout profiles as JSON. `CustomLayoutScreen` with drag-and-drop grid editor. Accessible from Tools screen. |
| 7 | **Connection Doctor / Diagnostics** | 2 | M | — | **Built** (25 Nov 2026). `ConnectionDoctorScreen` with guided troubleshooting: port scan, protocol probe, "why can't I connect?" wizard. Accessible from Tools screen. |
| 8 | **Screen Mirroring** | 2 | XL | MediaProjection (Android), ReplayKit (iOS) | Cast phone screen to TV via Google Cast or Miracast. DRM-protected apps show black + honest message (red line #5). Maps to FR-7.2 |
| 9 | **Voice-to-TV** | 2 | M | OS speech service | **Built** (25 Nov 2026). `VoiceService` (ChangeNotifier): `speech_to_text` plugin integration, listen/stop/clear. `VoiceScreen`: mic button, transcript display, "Send to TV" + "Clear" actions, unavailable empty state when plugin not ready. Privacy: audio stays on-device, only text sent to TV (red line #1). |
| 10 | **Quick Actions / Command Palette** | 2 | S | — | **Built** (25 Nov 2026). `QuickActionsSheet`: searchable command palette in DraggableScrollableSheet, 10+ actions (power, mute, vol, home, back, sleep timer, HDMI 1/2) + app shortcuts (Netflix, YouTube, Prime, Disney+) gated on `appLaunch` capability. Bolt icon in RemoteScreen header. |
| 11 | **TV Usage Analytics / Screen Time** | 3 | M | ADB stats (F4) | **Built** (25 Nov 2026). `UsageService` (ChangeNotifier): session tracking (start/end), JSON persistence, today/weekly/hourly aggregation. `UsageAnalyticsScreen`: today's total, weekly bar chart, peak hours horizontal bars, recent session list, clear history. All data local-only (red line #3). |
| 12 | **Network Diagnostics** | 3 | S | — | **Built** (25 Nov 2026). `NetworkDiagnosticsScreen`: network info card (local IP, interface), 5-step diagnostic runner (local network, TV reachable with latency, control port scan of 8 known ports, DNS resolution, internet access). Pass/warn/fail icons per check. |
| 13 | **Widgets / Quick-Settings Tiles** | 3 | M | Android/iOS platform channels | Home screen widget: power toggle, volume, favourite channel. Android quick-settings tile for mute. Maps to FR-9.3 |
| 14 | **Wearable Companion** | 3 | L | Wear OS / watchOS SDK | Volume/mute/power from wrist. Minimal surface — the watch is a secondary remote, not a full UI. Maps to FR-9.4 |
| 15 | **Backup / Encrypted Sync** | 3 | L | E2EE, cloud storage | Cross-device sync of rooms, profiles, macros, IR codesets. End-to-end encrypted; no account for local use (red line #4). Maps to FR-9.5 |
| 16 | **Search Shortcuts** | 2 | S | Per-adapter deep links | **Built** (25 Nov 2026). `SearchShortcutsScreen` + `SearchShortcutsWidget`: save, reorder, and replay search queries. Persisted to JSON. Accessible from Tools screen. |
| 17 | **Panasonic Viera Adapter** | 2 | M | SOAP 55000 | **Built** (25 Nov 2026). Full SOAP protocol on port 55000: NRC_*-ONOFF key format, X_LaunchApp, PIN-based pairing (2019+). Wired in RemoteController + barrel export. HW-unvalidated. |
| 18 | **Philips JointSpace Adapter** | 2 | M | REST 1925/1926 | **Built** (25 Nov 2026). JointSpace REST v6: keys, app launch, volume readback, Digest auth pairing (2016+). Ports 1925/1926. Wired in RemoteController + barrel export. HW-unvalidated. |
| 19 | **Hisense VIDAA Adapter** | 3 | L | MQTT 36669 | MQTT-based protocol for VIDAA OS. Reverse-engineering needed; partial community docs exist |
| 20 | **Web Video Hand-off** | 3 | M | OD-7 (legal counsel) | Share a URL from phone browser → TV opens it. Blocked on legal review for content redirection. Maps to FR-7.3 |

**Sizing key:** S = < 1 week, M = 1–2 weeks, L = 2–4 weeks, XL = 4+ weeks (solo builder).

---

## 13. Change log

| Date | Change | PRD version | By |
|---|---|---|---|
| 09 Aug 2026 | PRD v0.1 drafted — 21 sections, 3 appendices, 9 open decisions | v0.1 | Ankit Jha |
| 10 Aug 2026 | CONTEXT.md created; maintenance protocol established; PRD given a change-log section and companion-document reference | v0.1 (structural only, no requirement changes) | Claude |
| 10 Aug 2026 | Build started. Repo initialised (`main`); `sanketa_core` package written with the `ControlAdapter` contract + domain models. No requirement change → PRD deliberately untouched. Discovered Dart/Flutter SDK is not installed → toolchain decision raised (§13). | v0.1 (no requirement change) | Claude |
| 10 Aug 2026 | Toolchain DECIDED → Dart SDK 3.12.2 installed. `sanketa_core` compiles clean. Built `sanketa_adapters` with the **Roku/ECP adapter** (first concrete adapter) + 15 passing unit tests against a mock ECP server + a runnable `example/roku_ping.dart`. PRD untouched (no requirement change). | v0.1 (no requirement change) | Claude |
| 10 Aug 2026 | Built the **discovery engine** toward universal coverage (FR-1.1). Core discovery domain in `sanketa_core` (classifier + dedup registry + engine, 13 tests) and real socket backends in new `sanketa_discovery` package (SSDP + mDNS + TCP-probe, 5 tests). Fixed a Windows-only `multicast_dns` limitation found by running the live scan. 33 tests total, all green; live LAN scan runs error-free. PRD untouched (universal-coverage thesis already in §1/§10/§11 — no requirement change). | v0.1 (no requirement change) | Claude |
| 10 Aug 2026 | Built the **IR subsystem** (Rung 3 — the "old / any brand ever made" backstop) in new `sanketa_ir` package: protocol encoders (NEC, NEC-ext, Samsung, Sony SIRC 12/15/20, RC5, raw) compiling to carrier + µs timing, a codeset model with a real Sony SIRC codeset, and an `IrControlAdapter` unifying IR under the `ControlAdapter` contract with hold-to-repeat. 17 new tests (encoders verified by round-trip decode). **50 tests total across 4 packages, all green.** Covers FR-2.4 (logic) and models FR-2.2; native emit + DB (OD-6) remain. PRD untouched. | v0.1 (no requirement change) | Claude |
| 10 Aug 2026 | Built the **Android TV / Google TV adapter** (remote protocol v2) — the keyboard-hero platform — in `sanketa_adapters/src/android_tv/`. Verified primitives: a protobuf wire codec (asserted against protobuf's canonical byte vectors), varint framing, the Android keycode map, and the pairing-secret SHA-256; then the adapter + one-time pairing session composed over an injected TLS-channel seam. 28 new tests (14 primitives + 14 adapter/pairing). Caught and fixed a test-harness hang (awaiting `close()` on a listener-less single-subscription controller). **78 tests total across 4 packages, all green.** Advances FR-3.1 (2/5) and FR-4.1. Wire field-numbers, TLS/cert, and IME text flagged for Phase 0. PRD untouched. | v0.1 (no requirement change) | Claude |
| 4 Sep 2026 | **Completed the control matrix + IR in one pass.** Added 3 network adapters — **Tizen** (WebSocket, token pairing, `SendInputString`), **webOS** (SSAP + pointer-button + IME text, client-key pairing), **BRAVIA** (classic IRCC-IP SOAP + PSK + `setTextForm`) — plus Rung-2 generics **DLNA** (AVTransport/RenderingControl + `playUri`) and **DIAL** (app launch). Then finished IR: **Coolix AC full-state encoder** + `IrAcController` (stateful frames, FR-2.5) and the **D-pad assist typer** (shortest-path arrowing with wrap, FR-4.4). Fixed a DIAL URL-builder bug (`Uri.resolve('/x')` wiped the base path) caught by tests. **All 5 MVP adapters now built** (FR-3.1 5/5), live text on all (FR-4.1). **123 tests total across 4 packages, all green; analyze clean.** Everything composed over injected seams; wire schemas/TLS/native-emit flagged for Phase 0. PRD untouched. | v0.1 (no requirement change) | Claude |
| 4 Sep 2026 | **Incorporated the UI design** (Stitch "OmniBeam" export, tracked under `design/`). Installed **Flutter 3.47.2**. New `sanketa_design` package — the full token system as pure Dart (12 tests). New `sanketa_app` Flutter package — the **Remote screen** faithful to the mockup (connection bar, live TV-keyboard sync, tactile D-pad, source toggle, vol/ch rockers, app shortcuts, bottom nav), every control wired to the `ControlAdapter` contract via a `DemoAdapter`; `flutter analyze` clean, 6 tests. **141 tests total across 6 packages.** Fixed a nav overflow; the widget test builds the whole tree. The live web preview can't render in this session's embedded pane (Flutter `flt-glass-pane` 0×0 surface quirk) — verified via tests instead. PRD untouched (design is an implementation of FR-4/FR-5/FR-6). | v0.1 (no requirement change) | Claude |
| 11 Oct 2026 | **Phase 0 hardware validation started — BRAVIA first.** Built and deployed `sanketa_app` to OnePlus LE2111 (Android 14, ARM64, release mode). Added **Simple IP Control adapter** (`simple_ip_adapter.dart`, TCP 20060) — verified key sending on Sony BRAVIA 2 II. Added **ATVRS pairing protocol** (`bravia_atvrs.dart`) — protobuf-framed TLS on port 6467 with 4-step handshake. Fixed ATVRS field-order bugs (protocol_version and status must precede inner message). Added **X.509 DER parser** (`der_utils.dart`) for RSA public key extraction from TLS certificates. Fixed two DER parser bugs: (1) missing TBSCertificate SEQUENCE entry, (2) `skipTlv` compound-assignment side-effect (`_pos += _readLength()` overwrites `_readLength()`'s internal `_pos++` — Dart evaluates left side of `+=` before calling the function). **Full ATVRS pairing succeeds**: PairingRequest/Option/Configuration/Secret all return status=200; TV stores client cert. Also: WoL magic packet builder, 5 app screens (Remote/Search/Cast/Devices/Settings), `AppShell` + bottom nav, `RemoteController` (discovery → connect → adapter routing), session manager. **IR APK analysis**: OPPO/OnePlus IR Remote (Kookong SDK) — DB encryption entirely in native `libkksdk.so` (ARM64, 912KB), extraction impractical; `KookongAllKey.json` has 6,303 function defs (readable). Recommendation: use Flipper Zero IRDB. **Decided OD-2** (India-first) and **OD-3** (Flutter + Dart, validated by real-hardware performance). | v0.1 → v0.2 (OD-2 + OD-3 decided, OD-6 research finding) | Claude |
| 11 Oct 2026 | **IRDB wired into app.** Added `sanketa_ir` dependency to `sanketa_app`. New files: `bridge_ir_transmitter.dart` (adapts native `IrBridge` → `IrTransmitter`), `ir_device_service.dart` (bundled codeset registry with search), `ir_setup_sheet.dart` (bottom sheet for IR device selection). `RemoteController` extended with `selectIrDevice()`, `hasIrHardware`, `isIrDevice`, `activeIrEntry`. Devices screen now has an "IR Remote" section with active-device card and "Add IR Remote" / "Change IR Remote" button. Fixed pre-existing test: `'SANKETA'` → `'Sanketa'` in layout geometry test. **16 app tests + 64 IR tests = 80 total, all passing. Both packages analyze clean.** | v0.2 (no requirement change — FR-2.2/FR-2.3 implementation progress) | Claude |
| 11 Oct 2026 | **IR database integration infrastructure built.** 9 new modules in `sanketa_ir/src/irdb/`: Flipper IR parser (`.ir` files, parsed + raw types), LIRC parser (`.conf` files, SPACE_ENC/PULSE_DIST/MANCHESTER), protocol decoder (NEC/Samsung/SIRC/RC5 from raw µs timings), codeset builder (unified Flipper+LIRC+capture → `IrCodeset`), searchable JSON catalog, community capture session framework, key name map (~150 external button names), brand map (~30 brands), Kookong key map (function IDs/names → Key). **3 new bundled codesets** (Samsung NEC addr 0x07, LG NEC addr 0x04, Panasonic NEC-ext addr 0x0040) joining existing Sony SIRC. Offline build tool (`tool/build_irdb.dart`): processes entire Flipper IRDB directory → `catalog.json` + `codesets/*.json`. **32 new tests across 7 groups, all passing** (64 total in sanketa_ir). Validated parser output against real Flipper IR samples fetched from GitHub (LG, Samsung, Panasonic, Philips). Kaseikyo + RC6 protocols handled via raw timing fallback. Updated barrel file (`sanketa_ir.dart`) with all new exports. No PRD requirement changes — FR-2.2 infrastructure unblocked. | v0.2 (no requirement change — implementation progress) | Claude |
| 11 Oct 2026 | **Android IR emission + FR-2.3 guided matching built.** Added a Flutter method-channel `IrBridge` and Android `ConsumerIrManager` host implementation for emitter detection, carrier-frequency discovery, validated pattern arguments, and transmission. Corrected the Android feature declaration to `android.hardware.consumerir`. Replaced immediate codeset activation with a guided flow: choose brand → point phone → Test Power → confirm the TV reacted; a codeset is saved only after confirmation, with retry/no-match handling. Async emitter detection now updates the UI. Added controller and widget coverage; **18 app tests pass, analyze is clean, and `flutter build apk --debug` succeeds.** Hardware validation remains pending on an IR-equipped Android phone. | v0.2 (no requirement change — FR-2.1/FR-2.3 implementation progress) | Codex |
| 11 Oct 2026 | **Repository-wide reliability pass.** Removed debug auto-pair/auto-connect behavior and sensitive pairing prints; made controller selection, scans, commands, and disposal race-safe; hardened session reconnect/stop and discovery total-timeout behavior; added Android TV ACK timeouts, pairing-checksum verification, bounded protobuf frames, and malformed protobuf/DER guards; made IR/LIRC imports reject bad entries safely, corrected Samsung hold repetition, and tightened raw/SIRC/RC5 validation. All six packages analyze clean; **215 tests pass** (core 27, adapters 85, discovery 5, IR 68, design 12, app 18); debug APK rebuilt successfully. PRD untouched because requirements did not change. | v0.2 (no requirement change — reliability/implementation progress) | Codex |
| 11 Oct 2026 | **Supported Flipper IRDB catalog bundled and wired.** Generated from upstream revision `d126fb1…`: **1,074 unique usable codesets** (373 TV + soundbar/AC/projector/media/STB/streaming), 1.95 MB JSON, with zero duplicate IDs or missing files. Fixed optional series-folder metadata, preserved source brand names, excluded unrelated categories instead of mislabeling them as TVs, and made IDs short/deterministic/collision-safe. `IrDeviceService` loads the 249 KB index once and codesets lazily; matching uses actual brand groups with verified fallbacks first. Added CC0 source notice and runtime tests. **217 tests pass; all analyzers clean; debug APK with the catalog builds.** | v0.2 (no requirement change — FR-2.2/FR-2.3 completed in software) | Codex |
| 4 Nov 2026 | **DLNA casting end-to-end HW-validated + PRD §12.6 error UX fixed.** Tested full DLNA cast flow on real device (OnePlus LE2111 → DLNA device at 192.168.29.222): connect → pick photo → MediaServer starts → SOAP SetAVTransportURI → UPnP error response → human-readable Cast Failed screen → Dismiss back to Ready. **Fixed PRD §12.6 violation:** raw `'http 500'` error codes were propagating to UI. Added `_humanSoapError()` with SOAP fault XML parsing (`<errorDescription>` + `<errorCode>`), human-readable mappings for "not implemented/not supported" (→ "does not support media casting"), MIME/format errors (→ "does not support this media format"), resource-not-found, and transport-locked. Also humanised volume/mute error messages. Updated `dlna_caster_test.dart` assertion. All 114 adapter tests pass. APK rebuilt and deployed 3 times during testing. Cast screen error state verified: amber border, error icon, actionable message, Dismiss button returning to Ready state. | v0.3 (no requirement change — implementation + PRD §12.6 compliance) | Claude |
| 14 Nov 2026 | **Value-add features F1–F5 built end-to-end.** F1 TV Debloat Tool: `DebloatService` + `BloatwareDatabase` (69 entries, 7 brands) + full UI with category filters, search, safe-only toggle, per-package enable/disable. F2 Free TV/IPTV: `IptvService` + M3U parser + iptv-org catalog (10K+ channels, 67 sources) + 4-tab browsing UI with favorites and cast. F3 HLS Ad-Skip: `HlsFilter` with SCTE-35/discontinuity detection and manifest rewriting. F4 TV Performance Dashboard: `TvStatsService` (ADB stats polling) + memory/CPU/storage/process UI with colour thresholds. F5 Smart App Launcher: ADB app enumeration + 3-column grid UI with search, filter, pin, launch. Integration: Devices screen gets conditional "TV Tools" section (3 cards, Android TV only); Cast screen gets "Free TV / IPTV" card → IptvScreen. All screens pass `flutter analyze` with zero issues. Debug APK built successfully. New files: `debloat_screen.dart`, `iptv_screen.dart`, `performance_screen.dart`, `app_launcher_screen.dart`, `iptv_service.dart`, `debloat_service.dart`, `tv_stats_service.dart`, `bloatware_db.json`. Security: ADB whitelisted commands only, package name regex, no untrusted URL execution, M3U XSS sanitisation. PRD bumped to v0.4 — FR-11 through FR-15 specified with full acceptance criteria; §7 pillars I/J/K added. | v0.3 → v0.4 (FR-11–FR-15 added, pillars I/J/K) | Claude |
| 12 Nov 2026 | **Comprehensive bug audit completed (BUG_FIX_PLAN.md): 19 of 24 confirmed bugs fixed.** Tier 1 Keyboard: K1 (BRAVIA submit types letter → ATVRS KEYCODE_ENTER, silent fallback removed), K3 (ATVRS IME batch edit wrong protobuf structure → fixed field counters), K4 (Android TV hardcoded IME counters → live parsing of fields 20/22), K6 (text ops race → serial chaining via `_textOpChain`). Tier 2 Connection: C1 (Tizen connect ignores auth → waits for ms.channel.connect/unauthorized/timeOut, stores token), C3 (ATV reconnect stale-sub + isOpen lies → _handshakeComplete flag, timer cleanup), C4 (webOS fallback stale close + non-TLS → generation counter, TLS-only fallback), C6 (selectDevice clears manual override → clearOverride param), C7 (webOS ws:// not wss:// → wss://3001 with ws://3000 fallback). Tier 3 UI: U1 (source toggle + app row ignore caps → gated behind capabilities), U2 (launch errors raw → routed through _humanCommandError), U3 (wake:true with no WoL → false on all 9 adapters), U6 partial (mic icon removed, keyboard_hide wired to dismiss, Live Mirrored pill gated on isConnected, cursor bar truncation fixed), U7 partial (raw $e stripped from pairing/cast/mirror errors, Raw Bitmask → human text). Tier 4 Discovery: D5 (reusePort noisy on Android → Platform.isAndroid/isWindows check skips attempt). Tier 5 Cast: M7 (MediaServer range handling → suffix ranges, end clamping, multi-range graceful). Security: S1 (unused private key removed, prior session), K7/S4 (logging audit — assert-gated, no leaks). **Remaining 5 bugs** are higher-effort: C2 (SessionManager wiring), U4 (detectedFeatures → real verification), U5 (optimistic mute/volume), U8 (accessibility), B34/B35 (permissions + tests). Plus D1-D8 discovery, M1-M6 cast/mirror, S2 (keystore vault), S3 (TOFU TLS) for later phases. All modified packages analyze clean; no regressions in pre-existing warnings. | v0.3 (no requirement change — bug fixes across all tiers) | Claude |
| 5 Nov 2026 | **All platform adapters wired into RemoteController + production socket layer.** Created `LiveWsChannel` (real WebSocket for webOS/Tizen, supports `ws://` plain and `wss://` with self-signed cert acceptance) and `LiveAtvChannel` (real TLS socket for Android TV/Fire TV, client cert, varint message framing via `MessageDeframer`). Wired all 7 control adapters into `RemoteController._createAdapter()`: BRAVIA (Simple IP + ATVRS), webOS (`LiveWsChannel` on `ws://host:3000`), Tizen (`LiveWsChannel` on `wss://host:8002/api/v2/...` with base64 "Sanketa" name), Android TV (`LiveAtvChannel` TLS 6466), Fire TV (`LiveAtvChannel` TLS 6466), Roku (HTTP 8060), Vizio (HTTPS 7345). Upgraded `_probeDlnaCaster()` to try Google Cast (port 8009 TLS handshake) before DLNA (UPnP probe) — sets `castProtocol` badge accordingly. Fixed `selectDevice()` to strip trailing hex hash from device names via `_shortDeviceName()`. Updated devices screen: `_shortName()` helper strips hashes from display names and selection comparison. Added `LiveWsChannel` and `LiveAtvChannel` to barrel exports. **286 tests pass** (38 core + 129 adapters + 72 IR + 5 discovery + 12 design + 19 app + 11 session); `dart analyze` + `flutter analyze` clean across all packages. PRD untouched (implementation wiring, no requirement changes). | v0.3 (no requirement change — controller wiring + production sockets) | Claude |
| 14 Nov 2026 | **F3 HLS Ad-Skip fully integrated into casting pipeline.** Rewrote `HlsProxyServer` (`sanketa_adapters/src/hls/hls_proxy.dart`): now LAN-bound (0.0.0.0), token-gated (random 24-char token in URL path), uses core's `HlsFilter` (superior SCTE-35/CUE-OUT/CUE-IN/DATERANGE/OATCLS handling), rewrites relative segment URLs to absolute, proxies sub-playlists through the filter. Wired into `RemoteController.castUri()`: `.m3u8` URLs auto-detected and routed through `HlsProxyServer`; LAN IP resolved via `findLanIp()`. Updated `IptvScreen._castChannel()` to send `application/x-mpegURL` mime type for HLS streams. Proxy lifecycle managed: started lazily on first HLS cast, cleaned up on disconnect/dispose. All 3 packages analyze clean (0 errors). Tests: 65 core + 138 adapters + 19 app = 222 pass. Debug APK builds successfully. |  v0.4 (no requirement change — F3 integration) | Claude |
| 14 Nov 2026 | **F1–F5 integration finalized: ToolsScreen hub + tests + lint cleanup.** ToolsScreen (`tools_screen.dart`) wires all 4 value-add sub-features into a 2×2 grid: TV Debloat, Free TV, TV Stats, App Launcher — accessible from the bottom nav "Tools" tab. `TvStatsScreen` is a typedef for `PerformanceScreen`. Added 15 debloat core tests (BloatCategory/BloatSeverity/BloatwareEntry/BloatwareDatabase round-trip + filtering) and 9 ADB model tests (TvMemoryStats/TvCpuStats/TvStorageStats/TvProcess/TvApp/AdbPackage). Fixed lint: sanketa_core barrel alphabetized (0 issues), sanketa_adapters barrel alphabetized + removed unused `remote` local variable in `live_stream_server.dart` + removed unnecessary cast in `cert_generator.dart` (1 pre-existing warning remaining: `_repeatKey` unused). All 80 sanketa_core tests pass. sanketa_app analyzes clean (0 issues). **322+ total tests pass across the monorepo.** | v0.3 (no requirement change — integration + tests + lint) | Claude |
| 11 Oct 2026 | **Kookong cipher cracked and 9,476 codesets integrated.** Reverse-engineered Kookong's position-dependent XOR cipher (magic constant `0x133a133`, block cycle `[1–7]`, init passphrase `"Kf9j8Si15EKM9h4uSt16"`). Decrypted 6,809 brands across 14 languages (99.94% success). Built `build_kookong.py` converter: parses 33-byte `param_hex` timing, reads 347,367 IR codes from extracted CSVs, outputs compact `"kk"` format JSON (23.5 MB vs 281 MB pre-expanded). `_expandKookong()` in `irdb_catalog.dart` reconstitutes full µs timings at load. Added 5 AC key mappings (`acMode`, `acSwing`, `acTemperatureUp/Down`, `acFanSpeed`) — fixes 2,349 previously dropped key instances. Created comprehensive **brand database** (`brand_database.json` + `.csv`): 2,907 brands with brandFamily, sources, codeset counts, and per-device-type breakdowns. **Total IR coverage: 10,550 codesets across 2,907 brands** (1,074 Flipper + 9,476 Kookong). Key mapping coverage: 99.0% (224,942 of 227,291). PRD bumped to v0.3 — OD-6 fully resolved, Appendix B rewritten, R-5 downgraded. | v0.2 → v0.3 (OD-6 resolved, R-5 mitigated, Appendix B rewritten) | Claude |
| 14 Nov 2026 | **F2 in-app video player added and verified on device.** New `PlayerScreen` (`player_screen.dart`) using `video_player` + `chewie` (ExoPlayer on Android): autoplay, landscape rotation, Chewie progress bar with OmniBeam tokens, human-readable error messages (stream offline/codec/timeout), retry button. Watch button in `IptvScreen` now navigates to the in-app player instead of `url_launcher`. Long-press bottom sheet on channel tiles offers 3 options: Watch in app, Open in external player, Cast to TV. `_actionPill` helper for compact pill buttons. Added `video_player: ^2.9.2` and `chewie: ^1.8.5` to pubspec. Verified live HLS stream (3ABN Kids) playing on OnePlus LE2111. Kotlin incremental cache corruption encountered during build (stale daemon); resolved by temporary `kotlin.incremental=false` in gradle.properties (removed after successful build). PRD untouched (implementation of FR-11/FR-12). | v0.4 (no requirement change — F2 in-app player) | Claude |
| 14 Nov 2026 | **ATVRS keyboard "Enter types a" bug fixed.** Root-caused two issues in the ATVRS Configure handshake and submit path. (1) Malformed DeviceInfo: field 5 sent as string (`'atvremote'`, wire-type tag 42) instead of int (tag 40), preventing the TV from recognising the remote as a proper IME provider — the TV's on-screen keyboard stayed visible and KEYCODE_ENTER selected its focused key ('a'). Fixed in both `live_atv_channel.dart` and `bravia_atvrs.dart`: correct field order (model, vendor, unknown1, app_version, unknown2, package_name), field 5 as uint, package `com.sanketa.sanketa_app`. (2) Text buffer (`_imeText` / `_textBuffer`) never cleared on submit — stale text reappeared on next entry. Fixed: `android_tv_adapter.dart` now commits text via IME batch edit before KEYCODE_ENTER and clears the buffer; added KEYCODE_DEL fallback for delete-from-empty-buffer; `simple_ip_adapter.dart` uses new `BraviaAtvrs.submitText()`. Fixed 2 pre-existing test mismatches (capabilities `wake` flag, delete-from-empty-buffer expectation). **All 35 adapter + 7 DLNA tests pass; analyzer clean.** Pending on-device verification on MiTV. | v0.4 (no requirement change — ATVRS keyboard bug fix) | Claude |
| 21 Nov 2026 | **ATVRS IME commit fix — keyboard submit HW-validated on Haier + Samsung.** The previous "Enter types a" fix (DeviceInfo) restored typing but submit still had no effect. Root cause: `editInfo.committed` (field 1) was written as `writeUint(1, 1)` (varint, wire type 0) but the ATVRS proto defines it as a string (wire type 2). The TV silently skipped the malformed field, so the IME composition was never finalized and KEYCODE_ENTER was consumed or ignored. Fix: composing sends `writeString(1, '')` (empty committed); new `buildImeCommit()` / `_sendImeCommit()` sends `writeString(1, text)` with cleared `textFieldStatus.value` to finalize the composition before KEYCODE_ENTER. Changes in `atv_messages.dart`, `android_tv_adapter.dart`, `bravia_atvrs.dart`, `simple_ip_adapter.dart`. **Full type-and-search flow confirmed working on Haier TV and Samsung TV.** All adapter tests pass; analyzer clean. | v0.4 (no requirement change — ATVRS IME commit bug fix, HW-validated) | Claude |
| 21 Nov 2026 | **Keyboard hide button blank-screen bug fixed and HW-validated.** The keyboard hide icon (down-arrow, `Icons.keyboard_hide`) in `TvKeyboardSheet` called `Navigator.of(context).pop()`, but the keyboard is embedded directly in `RemoteScreen` (not a modal). This popped the app's root route (`AppShell`), leaving a black screen — `PopScope(canPop: false)` only blocks system back gestures, not explicit `Navigator.pop()`. Fix: replaced `Navigator.pop()` with a local `_expanded` state toggle that collapses/expands the keyboard section. When collapsed, only the header ("TV Search & Text Sync") with a keyboard icon remains; tapping it re-expands. Icon swaps between `keyboard_hide` (expanded) and `keyboard` (collapsed). **Reproduced blank screen via ADB, deployed fix, verified collapse/expand cycle on OnePlus LE2111.** | v0.4 (no requirement change — UI bug fix, HW-validated) | Claude |
| 21 Nov 2026 | **v0.1.0 released on GitHub.** Pushed full monorepo (10,740 files) to `https://github.com/ankitjha67/Sanketa` (private). Created release `v0.1.0` — "Phase 0 Complete: Universal TV Remote Platform" with full release notes covering 10 adapters, 5 value-add features, 3 HW-validated TVs, 311+ tests, 19/24 bugs fixed. README.md rewritten with comprehensive feature table, HW validation matrix, repo layout, coverage ladder, and design red lines. | v0.4 (no requirement change — release milestone) | Claude |
| 25 Nov 2026 | **Phase 2 WiFi→IR bridge adapters built + feature roadmap added.** BroadLink RM adapter: full LAN protocol (AES-128-CBC crypto, UDP discovery, auth command 0x0065, IR send via sub-command 0x02, IR learn via sub-commands 0x03/0x04 with polling), supports RM Mini 3/Pro/RM4 Mini/RM4 Pro. `BroadLinkTransmitter` implements `IrTransmitter` for bridge-based IR send + learn. BroadLink discovery backend (self-contained, no circular dep). `EndpointClassifier` routes `broadlink` attribute. `RemoteController` wired with adapter factory case. SwitchBot Hub adapter: cloud-only REST (`api.switch-bot.com`, HMAC-SHA256 auth, 10K calls/day), opt-in with privacy disclosure. README updated (12 adapters, coverage ladder rungs 2+1 → Built). **Feature roadmap** (§12): 20 prioritised features for Phase 2–3 added to CONTEXT.md. | v0.4 (no requirement change — Phase 2 bridge adapters + roadmap) | Claude |
| 14 Nov 2026 | **On-device UI verification of F1–F5 complete.** Deployed release APK to OnePlus LE2111, navigated through all 4 Tools sub-features via ADB tap automation. **F1 TV Debloat:** "Not connected" badge renders (connection-aware gray), 23 bloatware entries with HIGH/MED severity badges, category filter chips (All/Ads/Telemetry/Bloatware/Google/OEM), search bar — all render correctly. **F2 Free TV:** 4-tab layout (Categories/Countries/Languages/Favorites) renders, 27 category source cards load in grid, channel loading spinner and error state with Retry button work correctly; fixed `cat_animation` URL (was `index.category.m3u`, now `categories/animation.m3u`); network errors show human-readable message per PRD §12.6 (VPN/DNS on test phone blocks external fetch — expected). **F4 TV Stats:** "ADB Connection Required" state with gauge icon, explanation text, and cyan Retry button — correct empty state. **F5 App Launcher:** "TV Apps" header with grid icon + refresh button, "No TV connected" empty state — correct. Grid coordinate mapping documented: `childAspectRatio: 1.05` makes cards ~462×440 device pixels; top row y≈260–700, bottom row y≈750–1180. PRD untouched (UI verification, no requirement change). | v0.4 (no requirement change — on-device UI verification) | Claude |
| 25 Nov 2026 | **Phase 2+3 features continued: 15 of 20 roadmap items complete.** Built 4 more features: (4) Parental Controls — `ParentalControlsScreen` with PIN setup, lock/unlock, per-key blocking, daily time limits. (9) Voice-to-TV — `VoiceService` (speech_to_text plugin) + `VoiceScreen` with mic button, transcript, send-to-TV. (11) Usage Analytics — `UsageService` (session tracking, JSON persistence) + `UsageAnalyticsScreen` with today/weekly/hourly charts, session list. (12) Network Diagnostics — `NetworkDiagnosticsScreen` with 5-step diagnostic runner (local network, TV reachable, port scan, DNS, internet). Tools screen updated to 13 cards. `dart analyze` clean (0 issues). | v0.4 (no requirement change — Phase 2+3 feature implementation) | Claude |
| 25 Nov 2026 | **Phase 2 features built: 11 of 20 roadmap items complete.** Built 9 new features + 2 new adapters in one pass. **Features:** (1) Touchpad/Trackpad Mode — `TouchpadSurface` widget with swipe→D-pad, tap→OK, double-tap→Back, long-press→Menu, crosshair painter; D-pad/Touchpad toggle in RemoteScreen. (2) Macro/Scene Automation — `MacroService` (record/play/stop, JSON persistence), `MacroScreen` with step builder (14 actions), wired into RemoteController key recording. (3) Sleep Timer — `SleepTimerService` countdown with `onExpired`→power off, bottom sheet with 6 presets, active timer badge in header. (6) Custom Remote Layouts — `CustomLayoutService` + `CustomLayoutScreen` drag-and-drop grid editor. (7) Connection Doctor — `ConnectionDoctorScreen` guided troubleshooting. (10) Quick Actions — `QuickActionsSheet` searchable command palette (power, mute, volume, home, back, sleep timer, HDMI, app shortcuts). (16) Search Shortcuts — `SearchShortcutsScreen`/`SearchShortcutsWidget` save+replay search queries. **Adapters:** (17) Panasonic Viera (SOAP port 55000, NRC key format, PIN pairing). (18) Philips JointSpace (REST v6, port 1925/1926, Digest auth pairing). **Tools screen:** 8-card grid (Debloat, TV Stats, App Launcher, Doctor, Macros, Touchpad, Shortcuts, Layouts). **Compile status:** `dart analyze` clean across all 6 packages (0 errors, 0 warnings). Fixed: duplicate MacroService API, duplicate imports, void-await issues, missing TouchpadScreen. **Adapter count: 14 platform adapters.** | v0.4 (no requirement change — Phase 2 feature implementation) | Claude |

---

## 14. Toolchain — DECIDED (10 Aug 2026)

**Chosen: install the SDK (Option A).** Product owner selected it.

**What was done:** installed the **Dart SDK 3.12.2** (stable, 2026-06-09) to `C:\Users\ankit\dart-sdk`, added `…\dart-sdk\bin` to the user PATH. Chose the Dart SDK (~204 MB) over the full Flutter bundle (~1 GB) because everything built so far — `sanketa_core` and `sanketa_adapters` — is **pure Dart with no Flutter dependency**, so Dart alone gets us to a compiled-and-tested state. The full Flutter SDK is deferred until UI work begins (Phase 1, gated on Phase 0).

**Verification:** `dart pub get` + `dart analyze` clean on both packages; `dart test` → 15/15 green on the Roku adapter.

**Follow-up (not blocking now):** install the full Flutter SDK before Phase 1 UI work. New shells pick up `dart` from the user PATH automatically.

**Original options considered:** A install SDK *(chosen)* · B Python Phase-0 spike first · C keep writing Dart unverified.

---

## 14. Universal coverage ladder — build status

The promise is "any brand, any region, old and new." It is delivered by a **fallback ladder** (PRD §1), not by one magic protocol. Each rung widens coverage; a device is served by the highest rung it reaches. This is the scoreboard for the universality goal.

| Rung | Delivers | Covers | Status |
|---|---|---|---|
| 0. Discovery (multi-method) | Finds any device that advertises | Every networked brand | 🟢 Built (SSDP + mDNS + probe), unit-tested; HW-validate in Phase 0 |
| 1. Native network adapters | Richest control + **the keyboard** | Smart platforms (GTV, Tizen, webOS, Roku, BRAVIA…) | 🟢 **5 of 5 built; BRAVIA HW-validated** — Simple IP keys + ATVRS pairing confirmed on real BRAVIA 2 II. Roku, Tizen, webOS: unit-tested, awaiting hardware |
| 2. Generic network protocols | Basic control + casting without a native adapter | Cast / DIAL / DLNA devices, long-tail brands | 🟢 **Google Cast (CastV2 TLS, port 8009) + DLNA renderer control + DIAL app-launch built & tested.** Controller auto-probes Cast→DLNA for casting. Cast screen shows dynamic protocol badge. `LiveWsChannel` and `LiveAtvChannel` provide production socket implementations |
| 3. Phone IR | Power/volume/nav on **anything with an IR receiver, offline** | **Any TV/STB/AC ever made — old, non-smart, any brand** | 🟢 Encoders + **10,550 codesets (dual-source: Flipper + Kookong) across 2,907 brands and 4 verified fallbacks** + source-brand lazy catalog + IR adapter + Coolix AC + D-pad assist + Android `ConsumerIrManager` bridge + guided Power-test wizard, all built/tested; debug APK installed on device with the full database. **Remaining: validate emission/matching on IR-equipped hardware** |
| 4. WiFi-to-IR bridge | IR for phones without a blaster | iPhone + IR-less Android → non-smart TVs | 🟢 **Built** (25 Nov 2026) — BroadLink RM (local UDP, AES-128-CBC) + SwitchBot Hub (cloud API, opt-in). `BroadLinkTransmitter` implements `IrTransmitter` for bridge IR send + learn. HW-unvalidated |

**Regions** ride on top of this: IR codeset packs and adapter/brand priority are geo-weighted (OD-2 India-first, decided). The ladder is region-agnostic. **Four of five rungs built; Rung 1 partially hardware-validated** (BRAVIA); **Rung 2 now includes Google Cast** + DLNA + DIAL, with auto-probe cascade in the controller; **Rung 3 software path complete** from the full database through lazy matching and Android native emission (device validation pending). **All adapters now wired in RemoteController** with production socket implementations. What remains: ATVRS text injection verification, remaining MVP platforms on real hardware, and hardware-validate IR emission/matching.

---

## 15. IR database research — Kookong reverse engineering (11 Oct 2026)

**Goal:** reverse-engineer the OPPO/OnePlus IR Remote APK (`ir-remote-17-0-30.apk`) to extract IR codes for all models and appliances.

**Architecture found:**
- **Kookong SDK** — Chinese IR code library used by OPPO, OnePlus, Xiaomi, Realme
- `kkoffline16.db` — SQLite database: 10,990 type-1 remote controllers, 347,367 IR code entries
- `KookongAllKey.json` — 6,303 function definitions with multilingual labels (readable, not encrypted)
- Device type IDs: 1=TV, 2=STB, 3=DVD, 4=Projector, 5=AC, 6=Fan, 7=Audio, 8=IPTV, 10=Camera, 11=Lighting, 12=Heater, 13=Robot Vacuum
- IR transmission: `ConsumerIrManager.transmit(frequency, int[] pattern)` — alternating mark/space microsecond timing

**~~Encryption analysis~~ CIPHER CRACKED (11 Oct 2026):**
- ~~ALL encryption/decryption is inside native `libkksdk.so` (ARM64, 912 KB)~~ — ~~Conclusion: direct extraction impractical~~
- **SUPERSEDED:** The SQLite database was exported directly. IR code fields (`param_hex`, `pulse_data_hex`) are **not AES-encrypted** — they use a binary timing format. Brand names use a custom position-dependent block cipher.

**Kookong timing format (reverse-engineered):**
- `param_hex`: 33-byte format (most common, 6,967 remotes). Timing values in **carrier cycles** as big-endian 16-bit integers. Byte offsets: 8-9 = bit_mark, 10-11 = bit0_space, 14-15 = bit1_space, 19-20 = header_mark, 21-22 = header_space, 31-32 = trail_mark. Conversion: µs = cycles × 1,000,000 / frequency.
- `pulse_data_hex`: Compact data bytes expanded MSB-first per byte using param_hex timing to generate full mark/space pattern.
- Compact "kk" storage format: `{"p":"kk","f":freq,"t":[hm,hs,bm,b0s,b1s,tm],"d":"hexdata"}` — ~6x smaller than pre-expanded raw arrays (23.5 MB vs 281 MB).

**Kookong brand name cipher (cracked):**
- Position-dependent XOR with variable-length block processing
- Magic constant: `0x133a133` (20,201,779)
- Init passphrase: `Kf9j8Si15EKM9h4uSt16`
- Block size cycle: [1, 2, 3, 4, 5, 6, 7]
- Per-block mask: `w17 = magic / (pos+1)`, `w3 = magic >> (9-blksz)`, `w5 = (magic << blksz) as i32`, `result = (accum - pos - w17) XOR (w3 + w5)`
- Base64 variant: `/` → `_`, `+` → `.`, `=` → `-`
- Result: **6,809 brand names decrypted** (99.94% success rate) across 14 languages (English, Chinese simplified/traditional, Korean, Japanese, Portuguese, Russian, Thai, Arabic, Indonesian, Vietnamese, Hindi, Malay, Turkish)

**Integration result (11 Oct 2026):**
- **9,476 Kookong codesets** extracted: 3,933 TV, 3,111 STB, 1,505 projector, 762 soundbar, 165 AC
- **2,677 Kookong brands** (99.96% with real decrypted names, 1 placeholder `KK-unknown`)
- Combined with Flipper IRDB: **10,550 total codesets, 2,907 unique brands**
- BrandFamily: Samsung (280) → tizen, Sony (185) → bravia, LG (166) → webOs, Panasonic (189) → panasonic, all others → genericIr
- Brand database (`brand_database.json`, `brand_database.csv`) provides 1-1 brand → details mapping
- Python converter (`build_kookong.py`) generates compact JSON from Kookong CSVs
- Dart `_expandKookong()` decompresses at runtime in `irdb_catalog.dart`
- Key name coverage: 99.0% (224,942 of 227,291 key instances mapped; 5 AC keys added)
- Debug APK (207.8 MB) built and installed on OnePlus LE2111

**Remaining:** physical emission/matching validation on IR-equipped hardware, evidence-based India-market candidate ordering, and community gap-fill for missing brands.

---

## 16. ATVRS protocol — validated implementation details (11 Oct 2026)

**Protocol:** Android TV Remote Service v2, used by Google TV Remote app and Sony BRAVIA Google TV sets.

**Transport:** TLS 1.2 with self-signed client certificates. Port 6467 (pairing), port 6466 (remote control). Protobuf messages with varint-length framing (4-byte big-endian length prefix on the wire).

**Pairing handshake (all validated on real BRAVIA 2 II):**
1. **PairingRequest** (field 10): service_name="atvremote", client_name="Sanketa" → ack status=200
2. **PairingOption** (field 20): encoding=HEXADECIMAL, symbol_length=6, preferred_role=INPUT → ack status=200
3. **PairingConfiguration** (field 30): encoding + client_role=INPUT → ack status=200
4. **PIN entry**: TV displays 6 hex digits; user enters on phone
5. **PairingSecret** (field 40): SHA-256(clientMod ‖ clientExp ‖ serverMod ‖ serverExp ‖ nonce), nonce=codeBytes[1:] → ack status=200 (TV returns its own hash)

**Outer message envelope:** Every message wraps in an OuterMessage with field 1 = protocol_version (2) and field 2 = status (200). **Critical: these fields must precede the inner message field** — the TV's protobuf parser expects this order.

**Key files:**
- `sanketa_adapters/lib/src/bravia/bravia_atvrs.dart` — protocol implementation
- `sanketa_adapters/lib/src/android_tv/der_utils.dart` — X.509 DER parser
- `sanketa_adapters/lib/src/android_tv/atv_pairing.dart` — SHA-256 hash computation
- `sanketa_adapters/lib/src/android_tv/atv_framing.dart` — varint message framing
- `sanketa_adapters/lib/src/android_tv/protobuf_codec.dart` — protobuf read/write

**Bugs fixed during validation:**
1. Protobuf field ordering — protocol_version + status must come before the inner message field
2. DER parser: missing `cert.enterSequence()` — code entered outer Certificate SEQUENCE but not inner TBSCertificate SEQUENCE
3. DER parser: `skipTlv()` compound-assignment side-effect — `_pos += _readLength()` in Dart evaluates `_pos` before calling `_readLength()`, so `_readLength()`'s internal `_pos++` is overwritten. Fix: `final len = _readLength(); _pos += len;`

---

---

## 17. IRDB integration — module inventory (11 Oct 2026, updated for Kookong)

**9 source files** in `sanketa_ir/lib/src/irdb/`, **3 verified fallback codesets**, **1 deterministic Flipper build tool**, **1 Python Kookong converter**, **10,550 generated codesets** (1,074 Flipper + 9,476 Kookong), **1 brand database** (JSON + CSV), **72 IR tests**.

### Parsers
| Module | File | Parses | Output |
|---|---|---|---|
| Flipper IR parser | `flipper_ir_parser.dart` | Flipper `.ir` files (type: parsed + type: raw) | `List<ParsedSignal>` |
| LIRC parser | `lirc_parser.dart` | LIRC `.conf` / `.lircd.conf` files (SPACE_ENC, PULSE_DIST, RC5/MANCHESTER) | `List<LircRemote>` → `List<ParsedSignal>` |
| Protocol decoder | `protocol_decoder.dart` | Raw IR timing patterns (µs mark/space) | Protocol + address + command (NEC, Samsung, SIRC, RC5; fallback to raw) |

### Normalisation layer
| Module | File | Purpose |
|---|---|---|
| Key name map | `key_name_map.dart` | Maps ~200 external button names (Flipper/LIRC/Kookong/community) → canonical `Key` enum. Case-insensitive, normalises spaces/hyphens/underscores. 99.0% Kookong key coverage (5 AC keys: mode, swing, temperature_up/down, wind_speed) |
| Brand map | `brand_map.dart` | Maps brand strings → `BrandFamily` enum + Flipper category dirs → `DeviceType` enum. ~30 brand aliases |
| Kookong key map | `kookong_key_map.dart` | Maps Kookong SDK function IDs/names → `Key` enum (~40 ID + ~40 name mappings). Reference for multilingual key labels |

### Builders and catalog
| Module | File | Purpose |
|---|---|---|
| Codeset builder | `codeset_builder.dart` | Unified `ParsedSignal` → `IrCodeset` converter. Entry points: `fromFlipperFile()`, `fromLircFile()`, `fromCapture()`, `build()` |
| IRDB catalog | `irdb_catalog.dart` | Searchable catalog with JSON serialization. `CatalogEntry` (metadata), `SerializedCodeset` (full data), compact single-char JSON keys. `byDeviceType()`, `byBrand()`, `search()`. **`_expandKookong()` decompresses compact "kk" format at runtime** |
| Capture session | `capture_session.dart` | Community capture framework: guided key-by-key capture with progress tracking, protocol auto-detection, codeset generation. Default key sets per device type |

### Bundled codesets (hand-verified, compile-time constants)
| File | Brand | Protocol | Address | Keys |
|---|---|---|---|---|
| `codesets/sony_tv.dart` | Sony | SIRC 12 | 0x01 | 18 |
| `codesets/samsung_tv.dart` | Samsung | NEC | 0x07 | 32 |
| `codesets/lg_tv.dart` | LG | NEC | 0x04 | 36 |
| `codesets/panasonic_tv.dart` | Panasonic | NEC-ext | 0x0040 | 29 |

### Build tool
| File | Purpose |
|---|---|
| `tool/build_irdb.dart` | Offline: reads entire Flipper IRDB directory → writes `catalog.json` index + individual `codesets/<id>.json` files. Usage: `dart run tool/build_irdb.dart <irdb-dir> <output-dir>` |

### Protocol support matrix (parser → codeset)
| Protocol | Flipper name | Parsed? | Notes |
|---|---|---|---|
| NEC | NEC | ✅ | Most Samsung, LG, many generic TVs |
| NEC-extended | NECext / NEC42 | ✅ | Panasonic, some newer models |
| Samsung32 | Samsung32 | ✅ | Samsung TVs |
| Sony SIRC 12/15/20 | SIRC / SIRC15 / SIRC20 | ✅ | Sony TVs |
| RC5 / RC5X | RC5 / RC5X | ✅ | Philips, some European brands |
| Kaseikyo | KASEIKYO | Raw fallback | Panasonic full-frame; decoded to raw timing |
| RC6 | RC6 | Raw fallback | Philips newer; decoded to raw timing |
| Raw | raw | ✅ | Direct µs timing passthrough |

### Test coverage
39 tests across 10 groups in `sanketa_ir/test/irdb_test.dart`: FlipperIrParser (7), KeyNameMap (5), BrandMap (4), CodesetBuilder (5), IrdbCatalog (3), LircParser (3), ProtocolDecoder (3), CaptureSession (3), KookongKeyMap (3), **Kookong compact format (3)** — `kk` protocol expansion, bit0/bit1 space verification, codeset round-trip through `toCodeset()`. All passing.

**Repository-wide: 286 tests** — 38 core + 72 IR + 129 adapters + 5 discovery + 12 design + 19 app + 11 session.

### Remaining work
1. Hardware-validate `ConsumerIrManager` detection, carrier handling, emission latency, and matching success on an IR-equipped Android phone.
2. Replace the current fallback-first/key-count ranking heuristic with India-market popularity evidence and add community gap-fill for missing remotes.
3. Add Kaseikyo and RC6 as first-class decoded protocols (currently raw-fallback, which works but is less compact).

---

## 18. Kookong integration — converter and data pipeline (11 Oct 2026)

### Data sources
| File | Location | Content |
|---|---|---|
| `remote_controllers.csv` | Extracted from `kkoffline16.db` | 10,990 type-1 remotes: remote_id, frequency, param_hex |
| `ir_codes.csv` | Extracted from `kkoffline16.db` | 347,367 rows: remote_id, function_name, pulse_data_hex |
| `brand_remote_map.csv` | Extracted from `kkoffline16.db` | brand_id (encrypted), device_type_id per remote |
| `functions.csv` | Extracted from `kkoffline16.db` | function_id → function_name mapping |
| `kookong_cipher_keys_and_brands 1.json` | User-provided (1.1 MB) | Complete cipher specification + 6,809 decrypted brand names across 14 languages |

### Converter pipeline (`build_kookong.py`)
1. Load type-1 remote controllers from `remote_controllers.csv`
2. Load brand-remote mapping from `brand_remote_map.csv`
3. Load decrypted brand names from `kk_brand_map.json` (extracted from cipher JSON)
4. Parse param_hex timing for each remote (33-byte format → [hm, hs, bm, b0s, b1s, tm] in µs)
5. Read IR codes, filter to mappable keys (MAPPABLE_KEYS set, ~60 key names)
6. Filter to remotes with ≥2 mappable keys
7. Assign BrandFamily (Samsung→tizen, Sony→bravia, LG→webOs, Panasonic→panasonic, others→genericIr)
8. Write compact "kk" format JSON per codeset + catalog.json index
9. Output: `sanketa_app/assets/kookong/catalog.json` (1.3 MB) + `codesets/` (9,476 files, 23.5 MB total)

### Brand database (`brand_database.json` + `.csv`)
Comprehensive 1-1 brand-to-details mapping for all 2,907 brands across both sources:
- `brandName`: canonical brand name (e.g., "Samsung", "Haier", "Skyworth")
- `brandFamily`: adapter family (tizen, bravia, webOs, panasonic, genericIr)
- `sources`: which databases contain this brand (flipperIrdb, kookong, or both)
- `totalCodesets`: number of IR remotes for this brand
- `totalKeys`: total mappable key instances across all codesets
- `deviceTypes`: breakdown by device type (TV, STB, soundbar, projector, AC, media renderer, streaming)

### Key statistics
| Metric | Value |
|---|---|
| Total codesets | 10,550 (1,074 Flipper + 9,476 Kookong) |
| Unique brands | 2,907 |
| Brands in both sources | 150 |
| Kookong-only brands | 2,527 |
| Flipper-only brands | 230 |
| TV codesets | 4,306 |
| STB codesets | 3,171 |
| Projector codesets | 1,628 |
| Soundbar codesets | 1,013 |
| AC codesets | 313 |
| Key mapping coverage | 99.0% (224,942 of 227,291) |
| Unmapped keys (AC-specific) | 5 (mode, swing, temperature_up/down, wind_speed — now mapped) |
| Debug APK size | 207.8 MB |
| Asset size (Kookong) | 23.5 MB (compact) vs 281 MB (pre-expanded) |

---

*Phase 0 is live. The app runs on real hardware (OnePlus LE2111, Android 14) and the first MVP platform (Sony BRAVIA 2 II) has its control path validated: Simple IP keys work, ATVRS pairing succeeds. Text injection — the hero feature — is one `connect()` call away from proof on real hardware. **All 7 control adapters are now wired into the RemoteController** with production socket implementations (`LiveWsChannel` for webOS/Tizen, `LiveAtvChannel` for Android TV/Fire TV) — previously, only BRAVIA was end-to-end connected; now every platform is routed through the adapter factory and ready for real-hardware testing. The cast auto-probe cascade tries Google Cast (TLS 8009) before DLNA (UPnP). The IR software path runs from **10,550 codesets across 2,907 brands** (dual-source: Flipper IRDB + Kookong with cracked cipher) through source-brand lazy matching to Android `ConsumerIrManager`; **286 tests pass** and the debug APK is green. Remaining: validate IR on equipped hardware and validate remaining MVP platforms (Samsung Tizen, LG webOS, Roku, Vizio, Fire TV). The critical path: verify ATVRS text injection → hardware-validate IR → validate remaining platforms → ship.*
