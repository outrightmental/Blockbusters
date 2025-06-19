class_name BlockHalf
extends Collidable

# Whether this block has a gem
@export var half_num: int
# Preload the quarter scenes
const quart_scene_1a: PackedScene = preload("res://models/block/block_quart_1a.tscn")
const quart_scene_1b: PackedScene = preload("res://models/block/block_quart_1b.tscn")
const quart_scene_2a: PackedScene = preload("res://models/block/block_quart_2a.tscn")
const quart_scene_2b: PackedScene = preload("res://models/block/block_quart_2b.tscn")


# List of nodes that should not break this
@export var dont_break_by: Array[Node] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Break the block half apart into two quarters
func do_break(broken_by: Node = null) -> void:
	# Don't break by objects in the dont_break_by list
	if broken_by in dont_break_by:
		return
	# Quarter A
	var quartA: Node = (quart_scene_1a if half_num == 1 else quart_scene_2a).instantiate()
	quartA.add_collision_exception_with(self)
	quartA.position = position
	quartA.linear_velocity = linear_velocity
	# Quarter B
	var quartB: Node = (quart_scene_1b if half_num == 1 else quart_scene_2b).instantiate()
	quartB.add_collision_exception_with(self)
	quartB.position = position
	quartB.linear_velocity = linear_velocity
	# Avoid collisions with the block that broke this half
	if broken_by:
		quartA.dont_break_by.append(broken_by)
		quartB.dont_break_by.append(broken_by)
	# Add the quarters to the scene
	self.get_parent().call_deferred("add_child", quartA)
	self.get_parent().call_deferred("add_child", quartB)
	# Remove the block from the scene
	self.call_deferred("queue_free")
	pass
