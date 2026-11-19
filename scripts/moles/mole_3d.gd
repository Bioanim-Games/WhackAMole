class_name Mole3D
extends Node3D

## Pure-Godot 3D Hard-Hat ("Casco") Mole built from MeshInstance3D primitives.
## Implements SPEC-M2-03 state machine: HIDDEN, WALK_IN, EMERGING, EXPOSED (5.0s base),
## THROWING_ROCK, TAUNTING (2.0s), HIT_OUCH, RETREATING.

signal mole_whacked(hole_index: int, world_pos: Vector3)
signal rock_thrown(hole_index: int, start_world_pos: Vector3)
signal taunt_started(hole_index: int, world_pos: Vector3)
signal mole_hidden(hole_index: int)
signal intro_walk_finished

enum State {
	HIDDEN,
	WALK_IN,
	EMERGING,
	EXPOSED,
	THROWING_ROCK,
	TAUNTING,
	HIT_OUCH,
	RETREATING,
}

const HIDDEN_Y: float = -1.45
const EXPOSED_Y: float = 0.0

@onready var visual_root: Node3D = $VisualRoot
@onready var hard_hat_root: Node3D = $VisualRoot/HardHatRoot
@onready var right_arm: Node3D = $VisualRoot/RightArm
@onready var left_arm: Node3D = $VisualRoot/LeftArm
@onready var held_rock: MeshInstance3D = $VisualRoot/RightArm/HeldRock

var hole_index: int = 0
var state: State = State.HIDDEN
var exposure_duration: float = 5.0
var exposure_remaining: float = 0.0
var _active_tween: Tween = null
var _bob_time: float = 0.0


func _ready() -> void:
	_build_3d_materials()
	set_hidden_immediate()


func _process(delta: float) -> void:
	if state == State.EXPOSED:
		_bob_time += delta * 5.5
		visual_root.position.y = sin(_bob_time) * 0.05
		visual_root.rotation.y = sin(_bob_time * 0.6) * 0.14
		exposure_remaining -= delta
		if exposure_remaining <= 0.0:
			_enter_throwing_rock()
	elif state == State.TAUNTING:
		_bob_time += delta * 18.0
		visual_root.position.y = absf(sin(_bob_time)) * 0.22
		visual_root.rotation.z = sin(_bob_time * 0.8) * 0.16


func _build_3d_materials() -> void:
	var fur_mat := StandardMaterial3D.new()
	fur_mat.albedo_color = Color("#8D5524")
	fur_mat.roughness = 0.78

	var belly_mat := StandardMaterial3D.new()
	belly_mat.albedo_color = Color("#C68642")
	belly_mat.roughness = 0.82

	var nose_mat := StandardMaterial3D.new()
	nose_mat.albedo_color = Color("#3E1F0D")
	nose_mat.roughness = 0.45

	var teeth_mat := StandardMaterial3D.new()
	teeth_mat.albedo_color = Color("#FFFDF7")
	teeth_mat.roughness = 0.3

	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color("#111317")
	glass_mat.metallic = 0.65
	glass_mat.roughness = 0.18

	var hat_mat := StandardMaterial3D.new()
	hat_mat.albedo_color = Color("#FFCC00")
	hat_mat.roughness = 0.32
	hat_mat.metallic = 0.1

	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color("#7F8C8D")
	rock_mat.roughness = 0.9

	($VisualRoot/BodyMesh as MeshInstance3D).material_override = fur_mat
	($VisualRoot/BellyMesh as MeshInstance3D).material_override = belly_mat
	($VisualRoot/SnoutMesh as MeshInstance3D).material_override = belly_mat
	($VisualRoot/NoseTipMesh as MeshInstance3D).material_override = nose_mat
	($VisualRoot/GrinTeethMesh as MeshInstance3D).material_override = teeth_mat
	($VisualRoot/SunglassesLeft as MeshInstance3D).material_override = glass_mat
	($VisualRoot/SunglassesRight as MeshInstance3D).material_override = glass_mat
	($VisualRoot/SunglassesBridge as MeshInstance3D).material_override = glass_mat
	($VisualRoot/HardHatRoot/HatDome as MeshInstance3D).material_override = hat_mat
	($VisualRoot/HardHatRoot/HatBrim as MeshInstance3D).material_override = hat_mat
	($VisualRoot/LeftArm/ArmMesh as MeshInstance3D).material_override = fur_mat
	($VisualRoot/RightArm/ArmMesh as MeshInstance3D).material_override = fur_mat
	held_rock.material_override = rock_mat


