class_name Ship
extends Collidable

var input_mapping: Dictionary = {
									"left": "ui_left",
									"right": "ui_right",
									"up": "ui_up",
									"down": "ui_down",
									"action_a": "ui_accept",
									"action_b": "ui_cancel",
								}

const dir_vectors := {
						 "right": Vector2(1, 0),
						 "left": Vector2(-1, 0),
						 "up": Vector2(0, -1),
						 "down": Vector2(0, 1),
					 }
enum ShipMovementState {
	ACCELERATE,
	DRIFT,
	NONE,
}
# keep track of the time when the input direction was pressed
var input_direction_start_ticks_msec: float = 0.0
# whether the input direction is pressed
var input_direction_pressed: bool = false
# keep track of ship movement state and associated sounds
var movement_state: ShipMovementState = ShipMovementState.NONE

@onready var movement_audio_key: String = "movement_%d" % player_num

# fixed actual angle moves towards target angle -- used for strafe/accelerate mechanic
var target_rotation: float = 0.0
var actual_rotation: float = 0.0
# keep track of the time when the projectile explosive was last launched
var projectile_explosive_start_ticks_msec: float = 0.0
# keep track of whether the ship is disabled, and when
var is_disabled: bool                = false
var disabled_until_ticks_msec: float = 0.0
# variables for laser tool
var laser: LaserBeam        = null
var laser_charge_sec: float = Config.PLAYER_SHIP_LASER_CHARGE_MAX_SEC

@onready var laser_audio_key: String = "laser_%d" % player_num

# variable for being heated
var heated_sec: float   = 0.0
var heated_delta: float = 0.0
# Preload the projectile explosive scene
const projectile_explosive_scene: PackedScene = preload("res://models/explosive/projectile_explosive.tscn")
# Preload the laser beam scene
const laser_scene: PackedScene = preload("res://models/player/laser_beam.tscn")
# Cache reference to heated effect
@onready var heated_effect: Node2D = $HeatedEffect

# Player number to identify the ship
@export var player_num: int = 0

# Ship has force field to "Hold" objects #21
@onready var forcefield_area: Area2D = $ForcefieldArea

var forcefield_targets: Dictionary[int, Node2D] = {}

# Called when the ship is disabled
func do_disable(responsible_player_num: int) -> void:
	is_disabled = true
	disabled_until_ticks_msec = Time.get_ticks_msec() + Config.PLAYER_SHIP_DISABLED_SEC * 1000.0
	_set_colors(Config.PLAYER_SHIP_DISABLED_S_RATIO, Config.PLAYER_SHIP_DISABLED_V_RATIO)
	Game.player_did_harm.emit(responsible_player_num)


# Called when the ship is re-enabled
func do_enable() -> void:
	is_disabled = false
	disabled_until_ticks_msec = 0.0
	_set_colors(1.0)


# Apply heat if not disabled
func apply_heat(delta: float) -> void:
	if is_disabled:
		return
	heated_delta += delta


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_linear_damp(Config.PLAYER_SHIP_LINEAR_DAMP)
	# Set up input mapping for player
	for key in input_mapping.keys():
		var action_name: String = Config.player_input_mapping_format[key] % player_num
		if InputMap.has_action(action_name):
			input_mapping[key] = action_name
		else:
			push_error("Input action not found: ", action_name)

	# Set the sprite texture based on player_num
	_set_colors(1.0)

	# Initialize the rotation
	actual_rotation = rotation
	target_rotation = rotation

	# Update the laser charge indicator
	Game.player_laser_charge_updated.emit(player_num, laser_charge_sec)

	# Connect the forcefield body entered signal
	forcefield_area.body_entered.connect(_on_body_entered)
	forcefield_area.body_exited.connect(_on_body_exited)
	# Set the forcefield color based on player_num
	if player_num in Config.PLAYER_COLORS:
		$ForcefieldEffect.color = Config.PLAYER_COLORS[player_num][0]
	else:
		push_error("No color found for player ", player_num)
	$ForcefieldEffect.set_emitting(false)

	# Update the heated effect visibility
	_update_heated_effect()


