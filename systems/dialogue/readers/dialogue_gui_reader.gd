class_name DialogueGuiReader extends Control

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal finished_reading()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var label: Label = $PanelContainer/MarginContainer/HBoxContainer/PanelContainer/MarginContainer/Label
@onready var reader: DialogueReader = $DialogueReader

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	reader.sound_queue.connect(_on_sound_queue)
	reader.finished_reading.connect(_on_finished_reading)
	reader.start()

func _physics_process(delta: float) -> void:
	label.text = reader.active_text

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_sound_queue(sound_id: int, sound_type: int, volume_db: float, pitch: float) -> void:
	SoundManager.play_ui_sfx(sound_id, sound_type, volume_db, pitch)

func _on_finished_reading() -> void:
	finished_reading.emit()
