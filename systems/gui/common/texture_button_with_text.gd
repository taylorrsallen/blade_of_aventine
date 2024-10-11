@tool
class_name TextureButtonWithText extends TextureButton

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export_multiline var text: String: set = _set_text
@export var pressed_sound: SoundReferenceData
@export var hovered_sound: SoundReferenceData

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_text(_text: String) -> void:
	text = _text
	
	if get_children().is_empty(): return
	$Label.text = text

func _on_pressed() -> void:
	var height_percent: float = global_position.y / get_viewport().size.y
	if pressed_sound: SoundManager.play_pitched_ui_sfx(pressed_sound.id, pressed_sound.type, 0.95 - height_percent * 0.5, 1.05 - height_percent * 0.5)

func _on_mouse_entered() -> void:
	var height_percent: float = global_position.y / get_viewport().size.y
	if !button_pressed && hovered_sound: SoundManager.play_pitched_ui_sfx(hovered_sound.id, hovered_sound.type, 0.9 - height_percent * 0.5, 1.1 - height_percent * 0.5)
