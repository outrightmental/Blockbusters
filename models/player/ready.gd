class_name Ready
extends Node2D

# Constants
const READY_COLOR_SV_RATIO: float   = 1.0
const UNREADY_COLOR_SV_RATIO: float = 0.3
# Player number to identify the home
@export var player_num: int = 0
# When the player is ready
@export var is_ready: bool = false
# Input mapping
var input_mapping: Dictionary = {
									"action_a": "ui_accept",
								}



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_player_name()
	_set_color()
	# Set up input mapping for player
	for key in input_mapping.keys():
		var action_name: String = Config.player_input_mapping_format[key] % player_num
		if InputMap.has_action(action_name):
			input_mapping[key] = action_name
		else:
			print("Input action not found: ", action_name)


# Set the name of the player based on player_num
func _set_player_name() -> void:
	$Text.set_text("Player " + str(player_num))
	pass


# Set the colors of the ship based on player_num
func _set_color() -> void:
	if player_num in Config.PLAYER_COLORS:
		$Text.set("theme_override_colors/default_color", Util.color_at_sv_ratio(Config.PLAYER_COLORS[player_num][0], READY_COLOR_SV_RATIO if is_ready else UNREADY_COLOR_SV_RATIO))
	else:
		print("No colors found for player_num: ", player_num)
	pass

	
# Toggle readiness
func _toggle_ready() -> void:
	is_ready = !is_ready
	_set_color()
	Game.player_ready_updated.emit()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Check if input action is pressed
	if Input.is_action_just_pressed(input_mapping["action_a"]):
		_toggle_ready()

	
