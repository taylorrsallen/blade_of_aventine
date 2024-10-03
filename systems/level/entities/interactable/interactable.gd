class_name Interactable extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var collider: InteractableCollider = $StaticBody3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func enable_collision() -> void: collider.collision_layer = 513
func disable_collision() -> void: collider.collision_layer = 0
