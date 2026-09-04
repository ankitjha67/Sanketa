# SANKETA — Project Context

> **What this file is.** The living working-memory of the project: current state, decisions taken, what is built vs. planned, and what happens next. The PRD says *what we are building and why*. This file says *where we are and what we decided along the way*.
>
> **Read order for anyone (human or agent) joining:** this file first, then the relevant PRD section by ID. Never read the full PRD to answer a status question — the answer belongs here.

| Field | Value |
|---|---|
| Project | SANKETA (संकेत) — Universal TV remote and casting platform for mobile |
| Companion PRD | [SANKETA_PRD_v0.1.md](SANKETA_PRD_v0.1.md) (v0.1, dated 09 Aug 2026) |
| Product owner | Ankit Jha |
| Context file version | v1.6 |
| Last updated | 4 September 2026 |
| Overall status | 🟢 **Full control matrix + IR complete (all pure-Dart, unit-tested).** Dart SDK 3.12.2. **Four packages, all analyzing clean, 123 unit tests green.** All **5 MVP network adapters** (Roku, Android TV, Tizen, webOS, BRAVIA) + **Rung-2 generic** (DLNA renderer control, DIAL app-launch) + the **IR subsystem** (6 protocol encoders, Sony codeset, IR adapter, **Coolix AC full-state encoder**, **D-pad assist typer**) + **multi-method discovery**. Everything composed over injected transport seams and tested with mocks/fakes. **Not yet hardware-validated — that is Phase 0**; per-adapter wire schemas/TLS flagged throughout. Awaiting the 9 open decisions (§5.2). |

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

**Phase: Foundation (pre-Phase-0).** The repo, the adapter contract, the domain models, and the first adapter (Roku) all exist, compile clean, and pass unit tests — the Dart toolchain is installed and green. What remains before Phase 1 is **real-hardware validation (Phase 0)** and sign-off on the blocking open decisions in §5.2. Note the honesty line: the Roku adapter is *unit-tested against a mock*, not yet *validated against a real Roku* — those are different bars, and only Phase 0 clears the second.

| Gate ahead | Requirement to pass |
|---|---|
| Start Phase 0 | OD-2 (launch geography) and OD-6 (IR DB sourcing) decided |
| Start Phase 1 | Phase 0 matrix signed off — all 5 MVP platforms green on pairing + keys + text; OD-3 (stack) confirmed by latency benchmark |

---

## 4. Next actions (the only list that matters right now)

0. ✅ **Toolchain resolved** (10 Aug 2026) — Dart SDK 3.12.2 installed; both packages compile clean and tests pass. See §13. Full Flutter SDK still to be added when UI work begins (Phase 1).
1. **Sign off the blocking open decisions** — OD-2, OD-3 (provisional), OD-6. Everything downstream waits on these. See §5.2.
2. **Trademark + store-name search for "SANKETA"** (OD-1). Cheap, slow, do it in parallel with everything else.
3. **Apply for the iOS multicast entitlement** (`com.apple.developer.networking.multicast`). Long lead time — risk R-6 says apply at project start, even though iOS is Phase 2.
4. **Write the Phase 0 spike plan** — per-cell validation scripts for the Section 11 matrix, plus the Flutter socket-latency benchmark that decides OD-3.
5. **Assemble the physical device lab** — 1 reference device per MVP adapter (Google TV stick, Samsung Tizen, LG webOS, Roku stick, Sony BRAVIA) + 2 IR targets + an IR-blaster phone.
6. ✅ **Initialise the repo** — done 10 Aug 2026. `git init` on `main`; skeleton + `sanketa_core` package with the `ControlAdapter` contract (PRD §13.3) and domain models as the first code artifacts. Not yet committed (awaiting your go-ahead), not yet compiled (see item 0).

---

## 5. Decision log

### 5.1 Decided

*(Empty. Every decision below is still open. Entries move here with date + rationale when signed off.)*

