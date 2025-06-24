extends Node2D

# Player number to identify the laser beam
@export var player_num: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set the sprite texture based on player_num
	if player_num in Config.PLAYER_COLORS:
		$Line2D.default_color = Config.PLAYER_COLORS[player_num][0]
	else:
		print("No texture found for player_num: ", player_num)
