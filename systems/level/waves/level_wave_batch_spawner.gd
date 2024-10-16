class_name LevelWaveBatchSpawner

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const CHARACTER: PackedScene = preload("res://systems/character/character.scn")
const AI_CONTROLLER: PackedScene = preload("res://systems/controller/ai/ai_controller.scn")

var FACTION_DATABASE: FactionDatabase = load("res://resources/factions/faction_database.res")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
var data: LevelWaveBatchData: set = _set_data

var spawn_count: int
var spawn_delay_timer: float
var spawn_timer: float
var coins_per_spawn: Array[int]

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_data(_data: LevelWaveBatchData) -> void:
	data = _data
	
	var coins_to_spawn: int = data.coins
	coins_per_spawn.resize(data.spawn_count)
	while coins_to_spawn > 0:
		var coin_value: int = 10
		if coins_to_spawn < 10: coin_value = coins_to_spawn
		coins_to_spawn -= coin_value
		coins_per_spawn[randi_range(0, coins_per_spawn.size() - 1)] += coin_value
	
	spawn_count = data.spawn_count

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _try_finish_spawning(delta: float, spawner: UnitSpawner) -> bool:
	if spawn_delay_timer < data.spawn_delay:
		spawn_delay_timer += delta
		return false
	
	if spawn_count == 0: return true
	
	if spawner.spawned < spawner.spawn_max:
		spawn_timer += delta
		if spawn_timer >= data.spawn_rate:
			spawn_timer -= data.spawn_rate
			spawn_enemy(spawner)
	
	return false

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func spawn_enemy(spawner: UnitSpawner) -> void:
	spawner.spawned += 1
	spawn_count -= 1
	
	var ai_controller: AIController = AI_CONTROLLER.instantiate()
	ai_controller.faction_id = data.faction_id
	ai_controller.target_faction_id = data.target_faction_id
	Util.main.level.add_ai(data.faction_id, ai_controller)
	ai_controller.character = CHARACTER.instantiate()
	ai_controller.character.body_data = FACTION_DATABASE.database[data.faction_id].units[data.unit_id].body_data
	ai_controller.character.team = FACTION_DATABASE.database[data.faction_id].team_id
	ai_controller.character.position = spawner.global_position
	ai_controller.character.jog_speed = 1.5
	ai_controller.character.killed.connect(spawner._on_unit_killed)
	ai_controller.add_child(ai_controller.character)
	
	var drops: DropsData = DropsData.new()
	var coins: Array[PickupData] = CoinSpawner.get_coins_for_amount(coins_per_spawn.pop_back())
	for coin in coins:
		var drop_data: DropData = DropData.new()
		drop_data.pickup_data = coin
		drop_data.amount = 1
		drops.drops.append(drop_data)
	
	ai_controller.character.drops_data = drops
