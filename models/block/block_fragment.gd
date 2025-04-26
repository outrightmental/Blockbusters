extends "res://models/collidable/collidable.gd"


var gem: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(Global.GROUP_BLOCK_FRAGMENTS)
	add_to_group(Global.GROUP_AFFECTED_BY_EXPLOSION)
	pass
