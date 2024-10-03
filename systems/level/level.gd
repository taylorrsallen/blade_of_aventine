class_name Level extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const ENEMY_SPAWNER: PackedScene = preload("res://systems/level/entities/enemy_spawner.scn")
const INTERACTABLE: PackedScene = preload("res://systems/level/entities/interactable/interactable.scn")
const BLOCK_PILE: PackedScene = preload("res://systems/level/entities/interactable/block_pile/block_pile.scn")
const LEVEL_1 = preload("res://resources/levels/level_1.png")

const TERRAIN_TILE_DATABASE: TerrainTileDatabase = preload("res://resources/terrain_tiles/terrain_tile_database.res")
const BLOCK_DATABASE: BlockDatabase = preload("res://resources/blocks/block_database.res")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var terrain_grid_map: GridMap = $TerrainGridMap

@export var level_dim: int = 64
var data: LevelData

@export var entities_r_value_database: Array[int] = [
	32, # Wood
	128, # Castle
	255, # Spawner
]

@export var terrain_g_value_database: Array[int] = [
	32, # Dirt
	0,  # Stone Wall
	255, # Pillar
	64, # Stairs
	48, # Bricks
]

var active_level_image: Image
var terrain_tiles: PackedInt32Array = PackedInt32Array()
var flow_field: PackedVector2Array = PackedVector2Array()
var target_local_coord: Vector2i

var spawners: Array[EnemySpawner] = []
var spawn_towers: Array[TowerBase] = []

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
#func _ready() -> void:
	#load_layout_from_image(LEVEL_1.get_image())
	#update_flow_field()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func update_flow_field() -> void:
	flow_field.clear()
	for z in level_dim: for x in level_dim: flow_field.append(Vector2.ZERO)
	
	var dijkstra_grid: Array[int] = _generate_dijkstra_grid()
	for z in level_dim: for x in level_dim:
		var i: int = z * level_dim + x
		if dijkstra_grid[i] == Util.UINT32_MAX: continue
		
		var neighbor_indices: Array[int] = _get_all_neighbor_indices(i)
		
		var min_index: int = -1
		var min_distance: int = 0
		
		for neighbor_index in neighbor_indices:
			var distance: int = dijkstra_grid[neighbor_index] - dijkstra_grid[i]
			if distance < min_distance:
				min_index = neighbor_index
				min_distance = distance
		
		if min_index != -1:
			var min_neighbor_local_coord: Vector2i = Vector2i(min_index % level_dim, min_index / level_dim)
			flow_field[i] = Vector2(min_neighbor_local_coord - Vector2i(x, z)).normalized()

func _generate_dijkstra_grid() -> Array[int]:
	var dijkstra_grid: Array[int] = []
	for z in level_dim: for x in level_dim:
		var i: int = z * level_dim + x
		if TERRAIN_TILE_DATABASE.database[terrain_tiles[i]].ground_obstacle:
			dijkstra_grid.append(Util.INT32_MAX)
		else:
			dijkstra_grid.append(-1)
	
	var path_end_index: int = target_local_coord.y * level_dim + target_local_coord.x
	dijkstra_grid[path_end_index] = 0
	var indices_to_visit: Array[int] = [path_end_index]
	
	while !indices_to_visit.is_empty():
		var i: int = indices_to_visit.pop_front()
		var neighbors: Array[int] = _get_direct_neighbor_indices(i)
		for neighbor_index in neighbors:
			if dijkstra_grid[neighbor_index] == -1:
				dijkstra_grid[neighbor_index] = dijkstra_grid[i] + 1
				indices_to_visit.append(neighbor_index)
	
	return dijkstra_grid

func _is_index_valid(i: int) -> bool:
	return i > -1 && i < level_dim * level_dim

func _get_direct_neighbor_indices(i: int) -> Array[int]:
	var possible_neighbors: Array[int] = [
		i - 1, # Left
		i + 1, # Right
		i - level_dim, # Back
		i + level_dim, # Front
	]
	
	var valid_neighbors: Array[int] = []
	for possible_neighbor in possible_neighbors:
		if _is_index_valid(possible_neighbor): valid_neighbors.append(possible_neighbor)
	
	return valid_neighbors

