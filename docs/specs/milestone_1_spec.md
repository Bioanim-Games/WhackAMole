# Step 2: Spec-Driven Technical Specification — Milestone 1

> [!IMPORTANT]
> **3-Step Workflow Enforcement (`1. Plan` → `2. Spec-Driven` → `3. Implementation`)**
> This document is the dedicated **Step 2: Spec-Driven Specification** for Milestone 1 (stored both in the brain artifact directory and in the repository at [docs/specs/milestone_1_spec.md](file:///mnt/c/Users/jmarc/Documents/Godot/Games/whack-a-mole/whack-a-mole/docs/specs/milestone_1_spec.md)). For Milestone 2 and beyond, we will always generate and review `specs.md` as a separate step *after* `implementation_plan.md` is approved and *before* any implementation begins.

---

## 1. Specification Overview & Scope (Milestone 1)

| Spec ID | Subsystem | Responsibility |
| :--- | :--- | :--- |
| **SPEC-M1-01** | `LocalizationManager` & `TranslationsData` | 9-language i18n catalog (`es_419` primary fallback, `es_ES`, `pt`, `fr`, `de`, `en`, `ko`, `ja`, `zh_CN`) + automatic OS locale detection (`OS.get_locale()`) on first install of `.apk`/app. |
| **SPEC-M1-02** | `GameManager` | Persistent progression state (`user://save_data.cfg`), PvZ-style 1→2→3 lane unlock schedule, triangular mole unlock schedule (`+1, +2, +3, +4` matches), Rank difficulty scaling (`5.0s` base exposure), and Store purchase/equip logic. |
| **SPEC-M1-03** | `UIThemeBuilder` | Pure-Godot procedural `StyleBoxFlat`, CJK-compatible `SystemFont`, and procedural node avatars (`Control`, `Panel`, `Polygon2D`) for the 5 Moles and 4 Tools. |
| **SPEC-M1-04** | `TitleScreen` (`title_screen.tscn`) | Full-bleed `topo_hero.jpg` background with breathing zoom `Tween`, vignette overlay, rising `CPUParticles2D`, live 9-language selector, and start button. |
| **SPEC-M1-05** | `MainHub` (`main_hub.tscn`) | Top status bar, PvZ 3-lane lawn blueprint visualizer, 5-mole unlock roster, level briefing card, Play preview modal, Store navigation, and test progression simulator bar. |
| **SPEC-M1-06** | `StoreScreen` (`store_screen.tscn`) | Interactive In-Game Store for the 4 Anti-Mole Tools + 5 Multimartillo strike pattern selector buttons. |

---

## 2. Detailed Subsystem Specifications

### SPEC-M1-01: Internationalization & Device Locale Auto-Detection

#### A. Supported Locales Contract
1. `es_419` — Español (Latinoamérica) **[Default / Global Fallback]**
2. `es_ES` — Español (España)
3. `pt` — Português
4. `fr` — Français
5. `de` — Deutsch
6. `en` — English
7. `ko` — 한국어
8. `ja` — 日本語
9. `zh_CN` — 简体中文

#### B. Pure Function Contract: `map_os_locale_to_supported(raw_locale: String) -> String`
- Normalize `raw_locale` via `.strip_edges().replace("-", "_").to_lower()`.
- If `lower == "es_es"` or `lower.begins_with("es_es_")` → return `"es_ES"`.
- Else if `lower == "es"` or `lower.begins_with("es_")` → return `"es_419"`.
- Else if `lower` begins with `"pt"`, `"fr"`, `"de"`, `"en"`, `"ko"`, `"ja"` → return the corresponding 2-letter code.
- Else if `lower` begins with `"zh"` → return `"zh_CN"`.
- Else → return `"es_419"`.

#### C. Persistence Contract (`user://settings.cfg`)
- Section `"i18n"`, key `"locale"`.
- On `_ready()`: if `"locale"` exists in `user://settings.cfg` and is in `TranslationsData.CATALOG`, load it; otherwise run `map_os_locale_to_supported(OS.get_locale())` and persist immediately.

---

### SPEC-M1-02: Progression, PvZ Lanes & Triangular Mole Unlocks (`GameManager`)

#### A. PvZ-Style Lane Unlock Formula
The 3×3 matrix consists of 3 horizontal rows (`TopRow`, `CenterRow`, `BottomRow`), each holding 3 holes:
- `matches_completed in [0, 1]` (Games 1–2): **1 Lane active (3 holes)** → `[false, true, false]` (Center training strip).
- `matches_completed in [2, 3, 4]` (Games 3–5): **2 Lanes active (6 holes)** → `[false, true, true]`.
- `matches_completed >= 5` (Game 6+): **3 Lanes active (9 holes)** → `[true, true, true]`.

#### B. Triangular Mole Unlock Schedule (`+1, +2, +3, +4` games)
| Mole ID | Name Key | Required Matches Completed | First Appears in Game # | Delta from Previous Unlock |
| :--- | :--- | :---: | :---: | :---: |
| `casco` | `MOLE_CASCO_NAME` | `0` | **Game #1** | Base |
| `escudo` | `MOLE_ESCUDO_NAME` | `1` | **Game #2** | `+1 game` |
| `ninja` | `MOLE_NINJA_NAME` | `3` | **Game #4** | `+2 games` |
| `payaso` | `MOLE_PAYASO_NAME` | `6` | **Game #7** | `+3 games` |
| `dorado` | `MOLE_DORADO_NAME` | `10` | **Game #11** | `+4 games` |

#### C. Mole Exposure Difficulty Formula
- Base exposure time at Rank 1 = `5.0` seconds (before throwing a rock at the screen and taunting for `2.0` seconds).
- Formula: `snappedf(maxf(1.8, 5.0 - float(player_rank - 1) * 0.25), 0.1)`.

---

### SPEC-M1-03 to SPEC-M1-06: Godot 4.7 UI Node & API Constraints

- **BoxContainer Alignment Constraint:** Godot 4 `BoxContainer` supports only `ALIGNMENT_BEGIN` (0), `ALIGNMENT_CENTER` (1), and `ALIGNMENT_END` (2). Space-between layouts in `HBoxContainer` must use `size_flags_horizontal = Control.SIZE_EXPAND_FILL` on expanding children rather than CSS-style `ALIGNMENT_BETWEEN`.
- **Responsive Viewport Contract:**
  - Base viewport: `1080×1920` (Portrait).
  - Window override for desktop testing: `540×960`.
  - Stretch mode: `canvas_items`, Aspect: `expand` (centers the `920px` safe column cleanly when resized to 16:9 widescreen on PC/Console).
- **Controller / Keyboard Focus Contract:**
  - Every screen calls `.grab_focus()` on its primary action button in `_ready()` and when closing modals.

---

## 3. Acceptance Criteria Checklist

- [x] **AC-01:** Launching the project opens `TitleScreen` displaying `topo_hero.jpg` with breathing animation, particles, and localized text.
- [x] **AC-02:** Switching any of the 9 languages in the `OptionButton` updates all visible labels immediately and persists to `user://settings.cfg`.
- [x] **AC-03:** Clicking the Start button transitions to `MainHub` without any GDScript parse or runtime errors.
- [x] **AC-04:** Clicking `+1 Match Won (+150 pts)` on `MainHub` increments `matches_completed`, updates Rank and exposure timer, expands the PvZ lawn rows (`1 → 2 → 3`), and unlocks moles at Games `#2, #4, #7, #11`.
- [x] **AC-05:** Clicking the Store button opens `StoreScreen`, allowing the user to buy/equip tools and change the 5 Multimartillo strike patterns.
