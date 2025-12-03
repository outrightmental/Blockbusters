class_name Ship
extends Heatable

# Keep track of the movement direction
var movement_dir: Vector2 = Vector2.ZERO
# fixed actual angle moves towards target angle -- used for strafe/accelerate mechanic
var target_rotation: float = 0.0
var actual_rotation: float = 0.0
# keep track of the time when the projectile explosive was last launched
var projectile_explosive_cooldown_sec: float = 0.0
# keep track of whether the ship is disabled, and when
var is_disabled: bool       = false
var disabled_for_sec: float = 0.0
# variables for laser tool
var laser: LaserBeamCluster = null
var laser_charge_sec: float = Constant.PLAYER_SHIP_LASER_CHARGE_MAX_SEC

@onready var laser_audio_key: String = "laser_%d" % player_num
# Cache reference to heated effect
@onready var heated_effect: Node2D = $HeatedEffect

# Player number to identify the ship
@export var player_num: int = 0

# Ship has force field to "Hold" objects #21
@onready var forcefield_area: Area2D = $ForcefieldArea

var forcefield_targets: Dictionary[int, Node2D] = {}

# Keep track of the previous forcefield direction
# in order to "hold" objects while the forcefield is turning
var forcefield_position_previous: Vector2 = Vector2.ZERO


# Called when the ship is disabled
func do_disable() -> void:
	if Game.is_lighting_fx_enabled:
		$PointLight2D.enabled = false
	is_disabled = true
	heatable = false
	heat = 0.0
	disabled_for_sec = Constant.PLAYER_SHIP_DISABLED_SEC
	_set_colors(Constant.PLAYER_SHIP_DISABLED_S_RATIO, Constant.PLAYER_SHIP_DISABLED_V_RATIO)
	_do_deactivate_laser()
	Game.player_enabled.emit(player_num, false)
	# Play sound effect
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.SHIP_DISABLED)


# Called when the ship is re-enabled
func do_enable() -> void:
	if Game.is_lighting_fx_enabled:
		$PointLight2D.enabled = true
	is_disabled = false
	heatable = true
	laser_charge_sec = Constant.PLAYER_SHIP_LASER_CHARGE_MAX_SEC
	disabled_for_sec = 0.0
	_set_colors(1.0)
	Game.player_enabled.emit(player_num, true)
	# Play sound effect
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.SHIP_REENABLED)


# Get the heated ratio (0.0 to 1.0)
func get_heated_ratio() -> float:
	return clamp(heat / Constant.PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC, 0.0, 1.0)


# Aim the ship at a specific position
func aim_at_position(target_position: Vector2) -> void:
	var direction: Vector2 = (target_position - global_position).normalized()
	target_rotation = direction.angle()
	
# Whether the laser is currently active
func is_laser_active() -> bool:
	return laser != null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	set_linear_damp(Constant.PLAYER_SHIP_LINEAR_DAMP)

	# Set the sprite texture based on player_num
	_set_colors(1.0)

	# Initialize the rotation
	actual_rotation = rotation
	target_rotation = rotation

	# When the ship collides with another body
	self.body_entered.connect(_on_collision)

	# Connect the forcefield body entered signal
	forcefield_area.body_entered.connect(_on_forcefield_entered)
	forcefield_area.body_exited.connect(_on_forcefield_exited)
	# Set the forcefield color based on player_num
	if player_num in Constant.PLAYER_COLORS:
		$ForcefieldEffect.color = Constant.PLAYER_COLORS[player_num][0]
	else:
		push_error("No color found for player ", player_num)
	$ForcefieldEffect.set_emitting(false)

	# Update the heated effect visibility
	_update_heated_effect()

	# Update the HUD energy display
	_update_hud_energy()

	# Connect to input signals
	InputManager.action_pressed.connect(_on_input_action_pressed)
	InputManager.action_released.connect(_on_input_action_released)

	# Laser should stop if in use when banner is shown #198
	Game.show_banner.connect(func(_p: int, _m1: String, _m2: String): _do_deactivate_laser())

	# Victory jumbotron is palpably victorious #193
	Game.outcome.connect(_on_game_outcome)

	# Disable lighting if not enabled in settings
	if not Game.is_lighting_fx_enabled:
		$PointLight2D.enabled = false


