class_name DialogueWorldReader extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const EMPTY_ICON: Texture2D = preload("res://assets/sprites/icons/empty_icon.png")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal finished_reading()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var label_3d: Label3D = $Label3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var reader: DialogueReader = $DialogueReader

@onready var speech_icons_pivot: Node3D = $SpeechIconsPivot
@onready var speech_icons: Node3D = $SpeechIconsPivot/SpeechIcons

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	mesh_instance_3d.mesh = mesh_instance_3d.mesh.duplicate()
	mesh_instance_3d.set_surface_override_material(0, mesh_instance_3d.get_surface_override_material(0).duplicate())
	reader.sound_queue.connect(_on_sound_queue)
	reader.line_changed.connect(_on_line_changed)
	reader.finished_reading.connect(_on_finished_reading)
	
	init_icons()
	clear_icons()

func _physics_process(_delta: float) -> void:
	label_3d.text = reader.active_text
	mesh_instance_3d.mesh.size.x = label_3d.text.length() * 0.11
	mesh_instance_3d.get_surface_override_material(0).uv1_scale.x = mesh_instance_3d.mesh.size.x / .32
	if reader.is_reading():
		mesh_instance_3d.get_surface_override_material(0).albedo_color = Color.WHITE
	else:
		mesh_instance_3d.get_surface_override_material(0).albedo_color = Color.GOLDENROD
	
	var player_cameras: Array[Camera3D] = []
	if !is_instance_valid(Util.player.camera_rig): return
	player_cameras.append(Util.player.camera_rig.camera_3d)
	for extra_player in Util.extra_players:
		if !is_instance_valid(extra_player) || !is_instance_valid(extra_player.camera_rig): continue
		player_cameras.append(extra_player.camera_rig.camera_3d)
	
	var closest_camera: Camera3D = null
	var closest_distance: float = 100.0
	for camera in player_cameras:
		if !is_instance_valid(camera): continue
		var distance: float = global_position.distance_to(camera.global_position)
		if distance < closest_distance:
			closest_camera = camera
			closest_distance = distance
	
	if is_instance_valid(closest_camera): speech_icons_pivot.look_at(closest_camera.global_position)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func init_icons() -> void:
	var my_icons: Array[Node] = speech_icons.get_children()
	for icon in my_icons: icon.set_surface_override_material(0, icon.get_surface_override_material(0).duplicate())

func clear_icons() -> void:
	var my_icons: Array[Node] = speech_icons.get_children()
	for icon in my_icons: icon.get_surface_override_material(0).albedo_texture = EMPTY_ICON

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_sound_queue(sound_id: int, sound_type: int, volume_db: float, pitch: float) -> void:
	SoundManager.play_3d_sfx(sound_id, sound_type, global_position, volume_db, 5.0, pitch)

func _on_line_changed() -> void:
	if !reader.active_line: return
	var my_icons: Array[Node] = speech_icons.get_children()
	for icon in my_icons: icon.get_surface_override_material(0).albedo_texture = EMPTY_ICON
	for i in reader.active_line.icons.size():
		my_icons[i].get_surface_override_material(0).albedo_texture = reader.active_line.icons[i]

func _on_finished_reading() -> void:
	finished_reading.emit()
