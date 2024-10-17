class_name HUDGui extends Control

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var coins_icon: TextureRect = $MarginContainer/HBoxContainer3/HBoxContainer/HBoxContainer/CoinsIcon
@onready var coins_label: Label = $MarginContainer/HBoxContainer3/HBoxContainer/HBoxContainer/CoinsLabel
@onready var bread_icon: TextureRect = $MarginContainer/HBoxContainer3/HBoxContainer/HBoxContainer2/BreadIcon
@onready var bread_label: Label = $MarginContainer/HBoxContainer3/HBoxContainer/HBoxContainer2/BreadLabel

@onready var recipes: MarginContainer = $Recipes

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_viewport_size_changed() -> void:
	coins_label.add_theme_font_size_override("font_size", get_viewport().size.y * 0.0463)
	bread_label.add_theme_font_size_override("font_size", get_viewport().size.y * 0.0463)
