# Step 2: Spec-Driven Technical Specification — Milestone 1.5 (UI Scale & Village Hub)

> [!IMPORTANT]
> **Strict 3-Step Workflow (`1. Plan` [Approved] → `2. Spec-Driven` [Current] → `3. Implementation`)**
> This document defines the exact technical specifications for **Milestone 1.5**. No project files have been modified yet. Once you approve `specs.md`, I will save a copy to `docs/specs/milestone_1_5_spec.md` and execute **Step 3 (Implementation)**.

---

## 1. SPEC-M1.5-01: Display & Typography Sizing Contract

To ensure every button and label is immediately readable without squinting on both Mobile and PC/Console:

### A. Viewport & Desktop Preview Window (`project.godot`)
- `window/size/viewport_width = 1080`
- `window/size/viewport_height = 1920`
- `window/size/window_width_override = 675` (up from `540`)
- `window/size/window_height_override = 1200` (up from `960`)
- `window/stretch/mode = "canvas_items"`
- `window/stretch/aspect = "expand"`

### B. Enlarged Typography & Button Dimension Table
| UI Element | Previous Size | **New Spec Size** | Outline / Minimum Height |
| :--- | :---: | :---: | :--- |
| **Game Title Logo (`TOPO SMASH`)** | `58px` | **`92px`** | `outline_size = 16`, shadow `(0, 8)` |
| **Game Subtitle (`CAOS CON CASCO`)** | `28px` | **`46px`** | `outline_size = 10`, shadow `(0, 5)` |
| **Title Tagline / Hints** | `16px–18px` | **`30px`** | `outline_size = 7` |
| **Hero Primary Button (`PLAY / INICIAR`)** | `26px–30px` (`76–86px` h) | **`50px`** | **`156px` min height**, `border_width_bottom = 12` |
| **Village Hub Menu Buttons (`STORE`, `PROFILE`, `SETTINGS`)** | `22px` (`66px` h) | **`42px`** | **`128px` min height**, `border_width_bottom = 10` |
| **Top Status Bar Badges (`Points`, `Coins`, `Back`, `Settings`)** | `16px–19px` (`38px` h) | **`34px`** | **`84px` min height**, pill radius `24px` |
| **Language `OptionButton` & PopupMenu Items** | `15px–16px` | **`32px`** | **`84px` min height** + `get_popup().add_theme_font_size_override("font_size", 32)` |
| **Store Tool Card Title** | `21px` | **`38px`** | `outline_size = 8` |
| **Store Tool Card Description** | `16px` | **`27px`** | `outline_size = 5` |
| **Store Tool Icon & Buy/Equip Button** | `76×76` / `18px` | **`124×124` icon / `34px` font** | **`112px` button height**, `270px` min width |

---

## 2. SPEC-M1.5-02: State & Persistence Contract (`GameManager`)

### A. Separate Points (🏆) & Coins (🪙) + Audio Settings
```gdscript
const STARTING_COINS: int = 250

var player_rank: int = 1
var total_points: int = 0        # 🏆 Score / Rank Points
var total_coins: int = 250       # 🪙 In-Game Store Currency
var matches_completed: int = 0

# Audio Settings (persisted in user://save_data.cfg under [audio])
var music_enabled: bool = true
var music_volume: float = 0.80   # Range 0.0 .. 1.0
var sfx_enabled: bool = true
var sfx_volume: float = 0.90     # Range 0.0 .. 1.0
```

### B. Store & Match Completion Methods
- `can_afford_tool(tool_id: String) -> bool`: Checks `total_coins >= int(t["cost"])`.
- `buy_tool(tool_id: String) -> bool`: Deducts `cost` from `total_coins`, appends `tool_id` to `owned_tools`, equips it, saves, and emits `state_changed`.
- `record_match_completed(points_earned: int = 100, coins_earned: int = 150) -> void`:
  - `matches_completed += 1`
  - `total_points += points_earned`
  - `total_coins += coins_earned`
  - `player_rank = 1 + matches_completed`
  - Saves and emits `state_changed`.
