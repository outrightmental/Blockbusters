extends Node2D
## Audio manager node. Inteded to be globally loaded as a 2D Scene. Handles [method create_2d_audio_at_location()] and [method create_audio()] to handle the playback and culling of simultaneous sound effects.
##
## To properly use, define [enum SoundEffectSetting.SOUND_EFFECT_TYPE] for each unique sound effect, create a Node2D scene for this AudioManager script add those SoundEffectSetting resources to this globally loaded script's [member sound_effects], and setup your individual SoundEffectSetting resources. Then, use [method create_2d_audio_at_location()] and [method create_audio()] to play those sound effects either at a specific location or globally.
## 
## See https://github.com/Aarimous/AudioManager for more information.
##
## @tutorial: https://www.youtube.com/watch?v=Egf2jgET3nQ

@export var sound_effect_dict: Dictionary[SoundEffectSetting.SOUND_EFFECT_TYPE, SoundEffectSetting] ## Stores all possible SoundEffects that can be played.

## Stores currently playing sounds at the global level so they don't interfere with local objects simulation
var playing_2d_audios: Dictionary[String, AudioStreamPlayer2D] = {}


## Creates a sound effect at a specific location if the limit has not been reached. Pass [param location] for the global position of the audio effect, and [param type] for the SoundEffectSetting to be queued.
func create_2d_audio_at_location(location: Vector2, type: SoundEffectSetting.SOUND_EFFECT_TYPE, key: String = "") -> void:
	if sound_effect_dict.has(type):
		var sound_effect: SoundEffectSetting = sound_effect_dict[type]
		if sound_effect.has_open_limit():
			sound_effect.change_audio_count(1)
			var new_2D_audio: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
			add_child(new_2D_audio)
			new_2D_audio.position = location
			new_2D_audio.stream = sound_effect.sound_effect
			new_2D_audio.volume_db = sound_effect.volume
			new_2D_audio.pitch_scale = sound_effect.pitch_scale
			new_2D_audio.pitch_scale += randf_range(-sound_effect.pitch_randomness, sound_effect.pitch_randomness )
			new_2D_audio.finished.connect(sound_effect.on_audio_finished)
			new_2D_audio.finished.connect(new_2D_audio.queue_free)
			new_2D_audio.play()
			if key != "":
				playing_2d_audios[key] = new_2D_audio
				new_2D_audio.finished.connect(func() -> void: playing_2d_audios.erase(key))
	else:
		push_error("Audio Manager failed to find setting for type ", type)


## Creates a sound effect if the limit has not been reached. Pass [param type] for the SoundEffectSetting to be queued.
func create_audio(type: SoundEffectSetting.SOUND_EFFECT_TYPE) -> void:
	if sound_effect_dict.has(type):
		var sound_effect: SoundEffectSetting = sound_effect_dict[type]
		if sound_effect.has_open_limit():
			sound_effect.change_audio_count(1)
			var new_audio: AudioStreamPlayer = AudioStreamPlayer.new()
			add_child(new_audio)
			new_audio.stream = sound_effect.sound_effect
			new_audio.volume_db = sound_effect.volume
			new_audio.pitch_scale = sound_effect.pitch_scale
			new_audio.pitch_scale += randf_range(-sound_effect.pitch_randomness, sound_effect.pitch_randomness )
			new_audio.finished.connect(sound_effect.on_audio_finished)
			new_audio.finished.connect(new_audio.queue_free)
			new_audio.play()
	else:
		push_error("Audio Manager failed to find setting for type ", type)


## Stop a 2d audio effect by [param key] if it exists in the [member playing_sounds] dictionary.
func stop_2d_audio(key: String = "") -> void:
	if playing_2d_audios.has(key):
		var audio_player: AudioStreamPlayer2D = playing_2d_audios[key]
		audio_player.stop()
		audio_player.finished.emit()
		playing_2d_audios.erase(key)
	else:
		push_error("Audio Manager failed to find audio with key ", key)


## Update the global position of a 2d audio effect by [param key] if it exists in the [member playing_sounds] dictionary.
func update_2d_audio_global_position(key: String = "", gp: Vector2 = Vector2.ZERO) -> void:
	if playing_2d_audios.has(key):
		var audio_player: AudioStreamPlayer2D = playing_2d_audios[key]
		audio_player.set_global_position(gp)
	else:
		push_error("Audio Manager failed to find audio with key ", key)
