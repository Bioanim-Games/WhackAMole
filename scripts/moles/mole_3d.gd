class_name Mole3D
extends Node3D

## Pure-Godot 3D Multi-Archetype Mole built from MeshInstance3D primitives (SPEC-M3-02 & SPEC-M3-03).
## Supports all 5 mole types:
## - "casco"  (Hard Hat Mole): Basic exposed timer -> throws "rock"
## - "escudo" (Shield Mole): Exposed (1.8s) -> Shield Up (2.6s invulnerable) -> Exposed (1.8s) -> throws "rock"
## - "ninja"  (Ninja Mole): High-Speed Dash (1.8s untouchable) -> Charging Shuriken (2.6s vulnerable) -> Substitution Log Trap (1.0s stuns hammer 2s) -> throws "shuriken"
## - "payaso" (Clown Mole): Red Balloon Trap (2.2s stuns hammer 2s if hit) -> Self-Popped Dizzy Stun (2.8s vulnerable) -> throws "pie"
## - "dorado" (Golden Mole): Fast 2.0s high-value cameo (+500 pts / +150 coins), never attacks

signal mole_whacked(hole_index: int, world_pos: Vector3, mole_type: String, points: int, coins: int)
signal attack_blocked(hole_index: int, world_pos: Vector3)
signal attack_dodged(hole_index: int, world_pos: Vector3)
signal trap_triggered(hole_index: int, world_pos: Vector3, mole_type: String)
signal self_stun_started(hole_index: int, world_pos: Vector3)
signal rock_thrown(hole_index: int, start_world_pos: Vector3, projectile_type: String)
signal taunt_started(hole_index: int, world_pos: Vector3)
signal mole_hidden(hole_index: int)
signal intro_walk_finished

enum State {
	HIDDEN,
	WALK_IN,
	EMERGING,
	EXPOSED,
	SHIELD_UP,
	NINJA_DASH,
	NINJA_SHURIKEN,
	NINJA_LOG_DECOY,
	CLOWN_BALLOON_TRAP,
	CLOWN_SELF_STUNNED,
	THROWING_ROCK,
	TAUNTING,
	HIT_OUCH,
	RETREATING,
}

enum WhackResult {
	IGNORED,
	HIT_SUCCESS,
	BLOCKED_BY_SHIELD,
	DODGED_BY_SPEED,
	TRIGGERED_STUN_TRAP,
}

const HIDDEN_Y: float = -1.45
const EXPOSED_Y: float = 0.0

@onready var visual_root: Node3D = $VisualRoot
@onready var body_mesh: MeshInstance3D = $VisualRoot/BodyMesh
@onready var belly_mesh: MeshInstance3D = $VisualRoot/BellyMesh
@onready var snout_mesh: MeshInstance3D = $VisualRoot/SnoutMesh
@onready var nose_tip_mesh: MeshInstance3D = $VisualRoot/NoseTipMesh
@onready var hard_hat_root: Node3D = $VisualRoot/HardHatRoot
@onready var hat_dome: MeshInstance3D = $VisualRoot/HardHatRoot/HatDome
@onready var hat_brim: MeshInstance3D = $VisualRoot/HardHatRoot/HatBrim
@onready var right_arm: Node3D = $VisualRoot/RightArm
@onready var left_arm: Node3D = $VisualRoot/LeftArm
@onready var held_rock: MeshInstance3D = $VisualRoot/RightArm/HeldRock

var hole_index: int = 0
var mole_type: String = "casco"
var state: State = State.HIDDEN
var phase_duration: float = 5.0
var phase_remaining: float = 0.0
var _escudo_subphase: int = 0
var _active_tween: Tween = null
var _bob_time: float = 0.0

# Materials for dynamic archetype switching
var _fur_brown_mat: StandardMaterial3D
var _belly_tan_mat: StandardMaterial3D
var _nose_dark_mat: StandardMaterial3D
var _nose_clown_mat: StandardMaterial3D
var _hat_yellow_mat: StandardMaterial3D
var _hat_blue_mat: StandardMaterial3D
var _ninja_suit_mat: StandardMaterial3D
var _gold_body_mat: StandardMaterial3D
var _gold_belly_mat: StandardMaterial3D

