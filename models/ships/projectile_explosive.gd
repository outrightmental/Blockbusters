extends "res://models/collidable/collidable.gd"

const FORCE_AMOUNT: int             = 500
const LINEAR_DAMP: int              = 1
const TARGET_ROTATION_FACTOR: float = 10
var screen_size: Vector2


# keep track of the time when the input was pressed
var input_start_ticks_msec: float = 0.0
# whether the input is pressed
var input_pressed: bool = false
# threshold that's rotation only (strafe) before applying force
const STRAFE_THRESHOLD_MSEC: float = 500
# fixed actual angle moves towards target angle -- used for strafe/accelerate mechanic
var target_rotation: float = 0.0
var actual_rotation: float = 0.0


# Player number to identify the ship
@export var player_num: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_linear_damp(LINEAR_DAMP)
	get_tree().root.size_changed.connect(_on_viewport_resize)
	_on_viewport_resize()

	# Set the sprite texture based on player_num
	if player_num in Global.PLAYER_COLORS:
		$TriangleLight.color = Global.PLAYER_COLORS[player_num][0]
		$TriangleDark.color = Global.PLAYER_COLORS[player_num][1]
	else:
		print("No texture found for player_num: ", player_num)

	actual_rotation = rotation
	target_rotation = rotation
	pass


func _on_viewport_resize() -> void:
	screen_size = get_viewport_rect().size
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# Called when the ship is instantiated
func _init():
	super._init()
