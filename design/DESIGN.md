---
name: OmniBeam Living UI
colors:
  surface: '#10131a'
  surface-dim: '#10131a'
  surface-bright: '#363941'
  surface-container-lowest: '#0b0e15'
  surface-container-low: '#191b23'
  surface-container: '#1d1f27'
  surface-container-high: '#272a32'
  surface-container-highest: '#32353d'
  on-surface: '#e1e2ec'
  on-surface-variant: '#bac9cc'
  inverse-surface: '#e1e2ec'
  inverse-on-surface: '#2d3038'
  outline: '#849396'
  outline-variant: '#3b494c'
  surface-tint: '#00daf3'
  primary: '#c3f5ff'
  on-primary: '#00363d'
  primary-container: '#00e5ff'
  on-primary-container: '#00626e'
  inverse-primary: '#006875'
  secondary: '#c0c1ff'
  on-secondary: '#1000a9'
  secondary-container: '#3131c0'
  on-secondary-container: '#b0b2ff'
  tertiary: '#a8ffd2'
  on-tertiary: '#003824'
  tertiary-container: '#5be9ad'
  on-tertiary-container: '#006645'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#9cf0ff'
  primary-fixed-dim: '#00daf3'
  on-primary-fixed: '#001f24'
  on-primary-fixed-variant: '#004f58'
  secondary-fixed: '#e1e0ff'
  secondary-fixed-dim: '#c0c1ff'
  on-secondary-fixed: '#07006c'
  on-secondary-fixed-variant: '#2f2ebe'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#10131a'
  on-background: '#e1e2ec'
  surface-variant: '#32353d'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-xl-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-mono-lg:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.05em
  label-mono-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.08em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  space-2xs: 0.125rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-base: 1rem
  space-lg: 1.25rem
  space-xl: 1.5rem
  space-2xl: 2rem
  space-3xl: 3rem
  touch-target-min: 3rem
---

## Brand & Style

This design system is engineered for smart home hardware orchestration, home cinema control, and media stream casting. The interface balances high-efficiency tactile control with an immersive living room aesthetic calibrated specifically for low-light, home-theater environments.

The design movement synthesizes **Tactile Precision** and **Luminescent Modernism**:
- **Tactile Precision:** Hardware-inspired skeuomorphic undertones featuring micro-beveled switches, directional pads (D-pads), and recessed buttons that simulate real remote hardware with instant physical feedback.
- **Luminescent Accents:** High-potency optical glows and status beacons signaling state changes, beam transmissions, and network handshakes without washing out user dark adaptation.
- **Cinema-Grade High Contrast:** Deep, pitch-adjacent slate planes paired with surgically sharp typography and luminous color cues to guarantee zero-strain usability in dark rooms.

## Colors

The palette establishes an ultra-low luminance foundation accented with piercing, high-chroma beacons for critical transmission states.

### Palette Roles & Values
- **Base Canvas (`#0A0D14`):** The deepest void background; prevents OLED panel light bleed and preserves night vision.
- **Surface Elevation 1 (`#121722`):** Primary structural surface for control docks, remote casings, and device cards.
- **Surface Elevation 2 (`#1A2130`):** Raised interactive plates, tactile remote keys, and recessed D-pad housings.
- **Surface Elevated Interactive (`#242D42`):** Hovered and pressed button states; micro-beveled edges.
- **Primary Accent / Beam Cyan (`#00E5FF`):** Represents low-latency infrared transmission, active casting sessions, and primary active states. Features localized radial glows.
- **Secondary Accent / Stream Violet (`#6366F1`):** Represents Wi-Fi connectivity, casting protocols (AirPlay, Chromecast, DLNA), and secondary mode switches.
- **Tertiary Accent / Signal Emerald (`#10B981`):** Hardware heartbeat, battery status, and verified network handshakes.
- **Alert / Overheat Amber & Crimson (`#F59E0B`, `#EF4444`):** Packet drops, disconnected IR repeaters, and power-off destructive sequences.
- **Text & Foregrounds:**
  - `Text-Primary` (`#F8FAFC`): 98% pure white for optimal display readability in ambient darkness.
  - `Text-Secondary` (`#94A3B8`): Muted cool slate for secondary metadata and inactive controls.
  - `Text-Tertiary` (`#475569`): Demarcation lines and passive icon states.

## Typography

Typography pairs the structural legibility of **Plus Jakarta Sans** for navigation and layout elements with the technical precision of **JetBrains Mono** for hardware payloads, frequency readouts, and connectivity metadata.

- **Legibility Strategy:** Font weights are bumped one tier higher than typical day-mode designs (Medium -> SemiBold, Regular -> Medium) to prevent optical thinning against deep `#0A0D14` backgrounds.
- **Monospaced Instrumentation:** All hardware metrics (e.g., `38.4 kHz IR`, `5.0 GHz Cast`, `-42 dBm`) use JetBrains Mono to anchor numerical readouts and prevent layout shift during live feedback pulses.

