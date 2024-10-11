class_name BlockPileRecipeData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const TOWER_BASE: PackedScene = preload("res://systems/level/entities/interactable/towers/tower_base.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var ingredients: Array[BlockData]
@export var tower_type_data: TowerTypeData

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func instantiate(global_coord: Vector3) -> Interactable:
	var tower_base: TowerBase = TOWER_BASE.instantiate()
	tower_base.position = global_coord
	tower_base.recipe = self
	tower_base.type_data = tower_type_data
	Util.main.level.add_tile_entity(tower_base)
	return tower_base
