extends Node

# All available signals -- use these constants to reference them to avoid typos
signal reset_game()
signal score_updated(score: Dictionary)
signal player_did_launch_projectile(player_num: int)
signal player_did_collect_gem(player_num: int)
signal player_did_harm(player_num: int)
signal projectile_count_updated
signal player_ready_updated
signal player_laser_charge_updated(player_num: int, charge_sec: float)
# Group names
const BLOCK_GROUP: StringName = "BlockGroup"
const GEM_GROUP: StringName   = "GemGroup"
# Enum for whether Player 1 wins, Player 2 wins, or a draw
enum Result {
	PLAYER_1_WINS,
	PLAYER_2_WINS,
	DRAW,
}

# Keeping track of the score
@onready var score: Dictionary = {
									 1: 0,
									 2: 0,
								 }

# Keeping track of the gem count
@onready var gems_collected: int = 0
# Keeping track of the projectile count
@onready var projectiles_in_play: int = 0


# Check if the player can launch a projectile
func player_can_launch_projectile(player_num: int) -> bool:
	if score.has(player_num):
		return score[player_num] > 0
	else:
		push_error("No score found for player_num: ", player_num)
		return false


func _ready() -> void:
	reset_game.connect(_do_reset_game)
	player_did_launch_projectile.connect(_on_player_launch_projectile)
	player_did_collect_gem.connect(_on_player_collect_gem)
	player_did_harm.connect(_on_player_harm)
	projectile_count_updated.connect(_on_projectile_count_updated)
	player_ready_updated.connect(_on_player_ready_updated)
	player_laser_charge_updated.connect(_on_player_laser_charge_updated)


func _do_reset_game() -> void:
	gems_collected = 0
	score[1] = Config.PLAYER_SCORE_INITIAL
	score[2] = Config.PLAYER_SCORE_INITIAL
	print("[GAME] Resetting game score to: ", score)
	score_updated.emit()


func _on_player_launch_projectile(player_num: int) -> void:
	score[player_num] = clamp(score[player_num] - 1, 0, Config.PLAYER_SCORE_VICTORY)
	print("[GAME] Player %d launched projectile, new score: %d" % [player_num, score[player_num]])
	score_updated.emit()


func _on_player_collect_gem(player_num: int) -> void:
	score[player_num] = clamp(score[player_num] + Config.PLAYER_SCORE_COLLECT_GEM_VALUE, 0, Config.PLAYER_SCORE_VICTORY)
	print("[GAME] Player %d collected gem, new score: %d" % [player_num, score[player_num]])
	score_updated.emit()


func _on_player_harm(player_num: int) -> void:
	score[player_num] = clamp(score[player_num] - Config.PLAYER_SCORE_DISABLE_SHIP_VALUE, 0, Config.PLAYER_SCORE_VICTORY)
	print("[GAME] Player %d did harm, new score: %d" % [player_num, score[player_num]])
	score_updated.emit()


func _on_projectile_count_updated() -> void:
	print ("[PROJECTILES] in play: ", projectiles_in_play)


func _on_player_ready_updated() -> void:
	pass


func _on_player_laser_charge_updated(_player_num: int, _charge_sec: float ) -> void:
	pass