# Set the colors of the ship based on player_num
func _set_colors(s_ratio: float, v_ratio: float = 0) -> void:
	if player_num in Config.PLAYER_COLORS:
		$TriangleLight.color = Util.color_at_sv_ratio(Config.PLAYER_COLORS[player_num][0], s_ratio, v_ratio)
		$TriangleDark.color = Util.color_at_sv_ratio(Config.PLAYER_COLORS[player_num][1], s_ratio, v_ratio)
	else:
		push_error("No colors found for player_num: ", player_num)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_disabled:
		if Time.get_ticks_msec() > disabled_until_ticks_msec:
			do_enable()
	else:
		_input_process(delta)

	# Adjust the rotation towards the target angle by a factor and delta time
	var angle_diff: float = fmod(target_rotation - actual_rotation, TAU)
	if angle_diff > PI:
		angle_diff -= TAU
	elif angle_diff < -PI:
		angle_diff += TAU
	actual_rotation += angle_diff * Config.PLAYER_SHIP_TARGET_ROTATION_FACTOR * delta
	rotation = actual_rotation

	# Update the laser charge
	_update_laser(delta)

	# Update the heated state
	_update_heat(delta)

	# Apply forcefield forces
	_update_forcefield(delta)

	# Update the movement state audio
	_update_movement_audio_position()


# Process input for the ship (if not disabled)
func _input_process(delta: float) -> void:
	# Check if input action is pressed
	if Input.is_action_just_pressed(input_mapping["action_a"]):
		_do_activate_laser()
	if Input.is_action_just_released(input_mapping["action_a"]):
		_do_deactivate_laser()
	if Input.is_action_just_pressed(input_mapping["action_b"]):
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
		_update_movement_state(ShipMovementState.NONE)
	else:
		# If the input vector is not zero, set the pressed state and start time
		if not input_direction_pressed:
			input_direction_pressed = true
			input_direction_start_ticks_msec = Time.get_ticks_msec()

		if Time.get_ticks_msec() - input_direction_start_ticks_msec < Config.PLAYER_SHIP_STRAFE_THRESHOLD_MSEC:
			# The time elapsed is less than the strafe threshold, so we turn without applying force
			target_rotation = input_vector.angle()
			_update_movement_state(ShipMovementState.DRIFT)
		else:
			target_rotation = linear_velocity.angle()
			_update_movement_state(ShipMovementState.ACCELERATE)

	# Apply force in the direction of the input vector
	apply_impulse(input_vector * Config.PLAYER_SHIP_FORCE_AMOUNT * delta)


# Called when the player wants to activate the primary tool
func _do_activate_laser() -> void:
	if laser_charge_sec < Config.PLAYER_SHIP_LASER_AVAILABLE_MIN_CHARGE_SEC:
		return
	if laser:
		return
	laser         = laser_scene.instantiate()
	laser.player_num = player_num
	laser.source_ship = self
	self.get_parent().call_deferred("add_child", laser)
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.LASER_ACTIVATE, laser_audio_key)


func _do_deactivate_laser() -> void:
	if laser:
		laser.call_deferred("queue_free")
		laser = null
		Game.player_laser_charge_updated.emit(player_num, laser_charge_sec)
		AudioManager.stop_2d_audio(laser_audio_key)


# Called when the player wants to activate the secondary tool
func _do_launch_projectile_explosive() -> void:
	if Time.get_ticks_msec() - projectile_explosive_start_ticks_msec < Config.PROJECTILE_EXPLOSIVE_COOLDOWN_MSEC:
		return
	if not Game.player_can_launch_projectile(player_num):
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.PROJECTILE_FAIL)
		return
	projectile_explosive_start_ticks_msec = Time.get_ticks_msec()
	var rotation_vector: Vector2 = Vector2(cos(actual_rotation), sin(actual_rotation))
	var projectile: Node         = projectile_explosive_scene.instantiate()
	projectile.add_collision_exception_with(self)
	projectile.position = position
	projectile.rotation = actual_rotation
	projectile.linear_velocity = linear_velocity + rotation_vector * Config.PROJECTILE_EXPLOSIVE_INITIAL_VELOCITY
	projectile.player_num = player_num
	self.get_parent().call_deferred("add_child", projectile)
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.PROJECTILE_FIRE)
	# Emit a signal to notify that the projectile explosive was launched
	Game.player_did_launch_projectile.emit(player_num)


func _update_laser(delta: float) -> void:
	# If the laser is active, decrease the charge
	if laser:
		laser.set_position(position)
		laser.set_rotation(actual_rotation)
		laser_charge_sec -= delta
		AudioManager.update_2d_audio_global_position(laser_audio_key, global_position)
		if laser_charge_sec < 0:
			laser_charge_sec = 0
			_do_deactivate_laser()
		Game.player_laser_charge_updated.emit(player_num, laser_charge_sec)
	elif laser_charge_sec < Config.PLAYER_SHIP_LASER_CHARGE_MAX_SEC and not is_disabled:
		# If the laser is not active, recharge it
		laser_charge_sec += delta * Config.PLAYER_SHIP_LASER_RECHARGE_RATE
		if laser_charge_sec > Config.PLAYER_SHIP_LASER_CHARGE_MAX_SEC:
			laser_charge_sec = Config.PLAYER_SHIP_LASER_CHARGE_MAX_SEC
		Game.player_laser_charge_updated.emit(player_num, laser_charge_sec)


