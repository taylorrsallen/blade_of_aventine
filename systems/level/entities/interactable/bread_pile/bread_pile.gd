class_name BreadPile extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal faction_defeated(bread_pile: BreadPile)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const GRABBABLE_BREAD: PackedScene = preload("res://systems/level/entities/interactable/bread_pile/grabbable_bread.scn")
const BREAD_STACK_MODEL: PackedScene = preload("res://scenes/items/bread_stack_model.scn")

const BREAD_STACK_PLACEMENT_POSITIONS: Array[Vector3] = [
	Vector3(-1.0, 0.0, -1.0),
	Vector3(0.0, 0.0, -1.0),
	Vector3(1.0, 0.0, -1.0),
	Vector3(-1.0, 0.0, 0.0),
	Vector3(0.0, 0.0, 0.0),
	Vector3(1.0, 0.0, 0.0),
	Vector3(-1.0, 0.0, 1.0),
	Vector3(0.0, 0.0, 1.0),
	Vector3(1.0, 0.0, 1.0),
]

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var faction_id: int
@export var bread_count: int: set = _set_bread_count

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_bread_count(_bread_count: int) -> void:
	bread_count = max(0, _bread_count)
	if bread_count == 0: faction_defeated.emit(self)
	_refresh()

func take_bread() -> GrabbableBread:
	if bread_count > 0:
		bread_count -= 1
		_refresh()
		return GRABBABLE_BREAD.instantiate()
	return null

func _refresh() -> void:
	for child in $BreadStacks.get_children(): child.queue_free()
	var bread_to_place: int = bread_count
	var stacks_placed: int = 0
	while bread_to_place > 0 && stacks_placed < 9:
		bread_to_place -= 5
		var bread_stack_model: Node3D = BREAD_STACK_MODEL.instantiate()
		bread_stack_model.position = BREAD_STACK_PLACEMENT_POSITIONS[stacks_placed]
		bread_stack_model.rotate_y(randf() * 3.14)
		bread_stack_model.scale = Vector3(randf_range(0.9, 1.1), randf_range(0.9, 1.1), randf_range(0.9, 1.1))
		$BreadStacks.add_child(bread_stack_model)
		stacks_placed += 1
