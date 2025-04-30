extends Node2D

# Signal that never happens, in case the tree is unloaded
signal never

# Constants
const GAME_START_DELAY_SECONDS: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.player_ready_updated.connect(_on_player_ready_updated)
	pass

	
# If both players are ready, start the game
func _on_player_ready_updated() -> void:
	if $ReadyPlayer1.is_ready and $ReadyPlayer2.is_ready:
		# TODO here we should show an indication that both players are ready and the game will start if nobody unreadies
		await _delay(GAME_START_DELAY_SECONDS)
		if $ReadyPlayer1.is_ready and $ReadyPlayer2.is_ready:
			_goto_scene("res://scenes/play_game.tscn")


# Goto a scene, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _goto_scene(path: String) -> void:
	if get_tree():
		get_tree().change_scene_to_file(path)


# Delay, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _delay(seconds: float) -> Signal:
	if get_tree():
		return get_tree().create_timer(seconds).timeout
	else:
		return never
