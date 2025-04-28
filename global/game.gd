extends Node

# All available signals -- use these constants to reference them to avoid typos
signal reset_game
signal update_score(score: Dictionary)
signal player_did_launch_projectile(player_num: int)
signal player_did_collect_gem(player_num: int)
signal player_did_harm(player_num: int)

# Keeping track of the score
@onready var score: Dictionary = {
									 1: 0,
									 2: 0,
								 }


# Check if the player can launch a projectile
func player_can_launch_projectile(player_num: int) -> bool:
	if score.has(player_num):
		return score[player_num] > 1
	else:
		print("No score found for player_num: ", player_num)
		return false


func _ready() -> void:
	reset_game.connect(_do_reset_game)
	player_did_launch_projectile.connect(_on_player_launch_projectile)
	player_did_collect_gem.connect(_on_player_collect_gem)
	player_did_harm.connect(_on_player_harm)


func _do_reset_game() -> void:
	score[1] = Config.PLAYER_INITIAL_SCORE
	score[2] = Config.PLAYER_INITIAL_SCORE
	print("[GAME] Resetting game score to: ", score)
	_update()


func _on_player_launch_projectile(player_num: int) -> void:
	score[player_num] = clamp(score[player_num] - 1, 0, Config.PLAYER_VICTORY_SCORE)
	print("[GAME] Player %d launched projectile, new score: %d" % [player_num, score[player_num]])
	_update()


func _on_player_collect_gem(player_num: int) -> void:
	score[player_num] = clamp(score[player_num] + 2, 0, Config.PLAYER_VICTORY_SCORE)
	print("[GAME] Player %d collected gem, new score: %d" % [player_num, score[player_num]])
	_update()
	
	
func _on_player_harm(player_num: int) -> void:
	score[player_num] = clamp(score[player_num] - 3, 0, Config.PLAYER_VICTORY_SCORE)
	print("[GAME] Player %d did harm, new score: %d" % [player_num, score[player_num]])
	_update()


func _update():
	update_score.emit(score)
