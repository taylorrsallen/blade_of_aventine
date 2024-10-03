class_name TowerBase extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var experience: float
@export var team: int

@export var range: float = 5.0
@export var move_speed_multiplier: float = 1.0
@export var attack_speed_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0

var enemies: Array[Node3D] = []
var protect_position: bool
@export var position_to_protect: Vector3

@export var target: Node3D

@export var burst_size: int = 4
@export var burst_cd: float = 0.5
var burst_count: int
var burst_timer: float

@export var firing_cd: float = 1.0
var firing: bool
var firing_timer: float

@export var build_time: float = 5.0
var built: bool
var build_timer: float

var start_position: Vector3

@export var max_health: float = -1.0
@export var health: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func init() -> void:
	start_position = position
	start_position.y = 0.0

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func try_build_tower(delta: float) -> bool:
	if !built:
		build_timer += delta
		if build_timer >= build_time:
			position = start_position
			built = true
			return true
		else:
			var build_percent: float = build_timer / build_time
			position.y = -2.0 + 2.0 * build_percent
			position.x = start_position.x + randf_range(-0.05, 0.05)
			position.z = start_position.z + randf_range(-0.05, 0.05)
		
		return false
	return true

func damage(damage_data: DamageData) -> void:
	if max_health < 0.0: return
	health -= damage_data.damage_strength
	if health < 0.0:
		print("Tower dies")