## Layout & Spacing

The spatial model centers on thumb-driven ergonomics for mobile control surfaces:

- **Thumb Zone Anchoring:** All interactive hardware arrays (D-pad, volume rockers, source triggers) sit within the lower 60% of the viewport. Status readouts and session overviews occupy the top 40%.
- **Minimum Touch Targets:** Remote triggers strictly enforce a `touch-target-min` (48px / 3rem) boundary, regardless of visible icon size, ensuring reliable single-handed touch operation in unlit rooms.
- **Grid Architecture:** 
  - Mobile uses a 4-column fluid layout with `1.25rem` outer screen gutters and `0.75rem` internal component spacing.
  - Tablet/Landscape unfolds into a dual-chassis layout: left pane for device browsing/casting queue (6 columns), right pane dedicated to the physical remote pad (6 columns).

## Elevation & Depth

Depth is conveyed through a hybrid of physical tactile extrusion and optical luminance:

1. **Hardware Recesses (Well Depth):**
   - Negative elevation (concave trays such as D-pad wells): `inset 0 2px 4px rgba(0, 0, 0, 0.7), inset 0 -1px 1px rgba(255, 255, 255, 0.04)`.
2. **Tactile Remote Buttons (Chiseled Convexity):**
   - High-relief top highlight: `inset 0 1px 0 rgba(255, 255, 255, 0.15)`.
   - Bottom drop shadow: `0 4px 10px rgba(0, 0, 0, 0.6), 0 1px 2px rgba(0, 0, 0, 0.4)`.
   - Pressed state shifts physical transform down (`translateY(2px)`) with shadow depth reduced to `0 1px 2px rgba(0, 0, 0, 0.8)`.
3. **Luminescent Proximity Glows:**
   - Active IR firing state: Button rim activates `box-shadow: 0 0 16px rgba(0, 229, 255, 0.4), inset 0 0 8px rgba(0, 229, 255, 0.2)`.
   - Wi-Fi stream locked: Base card emits `box-shadow: 0 0 24px -4px rgba(99, 102, 241, 0.25)`.
4. **Surface Sheen:**
   - Cards and control docks use subtle 1px perimeter gradient borders: `linear-gradient(180deg, rgba(255, 255, 255, 0.1) 0%, rgba(255, 255, 255, 0.02) 100%)`.

## Shapes

The design uses balanced `0.5rem` to `1.5rem` rounding to evoke ergonomic consumer electronics:

- **Remote Outer Shell:** `rounded-xl` (1.5rem / 24px) for the main device enclosure to mimic handheld remotes.
- **Tactile Keypads & D-Pads:** Directional buttons use specialized continuous segment arcs (pie sectors with `0.5rem` corner smoothing), while individual keys use uniform `0.75rem` (12px) radii.
- **Connection & Protocol Badges:** Complete pill shapes (`rounded-full` / 9999px) for persistent hardware status pills.

## Components

### 1. Hardware Buttons & Directional Pad (D-Pad)
- **Standard Button:** Dark slate background (`#1A2130`), top-lit bevel with 1px border highlight, center-aligned icon in `#F8FAFC`. Active state triggers cyan flash outline (`#00E5FF`) lasting 120ms to confirm IR signal dispatch.
- **Omni-Directional D-Pad:** Circular cross-cluster set within a recessed `#0A0D14` chassis. Center `OK` button elevated above the cardinal arrows (`UP`, `DOWN`, `LEFT`, `RIGHT`) with distinct tactile micro-grooves.

### 2. Luminous Connection Pills
- **IR Blaster Active:** Ultra-dark cyan background (`rgba(0, 229, 255, 0.12)`), perimeter stroke in `#00E5FF`, JetBrains Mono label `IR :: READY` or `IR :: TRANSMITTING`, accompanied by a pulsing neon cyan beacon dot.
- **Wi-Fi / Cast Active:** Indigo background (`rgba(99, 102, 241, 0.14)`), violet stroke (`#6366F1`), monospaced identifier `CAST :: 4K STREAM`, paired with live signal bars.

### 3. Volume & Channel Rockers
- Dual-segmented vertical capsules with a distinct central separation ridge. Continuous press increments trigger haptic feedback patterns and scaling glow intensities along the capsule rail.

### 4. Media Cast Cards
- Background: `#121722` encased in 1px low-opacity border.
- Features real-time artwork preview, dynamic indigo glow underneath playback controls, and an integrated source badge (HDMI 1, AirPlay, Chromecast, Sony Bravia IR).

### 5. Input Fields & Code Capture
- Terminal-inspired text inputs for hex code entry, device learning, and IP address bindings. Uses JetBrains Mono text, deeply recessed surface color (`#0A0D14`), and a steady cyan carets.