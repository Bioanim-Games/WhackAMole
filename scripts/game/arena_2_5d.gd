extends Node3D

## 2.5D Backyard Arena implementing Milestone 2 & Milestone 3 (SPEC-M2-01..06 & SPEC-M3-01..05):
## - Responsive Portrait (Pixel 5 19.5:9) & Widescreen camera framing
## - Full-screen anchored HUDRoot inside CanvasLayer with huge readable buttons/panels
## - 3x3 Hole Matrix with PvZ-style 1-to-3 lane rollout
## - Introductory off-screen Mole walk-in & head-first dive into nearest active hole
## - All 5 Mole Archetypes ("casco", "escudo", "ninja", "payaso", "dorado") with multi-phase state machine
## - 2.0s Hammer Stun when striking Ninja's Substitution Log or Clown's Trap Balloon
## - Interactive 0.95s 3D Projectiles ("rock", "shuriken", "pie") & Evasion/Deflection

const MAIN_HUB_SCENE_PATH: String = "res://scenes/ui/main_hub.tscn"
const ROUND_DURATION_SECONDS: float = 45.0
const MAX_SCREEN_HEARTS: int = 3
const ROCK_FLIGHT_DURATION: float = 0.95
const HAMMER_STUN_DURATION: float = 2.0
const POINTS_PER_EVADE: int = 25

enum MatchState {
	INTRO,
	PLAYING,
	VICTORY,
	DEFEAT,
}

@onready var camera_3d: Camera3D = $Camera3D
@onready var lawn_ground_mesh: MeshInstance3D = $Environment3D/LawnGroundMesh
@onready var dirt_border_mesh: MeshInstance3D = $Environment3D/DirtBorderMesh
@onready var fence_back_mesh: MeshInstance3D = $Environment3D/FenceBackMesh
@onready var bush_left_mesh: MeshInstance3D = $Environment3D/BushLeftMesh
@onready var bush_right_mesh: MeshInstance3D = $Environment3D/BushRightMesh

@onready var holes_grid: Node3D = $HolesGrid
@onready var intro_mole: Mole3D = $IntroMole
@onready var hammer_3d: Hammer3D = $Hammer3D
@onready var projectiles_root: Node3D = $Projectiles3D

@onready var hud_root: Control = $HUD/HUDRoot
@onready var safe_margin: MarginContainer = $HUD/HUDRoot/SafeMargin
@onready var cracks_layer: Control = $HUD/HUDRoot/CracksLayer
@onready var timer_bars_layer: Control = $HUD/HUDRoot/TimerBarsLayer
@onready var flying_rocks_ui_layer: Control = $HUD/HUDRoot/FlyingRocksUILayer
@onready var callouts_layer: Control = $HUD/HUDRoot/CalloutsLayer

@onready var top_hud_panel: PanelContainer = $HUD/HUDRoot/SafeMargin/MainHUDVBox/TopBarPanel
@onready var exit_btn: Button = $HUD/HUDRoot/SafeMargin/MainHUDVBox/TopBarPanel/TopHBox/ExitVillageBtn
@onready var timer_label: Label = $HUD/HUDRoot/SafeMargin/MainHUDVBox/TopBarPanel/TopHBox/TimerBadge
@onready var hearts_label: Label = $HUD/HUDRoot/SafeMargin/MainHUDVBox/TopBarPanel/TopHBox/HeartsBadge
@onready var score_label: Label = $HUD/HUDRoot/SafeMargin/MainHUDVBox/TopBarPanel/TopHBox/ScoreBadge

@onready var intro_banner_panel: PanelContainer = $HUD/HUDRoot/SafeMargin/MainHUDVBox/IntroBannerCenter/IntroBannerPanel
@onready var intro_banner_label: Label = $HUD/HUDRoot/SafeMargin/MainHUDVBox/IntroBannerCenter/IntroBannerPanel/IntroBannerLabel

@onready var evade_button: Button = $HUD/HUDRoot/SafeMargin/MainHUDVBox/BottomEvadeBox/EvadeRockButton

