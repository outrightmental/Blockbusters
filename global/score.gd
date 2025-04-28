extends Node

# Keeping track of the score
@onready var score: Dictionary = {
									 1: 0,
									 2: 0,
								 }


func _ready() -> void:
	SignalBus.reset_game.connect(_do_reset_game)
	SignalBus.projectile_explosive_launched.connect(_on_projectile_explosive_launched)


func _do_reset_game() -> void:
	score[1] = Config.PLAYER_INITIAL_SCORE
	score[2] = Config.PLAYER_INITIAL_SCORE
	_update()


func _on_projectile_explosive_launched(player_num: int) -> void:
	score[player_num] -= 1
	_update()


func _update():
	SignalBus.update_score.emit(score)
