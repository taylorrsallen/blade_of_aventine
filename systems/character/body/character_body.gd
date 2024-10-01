extends Node3D
class_name CharacterBody

# ////////////////////////////////////////////////////////////////////////////////////////////////
signal damaged(damage_data: DamageData, area_id: int)

# ////////////////////////////////////////////////////////////////////////////////////////////////
@onready var animation_tree: AnimationTree = $AnimationTree
@export var eye_target: Node3D

@export var stats: CharacterBodyStatsData

var is_free: bool = true

# ////////////////////////////////////////////////////////////////////////////////////////////////
func can_walk() -> bool: return is_free

func set_yaw_look_basis(_basis: Basis) -> void: pass
func set_pitch_look_basis(_basis: Basis) -> void: pass
func set_walking(_active: bool) -> void: pass
func get_eye_target() -> Node3D: return eye_target
func get_head_ik_yaw() -> Node3D: return null
