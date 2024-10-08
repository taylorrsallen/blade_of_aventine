class_name WaveContentsIcon extends TextureRect

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const EMPTY_ICON: Texture2D = preload("res://assets/sprites/icons/empty_icon.png")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var icons: Array[TextureRect] = [
	self,
	$WaveIcon1,
	$WaveIcon1/WaveIcon2,
	$WaveIcon1/WaveIcon2/WaveIcon3,
]

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func copy_data(other_wave_contents_icon: WaveContentsIcon) -> void:
	for i in icons.size():
		icons[i].texture = other_wave_contents_icon.icons[i].texture
		if !icons[i].texture: icons[i].hide()

func clear() -> void:
	for icon in icons: icon.texture = EMPTY_ICON

func set_icon_texture(icon_id: int, _texture: Texture2D) -> void:
	icons[icon_id].texture = _texture
