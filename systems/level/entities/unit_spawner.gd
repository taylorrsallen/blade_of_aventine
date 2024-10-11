class_name UnitSpawner extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
var batch_spawners: Array[LevelWaveBatchSpawner]

@export var spawn_max: int = 50
var spawned: int

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _physics_process(delta: float) -> void:
	var spawners_to_remove: Array[LevelWaveBatchSpawner] = []
	for spawner in batch_spawners: if spawner._try_finish_spawning(delta, self): spawners_to_remove.append(spawner)
	for spawner in spawners_to_remove: batch_spawners.erase(spawner)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func spawn_batch(batch_data: LevelWaveBatchData) -> void:
	var batch_spawner: LevelWaveBatchSpawner = LevelWaveBatchSpawner.new()
	batch_spawner.data = batch_data
	batch_spawners.append(batch_spawner)

func _on_unit_killed() -> void:
	spawned -= 1
