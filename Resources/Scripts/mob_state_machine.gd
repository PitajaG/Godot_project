extends CharacterBody3D

# Stany w jakich może znajdować się mob
enum {
	IDLE,
	FIGHT,
	ATTACK,
	DAMAGED,
	STUNNED,
	HOOKED
}

# Statystyki moba
const attack_dm = 20
var health = 200
const turn_speed : float = 5.0
const speed : float = 2.5

# Stan początkowy przeciwnika
var state = IDLE
var target
var player = null
var player_path : NodePath

# Referencje
@onready var raycast = $RayCast3D
@onready var ap = $AnimationPlayer
@onready var eyes = $Eyes
@onready var nav_agent = $NavigationAgent3D
@onready var attack_timer = $AttackTimer
@onready var death_particle = preload("res://scenes/destroy_particle.tscn")

func _ready():
	player = get_tree().get_first_node_in_group("Player")

# Funkcja wywoływana poprzez wejście gracza w polę widzenia przeciwnika
# Zmienia stan przeciwnika na walkę
# Ustawia cel przeciwnika na gracza
func _on_sight_range_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		state = FIGHT
		target = body

# Funkcja wywoływana poprzez wyjście gracza z pola widzenia przeciwnika
func _on_sight_range_body_exited(body: Node3D) -> void:
	state = IDLE

func _process(delta):
	match state:
		IDLE:
			pass
			# ap.play("IDLE")
		FIGHT:
			# ap.play("FIGHT")
			# Kiedy przeciwnik jest w stanie walki automatycznie obróci się na przeciwnika
			if target:
				eyes.look_at(target.global_transform.origin, Vector3.UP)
				rotate_y(deg_to_rad(eyes.rotation.y * turn_speed))
				velocity = Vector3.ZERO
				nav_agent.set_target_position(player.global_transform.origin)
				var next_nav_point = nav_agent.get_next_path_position()
				velocity = (next_nav_point - global_transform.origin).normalized() * speed
				move_and_slide()
			else:
				pass
		ATTACK:
			if attack_timer.is_stopped():
				attack_timer.start()
		DAMAGED:
			print("DAMAGED")
			# ap.play("DAMAGED")
		STUNNED:
			print("STUNNED")
			# ap.play("STUNNED")
		HOOKED:
			print("HOOKED")
			# ap.play("HOOKED")
	if health <= 0:
		var p = death_particle.instantiate()
		get_tree().get_root().add_child(p)
		p.global_transform.origin = self.global_transform.origin
		queue_free()

# Funkcja sprawdza czy gracz znajduje się w zasięgu ataku
func _on_attack_range_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if player.has_method("mob_hit"):
				player.mob_hit(attack_dm)
		state = ATTACK

func _on_attack_range_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		state = FIGHT
		attack_timer.stop()

func _on_attack_timer_timeout() -> void:
	if player.has_method("mob_hit"):
		player.mob_hit(attack_dm)
