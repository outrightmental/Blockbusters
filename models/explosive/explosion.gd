extends Node2D

# Cache the collision shape and explosive area
@onready var collision_shape: CollisionShape2D = $ExplosiveArea2D/CollisionShape2D
@onready var explosive_area: Area2D = $ExplosiveArea2D

# Player number to identify the projectile
@export var player_num: int = 0

# Variables
var alive_sec: float   = 0.0
var heat_radius: float = 0.0
var exploded: bool     = false
var affected_bodies_waves: Dictionary[int, Array] = {}

# Constants
const WAVE_SEC = Constant.EXPLOSION_LIFETIME_SEC / Constant.EXPLOSION_WAVE_COUNT


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_shape.shape.radius = Constant.EXPLOSION_RADIUS
	heat_radius = Constant.EXPLOSION_RADIUS_HEATED

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
func _physics_process(delta: float) -> void:
	if affected_bodies_waves.size() > 0:
		alive_sec += delta
		for wave_num in affected_bodies_waves.keys():
			# If the time has come to apply effects to the bodies
			if alive_sec >= wave_num * WAVE_SEC:
				for item in affected_bodies_waves[wave_num]:
					_apply_to_body(delta, item)
				if alive_sec >= wave_num * WAVE_SEC + Constant.EXPLOSIVE_AFFECT_SEC:
					affected_bodies_waves.erase(wave_num)

	if alive_sec > Constant.EXPLOSION_LIFETIME_SEC:
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
		var wave_num: int   = floori(Constant.EXPLOSION_WAVE_COUNT * pow(distance/Constant.EXPLOSION_RADIUS, 2) * Constant.EXPLOSION_LIFETIME_SEC)
		if not wave_num in affected_bodies_waves:
			affected_bodies_waves.set(wave_num, [])
		var item: Dictionary = {}
		item.body     = body
		item.dir      = dir
		item.distance = distance
		affected_bodies_waves[wave_num].append(item)


# Apply explosion effects to the body based on distance
func _apply_to_body(delta: float, item: Dictionary) -> void:
	var body     = item.body
	var dir      = item.dir
	var distance = item.distance
	if not body:
		return  # Ensure body is valid before proceeding
	body.apply_central_force(delta * dir * Constant.EXPLOSION_FORCE * (1-pow(distance / Constant.EXPLOSION_RADIUS, 2)))
	if body is Heatable:
		var heat = Constant.EXPLOSION_HEAT_MAX * Constant.EXPLOSION_SHIP_EFFECT_MULTIPLIER if body is Ship else Constant.EXPLOSION_HEAT_MAX
		if distance <= heat_radius:
			body.apply_heat(delta * heat * (1-pow(-distance / heat_radius, 2)))

			
