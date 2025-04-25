extends Node

# All available signals -- use these constants to reference them to avoid typos
signal reset_game
signal update_score(score: Dictionary)
signal projectile_explosive_launched(player_num: int, projectile: Node)

# Keeping track of the score
@onready var score: Dictionary = {
	1: 0,
	2: 0,
								 }

func _ready() -> void:
	reset_game.connect(_do_reset_game)
	projectile_explosive_launched.connect(_on_projectile_explosive_launched)


func _do_reset_game() -> void:
	score[1] = Global.PLAYER_INITIAL_SCORE
	score[2] = Global.PLAYER_INITIAL_SCORE
	_update()
	
	
func _on_projectile_explosive_launched(player_num: int) -> void:
	score[player_num] -= 1
	_update()
	

func _update():
	update_score.emit(score)
