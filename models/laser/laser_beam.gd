extends Node2D

# References to child nodes
@onready var raycastOne: RayCast2D = $RaycastOne
@onready var lineOne: Line2D = $LineOne
@onready var raycastTwo: RayCast2D = $RaycastTwo
@onready var lineTwo: Line2D = $LineTwo
@onready var sparks: CPUParticles2D = $Sparks
@onready var sparksLight: PointLight2D = $Sparks/PointLight2D

# variable for flickering effect
var alpha: float = 0.0


# Called when the node enters the scene tree for the first time.
func setup(player_num: int, source_ship: Ship = null) -> void:
	if source_ship:
		raycastOne.add_exception(source_ship)
	# Set the sprite texture based on player_num
	if player_num in Constant.PLAYER_COLORS:
		lineOne.default_color = Constant.PLAYER_COLORS[player_num][0]
		lineTwo.default_color = Constant.PLAYER_COLORS[player_num][0]
		sparks.color = Constant.PLAYER_COLORS[player_num][0]
		sparksLight.color = Constant.PLAYER_COLORS[player_num][0]
		
	else:
		push_error("No color found for player ", player_num)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_send_ray_one(0)


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	_send_ray_one(delta)


# Send ray one and handle collisions
func _send_ray_one(delta) -> void:
	# get the raycast collision point 
	# If no collision, set the line to max distance and hide ray two
	if raycastOne.is_colliding():
		_do_ray_one_collision(delta)
	else:
		lineOne.set_point_position(1, Vector2(Constant.PLAYER_SHIP_LASER_MAX_DISTANCE, 0))
		lineOne.modulate.a = 0.0
		_hide_ray_two()


# Do the ray one collision
func _do_ray_one_collision(delta: float) -> void:
	var local_collision_point: Vector2 = Vector2(global_position.distance_to(raycastOne.get_collision_point()), 0)

	# Make the line visible up to the collision point
	lineOne.set_point_position(1, local_collision_point)
	# Set the line to a random alpha value for a flickering effect
	alpha = wrapf(
		alpha + delta * Constant.PLAYER_SHIP_LASER_FLICKER_RATE,
		0.0,
		Constant.PLAYER_SHIP_LASER_ALPHA_MAX
	)
	lineOne.modulate.a = alpha

	# If the body is a gem, reflect the laser off the surface at the reflection angle
	if raycastOne.get_collider() is Gem:
		_send_ray_two(local_collision_point, delta)
	else:
		_do_hit(raycastOne.get_collider(), local_collision_point, delta)
		_hide_ray_two()


# Position raycastTwo at the collision point and set its direction to the reflection vector
func _send_ray_two(local_source_point: Vector2, delta: float) -> void:
	var normal: Vector2               = raycastOne.get_collision_normal()
	var local_normal_angle: float     = normal.angle() - get_parent().rotation
	var local_reflect_vector: Vector2 = local_source_point.bounce(Vector2.RIGHT.rotated(local_normal_angle))
	var local_raycast_target: Vector2 = local_reflect_vector.normalized() * Constant.PLAYER_SHIP_LASER_MAX_DISTANCE
	raycastTwo.position = local_source_point
	raycastTwo.enabled = true
	raycastTwo.target_position = local_raycast_target
	raycastTwo.force_raycast_update()
	lineTwo.visible = true
	lineTwo.modulate.a = alpha
	lineTwo.set_point_position(0, local_source_point)
	##### Debug info
	#
	#	Game.show_debug_text.emit("normal: %s, local_normal_angle: %s, local_reflect_angle: %s" % [
	#	Util.fmt_angle(normal.angle()),
	#	Util.fmt_angle(local_normal_angle),
	#	Util.fmt_angle(local_reflect_vector.angle())
	#	])
	#
	#####
	if raycastTwo.is_colliding():
		_do_ray_two_collision(raycastTwo.get_collider(), to_local(raycastTwo.get_collision_point()), delta)
	else:
		lineTwo.set_point_position(1, local_raycast_target)


# Make the line visible up to the collision point
# Do the ray two collision	
func _do_ray_two_collision(body: Node2D, local_target_point: Vector2, delta: float) -> void:
	lineTwo.set_point_position(1, local_target_point)
	_do_hit(body, local_target_point, delta)


# If the body is a gem, do not apply heat again, just hide the sparks
func _do_hit(body: Node2D, target_point: Vector2, delta: float) -> void:
	# If the body is heatable, apply heat and emit sparks at the collision point
	if body is Heatable:
		body.apply_heat(delta)
		sparks.set_emitting(true)
		sparks.position =  target_point
		if Game.is_lighting_fx_enabled:
			sparksLight.set_enabled(true)
	else:
		sparks.set_emitting(false)
		if Game.is_lighting_fx_enabled:
			sparksLight.set_enabled(false)


# Hide the second ray and its line
func _hide_ray_two() -> void:
	raycastTwo.enabled = false
	lineTwo.visible = false
