class_name DialogueWorldReader extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal finished_reading()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var label_3d: Label3D = $Label3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var reader: DialogueReader = $DialogueReader

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	reader.sound_queue.connect(_on_sound_queue)
	reader.finished_reading.connect(_on_finished_reading)

func _physics_process(_delta: float) -> void:
	label_3d.text = reader.active_text
	mesh_instance_3d.mesh.size.x = label_3d.text.length() * 0.11

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_sound_queue(sound_id: int, sound_type: int, volume_db: float, pitch: float) -> void:
	SoundManager.play_3d_sfx(sound_id, sound_type, global_position, volume_db, 5.0, pitch)

func _on_finished_reading() -> void:
	finished_reading.emit()
