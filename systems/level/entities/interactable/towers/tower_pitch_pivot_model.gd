class_name TowerPitchPivotModel extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var projectile_emitter: Node3D
@export var no_rotation: bool
var animation_tree: AnimationTree

var fire_step: int
var fire_speed_multiplier: float = 20.0
var reload_percent: float
var step_timer: float
var step_time_cd: float = 0.1

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _physics_process(delta: float) -> void:
	animation_tree = get_node_or_null("AnimationTree")
	if animation_tree:
		animation_tree["parameters/reload_step/seek_request"] = floorf(get_truncated_reload_percent() * 7.0) * CharacterAnimationTypeData.STEP_FACTOR
		advance_step(delta)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func advance_step(delta: float) -> void:
	step_timer += delta * fire_speed_multiplier
	if step_timer >= step_time_cd:
		step_timer -= step_time_cd
		if fire_step + 1 > 7:
			fire_step = 7
			animation_tree["parameters/reload_blend/blend_amount"] = 1.0
		else:
			fire_step = (fire_step + 1) % 8
	
	animation_tree["parameters/fire_step/seek_request"] = fire_step * CharacterAnimationTypeData.STEP_FACTOR

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
## One time animations
func fire() -> void:
	if animation_tree: animation_tree["parameters/reload_blend/blend_amount"] = 0.0
	fire_step = 0

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func get_truncated_reload_percent() -> float:
	return roundf(reload_percent * 5.0) * 0.2
