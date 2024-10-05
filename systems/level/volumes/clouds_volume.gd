@tool
extends Node3D
class_name CloudsVolume

## COMPOSITION
@onready var bright_layer: MeshInstance3D = $BrightLayer
@onready var mid_layer: MeshInstance3D = $MidLayer
@onready var dark_layer: MeshInstance3D = $DarkLayer

## DATA
@export_range(0.0, 2.0) var cloudiness: float = 1.0: set = _set_cloudiness
@export_range(0.0, 2.0) var cloud_darkness: float = 1.0: set = _set_cloud_darkness
@export var wind_direction: Vector2 = Vector2.ONE * 0.5: set = _set_wind_direction
@export_range(0.0, 100.0) var wind_speed: float = 0.1: set = _set_wind_speed

@export var bright_layer_base: float = 0.845
@export var mid_layer_base: float = 0.845
@export var dark_layer_base: float = 1.075

@export var bright_layer_base_brightness: float = 1.62
@export var mid_layer_base_brightness: float = 0.435
@export var dark_layer_base_brightness: float = 0.19

func _set_cloudiness(_cloudiness: float) -> void:
	if get_children().is_empty(): return
	
	cloudiness = _cloudiness
	$BrightLayer.get_surface_override_material(0)["shader_parameter/threshold"] = bright_layer_base * (1.0 - (cloudiness - 1.0))
	$MidLayer.get_surface_override_material(0)["shader_parameter/threshold"] = mid_layer_base * (1.0 - (cloudiness - 1.0))
	$DarkLayer.get_surface_override_material(0)["shader_parameter/threshold"] = dark_layer_base * (1.0 - (cloudiness - 1.0))
	$ShadowLayer.get_surface_override_material(0)["shader_parameter/threshold"] = bright_layer_base * (1.0 - (cloudiness - 1.0))

func _set_cloud_darkness(_cloud_darkness: float) -> void:
	if get_children().is_empty(): return
	
	cloud_darkness = _cloud_darkness
	$BrightLayer.get_surface_override_material(0)["shader_parameter/brightness"] = bright_layer_base_brightness * cloud_darkness
	$MidLayer.get_surface_override_material(0)["shader_parameter/brightness"] = mid_layer_base_brightness * cloud_darkness
	$DarkLayer.get_surface_override_material(0)["shader_parameter/brightness"] = dark_layer_base_brightness * cloud_darkness

func _set_wind_direction(_wind_direction: Vector2) -> void:
	if get_children().is_empty(): return
	
	wind_direction = _wind_direction
	$BrightLayer.get_surface_override_material(0)["shader_parameter/wind_direction"] = wind_direction
	$MidLayer.get_surface_override_material(0)["shader_parameter/wind_direction"] = wind_direction
	$DarkLayer.get_surface_override_material(0)["shader_parameter/wind_direction"] = wind_direction
	$ShadowLayer.get_surface_override_material(0)["shader_parameter/wind_direction"] = wind_direction

func _set_wind_speed(_wind_speed: float) -> void:
	if get_children().is_empty(): return
	
	wind_speed = _wind_speed
	$BrightLayer.get_surface_override_material(0)["shader_parameter/speed"] = wind_speed
	$MidLayer.get_surface_override_material(0)["shader_parameter/speed"] = wind_speed
	$DarkLayer.get_surface_override_material(0)["shader_parameter/speed"] = wind_speed
	$ShadowLayer.get_surface_override_material(0)["shader_parameter/speed"] = wind_speed
