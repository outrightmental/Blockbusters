class_name Ship
extends Collidable

const FORCE_AMOUNT: int             = 500
const LINEAR_DAMP: float            = 0.9
const TARGET_ROTATION_FACTOR: float = 10
const DISABLED_MSEC: int            = 3000
const DISABLED_SV_RATIO: float      = 0.38

var input_mapping: Dictionary = {
									"left": "ui_left",
									"right": "ui_right",
									"up": "ui_up",
									"down": "ui_down",
									"action_a": "ui_accept",
								}

const dir_vectors := {
						 "right": Vector2(1, 0),
						 "left": Vector2(-1, 0),
						 "up": Vector2(0, -1),
						 "down": Vector2(0, 1),
					 }
# keep track of the time when the input direction was pressed
var input_direction_start_ticks_msec: float = 0.0
# whether the input direction is pressed
var input_direction_pressed: bool = false
# fixed actual angle moves towards target angle -- used for strafe/accelerate mechanic
var target_rotation: float = 0.0
var actual_rotation: float = 0.0
# keep track of the time when the projectile explosive was last launched
var projectile_explosive_start_ticks_msec: float = 0.0
# keep track of whether the ship is disabled, and when
var is_disabled: bool             = false
var disabled_at_ticks_msec: float = 0.0

# Preload the projectile explosive scene
const projectile_explosive_scene: PackedScene = preload("res://models/player/projectile_explosive.tscn")

# Player number to identify the ship
@export var player_num: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_linear_damp(LINEAR_DAMP)
	# Set up input mapping for player
	for key in input_mapping.keys():
		var action_name: String = Config.player_input_mapping_format[key] % player_num
		if InputMap.has_action(action_name):
			input_mapping[key] = action_name
		else:
			print("Input action not found: ", action_name)

	# Set the sprite texture based on player_num
	_set_colors(1.0)

	actual_rotation = rotation
	target_rotation = rotation
	pass


# Set the colors of the ship based on player_num
func _set_colors(sv_ratio: float) -> void:
	if player_num in Config.PLAYER_COLORS:
		$TriangleLight.color = Util.color_at_sv_ratio(Config.PLAYER_COLORS[player_num][0], sv_ratio)
		$TriangleDark.color = Util.color_at_sv_ratio(Config.PLAYER_COLORS[player_num][1], sv_ratio)
	else:
		print("No colors found for player_num: ", player_num)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_disabled:
		if Time.get_ticks_msec() - disabled_at_ticks_msec > DISABLED_MSEC:
			do_enable()
	else:
		_process_input(delta)

	# Adjust the rotation towards the target angle by a factor and delta time
	var angle_diff: float = fmod(target_rotation - actual_rotation, TAU)
	if angle_diff > PI:
		angle_diff -= TAU
	elif angle_diff < -PI:
		angle_diff += TAU
	actual_rotation += angle_diff * TARGET_ROTATION_FACTOR * delta
	rotation = actual_rotation
	pass


# Process input for the ship (if not disabled)
func _process_input(delta: float) -> void:
	# Check if input action is pressed
	if Input.is_action_just_pressed(input_mapping["action_a"]):
		_do_launch_projectile_explosive()

	# Get input vector from which keys are pressed
	var input_vector: Vector2 = Vector2.ZERO
	for key in dir_vectors.keys():
		if Input.is_action_pressed(input_mapping[key]):
			input_vector += dir_vectors[key]

	# Normalize the input vector to avoid faster diagonal movement
	if input_vector.length() > 1:
		input_vector = input_vector.normalized()

	# Reset input pressed state if no keys are pressed		
	if input_vector == Vector2.ZERO:
		input_direction_pressed = false
	else:
		# If the input vector is not zero, set the pressed state and start time
		if not input_direction_pressed:
			input_direction_pressed = true
			input_direction_start_ticks_msec = Time.get_ticks_msec()

		if Time.get_ticks_msec() - input_direction_start_ticks_msec < Config.PLAYER_SHIP_STRAFE_THRESHOLD_MSEC:
			# The time elapsed is less than the strafe threshold, so we turn without applying force
			target_rotation = input_vector.angle()
		else:
			target_rotation = linear_velocity.angle()

	# Apply force in the direction of the input vector
	apply_impulse(input_vector * FORCE_AMOUNT * delta)
	pass


# Called when the ship is disabled
func do_disable(responsible_player_num: int) -> void:
	is_disabled = true
	disabled_at_ticks_msec = Time.get_ticks_msec()
	_set_colors(DISABLED_SV_RATIO)
	Game.player_did_harm.emit(responsible_player_num)
	pass


# Called when the ship is re-enabled
func do_enable() -> void:
	is_disabled = false
	disabled_at_ticks_msec = 0.0
	_set_colors(1.0)
	pass


# Called when the player wants to launch a projectile explosive
func _do_launch_projectile_explosive() -> void:
	if Time.get_ticks_msec() - projectile_explosive_start_ticks_msec < Config.PLAYER_SHIP_PROJECTILE_EXPLOSIVE_COOLDOWN_MSEC:
		return
	if not Game.player_can_launch_projectile(player_num):
		return
	projectile_explosive_start_ticks_msec = Time.get_ticks_msec()
	var rotation_vector: Vector2 = Vector2(cos(actual_rotation), sin(actual_rotation))
	var projectile: Node         = projectile_explosive_scene.instantiate()
	projectile.call_deferred("set_owner", self)
	projectile.add_collision_exception_with(self)
	projectile.position = position
	projectile.rotation = actual_rotation
	projectile.linear_velocity = linear_velocity + rotation_vector * Config.PLAYER_SHIP_PROJECTILE_EXPLOSIVE_INITIAL_VELOCITY
	projectile.player_num = player_num
	self.get_parent().call_deferred("add_child", projectile)
	# Emit a signal to notify that the projectile explosive was launched
	Game.player_did_launch_projectile.emit(player_num)


# Called when the ship is instantiated
func _init():
	super._init()

	