# Procedural 3D archetype attachments
var _shield_root: Node3D
var _ninja_headband_root: Node3D
var _log_decoy_root: Node3D
var _clown_wig_root: Node3D
var _balloon_trap_root: Node3D
var _golden_crown_root: Node3D


func _ready() -> void:
	_build_3d_materials()
	_build_archetype_props()
	apply_mole_type("casco")
	set_hidden_immediate()


func _process(delta: float) -> void:
	match state:
		State.EXPOSED:
			_bob_time += delta * (8.0 if mole_type == "dorado" else 5.5)
			visual_root.position = Vector3(0.0, sin(_bob_time) * 0.05, 0.0)
			visual_root.rotation = Vector3(0.0, sin(_bob_time * 0.6) * 0.14, 0.0)
			phase_remaining -= delta
			if phase_remaining <= 0.0:
				_on_phase_timer_expired()

		State.SHIELD_UP:
			_bob_time += delta * 4.0
			visual_root.position = Vector3(0.0, sin(_bob_time) * 0.02, 0.0)
			visual_root.rotation = Vector3(0.0, sin(_bob_time * 0.5) * 0.06, 0.0)
			phase_remaining -= delta
			if phase_remaining <= 0.0:
				_on_phase_timer_expired()

		State.NINJA_DASH:
			_bob_time += delta * 28.0
			visual_root.position = Vector3(sin(_bob_time) * 0.42, absf(cos(_bob_time)) * 0.08, 0.0)
			visual_root.rotation = Vector3(0.0, sin(_bob_time * 0.5) * 0.35, -sin(_bob_time) * 0.18)
			phase_remaining -= delta
			if phase_remaining <= 0.0:
				_on_phase_timer_expired()

		State.NINJA_SHURIKEN:
			_bob_time += delta * 7.0
			visual_root.position = Vector3(0.0, sin(_bob_time) * 0.04, 0.0)
			visual_root.rotation = Vector3(0.0, sin(_bob_time * 0.8) * 0.12, 0.0)
			held_rock.rotation.y += delta * 14.0
			phase_remaining -= delta
			if phase_remaining <= 0.0:
				_on_phase_timer_expired()

		State.NINJA_LOG_DECOY:
			_bob_time += delta * 10.0
			_log_decoy_root.rotation.y = sin(_bob_time) * 0.15
			phase_remaining -= delta
			if phase_remaining <= 0.0:
				_on_phase_timer_expired()

		State.CLOWN_BALLOON_TRAP:
			_bob_time += delta * 6.5
			visual_root.position = Vector3(0.0, sin(_bob_time) * 0.05, 0.0)
			var pulse: float = 1.0 + sin(_bob_time * 1.4) * 0.08
			_balloon_trap_root.scale = Vector3(pulse, pulse, pulse)
			phase_remaining -= delta
			if phase_remaining <= 0.0:
				_on_phase_timer_expired()

		State.CLOWN_SELF_STUNNED:
			_bob_time += delta * 12.0
			visual_root.position = Vector3(sin(_bob_time) * 0.06, 0.0, 0.0)
			visual_root.rotation = Vector3(0.12, sin(_bob_time * 0.7) * 0.25, cos(_bob_time) * 0.18)
			phase_remaining -= delta
			if phase_remaining <= 0.0:
				_on_phase_timer_expired()

		State.TAUNTING:
			_bob_time += delta * 18.0
			visual_root.position = Vector3(0.0, absf(sin(_bob_time)) * 0.22, 0.0)
			visual_root.rotation = Vector3(0.0, 0.0, sin(_bob_time * 0.8) * 0.16)


