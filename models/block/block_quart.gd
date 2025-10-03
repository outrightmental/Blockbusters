class_name BlockQuart
extends Heatable

# Preloaded scene for the block quarter shattering
const shatter_scene: PackedScene = preload("res://models/explosive/shatter.tscn")
# Cache reference to heated effect
@onready var heated_effect: Node2D = $HeatedEffect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()

	# Update the heated effect visibility
	_update_heated_effect()


# Shatter into dust
func do_shatter() -> void:
	var shatter: Node = shatter_scene.instantiate()
	shatter.position = position
	self.get_parent().call_deferred("add_child", shatter)
	self.call_deferred("queue_free")
	# Play sound effect
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.BLOCK_QUARTER_SHATTER_DUST)


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_heated_effect()


# Update the heated effect visibility and intensity
func _update_heated_effect() -> void:
	if heat >= Constant.BLOCK_HALF_HEATED_BREAK_SEC:
		do_shatter()
		return
	if heated_effect == null:
		return
	if heat > 0:
		heated_effect.set_visible(true)
		heated_effect.modulate.a = clamp(heat / Constant.BLOCK_HALF_HEATED_BREAK_SEC, 0.0, 1.0)
	else:
		heated_effect.set_visible(false)
	pass
