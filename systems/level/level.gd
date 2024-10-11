class_name Level extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal wave_progress_changed(progress: float)
signal active_wave_icons_changed(icons: Array[Texture2D])
signal incoming_wave_icons_changed(icons: Array[Texture2D])
signal next_wave_icons_changed(icons: Array[Texture2D])

signal level_beaten(level_id: int)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const UNIT_SPAWNER: PackedScene = preload("res://systems/level/entities/unit_spawner.scn")
const INTERACTABLE: PackedScene = preload("res://systems/level/entities/interactable/interactable.scn")
const BLOCK_PILE: PackedScene = preload("res://systems/level/entities/interactable/block_pile/block_pile.scn")
const BREAD_PILE: PackedScene = preload("res://systems/level/entities/interactable/bread_pile/bread_pile.scn")
const BUILDING_ASSEMBLER: PackedScene = preload("res://systems/level/entities/building/building_assembler.scn")
const SPECIAL_NPC_BASE: PackedScene = preload("res://systems/level/entities/interactable/special_npc/special_npc_base.scn")
const HARVESTABLE_BASE: PackedScene = preload("res://systems/level/entities/interactable/harvestable/harvestable_base.scn")
const SHOP_BASE: PackedScene = preload("res://systems/level/entities/interactable/shop/shop_base.scn")

const DECORATION_TILE_DATABASE: DecorationTileDatabase = preload("res://resources/decoration_tiles/decoration_tile_database.res")
const BLOCK_DATABASE: BlockDatabase = preload("res://resources/blocks/block_database.res")
const FACTION_DATABASE: FactionDatabase = preload("res://resources/factions/faction_database.res")
const SPECIAL_NPC_DATABASE: SpecialNPCDatabase = preload("res://resources/special_npcs/special_npc_database.res")
var SHOP_DATABASE: ShopDatabase = load("res://resources/shops/shop_database.res")
var TERRAIN_TILE_DATABASE: TerrainTileDatabase = load("res://resources/terrain_tiles/terrain_tile_database.res")
var HARVESTABLE_DATABASE: HarvestableDatabase = load("res://resources/harvestable/harvestable_database.res")
var LEVEL_DATABASE: LevelDatabase = load("res://resources/levels/level_database.res")


# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var terrain_grid_map: GridMap = $TerrainGridMap

@export var level_dim: int = 64
var data: LevelData
var data_id: int

var active_level_image: Image
var terrain_tiles: PackedInt32Array = PackedInt32Array()

var factions_in_level: Array[int] = []
var faction_flow_fields: Array[PackedVector2Array] = []
var faction_base_local_coords: Array[Vector2i] = []
var faction_spawners: Array[UnitSpawner] = []
var faction_bread_piles: Array[BreadPile] = []

var building_tiles: Array[Vector3i] = []

var player_spawn_local_coord: Vector2i = Vector2i.ZERO
var orcus_spawn_local_coord: Vector2i = Vector2i.ZERO

var active_wave: LevelWaveData
var waves: Array[LevelWaveData] = []
var wave_timer: float

var loading: bool
var started: bool
var boss_prep_started: bool
var completed: bool
var no_waves: bool

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	unload()

