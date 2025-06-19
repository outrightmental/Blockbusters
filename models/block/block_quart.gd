class_name BlockQuart
extends Collidable

# List of nodes that should not break this
@export var dont_break_by: Array[Node] = []
# Preloaded scene for the block quarter shattering
const shatter_scene: PackedScene = preload("res://models/block/block_quart_shatter.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Break the block quarter apart into dust
func do_break(broken_by: Node = null) -> void:
	# Don't break by objects in the dont_break_by list
	if broken_by in dont_break_by:
		return
	var shatter: Node = shatter_scene.instantiate()
	shatter.position = position
	self.get_parent().call_deferred("add_child", shatter)
	self.call_deferred("queue_free")
	pass