@onready var summary_backdrop: ColorRect = $HUD/HUDRoot/SummaryBackdrop
@onready var summary_card: PanelContainer = $HUD/HUDRoot/SummaryBackdrop/SummaryCenter/SummaryCard
@onready var summary_title_lbl: Label = $HUD/HUDRoot/SummaryBackdrop/SummaryCenter/SummaryCard/SummaryVBox/SummaryTitleLabel
@onready var summary_stats_lbl: Label = $HUD/HUDRoot/SummaryBackdrop/SummaryCenter/SummaryCard/SummaryVBox/SummaryStatsLabel
@onready var summary_next_btn: Button = $HUD/HUDRoot/SummaryBackdrop/SummaryCenter/SummaryCard/SummaryVBox/SummaryNextButton
@onready var summary_village_btn: Button = $HUD/HUDRoot/SummaryBackdrop/SummaryCenter/SummaryCard/SummaryVBox/SummaryVillageButton

var match_state: MatchState = MatchState.INTRO
var holes: Array[Hole3D] = []
var time_remaining: float = ROUND_DURATION_SECONDS
var screen_hearts: int = MAX_SCREEN_HEARTS
var round_points: int = 0
var round_coins: int = 0
var moles_whacked_count: int = 0
var rocks_evaded_count: int = 0

var _spawn_cooldown: float = 0.7
var _hammer_stun_remaining: float = 0.0
var _base_camera_pos: Vector3 = Vector3(0.0, 10.8, 9.2)
var _shake_time: float = 0.0
var _shake_intensity: float = 0.0

var _flying_rocks: Array[Dictionary] = []
var _hole_timer_bars: Array[ProgressBar] = []


func _ready() -> void:
	_update_camera_framing()
	get_viewport().size_changed.connect(_update_camera_framing)
	_apply_3d_environment_materials()
	_apply_hud_styles()
	_setup_holes_matrix()

	exit_btn.pressed.connect(_on_exit_pressed)
	evade_button.pressed.connect(_on_evade_button_pressed)
	summary_next_btn.pressed.connect(_on_summary_next_pressed)
	summary_village_btn.pressed.connect(_on_summary_village_pressed)
	intro_mole.intro_walk_finished.connect(_on_intro_walk_finished)

	_start_new_round()


## Dynamically adapts Camera3D distance & aspect mode so all 3 columns (X = -1.8..+1.8)
## and all 3 rows (Z = -1.95..+1.95) fit comfortably on tall mobile screens (like Pixel 5 19.5:9)
## as well as PC/Console widescreen monitors.
func _update_camera_framing() -> void:
	UIThemeBuilder.apply_device_safe_area(safe_margin, 24, 32, 24, 44)
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	if vp_size.y <= 1.0:
		return
	var aspect: float = vp_size.x / vp_size.y
	if aspect < 0.75:
		camera_3d.keep_aspect = Camera3D.KEEP_WIDTH
		camera_3d.fov = 34.0
		_base_camera_pos = Vector3(0.0, 10.6, 9.0)
	else:
		camera_3d.keep_aspect = Camera3D.KEEP_HEIGHT
		camera_3d.fov = 44.0
		_base_camera_pos = Vector3(0.0, 9.6, 8.2)
	camera_3d.position = _base_camera_pos


func _unhandled_input(event: InputEvent) -> void:
	if match_state != MatchState.PLAYING:
		return
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			if ke.keycode == KEY_SPACE or ke.keycode == KEY_SHIFT:
				_try_evade_oldest_rock()
	elif event is InputEventJoypadButton:
		var jb := event as InputEventJoypadButton
		if jb.pressed and (jb.button_index == JOY_BUTTON_B or jb.button_index == JOY_BUTTON_X):
			_try_evade_oldest_rock()


