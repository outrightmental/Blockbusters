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
var heated_sec: float   = 0.0
var heated_delta: float = 0.0
# Preloaded scene for the block quarter shattering
const shatter_scene: PackedScene = preload("res://models/block/block_quart_shatter.tscn")
# Cache reference to heated effect
@onready var heated_effect: Node2D = $HeatedEffect

# List of nodes that should not break this
@export var dont_break_by: Array[Node] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Update the heated effect visibility
	_update_heated_effect()
	pass


# Break the block half apart into two quarters
func do_break(broken_by: Node = null, level: int = 1) -> void:
	# Don't break by objects in the dont_break_by list
	if broken_by in dont_break_by:
		return
	# Quarter A
	var quartA: Node = (quart_scene_1a if half_num == 1 else quart_scene_2a).instantiate()
	quartA.add_collision_exception_with(self)
	quartA.position = position
	quartA.linear_velocity = linear_velocity + (Vector2(-Config.BLOCK_HALF_BREAK_APART_VELOCITY, 0) if half_num == 1 else Vector2(Config.BLOCK_HALF_BREAK_APART_VELOCITY, 0))
	quartA.do_heat(Config.BLOCK_QUART_HEATED_BREAK_SEC * Config.BLOCK_BREAK_HEAT_TRANSFER_RATIO)
	# Quarter B
	var quartB: Node = (quart_scene_1b if half_num == 1 else quart_scene_2b).instantiate()
	quartB.add_collision_exception_with(self)
	quartB.position = position
	quartB.linear_velocity = linear_velocity + (Vector2(0, -Config.BLOCK_HALF_BREAK_APART_VELOCITY) if half_num == 1 else Vector2(0, Config.BLOCK_HALF_BREAK_APART_VELOCITY))
	quartB.do_heat(Config.BLOCK_QUART_HEATED_BREAK_SEC * Config.BLOCK_BREAK_HEAT_TRANSFER_RATIO)
	# Avoid collisions with the block that broke this half
	if broken_by:
		quartA.dont_break_by.append(broken_by)
		quartB.dont_break_by.append(broken_by)
	# Add the quarters to the scene
	self.get_parent().call_deferred("add_child", quartA)
	self.get_parent().call_deferred("add_child", quartB)
	# If the break level is higher than 1, pass the break down to the quarters
	if level > 1:
		quartA.call_deferred("do_break", broken_by, level-1)
		quartB.call_deferred("do_break", broken_by, level-1)
	# Remove the block from the scene
	self.call_deferred("queue_free")
	pass


# Shatter into dust
func do_shatter() -> void:
	var shatter: Node = shatter_scene.instantiate()
	shatter.position = position
	self.get_parent().call_deferred("add_child", shatter)
	self.call_deferred("queue_free")


# Add heat
func do_heat(delta: float) -> void:
	heated_delta += delta
	pass


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	_update_heat(_delta)
	pass


# If the ship is heated, increase the heated time, otherwise decrease it
# If the ship is heated for too long, disable it
func _update_heat(delta: float) -> void:
	if heated_delta > 0:
		heated_sec += heated_delta
		heated_delta = 0.0
		_update_heated_effect()
		if heated_sec >= Config.BLOCK_HALF_HEATED_BREAK_SEC:
			call_deferred("do_break")
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
		heated_effect.modulate.a = clamp(heated_sec / Config.BLOCK_HALF_HEATED_BREAK_SEC, 0.0, 1.0)
	else:
		heated_effect.set_visible(false)
	pass
