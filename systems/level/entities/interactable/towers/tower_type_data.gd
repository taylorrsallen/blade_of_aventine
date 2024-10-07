class_name TowerTypeData extends Resource

@export var name: String

@export var level_blueprints: Array[TowerStatsBlueprintData] = []
@export var build_time: float = 5.0
@export var exp_needed_for_first_level: float = 50.0
@export var extra_exp_requirement_per_level: float = 75.0

@export_category("Projectile")
@export var projectile: PackedScene
@export var projectile_data: ProjectileData
@export var projectile_sound: SoundReferenceData
@export var projectile_hit_sound: SoundReferenceData
@export var reload_sound: SoundReferenceData
