# Step 2: Spec-Driven Technical Specification — Milestone 2.1 (Pixel 5 Safe-Area, Unobstructed Intro & Illustrated Village Hub)

> [!IMPORTANT]
> **Strict 3-Step Workflow (`1. Plan` [Approved] → `2. Spec-Driven` [Current] → `3. Implementation`) & Git Rule**
> This document is the dedicated **Step 2: Spec-Driven Specification** for Milestone 2.1. Once you approve `specs.md`, I will save a copy to `docs/specs/milestone_2_1_spec.md` and execute **Step 3 (Implementation)** while leaving all files uncommitted in your working tree.

---

## 1. SPEC-M2.1-01: Physical Front-Camera & Notch Safe-Area Contract

### Pure Function Contract: `UIThemeBuilder.apply_device_safe_area(margin: MarginContainer, base_left: int = 28, base_top: int = 36, base_right: int = 28, base_bottom: int = 44) -> void`
1. Read `var window_size: Vector2i = DisplayServer.window_get_size()` and `var safe_rect: Rect2i = DisplayServer.get_display_safe_area()`.
2. Read the current scene's viewport size: `var vp_size: Vector2 = margin.get_viewport_rect().size`.
3. Calculate coordinate scale from physical window pixels to viewport units:
   - `var scale_y: float = vp_size.y / float(maxi(1, window_size.y))`
   - `var scale_x: float = vp_size.x / float(maxi(1, window_size.x))`
4. Compute physical cutout insets in viewport units:
   - `var top_inset: int = roundi(float(maxi(0, safe_rect.position.y)) * scale_y)`
   - `var left_inset: int = roundi(float(maxi(0, safe_rect.position.x)) * scale_x)`
   - `var bottom_raw: int = maxi(0, window_size.y - (safe_rect.position.y + safe_rect.size.y))`
   - `var bottom_inset: int = roundi(float(bottom_raw) * scale_y)`
5. **Android / iOS Front-Camera Safety Floor:**
   - When running on a mobile OS (`OS.has_feature("mobile")` or `OS.get_name() in ["Android", "iOS"]`), some fullscreen Android modes report `safe_rect.position.y == 0` even when a punch-hole camera is present at the top-left (like the Pixel 5 punch-hole at ~`110px–125px`).
   - Therefore, on Android/iOS (or when `vp_size.y / maxi(1.0, vp_size.x) > 1.85` like a 19.5:9 phone screen), enforce a **minimum top safe margin of `128px`** and a **minimum bottom safe margin of `64px`**:
     - `var final_top: int = maxi(base_top + top_inset, 128 if is_tall_or_mobile else base_top)`
     - `var final_bottom: int = maxi(base_bottom + bottom_inset, 64 if is_tall_or_mobile else base_bottom)`
     - `var final_left: int = base_left + left_inset`
     - `var final_right: int = base_right + left_inset`
6. Apply `margin_top`, `margin_bottom`, `margin_left`, and `margin_right` theme constant overrides to `margin`.
7. Invoke `UIThemeBuilder.apply_device_safe_area(safe_margin)` in `_ready()` and on `get_viewport().size_changed` across all 4 screens:
   - `TitleScreen` (`$SafeMargin`)
   - `MainHub` (`$SafeMargin`)
   - `StoreScreen` (`$SafeMargin`)
   - `Arena25D` (`$HUD/HUDRoot/SafeMargin`)

---

## 2. SPEC-M2.1-02: Unobstructed Arena Intro Banner & Seamless 3D Horizon (`Arena25D`)

### A. Top-Positioned Intro Banner
In `res://scenes/game/arena_2_5d.tscn`, reorder `MainHUDVBox` children so `IntroBannerCenter` is immediately below `TopBarPanel` (with a `16px` top gap), BEFORE `CenterSpacerTop`:
```text
MainHUDVBox (VBoxContainer)
├── TopBarPanel (PanelContainer - min_height: 138px)
├── IntroBannerCenter (CenterContainer - sits right below TopBarPanel in the upper sky/fence area!)
│   └── IntroBannerPanel (PanelContainer - min_size: 860x110, warm rustic wood & gold rim)
│       └── IntroBannerLabel (Label - 42px font, "👀 ¡UN TOPO ENTRA AL JARDÍN!")
├── CenterSpacer (Control - size_flags_vertical: EXPAND_FILL)
└── BottomEvadeBox (HBoxContainer)
    └── EvadeRockButton (Button - min_height: 168px)
```
- Because `IntroBannerCenter` is now docked right under `TopBarPanel` at the top of the screen, the middle and lower 75% of the screen (where the 3×3 mole matrix sits) is **100% unobstructed** during the mole walk-in!

