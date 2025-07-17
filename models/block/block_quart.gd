class_name BlockQuart
extends Collidable

# List of nodes that should not break this
@export var dont_break_by: Array[Node] = []
# Preloaded scene for the block quarter shattering
const shatter_scene: PackedScene = preload("res://models/block/block_quart_shatter.tscn")
# variable for being heated
var heated_sec: float   = 0.0
var heated_delta: float = 0.0

# Cache reference to heated effect
@onready var heated_effect: Node2D = $HeatedEffect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Update the heated effect visibility
	_update_heated_effect()
	pass


# Break the block quarter apart into dust
func do_break(broken_by: Node = null, _level: int = 1) -> void:
	# Don't break by objects in the dont_break_by list
	if broken_by in dont_break_by:
		return
	do_shatter()
	
# Shatter into dust
func do_shatter() -> void:
	var shatter: Node = shatter_scene.instantiate()
	shatter.position = position
	self.get_parent().call_deferred("add_child", shatter)
	self.call_deferred("queue_free")


# Add heat
func do_heat(delta: float) -> void:
	heated_delta += delta
	pass


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	_update_heat(_delta)
	pass


# If the ship is heated, increase the heated time, otherwise decrease it
# If the ship is heated for too long, disable it
func _update_heat(delta: float) -> void:
	if heated_delta > 0:
		heated_sec += heated_delta
		heated_delta = 0.0
		_update_heated_effect()
		if heated_sec >= Config.BLOCK_HALF_HEATED_BREAK_SEC:
			call_deferred("do_break")
	elif heated_sec > 0:
		heated_sec -= delta
		if heated_sec < 0:
			heated_sec = 0.0
		_update_heated_effect()
	pass


# Update the heated effect visibility and intensity
func _update_heated_effect() -> void:
	if heated_effect == null:
		return  # Ensure heated_effect is valid before proceeding
	if heated_sec > 0:
		heated_effect.set_visible(true)
		heated_effect.modulate.a = clamp(heated_sec / Config.BLOCK_HALF_HEATED_BREAK_SEC, 0.0, 1.0)
	else:
		heated_effect.set_visible(false)
	pass
