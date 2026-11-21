# SANKETA Bug & Error Report

**Date:** 2026-10-10
**Device:** OnePlus LE2111 (e3b9507e), Android 14 (API 34), 1080x2400, 480dpi
**Build:** Debug APK, Flutter 3.47.2 / Dart 3.12.2
**Network:** 192.168.29.0/24 (phone IP: 192.168.29.223)

---

## Network Discovery Scan Results

| IP | MAC | Identity |
|---|---|---|
| 192.168.29.1 | 78:bb:c1:d6:72:66 | Router (REACHABLE) |
| 192.168.29.79 | unknown | Endpoint |
| 192.168.29.108 | unknown | Endpoint |
| 192.168.29.124 | unknown | Endpoint |
| 192.168.29.173 | unknown | Endpoint |
| 192.168.29.180 | unknown | Endpoint |
| 192.168.29.191 | 3c:e4:41:f1:d2:f2 | Endpoint |
| 192.168.29.202 | 92:29:54:43:04:79 | Endpoint (randomized MAC) |
| 192.168.29.206 | 66:36:79:49:a1:6c | Endpoint (randomized MAC) |
| 192.168.29.223 | 9e:ef:c4:dc:0e:ca | This phone |

**Port scan** (8008/8009 Chromecast, 8060 Roku, 8001/8002 Samsung, 3000/3001 LG WebOS, 1925 Philips/AndroidTV, 7000 Vizio, 36866 Roku, 9197, 55443, 5555, 9090): **Zero open ports on any device.**

**SSDP multicast discovery:** No responses received.

**Conclusion:** No smart TVs or streaming devices are currently reachable on this network. All non-router devices appear to be phones/laptops/IoT (most use randomized MACs).

---

## CRITICAL

### BUG-001: Back button exits app without confirmation
- **File:** `sanketa_app/lib/screens/app_shell.dart`
- **Behavior:** Pressing Android back on the root screen immediately exits the app to the home screen / app drawer.
- **Expected:** Show an exit confirmation dialog, or minimize app to background (standard Android behavior).
- **Root cause:** `AppShell` Scaffold has no `PopScope` wrapper. Flutter's default behavior pops the only route, exiting the activity.
- **Fix:** Wrap `AppShell` body with `PopScope(canPop: false, onPopInvokedWithResult: ...)` that either shows a confirm dialog or calls `SystemNavigator.pop()` on double-back.

---

## HIGH

### BUG-002: Discovery backends exist but are not wired into the app
- **Files:** `sanketa_discovery/lib/src/{ssdp_backend,mdns_backend,probe_backend}.dart` (fully implemented), `sanketa_app/lib/screens/devices_screen.dart` (static placeholder)
- **Behavior:** Devices screen shows a spinning "Scanning your network..." indicator forever. No actual mDNS/SSDP/probe scan is triggered.
- **Root cause:** `sanketa_app/pubspec.yaml` does not depend on `sanketa_discovery`. The backends are implemented but never imported or called from the app. `devices_screen.dart` is a pure static layout with no state or discovery integration.
- **Fix:** Add `sanketa_discovery` dependency, create a `DiscoveryEngine` in the app, wire discovered endpoints into the Devices screen state.

### BUG-003: All device data is hardcoded demo
- **File:** `sanketa_app/lib/control/remote_controller.dart:11,24`
- **Behavior:** `deviceName = 'Demo TV'`, adapter is always `DemoAdapter`. Connection bar always shows "Connected to Demo TV". All button presses go to a logging-only adapter.
- **Root cause:** No real adapter selection, no device connection flow, no pairing. The entire control path is a demo stub.
- **Impact:** Every screen references `c.deviceName` which is always "Demo TV". Every control action is logged but not sent anywhere.

### BUG-004: "Add Device Manually" button is non-functional
- **File:** `sanketa_app/lib/screens/devices_screen.dart:215-237`
- **Behavior:** Tapping the "Add Device Manually" button does nothing.
- **Root cause:** The `Container` has no `GestureDetector` wrapper — it's purely decorative.
- **Fix:** Wrap in `GestureDetector(onTap: ...)` that opens a manual IP entry dialog per FR-1.3.

### BUG-005: Media source cards (Photos/Videos/Music/Files) are non-functional
- **File:** `sanketa_app/lib/screens/cast_screen.dart:154-169`
- **Behavior:** Tapping Photos, Videos, Music, or Files cards does nothing.
- **Root cause:** `_sourceCard()` builds a `Container` with no tap handler. No media picker integration exists.

### BUG-006: Default Flutter splash screen instead of branded SANKETA splash
- **Behavior:** On cold start, the app shows the default blue Flutter logo on a black background for ~2 seconds before the UI loads.
- **Expected:** Show the SANKETA brand mark with OmniBeam cyan on deep black.
- **Root cause:** `LaunchTheme` and `NormalTheme` in `styles.xml` use Flutter defaults. No custom splash assets.

---

## MEDIUM

### BUG-007: Settings tune icon touch target too small (20dp)
- **File:** `sanketa_app/lib/screens/remote_screen.dart:109`
- **Behavior:** The settings gear icon on the Remote screen header is only 20dp. Requires very precise tapping on a phone.
- **Standard:** Material Design minimum touch target is 48x48dp.
- **Fix:** Wrap in `SizedBox(width: 48, height: 48)` with centered icon, or increase the `GestureDetector` hit area.

