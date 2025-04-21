extends RigidBody3D

var dropped:bool = false

func _ready():
	pass

func _process(delta: float) -> void:
	if dropped == true:
		apply_impulse(transform.basis.z, -transform.basis.z * 10)
		dropped = false
