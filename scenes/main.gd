extends Node2D

# Constants
const GAME_START_DELAY_SECONDS: float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.player_ready_updated.connect(_on_player_ready_updated)
	if Game.is_table_mode():
		_goto_scene("res://scenes/main_table.tscn")
	$MenuMain.configure([
	$MenuMain.create_entry("START", Callable(self, "on_start")),
	$MenuMain.create_entry("OPTIONS", Callable(self, "on_options")),
	$MenuMain.create_entry("EXIT", Callable(self, "on_exit")),
	])


# If both players are ready, start the game
func _on_player_ready_updated() -> void:
	if $ReadyP1.is_ready and $ReadyP2.is_ready:
		await Util.delay(GAME_START_DELAY_SECONDS)
		if $ReadyP1.is_ready and $ReadyP2.is_ready:
			_goto_scene("res://scenes/play_game.tscn")


# Goto a scene, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _goto_scene(path: String) -> void:
	if get_tree():
		get_tree().change_scene_to_file(path)


# Start the game
func on_start() -> void:
	_goto_scene("res://scenes/play_game.tscn")


# Show the options menu
func on_options() -> void:
	_goto_scene("res://scenes/options.gd")


# Exit the game
func on_exit() -> void:
	get_tree().quit()
	