func _build_3d_materials() -> void:
	_fur_brown_mat = StandardMaterial3D.new()
	_fur_brown_mat.albedo_color = Color("#8D5524")
	_fur_brown_mat.roughness = 0.78

	_belly_tan_mat = StandardMaterial3D.new()
	_belly_tan_mat.albedo_color = Color("#C68642")
	_belly_tan_mat.roughness = 0.82

	_nose_dark_mat = StandardMaterial3D.new()
	_nose_dark_mat.albedo_color = Color("#3E1F0D")
	_nose_dark_mat.roughness = 0.45

	_nose_clown_mat = StandardMaterial3D.new()
	_nose_clown_mat.albedo_color = Color("#FF1744")
	_nose_clown_mat.roughness = 0.25

	var teeth_mat := StandardMaterial3D.new()
	teeth_mat.albedo_color = Color("#FFFDF7")
	teeth_mat.roughness = 0.3

	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color("#111317")
	glass_mat.metallic = 0.65
	glass_mat.roughness = 0.18

	_hat_yellow_mat = StandardMaterial3D.new()
	_hat_yellow_mat.albedo_color = Color("#FFCC00")
	_hat_yellow_mat.roughness = 0.32
	_hat_yellow_mat.metallic = 0.1

	_hat_blue_mat = StandardMaterial3D.new()
	_hat_blue_mat.albedo_color = Color("#2980B9")
	_hat_blue_mat.roughness = 0.30
	_hat_blue_mat.metallic = 0.25

	_ninja_suit_mat = StandardMaterial3D.new()
	_ninja_suit_mat.albedo_color = Color("#1C2833")
	_ninja_suit_mat.roughness = 0.65

	_gold_body_mat = StandardMaterial3D.new()
	_gold_body_mat.albedo_color = Color("#FFD700")
	_gold_body_mat.metallic = 0.85
	_gold_body_mat.roughness = 0.18

	_gold_belly_mat = StandardMaterial3D.new()
	_gold_belly_mat.albedo_color = Color("#FFF59D")
	_gold_belly_mat.metallic = 0.70
	_gold_belly_mat.roughness = 0.22

	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color("#7F8C8D")
	rock_mat.roughness = 0.9

	body_mesh.material_override = _fur_brown_mat
	belly_mesh.material_override = _belly_tan_mat
	snout_mesh.material_override = _belly_tan_mat
	nose_tip_mesh.material_override = _nose_dark_mat
	($VisualRoot/GrinTeethMesh as MeshInstance3D).material_override = teeth_mat
	($VisualRoot/SunglassesLeft as MeshInstance3D).material_override = glass_mat
	($VisualRoot/SunglassesRight as MeshInstance3D).material_override = glass_mat
	($VisualRoot/SunglassesBridge as MeshInstance3D).material_override = glass_mat
	hat_dome.material_override = _hat_yellow_mat
	hat_brim.material_override = _hat_yellow_mat
	($VisualRoot/LeftArm/ArmMesh as MeshInstance3D).material_override = _fur_brown_mat
	($VisualRoot/RightArm/ArmMesh as MeshInstance3D).material_override = _fur_brown_mat
	held_rock.material_override = rock_mat