### B. Seamless 3D Lawn Horizon (Eliminating the Green Seam in Screenshot #6)
- Increase `BoxMesh_lawn` depth from `Vector3(16, 1.8, 16)` to `Vector3(28, 1.8, 36)` shifted slightly backward (`Z = -6.0`), and match `ProceduralSkyMaterial` ground colors (`ground_bottom_color = Color("#27AE60")`, `ground_horizon_color = Color("#2ECC71")`) so the lawn blends seamlessly into the horizon above the wooden fence with zero visible seam.

---

## 3. SPEC-M2.1-03: Illustrated Village Main Hub & Rustic Timber Button System

### A. Background Art Integration
- Copy `C:\Users\jmarc\Documents\Godot\Games\whack-a-mole\fondo main hub celular concepto 2.jpg` to `res://assets/art/village_hub_bg.jpg`.
- In `res://scenes/ui/main_hub.tscn`, replace `VillageBackdropHolder` with:
  - `VillageHeroArt` (`TextureRect`, `anchors_preset = 15`, `texture = res://assets/art/village_hub_bg.jpg`, `expand_mode = 1`, `stretch_mode = 6` — `STRETCH_KEEP_ASPECT_COVERED`).
  - Subtle bottom warm vignette (`BottomVignette`, `TextureRect` with `GradientTexture2D` transparent at top 65%, warm dark earth `Color(0.08, 0.04, 0.01, 0.38)` at the bottom 35%) to give the buttons crisp contrast while keeping the sandy clearing visible.

### B. Rustic Hand-Drawn Village Button Aesthetic (`UIThemeBuilder.apply_village_button_style`)
Designed to match the black-ink outlines (`#231208`), warm oak timbers, golden-amber `"TABERNA"` signboard, and terracotta roof tiles in `village_hub_bg.jpg`:

| Button / Element | Fill Color | 3D Carved Lip / Rim Color | Outer Ink Outline | Text Color & Size | Dimensions |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **`TopStatusBar` Container** | `#2B170BE6` (Dark Tavern Oak) | `#D99B26` (Warm Amber Gold, `4px`) | `#1A0C04` shadow | — | `900×104px` |
| **`⬅ Title` Button** | `#7A4924` (Carved Oak) | `#4A2A12` (`8px` bottom lip) | `#231208` | `#FFF5D6` (`30px`) | `190×78px` |
| **`🏆 Points` & `🪙 Coins` Pills** | `#432613F2` (Warm Chestnut) | `#E5A93B` (`3px` gold trim) | `#1A0C04` | `#FFE066` / `#FFF5D6` (`32px`) | `78px` tall |
| **1. `🔨 PLAY! / ¡JUGAR!`** | **`#F59E0B`** (Warm Amber Signboard Gold) | **`#9A3412`** (`12px` deep mahogany lip) | `#231208` (`10px` text outline) | `#FFFDF5` (**`48px`**) | **`740×136px`** |
| **2. `🛒 STORE / TIENDA`** | **`#D9531E`** (Taberna Terracotta Roof Tile) | **`#7F2709`** (`10px` burnt sienna lip) | `#231208` (`9px` text outline) | `#FFF7E6` (**`42px`**) | **`740×118px`** |
| **3. `🏅 PROFILE` (Left Half)** | **`#8C5227`** (Warm Timber Plank) | **`#4E2A10`** (`9px` dark oak lip) | `#231208` (`8px` text outline) | `#FCE7B2` (**`32px`**) | **`358×108px`** |
| **4. `⚙️ SETTINGS` (Right Half)** | **`#6E4223`** (Aged Walnut Plank) | **`#3D220E`** (`9px` dark walnut lip) | `#231208` (`8px` text outline) | `#FCE7B2` (**`32px`**) | **`358×108px`** |

