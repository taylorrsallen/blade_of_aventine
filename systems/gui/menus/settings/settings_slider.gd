@tool
class_name SettingsSlider extends PanelContainer

signal value_changed(value: float)

@onready var label: Label = $MarginContainer/HBoxContainer/Label
@onready var label_2: Label = $MarginContainer/HBoxContainer/Label2
@onready var slider: HSlider = $MarginContainer/HBoxContainer/Slider

@export var text: String: set = _set_text
@export var min_max: Vector2 = Vector2(0, 150): set = _set_min_max
@export var value: float = 100: set = _set_value

func _set_min_max(_min_max: Vector2) -> void:
	min_max = _min_max
	if is_instance_valid(slider):
		slider.min_value = min_max.x
		slider.max_value = min_max.y

func _set_value(_value: float) -> void:
	value = _value
	if is_instance_valid(slider): slider.value = value

func _set_text(_text: String) -> void:
	text = _text
	if is_instance_valid(label): label.text = text

func _ready() -> void:
	text = text
	value = value
	min_max = min_max
	if is_instance_valid(label_2) && is_instance_valid(slider): label_2.text = str(slider.value)

func _on_slider_value_changed(value: float) -> void:
	if is_instance_valid(label_2): label_2.text = str(value)
	value_changed.emit(value)
