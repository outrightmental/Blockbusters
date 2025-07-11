class_name LaserBeam
extends Node2D

# Player number to identify the laser beam
@export var player_num: int = 0
# Player ship to avoid self-collision
@export var source_ship: Ship = null

# References to child nodes
@onready var raycast: RayCast2D = $RayCast2D
@onready var line: Line2D = $Line2D
@onready var sparks: CPUParticles2D = $Sparks

# variable for flickering effect
var alpha: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if source_ship:
		raycast.add_exception(source_ship)
	# Set the sprite texture based on player_num
	if player_num in Config.PLAYER_COLORS:
		line.default_color = Config.PLAYER_COLORS[player_num][0]
		sparks.color = Config.PLAYER_COLORS[player_num][0]
	else:
		push_error("No texture found for player_num: ", player_num)


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# get the raycast collision point 
	if raycast.is_colliding():
		var collision_distance: float = global_position.distance_to(raycast.get_collision_point())
		var body: Node2D              = raycast.get_collider()
		var target_point: Vector2     = Vector2(collision_distance, 0)

		# If the body is heatable, apply heat
		if body is Ship or body is Block or body is BlockHalf or body is BlockQuart:
			body.do_heat(delta)

		# Make the line visible up to the collision point
		line.set_point_position(1, target_point)
		# Set the line to a random alpha value for a flickering effect
		alpha = wrapf(alpha + delta * Config.PLAYER_SHIP_LASER_FLICKER_RATE, 0.0, 1.0)
		line.set_default_color(Util.color_at_alpha_ratio(Config.PLAYER_COLORS[player_num][0], alpha))
		# Emit sparks at the collision point
		sparks.set_emitting(true)
		sparks.position =  target_point
