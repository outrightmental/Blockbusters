extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PlayGameButton.connect("pressed", _on_texture_button_pressed)

func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/play_game.tscn")
	