func _physics_process(delta: float) -> void:
	if loading || no_waves: return
	
	if active_wave:
		if !boss_prep_started && waves.size() == 1 && active_wave.time_to_next_wave - wave_timer < 5.5:
			boss_prep_started = true
			if data.boss_music:
				SoundManager.fade_background_track(SoundManager.BackgroundTrackLayer.MUSIC_1, 5.0, 31.0, -50.0, true)
				SoundManager.play_background_track(data.boss_music.id, data.boss_music.type, SoundManager.BackgroundTrackLayer.MUSIC_0, true, -50.0)
				SoundManager.fade_background_track(SoundManager.BackgroundTrackLayer.MUSIC_0, 5.0, 31.0, data.boss_music.volume_db)
		elif !boss_prep_started && waves.is_empty():
			if data.boss_music:
				SoundManager.fade_background_track(SoundManager.BackgroundTrackLayer.MUSIC_1, 5.0, 31.0, -50.0, true)
				SoundManager.play_background_track(data.boss_music.id, data.boss_music.type, SoundManager.BackgroundTrackLayer.MUSIC_0, true, -50.0)
				SoundManager.fade_background_track(SoundManager.BackgroundTrackLayer.MUSIC_0, 5.0, 31.0, data.boss_music.volume_db)
	
		wave_timer += delta
		if !waves.is_empty():
			wave_progress_changed.emit(wave_timer / active_wave.time_to_next_wave)
		else:
			wave_progress_changed.emit(0.0)
		if wave_timer >= active_wave.time_to_next_wave:
			wave_timer -= active_wave.time_to_next_wave
			_start_new_wave()
		
	elif !waves.is_empty():
		_start_new_wave()
	else:
		if $Enemies.get_children().is_empty():
			if !completed && started: _level_complete()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _level_complete() -> void:
	completed = true
	SoundManager.fade_background_track(SoundManager.BackgroundTrackLayer.MUSIC_0, 1.0, 31.0, -50.0, true)
	if data.victory_music:
		SoundManager.play_background_track(data.victory_music.id, data.victory_music.type, SoundManager.BackgroundTrackLayer.MUSIC_1, true, -50.0)
		SoundManager.fade_background_track(SoundManager.BackgroundTrackLayer.MUSIC_1, 1.0, 31.0, data.victory_music.volume_db, false)
	level_beaten.emit(data_id)
	
	var special_npc_orcus: SpecialNPCBase = SPECIAL_NPC_BASE.instantiate()
	special_npc_orcus.position = centered_global_coord_from_local_coord(orcus_spawn_local_coord)
	special_npc_orcus.data = SPECIAL_NPC_DATABASE.database[0]
	special_npc_orcus.dialogue_data = data.victory_dialogue
	if data.next_level_id > -1 && data.next_level_id < LEVEL_DATABASE.database.size():
		special_npc_orcus.level_id_to_send_player_to_override = data.next_level_id
	add_tile_entity(special_npc_orcus)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _start_new_wave() -> void:
	var active_wave_icons: Array[Texture2D] = []
	var incoming_wave_icons: Array[Texture2D] = []
	var next_wave_icons: Array[Texture2D] = []
	
	active_wave = waves.pop_front()
	if !active_wave:
		active_wave_icons_changed.emit(active_wave_icons)
		return
	
	print("Starting new wave")
	for batch in active_wave.batches:
		if !is_instance_valid(faction_spawners[batch.faction_id]): continue
		active_wave_icons.append(FACTION_DATABASE.database[batch.faction_id].units[batch.unit_id].icon)
		faction_spawners[batch.faction_id].spawn_batch(batch)
	
	if !waves.is_empty():
		for batch in waves[0].batches:
			if !is_instance_valid(faction_spawners[batch.faction_id]): continue
			incoming_wave_icons.append(FACTION_DATABASE.database[batch.faction_id].units[batch.unit_id].icon)
		
		if waves.size() > 1:
			for batch in waves[1].batches:
				if !is_instance_valid(faction_spawners[batch.faction_id]): continue
				next_wave_icons.append(FACTION_DATABASE.database[batch.faction_id].units[batch.unit_id].icon)
	
	active_wave_icons_changed.emit(active_wave_icons)
	incoming_wave_icons_changed.emit(incoming_wave_icons)
	next_wave_icons_changed.emit(next_wave_icons)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func add_ai(faction_id: int, ai: Node) -> void:
	if faction_id == 0:
		$Allies.add_child(ai)
	else:
		$Enemies.add_child(ai)

func add_tile_entity(tile_entity: Interactable) -> void:
	$TileEntities.add_child(tile_entity)

func add_pickup(pickup: Pickup) -> void:
	$Pickups.add_child(pickup)

