extends Node2D

# Cache the collision shape
@onready var collision_shape: CollisionShape2D = $ExplosiveArea2D/CollisionShape2D

# Player number to identify the projectile
@export var player_num: int = 0
# Variables
var instantiated_at_ticks_msec: float    = 0.0
var explosive_radius: float              = 0.0
var critical_radius_ship: float          = 0.0
var critical_radius_block_break: float   = 0.0
var critical_radius_block_shatter: float = 0.0
var heat_radius: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instantiated_at_ticks_msec = Time.get_ticks_msec()
	explosive_radius = collision_shape.shape.radius
	critical_radius_ship = explosive_radius * Config.EXPLOSION_CRITICAL_RADIUS_SHIP_RATIO
	critical_radius_block_break = explosive_radius * Config.EXPLOSION_CRITICAL_RADIUS_BLOCK_BREAK_RATIO
	critical_radius_block_shatter = explosive_radius * Config.EXPLOSION_CRITICAL_RADIUS_BLOCK_SHATTER_RATIO
	heat_radius = explosive_radius * Config.EXPLOSION_HEAT_RADIUS_RATIO
	$ExplosiveArea2D.body_entered.connect(_on_body_entered)
	# Set the explosion color based on player_num
	if player_num in Config.PLAYER_COLORS:
		$ParticleEmitter.color = Config.PLAYER_COLORS[player_num][0]
	else:
		push_error("No texture found for player_num: ", player_num)
	$ParticleEmitter.emitting = true


# Called when another body enters the collission area
func _on_body_entered(body: Node2D) -> void:
	var diff: Vector2 = (body.position - position)
	var distance: float = diff.length()
	body.apply_central_force(diff.normalized() * Config.EXPLOSION_FORCE * (1 - distance / explosive_radius))
	if body is Block or body is BlockHalf or body is BlockQuart:
		if distance <= heat_radius:
			body.do_heat(clamp(Config.BLOCK_HEATED_BREAK_SEC * 1.2 - distance/heat_radius, 0, Config.BLOCK_HEATED_BREAK_SEC ))
		if distance <= critical_radius_block_shatter:
			body.do_shatter()
		elif distance <= critical_radius_block_break:
			body.do_break(self)
	if body is Ship:
		if distance <= heat_radius:
			body.do_heat(clamp(Config.PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC * 1.2 - distance/heat_radius, 0, Config.PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC ))


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if Time.get_ticks_msec() - instantiated_at_ticks_msec > Config.EXPLOSION_LIFETIME_MSEC:
		queue_free()
