extends Menu

# Initialize the menu with items
func _ready() -> void:
	_register_menu_item( $VBoxContainer/ItemStart, Callable(self, "_on_start"))
	_register_menu_item( $VBoxContainer/ItemOptions, Callable(self, "_on_options"))
	_register_menu_item( $VBoxContainer/ItemExit, Callable(self, "_on_exit"))
	super._ready()


# Start the game
func _on_start() -> void:
	_goto_scene("res://scenes/play_game.tscn")


# Show the options menu
func _on_options() -> void:
	_goto_scene("res://scenes/options.gd")


# Exit the game
func _on_exit() -> void:
	get_tree().quit()
