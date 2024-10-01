extends Resource
class_name CharacterBodyAttributeData

@export var strength: int = 5
@export var endurance: int = 5
@export var dexterity: int = 5
@export var luck: int = 5

func update_stats(base_stats: CharacterBodyStatsData, current_stats: CharacterBodyStatsData) -> void:
	current_stats = base_stats.duplicate()
	
	current_stats.weight_mult += strength * 0.05
	current_stats.all_speed_mult += strength * 0.05
	current_stats.movement_force_mult += strength * 0.025
	current_stats.attack_force_mult += strength * 0.05
	current_stats.recoil_mult = clampf(current_stats.recoil_mult - strength * 0.01, 0.0, 100.0)
	current_stats.percent_resistance = clampf(current_stats.percent_resistance + strength * 0.05, 0.0, 100.0)
	current_stats.flat_resistance += strength * 0.5
	current_stats.jump_height_mult += strength * 0.5
	current_stats.stamina_use_mult += strength * 0.1
	current_stats.health_per_second += strength * 0.05
	current_stats.max_health += strength * 2.0
	
	current_stats.percent_resistance = clampf(current_stats.percent_resistance + endurance * 0.05, 0.0, 100.0)
	current_stats.flat_resistance += endurance * 0.5
	current_stats.stamina_per_second += endurance
	current_stats.max_stamina += endurance * 5.0
	current_stats.health_per_second += endurance * 0.025
	current_stats.max_health += endurance
	
	current_stats.air_control_mult = clampf(current_stats.air_control_mult + dexterity * 0.01, 0.0, 1.0)
	current_stats.all_speed_mult += dexterity * 0.05
	
