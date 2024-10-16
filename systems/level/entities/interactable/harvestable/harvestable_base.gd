class_name HarvestableBase extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const BLOCK_PILE: PackedScene = preload("res://systems/level/entities/interactable/block_pile/block_pile.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
var data: HarvestableData: set = _set_data

var model: Node3D

var hits: int

func _set_data(_data: HarvestableData) -> void:
	data = _data
	
	if get_children().is_empty(): return
	$InteractableCollider/CollisionShape3D.shape.height = data.height
	$InteractableCollider/CollisionShape3D.shape.radius = data.radius
	$InteractableCollider.position.y = data.height * 0.5
	if is_instance_valid(model): model.queue_free()
	model = data.model_scene.instantiate()
	add_child(model)
	
	if data.interactable_data: interactable_data = data.interactable_data

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	$InteractableCollider/CollisionShape3D.shape = $InteractableCollider/CollisionShape3D.shape.duplicate()
	data = data

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func deal_scepter_damage() -> void:
	if destroyed: return
	
	_deal_scepter_damage()
	
	hits += 1
	
	await _play_generic_damage_animation()
	
	if hits >= data.scepter_hits_to_break: destroy()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func destroy() -> void:
	_destroy()
	
	if data.pickup_drops: data.pickup_drops.drop(global_position)
	
	if !data.block_drops.is_empty():
		var block_pile: BlockPile = BLOCK_PILE.instantiate()
		for block_data in data.block_drops: block_pile.add_block(block_data)
		block_pile.position = global_position
		block_pile.position.y = 0.0
		Util.main.level.add_tile_entity(block_pile)

func _play_generic_damage_animation() -> void:
	for i in 5:
		model.position = (Vector3(randf(), randf(), randf()) - Vector3.ONE * 0.5) * 0.3
		await get_tree().create_timer(0.01).timeout
		model.position = Vector3.ZERO
		await get_tree().create_timer(0.01).timeout
