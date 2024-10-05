class_name EnemySpawner extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const CHARACTER: PackedScene = preload("res://systems/character/character.scn")
const AI_CONTROLLER: PackedScene = preload("res://systems/controller/ai/ai_controller.scn")

const FACTION_DATABASE: FactionDatabase = preload("res://resources/factions/faction_database.res")
const COIN: PickupData = preload("res://resources/pickups/coin.res")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var spawn_count: int
@export var spawn_rate: float = 0.5
var spawn_timer: float = 0.0

@export var spawn_max: int = 100
var spawned: int

@export var target_faction_id: int
@export var faction_id: int
@export var unit_id: int

var coins_per_guy: Array[int]
var coins_to_spawn: int

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _physics_process(delta: float) -> void:
	if spawned >= spawn_max: return
	if spawn_count == 0: return
	
	spawn_timer += delta
	if spawn_timer >= spawn_rate:
		spawn_timer -= spawn_rate
		spawn_enemy()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func refresh() -> void:
	coins_per_guy.resize(spawn_count)
	while coins_to_spawn > 0:
		var coin_value: int = 10
		if coins_to_spawn < 10: coin_value = coins_to_spawn
		coins_to_spawn -= coin_value
		coins_per_guy[randi_range(0, coins_per_guy.size() - 1)] += coin_value

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
	
	var drops: DropsData = DropsData.new()
	var drop_data: DropData = DropData.new()
	drop_data.pickup_data = COIN
	drop_data.amount = coins_per_guy.pop_back() / 10
	drops.drops.append(drop_data)
	ai_controller.character.drops_data = drops

func _on_enemy_killed() -> void:
	spawned -= 1
