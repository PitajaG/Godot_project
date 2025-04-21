extends CharacterBody3D

@onready var death_particle = preload("res://scenes/destroy_particle.tscn")

var health = 200

	
func _process(_delta):
	if health <= 0:
		var p = death_particle.instantiate()
		get_tree().get_root().add_child(p)
		p.global_transform.origin = self.global_transform.origin
		queue_free()
