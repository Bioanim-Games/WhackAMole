# Step 2 — Spec-Driven Technical Specification (`specs.md`): Custom App Miniature & Android Launcher Icons

## 1. Overview
This specification defines the exact asset pipeline, dimensions, and Godot configuration contracts for replacing the default Godot placeholder icon with the custom artwork (`C:\Users\jmarc\Documents\Godot\Games\whack-a-mole\miniatura para app.webp`) across desktop and Android exports.

---

## 2. Asset Pipeline & Exact Dimensions

| Target Resource Path | Source | Format | Exact Dimensions | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `res://icon.webp` | `miniatura para app.webp` | WebP | `1024 × 1024 px` | Primary Godot project icon (`config/icon`) & boot splash icon |
| `res://assets/art/icons/launcher_main_192x192.png` | Downscaled (Lanczos) from `miniatura para app.webp` | PNG (RGBA) | `192 × 192 px` | Android `launcher_icons/main_192x192` |
| `res://assets/art/icons/launcher_adaptive_foreground_432x432.png` | Centered `312 × 312 px` artwork inside `432 × 432 px` safe zone (with full-bleed edge extension so circular/squircle masks never clip key art or reveal blank edges) | PNG (RGBA) | `432 × 432 px` | Android `launcher_icons/adaptive_foreground_432x432` |
| `res://assets/art/icons/launcher_adaptive_background_432x432.png` | Solid dark construction-theme background (`#19120C`) | PNG (RGBA) | `432 × 432 px` | Android `launcher_icons/adaptive_background_432x432` |

---

## 3. Configuration File Contracts

### 3.1 [project.godot](file:///mnt/c/Users/jmarc/Documents/Godot/Games/whack-a-mole/whack-a-mole/project.godot)
Under `[application]`:
```ini
[application]

config/name="Topo Smash: Hard Hat Havoc"
run/main_scene="res://scenes/ui/title_screen.tscn"
config/features=PackedStringArray("4.7", "Forward Plus")
boot_splash/bg_color=Color(0.08, 0.06, 0.04, 1)
boot_splash/image="res://icon.webp"
config/icon="res://icon.webp"
```

### 3.2 [export_presets.cfg](file:///mnt/c/Users/jmarc/Documents/Godot/Games/whack-a-mole/whack-a-mole/export_presets.cfg)
Under `[preset.0.options]` (Android preset `"WhackAMole"`):
```ini
launcher_icons/main_192x192="res://assets/art/icons/launcher_main_192x192.png"
launcher_icons/adaptive_foreground_432x432="res://assets/art/icons/launcher_adaptive_foreground_432x432.png"
launcher_icons/adaptive_background_432x432="res://assets/art/icons/launcher_adaptive_background_432x432.png"
launcher_icons/adaptive_monochrome_432x432=""
```
And under splash screen options:
```ini
splash_screen/icon="res://assets/art/icons/launcher_main_192x192.png"
```

---

## 4. Acceptance Criteria
1. `res://icon.webp` and `res://assets/art/icons/*.png` exist in the repository with valid Godot `.import` metadata files generated via a headless Godot import check.
2. `project.godot` points `config/icon` and `boot_splash/image` to `res://icon.webp`.
3. `export_presets.cfg` points Android `main_192x192`, `adaptive_foreground_432x432`, `adaptive_background_432x432`, and `splash_screen/icon` to the newly generated icon resources.
4. No files are committed or pushed to Git (`git status` shows all changes in the working tree).
