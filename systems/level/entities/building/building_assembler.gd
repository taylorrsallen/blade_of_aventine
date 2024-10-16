class_name BuildingAssembler extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const TERRAIN_TILE_DATABASE: TerrainTileDatabase = preload("res://resources/terrain_tiles/terrain_tile_database.res")
const DECORATION_TILE_DATABASE: DecorationTileDatabase = preload("res://resources/decoration_tiles/decoration_tile_database.res")

const TILE_SETS: Array[BuildingTileSetData] = [
	preload("res://resources/decoration_tiles/temple_tile_set.res"),
	preload("res://resources/decoration_tiles/insulae_tile_set.res"),
]

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
enum TileSetType {
	TEMPLE,
	INSULAE,
}

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var end_position: Vector3
@export var building_dims: Vector2i = Vector2i(7, 13)
@export var building_orientation: int
@export var building_tile_set: TileSetType = TileSetType.TEMPLE
@export var id: int

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
#func _physics_process(delta: float) -> void:
	#DebugDraw3D.draw_aabb(AABB(global_position, Vector3(building_dims.x, 1.0, building_dims.y)), Color.FLORAL_WHITE, delta)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func update_dims() -> void:
	var vec3_dims: Vector3 = (end_position - global_position).floor()
	building_dims = Vector2i(vec3_dims.x, vec3_dims.z) + Vector2i.ONE

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func assemble() -> void:
	for z in building_dims.y: for x in building_dims.x:
		var global_coord: Vector3 = global_position.floor() + Vector3(x, 0.0, z)
		var tile_set: BuildingTileSetData = TILE_SETS[building_tile_set]
		
		var corner_terrain_id: int = tile_set.corner_terrain_tile
		var decoration_wall_height: int = TERRAIN_TILE_DATABASE.database[corner_terrain_id].height
		var decoration_roof_height: int = decoration_wall_height + DECORATION_TILE_DATABASE.database[tile_set.roof_border_wall_00].height
		
		if z == 0:
			if x == 0:
				## FRONT LEFT CORNER
				Util.main.level.set_terrain_tile_at_global_coord(corner_terrain_id, global_coord, 0)
				_place_wall_corner(tile_set, global_coord, decoration_wall_height, 1)
				_place_roof_corner(tile_set, global_coord, decoration_roof_height, 1)
			elif x == building_dims.x - 1:
				## FRONT RIGHT CORNER
				Util.main.level.set_terrain_tile_at_global_coord(corner_terrain_id, global_coord, 0)
				_place_wall_corner(tile_set, global_coord, decoration_wall_height, 2)
				_place_roof_corner(tile_set, global_coord, decoration_roof_height, 2)
			else:
				## FRONT WALLS
				_place_wall(tile_set, x, global_coord, decoration_wall_height, 1)
				_place_wall_roof(tile_set, 0, Vector2i(x, z), global_coord, decoration_roof_height, 2)
		elif z == building_dims.y - 1:
			if x == 0:
				## BACK LEFT CORNER
				Util.main.level.set_terrain_tile_at_global_coord(corner_terrain_id, global_coord, 0)
				_place_wall_corner(tile_set, global_coord, decoration_wall_height, 3)
				_place_roof_corner(tile_set, global_coord, decoration_roof_height, 3)
			elif x == building_dims.x - 1:
				## BACK RIGHT CORNER
				Util.main.level.set_terrain_tile_at_global_coord(corner_terrain_id, global_coord, 0)
				_place_wall_corner(tile_set, global_coord, decoration_wall_height, 0)
				_place_roof_corner(tile_set, global_coord, decoration_roof_height, 0)

			else:
				## BACK WALLS
				_place_wall(tile_set, x, global_coord, decoration_wall_height, 0)
				_place_wall_roof(tile_set, 0, Vector2i(x, z), global_coord, decoration_roof_height, 3)
		elif x == 0 && z != 0 && z != building_dims.y - 1:
			## LEFT WALLS
			_place_wall(tile_set, z, global_coord, decoration_wall_height, 3)
			_place_wall_roof(tile_set, 1, Vector2i(x, z), global_coord, decoration_roof_height, 1)
		elif x == building_dims.x - 1 && z != 0 && z != building_dims.y - 1:
			## RIGHT WALLS
			_place_wall(tile_set, z, global_coord, decoration_wall_height, 2)
			_place_wall_roof(tile_set, 1, Vector2i(x, z), global_coord, decoration_roof_height, 0)
		else:
			## INTERIOR
			_place_interior_roof(tile_set, Vector2i(x, z), global_coord, decoration_roof_height)
			_place_interior_ceiling(tile_set, Vector2i(x, z), global_coord, decoration_wall_height)