func _process(delta: float) -> void:
	_update_camera_shake(delta)
	_update_hole_exposure_bars()

	if match_state != MatchState.PLAYING:
		return

	if _hammer_stun_remaining > 0.0:
		_hammer_stun_remaining = maxf(0.0, _hammer_stun_remaining - delta)
		if _hammer_stun_remaining > 0.0:
			intro_banner_panel.visible = true
			intro_banner_label.text = LocalizationManager.t(
				"ARENA_BANNER_STUNNED",
				{"sec": "%.1f" % _hammer_stun_remaining}
			)
		else:
			intro_banner_panel.visible = false

	time_remaining = maxf(0.0, time_remaining - delta)
	_refresh_top_hud()
	if time_remaining <= 0.0:
		_trigger_round_end(true)
		return

	_spawn_cooldown -= delta
	if _spawn_cooldown <= 0.0:
		_try_spawn_random_mole()

	_update_flying_rocks(delta)


func _apply_3d_environment_materials() -> void:
	var grass_mat := StandardMaterial3D.new()
	grass_mat.albedo_color = Color("#2ECC71")
	grass_mat.roughness = 0.88
	lawn_ground_mesh.material_override = grass_mat

	var border_mat := StandardMaterial3D.new()
	border_mat.albedo_color = Color("#5D3A1A")
	border_mat.roughness = 0.92
	dirt_border_mesh.material_override = border_mat

	var fence_mat := StandardMaterial3D.new()
	fence_mat.albedo_color = Color("#935116")
	fence_mat.roughness = 0.85
	fence_back_mesh.material_override = fence_mat

	var bush_mat := StandardMaterial3D.new()
	bush_mat.albedo_color = Color("#1E8449")
	bush_mat.roughness = 0.86
	bush_left_mesh.material_override = bush_mat
	bush_right_mesh.material_override = bush_mat


func _apply_hud_styles() -> void:
	top_hud_panel.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.12, 0.08, 0.05, 0.95), Color("#FFB800"), 28, 5, 18)
	)
	intro_banner_panel.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.14, 0.09, 0.04, 0.96), Color("#FFE047"), 32, 5, 28)
	)
	summary_card.add_theme_stylebox_override(
		"panel",
		UIThemeBuilder.make_panel_style(Color(0.12, 0.08, 0.05, 0.98), Color("#FFB800"), 34, 5, 36)
	)

	timer_label.label_settings = UIThemeBuilder.make_label_settings(44, Color("#FFF3C4"), 10)
	hearts_label.label_settings = UIThemeBuilder.make_label_settings(44, Color("#FF6B6B"), 10)
	score_label.label_settings = UIThemeBuilder.make_label_settings(44, Color("#58D68D"), 10)
	intro_banner_label.label_settings = UIThemeBuilder.make_label_settings(42, Color("#FFE047"), 10)

	summary_title_lbl.label_settings = UIThemeBuilder.make_label_settings(52, Color("#FFE047"), 12)
	summary_stats_lbl.label_settings = UIThemeBuilder.make_label_settings(38, Color("#FFF8E7"), 9)

	UIThemeBuilder.apply_arcade_button_style(exit_btn, Color("#6E4726"), Color("#422813"), Color.WHITE, 36, 22, 9)
	UIThemeBuilder.apply_arcade_button_style(summary_next_btn, Color("#27AE60"), Color("#196F3D"), Color.WHITE, 46, 28, 12)
	UIThemeBuilder.apply_arcade_button_style(summary_village_btn, Color("#2980B9"), Color("#1B4F72"), Color.WHITE, 42, 26, 10)
	_refresh_evade_button_visual(false)


func _setup_holes_matrix() -> void:
	holes.clear()
	_hole_timer_bars.clear()
	for child: Node in timer_bars_layer.get_children():
		child.queue_free()

	for i: int in range(9):
		var hole_node: Hole3D = holes_grid.get_node("Hole" + str(i)) as Hole3D
		holes.append(hole_node)
		hole_node.hole_tapped.connect(_on_hole_tapped)
		hole_node.mole.mole_whacked.connect(_on_mole_whacked)
		hole_node.mole.attack_blocked.connect(_on_mole_attack_blocked)
		hole_node.mole.attack_dodged.connect(_on_mole_attack_dodged)
		hole_node.mole.trap_triggered.connect(_on_mole_trap_triggered)
		hole_node.mole.self_stun_started.connect(_on_mole_self_stun_started)
		hole_node.mole.rock_thrown.connect(_on_mole_rock_thrown)
		hole_node.mole.taunt_started.connect(_on_mole_taunt_started)

		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(150, 26)
		bar.size = Vector2(150, 26)
		bar.max_value = 1.0
		bar.step = 0.01
		bar.show_percentage = false
		bar.visible = false
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bg_sb := StyleBoxFlat.new()
		bg_sb.bg_color = Color(0.1, 0.08, 0.06, 0.90)
		bg_sb.border_color = Color("#1A0F06")
		bg_sb.set_border_width_all(3)
		bg_sb.set_corner_radius_all(12)
		bar.add_theme_stylebox_override("background", bg_sb)
		var fill_sb := StyleBoxFlat.new()
		fill_sb.bg_color = Color("#58D68D")
		fill_sb.set_corner_radius_all(10)
		bar.add_theme_stylebox_override("fill", fill_sb)
		timer_bars_layer.add_child(bar)
		_hole_timer_bars.append(bar)


