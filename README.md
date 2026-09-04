# SANKETA (संकेत)

Universal TV remote and casting platform for mobile. One app that controls **any**
TV — network protocols for smart platforms, infrared for everything else — replaces
arrow-key TV typing with the phone keyboard/voice (the hero feature), and casts local
media to the screen.

> **Start here:** [CONTEXT.md](CONTEXT.md) for current status and decisions, then the
> [PRD](SANKETA_PRD_v0.1.md) for requirements. Do not read the full PRD to answer a
> status question — that is what CONTEXT.md is for.

## Status

🟢 **Control matrix + IR + the app's UI shell.** Six packages, analyzing clean,
**141 tests passing**: the contract, discovery, **all 5 MVP network adapters**
(Roku, Android TV, Tizen, webOS, BRAVIA), **generic DLNA + DIAL**, the full IR
subsystem (encoders, Sony codeset, Coolix AC, D-pad assist typer) — plus the
**OmniBeam design tokens** and a **Flutter Remote screen** wired straight to the
`ControlAdapter` contract. Nothing is hardware-validated yet — that is Phase 0.
See [CONTEXT.md](CONTEXT.md) §6 (tracker) and §14 (coverage ladder).

## Repository layout

```
SANKETA/
├─ SANKETA_PRD_v0.1.md   Requirements (authoritative for what/why)
├─ CONTEXT.md            Status, decisions, build tracker (authoritative for where we are)
├─ sanketa_core/         Pure-Dart core (no Flutter, no deps)
│  └─ lib/src/
│     ├─ adapter/        ControlAdapter — the interface every brand implements (PRD §13.3)
│     ├─ discovery/      Classifier + dedup registry + engine (brand-agnostic)
│     └─ model/          Key, TextOp, CapabilityMap, Device, Pairing, StateDelta
├─ sanketa_adapters/     Brand adapters (implement ControlAdapter) + generics
│  └─ lib/src/  roku · android_tv (protobuf/TLS) · tizen · webos · bravia (IRCC)
│               dlna (UPnP renderer) · dial (app launch) · common/ws_channel
├─ sanketa_discovery/    Real socket discovery backends (implement DiscoveryBackend)
│  └─ lib/src/           ssdp_backend · mdns_backend · probe_backend
│     └─ example/discover.dart   scans your LAN, prints devices from any brand
├─ sanketa_ir/           IR subsystem (Rung 3: any TV/STB/AC ever made, offline)
│  └─ lib/src/  ir_codec (NEC/SIRC/RC5/Samsung/raw) · ir_codeset · ir_control_adapter
│               ac/ (Coolix AC full-state) · assist/ (D-pad shortest-path typing)
│     └─ example/ir_compile.dart   compiles codeset keys → carrier + timing pattern
├─ sanketa_design/       OmniBeam design tokens (pure Dart): colours · type · spacing · elevation
├─ sanketa_app/          Flutter UI shell — the Remote screen, wired to ControlAdapter
│  └─ lib/  theme/ · control/ (DemoAdapter + RemoteController) · widgets/ · screens/
└─ design/               Stitch design source: DESIGN.md · code.html · screen.png
```

## Running the app

```bash
cd sanketa_app && flutter run          # or: flutter run -d chrome
```

The Remote screen renders the OmniBeam design and drives a `DemoAdapter` through
the `ControlAdapter` contract (every keypress logs a "sent to TV" line). Swap in
a real adapter — Roku, Android TV, IR — and nothing above the contract changes.

## The coverage ladder ("any brand, old and new")

Universal reach comes from a fallback ladder, not one protocol. Status in
[CONTEXT.md §14](CONTEXT.md): discovery 🟢 · native adapters 🟢 (5/5 built) ·
generic DLNA + DIAL 🟢 · **phone IR 🟢 (encoders + AC + assist typer)** · WiFi-IR
bridge ⚪ (Phase 2). Four of five rungs are built and unit-tested; a device is
served by the highest rung it reaches, and IR is the backstop that reaches
everything with an IR receiver.

## Architecture in one paragraph

A Flutter UI shell sits over a platform-agnostic core. Every controllable target —
Android TV, Tizen, webOS, Roku, BRAVIA, an IR blaster, a BroadLink bridge — implements
the **one** `ControlAdapter` interface. Nothing above that interface knows brands exist;
**capability flags, never brand names, drive the UI.** Adding a brand touches zero core
code (NFR-14). That contract is the moat.

## Design red lines (see CONTEXT.md §9)

- Typed text is never logged, analysed, or sent anywhere except the target TV.
- Zero third-party ads, ever. No account required except optional encrypted sync.
- The control plane makes zero calls to SANKETA servers. IR works fully offline.
- No DRM circumvention. No private APIs. No raw error codes in user-facing copy.

## Building `sanketa_core`

Requires the Dart SDK (≥ 3.0). Pure Dart, no external packages.

```bash
cd sanketa_core
dart pub get
dart analyze
dart test
```
