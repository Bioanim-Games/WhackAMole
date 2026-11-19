# Step 2: Spec-Driven Technical Specification — Milestone 3 (All 5 Mole Types, Traps, Hammer Stun & Projectiles)

> [!IMPORTANT]
> **Strict 3-Step Workflow (`1. Plan` [Approved] → `2. Spec-Driven` [Approved] → `3. Implementation`) & Git Rule**
> This standalone specification defines the exact data contracts, state machine transitions, 3D procedural node hierarchies, hammer stun timings, projectile types, and 9-language localization keys for **Milestone 3**.

---

## 1. Specification Overview & Subsystem IDs

| Spec ID | Subsystem | Responsibility |
| :--- | :--- | :--- |
| **SPEC-M3-01** | **Triangular Mole Unlocks & Weighted Spawner (`GameManager`)** | `get_unlocked_mole_ids()`, `pick_mole_type_for_spawn()` weighted selection across unlocked moles, and `unlock_all_moles_for_testing()` debug helper in `MainHub` Profile modal. |
| **SPEC-M3-02** | **5-Archetype 3D Mole Visuals (`Mole3D`)** | Pure-Godot `MeshInstance3D` attachments for `casco` (Hard Hat), `escudo` (Blue Helmet + Riot Shield), `ninja` (Stealth Suit + Red Headband + Shuriken + Substitution Log), `payaso` (Clown Wig + Red Nose + Trap Balloon + Pie), and `dorado` (Metallic Gold + Crown). |
| **SPEC-M3-03** | **Multi-Phase Mole State Machine (`Mole3D`)** | Phase transitions and exact durations for all 5 mole types, returning `WhackResult` (`HIT_SUCCESS`, `BLOCKED_BY_SHIELD`, `DODGED_BY_SPEED`, `TRIGGERED_STUN_TRAP`, `IGNORED`). |
| **SPEC-M3-04** | **2.0s Hammer Stun & Multi-Projectile System (`Arena25D`)** | `2.0s` player Hammer Stun when striking Ninja's Log (`🪵`) or Clown's Trap Balloon (`🎈`), color-coded hole status bars, and 3D Flying Projectiles (`rock`, `shuriken`, `pie`). |
| **SPEC-M3-05** | **9-Language i18n Parity (`TranslationsData`)** | 100% key parity across `es_419`, `es_ES`, `pt`, `fr`, `de`, `en`, `ko`, `ja`, and `zh_CN` for all new mole callouts, trap warnings, and debug unlock buttons. |

---

## 2. Detailed Subsystem Specifications

### SPEC-M3-01: Triangular Mole Unlocks & Weighted Spawner (`GameManager`)

#### A. Unlock Schedule & Rewards Contract
| Mole ID | Required Matches (`matches_completed`) | First Appears | Whack Points (`🏆`) | Whack Coins (`🪙`) | Projectile Type |
| :--- | :---: | :---: | :---: | :---: | :---: |
| `"casco"` | `0` | **Game #1** | `+100` | `+25` | `"rock"` (`🪨`) |
| `"escudo"` | `1` | **Game #2** (`+1`) | `+150` | `+35` | `"rock"` (`🪨`) |
| `"ninja"` | `3` | **Game #4** (`+2`) | `+200` | `+45` | `"shuriken"` (`⭐`) |
| `"payaso"` | `6` | **Game #7** (`+3`) | `+250` | `+55` | `"pie"` (`🥧`) |
| `"dorado"` | `10` | **Game #11** (`+4`) | **`+500`** | **`+150`** | `""` *(Never attacks)* |

#### B. Spawner Selection Contract: `GameManager.pick_mole_type_for_spawn() -> String`
1. Collect all unlocked mole definitions (`matches_completed >= required_matches`).
2. Assign spawn weights so the newest unlocked mole is prominently featured while earlier moles remain active:
   - `"casco"`: base weight `30`
   - `"escudo"`: base weight `28` (when unlocked)
   - `"ninja"`: base weight `26` (when unlocked)
   - `"payaso"`: base weight `24` (when unlocked)
   - `"dorado"`: base weight `14` (high-value golden bonus cameo when unlocked)
   - **Featured Stage Boost:** If a mole is the newest unlocked archetype for the current stage (`get_featured_mole_for_current_stage()["id"] == id`), add `+18` weight so the player immediately experiences their newly unlocked mole type!
