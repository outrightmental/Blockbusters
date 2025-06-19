extends Node2D

# Cache the collision shape
@onready var collision_shape: CollisionShape2D = $ExplosiveArea2D/CollisionShape2D

# Player number to identify the projectile
@export var player_num: int = 0
# Constants
const LIFETIME_MSEC: int                 = 200
const CRITICAL_RADIUS_BLOCK_RATIO: float = 0.5
const CRITICAL_RADIUS_SHIP_RATIO: float  = 0.4
const EXPLOSION_FORCE: int               = 5000
# Variables
var instantiated_at_ticks_msec: float = 0.0
var explosive_radius: float           = 0.0
var critical_radius_ship: float       = 0.0
var critical_radius_block: float      = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instantiated_at_ticks_msec = Time.get_ticks_msec()
	explosive_radius = collision_shape.shape.radius
	critical_radius_ship = explosive_radius * CRITICAL_RADIUS_SHIP_RATIO
	critical_radius_block = explosive_radius * CRITICAL_RADIUS_BLOCK_RATIO
	$ExplosiveArea2D.body_entered.connect(_on_body_entered)
	# Disable the collision shape so that collisions only occur at the instant of explosion
	collision_shape.call_deferred("set_disabled", true)

	
# Called when another body enters the collission area
func _on_body_entered(body: Node2D) -> void:
	var diff: Vector2 = (body.position - position)
	body.apply_central_force(diff.normalized() * EXPLOSION_FORCE * (1 - diff.length() / explosive_radius))
	if diff.length() <= critical_radius_block:
		if body is Block or body is BlockHalf or body is BlockQuart:
			body.do_break()
	if body is Ship and diff.length() <= critical_radius_ship:
		body.do_disable(player_num)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - instantiated_at_ticks_msec > LIFETIME_MSEC:
		queue_free()
