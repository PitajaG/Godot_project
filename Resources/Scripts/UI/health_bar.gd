extends Control

@export var source: Node

@onready var progress_bar = $TextureProgressBar
@onready var label = $Label


func start():
	if source:
		progress_bar.max_value = source.max_health
		progress_bar.min_value = source.min_health
		progress_bar.value = source.health
		label.text = str(clamp(source.health, source.min_health, source.max_health))
		
		source.health_change.connect(on_health_change)
	else:
		print("No source for healthbar")
		
func on_health_change(health, min_health, max_health):
	progress_bar.max_value = max_health
	progress_bar.min_value = min_health
	progress_bar.value = health
	label.text = str(clamp(health, min_health, max_health))
