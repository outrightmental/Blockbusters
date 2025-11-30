extends Node2D

# Player number to identify the projectile
@export var player_num: int = 0
# Message to display on the banner
@export var message: String
# Message to display on the banner after half time has passed
@export var message_2: String
# Amount of time to wait after starting the animation player before showing the banner and text
const hide_animation_reset_sec := 0.01


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Banner.hide()
	$Text.hide()
	# Set the banner color based on player_num
	if player_num > 0:
		if player_num in Constant.PLAYER_COLORS:
			$Banner.color = Constant.PLAYER_COLORS[player_num][0]
		else:
			push_error("No color found for player ", player_num)
	$Text.set_text(message)
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)
	$AnimationPlayer.speed_scale = 1.0 / Constant.TIME_SLOW_SCALE
	$AnimationPlayer.play("fly")
	# Show the banner and text after a short delay to sync with animation
	await Util.delay(hide_animation_reset_sec)
	$Banner.show()
	$Text.show()
	# Switch to second message halfway through the animation
	if message_2.length() > 0:
		await Util.delay(Constant.TIME_SLOW_SCALE * $AnimationPlayer.current_animation_length / 2)
		$Text.set_text(message_2)


# Called when the animation is finished
func _on_animation_finished(_anim_name: String) -> void:
	call_deferred("queue_free")
