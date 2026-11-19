class_name Hole3D
extends Node3D

## 3D Dirt Mound Hole in the 3x3 Lawn Matrix (SPEC-M2-02).
## Supports active lane vs PvZ locked-turf barricade state, direct touch/click
## input via Area3D, and embeds its Mole3D instance.

signal hole_tapped(hole_index: int, world_pos: Vector3)

@onready var dirt_mound_mesh: MeshInstance3D = $DirtMoundMesh
@onready var inner_pit_mesh: MeshInstance3D = $InnerPitMesh
@onready var locked_turf_cover: Node3D = $LockedTurfCover
@onready var locked_grass_slab: MeshInstance3D = $LockedTurfCover/GrassSlab
@onready var locked_plank_a: MeshInstance3D = $LockedTurfCover/WoodPlankA
@onready var locked_plank_b: MeshInstance3D = $LockedTurfCover/WoodPlankB
@onready var tap_area: Area3D = $TapArea3D
@onready var mole: Mole3D = $MoleHolder/Mole3D

var hole_index: int = 0
var is_lane_active: bool = true


func _ready() -> void:
	_apply_materials()
	tap_area.input_event.connect(_on_tap_area_input_event)


func setup_hole(idx: int, lane_active: bool) -> void:
	hole_index = idx
	is_lane_active = lane_active
	if mole != null:
		mole.hole_index = idx
		mole.set_hidden_immediate()
	_refresh_lane_visuals()


func _apply_materials() -> void:
	var dirt_mat := StandardMaterial3D.new()
	dirt_mat.albedo_color = Color("#6E4726")
	dirt_mat.roughness = 0.92
	dirt_mound_mesh.material_override = dirt_mat

	var pit_mat := StandardMaterial3D.new()
	pit_mat.albedo_color = Color("#140B05")
	pit_mat.roughness = 1.0
	inner_pit_mesh.material_override = pit_mat

	var uncut_turf_mat := StandardMaterial3D.new()
	uncut_turf_mat.albedo_color = Color("#195A2D")
	uncut_turf_mat.roughness = 0.9
	locked_grass_slab.material_override = uncut_turf_mat

	var plank_mat := StandardMaterial3D.new()
	plank_mat.albedo_color = Color("#8D5B3C")
	plank_mat.roughness = 0.85
	locked_plank_a.material_override = plank_mat
	locked_plank_b.material_override = plank_mat


func _refresh_lane_visuals() -> void:
	dirt_mound_mesh.visible = is_lane_active
	inner_pit_mesh.visible = is_lane_active
	locked_turf_cover.visible = not is_lane_active
	tap_area.input_ray_pickable = is_lane_active


func can_spawn_mole() -> bool:
	return is_lane_active and mole != null and mole.state == Mole3D.State.HIDDEN


func spawn_mole(exposure_sec: float) -> void:
	if can_spawn_mole():
		mole.spawn_from_hole(exposure_sec)


func _on_tap_area_input_event(
	_camera: Node,
	event: InputEvent,
	_event_position: Vector3,
	_normal: Vector3,
	_shape_idx: int
) -> void:
	if not is_lane_active:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			hole_tapped.emit(hole_index, global_position)
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			hole_tapped.emit(hole_index, global_position)
