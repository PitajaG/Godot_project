extends Node

var normal
var weapon_in_hand
var arsenal:Array = []
var weapon_count = 0
signal weapon_picked
var weapon_index = 0
#damage
func _ready() -> void:
	weapon_picked.connect(_on_weapon_picked)
var melee_dmg
var schab_dmg = 50
var chrupiaca_dmg = 20
var is_melee
func _process(_delta):
	_weapon_equiped()
func _weapon_equiped():
	if len(arsenal) == 0:
		return
	
	if Input.is_action_just_pressed("scroll_up") or Input.is_action_just_pressed("weapon2"):
		weapon_index += 1
		is_melee = false
	elif Input.is_action_just_pressed("scroll_down") or Input.is_action_just_pressed("weapon1"):
		weapon_index -= 1
		is_melee = false
	if weapon_index >= len(arsenal):
		weapon_index = 0
	elif weapon_index < 0:
		weapon_index = len(arsenal) - 1

func _on_weapon_picked():
	weapon_count += 1
	
