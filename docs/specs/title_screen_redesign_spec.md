# Step 2: Technical Specification (`specs.md`) — Title Screen Redesign (`Title screen.jpg`)

## 1. Scope & Overview
This specification defines the exact data contracts, scene hierarchy, layout dimensions, color palette, and procedural styling for the redesigned **Title Screen** (`res://scenes/ui/title_screen.tscn` and `res://scripts/ui/title_screen.gd`) using the new `Title screen.jpg` artwork (`res://assets/art/title_screen.jpg`).

---

## 2. Asset Contract
- **Source File**: `C:\Users\jmarc\Documents\Godot\Games\whack-a-mole\Title screen.jpg`
- **Target Project Path**: `res://assets/art/title_screen.jpg` (git-ignored under `/assets/art/` so it remains local-only and is never pushed to GitHub).
- **Runtime Loading Contract (`title_screen.gd`)**:
  - `const HERO_ART_PATH: String = "res://assets/art/title_screen.jpg"`
  - `const FALLBACK_HERO_ART_PATH: String = "res://assets/art/topo_hero.jpg"`
  - Loaded dynamically via `ResourceLoader.exists()` in `_ready()` so the scene file never contains a hard external dependency on git-ignored files.

---

## 3. Scene Node Hierarchy & Layout Specification (`res://scenes/ui/title_screen.tscn`)

### 3.1 Node Tree
```text
TitleScreen (Control) [anchors_preset = 15 (Full Rect), script = res://scripts/ui/title_screen.gd]
├── BackgroundHolder (Control) [anchors_preset = 15, clip_contents = true]
│   └── HeroArt (TextureRect) [anchors_preset = 15, expand_mode = 1, stretch_mode = 6 (STRETCH_KEEP_ASPECT_COVERED)]
├── VignetteOverlay (TextureRect) [anchors_preset = 15, mouse_filter = 2]
├── AmbientMotes (CPUParticles2D) [position = Vector2(540, 1750), amount = 28]
├── SafeMargin (MarginContainer) [anchors_preset = 15]
│   └── CenterWrap (HBoxContainer) [alignment = 1 (ALIGNMENT_CENTER)]
│       └── CenterColumn (VBoxContainer) [custom_minimum_size = Vector2(920, 0), size_flags_horizontal = 3, size_flags_vertical = 3]
│           ├── TopBar (HBoxContainer) [alignment = 2 (ALIGNMENT_END)]
│           │   └── OpenSettingsButton (Button) [custom_minimum_size = Vector2(320, 84)]
│           ├── LogoClearanceSpacer (Control) [custom_minimum_size = Vector2(0, 485), mouse_filter = 2]
│           ├── SubtitleCenterRow (HBoxContainer) [alignment = 1 (ALIGNMENT_CENTER)]
│           │   └── SubtitlePlaque (PanelContainer)
│           │       └── SubLogoLabel (Label) [horizontal_alignment = 1 (HORIZONTAL_ALIGNMENT_CENTER)]
│           ├── HeroMoleSpacer (Control) [size_flags_vertical = 3 (SIZE_EXPAND_FILL), mouse_filter = 2]
│           └── BottomActionBox (VBoxContainer) [theme_override_constants/separation = 16]
│               ├── StartButtonRow (HBoxContainer) [alignment = 1 (ALIGNMENT_CENTER)]
│               │   └── TapToStartButton (Button) [custom_minimum_size = Vector2(820, 154)]
│               └── PlatformHintLabel (Label) [horizontal_alignment = 1, autowrap_mode = 2]
└── SettingsBackdrop (ColorRect) [visible = false, anchors_preset = 15]
    └── ModalCenter (CenterContainer) [anchors_preset = 15]
        └── SettingsModal (PanelContainer) [custom_minimum_size = Vector2(880, 0)]
            └── ... (Existing 9-language & Audio Settings controls preserved)
```

### 3.2 Vertical Positioning & Unobstructed Artwork Zones (`1080x1920` Base Viewport)
| Vertical Band (`Y`) | Element | Visual Purpose |
| :--- | :--- | :--- |
| `0px – 128px` | `SafeMargin` top inset | Physical front-camera cutout avoidance (`UIThemeBuilder.apply_device_safe_area`) |
| `128px – 212px` | `TopBar` -> `OpenSettingsButton` | Top-right compact timber settings button (`320x84px`) |
| `212px – 697px` | `LogoClearanceSpacer` (`485px` min height) | Keeps the giant painted **"Topo Smash"** logo 100% unobstructed |
| `697px – 780px` | `SubtitleCenterRow` -> `SubtitlePlaque` (`SubLogoLabel`) | Sits in the natural gap right under **"Topo Smash"** and above the mole's yellow helmet |
| `780px – 1640px` | `HeroMoleSpacer` (`SIZE_EXPAND_FILL`) | Keeps the cool sunglasses mole, yellow hard hat, mine cart, and pickaxe 100% unobstructed |
| `1640px – 1868px` | `BottomActionBox` (`TapToStartButton` + `PlatformHintLabel`) | Anchors the new 3D Molten-Amber & Carved-Timber Start button over the bottom dirt mound |

---

## 4. Visual & Procedural Style Specification (`res://scripts/ui/title_screen.gd`)

