class_name TowerTypeData extends Resource

@export var name: String

@export var level_blueprints: Array[TowerStatsBlueprintData] = []
@export var build_time: float = 5.0

@export var base_damage_data: DamageData
@export var projectile: PackedScene
