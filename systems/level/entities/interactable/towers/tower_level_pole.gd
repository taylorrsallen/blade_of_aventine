class_name TowerLevelPole extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
var EXPERIENCE_MESHES: Array[MeshInstance3D]

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var level_pole_flag: MeshInstance3D = $aventine_level_flag/level_pole_flag

var experience_percent: float: set = _set_experience_percent
var experience_color: Color: set = _set_experience_color
var flag_color: Color: set = _set_flag_color

var readied: bool

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_experience_percent(_experience_percent: float) -> void:
	experience_percent = clampf(_experience_percent, 0.0, 1.0)
	if readied: _refresh_experience_meshes()

func _set_experience_color(_experience_color: Color) -> void:
	experience_color = _experience_color
	if !readied: return
	EXPERIENCE_MESHES[0].get_surface_override_material(0).albedo_color = experience_color
	EXPERIENCE_MESHES[0].get_surface_override_material(0).emission = experience_color

func _set_flag_color(_flag_color: Color) -> void:
	flag_color = _flag_color
	if readied: level_pole_flag.get_surface_override_material(0).albedo_color = flag_color

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	EXPERIENCE_MESHES = [
		$aventine_level_flag/level_pole_experience_00,
		$aventine_level_flag/level_pole_experience_01,
		$aventine_level_flag/level_pole_experience_02,
		$aventine_level_flag/level_pole_experience_03,
		$aventine_level_flag/level_pole_experience_04,
		$aventine_level_flag/level_pole_experience_05,
		$aventine_level_flag/level_pole_experience_06,
		$aventine_level_flag/level_pole_experience_07,
		$aventine_level_flag/level_pole_experience_08,
		$aventine_level_flag/level_pole_experience_09,
	]
	
	EXPERIENCE_MESHES[0].set_surface_override_material(0, EXPERIENCE_MESHES[0].mesh.surface_get_material(0).duplicate())
	EXPERIENCE_MESHES[0].get_surface_override_material(0).albedo_color = experience_color
	EXPERIENCE_MESHES[0].get_surface_override_material(0).emission_enabled = true
	EXPERIENCE_MESHES[0].get_surface_override_material(0).emission = experience_color
	EXPERIENCE_MESHES[0].get_surface_override_material(0).emission_energy_multiplier = 0.25
	EXPERIENCE_MESHES[0].get_surface_override_material(0).emission_texture = EXPERIENCE_MESHES[0].get_surface_override_material(0).albedo_texture
	level_pole_flag.set_surface_override_material(0, level_pole_flag.mesh.surface_get_material(0).duplicate())
	
	for i in 8:
		var index: int = i + 1
		EXPERIENCE_MESHES[index].set_surface_override_material(0, EXPERIENCE_MESHES[0].get_surface_override_material(0))
	
	readied = true
	_refresh_experience_meshes()

func _refresh_experience_meshes() -> void:
	for mesh in EXPERIENCE_MESHES: mesh.hide()
	
	var meshes_to_show: int = ceilf(experience_percent * 9.0)
	for i in meshes_to_show: EXPERIENCE_MESHES[i].show()