func _build_archetype_props() -> void:
	# 1. Riot Shield ("escudo")
	_shield_root = Node3D.new()
	_shield_root.name = "ShieldRoot"
	_shield_root.position = Vector3(0.0, 0.48, 0.56)
	visual_root.add_child(_shield_root)

	var shield_plate := MeshInstance3D.new()
	var plate_box := BoxMesh.new()
	plate_box.size = Vector3(0.92, 0.96, 0.10)
	shield_plate.mesh = plate_box
	var shield_mat := StandardMaterial3D.new()
	shield_mat.albedo_color = Color("#2471A3")
	shield_mat.metallic = 0.45
	shield_mat.roughness = 0.32
	shield_plate.material_override = shield_mat
	_shield_root.add_child(shield_plate)

	var shield_visor := MeshInstance3D.new()
	var visor_box := BoxMesh.new()
	visor_box.size = Vector3(0.64, 0.22, 0.13)
	shield_visor.mesh = visor_box
	shield_visor.position = Vector3(0.0, 0.20, 0.0)
	var visor_mat := StandardMaterial3D.new()
	visor_mat.albedo_color = Color("#85C1E9")
	visor_mat.metallic = 0.7
	visor_mat.roughness = 0.15
	shield_visor.material_override = visor_mat
	_shield_root.add_child(shield_visor)

	# 2. Ninja Red Headband & Substitution Log ("ninja")
	_ninja_headband_root = Node3D.new()
	_ninja_headband_root.name = "NinjaHeadbandRoot"
	_ninja_headband_root.position = Vector3(0.0, 0.73, 0.0)
	visual_root.add_child(_ninja_headband_root)

	var band_cyl := MeshInstance3D.new()
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = 0.46
	cyl_mesh.bottom_radius = 0.47
	cyl_mesh.height = 0.13
	band_cyl.mesh = cyl_mesh
	var red_band_mat := StandardMaterial3D.new()
	red_band_mat.albedo_color = Color("#E74C3C")
	red_band_mat.roughness = 0.5
	band_cyl.material_override = red_band_mat
	_ninja_headband_root.add_child(band_cyl)

	var knot_tail := MeshInstance3D.new()
	var tail_box := BoxMesh.new()
	tail_box.size = Vector3(0.28, 0.12, 0.18)
	knot_tail.mesh = tail_box
	knot_tail.position = Vector3(0.45, 0.02, -0.22)
	knot_tail.rotation = Vector3(0.0, 0.4, -0.3)
	knot_tail.material_override = red_band_mat
	_ninja_headband_root.add_child(knot_tail)

	_log_decoy_root = Node3D.new()
	_log_decoy_root.name = "LogDecoyRoot"
	_log_decoy_root.position = Vector3(0.0, 0.48, 0.0)
	add_child(_log_decoy_root)

	var log_trunk := MeshInstance3D.new()
	var log_mesh := CylinderMesh.new()
	log_mesh.top_radius = 0.36
	log_mesh.bottom_radius = 0.38
	log_mesh.height = 1.05
	log_trunk.mesh = log_mesh
	log_trunk.rotation.z = 0.12
	var bark_mat := StandardMaterial3D.new()
	bark_mat.albedo_color = Color("#5D4037")
	bark_mat.roughness = 0.92
	log_trunk.material_override = bark_mat
	_log_decoy_root.add_child(log_trunk)

	var log_top := MeshInstance3D.new()
	var top_cyl := CylinderMesh.new()
	top_cyl.top_radius = 0.32
	top_cyl.bottom_radius = 0.32
	top_cyl.height = 1.07
	log_top.mesh = top_cyl
	log_top.rotation.z = 0.12
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color("#D7CCC8")
	ring_mat.roughness = 0.85
	log_top.material_override = ring_mat
	_log_decoy_root.add_child(log_top)

	# 3. Clown Wig & Trap Balloon ("payaso")
	_clown_wig_root = Node3D.new()
	_clown_wig_root.name = "ClownWigRoot"
	_clown_wig_root.position = Vector3(0.0, 0.78, 0.0)
	visual_root.add_child(_clown_wig_root)

	var wig_colors: Array[Color] = [Color("#E91E63"), Color("#00E5FF"), Color("#FFEB3B")]
	var puff_offsets: Array[Vector3] = [
		Vector3(-0.36, 0.02, 0.0),
		Vector3(0.36, 0.02, 0.0),
		Vector3(0.0, 0.16, -0.05),
	]
	for idx: int in range(3):
		var puff := MeshInstance3D.new()
		var sp := SphereMesh.new()
		sp.radius = 0.25
		sp.height = 0.50
		puff.mesh = sp
		puff.position = puff_offsets[idx]
		var w_mat := StandardMaterial3D.new()
		w_mat.albedo_color = wig_colors[idx]
		w_mat.roughness = 0.65
		puff.material_override = w_mat
		_clown_wig_root.add_child(puff)

	_balloon_trap_root = Node3D.new()
	_balloon_trap_root.name = "BalloonTrapRoot"
	_balloon_trap_root.position = Vector3(0.0, 0.72, 0.64)
	visual_root.add_child(_balloon_trap_root)

	var balloon_sphere := MeshInstance3D.new()
	var b_mesh := SphereMesh.new()
	b_mesh.radius = 0.42
	b_mesh.height = 0.92
	balloon_sphere.mesh = b_mesh
	var balloon_mat := StandardMaterial3D.new()
	balloon_mat.albedo_color = Color("#FF1744")
	balloon_mat.roughness = 0.18
	balloon_mat.metallic = 0.15
	balloon_sphere.material_override = balloon_mat
	_balloon_trap_root.add_child(balloon_sphere)

	# 4. Golden Mole Crown ("dorado")
	_golden_crown_root = Node3D.new()
	_golden_crown_root.name = "GoldenCrownRoot"
	_golden_crown_root.position = Vector3(0.0, 0.88, 0.0)
	visual_root.add_child(_golden_crown_root)

	var crown_base := MeshInstance3D.new()
	var crown_cyl := CylinderMesh.new()
	crown_cyl.top_radius = 0.34
	crown_cyl.bottom_radius = 0.28
	crown_cyl.height = 0.24
	crown_base.mesh = crown_cyl
	var crown_mat := StandardMaterial3D.new()
	crown_mat.albedo_color = Color("#FFC107")
	crown_mat.metallic = 0.9
	crown_mat.roughness = 0.15
	crown_base.material_override = crown_mat
	_golden_crown_root.add_child(crown_base)


