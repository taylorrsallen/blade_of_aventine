class_name Interactable extends Node3D

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal just_highlighted(interactable: Interactable, source: Character, controller: PlayerController)
signal just_unhighlighted(interactable: Interactable, source: Character, controller: PlayerController)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var collider: InteractableCollider = $StaticBody3D
var recipe: BlockPileRecipeData

@export var faction_id: int
@export var team: int

@export var weight_slow_down: float
## If untrue, then it can be used like a button
@export var liftable: bool = true

var highlighted: bool
var grabbed: bool

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func set_grabbed(active: bool) -> void:
	if active:
		grabbed = true
		_disable_collision()
	else:
		grabbed = false
		_enable_collision()


func _enable_collision() -> void: collider.collision_layer = 513
func _disable_collision() -> void: collider.collision_layer = 0

func drop(_source: Node3D) -> void: pass

func interact(_source: Character, _controller: PlayerController) -> void: pass

func set_highlighted(active: bool, source: Character, controller: PlayerController) -> void:
	highlighted = active
	if highlighted:
		just_highlighted.emit(self, source, controller)
	else:
		just_unhighlighted.emit(self, source, controller)
