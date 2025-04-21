extends RigidBody3D

@onready var dmg_particle = preload("res://scenes/damage_particle.tscn")
@export var speed = 100

@onready var hitbox = $hitbox
@onready var label = preload("res://scenes/damage_info.tscn")

func _ready() -> void:
	var ignored_object = get_node("../Player") 
	var ignore_schabow = get_node("res://scenes/Schabowy/schabow_gun.tscn")
	add_collision_exception_with(ignored_object)
		


func _process(delta):
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			#label.text = var_to_str(Global.chrupiaca_dmg)
			var b = dmg_particle.instantiate()
			get_tree().get_root().add_child(b)
			b.global_transform.origin = body.global_transform.origin
			body.health -= Global.chrupiaca_dmg
			self.queue_free()
		elif  body.is_in_group("enviroment"):
			self.queue_free()
	position+=transform.basis.z * -speed * delta
	global_position=position
	