func apply_mole_type(new_type: String) -> void:
	mole_type = new_type
	hard_hat_root.visible = false
	_shield_root.visible = false
	_ninja_headband_root.visible = false
	_log_decoy_root.visible = false
	_clown_wig_root.visible = false
	_balloon_trap_root.visible = false
	_golden_crown_root.visible = false
	visual_root.visible = true

	# Default brown fur & dark nose
	body_mesh.material_override = _fur_brown_mat
	belly_mesh.material_override = _belly_tan_mat
	snout_mesh.material_override = _belly_tan_mat
	nose_tip_mesh.material_override = _nose_dark_mat
	($VisualRoot/LeftArm/ArmMesh as MeshInstance3D).material_override = _fur_brown_mat
	($VisualRoot/RightArm/ArmMesh as MeshInstance3D).material_override = _fur_brown_mat

	match mole_type:
		"casco":
			hard_hat_root.visible = true
			hat_dome.material_override = _hat_yellow_mat
			hat_brim.material_override = _hat_yellow_mat
		"escudo":
			hard_hat_root.visible = true
			hat_dome.material_override = _hat_blue_mat
			hat_brim.material_override = _hat_blue_mat
			_shield_root.visible = true
			_shield_root.position = Vector3(-0.48, 0.42, 0.32)
		"ninja":
			body_mesh.material_override = _ninja_suit_mat
			($VisualRoot/LeftArm/ArmMesh as MeshInstance3D).material_override = _ninja_suit_mat
			($VisualRoot/RightArm/ArmMesh as MeshInstance3D).material_override = _ninja_suit_mat
			_ninja_headband_root.visible = true
		"payaso":
			_clown_wig_root.visible = true
			nose_tip_mesh.material_override = _nose_clown_mat
		"dorado":
			body_mesh.material_override = _gold_body_mat
			belly_mesh.material_override = _gold_belly_mat
			snout_mesh.material_override = _gold_belly_mat
			($VisualRoot/LeftArm/ArmMesh as MeshInstance3D).material_override = _gold_body_mat
			($VisualRoot/RightArm/ArmMesh as MeshInstance3D).material_override = _gold_body_mat
			_golden_crown_root.visible = true


