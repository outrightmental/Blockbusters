extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	match Game.mode:
		Game.Mode.TABLE:
			Util.goto_scene("res://scenes/title/title_table_dual_container.tscn")
		Game.Mode.COUCH:
			Util.goto_scene("res://scenes/title/title_screen.tscn")
