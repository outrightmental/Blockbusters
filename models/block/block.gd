extends "res://models/collidable/collidable.gd"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(Global.GROUP_BLOCKS)
	add_to_group(Global.GROUP_AFFECTED_BY_EXPLOSION)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

	
# Called when the block is instantiated
func _init():
	super._init()
