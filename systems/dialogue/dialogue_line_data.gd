class_name DialogueLineData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export_multiline var line: String
@export var pause_after_finished: float = 1.5
@export var pitch: float = 1.0
@export var speed: float = 1.0
@export var text_color_override: Color = Color.WHITE
@export var is_overriding_speaker_color: bool

@export var icons: Array[Texture2D]