func _get_all_neighbor_indices(i: int) -> Array[int]:
	var possible_neighbors: Array[int] = [
		i - 1, # Left
		i + 1, # Right
		i - level_dim, # Back
		i + level_dim, # Front
		i - 1 - level_dim, # Left Back
		i + 1 - level_dim, # Right Back
		i - 1 + level_dim, # Left Front
		i + 1 + level_dim, # Right Front
	]
	
	var valid_neighbors: Array[int] = []
	for possible_neighbor in possible_neighbors:
		if _is_index_valid(possible_neighbor): valid_neighbors.append(possible_neighbor)
	
	return valid_neighbors

#func update_navigation() -> void:
	#for z in level_dim: for x in level_dim:
		#var global_coord: Vector3i = Vector3i(x - level_dim * 0.5, 0, z - level_dim * 0.5)
		#if terrain_grid_map.get_cell_item(global_coord) != 1:
			#navigation_grid_map.set_cell_item(global_coord, 0)
		#else:
			#navigation_grid_map.set_cell_item(global_coord, 4096)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func load_from_data(level_data: LevelData) -> void:
	data = level_data
	load_layout_from_image(level_data.layout_image.get_image())
	update_flow_field()

func load_layout_from_image(image: Image) -> void:
	terrain_grid_map.clear()
	terrain_tiles.clear()
	
	active_level_image = image.duplicate()
	
	for z in level_dim: for x in level_dim:
		var tile_color: Color = image.get_pixel(x, z)
		var terrain_tile_id: int = get_terrain_tile_id_from_color(tile_color)
		var cell_height: int = tile_color.b8
		var global_coord: Vector3i = Vector3i(x - level_dim * 0.5, 0.0, z - level_dim * 0.5)
		
		terrain_tiles.append(terrain_tile_id)
		terrain_grid_map.set_cell_item(global_coord, TERRAIN_TILE_DATABASE.database[terrain_tile_id].tile_mesh_id)
		
		spawn_entity_from_color(tile_color, Vector2i(x, z))
	
	for spawner in spawners: spawner.max = 100 / spawners.size()
	for tower in spawn_towers: tower.position_to_protect = Vector3(target_local_coord.x - level_dim * 0.5, 0.0, target_local_coord.y - level_dim * 0.5)

func get_terrain_tile_id_from_color(color: Color) -> int:
	for i in TERRAIN_TILE_DATABASE.database.size():
		if color.g8 == TERRAIN_TILE_DATABASE.database[i].g_value: return i
	return 0

func spawn_entity_from_color(color: Color, local_coord: Vector2i) -> void:
	var block_pile_spawn: int = -1
	var global_coord: Vector3 = Vector3(local_coord.x - level_dim * 0.5, 0.0, local_coord.y - level_dim * 0.5)
	match color.r8:
		32: block_pile_spawn = 0
		64: block_pile_spawn = 1
		96: block_pile_spawn = 2
		128: target_local_coord = local_coord
		160:
			var tower: Tower = preload("res://systems/level/entities/interactable/towers/tower.scn").instantiate()
			tower.position = global_coord + Vector3(0.5, -5.0, 0.5)
			tower.protect_position = true
			spawn_towers.append(tower)
			add_child(tower)
		255:
			var spawner: EnemySpawner = ENEMY_SPAWNER.instantiate()
			spawner.position = global_coord
			spawner.position.y = 1.0
			spawners.append(spawner)
			add_child(spawner)
	
	if block_pile_spawn != -1:
		var block_pile: Interactable = BLOCK_PILE.instantiate()
		block_pile.position = global_coord + Vector3(0.5, 0.0, 0.5)
		add_child(block_pile)
		block_pile.add_block(BLOCK_DATABASE.database[block_pile_spawn])

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func get_terrain_id_at_global_coord(global_coord: Vector3) -> int:
	var local_coord: Vector2i = Vector2i(floorf(global_coord.x) + level_dim * 0.5, floorf(global_coord.z) + level_dim * 0.5)
	var i: int = local_coord.y * level_dim + local_coord.x
	return terrain_tiles[i]
