class_name Score
extends Node2D

# Constants
const COLOR_SV_RATIO: float = 0.7


# Player number to identify the home
@export var player_num: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.score_updated.connect(_on_score_updated)
	_set_color()


# Set the colors of the ship based on player_num
func _set_color() -> void:
	if player_num in Constant.PLAYER_COLORS:
		$Text.set("theme_override_colors/default_color",Util.color_at_sv_ratio(Constant.PLAYER_COLORS[player_num][0], COLOR_SV_RATIO))
		$Underline.set("color",Util.color_at_sv_ratio(Constant.PLAYER_COLORS[player_num][0], COLOR_SV_RATIO))
	else:
		push_error("No colors found for player_num: ", player_num)
	pass

	
# Update the score for this player
func _on_score_updated() -> void:
	if Game.score.has(player_num):
		$Text.set_text(str(Game.score[player_num]))
	else:
		push_error("No score found for player_num: ", player_num)
	pass


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	pass

	
