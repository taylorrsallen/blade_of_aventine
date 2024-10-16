class_name ShopTableModel extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var animation_tree: AnimationTree = $AnimationTree

@export var talk_sounds: SoundPoolData

var talking_step: int
var thinking_step: int
var talking_target: float
var talking_blend: float
var step_timer: float
var step_time_cd: float = 0.2

var talk_audio_cd: float = 0.4
var talk_audio_timer: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _physics_process(delta: float) -> void:
	talk_audio_timer = min(talk_audio_timer + delta, talk_audio_cd)
	talking_blend = lerpf(talking_blend, talking_target, delta * 5.0)
	animation_tree["parameters/talking_blend/blend_amount"] = get_truncated_talking_blend()
	advance_step(delta)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func advance_step(delta: float) -> void:
	step_timer += delta
	if step_timer >= step_time_cd:
		step_timer -= step_time_cd
		thinking_step = (thinking_step + 1) % 8
		if talking_step + 1 > 7:
			talking_step = 7
			talking_target = 0.0
		else:
			talking_step = (talking_step + 1) % 8
	
	animation_tree["parameters/thinking_step/seek_request"] = thinking_step * CharacterAnimationTypeData.STEP_FACTOR
	animation_tree["parameters/talking_step/seek_request"] = talking_step * CharacterAnimationTypeData.STEP_FACTOR

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
## One time animations
func talk() -> void:
	animation_tree["parameters/talking_blend/blend_amount"] = 0.0
	talking_step = 0
	talking_target = 1.0
	
	if talk_audio_timer == talk_audio_cd && talk_sounds:
		talk_audio_timer = 0.0
		var sound: SoundReferenceData = talk_sounds.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_position, 0.9, 1.1, sound.volume_db, 5.0)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func get_truncated_talking_blend() -> float:
	return roundf(talking_blend * 5.0) * 0.2
