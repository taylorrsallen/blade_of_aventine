class_name ProjectileData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
enum Trajectory {
	LINEAR,
	ARC_ROLLING,
	ARC_LEADING,
}

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var curve: Curve
@export var trajectory: Trajectory
@export var perfect_accuracy: bool = true

@export var hitbox_radius: float = 0.1

@export var damage_data: DamageData
@export var damage_on_impact: bool = true
@export var aoe_damage_falloff: Curve
@export var aoe_radius: float
@export var aoe_force: float

@export var speed: float

@export var die_on_contact: bool = true

@export var lifetime: float = 10.0

@export var piercing_hits: int
@export var pierce_delay: float

@export var hit_sounds: SoundPoolData
@export var hit_effect: PackedScene

@export var model_scene: PackedScene

@export var stick_in_target: bool