- `set_music_enabled(enabled: bool)`, `set_music_volume(vol: float)`, `set_sfx_enabled(enabled: bool)`, `set_sfx_volume(vol: float)`: Updates audio bus / state, persists to `user://save_data.cfg`, and emits `state_changed`.

---

## 3. SPEC-M1.5-03: 9-Language Translation Keys Contract (`TranslationsData`)

In addition to existing keys, the following keys MUST be present with 100% parity across all 9 locales (`es_419`, `es_ES`, `pt`, `fr`, `de`, `en`, `ko`, `ja`, `zh_CN`):

| Key | `es_419` (Main Default) | `en` (English Reference) |
| :--- | :--- | :--- |
| `LBL_COINS` | `"Monedas"` | `"Coins"` |
| `HUB_VILLAGE_TITLE` | `"🏡 ALDEA CAZA-TOPOS"` | `"🏡 MOLE HUNTER VILLAGE"` |
| `BTN_HUB_PLAY` | `"🔨 ¡JUGAR!"` | `"🔨 PLAY!"` |
| `BTN_HUB_STORE` | `"🛒 TIENDA"` | `"🛒 STORE"` |
| `BTN_HUB_PROFILE` | `"🏅 PERFIL Y RÉCORDS"` | `"🏅 PROFILE & SCORES"` |
| `BTN_HUB_SETTINGS` | `"⚙️ AJUSTES"` | `"⚙️ SETTINGS"` |
| `SETTINGS_TITLE` | `"⚙️ AJUSTES DEL JUEGO"` | `"⚙️ GAME SETTINGS"` |
| `LBL_MUSIC` | `"🎵 Música"` | `"🎵 Music"` |
| `LBL_SFX` | `"🔊 Efectos de Sonido"` | `"🔊 Sound Effects"` |
| `LBL_ON` | `"ENCENDIDO"` | `"ON"` |
| `LBL_OFF` | `"APAGADO"` | `"OFF"` |
| `BTN_CLOSE` | `"✖ CERRAR"` | `"✖ CLOSE"` |
| `PROFILE_SOON_TITLE` | `"🏅 PERFIL Y TABLA DE RÉCORDS"` | `"🏅 PROFILE & HIGH SCORES"` |
| `PROFILE_SOON_DESC` | `"¡Próximamente! Aquí podrás ver tus trofeos, estadísticas y récords.\n\n🏆 Puntos actuales: {points}\n🪙 Monedas actuales: {coins}\n⭐ Rango: {rank}"` | `"Coming Soon! View your trophies, stats, and high scores here.\n\n🏆 Current Points: {points}\n🪙 Current Coins: {coins}\n⭐ Rank: {rank}"` |

*(Store cost strings `BTN_BUY` and `LBL_NOT_ENOUGH_PTS` will display `🪙 {cost}` so they clearly represent Coins across all languages.)*

---

## 4. SPEC-M1.5-04: Friendly Procedural Village Backdrop & Settings Modal (`UIThemeBuilder`)

### A. `UIThemeBuilder.build_village_background() -> Control`
Constructs a full-screen (`PRESET_FULL_RECT`) cheerful 2D Village environment using 100% native Godot nodes (`TextureRect`, `Polygon2D`, `Panel`, `CPUParticles2D`):
1. **Sky Layer:** `GradientTexture2D` from warm sky blue (`#38BDF8`) at top to sunny horizon gold (`#FDE68A`).
2. **Sun & Animated Clouds:**
   - Bright golden sun disc (`Panel` with `corner_radius = 90`, color `#FACC15`) in top-left sky.
   - 3 fluffy white cloud clusters (`Panel` nodes with rounded corners) gently drifting horizontally via looping `Tween`.
3. **Rolling Green Hills & Village Meadow:**
   - Back hill (`Polygon2D`, `#4ADE80`) and front village lawn (`Polygon2D`, `#22C55E`).
   - Winding cobblestone/dirt village plaza path (`Polygon2D`, `#D97706` with warm border `#F59E0B`).
