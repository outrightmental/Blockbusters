class_name BlockQuart
extends Heatable

# Cache reference to heated effect
@onready var heated_effect: Node2D = $HeatedEffect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	add_to_group(Game.BLOCK_QUART_GROUP)

	# Update the heated effect visibility
	_update_heated_effect()

	# Disable shadow if not enabled in settings
	if not (Game.is_shadow_fx_enabled and Game.is_lighting_fx_enabled):
		$LightOccluder2D.visible = false


# Shatter into dust
func do_shatter() -> void:
	var shatter: Node = ScenePreloader.explosive_shatter_scene.instantiate()
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
