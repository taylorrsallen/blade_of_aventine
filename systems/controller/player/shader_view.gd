extends Control
class_name ShaderView

@onready var vignette: ColorRect = $Vignette
@onready var dither: ColorRect = $Dither

func set_underwater() -> void:
	dither.hide()

func set_normal() -> void:
	dither.show()
