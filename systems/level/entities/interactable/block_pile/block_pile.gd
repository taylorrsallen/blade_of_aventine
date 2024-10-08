class_name BlockPile extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const BLOCK_PILE: PackedScene = preload("res://systems/level/entities/interactable/block_pile/block_pile.scn")
var BLOCK_RECIPE_DATABASE: BlockPileRecipeDatabase = load("res://resources/block_recipes/block_recipe_database.res")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var block_models: Node3D = $BlockModels
@export var blocks: Array[BlockData] = []
var pile_height: float

var valid_recipe: BlockPileRecipeData

var damage_to_block_destruction: float = 2.0
var damage_taken: float
var destroyed: bool

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	$StaticBody3D/CollisionShape3D.shape = $StaticBody3D/CollisionShape3D.shape.duplicate()
	_refresh()

func _physics_process(delta: float) -> void:
	damage_taken = max(damage_taken - delta, 0.0)

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
	for child in $BlockModels.get_children(): child.queue_free()
	pile_height = 0.0
	for block_data in blocks:
		var block_model: Node3D = block_data.model.instantiate()
		block_model.position.y = pile_height
		block_model.rotate_y(randf_range(0.0, 3.14))
		pile_height += block_data.height
		$BlockModels.add_child(block_model)
	$StaticBody3D/CollisionShape3D.shape.size.y = pile_height
	$StaticBody3D.position.y = pile_height * 0.5

	var found_recipe: BlockPileRecipeData = null
	for existing_recipe in BLOCK_RECIPE_DATABASE.database:
		if existing_recipe.ingredients.size() == blocks.size():
			var match_found: bool = true
			for i in existing_recipe.ingredients.size():
				if existing_recipe.ingredients[i] != blocks[i]:
					match_found = false
					continue
			
			if match_found:
				found_recipe = existing_recipe
	
	if found_recipe:
		valid_recipe = found_recipe
	else:
		valid_recipe = null

func try_craft() -> void:
	if !valid_recipe: return
	var result = valid_recipe.result.instantiate()
	result.recipe = valid_recipe
	result.faction_id = faction_id
	result.position = global_position - Vector3.UP * 5.0
	Util.main.level.add_tile_entity(result)
	queue_free()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func damage(damage_data: DamageData, _source: Node) -> void:
	if destroyed: return
	
	damage_taken += damage_data.damage_strength
	if damage_taken >= damage_to_block_destruction:
		damage_taken -= damage_to_block_destruction
		var taken_block_pile: BlockPile = take_block()
		if taken_block_pile == self:
			destroyed = true
			queue_free()
