
extends CharacterBody3D

# Debug
var Draw_cls = load("res://Resources/Scripts/util/draw.gd")
var Draw = Draw_cls.new()
var Draw2 = Draw_cls.new()

# Referencje
@onready var camera: Camera3D = $Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var capsule_shape : CapsuleShape3D = collision_shape.shape
@onready var hand =  $Camera3D/hand
@onready var reach = $Camera3D/Reach
@onready var schabow_projectile = preload("res://scenes/Schabowy/schabow_projectile.tscn")
@onready var schabow_gun = preload("res://scenes/Schabowy/schabow_gun.tscn")
@onready var schabow_pickup = preload("res://scenes/Schabowy/schabow_pickup.tscn")
@onready var chrupiaca_projectile = preload("res://scenes/Chrupiaca/chrupiaca_projectile.tscn")
@onready var chrupiaca_pickup = preload("res://scenes/Chrupiaca/chrupiaca_pickup.tscn")
@onready var chrupiaca_gun = preload("res://scenes/Chrupiaca/chrupiaca_gun.tscn")
@onready var melee_anim = $AnimationPlayer
@onready var melee_hitbox = $"Camera3D/melee hitbox"
@onready var patelnia = $Camera3D/Patelnia
@onready var dmg_particle = preload("res://scenes/damage_particle.tscn")
@onready var label = preload("res://scenes/damage_info.tscn")
@onready var FlightParticles1 = $FlightParticle1
@onready var FlightParticles2 = $FlightParticle2
@onready var hook_ray = $Camera3D/hook_ray
@onready var hook_origin_point = $hook_origin_point

# Parametry ruchu
@export var speed: float = 5.0
@export var crouch_speed: float = 2.5
@export var jump_force: float = 4.5
@export var gravity: float = 9.8
var direction

# Przyspieszenie
@export var ground_acceleration: float = 20.0
@export var air_acceleration: float = 5.0
@export var ground_friction: float = 15.0
@export var air_friction: float = 1.0

# Kucanie
var is_crouching = false
var original_camera_height: float
var original_height: float 
var crouch_height: float 

# Parametry ślizgu
var is_sliding: bool = false
var slide_cooldown: float = 0.0
var slide_speed: float
var last_slide_collision
var true_velocity: Vector3 = Vector3.ZERO
@export var slide_cd_time: float = 0.2
@export var slide_speed_multiplier: float = 1.5
@export var slide_rotation_speed_multiplier: float = 0.15

# Parametry latania
var is_flying: bool = false
var can_fly: bool = false
var current_flight_speed: float = 0.0
var current_flight_velocity: float = 0.0
@export var flight_speed: float = 6.0
@export var flight_accel: float = 8.0
@export var flight_fuel: float = 100.0
@export var fuel_consumption: float = 15.0

# Wall jump
var last_wall_normal: Vector3 = Vector3.ZERO
var wall_jump_timer: float = 0.0
@export var wall_jump_force: float = 6.0
@export var wall_jump_cooldown: float = 0.3
@export var wall_jump_horizontal_multiplier: float = 1.2

# Czułość myszy
@export var mouse_sensitivity: float = 0.002

# Zmienne wewnętrzne
var last_velocity: Vector3 = Vector3.ZERO
var last_active_collison
var last_active_collison_normal: Vector3 = Vector3.ZERO
var camera_pitch: float = 0.0
var original_camera_y: float
var original_shape: CapsuleShape3D
@export var health = 100
@export var max_health = 100
@export var min_health = 0

# Healing
var pierog_count: int
signal health_change(health, min_health, max_health)

# Hook
var is_hooked := false
var hook_distance
var hook_point
var max_hook_distance
var hooked_enemy
var hook_enemy_distance
var current_h_e_d
var enemy_is_hooked
var swing_dir
# Tu będą funkcje – zostaną dołączone w następnym kroku

func _ready():
	add_child(Draw)
	add_child(Draw2)
	slide_speed = speed * slide_speed_multiplier
	original_height = collision_shape.shape.height
	original_camera_height = camera.position.y
	crouch_height = original_height / 2
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	floor_max_angle = deg_to_rad(89)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pitch += event.relative.y * mouse_sensitivity
		camera_pitch = clamp(camera_pitch, deg_to_rad(-90), deg_to_rad(90))
		camera.rotation.x = -camera_pitch

