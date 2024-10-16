class_name GatewayBase extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var portal_plane: MeshInstance3D = $PortalArea/PortalPlane
@onready var portal_collision_shape_3d: CollisionShape3D = $PortalArea/PortalCollisionShape3D
@onready var portal_area: Area3D = $PortalArea
@onready var label_3d: Label3D = $PortalArea/PortalPlane/Label3D

@export var data: GatewayData: set = _set_data

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
var readied: bool

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_data(_data: GatewayData) -> void:
	data = _data
	if !readied: return
	
	data.dims.y = 7.0
	portal_plane.mesh.size = Vector2(data.dims)
	portal_plane.position = Vector3(data.dims.x, data.dims.y, 0.0) * 0.5 + Vector3.RIGHT * 0.125
	
	portal_collision_shape_3d.shape.size = Vector3(data.dims.x, data.dims.y, 0.0) - Vector3(0.25, 0.25, 0.0)
	portal_collision_shape_3d.position = Vector3(data.dims.x, data.dims.y, 0.0) * 0.5 + Vector3.RIGHT * 0.125
	
	var level_data: LevelData = Util.main.level.LEVEL_DATABASE.database[data.destination_level_id]
	if level_data.required_level_id_to_be_played != -1 && !Util.main.game_progress_data.levels_beaten.has(level_data.required_level_id_to_be_played):
		portal_plane.hide()
		portal_area.collision_layer = 0
		portal_area.collision_mask = 0
	label_3d.text = level_data.name
	
	#var level_model: Node3D = Util.main.level.get_terrain_model_scene_from_id(data.destination_level_id)
	#level_model.position.z = 4
	#add_child(level_model)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	portal_plane.mesh = portal_plane.mesh.duplicate()
	
	readied = true
	data = data

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_portal_area_body_entered(body: Node3D) -> void:
	if body is Character: body.entered_gateway.emit(data)