func set_hidden_immediate() -> void:
	_kill_tween()
	state = State.HIDDEN
	visible = false
	position.y = HIDDEN_Y
	visual_root.position = Vector3.ZERO
	visual_root.rotation = Vector3.ZERO
	visual_root.scale = Vector3.ONE
	hard_hat_root.position = Vector3(0, 0.72, 0)
	hard_hat_root.rotation = Vector3.ZERO
	right_arm.rotation = Vector3.ZERO
	held_rock.visible = false


func is_vulnerable() -> bool:
	return state == State.EXPOSED or (state == State.EMERGING and position.y > -0.75)


func get_exposure_ratio() -> float:
	if state != State.EXPOSED or exposure_duration <= 0.01:
		return 0.0
	return clampf(exposure_remaining / exposure_duration, 0.0, 1.0)


func spawn_from_hole(duration_sec: float) -> void:
	if state != State.HIDDEN:
		return
	_kill_tween()
	exposure_duration = maxf(1.2, duration_sec)
	exposure_remaining = exposure_duration
	_bob_time = 0.0

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
			state = State.EXPOSED
	)


## Plays the introductory sequence where the first mole runs in from off-screen
## and dives head-first into the nearest active hole.
func play_intro_walk_in(start_world_pos: Vector3, target_hole_world_pos: Vector3) -> void:
	_kill_tween()
	state = State.WALK_IN
	visible = true
	global_position = start_world_pos
	visual_root.position = Vector3.ZERO
	visual_root.scale = Vector3.ONE
	# Face toward the target hole along +X
	visual_root.rotation = Vector3(0, PI * 0.45, 0)
	held_rock.visible = false

	_active_tween = create_tween()
	# Run across the grass in 4 bouncy hops
	var steps: int = 5
	for i: int in range(steps):
		var t_next: float = float(i + 1) / float(steps)
		var step_pos: Vector3 = start_world_pos.lerp(target_hole_world_pos, t_next)
		var mid_pos: Vector3 = start_world_pos.lerp(target_hole_world_pos, (float(i) + 0.5) / float(steps)) + Vector3(0, 0.35, 0)
		_active_tween.tween_property(self, "global_position", mid_pos, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_active_tween.tween_property(self, "global_position", step_pos, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	# High leap and head-first dive into the hole!
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


## Called when the player taps/strikes this hole while the mole is vulnerable.
func whack() -> bool:
	if not is_vulnerable():
		return false

	_kill_tween()
	state = State.HIT_OUCH
	held_rock.visible = false

	# Squash-and-stretch bonk reaction + tilted hard hat
	visual_root.position = Vector3.ZERO
	visual_root.rotation = Vector3(0.15, 0, -0.22)
	visual_root.scale = Vector3(1.42, 0.52, 1.42)
	hard_hat_root.position = Vector3(0.12, 0.88, 0.05)
	hard_hat_root.rotation = Vector3(-0.35, 0.2, -0.45)

	mole_whacked.emit(hole_index, global_position + Vector3(0, 0.8, 0))

	_active_tween = create_tween()
	_active_tween.tween_property(visual_root, "scale", Vector3(1.15, 0.78, 1.15), 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_active_tween.tween_interval(0.12)
	_active_tween.tween_callback(_enter_retreating)
	return true


func _enter_throwing_rock() -> void:
	_kill_tween()
	state = State.THROWING_ROCK
	held_rock.visible = true

	_active_tween = create_tween()
	# Wind up right arm backward
	_active_tween.tween_property(right_arm, "rotation:x", -1.35, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Hurl rock forward toward camera!
	_active_tween.tween_property(right_arm, "rotation:x", 0.95, 0.14).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_active_tween.tween_callback(func() -> void:
		held_rock.visible = false
		right_arm.rotation = Vector3.ZERO
		rock_thrown.emit(hole_index, global_position + Vector3(0, 0.95, 0.45))
		_enter_taunting()
	)


func _enter_taunting() -> void:
	_kill_tween()
	state = State.TAUNTING
	_bob_time = 0.0
	taunt_started.emit(hole_index, global_position + Vector3(0, 1.1, 0))

	# 2.0 seconds of taunting laughter before hiding
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
