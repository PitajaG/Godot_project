extends RigidBody3D

@onready var dmg_particle = preload("res://scenes/damage_particle.tscn")
@onready var bounce_particle = preload("res://scenes/kotlet_bounce_particle.tscn")
@onready var label = preload("res://scenes/damage_info.tscn")

@export var speed = 100
var deflect_count = 0
var damage = 50

@onready var hitbox = $hitbox

#func BounceParticle():
	
	

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 5
	linear_velocity = transform.basis.z * -speed 
	var ignored_object = get_node("../Player") 
	add_collision_exception_with(ignored_object)
	
func _integrate_forces(state: PhysicsDirectBodyState3D):
	if state.get_contact_count() > 0:
		var normal = state.get_contact_local_normal(0) 
		linear_velocity = linear_velocity.bounce(normal).normalized() * speed 
		deflect_count += 1
		var p = bounce_particle.instantiate()
		get_tree().get_root().add_child(p)
		p.global_transform.origin = self.global_transform.origin
		
		
func _physics_process(_delta: float) -> void:
	if  deflect_count == 50:
		queue_free()
	else:
		pass
func _process(_delta):
	for body in hitbox.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			#label.text = var_to_str(Global.schab_dmg)
			var b = dmg_particle.instantiate()
			get_tree().get_root().add_child(b)
			b.global_transform.origin = body.global_transform.origin
			body.health -= Global.schab_dmg
			self.queue_free()
