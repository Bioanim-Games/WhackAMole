# Project Rules — Whack-a-Mole 2.5D (Topo Smash: Hard Hat Havoc)

## 1. 9-Language Internationalization (i18n) & Device Locale Auto-Detection
- Every user-facing string in any UI screen, HUD, modal, mole description, or store item MUST be localized in `res://scripts/data/translations_data.gd` with 100% key parity across all **9 required languages**:
  1. `es_419` — Español (Latinoamérica) **[Primary / Default Global Fallback]**
  2. `es_ES` — Español (España)
  3. `pt` — Português
  4. `fr` — Français
  5. `de` — Deutsch
  6. `en` — English
  7. `ko` — 한국어 (Korean)
  8. `ja` — 日本語 (Japanese)
  9. `zh_CN` — 简体中文 (Chinese Simplified)
- On first install / first launch of the `.apk` or app (when no user override exists in `user://settings.cfg`), `LocalizationManager` must detect the device language via `OS.get_locale()`, map `es_ES` to Spain, any other `es_*` to `es_419`, match `pt`/`fr`/`de`/`en`/`ko`/`ja`/`zh`, and fall back to `es_419`.
- All UI fonts must use `UIThemeBuilder.get_ui_font()` with CJK system font fallbacks so Korean, Japanese, and Simplified Chinese render without missing glyphs.

## 2. Mobile Front-Camera Safe-Area & Large Mobile-Arcade Typography (Pixel 5 Standard)
- **Physical Front-Camera Cutout / Notch Avoidance**:
  - Every full-screen UI scene (`TitleScreen`, `MainHub`, `StoreScreen`, `Arena25D`, and any future screen) MUST call `UIThemeBuilder.apply_device_safe_area(safe_margin)` in `_ready()` and on `get_viewport().size_changed`.
  - Queries `DisplayServer.get_display_safe_area()` and enforces a minimum `128px` top safe inset (and `64px` bottom inset) on mobile/tall portrait screens (`19.5:9` like the Pixel 5) so the top-left physical front camera never overlaps top-bar buttons or badges.
- **Large, High-Contrast Mobile-Arcade Typography & Buttons**:
  - Design for effortless readability on mobile portrait (`1080x1920` base viewport) without squinting:
    - Main Title / Logos: `88px–92px` (Subtitles: `44px–48px`)
    - Primary Action Buttons: `48px–52px` font, `136px–164px` minimum height
    - Secondary Menu / Store Buttons: `32px–42px` font, `108px–136px` minimum height
    - Top Status Bar Badges & Body Text: `27px–38px` font with dark outlines (`outline_size >= 6`)
    - `OptionButton` & `PopupMenu` Dropdown Items: `32px–34px` font via `UIThemeBuilder.style_option_button()`.
- **Unobstructed Gameplay View**:
  - In `Arena25D`, announcement banners must be docked near the top (below the Top HUD bar) so they never block the 3x3 mole matrix or the intro mole walk-in animation.
  - Portrait 3D camera must use `Camera3D.KEEP_WIDTH` so all 3 columns of holes always fit inside narrow portrait screens (like the Pixel 5) with comfortable side margins.
