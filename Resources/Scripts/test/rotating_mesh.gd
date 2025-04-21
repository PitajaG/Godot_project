extends Node3D

@export var rotation_speed: float = 0.1
@export var axis: AXIS = AXIS.Z

enum AXIS {
	X,
	Y,
	Z
}

func _process(delta: float) -> void:
	rotation[axis] += delta * rotation_speed
