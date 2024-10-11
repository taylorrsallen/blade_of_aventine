class_name DropsData extends Resource

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const PICKUP: PackedScene = preload("res://systems/level/entities/pickup/pickup.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@export var drops: Array[DropData] = []

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func drop(global_coord: Vector3) -> void:
	for drop_data in drops:
		for i in drop_data.amount:
			if drop_data.should_drop():
				var pickup: Pickup = PICKUP.instantiate()
				pickup.pickup_data = drop_data.pickup_data
				pickup.position = global_coord
				Util.main.level.add_pickup(pickup)
