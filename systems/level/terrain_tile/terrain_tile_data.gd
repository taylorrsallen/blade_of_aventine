class_name TerrainTileData extends Resource

@export var name: String
@export_range(0, 255) var g_value: int
@export var tile_mesh_id: int
@export var blocks_entity_placement: bool
@export var ground_obstacle: bool
@export var ground_pathing_obstacle: bool
@export var sky_obstacle: bool
@export var height: int
@export var footstep_sounds: SoundPoolData
