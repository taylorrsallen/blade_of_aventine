extends CharacterBody

func _ready() -> void:
	right_hand = $aventine_pigeon/Armature/Skeleton3D/RightHand
	left_hand = $aventine_pigeon/Armature/Skeleton3D/LeftHand

func _physics_process(delta: float) -> void:
	_update(delta)
