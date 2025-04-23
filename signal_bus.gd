extends Node

# All available signals -- use these constants to reference them to avoid typos
signal reset_game
signal update_score(score: int)

# Keeping track of the score
@onready var score: float = 0

func _ready() -> void:
	reset_game.connect(_do_reset_game)


func _do_reset_game() -> void:
	score = 0
	_update()
	

func _update():
	update_score.emit(score)
