class_name Interactable extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var collider: InteractableCollider = $StaticBody3D
var recipe: BlockPileRecipeData

@export var faction_id: int
@export var team: int

@export var weight_slow_down: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func enable_collision() -> void: collider.collision_layer = 513
func disable_collision() -> void: collider.collision_layer = 0

func drop(_source: Node3D) -> void: pass
