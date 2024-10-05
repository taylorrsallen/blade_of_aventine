class_name BreadPile extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal faction_defeated(bread_pile: BreadPile)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const GRABBABLE_BREAD: PackedScene = preload("res://systems/level/entities/interactable/bread_pile/grabbable_bread.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var faction_id: int
@export var bread_count: int: set = _set_bread_count

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _set_bread_count(_bread_count: int) -> void:
	bread_count = max(0, _bread_count)
	if bread_count == 0: faction_defeated.emit(self)
	
	if !get_children().is_empty(): $MeshInstance3D.mesh.size.y = bread_count * 0.25

func take_bread() -> GrabbableBread:
	if bread_count > 0:
		bread_count -= 1
		return GRABBABLE_BREAD.instantiate()
	return null
