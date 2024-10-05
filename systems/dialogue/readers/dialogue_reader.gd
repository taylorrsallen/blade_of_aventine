class_name DialogueReader extends Node

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
signal finished_reading()
signal sound_queue(sound_id: int, sound_type: int, volume_db: float, pitch: float)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
var active_text: String

@export var data: DialogueData

var active_char: int
var active_line: DialogueLineData
var lines_to_read: Array[DialogueLineData]

var started: bool = false
var finished: bool = false

var char_read_cd_mod: float
var char_read_cd: float = 0.1
var char_read_timer: float
var pause_timer: float

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _physics_process(delta: float) -> void:
	if !started || finished: return
	finished = _try_read_lines(delta)

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func start() -> void:
	started = true
	lines_to_read = data.lines.duplicate()
	if lines_to_read.is_empty():
		finished = true
	else:
		active_line = lines_to_read.pop_front()

func skip_to_end_of_current_line() -> void:
	active_text = active_line.line
	pause_timer = 0.0
	active_char = active_line.line.length()

func skip_line() -> void:
	_reset_line_reader()

# (({[%%%(({[=======================================================================================================================]}))%%%]}))
func _try_read_lines(delta: float) -> bool:
	if !active_line: active_line = lines_to_read.pop_front()
	
	if !active_line:
		finished_reading.emit()
		return true
	
	char_read_timer += delta * active_line.speed * data.speaker.speed
	if char_read_timer >= char_read_cd + char_read_cd_mod:
		char_read_timer -= char_read_cd + char_read_cd_mod
		char_read_cd_mod = 0.0
		if active_char < active_line.line.length():
			_add_char_to_line()
			active_char += 1
	
	if active_line.pause_after_finished < 0.0: return false
	if active_char == active_line.line.length():
		pause_timer += delta
		if pause_timer >= active_line.pause_after_finished:
			_reset_line_reader()
	
	return false

func _add_char_to_line() -> void:
	var char: String = active_line.line[active_char]
	var sound_id: int = data.speaker.beep.id
	var sound_type: int = data.speaker.beep.type
	var pitch: float = active_line.pitch * data.speaker.pitch
	active_text += char
	
	if char == ",":
		char_read_cd_mod = 0.2 * active_line.speed * data.speaker.speed
		sound_queue.emit(sound_id, sound_type, 0.0, 0.95 * pitch)
	elif char == ".":
		if active_char + 1 < active_line.line.length() && active_line.line[active_char + 1] == " ":
			char_read_cd_mod = active_line.speed * data.speaker.speed
		sound_queue.emit(sound_id, sound_type, 0.0, 0.95 * pitch)
	elif char == "!":
		if active_char + 1 < active_line.line.length() && active_line.line[active_char + 1] == " ":
			char_read_cd_mod = active_line.speed * data.speaker.speed
		sound_queue.emit(sound_id, sound_type, 0.0, 1.1 * pitch)
	elif char != " ":
		sound_queue.emit(sound_id, sound_type, 0.0, pitch)
	else:
		sound_queue.emit(sound_id, sound_type, -4.0, pitch)

func _reset_line_reader() -> void:
	active_line = null
	active_char = 0
	pause_timer = 0.0
	char_read_timer = 0.0
	active_text = ""
