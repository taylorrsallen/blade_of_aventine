class_name EnemySpawner extends Node3D

const CHARACTER: PackedScene = preload("res://systems/character/character.scn")
const AI_CONTROLLER: PackedScene = preload("res://systems/controller/ai/ai_controller.scn")

@export var enemies_per_second: float = 0.01
var spawn_timer: float = 0.0

var max: int = 150
var spawned: int

func _physics_process(delta: float) -> void:
	if spawned >= max: return
	
	spawn_timer += delta
	if spawn_timer >= enemies_per_second:
		spawn_timer -= enemies_per_second
		spawn_enemy()
	
	DebugDraw2D.set_text("Enemies: ", spawned)

func spawn_enemy() -> void:
	spawned += 1
	
	var ai_controller: AIController = AI_CONTROLLER.instantiate()
	Util.main.add_child(ai_controller)
	ai_controller.character = CHARACTER.instantiate()
	ai_controller.character.position = global_position
	ai_controller.character.jog_speed = 1.5
	ai_controller.add_child(ai_controller.character)
