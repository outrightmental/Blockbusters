class_name Ready
extends Node2D

# Constants
const READY_COLOR_SV_RATIO: float   = 1.0
const UNREADY_COLOR_SV_RATIO: float = 0.3
# Player number to identify the home
@export var player_num: int = 0
# When the player is ready
@export var is_ready: bool = false




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_player_name()
	_set_color()
	InputManager.action_pressed.connect(_on_input_action_pressed)
	

# Set the name of the player based on player_num
func _set_player_name() -> void:
	$PlayerNameText.set_text("Player " + str(player_num))
	pass


# Set the colors of the ship based on player_num
func _set_color() -> void:
	if player_num in Constant.PLAYER_COLORS:
		$PlayerNameText.set("theme_override_colors/default_color", Util.color_at_sv_ratio(Constant.PLAYER_COLORS[player_num][0], READY_COLOR_SV_RATIO if is_ready else UNREADY_COLOR_SV_RATIO))
	else:
		push_error("No colors found for player_num: ", player_num)
	pass

	
# Toggle readiness
func _toggle_ready() -> void:
	is_ready = !is_ready
	_set_color()
	if is_ready:
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.PLAYER_1_READY if player_num == 0 else SoundEffectSetting.SOUND_EFFECT_TYPE.PLAYER_2_READY)
		$PressStartText.hide()
	else:
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.PLAYER_UNREADY)
		$PressStartText.show()
	Game.player_ready_updated.emit()
	pass


func _on_input_action_pressed(player: int, action: String) -> void:
	if player != player_num:
		return  # Ignore input from other players
	if action == InputManager.INPUT_START:
		_toggle_ready()
