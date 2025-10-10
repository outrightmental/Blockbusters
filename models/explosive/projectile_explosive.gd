class_name ProjectileExplosive
extends Collidable

# Preloaded scene for the explosion effect
const explosion_scene: PackedScene = preload("res://models/explosive/explosion.tscn")
# Player number to identify the projectile
@export var player_num: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set the sprite texture based on player_num
	if player_num in Constant.PLAYER_COLORS:
		$TriangleLight.color = Constant.PLAYER_COLORS[player_num][0]
		$TriangleDark.color = Constant.PLAYER_COLORS[player_num][1]
		$PointLight2D.color = Constant.PLAYER_COLORS[player_num][0]
	else:
		push_error("No color found for player ", player_num)

	# Connect the Collision to the on-collision function
	connect("body_entered", _on_body_entered)

	# Count this projectile
	Game.projectiles_in_play += 1
	Game.projectile_count_updated.emit()

	# Disable lighting if not enabled in settings
	if not Game.is_lighting_enabled:
		$PointLight2D.enabled = false


# Called when the projectile is removed from the stage
func _exit_tree() -> void:
	Game.projectiles_in_play -= 1
	Game.projectile_count_updated.emit()
	pass


# Called when another body enters the collission area
func _on_body_entered(_other: Node) -> void:
	var explosion: Node = explosion_scene.instantiate()
	explosion.position = position
	explosion.player_num = player_num
	self.get_parent().call_deferred("add_child", explosion)
	# Remove this projectile from the stage
	self.queue_free()
	pass


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	# If below the maxiumum velocity, apply force
	if (get_linear_velocity().length() < Constant.PROJECTILE_EXPLOSIVE_MAX_VELOCITY):
		# Apply force in the direction of the ship
		apply_central_force(Constant.PROJECTILE_EXPLOSIVE_ACCELERATION * get_global_transform().x.normalized())
	pass
