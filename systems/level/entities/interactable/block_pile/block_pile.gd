class_name BlockPile extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const BLOCK_PILE: PackedScene = preload("res://systems/level/entities/interactable/block_pile/block_pile.scn")
var BLOCK_RECIPE_DATABASE: BlockPileRecipeDatabase = load("res://resources/block_recipes/block_recipe_database.res")
#const BLOCK_RECIPE_DATABASE = preload("res://resources/block_recipes/block_recipe_database.res")
# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var block_models: Node3D = $BlockModels
@export var blocks: Array[BlockData] = []
var pile_height: float

var valid_recipe: BlockPileRecipeData

var damage_to_block_destruction: float = 2.0
var damage_taken: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	$InteractableCollider/CollisionShape3D.shape = $InteractableCollider/CollisionShape3D.shape.duplicate()
	_refresh()

func _physics_process(delta: float) -> void:
	_update_thrown_state(delta)
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
		Util.main.level.add_tile_entity(new_block_pile)
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
	$InteractableCollider/CollisionShape3D.shape.size.y = pile_height
	$InteractableCollider.position.y = pile_height * 0.5

	var found_recipe: BlockPileRecipeData = null
	for existing_recipe in BLOCK_RECIPE_DATABASE.database:
		if existing_recipe.ingredients.size() == blocks.size():
			var match_found: bool = true
			var recipe_quantities: Dictionary = {}
			for ingredient in existing_recipe.ingredients:
				if !recipe_quantities.has(ingredient):
					recipe_quantities[ingredient] = 1
				else:
					recipe_quantities[ingredient] += 1
			
			var block_pile_quantities: Dictionary = {}
			for block in blocks:
				if !block_pile_quantities.has(block):
					block_pile_quantities[block] = 1
				else:
					block_pile_quantities[block] += 1
			
			for key in recipe_quantities.keys():
				if !block_pile_quantities.has(key):
					match_found = false
					break
				if recipe_quantities[key] != block_pile_quantities[key]:
					match_found = false
					break
			
			if match_found:
				found_recipe = existing_recipe
	
	if found_recipe:
		valid_recipe = found_recipe
	else:
		valid_recipe = null

func try_craft() -> bool:
	if !valid_recipe: return false
	EventBus.tower_built.emit()
	var result: Interactable = valid_recipe.instantiate(global_position)
	result.faction_id = faction_id
	queue_free()
	return true

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func damage(damage_data: DamageData, _source: Node) -> void:
	if destroyed: return
	
	_deal_scepter_damage()
	
	damage_taken += damage_data.damage_strength
	if damage_taken >= damage_to_block_destruction:
		damage_taken -= damage_to_block_destruction
		var taken_block_pile: BlockPile = take_block()
		if taken_block_pile == self:
			_destroy()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _special_tumbling_interactable_collision(interactable: Interactable) -> bool:
	if interactable is BlockPile && !blocks.is_empty():
		for i in blocks.size():
			interactable.add_block(blocks[i])
		queue_free()
		return true
	else:
		return false
