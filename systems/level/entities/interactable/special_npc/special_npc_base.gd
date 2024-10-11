class_name SpecialNPCBase extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var dialogue_world_reader: DialogueWorldReader = $DialogueWorldReader

var data: SpecialNPCData: set = _set_data
var model: Node3D
var start_position: Vector3

var readied: bool

var spawned: bool
var spawn_animation_started: bool
var spawn_timer: float

var dialogue_data: DialogueData

var level_id_to_send_player_to_override: int = -10

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_data(_data: SpecialNPCData) -> void:
	data = _data
	
	if !readied: return
	
	if is_instance_valid(model): model.queue_free()
	model = data.scene.instantiate()
	add_child(model)
	dialogue_world_reader.position.y = data.height

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	readied = true
	data = data
	start_position = global_position
	
	print(data.level_id_to_send_player_to)
	
	if data.spawn_animation == SpecialNPCData.SpawnAnimation.RISE_FROM_GROUND:
		global_position.y = -data.height
	
	await get_tree().create_timer(data.dialogue_spawn_delay).timeout
	dialogue_world_reader.finished_reading.connect(_on_dialogue_finished_reading)
	dialogue_data.speaker = data.speaker_data
	dialogue_world_reader.reader.data = dialogue_data
	dialogue_world_reader.reader.start()

func _physics_process(delta: float) -> void:
	if !spawned: _update_spawn_animation(delta)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func interact(_source: Character, _controller: PlayerController) -> void:
	if dialogue_world_reader.reader.is_reading():
		dialogue_world_reader.reader.skip_to_end_of_current_line()
	else:
		dialogue_world_reader.reader.skip_line()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _update_spawn_animation(delta: float) -> void:
	if data.spawn_animation == SpecialNPCData.SpawnAnimation.NONE:
		spawned = true
	else:
		if !spawn_animation_started:
			SoundManager.play_pitched_3d_sfx(2, SoundDatabase.SoundType.SFX_FOLEY, global_position)
			spawn_animation_started = true
		
		spawn_timer += delta
		if spawn_timer >= data.spawn_animation_time:
			global_position = start_position
			spawned = true
		else:
			var spawn_percent: float = spawn_timer / data.spawn_animation_time
			global_position.y = -data.height + data.height * spawn_percent
			global_position.x = start_position.x + randf_range(-0.05, 0.05)
			global_position.z = start_position.z + randf_range(-0.05, 0.05)

func _on_dialogue_finished_reading() -> void:
	if data.dialogue_finished_action == SpecialNPCData.DialogueFinishedAction.DISAPPEAR:
		queue_free()
	elif data.dialogue_finished_action == SpecialNPCData.DialogueFinishedAction.SEND_TO_LEVEL:
		if level_id_to_send_player_to_override > -1:
			Util.main.level.load_from_level_id(level_id_to_send_player_to_override)
		elif data.level_id_to_send_player_to > -1:
			Util.main.level.load_from_level_id(data.level_id_to_send_player_to)