func _start_new_round() -> void:
	match_state = MatchState.INTRO
	time_remaining = ROUND_DURATION_SECONDS
	screen_hearts = MAX_SCREEN_HEARTS
	round_points = 0
	round_coins = 0
	moles_whacked_count = 0
	rocks_evaded_count = 0
	_spawn_cooldown = 0.6
	_hammer_stun_remaining = 0.0

	summary_backdrop.visible = false
	_clear_flying_rocks()
	for child: Node in cracks_layer.get_children():
		child.queue_free()

	var active_rows: Array[bool] = GameManager.get_active_lane_rows()
	for idx: int in range(9):
		var row_idx: int = idx / 3
		holes[idx].setup_hole(idx, active_rows[row_idx])

	_refresh_top_hud()
	_refresh_evade_button_visual(false)

	intro_banner_panel.visible = true
	intro_banner_label.text = LocalizationManager.t("ARENA_INTRO_INCOMING")
	var target_hole_pos: Vector3 = holes[3].global_position
	var offscreen_start: Vector3 = target_hole_pos + Vector3(-2.6, 0.0, 0.0)
	var featured_id: String = String(GameManager.get_featured_mole_for_current_stage().get("id", "casco"))
	intro_mole.play_intro_walk_in(offscreen_start, target_hole_pos, featured_id)


func _on_intro_walk_finished() -> void:
	intro_banner_label.text = LocalizationManager.t("ARENA_INTRO_GO")
	var t: Tween = create_tween()
	t.tween_interval(0.65)
	t.tween_callback(func() -> void:
		if _hammer_stun_remaining <= 0.0:
			intro_banner_panel.visible = false
		match_state = MatchState.PLAYING
	)


func _try_spawn_random_mole() -> void:
	var candidates: Array[Hole3D] = []
	var currently_out: int = 0
	for h: Hole3D in holes:
		if h.is_lane_active:
			if h.mole.state != Mole3D.State.HIDDEN:
				currently_out += 1
			else:
				candidates.append(h)

	var max_simultaneous: int = GameManager.get_unlocked_lanes_count()
	if currently_out >= max_simultaneous or candidates.is_empty():
		_spawn_cooldown = 0.35
		return

	var chosen: Hole3D = candidates[randi() % candidates.size()]
	var exposure_sec: float = GameManager.get_current_mole_exposure_seconds()
	var mole_type_id: String = GameManager.pick_mole_type_for_spawn()
	chosen.spawn_mole(exposure_sec, mole_type_id)

	var base_interval: float = clampf(1.55 - float(GameManager.player_rank - 1) * 0.08, 0.65, 1.55)
	_spawn_cooldown = randf_range(base_interval * 0.75, base_interval * 1.15)


func _on_hole_tapped(hole_index: int, world_pos: Vector3) -> void:
	if match_state != MatchState.PLAYING:
		return
	if _hammer_stun_remaining > 0.0:
		_spawn_floating_callout(
			world_pos + Vector3(0, 0.9, 0),
			LocalizationManager.t("ARENA_CALLOUT_STUNNED"),
			Color("#AF7AC5")
		)
		return
	hammer_3d.play_strike_at(world_pos)
	var h: Hole3D = holes[hole_index]
	h.mole.whack()