func _place_interior_roof(tile_set: BuildingTileSetData, local_coord: Vector2i, global_coord: Vector3, height: int) -> void:
	var height_and_orientation: Vector2i = _get_roof_height_and_orientation(local_coord)
	
	if (building_orientation == 0 || building_orientation == 1) && local_coord.x == (building_dims.x - 1) * 0.5 || (building_orientation == 2 || building_orientation == 3) && local_coord.y == (building_dims.y - 1) * 0.5:
		Util.main.level.set_decoration_tile_at_global_coord(tile_set.roof_center, global_coord, height + height_and_orientation.x, height_and_orientation.y)
	else:
		Util.main.level.set_decoration_tile_at_global_coord(tile_set.roof, global_coord, height + height_and_orientation.x, height_and_orientation.y)

func _place_interior_ceiling(tile_set: BuildingTileSetData, local_coord: Vector2i, global_coord: Vector3, wall_height: int) -> void:
	var ceiling_variation_value: int = local_coord.x
	
	if local_coord.x == 1:
		## LEFT WALL
		if local_coord.y == 1:
			Util.main.level.set_decoration_tile_at_global_coord(tile_set.ceiling_corner, global_coord, wall_height, 1)
		elif local_coord.y == building_dims.y - 2:
			Util.main.level.set_decoration_tile_at_global_coord(tile_set.ceiling_corner, global_coord, wall_height, 3)
		else:
			Util.main.level.set_decoration_tile_at_global_coord(tile_set.ceiling_border, global_coord, wall_height, 3)
	elif local_coord.y == 1:
		## FRONT WALL
		if local_coord.x == building_dims.x - 2:
			Util.main.level.set_decoration_tile_at_global_coord(tile_set.ceiling_corner, global_coord, wall_height, 2)
		else:
			if building_orientation == 1 || building_orientation == 2:
				if local_coord.x % 4 != 0:
					Util.main.level.set_decoration_tile_at_global_coord(tile_set.ceiling_border, global_coord, wall_height, 1)
			else:
				Util.main.level.set_decoration_tile_at_global_coord(tile_set.ceiling_border, global_coord, wall_height, 1)
	elif local_coord.x == building_dims.x - 2:
		## RIGHT WALL
		if local_coord.y == building_dims.y - 2:
			Util.main.level.set_decoration_tile_at_global_coord(tile_set.ceiling_corner, global_coord, wall_height, 0)
		else:
			Util.main.level.set_decoration_tile_at_global_coord(tile_set.ceiling_border, global_coord, wall_height, 2)
	elif local_coord.y == building_dims.y - 2:
		## BACK WALL
		if local_coord.x % 4 == 0:
			Util.main.level.set_decoration_tile_at_global_coord(tile_set.ceiling_low_border, global_coord, wall_height, 3)
		else:
			Util.main.level.set_decoration_tile_at_global_coord(tile_set.ceiling_border, global_coord, wall_height, 0)
	else:
		if ceiling_variation_value % 4 == 0:
			Util.main.level.set_decoration_tile_at_global_coord(tile_set.ceiling_low, global_coord, wall_height, 2)
		else:
			Util.main.level.set_decoration_tile_at_global_coord(tile_set.ceiling, global_coord, wall_height)

func _place_wall_corner(tile_set: BuildingTileSetData, global_coord: Vector3, height: int, orientation: int) -> void:
	Util.main.level.set_decoration_tile_at_global_coord(tile_set.roof_border_corner, global_coord, height, orientation)