# Set the colors of the ship based on player_num
func _set_colors(s_ratio: float, v_ratio: float = 0) -> void:
	if player_num in Constant.PLAYER_COLORS:
		$TriangleLight.color = Util.color_at_sv_ratio(Constant.PLAYER_COLORS[player_num][0], s_ratio, v_ratio)
		$TriangleDark.color = Util.color_at_sv_ratio(Constant.PLAYER_COLORS[player_num][1], s_ratio, v_ratio)
		$PointLight2D.color = Constant.PLAYER_COLORS[player_num][0]
	else:
		push_error("No colors found for player_num: ", player_num)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)

	if projectile_explosive_cooldown_sec > 0:
		projectile_explosive_cooldown_sec -= delta

	if is_disabled:
		disabled_for_sec -= delta
		if disabled_for_sec <= 0:
			do_enable()

	# Adjust the rotation towards the target angle by a factor and delta time
	var angle_diff: float = fmod(target_rotation - actual_rotation, TAU)
	if angle_diff > PI:
		angle_diff -= TAU
	elif angle_diff < -PI:
		angle_diff += TAU
	actual_rotation += angle_diff * Constant.PLAYER_SHIP_TARGET_ROTATION_FACTOR * delta
	rotation = actual_rotation

	# Update movement based on input
	_update_movement(delta)

	# Update the laser charge
	_update_laser(delta)

	# Apply forcefield forces
	_update_forcefield(delta)

	# Update the ship heated effect
	_update_heated_effect()

	# Update the HUD energy display
	_update_hud_energy()


func _on_input_action_pressed(player: int, action: String) -> void:
	if player != player_num:
		return  # Ignore input from other players
	if is_disabled:
		return  # Ignore input if the ship is disabled
	if action == InputManager.INPUT_ACTION_A:
		_do_activate_laser()
	elif action == InputManager.INPUT_ACTION_B:
		_do_launch_projectile_explosive()


func _on_input_action_released(player: int, action: String) -> void:
	if player != player_num:
		return  # Ignore input from other players
	if is_disabled:
		return  # Ignore input if the ship is disabled
	if action == InputManager.INPUT_ACTION_A:
		_do_deactivate_laser()


func _update_movement(delta: float) -> void:
	if is_disabled:
		return # Ignore input if the ship is disabled

	# Always aim towards the input direction if above threshold
	if InputManager.movement[player_num].length() >= Constant.PLAYER_SHIP_AIM_INPUT_THRESHOLD:
		target_rotation = InputManager.movement[player_num].angle()

	# Apply force in the direction of the input vector
	movement_dir = InputManager.movement[player_num]

	# If the ship is not disabled, apply a force in the direction of the input
	if movement_dir.length() > 0 and not is_disabled:
		apply_impulse(movement_dir * Constant.PLAYER_SHIP_FORCE_AMOUNT * delta)


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
	pass


# Defeat (anti-Victory) jumbotron is palpably victorious #193
func _do_defeat() -> void:
	do_disable()


# Called when the player wants to activate the primary tool
func _do_activate_laser() -> void:
	if laser_charge_sec < Constant.PLAYER_SHIP_LASER_AVAILABLE_MIN_CHARGE_SEC:
		return
	if laser:
		return
	laser         = ScenePreloader.laser_scene.instantiate()
	laser.player_num = player_num
	laser.source_ship = self
	laser.z_index = -100  # Ensure laser is behind the ship
	self.get_parent().call_deferred("add_child", laser)
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.LASER_ACTIVATE, laser_audio_key)


func _do_deactivate_laser() -> void:
	if laser:
		laser.call_deferred("queue_free")
		laser = null
		AudioManager.stop_2d_audio(laser_audio_key)


# Called when the player wants to activate the secondary tool
func _do_launch_projectile_explosive() -> void:
	if projectile_explosive_cooldown_sec > 0:
		return
	if not Game.player_can_launch_projectile(player_num):
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.PROJECTILE_FAIL)
		return
	projectile_explosive_cooldown_sec = Constant.PROJECTILE_EXPLOSIVE_COOLDOWN_SEC
	var rotation_vector: Vector2 = Vector2(cos(actual_rotation), sin(actual_rotation))
	var projectile: Node         = ScenePreloader.projectile_explosive_scene.instantiate()
	projectile.add_collision_exception_with(self)
	projectile.position = position
	projectile.rotation = actual_rotation
	projectile.linear_velocity = linear_velocity + rotation_vector * Constant.PROJECTILE_EXPLOSIVE_INITIAL_VELOCITY
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
	elif laser_charge_sec < Constant.PLAYER_SHIP_LASER_CHARGE_MAX_SEC and not is_disabled:
		# If the laser is not active, recharge it
		laser_charge_sec += delta * Constant.PLAYER_SHIP_LASER_RECHARGE_RATE
		laser_charge_sec = clamp(laser_charge_sec, 0.0, Constant.PLAYER_SHIP_LASER_CHARGE_MAX_SEC)