4. **Cozy Village Cottages & Wooden Fence:**
   - **Left Village Cottage:** Cream stucco wall (`#FEF3C7`), terracotta pitched roof (`Polygon2D` `#EA580C`), chimney, warm glowing window (`#FDE047`), and arched wooden door (`#78350F`).
   - **Right Village Tool Shop Cottage:** Warm wood wall (`#FDE68A`), emerald/teal pitched roof (`Polygon2D` `#0D9488`), striped awning, and shop window.
   - **Wooden Picket Fence:** Row of warm brown fence posts (`#92400E`) connecting the cottages across the horizon.

### B. `UIThemeBuilder.style_option_button(opt: OptionButton, font_size: int = 32)`
- Styles both the main `OptionButton` AND its internal `PopupMenu` (`var popup: PopupMenu = opt.get_popup()`):
  - `popup.add_theme_font_override("font", get_ui_font())`
  - `popup.add_theme_font_size_override("font_size", font_size)`
  - `popup.add_theme_constant_override("v_separation", 18)`
  - High-contrast dark wood `StyleBoxFlat` panel for the dropdown list so every language option is huge and easy to tap.

---

## 5. SPEC-M1.5-05: Scene Node Hierarchy Specifications

### Scene 1: Title Screen (`res://scenes/ui/title_screen.tscn`)
```text
TitleScreen (Control - Full Rect)
├── BackgroundHolder (Control - Full Rect, clip_contents = true)
│   └── HeroArt (TextureRect - res://assets/art/topo_hero.jpg)
├── VignetteOverlay (TextureRect - GradientTexture2D)
├── AmbientMotes (CPUParticles2D)
├── SafeMargin (MarginContainer - 36px margins)
│   └── CenterWrap (HBoxContainer - alignment: CENTER)
│       └── CenterColumn (VBoxContainer - min_width: 920px)
│           ├── TopBar (HBoxContainer - alignment: END)
│           │   └── OpenSettingsButton (Button - min_size: 280x86, "⚙️ AJUSTES / IDIOMA", 32px font)
│           ├── TopTitleBadge (PanelContainer)
│           │   └── TitleVBox (VBoxContainer)
│           │       ├── MainLogoLabel (Label - 92px font, "TOPO SMASH")
│           │       ├── SubLogoLabel (Label - 46px font, "CAOS CON CASCO")
│           │       └── TaglineLabel (Label - 30px font)
│           ├── Spacer (Control - EXPAND_FILL)
│           └── BottomActionBox (VBoxContainer)
│               ├── TapToStartButton (Button - min_size: 0x160, 52px font, "🔨 ¡PRESIONA PARA INICIAR!")
│               └── PlatformHintLabel (Label - 28px font)
└── SettingsBackdrop (ColorRect - hidden by default, modal overlay)
    └── ModalCenter (CenterContainer)
        └── SettingsModal (PanelContainer - min_width: 880px)
            └── SettingsVBox (VBoxContainer)
                ├── SettingsTitleLabel (Label - 46px font)
                ├── LangRow (VBoxContainer)
                │   ├── LangTitleLabel (Label - 34px font)
                │   └── LanguageOptionButton (OptionButton - min_height: 86px, 34px font)
                ├── MusicRow (VBoxContainer)
                │   ├── MusicHeaderHBox (HBoxContainer -> MusicLabel 34px + MusicToggleBtn 80px tall)
                │   └── MusicSlider (HSlider - min_height: 48px)
                ├── SfxRow (VBoxContainer)
                │   ├── SfxHeaderHBox (HBoxContainer -> SfxLabel 34px + SfxToggleBtn 80px tall)
                │   └── SfxSlider (HSlider - min_height: 48px)
                └── CloseSettingsButton (Button - min_height: 104px, 38px font)
```

---

