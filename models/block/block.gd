extends "res://models/collidable/collidable.gd"


var gem: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(Global.GROUP_BLOCKS)
	add_to_group(Global.GROUP_AFFECTED_BY_EXPLOSION)

	# Roll a D6 and if it's 1, add a gem
	var random_number: int = randi() % 6 + 1
	if random_number == 1:
		_add_gem()
	pass

	

# Adds a gem inside this block
func _add_gem() -> void:
	gem = preload("res://models/gem/gem.tscn").instantiate()
	gem.set_owner(self)
	gem.add_collision_exception_with(self)
	gem.position = position
	self.get_parent().call_deferred("add_child", gem)

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if gem:
		gem.position = position
		gem.rotation = rotation
	pass

	
# Called when the block is instantiated
func _init():
	super._init()