### C. `MainHub` Scene Node Tree (`res://scenes/ui/main_hub.tscn`)
```text
MainHub (Control - Full Rect)
├── VillageHeroArt (TextureRect - res://assets/art/village_hub_bg.jpg, STRETCH_KEEP_ASPECT_COVERED)
├── BottomClearingShade (TextureRect - subtle bottom gradient for button pop)
├── SafeMargin (MarginContainer - auto-adjusted by UIThemeBuilder.apply_device_safe_area)
│   └── CenterWrap (HBoxContainer - alignment: CENTER)
│       └── MainColumn (VBoxContainer - min_width: 900px)
│           ├── TopStatusBar (PanelContainer - min_height: 104px)
│           │   └── TopHBox (HBoxContainer - separation: 14)
│           │       ├── BackToTitleBtn (Button - "⬅ Inicio")
│           │       ├── PointsBadgePanel (PanelContainer - EXPAND_FILL)
│           │       │   └── PointsBadge (Label - "🏆 Puntos: 0")
│           │       └── CoinsBadgePanel (PanelContainer - EXPAND_FILL)
│           │           └── CoinsBadge (Label - "🪙 Monedas: 250")
│           ├── ArtworkClearingSpacer (Control - size_flags_vertical: EXPAND_FILL, keeps middle 60% 100% open!)
│           └── ClearingButtonsWrap (CenterContainer - centers the 740px button cluster between the bottom bushes)
│               └── MenuButtonsBox (VBoxContainer - custom_minimum_size: 740x0, separation: 16)
│                   ├── PlayMatchButton (Button - 740x136, "🔨 ¡JUGAR!")
│                   ├── OpenStoreButton (Button - 740x118, "🛒 TIENDA")
│                   └── SecondaryRowHBox (HBoxContainer - separation: 20)
│                       ├── OpenProfileButton (Button - EXPAND_FILL, 358x108, "🏅 PERFIL")
│                       └── OpenSettingsButton (Button - EXPAND_FILL, 358x108, "⚙️ AJUSTES")
├── InfoModalBackdrop (ColorRect - hidden by default)
└── SettingsBackdrop (ColorRect - hidden by default)
```
- **Total height of `MenuButtonsBox`:** `136 + 16 + 118 + 16 + 108 = 394px` (down from `690px`!).
- On a `1920px` (or `2340px` Pixel 5) canvas, `394px` fits **100% inside the bottom sandy clearing (`Y = 1380 .. 1820`)**, leaving the waving Hard-Hat Mole, the minecarts, the stone bridge, and the village houses completely uncovered!

---

## 4. Acceptance Criteria Checklist

- [ ] **AC-M2.1-01:** `UIThemeBuilder.apply_device_safe_area()` pushes the top bar down on tall portrait/mobile screens (`>= 128px` top margin) so the Pixel 5 front-camera punch-hole never overlaps the `⬅ Title` / `⬅ Village` / `⬅ Back` button.
- [ ] **AC-M2.1-02:** In `Arena25D`, `IntroBannerCenter` is positioned directly below `TopBarPanel` near the top of the screen, leaving the 3×3 mole matrix completely unobstructed when the intro mole runs in and dives into the hole.
- [ ] **AC-M2.1-03:** `MainHub` uses `res://assets/art/village_hub_bg.jpg` (`fondo main hub celular concepto 2.jpg`), removes the redundant `"MOLE HUNTER VILLAGE"` banner, and arranges `PLAY!`, `STORE`, and side-by-side `PROFILE + SETTINGS` inside the bottom sandy clearing (`740px` wide) styled in warm rustic wood/amber/terracotta tones matching the artwork.

Please review [specs.md](file:///home/bioanim/.gemini/antigravity-cli/brain/21ea388a-0861-4126-ac7c-68f4bf0d2e3e/specs.md) and approve it when you're ready for me to execute **Step 3 (Implementation)**!
