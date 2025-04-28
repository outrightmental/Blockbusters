class_name Score
extends Node2D

# Constants
const COLOR_SV_RATIO: float = 0.6


# Player number to identify the home
@export var player_num: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.update_score.connect(_on_update_score)
	_set_color()


# Set the colors of the ship based on player_num
func _set_color() -> void:
	if player_num in Config.PLAYER_COLORS:
		$Text.set("theme_override_colors/default_color",Util.color_at_sv_ratio(Config.PLAYER_COLORS[player_num][0], COLOR_SV_RATIO))
	else:
		print("No colors found for player_num: ", player_num)
	pass

	
# Update the score for this player
func _on_update_score(score: Dictionary) -> void:
	if score.has(player_num):
		$Text.set_text(str(score[player_num]))
	else:
		print("No score found for player_num: ", player_num)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

	