### BUG-008: WindowOnBackDispatcher warning (Android 14+ predictive back)
- **File:** `sanketa_app/android/app/src/main/AndroidManifest.xml`
- **Log:** `WindowOnBackDispatcher: OnBackInvokedCallback is not enabled for the application. Set 'android:enableOnBackInvokedCallback="true"' in the application manifest.`
- **Impact:** Android 14 predictive back gesture animation does not work. User sees no back-swipe preview.
- **Fix:** Add `android:enableOnBackInvokedCallback="true"` to the `<application>` tag.

### BUG-009: Devices screen header settings icon is dead
- **File:** `sanketa_app/lib/screens/devices_screen.dart:69-70`
- **Behavior:** Settings icon rendered but has no tap handler.
- **Fix:** Either add a GestureDetector to navigate to Settings, or remove the icon.

### BUG-010: Search screen never persists recent searches
- **File:** `sanketa_app/lib/screens/search_screen.dart:190-216`
- **Behavior:** "RECENT" section always shows "Your recent searches will appear here" regardless of usage.
- **Root cause:** No state management for search history. Searches go through `c.type()` + `c.submit()` but are never recorded.

### BUG-011: Quick Launch buttons are demo-only
- **File:** `sanketa_app/lib/screens/search_screen.dart:172-175`
- **Behavior:** Netflix / YouTube / Prime Video / Disney+ buttons call `c.launch(name)` which hits `DemoAdapter._record()`. No real app launch.
- **Note:** These will work once a real adapter is connected, but currently provide no user feedback that the action was received.

### BUG-012: Orientation not handled for remote layout
- **Observed:** Logs show rotation event (1080x2400 -> 2297x1080 -> back). App survived without crash, but the remote layout (keyboard + d-pad stacked vertically) is not designed for landscape.
- **Fix:** Either lock to portrait via `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` or provide a landscape-specific layout.

### BUG-013: Infinite scanning indicator
- **File:** `sanketa_app/lib/screens/devices_screen.dart:195-212`
- **Behavior:** The "Scanning" label with spinning `CircularProgressIndicator` runs forever since no actual scan is happening.
- **Impact:** Misleads the user into thinking a scan is in progress.

---

## LOW

### BUG-014: No haptic feedback on any button press
- **Behavior:** D-pad, keyboard, power, mute, source buttons produce no haptic feedback.
- **Architecture note:** `HapticsBridge` platform channel is in the architecture but not wired.
- **Impact:** Reduced tactile confidence on a remote control app where feedback is critical.

### BUG-015: Mute button has no visual state
- **Behavior:** Mute icon is always `Icons.volume_off` in grey. No toggle state, no visual indication of muted vs unmuted.

### BUG-016: Power button has no on/off visual feedback
- **Behavior:** Power button icon is static. No glow, color change, or animation on tap.

### BUG-017: Connection bar is always "Connected"
- **File:** `sanketa_app/lib/widgets/connection_bar.dart`
- **Behavior:** Green dot + "Connected to Demo TV · Via Network" is always shown. There is no disconnected/reconnecting/error state.
- **Root cause:** No real connection lifecycle. `SessionManager` exists in `sanketa_core` but is not integrated into the app's UI state.

### BUG-018: Initial frame skipping on startup
- **Log:** `Skipped: false 76 cost 1274.7631` and `Skipped: false 75 cost 632.9477`
- **Impact:** ~132 + 75 frames skipped during initial render. Expected in debug mode due to JIT compilation. Verify in release build.

### BUG-019: Adreno GPU format warnings
- **Log:** Various `VRI[MainActivity]` and `Quality` messages related to surface buffer management.
- **Impact:** Cosmetic log noise. OnePlus/Qualcomm Adreno specific. No functional impact.

---

## Test Results Summary

| Test | Result | Notes |
|---|---|---|
| All 5 screens render | PASS | Remote, Search, Cast, Devices, Settings |
| Bottom nav switching | PASS | All 4 tabs navigate correctly |
| Settings navigation | PASS | Gear icon opens Settings, back arrow returns |
| OmniBeam dark theme | PASS | Consistent beam cyan (#00E5FF) throughout |
| Keyboard layout | PASS | All rows render correctly (QWERTY + numbers) |
| D-pad layout | PASS | Up/Down/Left/Right/OK buttons render correctly |
| Source switching UI | PASS | HDMI1/HDMI2/TV tabs switch visually |
| Orientation change | PASS | App survives rotation without crash |
| Android back button | FAIL | Exits app without confirmation (BUG-001) |
| Real device discovery | FAIL | Not wired (BUG-002) |
| Real TV connection | FAIL | Demo-only (BUG-003) |
| Keyboard typing to TV | N/A | Requires real adapter connection |
| Haptic feedback | FAIL | Not wired (BUG-014) |
| Network scan (live) | INFO | 10 devices found, 0 smart TVs |
| Unit tests (core) | PASS | 23/23 tests pass |
| Unit tests (adapters) | PASS | 79/79 tests pass |
| Widget tests (app) | PASS | 15/15 tests pass |

---

## Priority Fix Order

1. **BUG-001** — Back button exits app (user-facing crash-level UX)
2. **BUG-008** — AndroidManifest predictive back (1-line fix)
3. **BUG-007** — Settings touch target (small fix, big usability gain)
4. **BUG-006** — Branded splash screen (first impression)
5. **BUG-002** — Wire discovery backends (core feature)
6. **BUG-003** — Real adapter selection + connection flow (core feature)
7. **BUG-004** — Add Device Manually button (core feature)
8. **BUG-013** — Fix infinite scanning indicator
9. **BUG-009** — Dead settings icon in Devices header
10. **BUG-005** — Media source cards in Cast screen
11. **BUG-014** — Haptic feedback
12. Remaining items
