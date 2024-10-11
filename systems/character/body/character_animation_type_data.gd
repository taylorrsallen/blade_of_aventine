class_name CharacterAnimationTypeData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const STEP_FACTOR: float = 0.203125

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
enum CharacterAnimationType {
	IDLE,
	WALK,
	SPRINT,
	EAT,
	GRAB,
	DANCE,
	ATTACK,
	SPECIAL,
	STAGGER,
	DIE,
}

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var type: CharacterAnimationType
@export var steps: int = 8
@export var blend_lerp_speed: float = 5.0
@export var step_speed_multiplier: float = 1.0
@export var step_time_cd: float = 0.1
@export var one_shot: bool

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func get_blend_parameter() -> String:
	match type:
		CharacterAnimationType.IDLE: return ""
		CharacterAnimationType.WALK: return "parameters/movement_blend/blend_amount"
		CharacterAnimationType.SPRINT: return "parameters/movement_type_blend/blend_position"
		CharacterAnimationType.EAT: return "parameters/eating_blend/blend_amount"
		CharacterAnimationType.GRAB: return "parameters/grabbing_blend/blend_amount"
		CharacterAnimationType.DANCE: return "parameters/dancing_blend/blend_amount"
		CharacterAnimationType.ATTACK: return "parameters/attack_blend/blend_amount"
		CharacterAnimationType.SPECIAL: return "parameters/special_blend/blend_amount"
		CharacterAnimationType.STAGGER: return "parameters/stagger_blend/blend_amount"
		_: return "parameters/die_blend/blend_amount"

func get_step_parameter() -> String:
	match type:
		CharacterAnimationType.IDLE: return "parameters/idle_step/seek_request"
		CharacterAnimationType.WALK: return "parameters/movement_step/seek_request"
		CharacterAnimationType.SPRINT: return ""
		CharacterAnimationType.EAT: return "parameters/eating_step/seek_request"
		CharacterAnimationType.GRAB: return "parameters/grabbing_step/seek_request"
		CharacterAnimationType.DANCE: return "parameters/dancing_step/seek_request"
		CharacterAnimationType.ATTACK: return "parameters/attack_step/seek_request"
		CharacterAnimationType.SPECIAL: return "parameters/special_step/seek_request"
		CharacterAnimationType.STAGGER: return "parameters/stagger_step/seek_request"
		_: return "parameters/die_step/seek_request"
