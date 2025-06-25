class_name LaserBeam
extends Node2D

# Player number to identify the laser beam
@export var player_num: int = 0

# Player ship to avoid self-collision
@export var source_ship: Ship = null

@onready var raycast: RayCast2D = $RayCast2D
@onready var line: Line2D = $Line2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if source_ship:
		raycast.add_exception(source_ship)
	# Set the sprite texture based on player_num
	if player_num in Config.PLAYER_COLORS:
		line.default_color = Config.PLAYER_COLORS[player_num][0]
	else:
		printerr("No texture found for player_num: ", player_num)


func _process(delta: float) -> void:
	# get the raycast collision point 
	if raycast.is_colliding():
		var collision_distance: float = global_position.distance_to(raycast.get_collision_point())
		var body: Node2D              = raycast.get_collider()

		# If the body is heatable, apply heat
		if body is Ship or body is Block or body is BlockHalf or body is BlockQuart:
			body.do_heat(delta)

		# Make the line visible up to the collision point
		line.set_point_position(1, Vector2(collision_distance, 0))

	else:

		# If no collision, extend the line to a maximum length
		line.set_point_position(1, Vector2(Config.PLAYER_SHIP_LASER_MAX_LENGTH, 0))