func set_hidden_immediate() -> void:
	_kill_tween()
	state = State.HIDDEN
	visible = false
	position.y = HIDDEN_Y
	visual_root.visible = true
	visual_root.position = Vector3.ZERO
	visual_root.rotation = Vector3.ZERO
	visual_root.scale = Vector3.ONE
	hard_hat_root.position = Vector3(0, 0.72, 0)
	hard_hat_root.rotation = Vector3.ZERO
	right_arm.rotation = Vector3.ZERO
	held_rock.visible = false
	if _log_decoy_root != null:
		_log_decoy_root.visible = false
	if _balloon_trap_root != null:
		_balloon_trap_root.visible = false


func is_showing_status_bar() -> bool:
	return state in [
		State.EXPOSED,
		State.SHIELD_UP,
		State.NINJA_DASH,
		State.NINJA_SHURIKEN,
		State.NINJA_LOG_DECOY,
		State.CLOWN_BALLOON_TRAP,
		State.CLOWN_SELF_STUNNED,
	]


func get_exposure_ratio() -> float:
	if not is_showing_status_bar() or phase_duration <= 0.01:
		return 0.0
	return clampf(phase_remaining / phase_duration, 0.0, 1.0)


func get_reward_points() -> int:
	match mole_type:
		"escudo":
			return 150
		"ninja":
			return 200
		"payaso":
			return 250
		"dorado":
			return 500
		_:
			return 100


func get_reward_coins() -> int:
	match mole_type:
		"escudo":
			return 35
		"ninja":
			return 45
		"payaso":
			return 55
		"dorado":
			return 150
		_:
			return 25


func get_projectile_type() -> String:
	match mole_type:
		"ninja":
			return "shuriken"
		"payaso":
			return "pie"
		"dorado":
			return ""
		_:
			return "rock"


