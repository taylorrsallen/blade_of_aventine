class_name GrabbableBread extends Interactable

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
const BREAD: PickupData = preload("res://resources/pickups/bread.res")
var PICKUP: PackedScene = load("res://systems/level/entities/pickup/pickup.scn")

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func drop(source: Node3D) -> void:
	var pickup: Pickup = PICKUP.instantiate()
	pickup.position = source.global_position
	pickup.pickup_data = BREAD
	Util.main.level.add_pickup(pickup)
	queue_free()
