class_name Home
extends Node2D

# Constants
const COLOR_ALPHA_RATIO: float = 0.6


# Player number to identify the home
@export var player_num: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HomeArea2D.body_entered.connect(_on_body_entered)
	_set_colors()


# Called when another body enters the collission area
func _on_body_entered(body: Node2D) -> void:
	if body is Gem:
		Game.player_did_collect_gem.emit(player_num)
		Game.gems_collected += 1
		body.do_shatter()
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.PLAYER_COLLECTS_GEM)
	pass


# Set the colors of the ship based on player_num
func _set_colors() -> void:
	if player_num in Constant.PLAYER_COLORS:
		$CircleLight.material.set_shader_parameter("color", Util.color_at_alpha_ratio(Constant.PLAYER_COLORS[player_num][0], COLOR_ALPHA_RATIO))
	else:
		push_error("No colors found for player_num: ", player_num)
	pass
	

	
