class_name Goal
extends Node2D

# Constants
const COLOR_ALPHA_RATIO: float = 0.6
# Player number to identify the goal
@export var player_num: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_set_colors()

	# Connect the Collision to the on-collision function
	$GoalArea2D.body_entered.connect(_on_body_entered)

	# Victory jumbotron is palpably victorious #193
	Game.outcome.connect(_on_game_outcome)
	Game.player_goal.connect(_on_player_goal)

	# Compensate for banner time scale in animation player
	$AnimationPlayer.speed_scale = 1.0 / Constant.TIME_SLOW_SCALE

	# Disable lighting if not enabled in settings
	if not ConfigManager.is_lighting_fx_enabled:
		$PointLight2D.enabled = false


# Called when another body enters the collission area
func _on_body_entered(body: Node2D) -> void:
	if body is Gem:
		body.do_shatter()
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.PLAYER_COLLECTS_GEM)
		Game.do_player_goal(player_num)


# Called when a player scores a goal
func _on_player_goal(scoring_player_num: int) -> void:
	if scoring_player_num == player_num:
		$AnimationPlayer.play("Goal")


# Called on game outcome
func _on_game_outcome(result: Game.Result) -> void:
	match result:
		Game.Result.PLAYER_1_WINS:
			if player_num == 1:
				_do_victory()
			else:
				_do_defeat()
		Game.Result.PLAYER_2_WINS:
			if player_num == 2:
				_do_victory()
			else:
				_do_defeat()
		_:
			_do_defeat()


# Victory jumbotron is palpably victorious #193
func _do_victory() -> void:
	$ParticleEmitter.emitting = true
	$AnimationPlayer.play("Victory")


# Defeat (anti-Victory) jumbotron is palpably victorious #193
func _do_defeat() -> void:
	$AnimationPlayer.play("Defeat")


# Set the colors of the ship based on player_num
func _set_colors() -> void:
	if player_num in Constant.PLAYER_COLORS:
		$CircleLight.material.set_shader_parameter("color", Util.color_at_alpha_ratio(Constant.PLAYER_COLORS[player_num][0], COLOR_ALPHA_RATIO))
		$PointLight2D.color = Util.color_at_sv_ratio(Constant.PLAYER_COLORS[player_num][0], 1.0, 2.0)
		$ParticleEmitter.color = Constant.PLAYER_COLORS[player_num][0]
	else:
		push_error("No colors found for player_num: ", player_num)
	

	
