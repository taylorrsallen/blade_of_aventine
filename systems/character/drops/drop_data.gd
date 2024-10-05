class_name DropData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var pickup_data: PickupData
@export var amount: int
@export_range(0.0, 1.0) var chance: float = 1.0

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func should_drop() -> bool:
	if chance == 1.0: return true
	if randf() > 1.0 - chance: return true
	return false