| ID | Decision | Chosen | Date | Rationale / consequence |
|---|---|---|---|---|
| — | — | — | — | — |

### 5.2 Open (from PRD Section 20)

| ID | Decision | PRD recommendation | Blocking? | Notes |
|---|---|---|---|---|
| OD-1 | Product name | SANKETA | Store listing only | Needs trademark + store-name search either way |
| OD-2 | Launch geography order | India-first | **Yes** — shapes IR DB + adapter order | Drives everything in Phase 0 scoping |
| OD-3 | Stack | Flutter shell + native core | **Yes** — before Phase 1 | Confirm via Phase 0 latency benchmark; revisit trigger is >15 ms p95 dispatch overhead |
| OD-4 | Minimum OS versions | Android 8.0 / iOS 15 | No | |
| OD-5 | Open-source the adapter layer | Open adapters (Apache 2.0), closed app + IR DB | No | Revisit end of Phase 1 |
| OD-6 | IR database sourcing | Hybrid: audited open core + commercial gap-fill | **Yes** — blocks FR-2.2 | License audit is the gate, not the code |
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
| Android TV adapter (remote v2) | Built · unit-tested (fake channel) | `sanketa_adapters/src/android_tv/`: **verified primitives** — protobuf codec (canonical wire vectors), framing, keycode map, pairing-secret hash (14 tests); adapter + pairing session composed & tested (14 tests). **Wire field-numbers, TLS/cert, IME text → Phase 0.** The keyboard-hero platform |
| Tizen / webOS / BRAVIA adapters | Built · unit-tested (fakes) | Tizen (WebSocket `SendRemoteKey`/`SendInputString`, token pairing, 7 tests), webOS (SSAP + pointer-button + IME text, client-key pairing, 7 tests), BRAVIA (IRCC-IP SOAP + PSK + `setTextForm`, 6 tests). Live text on all. **WS/TLS sockets + exact wire details → Phase 0** |
| DLNA + DIAL (Rung 2) | Built · unit-tested (mock HTTP) | `dlna/`: UPnP AVTransport + RenderingControl — play/pause/stop + volume/mute + `playUri` cast entry (7 tests); declares **no d-pad / no text** per FR-3.5. `dial/`: app launch/stop/status (3 tests). Broadest "any renderer" coverage |
| Discovery domain (core) | Built · unit-tested | `sanketa_core/src/discovery/`: brand **classifier** (recognises every MVP brand's mDNS/SSDP signature + Control/Keyboard/Cast badges), **dedup registry** (IP-keyed cross-method merge), **engine** with AP-isolation detection; 13 tests |
| Discovery backends (net) | Built · unit-tested + live-clean | `sanketa_discovery/`: **SSDP** (pure `dart:io`), **mDNS** (`multicast_dns`; gracefully degraded on Windows dev host, full on Android/iOS targets), **TCP-probe** (loopback-tested). Live LAN scan runs with 0 backend errors |
| IR encoding engine | Built · unit-tested | `sanketa_ir/`: NEC, NEC-extended, Samsung, Sony SIRC 12/15/20, RC5, raw → carrier Hz + µs pattern. **Verified by round-trip decode** (encode→decode→assert bits); 10 tests. Compiled Sony/NEC waveforms hand-checked correct |
| IR codeset + adapter | Built · unit-tested | Codeset model + a **real Sony SIRC codeset**; `IrControlAdapter` puts IR behind the *same* `ControlAdapter` contract (`Transport.infrared`, `textMode: none` → assist, hold-to-repeat per FR-2.4); 7 tests. Native emit seam (`IrTransmitter`) injected — real `ConsumerIrManager` impl comes with the Flutter app |
| IR AC full-state (Coolix) | Built · unit-tested | `ir/ac/`: `AcState` + `AcEncoder` interface + **Coolix encoder** + `IrAcController` (stateful: temp±/mode/fan/power re-emit the full frame); 9 tests. OFF code + temp gray-table verified; ON-frame field placement flagged for Phase 0 (FR-2.5) |
| D-pad assist typer | Built · unit-tested | `ir/assist/`: shortest-path arrowing over an on-screen keyboard grid with wrap optimisation; one OK per char (FR-4.4 AC); 6 tests. Pure algorithm, fully verified |
| Conformance suite | Not started | One script, every adapter (FR-3.1 AC ≥95%). The 8 adapter test files seed it |

### MVP (Phase 1) — all P0 unless noted

| FR | Feature | Priority | Status | Notes |
|---|---|---|---|---|
| FR-1.1 | Zero-input LAN discovery (mDNS + SSDP + probes) | P0 | Built · unit-tested | Network path done: SSDP + mDNS + TCP-probe backends, IP-keyed dedup, brand + capability badges, AP-isolation detection. Remaining: auto subnet-scan candidate list for probe, and real-device validation (Phase 0 AC: GTV+Samsung+Roku all appear <6 s) |
| FR-1.2 | Permission choreography | P0 | Not started | iOS Local Network prompt is funnel risk R-2 |
| FR-1.3 | Manual add (IP / brand+model / QR) | P0 | Not started | |
| FR-1.4 | Per-platform pairing flows | P0 | Built · unit-tested | ATV code handshake (session), Tizen token, webOS client-key, BRAVIA PSK, Roku no-auth — each drives its native auth via `PairingContext`. Persisting secrets to Keystore/Keychain is the native Phase-1 wiring |
| FR-2.1 | IR hardware detection | P0 (Android+IR) | Not started | Native `ConsumerIrManager.hasIrEmitter()` — modelled as the `IrTransmitter.available` seam; real check lands with the Flutter app |
| FR-2.2 | IR code database | P0 | Model built; **content blocked on OD-6** | Codeset model + encoders done; 1 real Sony codeset bundled. The *pack DB + licensing* is the OD-6 gate, not the code |
| FR-2.3 | Guided codeset matching wizard | P0 | Not started | UI flow; sits on top of the codeset model |
| FR-2.4 | IR emission quality (<100 ms, repeats) | P0 | Built (logic) · unit-tested | Correct carrier per protocol, pre-baked patterns, NEC/Samsung repeat frames, hold-to-repeat in the adapter. Real tap-to-emit latency needs a device (Phase 0) |
| FR-2.5 | Beyond-TV IR devices (AC, soundbar, STB, projector) | P0 | Built · unit-tested | Stateless protocols cover STB/soundbar/projector via codesets; **AC full-state encoder built** (Coolix + `IrAcController`, stateful frames). More AC protocols (Gree/Daikin) + on-device validation Phase 0 |
| FR-2.6 | No IR learning on phones (explicit non-feature) | — | N/A | Bridge-only, FR-8 |
| FR-3.1 | Command coverage, 5 MVP adapters | P0 | **5 of 5 built** · unit-tested | Roku, Android TV, Tizen, webOS, BRAVIA — all composed + tested with mocks/fakes. Conformance suite + real-device runs are Phase 0 |
| FR-3.2 | Session behaviour (persistent conn, backoff) | P0 | Not started | |
| FR-3.3 | Power-on paths (WoL/WoWLAN) | P0 | Not started | |
| FR-3.4 | State readback where available | P0 | Not started | Omit claims where write-only |
| FR-3.5 | Graceful capability degradation | P0 | Built (core) · unit-tested | Every adapter emits a `CapabilityMap`; **DLNA proves it** — declares no d-pad, no text (tested). UI consumption lands with the Flutter shell (Phase 1) |
| FR-4.1 | **Live text injection (hero)** | P0 | Built · unit-tested (all 5) | Roku `Lit_`, Android TV IME, Tizen `SendInputString`, webOS `insertText`, BRAVIA `setTextForm` — every MVP adapter has a live-text path, tested. Per-platform on-device validation Phase 0 |
| FR-4.2 | Voice-to-TV | P0 | Not started | Audio never leaves phone except to OS speech service |
| FR-4.5 | Field-state honesty copy | P0 | Not started | |
| FR-5.1–5.5 | Remote UI, trackpad, haptics, simple mode, a11y | P0 | Not started | |
| FR-6 | App launching + input switching | P0 | Partial | Launch: webOS `system.launcher`, Roku `/launch`, **DIAL** app-launch; input switching via per-adapter keys. Android TV app-link + more Phase 0 |
| FR-7.1 | Local media casting (Cast + DLNA + Roku) | P0 | Partial | **DLNA `playUri`** (SetAVTransportURI + Play) built + tested — the first cast primitive. Remaining: embedded LAN media server (tokened), Google Cast sender, codec pre-flight |
| FR-10 | Settings, **connection doctor**, diagnostics | P0 | Not started | Projected to deflect most support contacts |

### Fast-follow / later phases

| FR | Feature | Priority | Phase | Status |
|---|---|---|---|---|
| FR-3.6 | Fire TV advanced via ADB (opt-in, default off) | P1 | 2 | Not started |
| FR-4.3 | Search shortcuts (Roku ECP search, deep links) | P1 | 2 | Not started |
| FR-4.4 | D-pad assist fallback (shortest-path arrowing) | P1 | 2 | **Built · unit-tested** — `AssistTyper` over a keyboard grid with wrap optimisation; one OK per char. Pure algorithm, verified |
| FR-7.2 | Screen mirroring (MediaProjection / ReplayKit) | P1 | 2 | Not started |
| FR-7.3 | Web video hand-off | P1 | 3 | **Blocked on OD-7** (counsel) |
| FR-8 | Bridge hardware (BroadLink-class) | P1 | 2 | Not started |
| FR-9.1 | Rooms and profiles | P1 | 2 | Not started |
| FR-9.5 | Backup / encrypted sync | P1 | 2 | Not started |
| FR-9.2 | Macros / activities | P2 | 3 | Not started |
| FR-9.3 | Widgets and quick-settings tiles | P2 | 3 | Not started |
| FR-9.4 | Wearables (Wear OS / watchOS) | P2 | 3 | Not started |

### Explicit non-goals (v1) — do not build, do not accept scope creep

General smart-home control · DRM circumvention of any kind · cloud-relay / out-of-home control · TV-side receiver app as a v1 dependency · voice-assistant platform skills · Windows/desktop clients.

---

## 7. Adapter status board

Statuses: `Unvalidated` (Phase 0 pending) · `Validated` · `Built` · `Conformance-passing` (≥95 % of declared command set)

| Platform | Phase | Transport | Text capability | Status |
|---|---|---|---|---|
| Android TV / Google TV | MVP | protobuf/TLS, 6466/6467 | live | **Adapter built + unit-tested (fake channel)**; primitives (codec/framing/keymap/secret) verified; wire schema + TLS Unvalidated (Phase 0) |
| Samsung Tizen | MVP | WebSocket, 8001/8002 | live (field-dependent) | **Adapter built + unit-tested (fake WS)**; sockets/token Unvalidated (Phase 0) |
| LG webOS | MVP | SSAP WebSocket, 3000/3001 | live (IME service) | **Adapter built + unit-tested (fake WS)**; pointer-socket + sockets Unvalidated (Phase 0) |
| Roku | MVP | ECP REST, 8060 | literal keys + search endpoint | **Adapter built + unit-tested (mock)**; protocol Unvalidated on real hardware (Phase 0) |
| Sony BRAVIA | MVP | ATV protocol / IRCC-IP + REST | live | **Classic IRCC adapter built + unit-tested (mock HTTP)**; modern sets route via Android TV. PSK/PIN Unvalidated (Phase 0) |
| Infrared (any TV) | MVP | ConsumerIrManager | none → assist mode | Unvalidated |
| Fire TV | 2 | DIAL + ADB opt-in | via ADB only | Unvalidated |
| Vizio SmartCast | 2 | REST, 7345 | partial | Unvalidated |
| Panasonic Viera | 2 | SOAP, 55000 | partial | Unvalidated |
| Philips JointSpace | 2 | REST, 1925/1926 | partial | Unvalidated |
| Hisense VIDAA | 2 | MQTT, 36669 | partial | Unvalidated |
| TCL | 2 | Model-routed | per route | Unvalidated |
| Generic DLNA | 2 | UPnP AVTransport | none | **Adapter built + unit-tested (mock HTTP)** — transport + volume + `playUri`; HTTP calls Unvalidated on real renderer (Phase 0) |
| DIAL (app launch) | 2 | SSDP + REST | n/a | **Client built + unit-tested (mock HTTP)** — launch/stop/status |
| Apple TV | P2 research | Companion (reverse-engineered) | — | Not pursued (OD-9) |

---

## 8. Architecture quick reference

```
Flutter UI shell  →  Core domain (DeviceRegistry, SessionManager, CommandRouter,
                     CapabilityMap, CastCoordinator, QueueEngine, PairingVault)
                  →  Discovery engine | Adapter set | Casting engine
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
| R-5 | IR DB gaps or licensing challenge | **Open — OD-6 unresolved** | Blocks FR-2.2 today |
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

## 12. Change log

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

---

## 13. Toolchain — DECIDED (10 Aug 2026)

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
| 1. Native network adapters | Richest control + **the keyboard** | Smart platforms (GTV, Tizen, webOS, Roku, BRAVIA…) | 🟢 **5 of 5 built & unit-tested** — Roku, Android TV, Tizen, webOS, BRAVIA. Live text on all. Hardware-validate in Phase 0 |
| 2. Generic network protocols | Basic control + casting without a native adapter | Cast / DIAL / DLNA devices, long-tail brands | 🟢 **DLNA renderer control + DIAL app-launch built & tested.** Google Cast sender is part of the casting engine (FR-7) — next |
| 3. Phone IR | Power/volume/nav on **anything with an IR receiver, offline** | **Any TV/STB/AC ever made — old, non-smart, any brand** | 🟢 Encoders (NEC/NEC-ext/Samsung/Sony SIRC/RC5/raw) + Sony codeset + IR adapter + **Coolix AC full-state** + **D-pad assist typer**, all built & tested. Remaining: native `ConsumerIrManager` emit, codeset DB content (OD-6), matching wizard |
| 4. WiFi-to-IR bridge | IR for phones without a blaster | iPhone + IR-less Android → non-smart TVs | ⚪ Phase 2 |

**Regions** ride on top of this: IR codeset packs and adapter/brand priority are geo-weighted (OD-2 India-first), but the ladder itself is region-agnostic. **Four of five rungs are now built and unit-tested in pure Dart** — only the WiFi-IR bridge (Rung 4, Phase 2) is untouched. What stands between this code and a user actually pressing buttons: the **native layer** (Flutter platform channels — IR emit via `ConsumerIrManager`, TLS sockets, discovery entitlements), the **codeset DB** (OD-6), and **Phase 0 hardware validation** to turn every "unit-tested" into "verified."

---

*The control brain is complete: all 5 MVP network adapters, generic DLNA/DIAL, multi-method discovery, and the full IR subsystem (TV codesets + AC + assist) — 123 tests, all pure-Dart and green, every brand behind one contract. Nothing is hardware-validated yet — that is the entire point of **Phase 0**, which now has a lot to validate. The two things between this and a shipping app: the **native/Flutter layer** (platform channels for IR emit, TLS sockets, capture, Keystore/Keychain, WoL) and the **UI shell** that consumes these capability maps. Then the casting engine (FR-7) and the household layer. Repo is uncommitted — say the word and I'll make the first commit.*
