class_name HUDGui extends Control

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
@onready var active_wave_contents_icon: WaveContentsIcon = $PanelContainer/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/HBoxContainer/ActiveWaveContentsIcon
@onready var wave_progress_bar: ProgressBar = $PanelContainer/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/HBoxContainer/WaveProgressBar
@onready var incoming_wave_contents_icon: WaveContentsIcon = $IncomingWaveContentsIcon
@onready var next_wave_contents_icon: WaveContentsIcon = $PanelContainer/PanelContainer/MarginContainer/HBoxContainer/MarginContainer/HBoxContainer/NextWaveContentsIcon

@onready var coins_icon: TextureRect = $PanelContainer/PanelContainer/MarginContainer/HBoxContainer/HBoxContainer/HBoxContainer/CoinsIcon
@onready var coins_label: Label = $PanelContainer/PanelContainer/MarginContainer/HBoxContainer/HBoxContainer/HBoxContainer/CoinsLabel
@onready var bread_icon: TextureRect = $PanelContainer/PanelContainer/MarginContainer/HBoxContainer/HBoxContainer/HBoxContainer2/BreadIcon
@onready var bread_label: Label = $PanelContainer/PanelContainer/MarginContainer/HBoxContainer/HBoxContainer/HBoxContainer2/BreadLabel

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func set_wave_progress(progress: float) -> void:
	wave_progress_bar.value = progress
	incoming_wave_contents_icon.global_position.x = wave_progress_bar.global_position.x + wave_progress_bar.size.x * (1.0 - progress) - incoming_wave_contents_icon.size.x * 0.5
	incoming_wave_contents_icon.global_position.y = wave_progress_bar.global_position.y + wave_progress_bar.size.y * 0.5 - incoming_wave_contents_icon.size.y * 0.5
	incoming_wave_contents_icon.show()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_wave_progress_changed(progress: float) -> void:
	set_wave_progress(progress)

func _on_active_wave_icons_changed(icons: Array[Texture2D]) -> void:
	active_wave_contents_icon.clear()
	for i in icons.size(): active_wave_contents_icon.set_icon_texture(i, icons[i])

func _on_incoming_wave_icons_changed(icons: Array[Texture2D]) -> void:
	incoming_wave_contents_icon.clear()
	for i in icons.size(): incoming_wave_contents_icon.set_icon_texture(i, icons[i])

func _on_next_wave_icons_changed(icons: Array[Texture2D]) -> void:
	next_wave_contents_icon.clear()
	for i in icons.size(): next_wave_contents_icon.set_icon_texture(i, icons[i])

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _on_viewport_size_changed() -> void:
	coins_label.add_theme_font_size_override("font_size", get_viewport().size.y * 0.0463)
	bread_label.add_theme_font_size_override("font_size", get_viewport().size.y * 0.0463)
	await get_tree().create_timer(0.1).timeout
	incoming_wave_contents_icon.size = active_wave_contents_icon.size