func add_building(building: Node3D) -> void:
	$Buildings.add_child(building)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func update_flow_field(target_team: int) -> void:
	var flow_field: PackedVector2Array = faction_flow_fields[target_team]
	flow_field.clear()
	for z in level_dim: for x in level_dim: flow_field.append(Vector2.ZERO)
	
	var dijkstra_grid: Array[int] = _generate_dijkstra_grid(target_team)
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

func _generate_dijkstra_grid(target_team: int) -> Array[int]:
	var dijkstra_grid: Array[int] = []
	for z in level_dim: for x in level_dim:
		var i: int = z * level_dim + x
		if TERRAIN_TILE_DATABASE.database[terrain_tiles[i]].ground_obstacle:
			dijkstra_grid.append(Util.INT32_MAX)
		else:
			dijkstra_grid.append(-1)
	
	for tile_entity in $TileEntities.get_children():
		if tile_entity is TowerBase:
			var local_coord: Vector2i = Vector2i(floorf(tile_entity.position.x) + level_dim * 0.5, floorf(tile_entity.position.z) + level_dim * 0.5)
			dijkstra_grid[local_coord.y * level_dim + local_coord.x] = Util.INT32_MAX
	
	var target_base_local_coord: Vector2i = faction_base_local_coords[target_team]
	var path_end_index: int = target_base_local_coord.y * level_dim + target_base_local_coord.x
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

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func unload() -> void:
	SoundManager.erase_background_track(SoundManager.BackgroundTrackLayer.MUSIC_0)
	SoundManager.erase_background_track(SoundManager.BackgroundTrackLayer.MUSIC_1)
	SoundManager.erase_background_track(SoundManager.BackgroundTrackLayer.WIND_0)
	
	active_level_image = null
	terrain_grid_map.clear()
	terrain_tiles.clear()
	terrain_tiles.resize(level_dim * level_dim)
	building_tiles.clear()
	
	wave_progress_changed.emit(0.0)
	var empty_icons: Array[Texture2D] = []
	active_wave_icons_changed.emit(empty_icons)
	incoming_wave_icons_changed.emit(empty_icons)
	next_wave_icons_changed.emit(empty_icons)
	
	faction_flow_fields.clear()
	faction_base_local_coords.clear()
	factions_in_level.clear()
	for i in FACTION_DATABASE.database.size():
		faction_flow_fields.append(PackedVector2Array())
		faction_base_local_coords.append(Vector2i.ZERO)
	
	for character in $Allies.get_children(): character.queue_free()
	for character in $Enemies.get_children(): character.queue_free()
	for tile_entity in $TileEntities.get_children(): tile_entity.queue_free()
	for pickup in $Pickups.get_children(): pickup.queue_free()
	for building in $Buildings.get_children(): building.queue_free()
	
	for spawner in faction_spawners: if is_instance_valid(spawner): spawner.queue_free()
	faction_spawners.clear()
	faction_spawners.resize(FACTION_DATABASE.database.size())
	for bread_pile in faction_bread_piles: if is_instance_valid(bread_pile): bread_pile.queue_free()
	faction_bread_piles.clear()
	faction_bread_piles.resize(FACTION_DATABASE.database.size())
	
	active_wave = null
	waves.clear()
	wave_timer = 0.0
	
	started = false
	boss_prep_started = false
	completed = false
	no_waves = false

func load_from_level_id(level_id: int) -> void:
	_load_from_data(LEVEL_DATABASE.database[level_id])
	data_id = level_id

func _load_from_data(level_data: LevelData) -> void:
	loading = true
	
	unload()
	
	await get_tree().create_timer(0.2).timeout
	
	data = level_data
	waves = data.waves.duplicate()
	if waves.is_empty(): no_waves = true
	
	await load_layout_from_image(data.layout_texture.get_image())
	
	for faction_id in factions_in_level:
		update_flow_field(faction_id)
	
	Util.main.game_started.emit()
	SoundManager.play_background_track(0, SoundDatabase.SoundType.BGT_WIND, SoundManager.BackgroundTrackLayer.WIND_0, true, -10.0)
	if data.music: SoundManager.play_background_track(level_data.music.id, level_data.music.type, SoundManager.BackgroundTrackLayer.MUSIC_1, true, level_data.music.volume_db)
	
	
	started = true
	loading = false