func _on_mole_whacked(_hole_index: int, world_pos: Vector3, mole_type: String, points: int, coins: int) -> void:
	moles_whacked_count += 1
	round_points += points
	round_coins += coins
	_refresh_top_hud()
	if mole_type == "dorado":
		_spawn_floating_callout(
			world_pos,
			LocalizationManager.t("ARENA_CALLOUT_GOLDEN", {"pts": points}),
			Color("#FFD700")
		)
	else:
		_spawn_floating_callout(
			world_pos,
			LocalizationManager.t("ARENA_CALLOUT_OUCH", {"pts": points}),
			Color("#FFE047")
		)


func _on_mole_attack_blocked(_hole_index: int, world_pos: Vector3) -> void:
	_trigger_camera_shake(0.14, 0.12)
	_spawn_floating_callout(
		world_pos,
		LocalizationManager.t("ARENA_CALLOUT_BLOCKED"),
		Color("#5DADE2")
	)


func _on_mole_attack_dodged(_hole_index: int, world_pos: Vector3) -> void:
	_spawn_floating_callout(
		world_pos,
		LocalizationManager.t("ARENA_CALLOUT_DODGED"),
		Color("#F5B041")
	)


func _on_mole_trap_triggered(_hole_index: int, world_pos: Vector3, _mole_type: String) -> void:
	_hammer_stun_remaining = HAMMER_STUN_DURATION
	_trigger_camera_shake(0.28, 0.24)
	_spawn_floating_callout(
		world_pos,
		LocalizationManager.t("ARENA_CALLOUT_STUNNED"),
		Color("#AF7AC5")
	)


func _on_mole_self_stun_started(_hole_index: int, world_pos: Vector3) -> void:
	_spawn_floating_callout(
		world_pos,
		LocalizationManager.t("ARENA_CALLOUT_SELF_STUN"),
		Color("#58D68D")
	)


func _on_mole_taunt_started(_hole_index: int, world_pos: Vector3) -> void:
	_spawn_floating_callout(
		world_pos,
		LocalizationManager.t("ARENA_CALLOUT_TAUNT"),
		Color("#FF9F43")
	)


## Spawns a 3D projectile ("rock", "shuriken", or "pie") that flies directly along the camera's
## view centerline so it stays dead-center on a Pixel 5 screen, tracked by a 240x240px tap target button!
func _on_mole_rock_thrown(_hole_index: int, start_world_pos: Vector3, projectile_type: String = "rock") -> void:
	if match_state != MatchState.PLAYING:
		return

	var proj_mesh := MeshInstance3D.new()
	var proj_mat := StandardMaterial3D.new()
	var target_text_key: String = "ARENA_ROCK_TARGET"
	var btn_bg_color: Color = Color(0.91, 0.25, 0.20, 0.94)

	match projectile_type:
		"shuriken":
			var star_cyl := CylinderMesh.new()
			star_cyl.top_radius = 0.42
			star_cyl.bottom_radius = 0.42
			star_cyl.height = 0.08
			star_cyl.radial_segments = 4
			proj_mesh.mesh = star_cyl
			proj_mat.albedo_color = Color("#D0D3D4")
			proj_mat.metallic = 0.85
			proj_mat.roughness = 0.20
			target_text_key = "ARENA_SHURIKEN_TARGET"
			btn_bg_color = Color(0.80, 0.16, 0.24, 0.94)
		"pie":
			var pie_cyl := CylinderMesh.new()
			pie_cyl.top_radius = 0.38
			pie_cyl.bottom_radius = 0.32
			pie_cyl.height = 0.22
			pie_cyl.radial_segments = 12
			proj_mesh.mesh = pie_cyl
			proj_mat.albedo_color = Color("#FFF8E7")
			proj_mat.roughness = 0.55
			target_text_key = "ARENA_PIE_TARGET"
			btn_bg_color = Color(0.68, 0.32, 0.78, 0.94)
		_:
			var sphere := SphereMesh.new()
			sphere.radius = 0.32
			sphere.height = 0.60
			sphere.radial_segments = 10
			sphere.rings = 8
			proj_mesh.mesh = sphere
			proj_mat.albedo_color = Color("#95A5A6")
			proj_mat.roughness = 0.85
			target_text_key = "ARENA_ROCK_TARGET"

	proj_mesh.material_override = proj_mat
	projectiles_root.add_child(proj_mesh)
	proj_mesh.global_position = start_world_pos

	var rock_target_btn := Button.new()
	rock_target_btn.custom_minimum_size = Vector2(240, 240)
	rock_target_btn.size = Vector2(240, 240)
	rock_target_btn.text = LocalizationManager.t(target_text_key)
	UIThemeBuilder.apply_arcade_button_style(
		rock_target_btn,
		btn_bg_color,
		Color("#FFE047"),
		Color("#FFFDF5"),
		38,
		120,
		10
	)
	flying_rocks_ui_layer.add_child(rock_target_btn)

	var cam_forward: Vector3 = -camera_3d.global_transform.basis.z.normalized()
	var cam_right: Vector3 = camera_3d.global_transform.basis.x.normalized()
	var cam_up: Vector3 = camera_3d.global_transform.basis.y.normalized()
	var end_world_pos: Vector3 = (
		camera_3d.global_position
		+ cam_forward * 3.2
		+ cam_right * randf_range(-0.35, 0.35)
		+ cam_up * randf_range(-0.25, 0.25)
	)

	var rock_entry: Dictionary = {
		"mesh": proj_mesh,
		"btn": rock_target_btn,
		"start": start_world_pos,
		"end": end_world_pos,
		"elapsed": 0.0,
		"type": projectile_type,
	}
	_flying_rocks.append(rock_entry)

	rock_target_btn.pressed.connect(func() -> void:
		_deflect_specific_rock(rock_entry)
	)
	_refresh_evade_button_visual(true)


