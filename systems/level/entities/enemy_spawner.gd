class_name EnemySpawner extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const CHARACTER: PackedScene = preload("res://systems/character/character.scn")
const AI_CONTROLLER: PackedScene = preload("res://systems/controller/ai/ai_controller.scn")

const FACTION_DATABASE: FactionDatabase = preload("res://resources/factions/faction_database.res")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var spawn_count: int
@export var spawn_rate: float = 0.5
var spawn_timer: float = 0.0

@export var spawn_max: int = 100
var spawned: int

@export var target_faction_id: int
@export var faction_id: int
@export var unit_id: int

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _physics_process(delta: float) -> void:
	if spawned >= spawn_max: return
	if spawn_count == 0: return
	
	spawn_timer += delta
	if spawn_timer >= spawn_rate:
		spawn_timer -= spawn_rate
		spawn_enemy()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func spawn_enemy() -> void:
	spawned += 1
	spawn_count -= 1
	
	var ai_controller: AIController = AI_CONTROLLER.instantiate()
	ai_controller.faction_id = faction_id
	ai_controller.target_faction_id = target_faction_id
	Util.main.level.add_ai(faction_id, ai_controller)
	ai_controller.character = CHARACTER.instantiate()
	ai_controller.character.body_data = FACTION_DATABASE.database[faction_id].units[unit_id].body_data
	ai_controller.character.team = FACTION_DATABASE.database[faction_id].team_id
	ai_controller.character.position = global_position
	ai_controller.character.jog_speed = 1.5
	ai_controller.character.killed.connect(_on_enemy_killed)
	ai_controller.add_child(ai_controller.character)

func _on_enemy_killed() -> void:
	spawned -= 1
