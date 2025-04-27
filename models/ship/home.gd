class_name Home
extends Node2D


# Player number to identify the home
@export var player_num: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set the sprite texture based on player_num
	_set_colors()
	pass


# Set the colors of the ship based on player_num
func _set_colors() -> void:
#	if player_num in Global.PLAYER_COLORS:
#		$CircleLight.ma = Global.color_at_saturation_ratio(Global.PLAYER_COLORS[player_num][0], saturation_ratio)
#		$CircleDark.color = Global.color_at_saturation_ratio(Global.PLAYER_COLORS[player_num][1], saturation_ratio)
#	else:
#		print("No colors found for player_num: ", player_num)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

	
