class_name Goal
extends Node2D

# Constants
const COLOR_ALPHA_RATIO: float = 0.6
# Player number to identify the goal
@export var player_num: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$GoalArea2D.body_entered.connect(_on_body_entered)
	_set_colors()

	# Compensate for banner time scale in animation player
	$AnimationPlayer.speed_scale = 1.0 / Constant.BANNER_SHOW_TIME_SCALE
	
	# Disable lighting if not enabled in settings
	if not Game.is_lighting_enabled:
		$PointLight2D.enabled = false


# Called when another body enters the collission area
func _on_body_entered(body: Node2D) -> void:
	if body is Gem:
		body.do_shatter()
		Game.do_player_goal(player_num)
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.PLAYER_COLLECTS_GEM)
		$AnimationPlayer.play("Goal")


# Set the colors of the ship based on player_num
func _set_colors() -> void:
	if player_num in Constant.PLAYER_COLORS:
		$CircleLight.material.set_shader_parameter("color", Util.color_at_alpha_ratio(Constant.PLAYER_COLORS[player_num][0], COLOR_ALPHA_RATIO))
		$PointLight2D.color = Util.color_at_sv_ratio(Constant.PLAYER_COLORS[player_num][0], 1.0, 2.0)
	else:
		push_error("No colors found for player_num: ", player_num)
	

	