3. Roll a weighted random choice and return its `id`.

#### C. Quick Testing Helper in Village Hub (`MainHub` Profile Modal)
- Inside the `🏅 PERFIL Y RÉCORDS` modal in `MainHub`, enable `info_reward_btn`:
  - If `matches_completed < 10`: Button displays `BTN_UNLOCK_ALL_TEST` (`"🔓 Desbloquear 5 Topos y 3 Filas (Prueba)"`) and calls `GameManager.unlock_all_moles_for_testing()`, setting `matches_completed = 10`, `player_rank = 11`, `total_coins += 500` so all 5 mole types and all 9 holes (3×3 matrix) can be tested immediately on PC or Pixel 5.
  - If `matches_completed >= 10`: Button displays `BTN_SIM_WIN_REWARD` (`"🏆 Ganar Partida (+100 Pts / +150 🪙)"`).

---

### SPEC-M3-02 & 03: Multi-Archetype `Mole3D` Visuals & Phase State Machine

#### A. Extended `Mole3D.State` & `Mole3D.WhackResult` Enums
```gdscript
enum State {
	HIDDEN,
	WALK_IN,
	EMERGING,
	EXPOSED,              # Vulnerable (Casco, Escudo Phase 1 & 3, Dorado)
	SHIELD_UP,            # Escudo Phase 2 (3.0s): Invulnerable riot shield raised
	NINJA_DASH,           # Ninja Phase 1 (2.0s): Untouchable high-speed oscillation
	NINJA_SHURIKEN,       # Ninja Phase 2 (3.0s): Vulnerable while charging shuriken
	NINJA_LOG_DECOY,      # Ninja Phase 3 (1.0s): Substitution Log trap (stuns player 2.0s if hit!)
	CLOWN_BALLOON_TRAP,   # Payaso Phase 1 (2.5s): Red Balloon trap (stuns player 2.0s if hit!)
	CLOWN_SELF_STUNNED,   # Payaso Phase 2 (3.0s): Dizzy after popping own balloon (Vulnerable!)
	THROWING_ROCK,        # Throws rock / shuriken / pie
	TAUNTING,             # 2.0s laugh
	HIT_OUCH,             # Whacked squash reaction
	RETREATING,
}

enum WhackResult {
	IGNORED,
	HIT_SUCCESS,
	BLOCKED_BY_SHIELD,
	DODGED_BY_SPEED,
	TRIGGERED_STUN_TRAP,
}
```

---

### SPEC-M3-04: 2.0s Hammer Stun, Hole Bars & Multi-Projectiles (`Arena25D`)

- **Player Hammer Stun (`2.0s`):** Triggered when hitting Ninja's Log (`🪵`) or Clown's Trap Balloon (`🎈`). Disables hole hammer strikes for `2.0s` and shows a live countdown banner `"⚡ ¡MARTILLO ATURDIDO! (1.8s)"` while allowing rock/shuriken/pie deflection.
- **Color-Coded Hole Status Bars:**
  - Green/Orange/Red: Vulnerable (`EXPOSED`, `NINJA_SHURIKEN`, `CLOWN_SELF_STUNNED`)
  - Gold (`#FFD700`): Golden Mole (`dorado`)
  - Steel Blue (`#3498DB`): Invulnerable Defense (`SHIELD_UP`, `NINJA_DASH`)
  - Warning Purple (`#AF7AC5`): Counter-Trap (`NINJA_LOG_DECOY`, `CLOWN_BALLOON_TRAP`)
- **3D Projectiles (`"rock"`, `"shuriken"`, `"pie"`):** Tracked by the `240×240px` tap target button and bottom `🛡️ ESQUIVAR` button.
