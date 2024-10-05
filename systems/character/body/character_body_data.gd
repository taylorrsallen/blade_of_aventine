class_name CharacterBodyData extends Resource

@export_category("Base")
@export var body_scene: PackedScene
@export var height: float

@export_category("Movement")
@export var base_speed: float
@export var sprint_speed: float

@export_category("Sound")
@export var random_noises_pool: SoundPoolData

@export_category("Game Resources")
@export var drops_data: DropsData
@export var experience_value_range: Vector2 = Vector2(1.0, 1.0)

@export_category("Violence")
@export var attack_damage: float = 1.0
@export var attack_rate: float = 1.0
@export var attack_range: float = 1.0

@export_category("Eating Bread")
@export var eating_sounds_pool: SoundPoolData
@export var time_to_eat: float = 1.0
@export var eating_noise_cd: float = 0.25
@export var bread_to_eat: int = 1

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func get_experience_value() -> float:
	return randf_range(experience_value_range.x, experience_value_range.y)