func _update_flying_rocks(delta: float) -> void:
	if _flying_rocks.is_empty():
		return

	var ui_size: Vector2 = hud_root.size
	var i: int = _flying_rocks.size() - 1
	while i >= 0:
		var entry: Dictionary = _flying_rocks[i]
		var elapsed: float = float(entry["elapsed"]) + delta
		entry["elapsed"] = elapsed
		var t: float = clampf(elapsed / ROCK_FLIGHT_DURATION, 0.0, 1.0)

		var start_p: Vector3 = entry["start"]
		var end_p: Vector3 = entry["end"]
		var pos: Vector3 = start_p.lerp(end_p, t)
		pos.y += sin(t * PI) * 1.15

		var mesh: MeshInstance3D = entry["mesh"]
		var btn: Button = entry["btn"]
		if is_instance_valid(mesh):
			mesh.global_position = pos
			mesh.rotation.x += delta * 9.0
			mesh.rotation.y += delta * 14.0
			mesh.rotation.z += delta * 7.0
			var s: float = lerpf(0.9, 1.9, t)
			mesh.scale = Vector3(s, s, s)

		var screen_pt: Vector2 = camera_3d.unproject_position(pos)
		screen_pt.x = clampf(screen_pt.x, 160.0, maxf(200.0, ui_size.x - 160.0))
		screen_pt.y = clampf(screen_pt.y, 260.0, maxf(400.0, ui_size.y - 320.0))

		if is_instance_valid(btn):
			btn.position = screen_pt - btn.size * 0.5

		if t >= 1.0:
			_cleanup_rock_entry(entry)
			_flying_rocks.remove_at(i)
			_on_rock_hit_screen(screen_pt)

		i -= 1

	_refresh_evade_button_visual(not _flying_rocks.is_empty())


func _on_evade_button_pressed() -> void:
	_try_evade_oldest_rock()


func _try_evade_oldest_rock() -> void:
	if _flying_rocks.is_empty():
		return
	var oldest: Dictionary = _flying_rocks[0]
	_deflect_specific_rock(oldest)


