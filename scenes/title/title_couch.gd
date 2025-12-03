extends Node2D

# Constants
const GAME_START_DELAY_SECONDS: float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.player_ready_updated.connect(_on_player_ready_updated)
	var menu_items: Array[Dictionary] = []
	menu_items.append({"label": "START", "action": Callable(self, "on_start")})
	menu_items.append({"label": "OPTIONS", "action": Callable(self, "on_options")})
	menu_items.append({"label": "EXIT", "action": Callable(self, "on_exit")})
	$MenuMain.configure(menu_items)


# If both players are ready, start the game
func _on_player_ready_updated() -> void:
	if $ReadyP1.is_ready and $ReadyP2.is_ready:
		await Util.delay(GAME_START_DELAY_SECONDS)
		if $ReadyP1.is_ready and $ReadyP2.is_ready:
			Util.goto_scene("res://scenes/game/play_game.tscn")


# Start the game
func on_start() -> void:
	Util.goto_scene("res://scenes/game/play_game.tscn")


# Show the options menu
func on_options() -> void:
	Util.goto_scene("res://scenes/options.gd")


# Exit the game
func on_exit() -> void:
	get_tree().quit()
	
