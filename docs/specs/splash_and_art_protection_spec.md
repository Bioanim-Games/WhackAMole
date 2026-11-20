# Step 2: Technical Specification (`specs.md`) — Godot Boot Splash, Bioanim Studio Splash & GitHub Art Protection

## 1. Scope & Overview
This specification defines:
1. **`project.godot` Boot & Main Scene Configuration**: Restoring the native built-in **Godot Engine** boot splash and routing app startup to `res://scenes/ui/splash_screen.tscn`.
2. **Bioanim Games Studio Splash Screen (`splash_screen.tscn` & `splash_screen.gd`)**: Displaying `res://assets/art/bioanim_splash.webp` (`572x1024`, ~9:16 portrait) right after the Godot boot splash with fade-in/hold/fade-out transitions and input skip support.
3. **Resilient Art Loading When Cloned Without Art**: Because `/assets/art/` will be excluded from GitHub via `.gitignore`, scenes referencing art (`splash_screen.gd`, `title_screen.gd`, `main_hub.gd`) must safely check `ResourceLoader.exists()` at runtime so the project never crashes if opened on a clean clone without the local art files.
4. **Git & GitHub Art Purge on `develop`**: Exact `.gitignore` rules and `git filter-branch` history rewrite contract on `develop` (leaving `master` and `develop-clone` completely untouched).

---

## 2. Engine Configuration (`project.godot`)

### 2.1 `[application]` Section Contract
| Key | Old Value | New Value | Purpose |
| :--- | :--- | :--- | :--- |
| `run/main_scene` | `"res://scenes/ui/title_screen.tscn"` | `"res://scenes/ui/splash_screen.tscn"` | Launches Bioanim Studio Splash right after Godot boot screen |
| `boot_splash/bg_color` | `Color(0.08, 0.06, 0.04, 1)` | *(Removed)* | Uses Godot's default boot splash background |
| `boot_splash/image` | `"res://icon.webp"` | *(Removed)* | Restores the built-in **Godot Engine** logo on app launch |
| `config/icon` | `"res://icon.webp"` | `"res://icon.webp"` | Preserves the custom app launcher icon |

---

## 3. Bioanim Games Studio Splash Screen Specification

### 3.1 Node Hierarchy (`res://scenes/ui/splash_screen.tscn`)
```text
SplashScreen (Control) [anchors_preset = 15 (Full Rect), script = res://scripts/ui/splash_screen.gd]
├── Background (ColorRect) [anchors_preset = 15, color = Color(0.03, 0.03, 0.04, 1.0)]
├── LogoTexture (TextureRect) [anchors_preset = 15, expand_mode = 1 (EXPAND_IGNORE_SIZE), stretch_mode = 6 (STRETCH_KEEP_ASPECT_COVERED)]
└── FadeOverlay (ColorRect) [anchors_preset = 15, mouse_filter = 2 (MOUSE_FILTER_IGNORE), color = Color(0, 0, 0, 1.0)]
```

### 3.2 Script Contract (`res://scripts/ui/splash_screen.gd`)
- **Constants**:
  - `LOGO_PATH: String = "res://assets/art/bioanim_splash.webp"`
  - `NEXT_SCENE_PATH: String = "res://scenes/ui/title_screen.tscn"`
  - `FADE_IN_DURATION: float = 0.55`
  - `HOLD_DURATION: float = 1.85`
  - `FADE_OUT_DURATION: float = 0.50`
  - `SKIP_UNLOCK_DELAY: float = 0.35`
- **Lifecycle & Behavior**:
  1. In `_ready()`:
     - If `ResourceLoader.exists(LOGO_PATH)`, loads and assigns `ResourceLoader.load(LOGO_PATH)` to `logo_texture.texture`.
     - Initializes `fade_overlay.color = Color(0, 0, 0, 1.0)` and `logo_texture.scale = Vector2(1.0, 1.0)`.
     - Creates a sequence `Tween`:
       - Tweens `fade_overlay.color:a` from `1.0` to `0.0` over `FADE_IN_DURATION` (`TRANS_SINE`, `EASE_OUT`).
       - Intervals for `HOLD_DURATION`.
       - Tweens `fade_overlay.color:a` from `0.0` to `1.0` over `FADE_OUT_DURATION` (`TRANS_SINE`, `EASE_IN`).
       - Calls `_go_to_title_screen()`.
  2. In `_input(event: InputEvent)`:
     - After `SKIP_UNLOCK_DELAY` has elapsed, any mouse button press, screen touch (`InputEventScreenTouch`), or `ui_accept` / `ui_select` key press immediately kills the active tween, fades out over `0.2s`, and calls `_go_to_title_screen()`.

---

## 4. Git-Ignored Art Resilience in `title_screen.tscn` & `main_hub.tscn`
Because `/assets/art/` is ignored by Git:
- In `scenes/ui/title_screen.tscn` and `scenes/ui/main_hub.tscn`, instead of hardcoding `[ext_resource type="Texture2D" path="res://assets/art/..."]` in the `.tscn` header (which would cause a missing resource error if someone clones the repo from GitHub without the art folder), the textures are loaded in `_ready()` if `ResourceLoader.exists("res://assets/art/...")` is `true`:
  - `title_screen.gd`: Loads `"res://assets/art/topo_hero.jpg"` into `hero_art.texture` when present on disk.
  - `main_hub.gd`: Loads `"res://assets/art/village_hub_bg.jpg"` into `hub_bg.texture` when present on disk.

---

## 5. Git Ignore & GitHub History Purge Contract

### 5.1 `.gitignore` Specification
```gitignore
# Godot 4+ specific ignores
.godot/
/android/

# Proprietary Art & Custom App Icons (Local only - never push to GitHub)
/assets/art/
/icon.webp
/icon.webp.import
```

### 5.2 History Rewrite & Remote Push Specification (`develop` Branch Only)
1. **Branch Safety Guard**:
   - Record commit SHA of `master` (`a16b528`) and `develop-clone` (`c7a76aa`).
   - Do **not** check out, modify, or push `master` or `develop-clone`.
2. **Local Art Backup**:
   - Copy `/assets/art/*` and `icon.webp*` to `/tmp/topo_art_backup/`.
3. **Purge Art from `develop` History**:
   - Run `git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch -r assets/art icon.webp icon.webp.import _gen_icons_tmp.gd _gen_icons_tmp.gd.uid' --prune-empty master..develop` so no commit on `develop` contains any proprietary art binary.
4. **Restore Local Art on Disk**:
   - Copy `/tmp/topo_art_backup/*` back into `assets/art/` and `icon.webp*` in the project directory.
   - Because `.gitignore` ignores `/assets/art/` and `/icon.webp*`, `git status` will confirm they are completely untracked by Git while remaining available to Godot on your machine.
5. **Replace `develop` on GitHub**:
   - Delete `develop` on `origin` and push the cleaned `develop` branch (as explicitly requested by the user).

---

## 6. Acceptance Criteria
- [ ] Opening the app displays the default **Godot Engine** screen first, followed immediately by the **Bioanim Games** full-screen portrait logo (`assets/art/bioanim_splash.webp`), and then transitions to `TitleScreen`.
- [ ] Tapping or pressing Enter during the Bioanim splash screen smoothly skips to `TitleScreen`.
- [ ] `git log --stat master..develop` contains zero references to `assets/art/` or `icon.webp`.
- [ ] `master` and `develop-clone` remain 100% untouched.
- [ ] All art files (`bioanim_splash.webp`, `topo_hero.jpg`, `village_hub_bg.jpg`, `icon.webp`) remain intact on the local filesystem and are ignored by Git.
