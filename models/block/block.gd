class_name Block
extends Heatable

# Variables
var item: Node = null

# Whether this block has a gem
@export var has_gem: bool = false

# Cache reference to heated effect
@onready var heated_effect: Node2D = $HeatedEffect
# Cache reference to Shapes
@onready var shapes: Node2D = $Shapes


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	set_linear_damp(Constant.BLOCK_LINEAR_DAMP)
	add_to_group(Game.BLOCK_GROUP)

	# On collision
	set_contact_monitor(true)

	# Start inactive
	freeze = true
	shapes.modulate.v = Constant.BLOCK_INACTIVE_MODULATE_VALUE

	# Update the heated effect visibility
	_update_heated_effect()


# When a gem can be added
func is_empty() -> bool:
	# If the block already has a gem, return false
	if item:
		return false
	# If the block is unfrozen, return false
	if not freeze:
		return false
	# otherwise, return true
	return true


# Adds a gem inside this block
func add_gem() -> void:
	$ParticleEmitter.emitting = true
	$LightOccluder2D.visible = false
	item = ScenePreloader.gem_scene.instantiate()
	item.position = Vector2(0, 0)
	item.add_collision_exception_with(self)
	item.freeze = true
	item.modulate.a = Constant.BLOCK_INNER_ITEM_ALPHA
	self.add_child(item)
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.GAME_START)


# Adds a pickup inside this block -- currently only projectiles
func add_pickup(type: Game.InventoryItemType) -> void:
	$ParticleEmitter.emitting = true
	$LightOccluder2D.visible = false
	match type:
		Game.InventoryItemType.PROJECTILE:
			item = ScenePreloader.pickup_projectile_scene.instantiate()
			item.position = Vector2(0, 0)
			item.add_collision_exception_with(self)
			item.freeze = true
			item.modulate.a = Constant.BLOCK_INNER_ITEM_ALPHA
			self.add_child(item)
		_:
			push_error("[Block] Unsupported pickup type: %s" % type)
			return
	# sound is currently the same as gem addition
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.GAME_START)


# Break the block apart into two halves
func do_break() -> void:
	# Half 1
	var half1: Node = ScenePreloader.block_half_1_scene.instantiate()
	half1.position = position
	half1.linear_velocity = linear_velocity + Vector2(-Constant.BLOCK_BREAK_APART_VELOCITY, -Constant.BLOCK_BREAK_APART_VELOCITY)
	half1.half_num = 1
	# Half 2
	var half2: Node = ScenePreloader.block_half_2_scene.instantiate()
	half2.position = position
	half2.linear_velocity = linear_velocity + Vector2(Constant.BLOCK_BREAK_APART_VELOCITY, Constant.BLOCK_BREAK_APART_VELOCITY)
	half2.half_num = 2
	# If the block has a gem, release it, and play the sound effect depending on whether there was a gem or not
	if _do_release_item():
		item.add_collision_exception_with(half1)
		item.add_collision_exception_with(half2)
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


func _do_release_item() -> bool:
	if item:
		item.freeze = false
		item.reparent(self.get_parent())
		item.add_collision_exception_with(self)
		item.modulate.a = 1.0
		item.position = position
		item.linear_velocity = linear_velocity
		return true
	return false


# Activate
func do_activate() -> void:
	freeze = false
	shapes.modulate.v = 1


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
