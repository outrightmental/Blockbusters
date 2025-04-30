class_name Block
extends Collidable

# Constants
const BREAK_APART_VELOCITY: int = 50
const INNER_GEM_ALPHA: float    = 0.3
const LINEAR_DAMP: float        = 0.1
# Variables
var gem: Node = null

# Whether this block has a gem
@export var has_gem: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_linear_damp(LINEAR_DAMP)
	if has_gem:
		_add_gem()
	pass


# Adds a gem inside this block
func _add_gem() -> void:
	gem = preload("res://models/gem/gem.tscn").instantiate()
	gem.position = Vector2(0, 0)
	gem.add_collision_exception_with(self)
	gem.freeze = true
	gem.modulate.a = INNER_GEM_ALPHA
	self.add_child(gem)
	pass


# Break the block apart into two fragments
func do_break() -> void:
	# Fragment 1
	var frag1: Node = preload("res://models/block/block_fragment_1.tscn").instantiate()
	frag1.add_collision_exception_with(self)
	frag1.position = position
	frag1.linear_velocity = linear_velocity + Vector2(-BREAK_APART_VELOCITY, -BREAK_APART_VELOCITY)
	# Fragment 2
	var frag2: Node = preload("res://models/block/block_fragment_2.tscn").instantiate()
	frag2.add_collision_exception_with(self)
	frag2.position = position
	frag2.linear_velocity = linear_velocity + Vector2(BREAK_APART_VELOCITY, BREAK_APART_VELOCITY)
	# Gem
	if gem:
		gem = preload("res://models/gem/gem.tscn").instantiate()
		gem.add_collision_exception_with(self)
		gem.position = position
		gem.linear_velocity = linear_velocity
		gem.add_collision_exception_with(frag1)
		gem.add_collision_exception_with(frag2)
		self.get_parent().add_child(gem)
		Game.gems_in_blocks -= 1
		Game.gems_free += 1
		Game.gem_count_updated.emit()
	# Remove the block from the scene
	self.get_parent().add_child(frag1)
	self.get_parent().add_child(frag2)
	self.call_deferred("queue_free")
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Called when the block is instantiated
func _init():
	super._init()