func load_layout_from_image(image: Image) -> void:
	active_level_image = image.duplicate()
	
	for z in level_dim:
		for x in level_dim:
			var tile_color: Color = image.get_pixel(x, z)
			var terrain_tile_id: int = get_terrain_tile_id_from_color(tile_color)
			
			set_terrain_tile_at_local_coord(terrain_tile_id, Vector2i(x, z))
			spawn_entity_from_color(tile_color, Vector2i(x, z))
			spawn_building_from_color(tile_color, Vector2i(x, z))
		
		#await get_tree().create_timer(0.00001).timeout
	
	Util.main.spawn_point = Vector3(player_spawn_local_coord.x - level_dim * 0.5, 0.0, player_spawn_local_coord.y - level_dim * 0.5)
	
	for tile_entity in $TileEntities.get_children():
		if tile_entity is TowerBase:
			tile_entity.position_to_protect = centered_global_coord_from_local_coord(faction_base_local_coords[tile_entity.faction_id])
			tile_entity.protect_position = true
	
	for faction_game_data in data.faction_game_datas:
		if faction_game_data.starting_bread_count > 0:
			var bread_pile: BreadPile = BREAD_PILE.instantiate()
			bread_pile.position = centered_global_coord_from_local_coord(faction_base_local_coords[faction_game_data.faction_id])
			bread_pile.faction_defeated.connect(_on_faction_defeated)
			bread_pile.faction_id = faction_game_data.faction_id
			bread_pile.bread_count = faction_game_data.starting_bread_count
			faction_bread_piles[faction_game_data.faction_id] = bread_pile
			add_child(bread_pile)
	
	for building in $Buildings.get_children():
		if !(building is BuildingAssembler): continue
		building.update_dims()
		building.assemble()

func spawn_entity_from_color(color: Color, local_coord: Vector2i) -> void:
	var block_pile_spawn: int = -1
	var faction_base_id: int = -1
	
	var global_coord: Vector3 = centered_global_coord_from_local_coord(local_coord)
	global_coord.y = get_placement_height_at_global_coord(global_coord)
	match color.r8:
		30: block_pile_spawn = 0
		40: block_pile_spawn = 1
		50: block_pile_spawn = 2
		120: faction_base_id = 0
		130: faction_base_id = 1
		140: faction_base_id = 2
		150: faction_base_id = 3
		160: faction_base_id = 4
		200: player_spawn_local_coord = local_coord
		210: orcus_spawn_local_coord = local_coord
		#250:
			#var tower: Tower = preload("res://systems/level/entities/interactable/towers/tower.scn").instantiate()
			#tower.position = global_coord + Vector3(0.5, -5.0, 0.5)
			#tower.protect_position = true
			#add_tile_entity(tower)
	
	if color.r8 > 169 && color.r8 < 180:
		var shop_base: ShopBase = SHOP_BASE.instantiate()
		shop_base.data = SHOP_DATABASE.database[color.r8 - 170]
		shop_base.position = global_coord
		if color.b8 > 252:
			print(90.0 * (color.b8 - 252))
			shop_base.rotate_y(deg_to_rad(90.0 * (color.b8 - 252)))
		add_tile_entity(shop_base)
	
	if block_pile_spawn != -1:
		var block_pile: Interactable = BLOCK_PILE.instantiate()
		block_pile.position = global_coord
		add_tile_entity(block_pile)
		block_pile.add_block(BLOCK_DATABASE.database[block_pile_spawn])
	elif faction_base_id != -1:
		faction_base_local_coords[faction_base_id] = local_coord
		if !factions_in_level.has(faction_base_id): factions_in_level.append(faction_base_id)
		
		var spawner: UnitSpawner = UNIT_SPAWNER.instantiate()
		spawner.position = global_coord
		spawner.position.y = 0.5
		faction_spawners[faction_base_id] = spawner
		add_child(spawner)
	
	if color.b8 < 128 || color.b8 > 252: return
	var harvestable_id: int = color.b8 - 128
	var harvestable: HarvestableBase = HARVESTABLE_BASE.instantiate()
	harvestable.data = HARVESTABLE_DATABASE.database[harvestable_id]
	harvestable.position = global_coord
	add_tile_entity(harvestable)