# Update the HUD energy display
func _update_hud_energy() -> void:
	match is_disabled:
		true:
			var energy := 1 - disabled_for_sec / Constant.PLAYER_SHIP_DISABLED_SEC
			Game.player_energy_updated.emit(player_num, energy, energy >= 1.0)
		false:
			Game.player_energy_updated.emit(player_num, laser_charge_sec / Constant.PLAYER_SHIP_LASER_CHARGE_MAX_SEC, laser_charge_sec >= Constant.PLAYER_SHIP_LASER_AVAILABLE_MIN_CHARGE_SEC)


# Apply forces to the bodies in the forcefield
func _update_forcefield(_delta: float) -> void:
	var forcefield_target_mass: float = 0
	if not is_disabled:
		var forcefield_position: Vector2 = forcefield_area.global_position - global_position
		var forcefield_delta: Vector2    = forcefield_position - forcefield_position_previous
		forcefield_position_previous = forcefield_position
		for key in forcefield_targets.keys():
			var body: Node2D = forcefield_targets[key]
			# if body is not in the scene tree, remove it from the forcefield_targets list
			if not body or not body.is_inside_tree():
				forcefield_targets.erase(key)
				continue
			# get the direction vector from the body to the center of forcefield
			var direction: Vector2 = (forcefield_area.global_position - body.global_position).normalized()
			# apply a force on the body towards the center of forcefield
			body.apply_central_force(direction * Constant.PLAYER_SHIP_FORCEFIELD_INWARD_FORCE * _delta)
			# apply a force on the body in the direction of the forcefield delta
			if forcefield_delta.length() > Constant.PLAYER_SHIP_FORCEFIELD_MOTION_THRESHOLD:
				body.apply_central_force(forcefield_delta * Constant.PLAYER_SHIP_FORCEFIELD_MOTION_FORCE * _delta)
			# accumulate the mass of the bodies in the forcefield
			if body is RigidBody2D:
				forcefield_target_mass += body.mass
	# Update the forcefield effect based on the mass of the ship
	if forcefield_target_mass > 0:
		var forcefield_amount = clamp(forcefield_target_mass / Constant.PLAYER_SHIP_FORCEFIELD_EFFECT_KG_MAX, 0.0, 1.0)
		$ForcefieldEffect.scale_amount_min = forcefield_amount * Constant.PLAYER_SHIP_FORCEFIELD_EFFECT_SCALE_MIN
		$ForcefieldEffect.scale_amount_max = forcefield_amount * Constant.PLAYER_SHIP_FORCEFIELD_EFFECT_SCALE_MAX
		$ForcefieldEffect.gravity = -Constant.PLAYER_SHIP_FORCEFIELD_EFFECT_GRAVITY * Vector2(cos(rotation), sin(rotation))
		$ForcefieldEffect.set_emitting(true)
	else:
		$ForcefieldEffect.set_emitting(false)


# Update the heated effect visibility and intensity
# Finite ship disabling #164
func _update_heated_effect() -> void:
	heat = clamp(heat, 0, Constant.PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC)
	if not is_disabled and heat >= Constant.PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC:
		do_disable()
		return
	if heated_effect == null:
		return
	if heat > 0:
		heated_effect.set_visible(true)
		heated_effect.modulate.a = clamp(heat / Constant.PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC, 0.0, 1.0)
	else:
		heated_effect.set_visible(false)


# Called when the ship collides with another body
func _on_collision(body: Node2D) -> void:
	if body is Block:
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.SHIP_COLLIDES_WITH_BLOCK_WHOLE)
	elif body is BlockHalf:
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.SHIP_COLLIDES_WITH_BLOCK_HALF)
	elif body is BlockQuart:
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.SHIP_COLLIDES_WITH_BLOCK_QUART)
	elif body is Gem:
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.SHIP_COLLIDES_WITH_GEM)
	elif body is Pickup:
		if Game.player_can_add_item(player_num):
			# FUTURE: AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.SHIP_COLLIDES_WITH_PICKUP)
			Game.player_did_collect_item.emit(player_num, body.type)
			body.do_pickup()


# Called when another body enters the forcefield area
func _on_forcefield_entered(body: Node2D) -> void:
	if body == self:
		return  # Ignore self

	if body is Collidable and not body is ProjectileExplosive:
		if body is Block and body.freeze:
			return
		if forcefield_targets.has(body.number):
			return
		forcefield_targets.set(body.number, body)


# Called when another body exits the forcefield area
func _on_forcefield_exited(body: Node2D) -> void:
	if body is Collidable and body.number in forcefield_targets:
		forcefield_targets.erase(body.number)
		
