# SANKETA — Complete Bug Audit & Fix Plan

**Date:** 2026-11-10 (verified 2026-11-11)  
**Scope:** Every bug discovered from project start through today  
**Rule:** This document is READ-ONLY analysis. No code has been modified.  
**Evidence levels:** ✅ Confirmed on device · 📄 Confirmed in code · 🔍 Inferred from code + research · 💤 Latent (untested path)  
**Verification pass (2026-11-11):** Every claim checked against the current uncommitted working tree. 7 of 31 original claims were stale (code updated since the audit notes were written). Affected entries are marked ~~STALE~~ or moved to Previously Fixed. 24 bugs remain confirmed open.

---

## Table of Contents

- [Tier 1 — Keyboard (hero feature broken on all three TVs)](#tier-1--keyboard)
- [Tier 2 — Connection & Liveness](#tier-2--connection--liveness)
- [Tier 3 — UI Honesty & Gating](#tier-3--ui-honesty--gating)
- [Tier 4 — Discovery](#tier-4--discovery)
- [Tier 5 — Cast & Mirror](#tier-5--cast--mirror)
- [Tier 6 — Security & Privacy](#tier-6--security--privacy)
- [Tier 7 — Build & Test](#tier-7--build--test)
- [Previously Fixed Bugs](#previously-fixed-bugs)
- [Untested / Unknown](#untested--unknown)
- [Suggested Execution Order](#suggested-execution-order)

---

## Tier 1 — Keyboard

The keyboard is the hero feature. ~~It is broken on every TV brand we have tested.~~ Samsung text input (buffering, delete, clear, submit) was fixed in the uncommitted working tree. BRAVIA and Android TV IME protocol issues remain open.

---

### K1 · Enter types the highlighted on-screen keyboard letter instead of submitting

| Field | Value |
|---|---|
| **Evidence** | ✅ Samsung: "Enter to TV now types letter a earlier it was q" · ✅ BRAVIA: "Keyboard still types Q when I click on Enter on TV" |
| **Affects** | Samsung (TizenAdapter), BRAVIA (SimpleIpAdapter fallback), potentially Haier |
| **Root cause** | ~~Two separate code paths, same symptom~~ — **Samsung path FIXED** (see Previously Fixed). BRAVIA path remains: |

**~~Samsung path~~ FIXED** — `tizen_adapter.dart:137-138` now sends `_inputEndFrame()` (`SendInputEnd`), not `sendKey(Key.ok)`. Verified in current working tree.  
**BRAVIA path (OPEN)** — `simple_ip_adapter.dart:173-187`: `submit` tries `atvrs.sendKey(66)` (KEYCODE_ENTER over the sidecar channel), but `ensureConnected()` at `bravia_atvrs.dart:340-348` swallows all connection failures silently. When the sidecar isn't connected (which is the current state — the BRAVIA cert was rewritten on Nov 10 and never re-paired), the code falls back to `sendKey(Key.ok)` at line 185, which maps to Simple IP IRCC code 13 = `DPAD_CENTER`. DPAD_CENTER on AOSP LeanbackIME types the highlighted key. The code comment at lines 174-177 literally describes this bug.

**Fix path:**

1. **~~Samsung~~ ALREADY FIXED** — `tizen_adapter.dart` submit now sends `SendInputEnd`. IME event listeners (`imeStart`/`imeUpdate`/`imeEnd`) still not wired — remaining gap for full session management.

2. **BRAVIA** — `simple_ip_adapter.dart`:
   - Remove the silent `sendKey(Key.ok)` fallback at line 185. When the sidecar is not connected, return `CommandResult.failure('ATVRS sidecar not connected — re-pair required')`.
   - In `bravia_atvrs.dart:340-348`, make `ensureConnected()` propagate the error instead of catching and ignoring it.
   - After ATVRS re-pair, KEYCODE_ENTER (66) over the sidecar should submit. Research confirms ENTER fires `performEditorAction` on AOSP LeanbackIME and submits on Gboard TV.

3. **General** — `tv_keyboard_sheet.dart:236-238`:
   - No change needed here (it correctly calls `c.submit`), but add a visible toast/feedback when submit fails so the user knows to re-pair.

**Verify:** Re-pair BRAVIA; type text, press Enter → text field submits. On Samsung: type text, press Enter → text commits.

---

### ~~K2 · Samsung text input: single-char sends, no backspace/clear, preview desync~~ ALREADY FIXED

| Field | Value |
|---|---|
| **Evidence** | 📄 `tizen_adapter.dart:131-146` |
| **Affects** | Samsung BU8000 |
| **Status** | **FIXED in current working tree** |
| **What changed** | `TizenAdapter` now buffers in `_imeText`: `insert` appends and sends full string via `SendInputString(base64(_imeText))`, `delete` removes last char and re-sends, `clear` sends empty string, `submit` sends `SendInputEnd`. |

**Remaining gaps (not bugs — enhancements):**
- No `imeStart`/`imeUpdate`/`imeEnd` event listeners yet — `_imeText` can desync if the user types directly on the TV remote.
- YouTube may ignore `SendInputString` entirely (IP Control docs report this) — no gate on `imeStart`.
- `remote_controller.dart:962-994` still uses optimistic `tvText` (see K6).

---

### K3 · BRAVIA text: correct field (21) but wrong protobuf structure

| Field | Value |
|---|---|
| **Evidence** | 📄 `bravia_atvrs.dart:378-383` — sends on field **21** (~~not 82 as originally noted~~) |
| **Affects** | BRAVIA (text likely never appears on TV due to wrong structure) |
| **Root cause** | ~~`_sendImeBatchEdit` wraps the text in field 82~~ **Correction:** the code sends on field **21** (verified in current working tree). However, the structure is still wrong: `_imeCounter` is used for both counter fields 1 and 2, and the nesting `{1:{1:text}}` differs from the reference format `{1:insert_flag, 2:{start, end, value}}`. The real `RemoteImeBatchEdit` structure is `{1:ime_counter, 2:field_counter, 3:[{1:insert_flag, 2:{1:start, 2:end, 3:value}}]}`. Additionally: `_imeCounter` serves double duty (used for both `ime_counter` and `field_counter` but they are independent values from fields 20 and 22), and the edit_info array structure does not match the `androidtvremote2` reference. |

**Fix path:**

1. **Shared** — Create `atv_ime_session.dart` in `sanketa_adapters/lib/src/android_tv/`:
   - Class `AtvImeSession` that:
     - Parses incoming field 20 (`RemoteImeKeyInject`) → extracts `app_info.counter` as `imeCounter` and `text_field_status.counter_field` as `fieldCounter`.
     - Parses incoming field 22 (`RemoteImeShowRequest`) → extracts `remote_text_field_status.counter_field` as `fieldCounter`, plus `value`, `start`, `end` for current field state.
     - Provides `buildImeBatchEdit(text)` → `RemoteMessage` on field **21** with:
       ```
       { 1: imeCounter, 2: fieldCounter, 3: [{ 1: 1, 2: { 1: len(text), 2: len(text), 3: text } }] }
       ```
       (matching `androidtvremote2` v0.3.3 format: `start=end=len(text)`, `value` = inserted text only, `insert=1`).
     - Tracks `_sentText` to compute delta for incremental sends.

2. **`bravia_atvrs.dart`** — Replace `_sendImeBatchEdit` and `_textBuffer`:
   - Instantiate `AtvImeSession` and feed it incoming fields 20, 22 from the existing handler at lines 430-504.
   - `sendText(insert)`: call `imeSession.buildImeBatchEdit(newText)` → write to socket on field **21**.
   - Remove field 82 entirely.
   - Remove `_textBuffer` (the session tracks state).

3. **`android_tv_adapter.dart`** — Same shared `AtvImeSession`:
   - Replace `buildImeText` call at line 118 with `imeSession.buildImeBatchEdit(op.text)`.
   - Subscribe to `channel.messages` stream (currently ignored) to feed fields 20/21/22 into the session.

4. **`atv_messages.dart`** — Remove or deprecate `buildImeText` and module-global `_imeSeq`.

**Verify:** Pair with BRAVIA, open YouTube search, type "hello" → letters appear one by one. On Haier, same test.

---

### K4 · Android TV hardcoded IME counters; start defaults to text.length; clear unimplemented

| Field | Value |
|---|---|
| **Evidence** | 📄 `atv_messages.dart:58-74` — `buildImeText` takes `imeCounter`/`fieldCounter` as params |
| **Affects** | Haier (Android TV), any future Android TV target |
| **Root cause** | ~~`buildImeText` uses a module-global `_imeSeq`~~ **Correction:** `buildImeText` takes `imeCounter` and `fieldCounter` as parameters (no module-global `_imeSeq`), and `start` defaults to `text.length` (not 0). However, the adapter passes **hardcoded `1`** for both counters and never updates them from the TV's responses. The TV expects these to echo the counters from its own `RemoteImeKeyInject` (field 20) and `RemoteImeShowRequest` (field 22). Stale/wrong counters → edit silently ignored, no error. `clear` still returns a hard failure. |

**Fix path:**

Subsumed by K3's `AtvImeSession` — the same class fixes this for both BRAVIA and plain Android TV. Specifically:
1. `AtvImeSession` echoes real counters from fields 20/22.
2. Sets `start = end = len(accumulatedText)` per the reference implementation.
3. Implements `clear` as a batch edit with `value=''`, `start=0`, `end=len(currentText)`.

Additionally in `live_atv_channel.dart`:
- Parse and forward fields 20, 21, 22 (currently ignored at lines 298-360) via the channel's message stream so `AtvImeSession` receives them.

**Verify:** On Haier, open a text field, type multiple characters → all appear (not just the last). Clear → field empties.

---

### ~~K5 · Sticky `_gotError` bricks the Android TV remote after any RemoteError~~ ALREADY FIXED

| Field | Value |
|---|---|
| **Evidence** | 📄 `live_atv_channel.dart:79,87` |
| **Affects** | Haier, any Android TV |
| **Status** | **FIXED in current working tree** |
| **What changed** | `_gotError` IS cleared in `connect()` (verified at lines 79 and 87). Reconnecting now resets the error flag, so a transient `RemoteError` no longer permanently bricks the session. |

**Remaining consideration:** The adapter still returns `'not_paired'` at `android_tv_adapter.dart:153-155` when `_channel.gotError` is true. Since `_gotError` now resets on reconnect, this is a less severe issue, but it would be better to distinguish transient errors from handshake failures.

---

### K6 · Controller: optimistic tvText, unordered unawaited sends, generic errors

| Field | Value |
|---|---|
| **Evidence** | 📄 `remote_controller.dart:962-994` |
| **Affects** | All TVs |
| **Root cause** | Multiple issues in the text pipeline: (a) `tvText` is mutated locally *before* the adapter result returns, so the phone preview is always "ahead" and diverges on failure. (b) Text operations are `unawaited` — rapid typing can reorder. (c) `submit` (line 990) sends ENTER but doesn't clear `tvText`. (d) All errors go through `_humanCommandError` which maps everything to the generic "Commands are not reaching the TV." (e) "Search on TV" button (`connection_bar.dart:46`) calls `c.submit` which sends ENTER — not a search action. |

**Fix path:**

1. **FIFO queue** — Add a `_textOpQueue` (simple async queue) in `RemoteController`:
   - Each `type`/`backspace`/`clearText`/`submit` call enqueues an operation.
   - Operations execute serially (await each before starting the next).
   - On failure, optionally pause the queue and show a typed error.

2. **Remove optimistic tvText** — Only update `tvText` *after* the adapter confirms success. Seed `tvText` from the adapter's IME session state where available (Android TV field 22 reports the TV's actual field content).

3. **Clear tvText on submit** — After a successful submit, set `tvText = ''`.

4. **Typed errors** — Replace `_humanCommandError` for text ops with specific messages:
   - `'not_paired'` → "TV connection lost — tap to reconnect"
   - `'field delete/clear not exposed…'` → "This TV doesn't support backspace from the remote"
   - `'ATVRS sidecar not connected'` → "Re-pair needed — open Settings > Pair"

5. **"Search on TV"** — Either remove the button or make it send a `Key.search` (keycode 84) instead of `submit`.

**Verify:** Type rapidly on Samsung → letters appear in order without gaps. Delete after a failed send → phone preview matches TV.

---

### K7 · Debug logging across adapter layer risks leaking typed text

| Field | Value |
|---|---|
| **Evidence** | 📄 91 logging call sites across 5 files (~~not 92 as originally counted; no blanket hex dump at line 299~~) |
| **Affects** | All Android TV targets (Haier, BRAVIA sidecar), Samsung, Cast |
| **Root cause** | ~~The blanket `print` at line 299 dumps hex of every frame~~ **Correction:** There is no blanket print at a single line; `_log` calls are targeted per message type. However, field 22 (`RemoteImeShowRequest`) carries the TV's text field contents back to the phone, and existing targeted `_log` calls throughout the adapter layer could expose this data. **The PRD (§9) says: "Typed text is never logged, never analyzed, never leaves the phone except to the target TV. This is an absolute rule."** |

**Fix path:**

1. **`live_atv_channel.dart`** — Audit all `_log` calls; remove any that include field 20/21/22 payloads (IME content). Keep connection-state logs without payload data.

2. **Audit all 91 logging call sites** (grep found 91 across 5 files):
   - `live_atv_channel.dart` (25 calls) — Remove frame payload data; keep connection-state logs.
   - `bravia_atvrs.dart` (22 calls) — Remove `_atvrsLog` calls that include handshake/cert bytes or text content; keep pair-step logs.
   - `google_cast_adapter.dart` (3 calls) — Keep, but strip message payloads.
   - `live_ws_channel.dart` (1 call) — Remove URL logging at line 40 (will leak tokens once added).
   - `remote_controller.dart` (40 calls) — Keep connection state; strip text and key names (current `debugPrint` of key presses).

**Verify:** `adb logcat | grep -i sanketa` while typing on the keyboard → zero typed characters appear in the log.

---

## Tier 2 — Connection & Liveness

---

### C1 · Samsung: "Connected" before authorized, no token, ws://8001 false positive

| Field | Value |
|---|---|
| **Evidence** | 📄 `tizen_adapter.dart:107` — `connect() = _ch.connect()` only; `live_ws_channel.dart` |
| **Affects** | Samsung BU8000 |
| **Root cause** | `connect()` calls `_ch.connect()` which opens the WebSocket and returns. But: (a) The Samsung TV shows an "Allow" prompt — the app doesn't wait for the `ms.channel.connect` event that confirms the user allowed it. (b) No `token` parameter is sent in the URL, so reconnection after the TV reboots requires re-authorization. (c) `ws://8001` fallback is tried on connection error — on 2018+ Samsung TVs, port 8001 is open but doesn't support the remote protocol properly; connecting to it is a false positive. |

**Fix path:**

1. **`tizen_adapter.dart`** — After `_ch.connect()`, wait for a `ms.channel.connect` message (with timeout):
   ```
   connect(): 
     await _ch.connect()
     final event = await _ch.messages.firstWhere(
       (m) => m['event'] == 'ms.channel.connect', 
       orElse: timeout 15s → throw 'TV did not authorize')
     _token = event['data']['token']  // persist for reconnect
   ```
   - Token shape: string on real TVs, number in some test fixtures — accept both.
   - Also handle: `ms.channel.unauthorized` → "TV denied access" (not "connection failed"). `ms.channel.timeOut` → "Allow not pressed" or "token expired".
   - Skip events like `ed.edenTV.update`, `ms.voiceApp.hide`, `ms.remote.touchEnable/touchDisable` while waiting for connect (they can arrive before it).
   - Add an `isAuthorized` state (separate from `isConnected`) → UI shows "Waiting for TV approval…" during the Allow prompt.

2. **Token persistence** — Store the Samsung token in the same secure vault as ATVRS certs (see S2). On reconnect, append `&token=$token` to the wss:8002 URL. **Confirmed: token must be on wss/8002 only** (samsungtvws). HA persists a new token when the connect event returns a different one — do the same (tokens can change). Ensure TV's Device Connection Manager → Access Notification is "First time only" (document this for the user).

3. **`live_ws_channel.dart`** — Remove `ws://8001` fallback for Samsung. **Confirmed: 8001 serves REST (GET /api/v2/) but refuses the remote channel with `ms.channel.unauthorized` on token-auth sets** (tested on 2018 NU8000, 2023 S95C). Use 8001 only for the device-info REST endpoint. Gate with: `GET http://tv:8001/api/v2/` → parse `device.TokenAuthSupport`; if `"true"`, use wss:8002 only.

4. **Device info at connect** — Before opening the WebSocket, call `GET http://tv:8001/api/v2/`. Parse:
   - `device.TokenAuthSupport` → wss:8002 required
   - `device.wifiMac` → store for WoL (can be the literal `"none"` — handle that)
   - `device.modelName` → display in UI
   - `device.FrameTVSupport` → power-off behavior (hold KEY_POWER 3 s for Frame TVs)
   - `isSupport` → second JSON decode needed (it's a JSON string inside JSON)

4. **`remote_controller.dart:476-486`** — Pass the token to `TizenAdapter` constructor; load it from the vault at adapter creation time.

**Verify:** Connect to Samsung → phone shows "Waiting for approval" → user presses Allow on TV → phone shows "Connected". Restart TV → app reconnects using saved token without re-prompting.

---

### C2 · No liveness supervision / reconnect after connection drops — **PARTIALLY FIXED**

| Field | Value |
|---|---|
| **Status** | **Step 1 done:** `SessionManager` built in `sanketa_app/lib/control/session_manager.dart` and wired into `RemoteController` — exponential backoff (1s→2s→4s→8s→max 30s + 20% jitter), JSON persistence of last device, auto-reconnect on connection failure when `autoReconnect` is true. Remaining: real heartbeat per protocol (step 2), `AppLifecycleState` observer (step 3), disconnect callback from channels (step 4). |
| **Evidence** | 📄 `remote_controller.dart:187,696-698` (autoReconnect dead); `session_manager.dart` (tested but never used); no `heartbeat()` calls anywhere in app |
| **Affects** | All TVs |
| **Root cause** | (a) `autoReconnect` toggle is written and read in the settings UI but **never consumed** — no code path reads it to decide reconnection behavior. (b) `SessionManager` in `sanketa_core/src/session/` implements connect→heartbeat→backoff→reconnect but is **never instantiated** by the app. (c) `heartbeat()` is never called — `AndroidTvAdapter.heartbeat` just writes an unsolicited ping response (not a real liveness test). (d) `isConnected` is only set `false` at `remote_controller.dart:328,424,430` — a silent TCP drop leaves it `true` forever. (e) No `AppLifecycleState` observer → app resume after screen-off doesn't reconnect. |

**Fix path:**

1. **Wire `SessionManager`** — In `remote_controller.dart:_connectToDevice`:
   - Wrap the adapter in a `SessionManager` that calls `adapter.heartbeat()` every 15 s.
   - On heartbeat failure, trigger disconnect notification → UI shows "Reconnecting…"
   - Backoff reconnect: 2 s → 4 s → 8 s → 15 s → 30 s → 60 s, max 10 attempts.
   - Honor the `autoReconnect` toggle: if off, show "Connection lost" without auto-retry.

2. **Real heartbeat per protocol**:
   - Android TV: send `PingRequest{val1=random}`, expect `PingResponse{val1=same}` within 5 s.
   - Samsung: send `{"method":"ms.remote.control","params":{"Cmd":"Click","DataOfCmd":"KEY_VOLUP","Option":"false","TypeOfRemote":"SendRemoteKey"}}` ping equivalent, or rely on WebSocket pong.
   - BRAVIA: Simple IP `*SEPOWR################\n` (power query) → `*SNAPOWR…` expected within 2 s.

3. **`AppLifecycleState` observer** — In `remote_screen.dart` or `app_shell.dart`:
   - On `resumed`: if `isConnected` was true, call `adapter.heartbeat()` → if fails, trigger reconnect.
   - On `paused`: save last-connected device info for resume.

4. **Clear `isConnected` on drop** — Add a disconnect callback from each channel/adapter to the controller that sets `isConnected = false` and `notifyListeners()`.

**Verify:** Connect to any TV → kill WiFi for 30 s → re-enable → app reconnects within one backoff cycle. Lock phone for 2 min → unlock → remote still works.

---

### C3 · LiveAtvChannel defects (unstored timer, duplicate reconnects, optimistic isOpen)

| Field | Value |
|---|---|
| **Evidence** | 📄 `live_atv_channel.dart:211-234` (timer), `:91` (isOpen), `:119-121` (gotError), `:141-146` (not_paired) |
| **Affects** | Haier, BRAVIA sidecar |
| **Root cause** | Multiple interacting defects: (a) `_scheduleReconnect` at line 223 creates a `Timer` that is **not stored** → calling `close()` then `connect()` (which `pairAtvrs` does at RC:712-713, 750-751) can't cancel the old timer → old timer fires and tears down the fresh socket. (b) Old `_sub` (stream subscription) not cancelled on watchdog/handshake-failure reconnect paths → duplicate listeners on the new socket. (c) `isOpen` set `true` at line 91 (after TLS, before handshake) → commands can be sent before the TV accepts the handshake → silently dropped. (d) ANY handshake failure (including plain timeout) throws `StateError('not_paired')` → UI says "TV requires pairing" even for network glitches. |

**Fix path:**

1. **Store the reconnect timer** — `Timer? _reconnectTimer;` field; cancel in `close()`, `connect()`, and `_scheduleReconnect` before creating a new one.

2. **Cancel old subscription** — In every reconnect path: `await _sub?.cancel()` before creating a new stream listener.

3. **Defer `isOpen`** — Set `isOpen = true` only after successful handshake completion (after `_respondToConfigure` succeeds). Before that, `_send` should queue or reject commands.

4. **Distinguish timeout from rejection** — In the handshake:
   ```dart
   on TimeoutException → throw StateError('handshake_timeout')
   on TlsException → throw StateError('not_paired')
   on SocketException → throw StateError('connection_failed')
   ```
   Map these to different UI messages in `_humanConnectionError`.

**Verify:** Connect to Haier → disconnect WiFi for 15 s → reconnect WiFi → channel recovers without "TV requires pairing". Run pair flow twice rapidly → no crashes.

---

### C4 · LiveWsChannel follow-up defects

| Field | Value |
|---|---|
| **Evidence** | 📄 `live_ws_channel.dart:62,99-101,40` |
| **Affects** | Samsung, webOS |
| **Root cause** | (a) Accept-all certificate at line 62. (b) `_cleanup` at lines 99-101 nulls `_ws` unconditionally — if the old socket's `onDone` fires after a new socket is established, it nulls the new one. (c) `HttpClient` created at connect time is never closed → file descriptor leak across reconnects. (d) `dev.log` at line 40 prints the full WebSocket URL (will include the Samsung token once added). (e) No disconnect notification to the controller. (f) Fallback from wss to ws triggers on ANY error, including auth rejection. |

**Fix path:**

1. **TLS** — See S3 (TOFU pinning).
2. **Stale onDone** — Tag each connection with a generation counter; in `onDone`, check `if (generation != _currentGeneration) return;` before calling `_cleanup`.
3. **Close HttpClient** — `_client?.close(force: true)` in `_cleanup` and `disconnect`.
4. **Remove URL logging** — Delete `dev.log` at line 40. Or log only the host, not the full URL.
5. **Disconnect notification** — Add an `onDisconnect` callback or expose a state stream.
6. **Qualify fallback** — Only fall back to ws:// if the error is a TLS-specific failure (handshake exception), not auth rejection or timeout.

**Verify:** Connect/disconnect Samsung 10 times → no file descriptor leak (check with `lsof`). Kill and restart TV WiFi → reconnects without token in logs.

---

### C5 · Stuck "Connecting…" spinner on adapter creation failure

| Field | Value |
|---|---|
| **Evidence** | 📄 `remote_controller.dart:338` — `_createAdapter` outside `try` |
| **Affects** | All TVs |
| **Root cause** | In `_connectToDevice`, the call `final next = await _createAdapter(d)` at line 338 is **outside** the `try` block whose `finally` (lines 433-437) clears `isConnecting`. If `_createAdapter` throws (e.g., `_ensureDeviceCert` at RC:455 fails, or `Uri.parse(location)` at RC:569 throws), `isConnecting` stays `true` forever → spinner never stops, user can't retry. |

**Fix path:**

1. **Move `_createAdapter` inside the try** — Move lines 338-342 into the existing `try` block that starts at line 343. The `finally` at 433 already handles cleanup.

2. **Belt-and-suspenders** — Add a timeout to the entire `_connectToDevice`:
   ```dart
   _connectToDevice(d).timeout(Duration(seconds: 30), 
     onTimeout: () { isConnecting = false; notifyListeners(); throw TimeoutException('Connect timed out'); });
   ```

**Verify:** Enter a malformed manual IP (e.g., `999.999.999.999`) → error shown, spinner stops, user can try again.

---

### C6 · `forcedAdapterId` leaks across devices; reset selects wrong device

| Field | Value |
|---|---|
| **Evidence** | 📄 `remote_controller.dart:679` (written), Settings UI reset at `settings_screen.dart:356-358` |
| **Affects** | All TVs (when using protocol switch in settings) |
| **Root cause** | (a) `forcedAdapterId` is written at RC:679 but **never cleared when the user selects a different device**. So switching from a Samsung (where you forced 'tizen') to a Haier keeps the 'tizen' override → Haier gets a TizenAdapter. (b) The "Reset" button at SET:356-358 calls `selectDevice(c.selectedDevice)` — but `selectedDevice` is the *overridden clone* stored by `switchAdapter` at RC:680-688 (which has the forced adapterId baked in) → reset doesn't actually reset. |

**Fix path:**

1. **Clear on device change** — In `selectDevice` (RC:322-334), add `forcedAdapterId = null;` at the top.
2. **Fix Reset** — Store the *original* device reference separately from the adapter-overridden copy. Reset should call `selectDevice(originalDevice)` with `forcedAdapterId = null`.
3. **Re-probe on reset** — After clearing the override, re-run `probeProtocols` so the protocol rows in Settings update.

**Verify:** Connect to Samsung, force AndroidTV adapter in Settings, switch to Haier → Haier gets its own auto-detected adapter, not TizenAdapter. Reset → Samsung returns to TizenAdapter.

---

### C7 · webOS hardcoded ws://3000 — broken on 2022+ LG TVs

| Field | Value |
|---|---|
| **Evidence** | 📄 `remote_controller.dart:472-475`; 🔍 Research: aiowebostv requires wss:3001 on 2022+ firmware |
| **Affects** | Any LG TV with 2022+ firmware (💤 latent — no webOS TV tested) |
| **Root cause** | `_createAdapter` builds the webOS adapter with `ws://$host:3000` — no TLS, no port 3001 fallback. On 2022+ LG firmware, ws://3000 either hangs or refuses. |

**Fix path:**

1. **`remote_controller.dart:472-475`** — Change to: try `wss://$host:3001` first (5 s timeout); on TLS failure or timeout, fall back to `ws://$host:3000`. Log which worked.
2. **`webos_adapter.dart`** — Accept the URL as a constructor parameter (currently it's passed in).
3. **TLS** — Use `onBadCertificate: true` for now (webOS self-signed cert), with a TODO for TOFU pinning per S3.

**Verify:** Latent — requires a 2022+ LG TV. Unit test: mock server on both ports, verify fallback.

---

## Tier 3 — UI Honesty & Gating

---

### U1 · Hardcoded HDMI 1 / HDMI 2 / TV tabs, no real input list

| Field | Value |
|---|---|
| **Evidence** | 📄 `remote_pad.dart:83`, `remote_controller.dart:159` |
| **Affects** | All TVs |
| **Root cause** | Source tabs are hardcoded `[HDMI 1, HDMI 2, TV]`. `currentSource` defaults to `"HDMI 1"` and is never reset on device change. Android TV / Fire TV always fail with "input switching not yet supported". The label is passed as the input ID (`RC:922`), but TVs need protocol-specific IDs (BRAVIA uses `INPT` codes, Roku uses `hdmi1`/`tuner`, webOS uses `com.webos.app.hdmi1`). |

**Fix path:**

1. **Add `inputList` to capabilities** — `CapabilityMap.inputList` already exists in the model; populate it from each adapter's input query:
   - BRAVIA: Simple IP `*SEINPT################\n` returns available inputs.
   - Samsung: **KEY_HDMI1–KEY_HDMI4 are silently ignored** (confirmed on CU8000, multiple community reports). `KEY_HDMI` cycles inputs, `KEY_SOURCE` opens the source menu. For direct switching: Samsung IP Control on port 1516 (HTTPS JSON-RPC): `{"jsonrpc":"2.0","method":"inputSourceControl","params":{"AccessToken":"…","inputSource":"HDMI1"}}`. Requires Network → Expert Settings → IP Remote on the TV; availability on BU8000 unverified — probe TCP 1516 at connect. If unavailable, hide specific-input tabs and offer only KEY_SOURCE (opens the TV's own source picker).
   - Android TV / Haier: No standard input-list API over ATVRS v2 — hide the tabs or offer HDMI switching via keycodes (KEYCODE_TV_INPUT_HDMI_1 = 243, etc.).
   - webOS: `ssap://tv/getExternalInputList` returns input list.

2. **`remote_pad.dart`** — Read `caps.inputList`; if empty, hide the source bar entirely. If populated, render one tab per input using its real label and ID.

3. **`remote_controller.dart:922`** — Pass `input.id` (the protocol-specific identifier), not the display label.

4. **Reset `currentSource`** on device change.

**Verify:** Connect to BRAVIA → see real inputs (HDMI 1, HDMI 2, Composite, etc.). Connect to Haier → source bar hidden (or shows generic HDMI keys).

---

### U2 · App-launch buttons ungated; raw error string "app launch not implemented for tizen yet"

| Field | Value |
|---|---|
| **Evidence** | ✅ User saw raw error on Samsung; 📄 `tizen_adapter.dart:145-146`, `remote_controller.dart:943-944` |
| **Affects** | Samsung (TizenAdapter), any adapter where appLaunch is false |
| **Root cause** | App buttons (Netflix, YouTube, Prime, Disney+) are unconditional in `remote_pad.dart:255-263`. No check for `caps.appLaunch`. Tizen returns a raw failure string. The controller at RC:943-944 sets `lastCommandError = result.error` bypassing `_humanCommandError` → the raw string appears in the UI. The error is sticky (never increments `_consecutiveFailures`, so the "clear on success" path at RC:878-881 doesn't trigger). |

**Fix path:**

1. **Gate buttons** — In `remote_pad.dart`, wrap each app button in:
   ```dart
   if (c.caps.appLaunch) AppButton(…)
   ```
   When `appLaunch` is false, show a disabled state or hide the row.

2. **Human error** — In `remote_controller.dart:943-944`, route through `_humanCommandError`:
   ```dart
   lastCommandError = _humanCommandError(result.error);
   ```
   Add mapping: `'app launch not implemented…'` → "App launching isn't available for this TV yet."

3. **Fix sticky error** — Increment `_consecutiveFailures` in the launch failure path so the next success clears the banner.

4. **Samsung app launch** — Implement `TizenAdapter.launchApp`:
   - Primary: `{"method":"ms.channel.emit","params":{"event":"ed.apps.launch","to":"host","data":{"action_type":"DEEP_LINK","appId":"<id>","metaTag":""}}}`. Reply: `{"data":200,"event":"ed.apps.launch","from":"host"}`.
   - Fallback for 2020+ sets (ed.apps.launch may not work): `{"id":"<appId>","method":"ms.application.start","params":{"id":"<appId>"}}`.
   - REST fallback: `POST http://tv:8001/api/v2/applications/<appId>` (works on 2021+ sets).
   - **Verified app IDs:**
     - Netflix: `11101200001` or `3201907018807` (DEEP_LINK, NATIVE_LAUNCH fails)
     - YouTube: `111299001912` (DEEP_LINK)
     - Prime Video: `3201512006785` or `3201910019365` (DEEP_LINK inferred)
     - Disney+: `3201901017640` or `3202204027038` (DEEP_LINK inferred)
   - `ed.installedApp.get` returns the app list but is unanswered on ~2020+ sets. Try it; if no response in 5 s, use the hardcoded ID table.
   - Set `caps.appLaunch = true` for Tizen once implemented.

**Verify:** Connect to Samsung with appLaunch implemented → Netflix button launches Netflix. Connect to DLNA → app buttons hidden.

---

### U3 · Wake: "Yes" in settings but no WoL packet is ever sent

| Field | Value |
|---|---|
| **Evidence** | 📄 `common/wol.dart` (bytes only); `native/stub_bridge.dart:43-45` (empty sendMagicPacket); 8 adapters declare `wake: true` |
| **Affects** | All TVs |
| **Root cause** | `WolPacket` only builds the magic packet bytes but has no send method. `WolBridge.sendMagicPacket` has one implementation (`StubWolBridge`) with an empty body. Neither is ever instantiated. No MAC address is stored anywhere. Yet `wake: true` is declared by every adapter except DLNA, and Settings shows "Wake: Yes". |

**Fix path:**

1. **Store MAC** — During discovery, read MAC from:
   - SSDP `USN` or ARP table (`ip neigh show` on Android).
   - Samsung device-info API (`GET :8001/api/v2/` → `wifiMac`).
   - Android TV TXT record or connection metadata.
   - Manual entry in the device-edit screen.

2. **Implement WolBridge** — Replace `StubWolBridge` with a real implementation that sends UDP broadcast on port 9 with the magic packet bytes. Use `RawDatagramSocket` in Dart.

3. **Wire into power** — In `remote_controller.dart:912-917`, when `power(on: true)` and the adapter supports wake:
   ```dart
   if (on && !isConnected && device.mac != null) {
     await wolBridge.sendMagicPacket(device.mac!);
     await Future.delayed(Duration(seconds: 5));
     await _connectToDevice(device);
   }
   ```

4. **Set `wake: false`** for adapters where WoL isn't implemented yet (DLNA, AirPlay, Roku, Vizio).

5. **Settings UI** — Show "Wake: Yes (WoL)" only when MAC is stored; otherwise "Wake: Not configured — add MAC address".

**Verify:** Power off Samsung → press Power in app → TV turns on. (Requires WoL enabled in TV settings and MAC stored.)

---

### U4 · AUTO-DETECTED badge based on hardcoded strings, not real detection

| Field | Value |
|---|---|
| **Evidence** | 📄 `remote_controller.dart:194-253`, `settings_screen.dart:525-526` |
| **Affects** | All TVs |
| **Root cause** | `detectedFeatures` in the controller builds capability descriptions from hardcoded `tizen`/`webos`/`roku`/`dlna` literal maps — these are the *same* static strings as the adapter's static `capabilities()`. The "AUTO-DETECTED" badge in Settings appears when `detected.isNotEmpty` (SET:525) — but nothing was actually detected at runtime; it's just the static capability declaration rephrased. |

**Fix path:**

1. **Real detection** — After connect, query the adapter for actually-verified capabilities:
   ```dart
   final verified = await adapter.verifyCapabilities();
   // e.g., try a volume query → volumeReadback confirmed
   // try a power query → stateReadback confirmed
   ```

2. **Replace `detectedFeatures`** — Build the settings rows from `adapter.capabilities()` (which already reflects negotiated features for ATV) plus the verification result. Label unverified capabilities as "Declared" and verified ones as "Confirmed".

3. **Remove hardcoded maps** at RC:218-241.

**Verify:** Connect to Haier → Settings shows "D-pad: Confirmed" (key send succeeded), "Volume Readback: Not confirmed" (field 50 not parsed yet).

---

### U5 · Optimistic mute/power; ATV volume push (field 50) unused

| Field | Value |
|---|---|
| **Evidence** | 📄 `remote_controller.dart:855-863` (mute), `:912-917` (power); `live_atv_channel.dart` ignores field 50 |
| **Affects** | All TVs (mute/power), Android TVs (volume) |
| **Root cause** | Mute toggles `isMuted` optimistically before sending; if the command fails, the icon is wrong. Power toggles `isPoweredOn` the same way. For Android TV, the TV pushes `RemoteSetVolumeLevel` (field 50) with real volume/mute state, but the channel ignores fields 50 entirely → this free state data is wasted. BRAVIA *does* poll volume via Simple IP, but the state isn't unified in the controller. |

**Fix path:**

1. **Parse field 50** — In `live_atv_channel.dart` or `AtvImeSession`, add a handler for field 50:
   ```dart
   case 50: 
     final vol = msg[7];  // volume_level
     final muted = msg[8]; // volume_muted
     emit StateDelta(volume: vol, muted: muted);
   ```

2. **State stream** — Add a `Stream<StateDelta>` to the `ControlAdapter` contract. Feed it from field 50 (ATV), Simple IP polling (BRAVIA), and Samsung events.

3. **Controller subscribes** — At connect, subscribe to the state stream. Update `isMuted`, `volume`, `isPoweredOn` from real TV state instead of optimistic toggles.

4. **Keep optimistic as fallback** — For adapters without state readback (Tizen until ms.channel.emit is wired, webOS until ssap://audio/getVolume), keep the optimistic toggle but add a TODO marker.

**Verify:** Connect to Haier → press Volume Up on the physical remote → app's volume indicator updates.

---

### U6 · Dead or misleading controls

| Field | Value |
|---|---|
| **Evidence** | 📄 See audit_notes_ui.md for full list |
| **Affects** | All screens |

**Summary of dead controls and fix for each:**

| Control | Location | Issue | Fix |
|---|---|---|---|
| Settings tiles (IR Hardware, Codeset Wizard) | `settings_screen.dart:53-65,736-764` | `_settingTile` has no tap handler, chevrons mislead | Add handlers or remove chevrons; mark as "Coming Soon" if planned |
| Mic icon | `tv_keyboard_sheet.dart:213` | No handler | Hide until voice-to-TV is implemented |
| `keyboard_hide` icon | `tv_keyboard_sheet.dart:110-114` | No handler | Wire to `Navigator.pop` or equivalent sheet dismiss |
| "Live Mirrored" pill | `tv_keyboard_sheet.dart:164-188` | Static, shows while disconnected | Bind to `c.isMirroring` |
| "Remote" chip on devices | `devices_screen.dart:425-442` | Plain Container, no tap action | Make it `c.selectDevice(d)` on tap |
| Two "Mirror Screen" buttons | `cast_screen.dart:751,803` | Low Latency one needs launchApp → fails on Tizen | Gate by `caps.appLaunch`; merge to one button with a quality picker |
| AP-isolation copy | `devices_screen.dart:650-660` | `gatewayReachable` never set (RC:70-72 doesn't enable it) | Wire up gateway reachability check or remove the copy |
| `scanError` label | `remote_controller.dart:308` | Set but never shown | Show in devices screen when `scanError != null` |
| Privacy/Offline Mode/version rows | `settings_screen.dart:68-79` | Static text, no action | Wire Privacy to a privacy-policy screen; Offline Mode to a toggle; version to package info |
| "TV CURS…" truncation | `tv_keyboard_sheet.dart:218-234` | `Flexible + Spacer` both flex=1 → text truncated | Remove `Spacer` or give text `flex: 2` |

**Verify:** Tap each control → something happens or it's clearly marked unavailable.

---

### U7 · Raw error strings reaching the user

| Field | Value |
|---|---|
| **Evidence** | 📄 See audit_notes_ui.md §Raw errors and audit_notes_cast_mirror.md §Q9 |
| **Affects** | All screens |

**Affected locations and human-readable replacements:**

| Location | Raw string | Human replacement |
|---|---|---|
| RC:943-944 | `"app launch not implemented for tizen yet"` | "App launching isn't available for this TV" |
| RC:1235 | `"Casting failed. Check that the TV is on the same network. ($e)"` | "Couldn't reach the TV for casting. Make sure your phone and TV are on the same WiFi network." |
| RC:1228 | `"AirPlay rejected playback (HTTP n)"`, `"AirPlay error: $e"` | "The TV couldn't play this file." |
| RC:1352, 1583 | `"Screen mirroring failed. ($e)"` | "Screen mirroring couldn't start." |
| RC:770 | `"Paired but could not open the keyboard channel: $e"` | "Paired successfully, but the keyboard channel didn't connect. Try reconnecting." |
| RC:735 | `"Pairing failed: $e"` | "Pairing didn't complete. Make sure the code matches and try again." |
| RC:214 | `"Raw Bitmask: $features"` | Replace with human-readable feature list |
| RC:903 | Generic catch-all including "not supported on this TV" → "Commands are not reaching the TV" | Differentiate: "not supported" → "This feature isn't available on this TV" |
| RC:1293-1296 | Every mirror start failure → "Screen capture permission was denied." | Check actual error; "permission denied" only for actual denial |
| GCA:209-211 | Cast receiver reason codes (INVALID_COMMAND etc.) | "The TV couldn't process the cast request." |
| DLNA:300 | Raw SOAP fault string | "This TV's media player reported an error." |

**Fix path:** Create a `human_errors.dart` utility with a single `humanize(String raw) → String` function. Route all user-facing error assignments through it. Add the PRD rule as a lint check.

**Verify:** Trigger each error → user sees plain English, no stack traces or HTTP codes.

---

### U8 · Accessibility: tap targets < 48dp, no Semantics

| Field | Value |
|---|---|
| **Evidence** | 📄 See audit_notes_ui.md §Accessibility |
| **Affects** | Entire app |
| **Root cause** | Many interactive elements are under 48×48dp minimum: power/mute 44×44, d-pad arrows 56×46, Back/Home/app buttons 40 high, keyboard keys 38 high, cursor keys 28×24, settings back arrow 24×24. No `Semantics` or `Tooltip` widgets anywhere. |

**Fix path:**

1. **Minimum tap targets** — Wrap undersized buttons in `SizedBox(width: 48, height: 48)` or use `MaterialButton.minimumSize`. The visual icon can stay smaller inside the hit area.
2. **Semantics** — Add `Semantics(label: '…', button: true)` to every interactive element.
3. **Tooltip** — Add `Tooltip(message: '…')` to icon buttons.

**Verify:** Run Flutter accessibility scanner (`flutter test --accessibility`). All tap targets ≥ 48dp, all buttons have labels.

---

### B32 · No per-press feedback — static "SENT TO TV" label

| Field | Value |
|---|---|
| **Evidence** | 📄 `remote_screen.dart` — static label, errors only after 2 failures |
| **Affects** | All TVs |
| **Root cause** | The status bar shows "SENT TO TV / press any control" as a static string. Individual key presses get no per-press feedback. The error banner only appears after `_consecutiveFailures >= 2`. A single failed command is invisible. |

**Fix path:**

1. **Per-press feedback** — On each `key()` / `type()` call, briefly flash a micro-animation (e.g., the button ripples or the status bar pulses green for 200 ms).
2. **Instant error on first failure** — Show a temporary amber indicator on the first failure (not the full error banner, just a subtle "missed" signal). Promote to the full banner on the second.
3. **Success indicator** — When a TV with state readback confirms the action (e.g., volume changed), show the confirmed state.

**Verify:** Press Volume Up → button pulses green. Disconnect TV, press Volume Up → button shows amber warning immediately.

---

## Tier 4 — Discovery

---

### D1 · Google Home Mini listed as ANDROIDTV and offered pairing

| Field | Value |
|---|---|
| **Evidence** | ✅ "M15 - OTHER" on three IPs + "Living Room TV" classified OTHER |
| **Root cause** | `endpoint_classifier.dart:65-71`: `_googlecast` → `BrandFamily.androidTv` + `adapterId: 'cast'` + `deviceType: tv`. A Google Home Mini advertises `_googlecast._tcp` and gets classified as a TV. When tapped in the device list, it takes the `default → AndroidTvAdapter` path at RC:521-530 and attempts TLS 6466 → fails → but `needsAtvrsPairing` (RC:599) is true because the adapter object exists → user sees "Pair to control this TV / A code will appear on the TV screen." |

**Fix path:**

1. **Use Cast TXT `ca` bitmask** — In mDNS backend, do a TXT lookup for `_googlecast._tcp` records. Parse `ca` decimal:
   - If bit 1 (video-out) is clear → `DeviceType.speaker` (audio-only).
   - If `md` matches known audio devices ("Google Home", "Nest Mini", "Nest Audio") → `DeviceType.speaker`.

2. **Use separate service type** — `_androidtvremote2._tcp` is the correct indicator of an Android TV. `_googlecast._tcp` alone does NOT imply Android TV. Classify `_googlecast` without `_androidtvremote2` as a Cast target, not an Android TV.

3. **`endpoint_classifier.dart`** — Add `DeviceType.speaker` / `DeviceType.castTarget` classification. Don't offer pairing for cast-only/speaker devices.

4. **`devices_screen.dart`** — For `DeviceType.speaker`, show a speaker icon and "Cast audio only" badge. Don't show "Pair to control this TV".

**Verify:** Scan network with Google Home Mini present → it appears as "Living Room - Speaker" with no pair prompt. Tapping it shows "Cast audio" option, not a remote control.

---

### D2 · Device name/brand flips between scans

| Field | Value |
|---|---|
| **Evidence** | ✅ Haier appears as "Mediatek_MTXXXX" / "Bedroom TV" / "2K-NSTV" across scans |
| **Root cause** | (a) `device_registry.dart:51` — `friendlyName` uses latest-endpoint-wins, so whichever discovery backend (SSDP or mDNS) reports last sets the name. (b) mDNS uses instance name (e.g., "Mediatek_MTXXXX"), SSDP uses UPnP friendlyName (e.g., "Bedroom TV"), and Cast TXT uses `fn` (e.g., "2K-NSTV"). (c) `device_registry.dart:49` — `type` also uses latest-wins. |

**Fix path:**

1. **Priority merge** — In `device_registry.dart`, assign priority to name sources:
   ```
   Cast TXT fn > UPnP friendlyName > mDNS instance name > IP address
   ```
   Only overwrite with a higher-priority source.

2. **Stable identity** — Use a composite key (IP + MAC or IP + UUID from Cast `id` or SSDP `USN`) for dedup instead of IP alone. This prevents the same device from appearing as multiple entries.

3. **User-editable name** — Store a user-set custom name in the device profile (persisted to disk). Once set, it overrides all discovery names.

**Verify:** Scan 5 times → Haier name stays consistent ("Bedroom TV" or whatever the user chose). No duplicate entries.

---

### D3 · DLNA probe: fixed ports, ignores SSDP location, control URLs guessed

| Field | Value |
|---|---|
| **Evidence** | 📄 `upnp_probe.dart:93-100`, `remote_controller.dart:567-588` |
| **Root cause** | `probeHost` tries 6 hardcoded port/path combos (52323, 8008, 49152, 1900, 8443, 60606) sequentially with 5 s timeout each → up to 30 s to fail. It ignores the SSDP `LOCATION` header which already tells us the exact description URL. `_createDlnaFromLocation` (RC:567-577) then *guesses* control URLs (`upnp/control/AVTransport`) from the location path instead of parsing the XML description document. Samsung's DLNA renderer is on port 9197 — not in the list. |

**Fix path:**

1. **Use SSDP LOCATION** — `ssdp_backend.dart` already fetches the UPnP description XML and caches it. Parse the `<controlURL>` for `AVTransport` from the actual XML instead of guessing.

2. **`upnp_probe.dart`** — Rewrite `probeHost` to accept an optional `locationUrl` parameter. When provided, fetch and parse it directly. Only fall back to port scanning when no SSDP location is available (e.g., manual IP entry).

3. **Add Samsung :9197** — In the fallback port list, add `9197/dmr` (description URL) and `9197/upnp/control/AVTransport1` + `RenderingControl1`. **Confirmed: Samsung Tizen renderer at `http://tv:9197/dmr`** (openHAB, CY AU8000). 2014-era sets use port 7676 with opaque paths — handle via SSDP LOCATION.

4. **Parallel probes** — Use `Future.wait` with individual timeouts instead of sequential attempts.

**Verify:** Connect to BRAVIA → DLNA probe completes in < 2 s (from SSDP location). Manual IP of Samsung → tries :9197 among others.

---

### D4 · DIAL availability is order-dependent (SSDP description cache)

| Field | Value |
|---|---|
| **Evidence** | 📄 `ssdp_backend.dart:78-80` |
| **Root cause** | UPnP description is cached per HOST — first LOCATION wins. If the `ssdp:all` response arrives before the DIAL-specific one, the cached description may not include the `Application-URL` header. Subsequent DIAL checks read from cache → DIAL appears unavailable. |

**Fix path:**

1. **Per-LOCATION cache** — Key the cache on the full LOCATION URL, not just the host.
2. **Merge headers** — When a second response for the same host arrives with an `Application-URL` header, merge it into the existing entry.

**Verify:** Run 10 scans → DIAL availability is consistent for BRAVIA (always found or always not found, not flickering).

---

### D5 · reusePort error logged on Android (harmless but noisy)

| Field | Value |
|---|---|
| **Evidence** | 📄 `mdns_backend.dart:23-47`; 🔍 Dart runtime logs but doesn't throw |
| **Root cause** | `_crossPlatformBind` tries `reusePort: true` first. On Android, the Dart runtime logs `"Dart Socket ERROR: … reusePort not supported on this platform."` to stderr but continues — no exception. The log appears on every scan. |

**Fix path:**

1. **Platform check** — In `_crossPlatformBind`, check `Platform.isAndroid || Platform.isWindows` and set `reusePort: false` for those platforms. Keep `reusePort: true` for iOS/macOS where it's needed.

**Verify:** Run scan on Android → no "reusePort" error in logcat.

---

### D6 · mDNS: hardcoded types, no TXT, time budget consumed by slow lookups

| Field | Value |
|---|---|
| **Evidence** | 📄 `mdns_backend.dart:55-59,98-119` |
| **Root cause** | (a) Only 3 service types hardcoded; adapters' `discoveryHints` (which declare what services they need) are never consumed. (b) No TXT record lookup → Cast `fn`/`ca`/`md` and ATV remote features are missed. (c) SRV lookup uses `await for` without `break` → if a service returns many SRV records, it blocks until the lookup timeout, consuming the shared deadline for other service types. |

**Fix path:**

1. **Read discoveryHints** — At engine startup, collect `discoveryHints` from all registered adapters. Union them with the hardcoded list to build the service-type set.
2. **TXT lookup** — After PTR → SRV, do a TXT lookup for each discovered instance. Parse known keys (`fn`, `ca`, `md`, `id`, `st` for Cast; service-specific keys for ATV remote).
3. **Break after first SRV** — In the SRV `await for` loop (lines 98-119), `break` after the first result (each PTR record should have one SRV).
4. **Per-type timeout** — Give each service type its own `Future.timeout(5.seconds)` instead of sharing one deadline.

**Verify:** Scan finds Cast `fn` names for Chromecast devices; ATV remote instances for Android TVs. Total scan time < 8 s.

---

### D7 · Scan bookkeeping: failed-race, AP isolation dead, manual devices wiped, ProbeBackend unused

| Field | Value |
|---|---|
| **Evidence** | 📄 `discovery_engine.dart:78-100,53`; `remote_controller.dart:70-72` |
| **Root cause** | (a) `discovery_engine.dart:78-100`: a backend that completes normally races the deadline timer → counted as "failed" in the `on Object` catch. (b) `registry.clear()` at line 53 wipes all entries each scan — including manually added IPs. (c) `ProbeBackend` (HTTP-based backup discovery) is registered in tests but never in the app. (d) AP isolation detection is never enabled (RC:70-72 doesn't set `gatewayReachable`). |

**Fix path:**

1. **Fix race** — Use `Future.any` or handle `TimeoutException` specifically; a clean completion is not a failure.
2. **Preserve manual entries** — Before `registry.clear()`, save entries where `source == 'manual'`; re-add them after scan.
3. **Wire ProbeBackend** — Add it to the backends list at RC:69-72 as a final fallback.
4. **AP isolation check** — At scan start, try to reach the default gateway (`192.168.1.1` or from `NetworkInterface.list`). Set `gatewayReachable` accordingly → show the AP-isolation help copy in Devices when unreachable.

**Verify:** Add manual IP → scan → manual device persists. Backend that finishes before deadline → not marked failed.

---

### D8 · Control badges for unsupported brands; substring false positives

| Field | Value |
|---|---|
| **Evidence** | 📄 `endpoint_classifier.dart:107-200` |
| **Root cause** | (a) Panasonic, Philips, Hisense get "control" badges in the classifier despite having no adapter implementation. (b) Brand matching is substring-based on the haystack that includes `friendlyName` → a Philips Hue bridge named "Philips Hue" matches the 'philips' TV brand → gets classified as a Philips TV. |

**Fix path:**

1. **Remove badges for unimplemented brands** — Panasonic, Philips, Hisense should get `CapabilityBadge.none` or `CapabilityBadge.discovery_only` until their adapters exist.
2. **Tighten substring match** — Match on the UPnP `manufacturer` field (not `friendlyName`) for brand detection. Or use a blocklist for known non-TV devices ("Hue", "Printer", "SoundBar").
3. **Manual IP → classifier** — A manually added IP currently falls through to `default → AndroidTvAdapter`. Instead, run `probeProtocols` on it first and pick the right adapter from probe results.

**Verify:** Philips Hue bridge on the network → not classified as a Philips TV. Manual IP of Samsung → gets TizenAdapter.

---

## Tier 5 — Cast & Mirror

---

### M1 · Cast success criterion wrong; timeout kills media server; retry skips launch

| Field | Value |
|---|---|
| **Evidence** | ✅ "Cast doesn't work on 1st time then when I retry it gives Pause/Stop button but TV turns black" |
| **Root cause** | (a) `google_cast_adapter.dart:194`: success = first `MEDIA_STATUS` of any kind → includes `IDLE` and error states. `playerState` and `idleReason` never checked. (b) 15 s LOAD timeout (GCA:188) → kills media server (RC:1225) while the receiver may still be starting. (c) Retry skips `_launchReceiver` because `_transportId` still set from first attempt → sends LOAD into a potentially stale session. (d) No `MEDIA_STATUS` listener after initial LOAD → UI stays "Now Playing" even after playback ends. (e) `castStop` doesn't close the receiver app → Default Media Receiver stays on screen. |

**Fix path:**

1. **Check playerState** — In the LOAD wait loop:
   ```dart
   if (type == MEDIA_STATUS) {
     final state = status['playerState'];
     if (state == 'PLAYING' || state == 'BUFFERING') return success;
     if (state == 'IDLE' && status['idleReason'] == 'ERROR') return failure;
   }
   ```

2. **Don't kill media server on timeout** — Instead, keep it alive for 60 s (or until the user cancels). Show "TV is loading…" in the UI.

3. **Full retry** — On retry, always call `_launchReceiver` (reset `_transportId` first).

4. **Ongoing listener** — After successful LOAD, keep listening to `MEDIA_STATUS`. On `IDLE/FINISHED`, update UI to "Playback ended". On `IDLE/ERROR`, show error.

5. **Clean stop** — In `castStop`, send `STOP` to both the media namespace and the receiver namespace, then close.

6. **DLNA/AirPlay fallback** — If Cast LOAD fails after 2 attempts, try DLNA (if available), then AirPlay.

**Verify:** Cast a photo → TV shows the photo, UI shows "Playing". Stop → TV returns to home screen. First-attempt timeout → UI says "Still loading", not "Failed".

---

### M2 · Mirroring: stale segments, BRAVIA URL never sent, playlist timing wrong, thread safety

| Field | Value |
|---|---|
| **Evidence** | ✅ "live for few seconds then started buffering" (was actually Miracast); 📄 Code analysis in audit_notes_cast_mirror.md |
| **Affects** | All TVs (HLS path), BRAVIA specifically (Cast+HLS) |

**Multiple sub-issues:**

**(a) Stale segments** — `segmentIndex = 0` on every start (SMS:140); nothing deleted on stop; `_listSegments` takes every `seg_*.ts` sorted by name → 2nd session's "last 6" are the previous session's files.  
**Fix:** Delete all `seg_*.ts` in the HLS directory on `startEncoding` before setting `segmentIndex = 0`.

**(b) BRAVIA URL never sent** — `SimpleIpAdapter.launchApp` uses only the app name for DIAL POST; `appDeepLink(name)` returns null for "Screen Mirror" → the receiver URL (which carries the WebSocket endpoint) never reaches the TV.  
**Fix:** In `SimpleIpAdapter.launchApp`, when `app.id` is a URL (starts with `http`), pass it as the DIAL POST body or as a query parameter to the Cast receiver.

**(c) Playlist timing** — `EXT-X-TARGETDURATION:1` and `EXTINF:1.000` are hardcoded, but segment duration depends on keyframe interval (KEY_I_FRAME_INTERVAL=1 second, but actual I-frames depend on scene changes).  
**Fix:** Track actual segment duration from PTS timestamps; write real `EXTINF` values. Set `TARGETDURATION` to `ceil(maxSegmentDuration)`.

**(d) TsMuxer thread safety** — Video thread (SMS:367) and audio thread (SMS:292) share `out` and `cc` counters during segment rotation.  
**Fix:** Guard segment rotation with a mutex (`synchronized` in Kotlin, or `ReentrantLock`). Or: only the video thread rotates; audio thread writes to current segment.

**(e) JMuxer mode:both requires audio** — `mode: 'both'` means JMuxer won't render until it gets both video AND audio samples. With video-only capture (no `RECORD_AUDIO` permission), nothing renders.  
**Fix:** Use `mode: 'video'` when audio isn't available. Detect audio availability before setting up JMuxer.

**Verify:** Start mirror twice → second session shows live content immediately (no stale frames). Mirror on BRAVIA → TV loads the receiver page.

---

### M3 · Mirror: no start confirmation, no re-entrancy guard

| Field | Value |
|---|---|
| **Evidence** | 📄 `remote_controller.dart:1333-1335`, `ScreenMirrorService.kt:74-136` |
| **Root cause** | (a) `isMirroring = true` is set when `launchApp` returns ok (RC:1333) — no confirmation that the TV actually loaded the receiver or that the WebSocket connected. (b) Mirror button is tappable during startup → second tap reuses the projection token, starts a second encoder, registers the receiver twice. |

**Fix path:**

1. **Start confirmation** — After setting up the mirror, wait for the first WebSocket client to connect (expose `clientCount` from WS server over MethodChannel). Only set `isMirroring = true` when `clientCount > 0`.
2. **Re-entrancy guard** — Add a `_mirrorStarting` flag. While true, the Mirror button shows a spinner and ignores taps. Clear on success or failure.
3. **Timeout** — If no client connects within 30 s, stop the service and show "TV didn't connect. Check that the TV loaded the mirror page."

**Verify:** Tap Mirror → button shows spinner → TV connects → button shows "Stop". Tap twice rapidly → only one session starts.

---

### M4 · No DRM messaging for screen capture

| Field | Value |
|---|---|
| **Evidence** | 📄 No `FLAG_SECURE` detection; notification says "Your screen is being cast to TV" |
| **Affects** | Users trying to mirror Netflix, Prime Video, etc. |
| **Root cause** | Apps that set `FLAG_SECURE` or disallow playback capture produce black frames. No detection, no user message. |

**Fix path:**

1. **Detect black frames** — In the encoder drain loop, after N consecutive identical (black) frames, trigger a warning.
2. **User message** — Show: "This app blocks screen recording (DRM protection). You can launch it directly on the TV using the app buttons instead."
3. **Netflix card** — The Cast tab already has a Netflix card (CS:520) that launches on TV. Add similar cards for Prime Video, Disney+, and a generic "Launch on TV" option.

**Verify:** Start mirror, open Netflix → within 5 s, see DRM warning. Tap "Launch on TV" → Netflix opens on the TV.

---

### M5 · AirPlay caster false positives; no real reachability test

| Field | Value |
|---|---|
| **Evidence** | 📄 `airplay_caster.dart:50,53,74,122` |
| **Root cause** | `isReachable = GET /server-info → 200` — but many devices respond to `/server-info` without supporting AirPlay playback (e.g., HomePod reports server-info but `/play` fails). Also, the caster uses plaintext AirPlay-1 `/play` which doesn't work on AirPlay 2 devices. |

**Fix path:**

1. **Better reachability** — After `/server-info`, check the `features` bitmask in the response. AirPlay 2 devices report features that indicate whether they support video playback.
2. **Don't offer AirPlay for confirmed non-video devices** — If `features` doesn't include video playback, don't list it as a cast target.
3. **Error handling** — Replace raw strings with human errors (see U7).

**Verify:** AirPlay-only audio device on network → not offered as a video cast target.

---

### M6 · Mirror endpoints have no authentication — anyone on LAN can watch

| Field | Value |
|---|---|
| **Evidence** | 📄 `live_stream_server.dart:57-63` (HLS), `MirrorWsServer.kt` (WebSocket) |
| **Affects** | All mirror sessions |
| **Root cause** | The HLS `/receiver` page, `/live/*` segments, and the WebSocket port carry no token. Anyone on the LAN can navigate to `http://phone-ip:port/receiver` and watch the screen. The `MediaServer` for casting *does* use a 24-char random token, but the mirror server doesn't. |

**Fix path:**

1. **Generate a session token** — At mirror start, generate a random token (same pattern as `MediaServer`).
2. **Require token** — All mirror endpoints (receiver page, playlist, segments, WebSocket) must include the token as a path segment or query parameter. Reject requests without it.
3. **Pass token to receiver** — The receiver URL sent to the TV includes the token. Only the TV (which was sent the URL) can connect.

**Verify:** Start mirror → navigate to `http://phone-ip:port/receiver` without token → 403. With token → stream works.

---

### M7 · MediaServer Range handling bugs

| Field | Value |
|---|---|
| **Evidence** | 📄 `media_server.dart:93-99`, `live_stream_server.dart:160-172` |
| **Root cause** | (a) `if (start >= length || end >= length || start > end) → 416` — but HTTP Range spec says `end` past EOF should be clamped to `length - 1`, not rejected. A request `bytes=0-1048575` on a 500 KB file fails with 416 instead of returning the whole file. (b) Suffix ranges (`bytes=-500`) and multi-range make `int.parse` throw → 500. Same logic duplicated in LSS:160-172. |

**Fix path:**

1. **Clamp end** — `end = min(end, length - 1)`.
2. **Handle suffix** — Parse `bytes=-N` as `start = max(0, length - N), end = length - 1`.
3. **Reject multi-range** — Return 200 with full content (don't try to parse).
4. **DRY** — Extract range parsing into a shared utility used by both `MediaServer` and `LiveStreamServer`.

**Verify:** Cast a 500 KB image → receiver requests `bytes=0-1048575` → 206 with full file. `bytes=-100` → last 100 bytes.

---

## Tier 6 — Security & Privacy

---

### S1 · Unused private key in source code

| Field | Value |
|---|---|
| **Evidence** | 📄 `remote_controller.dart:1641-1690` |
| **Root cause** | `_atvrsClientCert` and `_atvrsClientKey` are hardcoded PEM strings. They're unused (per-install cert generation replaced them), but they're still in the source. If this were a real private key, it would be a secret leak. |

**Fix path:**

1. Delete lines 1641-1690 entirely.
2. Add to `.gitignore`: `*.pem`, `*.key` (prevent accidental commits of generated keys).

**Verify:** Grep for `_atvrsClientCert` → zero results.

---

### S2 · Plaintext PEM key files — need Keystore-backed vault

| Field | Value |
|---|---|
| **Evidence** | 📄 `remote_controller.dart:96-118`; `StubKeystoreBridge` is in-memory only |
| **Root cause** | Per-install ATVRS client cert and private key are stored as plain `.pem` files in the app-support directory. The PRD requires "Pairing secrets in hardware-backed stores (Keystore/Keychain)". `StubKeystoreBridge` exists but is an in-memory `Map` — not persisted, not hardware-backed. |

**Fix path:**

1. **Android Keystore** — Replace file-based storage with `flutter_secure_storage` (or native `KeyStore` via MethodChannel):
   - Generate the RSA key pair inside the Android Keystore (key never leaves hardware).
   - Store the cert as a Keystore entry.
   - On connect, load cert from Keystore for TLS client auth.

2. **Samsung token** — Once C1 is implemented, store the Samsung token in the same vault.

3. **Migration** — On first launch after the update, read existing `.pem` files, import into Keystore, delete the `.pem` files.

4. **iOS** — Use Keychain for the same purpose.

**Verify:** Check app-support directory → no `.pem` files. Key operations still work (connect, pair).

---

### S3 · Accept-all TLS at 5 sites — need TOFU pinning

| Field | Value |
|---|---|
| **Evidence** | 📄 `google_cast_adapter.dart:56,:369`; `bravia_atvrs.dart:421`; `live_ws_channel.dart:62`; `live_atv_channel.dart:95` |
| **Affects** | All protocols using TLS |
| **Root cause** | Every TLS connection uses `onBadCertificate: (_) => true` — accepting any certificate, including MITM. TVs use self-signed certs (they have no CA chain), so the app can't verify against a trusted CA. But it should use Trust-On-First-Use (TOFU) pinning. |

**Fix path:**

1. **TOFU store** — Create a `TofuCertStore` class that:
   - On first connection to a host, saves the SHA-256 hash of the server cert's DER encoding.
   - On subsequent connections, compares the cert hash. If it differs, reject (possible MITM) and show: "This TV's security certificate changed. This could mean someone is intercepting your connection. Re-pair to accept the new certificate."

2. **`onBadCertificate` callback** — Replace `=> true` with:
   ```dart
   (cert) {
     final hash = sha256.convert(cert.der).toString();
     if (tofuStore.isKnown(host)) return tofuStore.matches(host, hash);
     tofuStore.save(host, hash);
     return true;
   }
   ```

3. **Apply to all 5 sites** — Each file gets the same pattern; import from a shared utility.

4. **X509Certificate.der** — Dart's `X509Certificate` exposes `der` bytes. Hash with `crypto` package's `sha256`.

**Verify:** Connect to Samsung → cert hash saved. Reconnect → accepted (same cert). Simulate cert change → rejected with user message.

---

### S4 · Debug logging leaks sensitive data

| Field | Value |
|---|---|
| **Evidence** | 📄 91 logging call sites across 5 files (~~92 across 6 originally reported~~) |
| **Root cause** | Overlaps with K7. Full summary: `live_atv_channel.dart` has targeted `_log` calls that may include IME field payloads (typed text), `bravia_atvrs.dart` logs cert bytes and handshake details, `live_ws_channel.dart:40` logs the full URL (will include tokens), `remote_controller.dart` logs key names. |

**Fix path:** Same as K7. Additionally:
1. **Release build** — Ensure all `print`/`debugPrint`/`dev.log` calls are stripped or gated in release mode.
2. **CI check** — Add a lint rule or CI grep that flags `print(` calls in `lib/` directories (excluding test).

**Verify:** Run release build → `adb logcat` shows zero SANKETA log lines.

---

### S5 · Generated cert is CA:TRUE, 10-year validity

| Field | Value |
|---|---|
| **Evidence** | 📄 `cert_generator.dart` |
| **Root cause** | The per-install client cert is generated with `cA=TRUE` in the basic constraints and a 10-year validity. A client cert should NOT be a CA cert (a CA cert can sign other certs). 10 years is excessive for a rotating client cert. |

**Fix path:**

1. **Remove CA flag** — Set `cA=FALSE` in the basic constraints extension.
2. **Shorter validity** — 1 year, with auto-renewal on expiry (regenerate + re-pair).
3. **Key usage** — Add `keyUsage: digitalSignature` (client auth), not `keyCertSign`.

**Verify:** Generate cert → `openssl x509 -text` shows `CA:FALSE`, `Validity: 1 year`, `Key Usage: Digital Signature`.

---

## Tier 7 — Build & Test

---

### ~~B33 · sanketa_adapters tests cannot compile: Flutter import in pure-Dart package~~ ALREADY FIXED

| Field | Value |
|---|---|
| **Evidence** | 📄 `sanketa_adapters/lib/src/cast/live_stream_server.dart` |
| **Affects** | All adapter tests |
| **Status** | **FIXED in current working tree** — the `package:flutter/foundation.dart` import has been removed. |

---

### ~~B34 · Android manifest: POST_NOTIFICATIONS missing~~ PARTIALLY FIXED

| Field | Value |
|---|---|
| **Evidence** | 📄 `AndroidManifest.xml:10` |
| **Affects** | Android 13+ mirroring |
| **Status** | **Declaration FIXED** — `POST_NOTIFICATIONS` is now declared in the manifest (verified at line 10). |

**Remaining gap:**
- **Runtime request** — On API 33+, the manifest declaration alone is not sufficient; the app must also request the permission at runtime before starting the mirror service. This runtime request is not yet implemented.
- **Version guard** — `NotificationChannel` and `startForegroundService` are API 26+ but used without version checks (minSdk is 24). Wrap in `if (Build.VERSION.SDK_INT >= 26)`.

**Verify:** On Android 13+ device, start mirror → notification permission prompt appears → notification shows. On API 24 device → no crash.

---

### B35 · Test coverage gaps

| Field | Value |
|---|---|
| **Evidence** | 📄 Multiple untested code paths |
| **Affects** | Confidence in all changes |

**Key gaps to address:**

1. **AtvImeSession** (new from K3/K4) — Unit tests: feed it field 20/22 messages, verify counter tracking and `buildImeBatchEdit` output matches androidtvremote2 format.
2. **TizenImeSession** (new from K2) — Unit tests: insert/delete/clear/submit sequences against `FakeWsChannel`.
3. **SessionManager** — Already has tests but isn't used. Wire it and add integration tests.
4. **Range parsing** — Unit tests for suffix ranges, multi-range, oversized ranges.
5. **TOFU cert store** — Unit tests for first-seen, match, mismatch.
6. **Endpoint classifier** — Test Google Home Mini (no video-out bit) → speaker classification.

**Verify:** `dart test` in each package → all pass. `flutter test` in sanketa_app → all pass.

---

## Previously Fixed Bugs

| ID | Date | Summary | Verified? |
|---|---|---|---|
| B01 | Sep 4 | UI blank body (bottom-nav covered content) | ✅ Yes |
| B02 | Sep 4 | Borders not centered (web build) | ❌ User never confirmed |
| B03 | Oct 3 | Demo leftovers (hardcoded text, dead buttons) | ❌ Not verified on device |
| B04 | Oct 10 | 19-item phone audit (Back exits, dead controls) | ✅ Yes |
| B05 | Oct 10 | Discovery not finding devices / Demo TV | ✅ Yes |
| B07 | Oct 10 | Caps keys typed lowercase | ✅ Yes |
| B08 | Oct 10 | BRAVIA nothing works (needed Simple IP) | ✅ Yes |
| B09 | Oct 10 | Cast tiles "Opening…" stub | ✅ Yes (via B19) |
| B11 | Oct 11 | BRAVIA pairing (proto, DER, field order) | ✅ Yes |
| B13 | Oct 11 | Default Flutter splash/icon | ❌ Not verified |
| B15 | Nov 4 | Cast stuck "Probing for DLNA", hash names | ✅ Yes |
| B19 | Nov 5 | Cast first-attempt failure / black screen | ✅ Partial (one photo) |
| B20 | Nov 5 | "Only Netflix worked" (DIAL + app-link) | ✅ Netflix/YouTube/Prime |
| B21 | Nov 5 | Connect once for everything | ✅ Yes |
| B28 | Nov 10 | Haier remote/pairing (classifier, handshake, cert) | ✅ Volume Up only |
| B30 | Nov 10 | Samsung connection (WebSocket.connect+customClient) | ✅ Yes |
| K1-S | Nov 10 | Samsung submit sent KEY_ENTER instead of SendInputEnd | 📄 Code verified (tizen_adapter.dart:137-138 sends _inputEndFrame) |
| K2 | Nov 10 | Samsung text: single-char sends, no backspace/clear | 📄 Code verified (TizenAdapter buffers in _imeText, handles all TextOp kinds) |
| K5 | Nov 10 | Sticky _gotError bricked ATV remote after RemoteError | 📄 Code verified (_gotError cleared in connect() at lines 79,87) |
| B33 | Nov 10 | Flutter import in pure-Dart sanketa_adapters package | 📄 Code verified (import removed from live_stream_server.dart) |
| B34 | Nov 10 | POST_NOTIFICATIONS missing from AndroidManifest.xml | 📄 Code verified (declared at AndroidManifest.xml:10; runtime request still needed on API 33+) |

---

## Untested / Unknown

| Item | Status |
|---|---|
| DLNA playback on any TV | Never proven (only "Optional Action Not Implemented" response) |
| AirPlay casting | Never reached a compatible device |
| Disney+ launch | Not installed on BRAVIA |
| BRAVIA typing & Enter after Nov 10 cert rewrite | Needs re-pair + retest |
| Haier: all keys except Volume Up | Untested |
| Samsung: app launch (IDs known, untested on BU8000), full keyboard session (protocol now known), token persistence (protocol now known), IP Control port 1516 | Protocol researched, needs on-device verification |
| IR emission | No IR blaster on test phone |
| webOS, Roku, Fire TV, Vizio | No hardware |
| Mirroring picture/audio on any TV | HLS picture after LIVE fix never confirmed; audio never heard |
| Miracast to BRAVIA | "Connection failed" — VPN theory untested |
| Multi-TV mirroring | Not built |

---

## Suggested Execution Order

The bugs are interdependent. This order minimizes rework.

**Post-verification note (2026-11-11):** B33, K1 Samsung, K2, K5 are already fixed. B34 declaration is done. This removes ~4.5 hours from the original estimate and eliminates 5 items from the sequence. Remaining: **~60-72 hours**.

### Phase 1 — Foundation (do first, everything else depends on it)
1. ~~**B33** — Fix Flutter import so tests compile (5 min)~~ DONE
2. **K7 + S4** — Remove/gate all 91 debug logging call sites (privacy rule; 30 min)
3. **S1** — Delete dead private key (2 min)
4. **C5** — Move `_createAdapter` inside try (5 min)

### Phase 2 — Keyboard (remaining issues)
5. **K3 + K4** — Build shared `AtvImeSession` with correct protobuf structure + echoed counters (new file + wire into ATV adapter + tests; 3-4 hours)
6. **K3 continued** — Wire `AtvImeSession` into `BraviaAtvrs`, fix structure on field 21 (1-2 hours)
7. ~~**K5** — Fix sticky `_gotError` (30 min)~~ DONE
8. **K1 (BRAVIA)** — Remove silent OK fallback, propagate sidecar error (30 min)
9. ~~**K1 (Samsung)** — Implement `SendInputEnd` for submit~~ DONE
10. ~~**K2** — Build `TizenImeSession` with full-string sends~~ DONE — Samsung IME event listeners (`imeStart`/`imeUpdate`/`imeEnd`) remain as an enhancement
11. **K6** — Add text op FIFO queue, remove optimistic tvText, typed errors (2 hours)

### Phase 3 — Connection (all 7 confirmed)
12. **C1** — Samsung: wait for `ms.channel.connect`, token persistence (2-3 hours)
13. **C3** — Fix LiveAtvChannel defects (stored timer, subscription cancel, deferred isOpen) (2 hours)
14. **C4** — Fix LiveWsChannel defects (generation counter, close client, remove URL log) (1 hour)
15. **C2** — Wire SessionManager, real heartbeat, AppLifecycleState observer (3-4 hours)
16. **C6** — Fix forcedAdapterId leak + reset (1 hour)

### Phase 4 — UI Honesty (all 5 confirmed + subissues)
17. **U2** — Gate app buttons by caps.appLaunch, human error messages (1 hour)
18. **U7** — Create `human_errors.dart`, route all error assignments through it (2 hours)
19. **U1** — Real input list from adapters, dynamic source tabs (3 hours)
20. **U3** — Implement WoL or set wake:false (2-3 hours)
21. **U4** — Replace hardcoded detection with real capability verification (2 hours)
22. **U5** — Parse field 50, add state stream, remove optimistic toggles (2-3 hours)
23. **U6** — Fix dead controls (per table above) (2-3 hours)
24. **U8** — Accessibility pass (2 hours)
25. **B32** — Per-press feedback (1-2 hours)

### Phase 5 — Discovery (all 3 confirmed + subissues)
26. **D1** — Fix Google Home Mini classification using Cast TXT ca bits (1-2 hours)
27. **D2** — Stable device naming with priority merge (1 hour)
28. **D3** — DLNA probe from SSDP location + Samsung :9197 (2 hours)
29. **D4-D8** — Remaining discovery fixes (3-4 hours)

### Phase 6 — Cast & Mirror (all 4 confirmed + subissues)
30. **M1** — Fix Cast success criterion, timeout, retry (2-3 hours)
31. **M2** — Fix stale segments, BRAVIA URL, playlist timing, thread safety (4-5 hours)
32. **M6** — Add token to mirror endpoints (1 hour)
33. **M7** — Fix Range handling (1 hour)
34. **M3-M5** — Mirror start confirmation, DRM messaging, AirPlay fixes (3 hours)

### Phase 7 — Security (all 4 confirmed)
35. **S2** — Keystore-backed secret storage (3-4 hours)
36. **S3** — TOFU cert pinning at 4 sites (2-3 hours)
37. **S5** — Fix cert generation (CA:FALSE, shorter validity) (30 min)
38. **C7** — webOS wss:3001 fallback (1 hour, no hardware to test)
39. **B34 remainder** — Runtime POST_NOTIFICATIONS request on API 33+ (30 min)

### Phase 8 — Test & Verify
40. **B35** — Write missing tests for all new code (4-6 hours)
41. On-device test matrix: BRAVIA re-pair + type + Enter, Haier all keys + IME, Samsung token + app launch, Cast retry, Mirror start

**Estimated total: ~60-72 hours of implementation work (reduced from ~65-80 after verification).**

---

*This plan is read-only. No code was changed. Verified against the current working tree on 2026-11-11: 5 items moved to Previously Fixed, 3 descriptions corrected, 24 bugs remain confirmed open. When ready to start implementing, the suggested first step is Phase 1 (K7 + S1 + C5) — a quick foundation cleanup that unblocks everything else.*
