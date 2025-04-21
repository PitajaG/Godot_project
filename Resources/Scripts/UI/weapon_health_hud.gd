extends Control

@export var health_bar_source: Node

@onready var health_bar = $Panel/HealthBar

func _ready():
	health_bar.source = health_bar_source
	health_bar.start()
