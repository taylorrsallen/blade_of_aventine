class_name SpecialNPCBase extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const SHRINK_THEN_DIE_WITH_PUFF: PackedScene = preload("res://scenes/vfx/shrink_then_die_with_puff.scn")

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

var interact_cd: float = 0.5
var interact_timer: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_data(_data: SpecialNPCData) -> void:
	data = _data
	
	if !readied: return
	
	if is_instance_valid(model): model.queue_free()
	model = data.scene.instantiate()
	add_child(model)
	dialogue_world_reader.position.y = data.height
	
	if data.dialogue_data_override: dialogue_data = data.dialogue_data_override

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	readied = true
	data = data
	start_position = global_position
	
	if data.spawn_animation == SpecialNPCData.SpawnAnimation.RISE_FROM_GROUND:
		global_position.y = -data.height
	
	if !data.collision: $InteractableCollider.collision_layer = 512
	
	dialogue_world_reader.reader.line_changed.connect(_on_dialogue_line_changed)
	dialogue_world_reader.finished_reading.connect(_on_dialogue_finished_reading)
	dialogue_data.speaker = data.speaker_data
	dialogue_world_reader.reader.data = dialogue_data
	
	await get_tree().create_timer(data.dialogue_spawn_delay).timeout
	dialogue_world_reader.reader.start()

func _physics_process(delta: float) -> void:
	interact_timer += delta
	if !spawned: _update_spawn_animation(delta)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func interact(_source: Character, _controller: PlayerController) -> void:
	if interact_timer < interact_cd: return
	interact_timer = 0.0
	
	if dialogue_world_reader.reader.is_reading():
		dialogue_world_reader.reader.skip_to_end_of_current_line()
	else:
		dialogue_world_reader.reader.skip_line()

func deal_scepter_damage() -> void:
	if destroyed: return
	
	if data.hit_reaction == SpecialNPCData.DialogueFinishedAction.DISAPPEAR:
		if data.dialogue_finished_sound:
			var sound: SoundReferenceData = data.dialogue_finished_sound.pool.pick_random()
			SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_position, 0.9, 1.1, sound.volume_db, 5.0)
		destroy()
	elif data.hit_reaction == SpecialNPCData.DialogueFinishedAction.SEND_TO_LEVEL:
		if level_id_to_send_player_to_override > -1:
			Util.main.level.load_from_level_id(level_id_to_send_player_to_override)
		elif data.level_id_to_send_player_to > -1:
			Util.main.level.load_from_level_id(data.level_id_to_send_player_to)

func destroy() -> void:
	_destroy()
	
	var vfx: LifetimeVFX = SHRINK_THEN_DIE_WITH_PUFF.instantiate()
	vfx.position = global_position + Vector3.UP
	var offset_node: Node3D = Node3D.new()
	offset_node.position = -Vector3.UP
	Util.main.add_child(vfx)
	vfx.add_child(offset_node)
	model.reparent(offset_node, false)

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
	if data.dialogue_finished_sound:
		var sound: SoundReferenceData = data.dialogue_finished_sound.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_position, 0.9, 1.1, sound.volume_db, 5.0)
	
	if data.dialogue_finished_action == SpecialNPCData.DialogueFinishedAction.DISAPPEAR:
		destroy()
	elif data.dialogue_finished_action == SpecialNPCData.DialogueFinishedAction.SEND_TO_LEVEL:
		if level_id_to_send_player_to_override > -1:
			Util.main.level.load_from_level_id(level_id_to_send_player_to_override)
		elif data.level_id_to_send_player_to > -1:
			Util.main.level.load_from_level_id(data.level_id_to_send_player_to)

func _on_dialogue_line_changed() -> void:
	if !dialogue_world_reader.reader.active_line: return
	if data.dialogue_interact_sound:
		var sound: SoundReferenceData = data.dialogue_interact_sound.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_position, 0.9, 1.1, sound.volume_db, 5.0)
