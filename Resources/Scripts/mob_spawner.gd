extends Node3D

var exist = false
@onready var mob = preload("res://scenes/Mobs/mob.tscn")
@onready var spawn_timer = $Timer

func _on_timer_timeout() -> void:
	if exist == false:
		var enemy = mob.instantiate()
		get_parent().add_child(enemy)
		enemy.global_position = global_position
		exist = true
	else:
		pass
