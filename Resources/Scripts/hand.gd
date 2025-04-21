extends Node3D

@onready var koklet = preload("res://scenes/Schabowy/schabow_projectile.tscn")
@onready var chrupiaca = preload("res://scenes/Chrupiaca/chrupiaca_projectile.tscn")
@onready var label = preload("res://scenes/damage_info.tscn")
@onready var dmg_particle = preload("res://scenes/damage_particle.tscn")
@onready var hit_particle = preload("res://scenes/melee_particle.tscn")
@onready var hand = self
@onready var camera = $".."
@onready var animation_player = $AnimationPlayer
@onready var shooting_point = $shooting_point
@onready var schabow_gun = $schabow_gun
@onready var chrupiaca_gun = $chrupiaca_gun
@onready var patelnia = $Patelnia
@onready var melee_hitbox = $"melee hitbox"

var melee_is_blocking = 0
var melee_can_hit = 0
var current_weapon
var projectile
var playing_reversed = false  
var anim_speed = 1.0  
var throw_cooldown = 0
func _ready():
	animation_player.animation_finished.connect(_on_animation_finished)
	Global.weapon_picked.connect(_on_weapon_picked)
	schabow_gun.visible = false
	chrupiaca_gun.visible = false
	Global.is_melee = true
func _process(delta: float) -> void:
	melee(delta)
	if Global.weapon_count == 0:
		pass
	elif Global.weapon_count != 0:
		current_weapon = Global.arsenal[Global.weapon_index]
		if current_weapon == "schabowy":
			_schabowy_throw(delta)
			chrupiaca_gun.visible = false
		if current_weapon == "chrupiaca":
			_chrupiaca_throw(delta)
			schabow_gun.visible = false
func melee(delta):
	#tryb mele
	if Input.is_action_pressed("melee"):
		animation_player.play("melee_idle2")
		animation_player.advance(delta*0.1)
		Global.is_melee = true
	if  Global.is_melee == true:
		chrupiaca_gun.visible = false
		schabow_gun.visible = false
		patelnia.visible = true
		#atak
		if Input.is_action_just_pressed("shoot"):
			animation_player.play("melee_attack2")
			melee_can_hit = 1
		if animation_player.current_animation == "melee_attack2" and not animation_player.current_animation == "melee_block":
			for body in melee_hitbox.get_overlapping_bodies():
				if body.is_in_group("enemy") and animation_player.current_animation_position >= 0.8194 and animation_player.current_animation_position < 0.9698 and melee_can_hit == 1:
					var b = dmg_particle.instantiate()
					var p = hit_particle.instantiate()
					melee_can_hit = 0
					get_tree().get_root().add_child(b)
					get_tree().get_root().add_child(p)
					b.global_transform.origin = body.global_transform.origin
					p.global_transform.origin = body.global_transform.origin
					body.health -= Global.melee_dmg
		if Input.is_action_just_pressed("alt_shoot") and not animation_player.current_animation == "melee_block" and not animation_player.current_animation == "melee_attack2":
			animation_player.play("melee_block")
			melee_is_blocking = 1
		#if animation_player.current_animation == "melee_block":
			#for body in block_hitbox.get_overlaping_bodies(): 
				#if body.is_in_group("projectile") and animation_player.current_animation_position >= 0.2088:
					
		
	else:
		patelnia.visible = false
func _schabowy_throw(delta):
	if current_weapon == "schabowy":
		schabow_gun.visible = true
	else:
		schabow_gun.visible = false
	#zwykły strzał
	if Input.is_action_just_pressed("shoot") and throw_cooldown == 0 and not playing_reversed and not Global.is_melee:
		projectile = koklet.instantiate()
		animation_player.play("throw_schabowy")
		anim_speed = 1.0 
			
	if animation_player.current_animation == "throw_schabowy":
		animation_player.advance(delta * anim_speed)
		if animation_player.current_animation_position >= 0.28 and not playing_reversed:
			projectile.position = shooting_point.global_position
			projectile.transform.basis = shooting_point.global_transform.basis
			get_parent().get_parent().get_parent().add_child(projectile)
			throw_cooldown = 1
			schabow_gun.visible = false
	
func _chrupiaca_throw(delta):
	if current_weapon == "chrupiaca":
		chrupiaca_gun.visible = true
	else:
		chrupiaca_gun.visible = false
	#zwykły strzał
	if Input.is_action_pressed("shoot") and throw_cooldown == 0 and not playing_reversed and not Global.is_melee:
		var local_projectile = chrupiaca.instantiate()
		animation_player.play("throw_chrupiaca")
		anim_speed = 1
	if animation_player.current_animation == "throw_chrupiaca":
		animation_player.advance(delta * anim_speed)
		if animation_player.current_animation_position >= 0.4 and not playing_reversed:
			var final_projectile = chrupiaca.instantiate()
			final_projectile.position = shooting_point.global_position
			final_projectile.transform.basis = shooting_point.global_transform.basis
			get_parent().get_parent().get_parent().add_child(final_projectile)
			throw_cooldown = 1
			chrupiaca_gun.visible = false

func _on_animation_finished(anim_name):
	if anim_name == "throw_schabowy":
		if not playing_reversed:
			playing_reversed = true
			animation_player.play_backwards("throw_schabowy")
			throw_cooldown = 0
		else:
			playing_reversed = false
			schabow_gun.visible = false
			anim_speed = 1.0  
			schabow_gun.visible = false
			throw_cooldown = 0
	if anim_name == "throw_chrupiaca":
		if not playing_reversed:
			playing_reversed = true
			animation_player.play_backwards("throw_chrupiaca")
			throw_cooldown = 0
		else:
			playing_reversed = false
			anim_speed = 5
			throw_cooldown = 0
			chrupiaca_gun.visible = false
	if anim_name == "melee_attack2":
		hand.visible = true
		animation_player.play("melee_idle2")
	if anim_name == "melee_block":
		if not playing_reversed:
			playing_reversed = true
			animation_player.play_backwards("melee_block")
		else:
			playing_reversed = false
			anim_speed = 5

func _on_weapon_picked():
	if Global.arsenal[Global.weapon_index] == "schabowy":
		schabow_gun.visible == true
	else:
		schabow_gun.visible == false
	if Global.arsenal[Global.weapon_index] == "chrupiaca":
		chrupiaca_gun.visible == true
	else:
		chrupiaca_gun.visible == false