### 4.1 Vignette Overlay (`GradientTexture2D_vignette`)
- Top (`0.0` to `0.72`): Completely transparent (`Color(0, 0, 0, 0.0)`) so the sunny blue sky, green pines, and painted **"Topo Smash"** logo retain 100% of their original brightness.
- Bottom (`0.78` to `1.0`): Smoothly darkens to `Color(0.08, 0.04, 0.01, 0.78)` at the bottom edge so the Start button and hint label have crisp contrast.

### 4.2 Carved-Timber & Amber Subtitle Plaque (`SubtitlePlaque` + `SubLogoLabel`)
- **`SubtitlePlaque` (`StyleBoxFlat`)**:
  - `bg_color`: `Color("#2B1508")` at `0.92` alpha (deep roasted timber brown matching the logo's dark ink outline)
  - `border_color`: `Color("#FF8C1A")` (molten amber-orange matching the glossy `"S"` in *"Topo Smash"*)
  - `border_width_left / top / right`: `4px`
  - `border_width_bottom`: `8px` (3D carved plaque lip)
  - `corner_radius` (all 4 corners): `26px` (pill-shaped ribbon badge)
  - `content_margin_left / right`: `38px`
  - `content_margin_top / bottom`: `10px`
  - `shadow_color`: `Color(0.08, 0.03, 0.01, 0.65)`, `shadow_size = 14`, `shadow_offset = Vector2(0, 6)`
- **`SubLogoLabel` (`LabelSettings`)**:
  - Text source: `LocalizationManager.t("GAME_TITLE_SUB")` (`"CAOS CON CASCO"`, `"HARD HAT HAVOC"`, etc.)
  - `font_size`: `46px`
  - `font_color`: `Color("#FFE566")` (warm hard-hat golden yellow)
  - `outline_size`: `12px`
  - `outline_color`: `Color("#1E0C04")` (deep espresso ink outline)
  - `shadow_offset`: `Vector2(0, 5)`

### 4.3 Molten-Amber & Carved-Timber Start Button (`TapToStartButton`)
- **Dimensions**: `custom_minimum_size = Vector2(820, 154)`
- **Custom Style (`_apply_hero_start_button_style(start_button)`)**:
  - **Normal State (`StyleBoxFlat`)**:
    - `bg_color`: `Color("#F97316")` (vibrant molten amber-orange matching the painted `"S"` in *"Smash"*)
    - `border_color`: `Color("#3B1908")` (heavy dark-timber/ink 3D rim matching the logo's outer stroke)
    - `border_width_left / top / right`: `6px`
    - `border_width_bottom`: `16px` (chunky 3D arcade bottom lip)
    - `corner_radius` (all 4 corners): `38px`
    - `shadow_color`: `Color(0.09, 0.04, 0.01, 0.72)`, `shadow_size = 18`, `shadow_offset = Vector2(0, 8)`
    - `content_margin_left / right`: `36px`, `content_margin_top`: `14px`, `content_margin_bottom`: `20px`
  - **Hover / Focus State**:
    - `bg_color`: `Color("#FB923C")` (brightened molten gold-orange)
    - `border_color`: `Color("#FFE066")` on Focus (`6px` sides/top, `16px` bottom)
  - **Pressed State**:
    - `bg_color`: `Color("#EA580C")`
    - `border_width_bottom`: `6px` (depresses down by `10px` when tapped)
    - `content_margin_top`: `24px`, `content_margin_bottom`: `10px`
  - **Typography & Pulse Animation**:
    - `font_size`: `50px`
    - `font_color`: `Color("#FFFDF2")` (warm cream white)
    - `font_outline_color`: `Color("#210D04")`, `outline_size`: `13px`
    - Gentle breathing pulse tween on `start_button` (`scale` `Vector2(1.0, 1.0)` <-> `Vector2(1.03, 1.03)` + warm golden modulate over `0.95s`).

### 4.4 Top-Right Settings Button (`OpenSettingsButton`)
- Styled with `UIThemeBuilder.apply_village_button_style()`:
  - `fill_color`: `Color("#4A2812")` (warm mine-timber brown)
  - `lip_color`: `Color("#231005")` (dark espresso border/lip)
  - `text_color`: `Color("#FFE89E")`
  - `font_size`: `32px`, `corner_radius`: `22px`, `lip_height`: `9px`

---

## 5. Removed Elements Contract
- `MainLogoLabel` (`"TOPO SMASH"`) is **removed** from `title_screen.tscn` and `title_screen.gd`.
- `TaglineLabel` (`"¡Defiende tu jardín en 2.5D de la invasión subterránea!"`) is **removed** from `title_screen.tscn` and `title_screen.gd`.

---

## 6. Acceptance Criteria
- [ ] `TitleScreen` displays the new `Title screen.jpg` background (`res://assets/art/title_screen.jpg`) with the painted **"Topo Smash"** logo and sunglasses mole completely unobstructed.
- [ ] The localized subtitle (`GAME_TITLE_SUB`, e.g., `"CAOS CON CASCO"`) is displayed in a carved-timber & amber plaque directly beneath the painted **"Topo Smash"** logo and updates across all 9 languages.
- [ ] The phrase `"¡Defiende tu jardín en 2.5D de la invasión subterránea!"` and the redundant text `"TOPO SMASH"` label are completely removed.
- [ ] The Start button (`TapToStartButton`) features the new molten-amber & dark-timber 3D style with a smooth breathing pulse animation.
- [ ] `res://assets/art/title_screen.jpg` remains ignored by Git (`.gitignore`) so it is never pushed to GitHub.