func _deflect_specific_rock(target_entry: Dictionary) -> void:
	var idx: int = _flying_rocks.find(target_entry)
	if idx == -1:
		return

	var mesh: MeshInstance3D = target_entry["mesh"]
	var rock_pos: Vector3 = mesh.global_position if is_instance_valid(mesh) else Vector3.ZERO
	hammer_3d.play_strike_at(rock_pos)

	_cleanup_rock_entry(target_entry)
	_flying_rocks.remove_at(idx)
	_refresh_evade_button_visual(not _flying_rocks.is_empty())

	rocks_evaded_count += 1
	round_points += POINTS_PER_EVADE
	_refresh_top_hud()
	_spawn_floating_callout(
		rock_pos,
		LocalizationManager.t("ARENA_CALLOUT_EVADED"),
		Color("#5DADE2")
	)


func _on_rock_hit_screen(impact_pt: Vector2) -> void:
	screen_hearts = maxi(0, screen_hearts - 1)
	_refresh_top_hud()
	_trigger_camera_shake(0.38, 0.32)
	_draw_screen_crack(impact_pt)
	_spawn_floating_callout_screen(
		impact_pt,
		LocalizationManager.t("ARENA_CALLOUT_ROCK_HIT"),
		Color("#FF5252")
	)

	if screen_hearts <= 0:
		_trigger_round_end(false)


func _cleanup_rock_entry(entry: Dictionary) -> void:
	var mesh: MeshInstance3D = entry["mesh"]
	if is_instance_valid(mesh):
		mesh.queue_free()
	var btn: Button = entry["btn"]
	if is_instance_valid(btn):
		btn.queue_free()


func _clear_flying_rocks() -> void:
	for entry: Dictionary in _flying_rocks:
		_cleanup_rock_entry(entry)
	_flying_rocks.clear()


func _refresh_evade_button_visual(rock_incoming: bool) -> void:
	if rock_incoming:
		evade_button.text = LocalizationManager.t("ARENA_BTN_EVADE_ACTIVE")
		UIThemeBuilder.apply_arcade_button_style(
			evade_button,
			Color("#E74C3C"),
			Color("#922B21"),
			Color("#FFF59D"),
			42,
			30,
			14
		)
	else:
		evade_button.text = LocalizationManager.t("ARENA_BTN_EVADE_IDLE")
		UIThemeBuilder.apply_arcade_button_style(
			evade_button,
			Color("#2E86C1"),
			Color("#1B4F72"),
			Color("#EBF5FB"),
			38,
			28,
			12
		)


func _update_hole_exposure_bars() -> void:
	for i: int in range(holes.size()):
		var h: Hole3D = holes[i]
		var bar: ProgressBar = _hole_timer_bars[i]
		if h.is_lane_active and h.mole.is_showing_status_bar():
			var ratio: float = h.mole.get_exposure_ratio()
			bar.visible = true
			bar.value = ratio
			var screen_pos: Vector2 = camera_3d.unproject_position(h.global_position + Vector3(0, 1.38, 0))
			bar.position = screen_pos - Vector2(bar.size.x * 0.5, bar.size.y)
			var fill_sb := bar.get_theme_stylebox("fill") as StyleBoxFlat
			if fill_sb != null:
				var m_state: Mole3D.State = h.mole.state
				if h.mole.mole_type == "dorado":
					fill_sb.bg_color = Color("#FFD700")
				elif m_state == Mole3D.State.SHIELD_UP or m_state == Mole3D.State.NINJA_DASH:
					fill_sb.bg_color = Color("#3498DB")
				elif m_state == Mole3D.State.NINJA_LOG_DECOY or m_state == Mole3D.State.CLOWN_BALLOON_TRAP:
					fill_sb.bg_color = Color("#AF7AC5")
				else:
					if ratio > 0.5:
						fill_sb.bg_color = Color("#58D68D")
					elif ratio > 0.25:
						fill_sb.bg_color = Color("#F39C12")
					else:
						fill_sb.bg_color = Color("#E74C3C")
		else:
			bar.visible = false


