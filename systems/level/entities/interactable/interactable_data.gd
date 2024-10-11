class_name InteractableData extends Resource

@export_category("Interaction")
@export var interact_sounds: SoundPoolData
@export var lift_sounds: SoundPoolData
@export var place_sounds: SoundPoolData
@export var hit_sounds: SoundPoolData
@export var break_sounds: SoundPoolData

@export var weight_slow_down: float
## If untrue, then it can be used like a button
@export var liftable: bool = true
@export var throwable: bool
@export var break_when_thrown: bool