# If the ship is heated, increase the heated time, otherwise decrease it
# If the ship is heated for too long, disable it
func _update_heat(delta: float) -> void:
	if heated_delta > 0:
		heated_sec += heated_delta
		heated_delta = 0.0
		_update_heated_effect()
		if heated_sec >= Config.PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC:
			do_disable(player_num)
	elif heated_sec > 0:
		heated_sec -= delta
		if heated_sec < 0:
			heated_sec = 0.0
		_update_heated_effect()


# Apply forces to the bodies in the forcefield
func _update_forcefield(_delta: float) -> void:
	var forcefield_target_mass: float = 0
	if not is_disabled:
		for key in forcefield_targets.keys():
			var body: Node2D = forcefield_targets[key]
			# if body is not in the scene tree, remove it from the forcefield_targets list
			if not body or not body.is_inside_tree():
				forcefield_targets.erase(key)
				continue
			# get the direction vector from the body to the center of forcefield
			var direction: Vector2 = (forcefield_area.global_position - body.global_position).normalized()
			# apply a force on the body towards the center of forcefield
			body.apply_central_force(direction * Config.PLAYER_SHIP_FORCEFIELD_FORCE * _delta)
			# accumulate the mass of the bodies in the forcefield
			if body is RigidBody2D:
				forcefield_target_mass += body.mass
	# Update the forcefield effect based on the mass of the ship
	if forcefield_target_mass > 0:
		var forcefield_amount = clamp(forcefield_target_mass / Config.PLAYER_SHIP_FORCEFIELD_EFFECT_KG_MAX, 0.0, 1.0)
		$ForcefieldEffect.scale_amount_min = forcefield_amount * Config.PLAYER_SHIP_FORCEFIELD_EFFECT_SCALE_MIN
		$ForcefieldEffect.scale_amount_max = forcefield_amount * Config.PLAYER_SHIP_FORCEFIELD_EFFECT_SCALE_MAX
		$ForcefieldEffect.gravity = -Config.PLAYER_SHIP_FORCEFIELD_EFFECT_GRAVITY * Vector2(cos(rotation), sin(rotation))
		$ForcefieldEffect.set_emitting(true)
	else:
		$ForcefieldEffect.set_emitting(false)


# Update the heated effect visibility and intensity
func _update_heated_effect() -> void:
	if heated_sec > 0:
		heated_effect.set_visible(true)
		heated_effect.modulate.a = clamp(heated_sec / Config.PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC, 0.0, 1.0)
	else:
		heated_effect.set_visible(false)


func _update_movement_state(_state: ShipMovementState) -> void:
	#	if movement_state == state:
	#		return
	#	movement_state = state
	#	AudioManager.stop_2d_audio(movement_audio_key)
	#	if state == ShipMovementState.ACCELERATE:
	#		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.SHIP_ACCELERATES_1 if player_num == 1 else SoundEffectSetting.SOUND_EFFECT_TYPE.SHIP_ACCELERATES_2, movement_audio_key)
	#	elif state == ShipMovementState.DRIFT:
	#		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.SHIP_DRIFTS_1 if player_num == 1 else SoundEffectSetting.SOUND_EFFECT_TYPE.SHIP_DRIFTS_2, movement_audio_key)
	#	else:
	#		return
	#	_update_movement_audio_position()
	pass


func _update_movement_audio_position() -> void:
	#	if movement_sound == null:
	#		return
	#	movement_sound.set_global_position(global_position)
	pass


# Called when another body enters the forcefield area
func _on_body_entered(body: Node2D) -> void:
	if body == self:
		return  # Ignore self
	if body is Collidable:
		if body is Block and body.freeze:
			return
		if forcefield_targets.has(body.number):
			return
		forcefield_targets.set(body.number, body)


# Called when another body exits the forcefield area
func _on_body_exited(body: Node2D) -> void:
	if body is Collidable and body.number in forcefield_targets:
		forcefield_targets.erase(body.number)


# Called when the ship is instantiated
func _init():
	super._init()

	
