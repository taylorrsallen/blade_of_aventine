class_name TowerTypeData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
enum TargetingPreference {
	HIGHEST_HP,
	LOWEST_HP,
	HIGHEST_ARMOR,
	LOWEST_ARMOR,
	SLOWEST,
	FASTEST,
	RANDOM,
	FURTHEST,
	CLOSEST,
}

enum TargetingType {
	GROUND_ONLY,
	FLYING_ONLY,
	ALL,
}

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export_category("Core")
@export var name: String
@export var level_blueprints: Array[TowerStatsData] = []

@export_category("Anatomy")
@export var pitch_pivot_scene: PackedScene
@export var yaw_pivot_scene: PackedScene
@export var foundation_scene: PackedScene

@export_category("Gameplay")
@export var targeting_type: TargetingType
@export var targeting_preference: TargetingPreference
@export var build_time: float = 5.0
@export var exp_needed_for_first_level: float = 50.0
@export var extra_exp_requirement_per_level: float = 75.0
@export var seek_targets: bool = true
@export var shoot_while_held: bool

@export_category("Projectile")
@export var projectile: PackedScene
@export var projectile_data: ProjectileData
@export var fire_sound: SoundReferenceData
@export var reload_sound: SoundReferenceData

@export_category("Duct Tape")
@export var interactable_data: InteractableData