func spawn_from_hole(duration_sec: float, archetype_id: String = "casco") -> void:
	if state != State.HIDDEN:
		return
	_kill_tween()
	apply_mole_type(archetype_id)
	_bob_time = 0.0
	_escudo_subphase = 0

	state = State.EMERGING
	visible = true
	position.y = HIDDEN_Y
	visual_root.position = Vector3.ZERO
	visual_root.rotation = Vector3.ZERO
	visual_root.scale = Vector3(0.9, 1.12, 0.9)
	hard_hat_root.position = Vector3(0, 0.72, 0)
	hard_hat_root.rotation = Vector3.ZERO
	held_rock.visible = false

	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.tween_property(self, "position:y", EXPOSED_Y, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(visual_root, "scale", Vector3.ONE, 0.25)
	_active_tween.chain().tween_callback(func() -> void:
		if state == State.EMERGING:
			_enter_initial_archetype_phase(duration_sec)
	)


func _enter_initial_archetype_phase(base_duration: float) -> void:
	_bob_time = 0.0
	match mole_type:
		"casco":
			state = State.EXPOSED
			phase_duration = maxf(1.5, base_duration)
			phase_remaining = phase_duration
		"escudo":
			_escudo_subphase = 1
			state = State.EXPOSED
			_shield_root.visible = true
			_shield_root.position = Vector3(-0.48, 0.42, 0.32)
			phase_duration = 1.8
			phase_remaining = phase_duration
		"ninja":
			state = State.NINJA_DASH
			phase_duration = 1.8
			phase_remaining = phase_duration
		"payaso":
			state = State.CLOWN_BALLOON_TRAP
			_balloon_trap_root.visible = true
			_balloon_trap_root.scale = Vector3.ONE
			phase_duration = 2.2
			phase_remaining = phase_duration
		"dorado":
			state = State.EXPOSED
			phase_duration = 2.0
			phase_remaining = phase_duration
		_:
			state = State.EXPOSED
			phase_duration = maxf(1.5, base_duration)
			phase_remaining = phase_duration


func _on_phase_timer_expired() -> void:
	_bob_time = 0.0
	match mole_type:
		"casco":
			_enter_throwing_rock()
		"escudo":
			if _escudo_subphase == 1:
				# Phase 2: Raise Riot Shield in front for 2.6s (Invulnerable!)
				_escudo_subphase = 2
				state = State.SHIELD_UP
				_shield_root.position = Vector3(0.0, 0.48, 0.56)
				phase_duration = 2.6
				phase_remaining = phase_duration
			elif _escudo_subphase == 2:
				# Phase 3: Lower shield to check if coast is clear for 1.8s (Vulnerable!)
				_escudo_subphase = 3
				state = State.EXPOSED
				_shield_root.position = Vector3(-0.48, 0.42, 0.32)
				phase_duration = 1.8
				phase_remaining = phase_duration
			else:
				_enter_throwing_rock()
		"ninja":
			if state == State.NINJA_DASH:
				# Phase 2: Stop dashing & charge shuriken for 2.6s (Vulnerable!)
				state = State.NINJA_SHURIKEN
				visual_root.position = Vector3.ZERO
				visual_root.rotation = Vector3.ZERO
				held_rock.visible = true
				phase_duration = 2.6
				phase_remaining = phase_duration
			elif state == State.NINJA_SHURIKEN:
				# Phase 3: Substitution Log Decoy for 1.0s (Stuns player hammer 2.0s if hit!)
				state = State.NINJA_LOG_DECOY
				held_rock.visible = false
				visual_root.visible = false
				_log_decoy_root.visible = true
				phase_duration = 1.0
				phase_remaining = phase_duration
			elif state == State.NINJA_LOG_DECOY:
				_log_decoy_root.visible = false
				visual_root.visible = true
				_enter_throwing_rock()
		"payaso":
			if state == State.CLOWN_BALLOON_TRAP:
				# Clown pops own balloon and gets dizzy for 2.8s (Vulnerable!)
				_balloon_trap_root.visible = false
				state = State.CLOWN_SELF_STUNNED
				phase_duration = 2.8
				phase_remaining = phase_duration
				self_stun_started.emit(hole_index, global_position + Vector3(0, 1.15, 0))
			elif state == State.CLOWN_SELF_STUNNED:
				visual_root.position = Vector3.ZERO
				visual_root.rotation = Vector3.ZERO
				_enter_throwing_rock()
		"dorado":
			# Golden Mole never attacks; hides immediately after 2.0s cameo
			_enter_retreating()


## Plays the introductory sequence where the first mole runs in from off-screen
## and dives head-first into the nearest active hole.
func play_intro_walk_in(start_world_pos: Vector3, target_hole_world_pos: Vector3, archetype_id: String = "casco") -> void:
	_kill_tween()
	apply_mole_type(archetype_id)
	state = State.WALK_IN
	visible = true
	global_position = start_world_pos
	visual_root.position = Vector3.ZERO
	visual_root.scale = Vector3.ONE
	visual_root.rotation = Vector3(0, PI * 0.45, 0)
	held_rock.visible = false

	_active_tween = create_tween()
	var steps: int = 5
	for i: int in range(steps):
		var t_next: float = float(i + 1) / float(steps)
		var step_pos: Vector3 = start_world_pos.lerp(target_hole_world_pos, t_next)
		var mid_pos: Vector3 = start_world_pos.lerp(target_hole_world_pos, (float(i) + 0.5) / float(steps)) + Vector3(0, 0.35, 0)
		_active_tween.tween_property(self, "global_position", mid_pos, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_active_tween.tween_property(self, "global_position", step_pos, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	var peak_pos: Vector3 = target_hole_world_pos + Vector3(0, 1.55, 0)
	var dive_pos: Vector3 = target_hole_world_pos + Vector3(0, HIDDEN_Y, 0)
	_active_tween.tween_callback(func() -> void:
		visual_root.rotation = Vector3(0, 0, 0)
	)
	_active_tween.tween_property(self, "global_position", peak_pos, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.parallel().tween_property(visual_root, "rotation:x", PI * 0.85, 0.28)
	_active_tween.tween_property(self, "global_position", dive_pos, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_active_tween.tween_callback(func() -> void:
		set_hidden_immediate()
		intro_walk_finished.emit()
	)


## Processes a hammer strike on this mole and returns the exact WhackResult outcome.
func whack() -> WhackResult:
	match state:
		State.SHIELD_UP:
			attack_blocked.emit(hole_index, global_position + Vector3(0, 1.0, 0))
			return WhackResult.BLOCKED_BY_SHIELD

		State.NINJA_DASH:
			attack_dodged.emit(hole_index, global_position + Vector3(0, 1.0, 0))
			return WhackResult.DODGED_BY_SPEED

		State.NINJA_LOG_DECOY, State.CLOWN_BALLOON_TRAP:
			_kill_tween()
			_log_decoy_root.visible = false
			_balloon_trap_root.visible = false
			visual_root.visible = true
			trap_triggered.emit(hole_index, global_position + Vector3(0, 1.05, 0), mole_type)
			_enter_taunting()
			return WhackResult.TRIGGERED_STUN_TRAP

		State.EXPOSED, State.NINJA_SHURIKEN, State.CLOWN_SELF_STUNNED:
			_trigger_whack_success()
			return WhackResult.HIT_SUCCESS

		State.EMERGING:
			if position.y > -0.75:
				_trigger_whack_success()
				return WhackResult.HIT_SUCCESS
			return WhackResult.IGNORED

		_:
			return WhackResult.IGNORED


func _trigger_whack_success() -> void:
	_kill_tween()
	state = State.HIT_OUCH
	held_rock.visible = false
	_balloon_trap_root.visible = false
	_log_decoy_root.visible = false
	visual_root.visible = true

	visual_root.position = Vector3.ZERO
	visual_root.rotation = Vector3(0.15, 0, -0.22)
	visual_root.scale = Vector3(1.42, 0.52, 1.42)
	hard_hat_root.position = Vector3(0.12, 0.88, 0.05)
	hard_hat_root.rotation = Vector3(-0.35, 0.2, -0.45)

	mole_whacked.emit(
		hole_index,
		global_position + Vector3(0, 0.8, 0),
		mole_type,
		get_reward_points(),
		get_reward_coins()
	)

	_active_tween = create_tween()
	_active_tween.tween_property(visual_root, "scale", Vector3(1.15, 0.78, 1.15), 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_active_tween.tween_interval(0.12)
	_active_tween.tween_callback(_enter_retreating)


func _enter_throwing_rock() -> void:
	var proj_type: String = get_projectile_type()
	if proj_type == "":
		_enter_retreating()
		return

	_kill_tween()
	state = State.THROWING_ROCK
	visual_root.visible = true
	visual_root.position = Vector3.ZERO
	visual_root.rotation = Vector3.ZERO
	held_rock.visible = true

	_active_tween = create_tween()
	_active_tween.tween_property(right_arm, "rotation:x", -1.35, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(right_arm, "rotation:x", 0.95, 0.14).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_active_tween.tween_callback(func() -> void:
		held_rock.visible = false
		right_arm.rotation = Vector3.ZERO
		rock_thrown.emit(hole_index, global_position + Vector3(0, 0.95, 0.45), proj_type)
		_enter_taunting()
	)


func _enter_taunting() -> void:
	_kill_tween()
	state = State.TAUNTING
	_bob_time = 0.0
	taunt_started.emit(hole_index, global_position + Vector3(0, 1.1, 0))

	_active_tween = create_tween()
	_active_tween.tween_interval(2.0)
	_active_tween.tween_callback(_enter_retreating)


func _enter_retreating() -> void:
	_kill_tween()
	state = State.RETREATING
	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.tween_property(self, "position:y", HIDDEN_Y, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_active_tween.tween_property(visual_root, "scale", Vector3(0.85, 1.1, 0.85), 0.24)
	_active_tween.chain().tween_callback(func() -> void:
		set_hidden_immediate()
		mole_hidden.emit(hole_index)
	)


func _kill_tween() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = null
