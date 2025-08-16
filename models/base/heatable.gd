class_name Heatable
extends Collidable

# Variables for being heated
var heat: float         = 0.0
var heat_delta: float   = 0.0
var last_heated_at: int = 0
var heating: bool       = false

@onready var heating_audio_key: String = "heating_%d" % number


# Apply heat
func apply_heat(delta: float) -> void:
	heat_delta += delta
	pass


# If heat has been applied, increase the total heat, or decrease it if no heat has been applied
func _physics_process(delta):
	super._physics_process(delta)

	if heat_delta > 0:
		heat += heat_delta
		heat_delta = 0.0
		last_heated_at = Time.get_ticks_msec()
		if not heating:
			heating = true
			AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.HEATING, heating_audio_key)
	elif heat > 0:
		heat -= delta
		if heat < 0:
			heat = 0.0
	if heating:
		AudioManager.update_2d_audio_global_position(heating_audio_key, global_position)
		if Time.get_ticks_msec() - last_heated_at > Constant.HEATING_TIMEOUT_MSEC:
			heating = false
			AudioManager.stop_2d_audio(heating_audio_key)
	pass
	