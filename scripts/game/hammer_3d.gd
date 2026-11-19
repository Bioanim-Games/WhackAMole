class_name Hammer3D
extends Node3D

## Pure-Godot 3D Basic 1-Head Wooden/Gold Mallet visual (SPEC-M2-05).

@onready var pivot_root: Node3D = $PivotRoot
@onready var handle_mesh: MeshInstance3D = $PivotRoot/HandleMesh
@onready var head_mesh: MeshInstance3D = $PivotRoot/HeadMesh
@onready var cap_left_mesh: MeshInstance3D = $PivotRoot/CapLeftMesh
@onready var cap_right_mesh: MeshInstance3D = $PivotRoot/CapRightMesh
@onready var shockwave_ring: MeshInstance3D = $ShockwaveRing

var _tween: Tween = null


func _ready() -> void:
	_apply_materials()
	visible = false


func _apply_materials() -> void:
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color("#8D4925")
	wood_mat.roughness = 0.75
	handle_mesh.material_override = wood_mat

	var head_mat := StandardMaterial3D.new()
	head_mat.albedo_color = Color("#C0392B")
	head_mat.roughness = 0.4
	head_mat.metallic = 0.2
	head_mesh.material_override = head_mat

	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color("#FFB800")
	gold_mat.metallic = 0.55
	gold_mat.roughness = 0.25
	cap_left_mesh.material_override = gold_mat
	cap_right_mesh.material_override = gold_mat

	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.88, 0.25, 0.85)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color("#FFE047")
	ring_mat.emission_energy_multiplier = 1.6
	shockwave_ring.material_override = ring_mat


func play_strike_at(target_world_pos: Vector3) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	global_position = target_world_pos
	visible = true
	pivot_root.position = Vector3(0.75, 0.55, 0.2)
	pivot_root.rotation = Vector3(0.15, -0.35, -1.15)
	shockwave_ring.visible = false
	shockwave_ring.scale = Vector3(0.35, 1.0, 0.35)

	_tween = create_tween()
	_tween.tween_property(pivot_root, "rotation:z", 0.22, 0.10).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func() -> void:
		shockwave_ring.visible = true
	)
	_tween.tween_property(shockwave_ring, "scale", Vector3(1.45, 1.0, 1.45), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_property(pivot_root, "rotation:z", -0.15, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(func() -> void:
		visible = false
	)