### Scene 2: Village Main Hub (`res://scenes/ui/main_hub.tscn`)
Clean, sunny Village layout with **only** the Top Bar (`Back`, `Points`, `Coins`), the Village Plaza Sign, and the **4 big buttons** (`PLAY`, `STORE`, `PROFILE`, `SETTINGS`). Zero enemy spoilers or text walls.

```text
MainHub (Control - Full Rect)
├── VillageBackdropHolder (Control - Full Rect, populated by UIThemeBuilder.build_village_background())
├── SafeMargin (MarginContainer - 32px margins)
│   └── CenterWrap (HBoxContainer - alignment: CENTER)
│       └── MainColumn (VBoxContainer - min_width: 920px, separation: 24)
│           ├── TopStatusBar (PanelContainer - min_height: 104px)
│           │   └── TopHBox (HBoxContainer - separation: 18)
│           │       ├── BackToTitleBtn (Button - min_size: 180x80, 32px font, "⬅ Inicio")
│           │       ├── PointsBadgePanel (PanelContainer - EXPAND_FILL)
│           │       │   └── PointsBadge (Label - 36px font, "🏆 Puntos: 0")
│           │       └── CoinsBadgePanel (PanelContainer - EXPAND_FILL)
│           │           └── CoinsBadge (Label - 36px font, "🪙 Monedas: 250")
│           ├── TopSpacer (Control - EXPAND_FILL)
│           ├── VillageSignBanner (PanelContainer - cozy wooden signboard style)
│           │   └── VillageTitleLabel (Label - 46px font, "🏡 ALDEA CAZA-TOPOS")
│           ├── MenuButtonsBox (VBoxContainer - separation: 22)
│           │   ├── PlayMatchButton (Button - min_height: 164px, 52px font, Gold, "🔨 ¡JUGAR!")
│           │   ├── OpenStoreButton (Button - min_height: 136px, 44px font, Emerald, "🛒 TIENDA")
│           │   ├── OpenProfileButton (Button - min_height: 124px, 40px font, Royal Blue, "🏅 PERFIL Y RÉCORDS")
│           │   └── OpenSettingsButton (Button - min_height: 124px, 40px font, Warm Slate, "⚙️ AJUSTES")
│           └── BottomSpacer (Control - custom_minimum_size: 0x30)
├── InfoModalBackdrop (ColorRect - hidden by default; used for "Play Stage Ready" or "Profile Coming Soon" dialog with 38px/30px text)
└── SettingsBackdrop (ColorRect - hidden by default; same big-text Settings Modal for Language, Music, and SFX)
```

---

### Scene 3: In-Game Store Screen (`res://scenes/ui/store_screen.tscn`)
Updated with big `38px` tool titles, `27px` descriptions, `124×124` icons, `112px` tall Buy/Equip buttons, and `🪙 Monedas` currency header.

---

## 6. Acceptance Criteria for Step 3 Implementation

- [ ] **AC-M1.5-01:** All buttons and text across `TitleScreen`, `MainHub`, `SettingsModal`, and `StoreScreen` match the enlarged pixel sizes in Section 1B (minimum `27px–30px` for body text, `34px–52px` for buttons/badges, `92px` for title).
- [ ] **AC-M1.5-02:** Opening the Language dropdown displays the 9 languages in `32px` font so every item is easy to read and select.
- [ ] **AC-M1.5-03:** `MainHub` renders the sunny procedural Village background, displays **🏆 Points** and **🪙 Coins** in the top bar, and displays only the **4 big buttons** (`PLAY`, `STORE`, `PROFILE`, `SETTINGS`) with zero enemy spoilers.
- [ ] **AC-M1.5-04:** Clicking **⚙️ SETTINGS** on either `TitleScreen` or `MainHub` opens the big Settings Modal where the user can change the language (9 locales) and toggle/slide **🎵 Music** and **🔊 Sound Effects**.

Please review `specs.md` and approve it when you're ready for me to execute **Step 3 (Implementation)**!
