class_name Block
extends Collidable

# Constants
const BREAK_APART_VELOCITY: int = 50
const INNER_GEM_ALPHA: float    = 0.3
const LINEAR_DAMP: float        = 0.1
# Variables
var gem: Node = null

# Preloaded scenes
const half1_scene: PackedScene = preload("res://models/block/block_half_1.tscn")
const half2_scene: PackedScene = preload("res://models/block/block_half_2.tscn")
const gem_scene: PackedScene = preload("res://models/gem/gem.tscn")

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
	gem = gem_scene.instantiate()
	gem.position = Vector2(0, 0)
	gem.add_collision_exception_with(self)
	gem.freeze = true
	gem.modulate.a = INNER_GEM_ALPHA
	self.add_child(gem)
	pass


# Break the block apart into two halves
func do_break() -> void:
	# Half 1
	var half1: Node = half1_scene.instantiate()
	half1.add_collision_exception_with(self)
	half1.position = position
	half1.linear_velocity = linear_velocity + Vector2(-BREAK_APART_VELOCITY, -BREAK_APART_VELOCITY)
	half1.half_num = 1
	# Half 2
	var half2: Node = half2_scene.instantiate()
	half2.add_collision_exception_with(self)
	half2.position = position
	half2.linear_velocity = linear_velocity + Vector2(BREAK_APART_VELOCITY, BREAK_APART_VELOCITY)
	half2.half_num = 2
	# Gem
	if gem:
		gem = gem_scene.instantiate()
		gem.add_collision_exception_with(self)
		gem.position = position
		gem.linear_velocity = linear_velocity
		gem.add_collision_exception_with(half1)
		gem.add_collision_exception_with(half2)
		self.get_parent().call_deferred("add_child", gem)
		Game.gems_in_blocks -= 1
		Game.gems_free += 1
		Game.gem_count_updated.emit()
	# Remove the block from the scene
	self.get_parent().call_deferred("add_child", half1)
	self.get_parent().call_deferred("add_child", half2)
	self.call_deferred("queue_free")
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


# Called when the block is instantiated
func _init():
	super._init()
