class_name BlockHalf
extends Collidable

# Whether this block has a gem
@export var half_num: int


# Preload the quarter scenes
@onready var quart_scene_1a: PackedScene = preload("res://models/block/block_quart_1a.tscn")
@onready var quart_scene_1b: PackedScene = preload("res://models/block/block_quart_1b.tscn")
@onready var quart_scene_2a: PackedScene = preload("res://models/block/block_quart_2a.tscn")
@onready var quart_scene_2b: PackedScene = preload("res://models/block/block_quart_2b.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Break the block half apart into two quarters
func do_break() -> void:
	# Quarter A
	var fragA: Node = quart_scene_1a.instantiate()
	fragA.add_collision_exception_with(self)
	fragA.position = position
	fragA.linear_velocity = linear_velocity
	# Quarter B
	var fragB: Node = quart_scene_1b.instantiate()
	fragB.add_collision_exception_with(self)
	fragB.position = position
	fragB.linear_velocity = linear_velocity
	# Remove the block from the scene
	self.get_parent().add_child(fragA)
	self.get_parent().add_child(fragB)
	self.call_deferred("queue_free")
	pass
