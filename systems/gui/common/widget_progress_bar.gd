@tool
class_name TextureProgressBarExceptItWorks extends Control

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const BASE_VIEWPORT_HEIGHT: float = 1600.0
const BASE_HEIGHT: float = 28.0

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var value: float = 0.0: set = _set_value
@export var progress_texture: Texture2D

@export_range(0.0, 1.0) var width_percent: float: set = _set_width_percent
@export var anchor_percent: Vector2: set = _set_anchor_percent
@export var height_size_percent: float = 0.08: set = _set_height_size_percent

@export var direction: int

var readied: bool

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_width_percent(_width_percent: float) -> void:
	width_percent = _width_percent
	if !readied: return
	custom_minimum_size.x = get_viewport().size.x * width_percent * (1.0 / scale.y)

func _set_anchor_percent(_anchor_percent: Vector2) -> void:
	anchor_percent = _anchor_percent
	if !readied: return
	global_position = Vector2(get_viewport().size) * anchor_percent * (1.0 / scale.y)

func _set_height_size_percent(_height_size_percent: float) -> void:
	height_size_percent = _height_size_percent
	if !readied: return
	scale.y = get_viewport().size.y * height_size_percent * 0.01

func _set_value(_value: float) -> void:
	value = clampf(_value, 0.0, 1.0)
	if !readied: return
	$ProgressContainer.custom_minimum_size.x = custom_minimum_size.x * value

func _set_progress_texture(_progress_texture: Texture2D) -> void:
	progress_texture = _progress_texture
	if !readied: return
	$ProgressContainer/ProgressTexture.texture = progress_texture

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	readied = true
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_set_progress_texture(progress_texture)
	_on_viewport_size_changed()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_viewport_size_changed() -> void:
	if direction == 0:
		$ProgressContainer.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	else:
		$ProgressContainer.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	
	width_percent = width_percent
	anchor_percent = anchor_percent
	height_size_percent = height_size_percent
	value = value
