class_name WaveContentsIcon3D extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const EMPTY_ICON: Texture2D = preload("res://assets/sprites/icons/empty_icon.png")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var icons: Array[MeshInstance3D] = [
	$WaveIcon0,
	$WaveIcon1,
	$WaveIcon2,
	$WaveIcon3,
]

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	for icon in icons: icon.set_surface_override_material(0, icon.get_surface_override_material(0).duplicate())
	clear()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func clear() -> void:
	for icon in icons: icon.get_surface_override_material(0).albedo_texture = EMPTY_ICON

func set_icon_texture(icon_id: int, _texture: Texture2D) -> void:
	if icon_id >= 4: return
	icons[icon_id].get_surface_override_material(0).albedo_texture = _texture

func set_icon_textures(textures: Array[Texture2D]) -> void:
	clear()
	for i in textures.size(): set_icon_texture(i, textures[i])
