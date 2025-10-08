extends Node2D

# References to child nodes
@onready var raycastOne: RayCast2D = $RaycastOne
@onready var lineOne: Line2D = $LineOne
@onready var raycastTwo: RayCast2D = $RaycastTwo
@onready var lineTwo: Line2D = $LineTwo
@onready var sparks: CPUParticles2D = $Sparks

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
	var collision_distance: float     = global_position.distance_to(raycastOne.get_collision_point())
	var body: Node2D                  = raycastOne.get_collider()
	var ray_one_target_point: Vector2 = Vector2(collision_distance, 0)

	# Make the line visible up to the collision point
	lineOne.set_point_position(1, ray_one_target_point)
	# Set the line to a random alpha value for a flickering effect
	alpha = wrapf(
		alpha + delta * Constant.PLAYER_SHIP_LASER_FLICKER_RATE,
		0.0,
		Constant.PLAYER_SHIP_LASER_ALPHA_MAX
	)
	lineOne.modulate.a = alpha

	# If the body is a gem, reflect the laser off the surface at the reflection angle
	if body is Gem:
		_send_ray_two(ray_one_target_point,  delta)
	else:
		_do_hit(ray_one_target_point, body, delta)
		_hide_ray_two()


# Send ray two from the collision point
func _send_ray_two(source_point: Vector2, delta: float) -> void:
	var normal: Vector2   = raycastOne.get_collision_normal()
	var incoming: Vector2 = (raycastOne.target_position - raycastOne.position).normalized()
	var reflect: Vector2  = incoming.bounce(normal).normalized()
	# Position raycastTwo at the collision point and set its direction to the reflection vector
	raycastTwo.position = source_point
	raycastTwo.target_position = reflect * Constant.PLAYER_SHIP_LASER_MAX_DISTANCE
	raycastTwo.enabled = true
	raycastTwo.rotation = PI / 2 # remove this testing piece
	raycastTwo.force_raycast_update()
	lineTwo.visible = true
	lineTwo.modulate.a = alpha
	lineTwo.set_point_position(0, source_point)
	# If raycastTwo is colliding, handle the collision
	# If no collision, set the line to max distance
	if raycastTwo.is_colliding():
		_do_ray_two_collision(delta)
	else:
		lineTwo.set_point_position(1, reflect * Constant.PLAYER_SHIP_LASER_MAX_DISTANCE)


# Do the ray two collision	
func _do_ray_two_collision(delta: float) -> void:
	var collision_distance: float     = raycastTwo.position.distance_to(raycastTwo.get_collision_point())
	var body: Node2D                  = raycastTwo.get_collider()
	var ray_two_target_point: Vector2 = raycastTwo.position + Vector2(collision_distance, 0).rotated(raycastTwo.rotation)

	# Make the line visible up to the collision point
	lineTwo.set_point_position(1, ray_two_target_point - raycastTwo.position)

	# If the body is a gem, do not apply heat again, just hide the second ray
	if not body is Gem:
		_do_hit(ray_two_target_point, body, delta)


# Hit a target
func _do_hit(ray_one_target_point: Vector2, body: Node2D, delta: float) -> void:
	# If the body is heatable, apply heat and emit sparks at the collision point
	if body is Heatable:
		body.apply_heat(delta)
		sparks.set_emitting(true)
		sparks.position =  ray_one_target_point


# Hide the second ray and its line
func _hide_ray_two() -> void:
	raycastTwo.enabled = false
	lineTwo.visible = false
