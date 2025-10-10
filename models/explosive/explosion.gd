extends Node2D

# Cache the collision shape and explosive area
@onready var collision_shape: CollisionShape2D = $ExplosiveArea2D/CollisionShape2D
@onready var explosive_area: Area2D = $ExplosiveArea2D

# Player number to identify the projectile
@export var player_num: int = 0

# Variables
var instantiated_at_ticks_msec: int = 0
var explosive_radius: float         = 0.0
var heat_radius: float              = 0.0
var exploded: bool                  = false
var affected_bodies: Dictionary[int, Array] = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instantiated_at_ticks_msec = Time.get_ticks_msec()
	explosive_radius = collision_shape.shape.radius
	heat_radius = explosive_radius * Constant.EXPLOSION_HEAT_RADIUS_RATIO

	# Set the explosion color based on player_num
	if player_num in Constant.PLAYER_COLORS:
		$ParticleEmitter.color = Constant.PLAYER_COLORS[player_num][0]
		$PointLight2D.color = Util.color_at_sv_ratio(Constant.PLAYER_COLORS[player_num][0], 1.0, 2.0)
	else:
		push_error("No color found for player ", player_num)

	# Start the explosion effect
	$ParticleEmitter.emitting = true
	$AnimationPlayer.play("explode")

	# Play the explosion sound effect
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.PROJECTILE_IMPACT)

	# Disable lighting if not enabled in settings
	if not Game.is_lighting_enabled:
		$PointLight2D.enabled = false


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if affected_bodies.size() > 0:
		var now_at_msec: int = Time.get_ticks_msec() - instantiated_at_ticks_msec
		for at_msec in affected_bodies.keys():
			# If the time has come to apply effects to the bodies
			if now_at_msec >= at_msec:
				for item in affected_bodies[at_msec]:
					_apply_to_body(item)
				affected_bodies.erase(at_msec)

	if Time.get_ticks_msec() - instantiated_at_ticks_msec > Constant.EXPLOSION_LIFETIME_MSEC:
		queue_free()
		return

	# If already exploded, don't process further
	if exploded:
		return

	# Process all bodies in the collision area
	for body in explosive_area.get_overlapping_bodies():
		exploded = true  # Mark as exploded
		var diff: Vector2   = (body.position - position)
		var distance: float = diff.length()
		var dir: Vector2    = diff.normalized()
		var at_msec: int    = floori(pow(distance/explosive_radius, 2) * Constant.EXPLOSION_LIFETIME_MSEC)
		if not at_msec in affected_bodies:
			affected_bodies.set(at_msec, [])
		var item: Dictionary = {}
		item.body     = body
		item.dir      = dir
		item.distance = distance
		affected_bodies[at_msec].append(item)


# Apply explosion effects to the body based on distance
func _apply_to_body(item: Dictionary) -> void:
	var body     = item.body
	var dir      = item.dir
	var distance = item.distance
	if not body:
		return  # Ensure body is valid before proceeding
	body.apply_central_force(dir * Constant.EXPLOSION_FORCE * (1-pow(distance / explosive_radius, 2)))
	const max_heat = Constant.BLOCK_HEATED_BREAK_SEC * Constant.BLOCK_EXPLOSION_OVERHEAT_RATIO
	if body is Heatable:
		var heat = max_heat * Constant.PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC * Constant.EXPLOSION_SHIP_EFFECT_MULTIPLIER if body is Ship else max_heat
		if distance <= heat_radius:
			body.apply_heat(heat * (1-pow(-distance / heat_radius, 2)))

			
