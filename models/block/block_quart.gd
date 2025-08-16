class_name BlockQuart
extends Collidable

# Preloaded scene for the block quarter shattering
const shatter_scene: PackedScene = preload("res://models/block/block_quart_shatter.tscn")
# variable for being heated
var heat: float   = 0.0
var heat_delta: float = 0.0

# Cache reference to heated effect
@onready var heated_effect: Node2D = $HeatedEffect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Update the heated effect visibility
	_update_heated_effect()
	pass


# Shatter into dust
func do_shatter() -> void:
	var shatter: Node = shatter_scene.instantiate()
	shatter.position = position
	self.get_parent().call_deferred("add_child", shatter)
	self.call_deferred("queue_free")
	# Play sound effect
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.BLOCK_QUARTER_SHATTER_DUST)

# Apply heat
func apply_heat(delta: float) -> void:
	heat_delta += delta
	pass


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	_update_heat(_delta)
	pass


# If the ship is heated, increase the heated time, otherwise decrease it
# If the ship is heated for too long, disable it
func _update_heat(delta: float) -> void:
	if heat_delta > 0:
		heat += heat_delta
		heat_delta = 0.0
		_update_heated_effect()
		if heat >= Constant.BLOCK_HALF_HEATED_BREAK_SEC:
			call_deferred("do_shatter")
	elif heat > 0:
		heat -= delta
		if heat < 0:
			heat = 0.0
		_update_heated_effect()
	pass


# Update the heated effect visibility and intensity
func _update_heated_effect() -> void:
	if heated_effect == null:
		return  # Ensure heated_effect is valid before proceeding
	if heat > 0:
		heated_effect.set_visible(true)
		heated_effect.modulate.a = clamp(heat / Constant.BLOCK_HALF_HEATED_BREAK_SEC, 0.0, 1.0)
	else:
		heated_effect.set_visible(false)
	pass
