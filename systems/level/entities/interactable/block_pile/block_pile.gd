class_name BlockPile extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const BLOCK_PILE: PackedScene = preload("res://systems/level/entities/interactable/block_pile/block_pile.scn")
const BLOCK_RECIPE_DATABASE: BlockPileRecipeDatabase = preload("res://resources/block_recipes/block_recipe_database.res")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var block_models: Node3D = $BlockModels
@export var blocks: Array[BlockData] = []

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	$StaticBody3D/CollisionShape3D.shape = $StaticBody3D/CollisionShape3D.shape.duplicate()
	_refresh()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func add_block(block: BlockData) -> void:
	blocks.append(block)
	_refresh()

func add_block_pile(other_block_pile: BlockPile) -> void:
	for block_data in other_block_pile.blocks:
		add_block(block_data)
	other_block_pile.queue_free()

func take_block() -> BlockPile:
	if blocks.size() > 1:
		var new_block_pile: BlockPile = BLOCK_PILE.instantiate()
		new_block_pile.add_block(blocks.pop_back())
		Util.main.level.add_child(new_block_pile)
		_refresh()
		return new_block_pile
	else:
		return self

func _refresh() -> void:
	var recipe_result: PackedScene = null
	for recipe in BLOCK_RECIPE_DATABASE.database:
		if recipe.ingredients.size() == blocks.size():
			var match_found: bool = true
			for i in recipe.ingredients.size():
				if recipe.ingredients[i] != blocks[i]:
					match_found = false
					continue
			
			if match_found:
				recipe_result = recipe.result
	
	if recipe_result:
		var result = recipe_result.instantiate()
		result.position = global_position - Vector3.UP * 5.0
		Util.main.level.add_child(result)
		queue_free()
	
	for child in $BlockModels.get_children(): child.queue_free()
	var pile_height: float = 0.0
	for block_data in blocks:
		var block_model: Node3D = block_data.model.instantiate()
		block_model.position.y = pile_height
		block_model.rotate_y(randf_range(0.0, 3.14))
		pile_height += block_data.height
		$BlockModels.add_child(block_model)
	$StaticBody3D/CollisionShape3D.shape.size.y = pile_height
	$StaticBody3D.position.y = pile_height * 0.5
