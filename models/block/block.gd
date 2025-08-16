class_name Block
extends Collidable

# Variables
var gem: Node = null
# Preloaded scenes
const half1_scene: PackedScene = preload("res://models/block/block_half_1.tscn")
const half2_scene: PackedScene = preload("res://models/block/block_half_2.tscn")
const gem_scene: PackedScene   = preload("res://models/gem/gem.tscn")
# Whether this block has a gem
@export var has_gem: bool = false

# Cache reference to heated effect
@onready var heated_effect: Node2D = $HeatedEffect
# Cache reference to Shapes
@onready var shapes: Node2D = $Shapes
# Preloaded scene for the block quarter shattering
const shatter_scene: PackedScene = preload("res://models/block/block_quart_shatter.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	set_linear_damp(Constant.BLOCK_LINEAR_DAMP)
	add_to_group(Game.BLOCK_GROUP)

	# On collision
	body_entered.connect(_on_body_entered)
	set_contact_monitor(true)

	# Start inactive
	freeze = true
	shapes.modulate.a = Constant.BLOCK_INACTIVE_OPACITY

	# Update the heated effect visibility
	_update_heated_effect()


# When a gem can be added
func can_add_gem() -> bool:
	# If the block already has a gem, return false
	if gem:
		return false
	# If the block is unfrozen, return false
	if not freeze:
		return false
	# otherwise, return true
	return true


# Adds a gem inside this block
func add_gem() -> void:
	$ParticleEmitter.emitting = true
	gem = gem_scene.instantiate()
	gem.position = Vector2(0, 0)
	gem.add_collision_exception_with(self)
	gem.freeze = true
	gem.modulate.a = Constant.BLOCK_INNER_GEM_ALPHA
	self.add_child(gem)
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.GAME_START)


# Break the block apart into two halves
func do_break() -> void:
	# Half 1
	var half1: Node = half1_scene.instantiate()
	half1.position = position
	half1.linear_velocity = linear_velocity + Vector2(-Constant.BLOCK_BREAK_APART_VELOCITY, -Constant.BLOCK_BREAK_APART_VELOCITY)
	half1.half_num = 1
	# Half 2
	var half2: Node = half2_scene.instantiate()
	half2.position = position
	half2.linear_velocity = linear_velocity + Vector2(Constant.BLOCK_BREAK_APART_VELOCITY, Constant.BLOCK_BREAK_APART_VELOCITY)
	half2.half_num = 2
	# If the block has a gem, release it, and play the sound effect depending on whether there was a gem or not
	if _do_release_gem():
		gem.add_collision_exception_with(half1)
		gem.add_collision_exception_with(half2)
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.BLOCK_BREAK_HALF_GEM)
	else:
		AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.BLOCK_BREAK_HALF_NOGEM)
	# Transfer heat to the broken pieces
	if heat > 0:
		half1.apply_heat(heat * 0.5 * Constant.BLOCK_BREAK_HALF_HEAT_TRANSFER_RATIO)
		half2.apply_heat(heat * 0.5 * Constant.BLOCK_BREAK_HALF_HEAT_TRANSFER_RATIO)
	# Add the halves to the scene
	self.get_parent().add_child(half2)
	self.get_parent().add_child(half1)
	# Remove the block from the scene
	self.call_deferred("queue_free")


func _do_release_gem() -> bool:
	# Gem
	if gem:
		gem.queue_free()
		gem = gem_scene.instantiate()
		gem.position = position
		gem.linear_velocity = linear_velocity
		gem.add_collision_exception_with(self)
		self.get_parent().call_deferred("add_child", gem)
		return true
	return false


# Activate
func do_activate() -> void:
	freeze = false
	shapes.modulate.a = 1


# Play a sound when colliding with another object
func _on_body_entered(_body: Node) -> void:
	print ("Block collided with: ", _body.name)
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.BLOCK_COLLIDES_WITH_BLOCK)


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_heated_effect()


# Update the heated effect visibility and intensity
func _update_heated_effect() -> void:
	if heat >= Constant.BLOCK_HEATED_BREAK_SEC:
		do_break()
		return
	elif freeze and heat >= Constant.BLOCK_ACTIVATION_HEAT_THRESHOLD:
		do_activate()
		return
	if heated_effect == null:
		return  # Ensure heated_effect is valid before proceeding
	if heat > 0:
		heated_effect.set_visible(true)
		heated_effect.modulate.a = clamp(heat / Constant.BLOCK_HEATED_BREAK_SEC, 0.0, 1.0)
	else:
		heated_effect.set_visible(false)


# Called when the block is instantiated
func _init():
	super._init()