func _draw_screen_crack(center: Vector2) -> void:
	var ui_size: Vector2 = hud_root.size
	var clamped_center := Vector2(
		clampf(center.x, 160.0, maxf(200.0, ui_size.x - 160.0)),
		clampf(center.y, 260.0, maxf(400.0, ui_size.y - 320.0))
	)
	var rays: int = 9
	for r: int in range(rays):
		var line := Line2D.new()
		line.width = 6.0
		line.default_color = Color(0.94, 0.98, 1.0, 0.9)
		var angle: float = (TAU / float(rays)) * float(r) + randf_range(-0.2, 0.2)
		var pts := PackedVector2Array([clamped_center])
		var cur: Vector2 = clamped_center
		for seg: int in range(4):
			var length: float = randf_range(65.0, 130.0)
			cur += Vector2(cos(angle), sin(angle)) * length
			angle += randf_range(-0.35, 0.35)
			pts.append(cur)
		line.points = pts
		cracks_layer.add_child(line)


func _spawn_floating_callout(world_pos: Vector3, text: String, color: Color) -> void:
	var screen_pt: Vector2 = camera_3d.unproject_position(world_pos)
	_spawn_floating_callout_screen(screen_pt, text, color)


func _spawn_floating_callout_screen(screen_pt: Vector2, text: String, color: Color) -> void:
	var ui_size: Vector2 = hud_root.size
	var safe_pt := Vector2(
		clampf(screen_pt.x, 200.0, maxf(250.0, ui_size.x - 200.0)),
		clampf(screen_pt.y, 220.0, maxf(300.0, ui_size.y - 260.0))
	)
	var lbl := Label.new()
	lbl.text = text
	lbl.label_settings = UIThemeBuilder.make_label_settings(48, color, 12, Color("#1A0E05"), Vector2(0, 6))
	lbl.position = safe_pt - Vector2(190, 35)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	callouts_layer.add_child(lbl)

	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(lbl, "position:y", lbl.position.y - 95.0, 0.82).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "modulate:a", 0.0, 0.82).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(lbl.queue_free)


func _trigger_camera_shake(duration: float, intensity: float) -> void:
	_shake_time = duration
	_shake_intensity = intensity


func _update_camera_shake(delta: float) -> void:
	if _shake_time > 0.0:
		_shake_time -= delta
		camera_3d.position = _base_camera_pos + Vector3(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity),
			0.0
		)
	else:
		camera_3d.position = _base_camera_pos


func _refresh_top_hud() -> void:
	exit_btn.text = LocalizationManager.t("ARENA_BTN_EXIT")
	timer_label.text = "⏱️ %ds" % ceili(time_remaining)

	var hearts_str: String = ""
	for i: int in range(MAX_SCREEN_HEARTS):
		hearts_str += "❤️" if i < screen_hearts else "🖤"
	hearts_label.text = hearts_str
	score_label.text = "🏆 %d" % round_points


func _trigger_round_end(victory: bool) -> void:
	match_state = MatchState.VICTORY if victory else MatchState.DEFEAT
	_hammer_stun_remaining = 0.0
	intro_banner_panel.visible = false
	_clear_flying_rocks()
	for h: Hole3D in holes:
		h.mole.set_hidden_immediate()
	for bar: ProgressBar in _hole_timer_bars:
		bar.visible = false

	var current_stage: int = GameManager.get_current_stage_number()
	if victory:
		round_coins += 100
		GameManager.record_match_completed(round_points, round_coins)
		summary_title_lbl.text = LocalizationManager.t("ARENA_WIN_TITLE", {"level": current_stage})
		summary_next_btn.text = LocalizationManager.t("ARENA_BTN_NEXT_STAGE")
	else:
		summary_title_lbl.text = LocalizationManager.t("ARENA_LOSE_TITLE", {"level": current_stage})
		summary_next_btn.text = LocalizationManager.t("ARENA_BTN_RETRY")

	summary_stats_lbl.text = LocalizationManager.t(
		"ARENA_SUMMARY_STATS",
		{
			"hits": moles_whacked_count,
			"evaded": rocks_evaded_count,
			"points": round_points,
			"coins": round_coins,
		}
	)
	summary_village_btn.text = LocalizationManager.t("ARENA_BTN_BACK_VILLAGE")
	summary_backdrop.visible = true
	summary_next_btn.grab_focus()


func _on_summary_next_pressed() -> void:
	_start_new_round()


func _on_summary_village_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_HUB_SCENE_PATH)


func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_HUB_SCENE_PATH)
