extends Node2D

# Constants
const GAME_START_DELAY_SECONDS: float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.player_ready_updated.connect(_on_player_ready_updated)


# If both players are ready, start the game
func _on_player_ready_updated() -> void:
	if $ReadyP1.is_ready and $ReadyP2.is_ready:
		await Util.delay(GAME_START_DELAY_SECONDS)
		if $ReadyP1.is_ready and $ReadyP2.is_ready:
			Util.goto_scene("res://scenes/game/game_board_screen.tscn")
		