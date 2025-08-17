extends Node2D

# Constants
const GAME_START_DELAY_SECONDS: float = 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.player_ready_updated.connect(_on_player_ready_updated)
	_setup()
	InputManager.input_mode_updated.connect(_setup)


# If both players are ready, start the game
func _on_player_ready_updated() -> void:
	if $ReadyP1.is_ready and $ReadyP2.is_ready:
		await Util.delay(GAME_START_DELAY_SECONDS)
		if $ReadyP1.is_ready and $ReadyP2.is_ready:
			_goto_scene("res://scenes/play_game.tscn")


# Setup the UI based on the current input mode		
func _setup() -> void:
	match InputManager.mode:
		InputManager.Mode.TABLE:
			$TableMode.show()
			$CouchMode.hide()
			$ReadyP1.transform = Transform2D(PI/2, Vector2(122, 291))
			$ReadyP2.transform = Transform2D(-PI/2, Vector2(906, 288))
		InputManager.Mode.COUCH:
			$TableMode.hide()
			$CouchMode.show()
			$ReadyP1.transform = Transform2D(0, Vector2(250, 450))
			$ReadyP2.transform = Transform2D(0, Vector2(776, 450))


# Goto a scene, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func _goto_scene(path: String) -> void:
	if get_tree():
		get_tree().change_scene_to_file(path)
