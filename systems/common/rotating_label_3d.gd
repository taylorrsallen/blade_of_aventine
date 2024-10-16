class_name RotatingLabel3D extends Label3D

var rot_timer: float
func _physics_process(delta: float) -> void:
	rot_timer += delta
	rotation_degrees.y = -180.0 - sin(rot_timer * 2) * 10.0
