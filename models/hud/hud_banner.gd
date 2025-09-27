extends Node2D

# Player number to identify the projectile
@export var player_num: int = 0

# Message to display on the banner
@export var message: String

# Message to display on the banner after half time has passed
@export var message_2: String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set the banner color based on player_num
	if player_num > 0:
		if player_num in Constant.PLAYER_COLORS:
			$Banner.color = Constant.PLAYER_COLORS[player_num][0]
		else:
			push_error("No color found for player ", player_num)
	$Text.set_text(message)
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)
	$AnimationPlayer.play("fly")
	if message_2.length() > 0:
		await Util.delay(2)
		$Text.set_text(message_2)
	

# Called when the animation is finished
func _on_animation_finished(anim_name: String) -> void:
	call_deferred("queue_free")