func _physics_process(delta):
	if velocity.length() > 0:
		Global.melee_dmg = int(100 + 5 * velocity.length())
	else:
		Global.melee_dmg = 100
	hook()
	if is_hooked:
		if velocity.length() >= 22:
			release_hook()
		if is_sliding:
			end_slide()
		if is_crouching:
			end_crouch()
		velocity.y -= gravity * delta
		move_and_slide()
		var to_hook = global_position - hook_point
		var distance = to_hook.length()
		if Input.is_action_pressed("ui_up") and distance > 5:
			hook_distance -= 2 * delta
		if Input.is_action_pressed("ui_down") and distance <= max_hook_distance:
			hook_distance += 2 * delta
		if distance > hook_distance:
			var dir = to_hook.normalized()
			global_position = hook_point + dir * hook_distance
			velocity = (velocity).slide(dir)
	else:
		wall_jump_timer = max(wall_jump_timer - delta, 0.0)
		slide_cooldown = max(slide_cooldown - delta, 0.0)
		flight(delta)
		if is_sliding:
			if Input.is_action_just_released("slide"):
				end_slide()
		elif not slide_cooldown and is_on_floor() and Input.is_action_pressed("slide"):
			start_slide()
		if not is_on_floor():
			velocity.y -= gravity * delta
		var is_on_wall = false
		if get_last_slide_collision() != null:
			last_wall_normal = get_last_slide_collision().get_normal()
			is_on_wall = last_wall_normal.dot(Vector3.UP) < 0.1 && !is_on_floor()
		if Input.is_action_just_pressed("ui_accept"):
			if is_on_floor():
				if is_sliding:
					end_slide()
				velocity.y = jump_force
			elif is_on_wall and wall_jump_timer <= 0.0:
				var wall_jump_dir = last_wall_normal * wall_jump_horizontal_multiplier
				velocity = Vector3(wall_jump_dir.x * wall_jump_force, jump_force, wall_jump_dir.z * wall_jump_force)
				wall_jump_timer = wall_jump_cooldown

		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if is_sliding:
			sliding(delta)
		else:
			var target_velocity = direction * speed
			var horizontal_velocity = Vector2(velocity.x, velocity.z)
			var target_horizontal = Vector2(target_velocity.x, target_velocity.z)

			if input_dir != Vector2.ZERO:
				var accel = ground_acceleration if is_on_floor() else air_acceleration
				horizontal_velocity = horizontal_velocity.move_toward(target_horizontal, accel * delta)
			else:
				var friction = ground_friction if is_on_floor() else air_friction
				horizontal_velocity = horizontal_velocity.move_toward(Vector2.ZERO, friction * delta)

			velocity.x = horizontal_velocity.x
			velocity.z = horizontal_velocity.y

		last_velocity = velocity
		move_and_slide()

	if enemy_is_hooked:
		var pull_force = 5
		var enemy_hook_dir = (global_position - hooked_enemy.global_position).normalized()
		var pull_velocity = enemy_hook_dir * pull_force
		hook_enemy_distance = global_position.distance_to(hooked_enemy.global_position)
		if hook_enemy_distance > 2:
			hooked_enemy.velocity = pull_velocity * pull_force
			hooked_enemy.move_and_slide()
			print(hook_enemy_distance)
		else:
			enemy_is_hooked = false

	if enemy_is_hooked == null:
		enemy_is_hooked = false
		
func hook():
	if Input.is_action_just_pressed("hook"):
		if is_hooked:
			release_hook()
		elif hook_ray.is_colliding():
			if hook_ray.get_collider().is_in_group("Enviroment"):
				hook_point = hook_ray.get_collision_point()
				hook_distance = global_position.distance_to(hook_point)
				max_hook_distance = hook_distance
				is_hooked = true
				swing_dir = hook_point - global_position
				if swing_dir.y <= 0:
					velocity += swing_dir.normalized()*5
				velocity += Vector3(velocity.x, 0, velocity.z)
			elif hook_ray.get_collider().is_in_group("enemy"):
				enemy_is_hooked = true
				hooked_enemy = hook_ray.get_collider()
				print(hooked_enemy)
				current_h_e_d = hook_enemy_distance

func release_hook():
	is_hooked = false

func _process(delta):
	_item_pickup()
	powerup(delta)
	heal()
	if pierog_count <= 0:
		pierog_count = 0
	var screen_size = get_viewport().size
	$WeaponViewport/SubViewport/HandCamera.global_transform = $Camera3D.global_transform
	if health <= 0:
		death()