func spawn_building_from_color(color: Color, local_coord: Vector2i) -> void:
	var building_id: int = color.b8
	if building_id == 0 || building_id > 127: return
	
	var assembler: BuildingAssembler = null
	for building in $Buildings.get_children():
		if !(building is BuildingAssembler): continue
		if building.id == building_id:
			assembler = building
			break
	
	if !is_instance_valid(assembler):
		assembler = BUILDING_ASSEMBLER.instantiate()
		assembler.id = building_id
		
		if building_id > 32:
			assembler.building_tile_set = BuildingAssembler.TileSetType.TEMPLE # NORMAL HOUSE
		elif building_id > 64:
			assembler.building_tile_set = BuildingAssembler.TileSetType.TEMPLE # RAMPARTS
		
		add_building(assembler)
	
	if color.r8 == 1:
		assembler.global_position = global_coord_from_local_coord(local_coord)
	elif color.r8 == 2:
		assembler.end_position = global_coord_from_local_coord(local_coord)
	elif color.r8 > 2 && color.r8 < 7:
		assembler.building_orientation = color.r8 - 3

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func set_terrain_tile_at_local_coord(tile_id: int, local_coord: Vector2i, orientation: int = 0) -> void:
	var i: int = index_from_local_coord(local_coord)
	if i < 0 || i > level_dim * level_dim - 1: return
	terrain_tiles[i] = tile_id
	terrain_grid_map.set_cell_item(global_coord_from_local_coord(local_coord), TERRAIN_TILE_DATABASE.database[tile_id].tile_mesh_id, tile_orientation_to_godot_orientation(orientation))

func set_terrain_tile_at_global_coord(tile_id: int, global_coord: Vector3, orientation: int = 0) -> void:
	set_terrain_tile_at_local_coord(tile_id, local_coord_from_global_coord(global_coord), orientation)

func set_decoration_tile_at_local_coord(tile_id: int, local_coord: Vector2i, height: int, orientation: int = 0) -> void:
	terrain_grid_map.set_cell_item(global_coord_from_local_coord(local_coord) + Vector3.UP * height, DECORATION_TILE_DATABASE.database[tile_id].tile_mesh_id, tile_orientation_to_godot_orientation(orientation))

func set_decoration_tile_at_global_coord(tile_id: int, global_coord: Vector3, height: int, orientation: int = 0) -> void:
	set_decoration_tile_at_local_coord(tile_id, local_coord_from_global_coord(global_coord), height, orientation)

func get_terrain_tile_at_global_coord(global_coord: Vector3) -> TerrainTileData:
	return TERRAIN_TILE_DATABASE.database[get_terrain_id_at_local_coord(local_coord_from_global_coord(global_coord))]

func get_terrain_id_at_global_coord(global_coord: Vector3) -> int:
	return get_terrain_id_at_local_coord(local_coord_from_global_coord(global_coord))

func get_terrain_id_at_local_coord(local_coord: Vector2i) -> int:
	var i: int = local_coord.y * level_dim + local_coord.x
	return terrain_tiles[i]

func get_terrain_tile_id_from_color(color: Color) -> int:
	for i in TERRAIN_TILE_DATABASE.database.size():
		if color.g8 == TERRAIN_TILE_DATABASE.database[i].g_value: return i
	return 0

func index_from_local_coord(local_coord: Vector2i) -> int:
	return local_coord.y * level_dim + local_coord.x

func index_from_global_coord(global_coord: Vector3) -> int:
	return index_from_local_coord(local_coord_from_global_coord(global_coord))

func local_coord_from_global_coord(global_coord: Vector3) -> Vector2i:
	return Vector2i(floorf(global_coord.x) + level_dim * 0.5, floorf(global_coord.z) + level_dim * 0.5)

