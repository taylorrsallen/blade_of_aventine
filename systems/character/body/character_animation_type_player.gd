class_name CharacterAnimationTypePlayer

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
var data: CharacterAnimationTypeData
var blend: float
var target: float
var step_timer: float
var current_step: int

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func update_blend(delta: float, animation_tree: AnimationTree) -> void:
	blend = lerpf(blend, target, delta * data.blend_lerp_speed)
	var blend_parameter: String = data.get_blend_parameter()
	if blend_parameter.is_empty(): return
	animation_tree[blend_parameter] = get_truncated_blend()

func advance_step(delta: float, animation_tree: AnimationTree) -> void:
	if target < 0.05: return
	
	var step_parameter: String = data.get_step_parameter()
	if step_parameter.is_empty(): return
	
	step_timer += delta * data.step_speed_multiplier
	if step_timer >= data.step_time_cd:
		step_timer -= data.step_time_cd
		if data.one_shot && current_step + 1 >= data.steps: target = 0.0
		current_step = (current_step + 1) % data.steps
	
	animation_tree[step_parameter] = current_step * CharacterAnimationTypeData.STEP_FACTOR

func get_truncated_blend() -> float:
	return roundf(blend * 5.0) * 0.2
