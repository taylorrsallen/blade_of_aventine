class_name UnitSpawner extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
var batch_spawners: Array[LevelWaveBatchSpawner]

@export var spawn_max: int = 50
var spawned: int

@onready var gate_rotation: Node3D = $GateRotation
@onready var gate_0_pivot: Node3D = $GateRotation/Gate0Pivot
@onready var gate_1_pivot: Node3D = $GateRotation/Gate1Pivot

var gate_open_target: float
var gate_open_blend: float

var gate_close_cd: float = 5.0
var gate_close_timer: float

@onready var next_wave_icons: WaveContentsIcon3D = $GateRotation/NextWaveIcons
@onready var active_wave_icons: WaveContentsIcon3D = $GateRotation/ActiveWaveIcons
@onready var incoming_wave_icons: WaveContentsIcon3D = $GateRotation/IncomingWaveIcons

@onready var label_3d: Label3D = $GateRotation/Label3D

var id: int

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	Util.main.level.wave_progress_changed.connect(_on_wave_progress_changed)
	Util.main.level.next_wave_icons_changed.connect(_on_next_wave_icons_changed)
	Util.main.level.active_wave_icons_changed.connect(_on_active_wave_icons_changed)
	Util.main.level.incoming_wave_icons_changed.connect(_incoming_wave_icons_changed)

func _physics_process(delta: float) -> void:
	var spawners_to_remove: Array[LevelWaveBatchSpawner] = []
	for spawner in batch_spawners: if spawner._try_finish_spawning(delta, self): spawners_to_remove.append(spawner)
	for spawner in spawners_to_remove: batch_spawners.erase(spawner)
	
	if batch_spawners.is_empty():
		gate_close_timer += delta
		if gate_close_timer >= gate_close_cd:
			gate_close_timer = 0.0
			gate_open_target = 0.0
	else:
		gate_open_target = 1.0
	
	gate_open_blend = lerpf(gate_open_blend, gate_open_target, delta * 10.0)
	gate_0_pivot.rotation_degrees.y = lerpf(0.0, -90.0, gate_open_blend)
	gate_1_pivot.rotation_degrees.y = lerpf(0.0, 90.0, gate_open_blend)
	
	label_3d.text = "%s / %s" % [Util.main.level.waves_passed, Util.main.level.data.waves.size()]
	#label_3d.text = str(id)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func spawn_batch(batch_data: LevelWaveBatchData) -> void:
	var batch_spawner: LevelWaveBatchSpawner = LevelWaveBatchSpawner.new()
	batch_spawner.data = batch_data
	batch_spawners.append(batch_spawner)

func _on_unit_killed() -> void:
	spawned -= 1

func disable_collision() -> void:
	$GateRotation/StaticBody3D.collision_layer = 0

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_wave_progress_changed(progress: float) -> void:
	if is_instance_valid(incoming_wave_icons): incoming_wave_icons.position.y = lerpf(15.0, 1.0, progress)
	if progress > 0.9:
		incoming_wave_icons.hide()
	else:
		incoming_wave_icons.show()

func _on_next_wave_icons_changed(textures: Array[Texture2D], spawner_ids: Array[int]) -> void:
	if !is_instance_valid(next_wave_icons): return
	var icons_set: int = 0
	for i in spawner_ids.size():
		if spawner_ids[i] != id: continue
		next_wave_icons.set_icon_texture(icons_set, textures[i])
		icons_set += 1

func _incoming_wave_icons_changed(textures: Array[Texture2D], spawner_ids: Array[int]) -> void:
	if !is_instance_valid(incoming_wave_icons): return
	var icons_set: int = 0
	for i in spawner_ids.size():
		if spawner_ids[i] != id: continue
		incoming_wave_icons.set_icon_texture(icons_set, textures[i])
		icons_set += 1

func _on_active_wave_icons_changed(textures: Array[Texture2D]) -> void:
	if is_instance_valid(active_wave_icons): active_wave_icons.set_icon_textures(textures)
