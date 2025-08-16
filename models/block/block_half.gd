class_name BlockHalf
extends Collidable

# Whether this block has a gem
@export var half_num: int
# Preload the quarter scenes
const quart_scene_1a: PackedScene = preload("res://models/block/block_quart_1a.tscn")
const quart_scene_1b: PackedScene = preload("res://models/block/block_quart_1b.tscn")
const quart_scene_2a: PackedScene = preload("res://models/block/block_quart_2a.tscn")
const quart_scene_2b: PackedScene = preload("res://models/block/block_quart_2b.tscn")
# Preloaded scene for the block quarter shattering
const shatter_scene: PackedScene = preload("res://models/block/block_quart_shatter.tscn")
# Cache reference to heated effect
@onready var heated_effect: Node2D = $HeatedEffect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()

	# Update the heated effect visibility
	_update_heated_effect()


# Break the block half apart into two quarters
func do_break() -> void:
	# Quarter A
	var quartA: Node = (quart_scene_1a if half_num == 1 else quart_scene_2a).instantiate()
	quartA.position = position
	quartA.linear_velocity = linear_velocity + (Vector2(-Constant.BLOCK_HALF_BREAK_APART_VELOCITY, 0) if half_num == 1 else Vector2(Constant.BLOCK_HALF_BREAK_APART_VELOCITY, 0))
	# Quarter B
	var quartB: Node = (quart_scene_1b if half_num == 1 else quart_scene_2b).instantiate()
	quartB.position = position
	quartB.linear_velocity = linear_velocity + (Vector2(0, -Constant.BLOCK_HALF_BREAK_APART_VELOCITY) if half_num == 1 else Vector2(0, Constant.BLOCK_HALF_BREAK_APART_VELOCITY))
	# Add the quarters to the scene
	self.get_parent().add_child(quartA)
	self.get_parent().add_child(quartB)
	# Transfer heat to the broken pieces
	if heat > 0:
		quartA.apply_heat(heat * 0.5 * Constant.BLOCK_BREAK_QUART_HEAT_TRANSFER_RATIO)
		quartB.apply_heat(heat * 0.5 * Constant.BLOCK_BREAK_QUART_HEAT_TRANSFER_RATIO)
	# Play sound effect
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.BLOCK_BREAK_QUARTERS)
	# Remove the block from the scene
	self.call_deferred("queue_free")


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_heated_effect()


# Update the heated effect visibility and intensity
func _update_heated_effect() -> void:
	if heat >= Constant.BLOCK_HALF_HEATED_BREAK_SEC:
		do_break()
		return
	if heated_effect == null:
		return  # Ensure heated_effect is valid before proceeding
	if heat > 0:
		heated_effect.set_visible(true)
		heated_effect.modulate.a = clamp(heat / Constant.BLOCK_HALF_HEATED_BREAK_SEC, 0.0, 1.0)
	else:
		heated_effect.set_visible(false)