func global_coord_from_local_coord(local_coord: Vector2i) -> Vector3:
	return Vector3(local_coord.x - level_dim * 0.5, 0.0, local_coord.y - level_dim * 0.5)

func centered_global_coord_from_local_coord(local_coord: Vector2i) -> Vector3:
	return Vector3(local_coord.x - level_dim * 0.5 + 0.5, 0.0, local_coord.y - level_dim * 0.5 + 0.5)

func tile_orientation_to_godot_orientation(tile_orientation: int) -> int:
	match tile_orientation:
		1: return 10
		2: return 16
		3: return 22
		_: return 0

func is_global_coord_in_bounds(global_coord: Vector3) -> bool:
	var local_coord: Vector2i = local_coord_from_global_coord(global_coord)
	if local_coord.x < 0 || local_coord.y < 0 || local_coord.x > level_dim - 1 || local_coord.y > level_dim - 1: return false
	return true

func get_placement_height_at_global_coord(global_coord: Vector3) -> float:
	return get_terrain_tile_at_global_coord(global_coord).height * 0.5

func get_interactable_from_global_coord(global_coord: Vector3) -> Interactable:
	var entities_in_selection: Array[PhysicsBody3D] = AreaQueryManager.query_area(global_coord + Vector3(0.5, 0.0, 0.5), 0.1, 512)
	if !entities_in_selection.is_empty(): return entities_in_selection[0].get_parent()
	return null

func place_interactable_at_global_coord(global_coord: Vector3, interactable: Interactable) -> void:
	var place_at: Vector3 = centered_global_coord_from_local_coord(local_coord_from_global_coord(global_coord))
	place_at.y = get_placement_height_at_global_coord(place_at)
	if Util.main.level.get_terrain_id_at_global_coord(place_at) == 5:
		Util.main.level.set_terrain_tile_at_global_coord(6, place_at)
	interactable.global_position = place_at
	
	if interactable is TowerBase:
		interactable.start_position = interactable.global_position
		interactable.current_animation_position = interactable.global_position
	
	if interactable.interactable_data.place_sounds:
		var sound: SoundReferenceData = interactable.interactable_data.place_sounds.pool.pick_random()
		SoundManager.play_pitched_3d_sfx(sound.id, sound.type, global_coord, 0.9, 1.1, sound.volume_db, 5.0)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_faction_defeated(bread_pile: BreadPile) -> void:
	if bread_pile.faction_id != 0:
		bread_pile.faction_defeated.disconnect(_on_faction_defeated)
		bread_pile.queue_free()
		faction_spawners[bread_pile.faction_id].queue_free()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func get_terrain_model_scene_from_id(level_id: int) -> Node3D:
	return get_terrain_model_scene(LEVEL_DATABASE.database[level_id])

## This is purely for visual purposes. The scene is non-functional.
func get_terrain_model_scene(level_data: LevelData) -> Node3D:
	var terrain_model_scene: Node3D = Node3D.new()
	var terrain_model_gridmap: GridMap = GridMap.new()
	terrain_model_gridmap.mesh_library = terrain_grid_map.mesh_library
	terrain_model_gridmap.cell_size = terrain_grid_map.cell_size
	terrain_model_gridmap.cell_center_y = false
	terrain_model_gridmap.collision_layer = 0
	terrain_model_gridmap.collision_mask = 0
	terrain_model_gridmap.scale = Vector3.ONE * 0.1
	terrain_model_scene.add_child(terrain_model_gridmap)
	
	var layout_image: Image = level_data.layout_texture.get_image()
	for z in level_dim: for x in level_dim:
		var tile_color: Color = layout_image.get_pixel(x, z)
		var terrain_tile_id: int = get_terrain_tile_id_from_color(tile_color)
		var global_coord: Vector3i = Vector3i(x - level_dim * 0.5, 0.0, z - level_dim * 0.5)
		terrain_model_gridmap.set_cell_item(global_coord, TERRAIN_TILE_DATABASE.database[terrain_tile_id].tile_mesh_id)
	
	return terrain_model_scene