func _place_roof_corner(tile_set: BuildingTileSetData, global_coord: Vector3, height: int, orientation: int) -> void:
	const ROOF_XY_OFFSETS: Array[Vector2] = [Vector2(1.0, 1.0), Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0)]
	var xy_offset: Vector2 = ROOF_XY_OFFSETS[orientation]
	
	var roof_orientation: int
	var inversion: bool = false
	match orientation:
		1:
			roof_orientation = 1 if (building_orientation == 0 || building_orientation == 1) else 3
			if (building_orientation == 2 || building_orientation == 3): inversion = true
		2:
			roof_orientation = 1 if (building_orientation == 0 || building_orientation == 1) else 2
			if (building_orientation == 0 || building_orientation == 1): inversion = true
		3:
			roof_orientation = 0 if (building_orientation == 0 || building_orientation == 1) else 3
			if (building_orientation == 0 || building_orientation == 1): inversion = true
		_:
			roof_orientation = 0 if (building_orientation == 0 || building_orientation == 1) else 2
			if (building_orientation == 2 || building_orientation == 3): inversion = true
	
	var roof: int = tile_set.roof_inverse if inversion else tile_set.roof
	var roof_end: int = tile_set.roof_end_inverse if inversion else tile_set.roof_end
	var roof_border_end_00: int = tile_set.roof_border_end_00_inverse if inversion else tile_set.roof_border_end_00
	var roof_border_end_01: int = tile_set.roof_border_end_01_inverse if inversion else tile_set.roof_border_end_01
	
	var roof_end_offset: Vector3 = Vector3(xy_offset.x, 0.0, 0.0)
	var roof_border_end_00_offset: Vector3 = Vector3(xy_offset.x, 0.0, xy_offset.y)
	var roof_border_end_01_offset: Vector3 = Vector3(0.0, 0.0, xy_offset.y)
	if (building_orientation == 2 || building_orientation == 3) && inversion:
		roof_end_offset = Vector3(0.0, 0.0, xy_offset.y)
		roof_border_end_00_offset = Vector3(xy_offset.y, 0.0, xy_offset.x)
		roof_border_end_01_offset = Vector3(xy_offset.y, 0.0, 0.0)
	elif (building_orientation == 2 || building_orientation == 3):
		roof_end_offset = Vector3(0.0, 0.0, xy_offset.y)
		roof_border_end_01_offset = Vector3(xy_offset.x, 0.0, 0.0)
	
	Util.main.level.set_decoration_tile_at_global_coord(roof, global_coord, height + 1, roof_orientation)
	Util.main.level.set_decoration_tile_at_global_coord(roof_end, global_coord + roof_end_offset, height, roof_orientation)
	Util.main.level.set_decoration_tile_at_global_coord(roof_border_end_00, global_coord + roof_border_end_00_offset, height, roof_orientation)
	Util.main.level.set_decoration_tile_at_global_coord(roof_border_end_01, global_coord + roof_border_end_01_offset, height, roof_orientation)

func _place_wall(tile_set: BuildingTileSetData, parallel_axis_value: int, global_coord: Vector3, height: int, orientation: int) -> void:
	if parallel_axis_value % 2 == 1:
		Util.main.level.set_decoration_tile_at_global_coord(tile_set.roof_border_wall_00, global_coord, height, orientation)
	else:
		Util.main.level.set_decoration_tile_at_global_coord(tile_set.roof_border_wall_01, global_coord, height, orientation)

