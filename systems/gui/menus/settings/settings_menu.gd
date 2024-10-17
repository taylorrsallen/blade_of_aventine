class_name SettingsMenu extends MenuBase

@onready var fov: SettingsSlider = $CanvasLayer/PanelContainer/MarginContainer/VBoxContainer/FOV

func _ready() -> void:
	if is_instance_valid(Util.player.camera_rig): fov.value = Util.player.camera_rig.base_fov

func _on_back_pressed() -> void: go_back()

func _on_master_volume_slider_value_changed(value: float) -> void: SoundManager.master_volume = value * 0.01
func _on_music_volume_slider_value_changed(value: float) -> void: SoundManager.music_volume = value * 0.01
func _on_ambience_volume_slider_value_changed(value: float) -> void: SoundManager.ambience_volume = value * 0.01
func _on_ui_volume_slider_value_changed(value: float) -> void: SoundManager.ui_volume = value * 0.01
func _on_sfx_volume_slider_value_changed(value: float) -> void: SoundManager.sfx_volume = value * 0.01

func _on_fov_value_changed(value: float) -> void:
	for i in 4:
		var player_controller: PlayerController = Util.get_player_controller(i)
		if !is_instance_valid(player_controller) || !is_instance_valid(player_controller.camera_rig): continue
		player_controller.camera_rig.base_fov = value
