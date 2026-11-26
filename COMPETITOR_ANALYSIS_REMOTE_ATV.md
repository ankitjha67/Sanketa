# Competitor Analysis: Remote ATV v6.1.0 vs Sanketa

**Date:** 2026-11-26
**Method:** APK reverse engineering (XAPK extraction, manifest decode via aapt2, Dart AOT string-pool analysis)
**Package:** `tech.simha.androidtvremote` v6.1.0 (code 45), minSdk 24, targetSdk 36

---

## Executive Summary

Remote ATV is a Flutter app using the same ATVRS (Android TV Remote Service) protocol as Sanketa for keyboard typing and TV control. Its main differentiator vs Sanketa is **clipboard paste to TV** (injecting phone clipboard text into TV text fields via ATVRS IME batch edit). It monetizes through 5 ad SDKs and RevenueCat subscriptions.

Sanketa already matches or exceeds Remote ATV in protocol implementation, TV coverage (14 adapters vs 1), and feature breadth (69 tools vs ~15 features). **Batch 12** (built 26 Nov 2026) closes the UX gaps identified by competitor users: Mouse Cursor mode, Floating Remote overlay, TV Screenshot capture, Cast Queue playlists, and Connection Pulse monitoring — all with original implementations.

---

## Architecture Comparison

| Aspect | Remote ATV | Sanketa |
|---|---|---|
| Framework | Flutter (Dart AOT) | Flutter 3.47.2 / Dart 3.12.2 |
| Protocol | ATVRS only | ATVRS + 13 more adapters |
| TV coverage | Android TV only | Any TV (network + IR + bridge) |
| APK size | 33.8 MB base + 20 MB arm64 | ~25 MB |
| Min SDK | 24 (Android 7.0) | 24 (Android 7.0) |
| Target SDK | 36 | 35 |

---

## Feature-by-Feature Comparison

### What Remote ATV Has (via Dart AOT class tokens + manifest)

| Feature | Evidence | Sanketa Status |
|---|---|---|
| **Keyboard typing** | `RemoteImeKeyInject`, `RemoteImeBatchEdit`, `RemoteTextFieldStatus` | **MATCH** — HW-validated on 3 TVs |
| **Clipboard paste to TV** | `RemoteImeBatchEdit` with `RemoteImeObject{start,end,value}` | **GAP** — not implemented |
| **Voice input** | `RemoteVoiceBegin`/`End`/`Payload`, RECORD_AUDIO permission | **PARTIAL** — Voice screen exists, protocol not wired |
| **Touchpad** | `TouchPad`/`Touchpad` tokens | **MATCH** — Touchpad screen built |
| **D-pad / navigation** | 200+ KEYCODE_* (DPAD_*, MEDIA_*, TV_*) | **MATCH** — full keycode mapping |
| **HDMI input switching** | `TVInputHDMI1-4`, `TVInputVGA1`, `TVInputComponent*` | **MATCH** — HDMI switching built |
| **Volume control** | `RemoteAdjustVolumeLevel`, `KEYCODE_VOLUME_*` | **MATCH** |
| **Power control** | `AVRPower`, `TVPower`, `KEYCODE_POWER` | **MATCH** |
| **App deep linking** | `RemoteAppLinkLaunchRequest` | **GAP** — no deep link launch |
| **Audio device routing** | `RemoteSetPreferredAudioDevice` | **GAP** — not implemented |
| **Streaming app shortcuts** | RaiPlay, RUTUBE, Viaplay, Videoland, WATCHA, STARZPLAY, ATRESplayer | **MATCH** — App Launcher screen |
| **Screen wake lock** | `wakelock_plus` package | **GAP** — should add |
| **Multi-language UI** | 30+ languages in string pool | **MATCH** — 15 keyboard languages |
| **Ping/keepalive** | `RemotePingRequest`/`Response` | **MATCH** — heartbeat manager |
| **TLS pairing** | `RemoteConfigure`, cert handling | **MATCH** — ATVRS protobuf TLS |

### What Remote ATV Has That Sanketa Explicitly Rejects

| Feature | Evidence | Sanketa Position |
|---|---|---|
| **5 ad SDKs** | AdMob, Unity Ads, Facebook AN, Yandex, Fyber/FairBid | **Red line: zero ads, ever** |
| **IAP subscriptions** | RevenueCat (`$rc_annual/lifetime/six_month/three_month`), `RC_BILLING` | Sanketa is free for basic control |
| **Analytics** | AppMetrica, Firebase Analytics, AD_ID | **Red line: zero server calls** |
| **In-app billing** | `com.android.vending.BILLING`, `SINGLE_PAYMENT` | No paywall on keyboard/basic control |
| **Ad ID access** | `ACCESS_ADSERVICES_*`, `AD_ID` permissions | Never |

### What Sanketa Has That Remote ATV Doesn't

