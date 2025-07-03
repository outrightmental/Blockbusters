class_name Block
extends Collidable

# Variables
var gem: Node = null
# variable for being heated
var heated_sec: float   = 0.0
var heated_delta: float = 0.0

# List of nodes that should not break this
@export var dont_break_by: Array[Node] = []
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
	set_linear_damp(Config.BLOCK_LINEAR_DAMP)
	add_to_group(Game.BLOCK_GROUP)
	# Update the heated effect visibility
	_update_heated_effect()
	# On collision
	body_entered.connect(_on_body_entered)
	set_contact_monitor(true)
	# Start inactive
	freeze = true
	shapes.modulate.a = Config.BLOCK_INACTIVE_OPACITY
	pass


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
	gem.modulate.a = Config.BLOCK_INNER_GEM_ALPHA
	self.add_child(gem)
	pass


# Break the block apart into two halves
func do_break(broken_by: Node = null) -> void:
	# Don't break by objects in the dont_break_by list
	if broken_by in dont_break_by:
		return
	# Half 1
	var half1: Node = half1_scene.instantiate()
	half1.add_collision_exception_with(self)
	half1.position = position
	half1.linear_velocity = linear_velocity + Vector2(-Config.BLOCK_BREAK_APART_VELOCITY, -Config.BLOCK_BREAK_APART_VELOCITY)
	half1.half_num = 1
	half1.do_heat(Config.BLOCK_HALF_HEATED_BREAK_SEC * Config.BLOCK_BREAK_HEAT_TRANSFER_RATIO)
	# Half 2
	var half2: Node = half2_scene.instantiate()
	half2.add_collision_exception_with(self)
	half2.position = position
	half2.linear_velocity = linear_velocity + Vector2(Config.BLOCK_BREAK_APART_VELOCITY, Config.BLOCK_BREAK_APART_VELOCITY)
	half2.half_num = 2
	half2.do_heat(Config.BLOCK_HALF_HEATED_BREAK_SEC * Config.BLOCK_BREAK_HEAT_TRANSFER_RATIO)
	# Gem
	if _do_release_gem():
		gem.add_collision_exception_with(half1)
		gem.add_collision_exception_with(half2)
	# Avoid collisions with the block that broke this half
	if broken_by:
		half1.dont_break_by.append(broken_by)
		half2.dont_break_by.append(broken_by)
	# Add the halves to the scene
	self.get_parent().call_deferred("add_child", half2)
	self.get_parent().call_deferred("add_child", half1)
	# Remove the block from the scene
	self.call_deferred("queue_free")
	pass


# Shatter into dust
func do_shatter() -> void:
	_do_release_gem()
	# Shatter effect
	var shatter: Node = shatter_scene.instantiate()
	shatter.position = position
	self.get_parent().call_deferred("add_child", shatter)
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


# Add heat
func do_heat(delta: float) -> void:
	heated_delta += delta
	pass


# Activate
func do_activate() -> void:
	freeze = false
	shapes.modulate.a = 1
	pass


# Play a sound when colliding with another object
func _on_body_entered(_body: Node) -> void:
	print ("Block collided with: ", _body.name)
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.BLOCK_COLLIDES_WITH_BLOCK)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_update_heat(_delta)
	pass


# If the ship is heated, increase the heated time, otherwise decrease it
# If the ship is heated for too long, disable it
func _update_heat(delta: float) -> void:
	if heated_delta > 0:
		heated_sec += heated_delta
		heated_delta = 0.0
		_update_heated_effect()
		if heated_sec >= Config.BLOCK_HEATED_BREAK_SEC:
			call_deferred("do_break")
		if freeze and heated_sec >= Config.BLOCK_ACTIVATION_HEAT_THRESHOLD:
			call_deferred("do_activate")
	elif heated_sec > 0:
		heated_sec -= delta
		if heated_sec < 0:
			heated_sec = 0.0
		_update_heated_effect()
	pass


# Update the heated effect visibility and intensity
func _update_heated_effect() -> void:
	if heated_effect == null:
		return  # Ensure heated_effect is valid before proceeding
	if heated_sec > 0:
		heated_effect.set_visible(true)
		heated_effect.modulate.a = clamp(heated_sec / Config.BLOCK_HEATED_BREAK_SEC, 0.0, 1.0)
	else:
		heated_effect.set_visible(false)
	pass


# Called when the block is instantiated
func _init():
	super._init()
