class_name BlockHalf
extends Collidable

# Whether this block has a gem
@export var half_num: int
# Preload the quarter scenes
const quart_scene_1a: PackedScene = preload("res://models/block/block_quart_1a.tscn")
const quart_scene_1b: PackedScene = preload("res://models/block/block_quart_1b.tscn")
const quart_scene_2a: PackedScene = preload("res://models/block/block_quart_2a.tscn")
const quart_scene_2b: PackedScene = preload("res://models/block/block_quart_2b.tscn")
# variable for being heated
var heat: float   = 0.0
var heat_delta: float = 0.0
# Preloaded scene for the block quarter shattering
const shatter_scene: PackedScene = preload("res://models/block/block_quart_shatter.tscn")
# Cache reference to heated effect
@onready var heated_effect: Node2D = $HeatedEffect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Update the heated effect visibility
	_update_heated_effect()
	pass


# Break the block half apart into two quarters
func do_break() -> void:
	# Quarter A
	var quartA: Node = (quart_scene_1a if half_num == 1 else quart_scene_2a).instantiate()
	quartA.position = position
	quartA.linear_velocity = linear_velocity + (Vector2(-Config.BLOCK_HALF_BREAK_APART_VELOCITY, 0) if half_num == 1 else Vector2(Config.BLOCK_HALF_BREAK_APART_VELOCITY, 0))
	# Quarter B
	var quartB: Node = (quart_scene_1b if half_num == 1 else quart_scene_2b).instantiate()
	quartB.position = position
	quartB.linear_velocity = linear_velocity + (Vector2(0, -Config.BLOCK_HALF_BREAK_APART_VELOCITY) if half_num == 1 else Vector2(0, Config.BLOCK_HALF_BREAK_APART_VELOCITY))
	# Add the quarters to the scene
	self.get_parent().add_child(quartA)
	self.get_parent().add_child(quartB)
	# Transfer heat to the broken pieces
	if heat > 0:
		quartA.apply_heat(heat * 0.5 * Config.BLOCK_BREAK_HEAT_TRANSFER_RATIO)
		quartB.apply_heat(heat * 0.5 * Config.BLOCK_BREAK_HEAT_TRANSFER_RATIO)
	# Remove the block from the scene
	self.call_deferred("queue_free")
	pass


# Apply heat
func apply_heat(delta: float) -> void:
	heat_delta += delta
	pass


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	_update_heat(_delta)
	pass


# If the ship is heated, increase the heated time, otherwise decrease it
# If the ship is heated for too long, disable it
func _update_heat(delta: float) -> void:
	if heat_delta > 0:
		heat += heat_delta
		heat_delta = 0.0
		_update_heated_effect()
		if heat >= Config.BLOCK_HALF_HEATED_BREAK_SEC:
			call_deferred("do_break")
	elif heat > 0:
		heat -= delta
		if heat < 0:
			heat = 0.0
		_update_heated_effect()
	pass


# Update the heated effect visibility and intensity
func _update_heated_effect() -> void:
	if heated_effect == null:
		return  # Ensure heated_effect is valid before proceeding
	if heat > 0:
		heated_effect.set_visible(true)
		heated_effect.modulate.a = clamp(heat / Config.BLOCK_HALF_HEATED_BREAK_SEC, 0.0, 1.0)
	else:
		heated_effect.set_visible(false)
	pass
