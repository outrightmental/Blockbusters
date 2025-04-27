class_name Block
extends Collidable


const BREAK_APART_VELOCITY: int = 50


var gem: Node = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Roll a D6 and if it's 1, add a gem
	var random_number: int = randi() % 6 + 1
	if random_number == 1:
		_add_gem()
	pass

	

# Adds a gem inside this block
func _add_gem() -> void:
	gem = preload("res://models/gem/gem.tscn").instantiate()
	gem.add_collision_exception_with(self)
	gem.position = position
	self.get_parent().call_deferred("add_child", gem)
	pass

	
# Break the block apart into two fragments
func do_break() -> void:
	# Fragment 1
	var frag1:Node = preload("res://models/block/block_fragment_1.tscn").instantiate()
	frag1.add_collision_exception_with(self)
	frag1.position = position
	frag1.linear_velocity = linear_velocity + Vector2(-BREAK_APART_VELOCITY, -BREAK_APART_VELOCITY)
	self.get_parent().call_deferred("add_child", frag1)
	# Fragment 2
	var frag2:Node = preload("res://models/block/block_fragment_2.tscn").instantiate()
	frag2.add_collision_exception_with(self)
	frag2.position = position
	frag2.linear_velocity = linear_velocity + Vector2(BREAK_APART_VELOCITY, BREAK_APART_VELOCITY)
	self.get_parent().call_deferred("add_child", frag2)
	# Gem
	if gem:
		gem.add_collision_exception_with(frag1)
		gem.add_collision_exception_with(frag2)
		frag1.add_collision_exception_with(gem)
		frag2.add_collision_exception_with(gem)
	# Remove the block from the scene
	self.call_deferred("queue_free")
	pass

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if gem:
		gem.position = position
		gem.rotation = rotation
	pass

	
# Called when the block is instantiated
func _init():
	super._init()
