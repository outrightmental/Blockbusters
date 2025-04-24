extends "res://models/collidable/collidable.gd"

const LINEAR_DAMP: int              = 1
var screen_size: Vector2

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
	
	# Connect the Collision to the on-collision function
	connect("body_entered", _on_body_entered)
	pass


func _on_viewport_resize() -> void:
	screen_size = get_viewport_rect().size
	pass
	
	
# Called when another body enters the collission area
func _on_body_entered(other: Node) -> void:
	print("PROJECTILE EXPLOSIVE COLLISION")
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