func _item_pickup():
	if Input.is_action_just_pressed("interact") and reach.get_collider():
		if reach.get_collider().is_in_group("Weapon_pickups"):
			if len(Global.arsenal) > 0:
				Global.weapon_index += 1
			if reach.get_collider().get_name() == "schabow_pickup":
				Global.arsenal.append("schabowy")
				Global.weapon_picked.emit()
			elif reach.get_collider().get_name() == "chrupiaca_pickup":
				Global.arsenal.append("chrupiaca")
				Global.weapon_picked.emit()
			reach.get_collider().queue_free()

func powerup(delta):
	if Input.is_action_just_pressed("interact") and reach.get_collider():
		if reach.get_collider().is_in_group("jetpack"):
			print("jetpack")
			can_fly = true
			reach.get_collider().queue_free()
		elif reach.get_collider().is_in_group("healing"):
			pierog_count += 1
			print("mam pieroga")
			reach.get_collider().queue_free()

func heal():
	if Input.is_action_just_pressed("healing") and pierog_count >= 1:
		if health <= 80:
			health += 20
		elif health >= 80:
			health = 100
		health_change.emit(health, min_health, max_health)
		pierog_count -= 1

func flight(delta):
	if Input.is_action_pressed("flight_debug") and flight_fuel > 0 and can_fly:
		if not is_flying:
			is_flying = true
			FlightParticles1.emitting = true
			FlightParticles2.emitting = true
		current_flight_velocity = lerp(current_flight_velocity, flight_speed, flight_accel * delta)
		velocity.y = current_flight_velocity
		flight_fuel = max(0, flight_fuel - fuel_consumption * delta)
	else:
		if is_flying:
			is_flying = false
			FlightParticles1.emitting = false
			FlightParticles2.emitting = false
			current_flight_velocity = 0.0

func start_crouch():
	is_crouching = true
	global_position.y -= (original_height - crouch_height) / 2 - 0.01
	capsule_shape.height = crouch_height
	var tween = get_tree().create_tween()
	tween.tween_property(camera, "position", Vector3(0, original_camera_height / 2, 0), 0.1)

func end_crouch():
	is_crouching = false
	global_position.y += (original_height - crouch_height) / 2 - 0.01
	capsule_shape.height = original_height
	var tween = get_tree().create_tween()
	tween.tween_property(camera, "position", Vector3(0, original_camera_height, 0), 0.15).set_ease(Tween.EASE_IN)

func start_slide():
	is_sliding = true
	slide_speed = velocity.length() * slide_speed_multiplier
	true_velocity = last_velocity
	start_crouch()
	var current_velocity = Vector3(velocity.x, 0, velocity.z)
	var slide_direction: Vector3 = current_velocity.normalized() if current_velocity.length() else -global_transform.basis.z.normalized()
	velocity = slide_direction * slide_speed

func end_slide():
	is_sliding = false
	last_slide_collision = null
	floor_snap_length = 0.1
	end_crouch()
	slide_cooldown = slide_cd_time

func sliding(delta):
	var floor_angle = get_floor_angle()
	var slide_normal = get_floor_normal()
	var slide_collision = null
	if get_slide_collision_count():
		slide_collision = get_slide_collision(0).get_collider()
		slide_normal = get_slide_collision(0).get_normal()
	if true_velocity.dot(slide_normal) <= 0:
		floor_snap_length = clamp(true_velocity.length(), 0.1, 100)
	else:
		floor_snap_length = 0
	if not is_on_floor():
		true_velocity.y -= gravity * delta
	if slide_collision and last_slide_collision != slide_collision or slide_normal != last_active_collison_normal:
		last_slide_collision = slide_collision
		last_active_collison_normal = slide_normal
		var bounce_velocity = true_velocity - slide_normal * true_velocity.dot(slide_normal)
		true_velocity = bounce_velocity
	if is_on_floor() and floor_angle:
		var rotation_axis = slide_normal.cross(Vector3.DOWN).normalized()
		var slope_speed = sin(floor_angle) * gravity
		var slope_direction = slide_normal.rotated(rotation_axis, PI / 2)
		var slope_velocity = slope_direction * slope_speed * delta
		true_velocity += slope_velocity
	velocity = true_velocity

func mob_hit(dmg):
	health -= dmg
	print(health)
	health_change.emit(health, min_health, max_health)
	if health <= 0:
		death()

func death():
	get_tree().reload_current_scene()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
