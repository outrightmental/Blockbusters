class_name BlockFragment
extends Collidable


var gem: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(Global.GROUP_BLOCK_FRAGMENTS)
	pass
