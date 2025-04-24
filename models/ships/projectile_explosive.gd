extends "res://models/collidable/collidable.gd"

# Player number to identify the ship
@export var player_num: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(Global.GROUP_AFFECTED_BY_EXPLOSION)
	add_to_group(Global.GROUP_PROJECTILE_EXPLOSIVES)

	# Set the sprite texture based on player_num
	if player_num in Global.PLAYER_COLORS:
		$TriangleLight.color = Global.PLAYER_COLORS[player_num][0]
		$TriangleDark.color = Global.PLAYER_COLORS[player_num][1]
	else:
		print("No texture found for player_num: ", player_num)
	
	# Connect the Collision to the on-collision function
	connect("body_entered", _on_body_entered)
	pass


# Called when another body enters the collission area
func _on_body_entered(other: Node) -> void:
	var explosion: Node = preload("res://models/effects/explosion.tscn").instantiate()
	explosion.position = position
	explosion.set_owner(owner)
	explosion.add_to_group(Global.GROUP_EXPLOSIONS)
	self.get_parent().call_deferred("add_child", explosion)
	# Remove this projectile from the stage
	self.queue_free()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# If below the maxiumum velocity, apply force
	if (get_linear_velocity().length() < Global.PLAYER_SHIP_PROJECTILE_EXPLOSIVE_MAX_VELOCITY):
		# Apply force in the direction of the ship
		apply_central_force(Global.PLAYER_SHIP_PROJECTILE_EXPLOSIVE_ACCELERATION * get_global_transform().x.normalized())
	pass


# Called when the ship is instantiated
func _init():
	super._init()