func _place_wall_roof(tile_set: BuildingTileSetData, parallel_axis_index: int, local_coord: Vector2i, global_coord: Vector3, height: int, orientation: int) -> void:
	var roof_offset: Vector3 = Vector3.ZERO
	if parallel_axis_index == 0:
		match orientation:
			3: roof_offset = Vector3(0.0, 0.0, 1.0)
			_: roof_offset = Vector3(0.0, 0.0, -1.0)
	else:
		match orientation:
			1: roof_offset = Vector3(-1.0, 0.0, 0.0)
			_: roof_offset = Vector3(1.0, 0.0, 0.0)
	
	if (building_orientation == 0 || building_orientation == 1) && (orientation == 0 || orientation == 1) || (building_orientation == 2 || building_orientation == 3) && (orientation == 2 || orientation == 3):
		Util.main.level.set_decoration_tile_at_global_coord(tile_set.roof_end, global_coord + roof_offset, height, orientation)
		Util.main.level.set_decoration_tile_at_global_coord(tile_set.roof, global_coord, height + 1, orientation)
	else:
		var center: bool = false
		if parallel_axis_index == 0 && local_coord.x == (building_dims.x - 1) * 0.5 || parallel_axis_index == 1 && local_coord.y == (building_dims.y - 1) * 0.5:
			center = true
		
		var inverse: bool
		var side_1: bool
		var roof_border_inner: int = tile_set.roof_border_inner
		var roof_height: int
		if parallel_axis_index == 0:
			roof_height = (building_dims.x - 3) * 0.5 + building_dims.x * 0.5
			if local_coord.y == 0:
				## LEFT WALL
				side_1 = true
				orientation = (orientation + 3) % 4
				if local_coord.x > float(building_dims.x - 2) * 0.5:
					roof_height -= local_coord.x
					inverse = true
					roof_border_inner = tile_set.roof_border_inner_inverse
				else:
					roof_height -= (building_dims.x - local_coord.x - 1)
			elif local_coord.y == building_dims.y - 1:
				## RIGHT WALL
				orientation = (orientation + 1) % 4
				if local_coord.x > float(building_dims.x - 2) * 0.5:
					roof_height -= local_coord.x
				else:
					inverse = true
					roof_border_inner = tile_set.roof_border_inner_inverse
					roof_height -= (building_dims.x - local_coord.x - 1)
		else:
			orientation = (orientation + 2) % 4
			roof_height = (building_dims.y - 3) * 0.5 + building_dims.y * 0.5
			if local_coord.x == 0:
				## LEFT WALL
				side_1 = true
				if local_coord.y > float(building_dims.y - 2) * 0.5:
					roof_height -= local_coord.y
				else:
					roof_height -= (building_dims.y - local_coord.y - 1)
					inverse = true
					roof_border_inner = tile_set.roof_border_inner_inverse
			elif local_coord.x == building_dims.x - 1:
				## RIGHT WALL
				if local_coord.y > float(building_dims.y - 2) * 0.5:
					roof_height -= local_coord.y
					inverse = true
					roof_border_inner = tile_set.roof_border_inner_inverse
				else:
					roof_height -= (building_dims.y - local_coord.y - 1)
		
		if center:
			Util.main.level.set_decoration_tile_at_global_coord(tile_set.roof_border_center, global_coord + roof_offset, height + roof_height, orientation)
			Util.main.level.set_decoration_tile_at_global_coord(tile_set.roof_center, global_coord, height + roof_height + 2, orientation)
		else:
			Util.main.level.set_decoration_tile_at_global_coord(roof_border_inner, global_coord + roof_offset, height + roof_height, orientation)
			if inverse:
				if side_1:
					Util.main.level.set_decoration_tile_at_global_coord(tile_set.roof, global_coord, height + roof_height + 2, (orientation + 3) % 4)
				else:
					Util.main.level.set_decoration_tile_at_global_coord(tile_set.roof, global_coord, height + roof_height + 2, (orientation + 1) % 4)
			else:
				Util.main.level.set_decoration_tile_at_global_coord(tile_set.roof, global_coord, height + roof_height + 2, orientation)
		
		for i in roof_height:
			Util.main.level.set_decoration_tile_at_global_coord(tile_set.roof_border_inner_wall, global_coord + roof_offset, height + i, orientation)

func _get_roof_height_and_orientation(local_coord: Vector2i) -> Vector2i:
	var height_and_orientation: Vector2i = Vector2i(0, 0)
	if (building_orientation == 0 || building_orientation == 1):
		height_and_orientation.x = building_dims.x
		if local_coord.x > float(building_dims.x - 2) * 0.5:
			height_and_orientation.x -= local_coord.x
			height_and_orientation.y = 0
		else:
			height_and_orientation.x -= (building_dims.x - local_coord.x - 1)
			height_and_orientation.y = 1
	else:
		height_and_orientation.x = building_dims.y
		if local_coord.y > float(building_dims.y - 2) * 0.5:
			height_and_orientation.x -= local_coord.y
			height_and_orientation.y = 3
		else:
			height_and_orientation.x -= (building_dims.y - local_coord.y - 1)
			height_and_orientation.y = 2
	
	return height_and_orientation