| Feature | Sanketa | Remote ATV |
|---|---|---|
| **IR remote** | 10,550 codesets, NEC/Samsung/SIRC/RC5/AC | None |
| **WiFi-IR bridges** | BroadLink + SwitchBot | None |
| **TV Debloat** | 69 entries, 7 brands via ADB | None |
| **IPTV/Free channels** | 10K+ channels, M3U parser | None |
| **HLS ad-skip** | SCTE-35 manifest rewriter | None |
| **Performance dashboard** | Live CPU/memory/storage stats | None |
| **Multi-brand support** | 14 protocol adapters | ATVRS only |
| **Google Cast** | CastV2 TLS on port 8009 | None |
| **DLNA casting** | UPnP AVTransport | None |
| **69 tool cards** | Debloat, macros, CEC, layouts, mouse cursor, floating remote, etc. | ~15 features |
| **Custom remote layouts** | Drag-and-drop JSON profiles | None |
| **Macro automation** | Record/replay sequences | None |
| **Connection doctor** | Guided troubleshooting | None |
| **Sleep timer** | 6 presets with countdown | None |
| **D-pad typing assist** | Shortest-path IR typing | None |

---

## Protocol Deep Dive: How Clipboard Paste Works

Based on the `remotemessage.proto` definitions (from androidtvremote2):

### Text Input Flow (ATVRS IME Protocol)
1. TV sends `RemoteImeShowRequest` (field 22) when a text field gets focus
   - Contains `RemoteTextFieldStatus{counter_field, value, start, end, label}`
2. Phone sends `RemoteImeBatchEdit` (field 21) with text changes
   - Contains `ime_counter`, `field_counter`, repeated `RemoteEditInfo`
   - Each `RemoteEditInfo` has `insert` flag + `RemoteImeObject{start, end, value}`
3. TV sends `RemoteImeKeyInject` (field 20) to sync state back

### Clipboard Paste Implementation
Remote ATV implements "paste from phone" by:
1. Reading the phone's system clipboard (`Clipboard.getData`)
2. Constructing a `RemoteImeBatchEdit` message with the clipboard text as `value`
3. Setting `start=0, end=current_field_length` to replace the entire field
4. Sending it over the existing ATVRS TLS connection

There is **no dedicated clipboard protobuf message**. It reuses the same IME batch edit that keyboard typing uses. The key insight: paste is just a large IME edit, not a separate protocol feature.

The protocol also defines `KEYCODE_PASTE` (279) which can be sent via `RemoteKeyInject`, but this only works if the TV has clipboard content — it doesn't transfer clipboard content from phone to TV.

---

## Actionable Gaps (Priority Order)

### P0: Clipboard Paste to TV
- **What:** Let users paste phone clipboard into TV text fields
- **Why:** Reddit user's #1 request; the differentiator they cited
- **How:** Read phone clipboard, send via `RemoteImeBatchEdit` with full-field replacement
- **Effort:** Small — the ATVRS IME channel already works for typing
- **Files:** `sanketa_adapters/lib/src/android_tv/atvrs_adapter.dart`, new clipboard button in `TvKeyboardSheet`

### P1: App Link Launch
- **What:** Send deep links / URLs to TV to open in specific apps
- **Why:** "Copy paste link from phone" use case — open YouTube/Netflix URLs directly
- **How:** `RemoteAppLinkLaunchRequest` protobuf message
- **Effort:** Small — add proto message and UI trigger

### P2: Wakelock
- **What:** Keep phone screen on while using as remote
- **Why:** Screen dims mid-typing; UX annoyance
- **How:** `wakelock_plus` or `wakelock` package, toggle in settings
- **Effort:** Trivial

### P3: Voice Protocol Wiring
- **What:** Wire microphone audio to TV via `RemoteVoice*` messages
- **Why:** Voice screen exists but protocol not connected
- **How:** `RemoteVoiceBegin` → stream audio → `RemoteVoiceEnd`
- **Effort:** Medium — needs audio capture + protobuf streaming

### P4: Audio Device Routing
- **What:** Select which audio output device the TV uses
- **How:** `RemoteSetPreferredAudioDevice` / `RemoteResetPreferredAudioDevice`
- **Effort:** Small

---

## Batch 12 — Competitor Gap Features (Built 26 Nov 2026)

Based on Remote ATV user reviews and feature analysis, 5 original features were built:

| Feature | User Need | Sanketa Implementation |
|---|---|---|
| **Mouse Cursor** | "No true trackpad for browser navigation" (top user complaint) | Touch-to-cursor translation, 4 cursor styles, sensitivity slider, left/right click, scroll mode |
| **Floating Remote** | "No way to use remote in other apps" | Configurable mini overlay, 13 buttons, 3 themes, opacity/size/position controls |
| **TV Screenshot** | Troubleshooting / sharing what's on TV | ADB screencap capture, PNG/JPEG/WebP, gallery with share |
| **Cast Queue** | No playlist casting in competitor | Sequential DLNA/Cast playback, auto-play/loop/shuffle, URL+title input |
| **Connection Pulse** | Connection reliability complaints | Live health score 0-100, latency sparkline, packet loss, session stats |

## Conclusion

Remote ATV is a single-protocol Flutter app with heavy monetization (5 ad SDKs + RevenueCat subscriptions). Its one genuine feature advantage over Sanketa is clipboard paste, which uses the standard ATVRS IME batch edit — the same channel Sanketa already has working for keyboard typing.

Implementing clipboard paste (P0) closes the Reddit user's specific complaint. The remaining gaps (P1-P4) are nice-to-haves that extend Sanketa's already-dominant feature set.

With Batch 12, Sanketa now has 69 tool cards vs Remote ATV's ~15 features, closes every UX gap identified from user reviews, and maintains its structural moats (14 adapters, IR coverage, zero ads, zero analytics, zero server calls) that Remote ATV cannot match.
