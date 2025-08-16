class_name SoundEffectSetting
extends Resource
## Sound effect resource, used to configure unique sound effects for use with the AudioManager. Passed to [method AudioManager.create_2d_audio_at_location()] and [method AudioManager.create_audio()] to play sound effects.

## Stores the different types of sounds effects available to be played to distinguish them from another. 
## Each new SoundEffectSetting resource created should add to this enum, to allow them to be easily instantiated via
## [method AudioManager.create_2d_audio_at_location()] and [method AudioManager.create_audio()].
##
## DO NOT CHANGE THE ORDER OF THESE ENUMS, as they are used to index the sound_effect_dict in the AudioManager.
## Instead, add new sound effects to the end of the enum.
##
enum SOUND_EFFECT_TYPE {
	BLOCK_COLLIDES_WITH_BLOCK,
	BLOCK_COLLIDES_WITH_BLOCK_2,
	GAME_START,
	LASER_ACTIVATE,
	LASER_IMPACT_BLOCK_HEAT_UP,
	PLAYER_1_READY,
	PLAYER_2_READY,
	PLAYER_COLLECTS_GEM,
	PLAYER_COLLECTS_GEM_DOUBLE,
	PLAYER_UNREADY,
	PROJECTILE_FAIL,
	PROJECTILE_FIRE,
	PROJECTILE_IMPACT,
	SHIP_ACCELERATES_1,
	SHIP_ACCELERATES_2,
	SHIP_COLLIDES_WITH_BLOCK,
	SHIP_COLLIDES_WITH_BLOCK_2,
	SHIP_DRIFTS_1,
	SHIP_DRIFTS_2,
	BLOCK_BREAK_HALF_GEM,
	BLOCK_BREAK_HALF_NOGEM,
	BLOCK_BREAK_QUARTERS,
	BLOCK_QUARTER_SHATTER_DUST,
	SHIP_DISABLED,
	SHIP_REENABLED,
	HEATING,
	SHIP_COLLIDES_WITH_BLOCK_WHOLE,
	SHIP_COLLIDES_WITH_BLOCK_HALF,
	SHIP_COLLIDES_WITH_BLOCK_QUART,
}
@export_range(0, 10) var limit: int = 5 ## Maximum number of this SoundEffectSetting to play simultaneously before culled.
@export var sound_effect: AudioStreamMP3 ## The [AudioStreamMP3] audio resource to play.

@export_range(	-40.0, 20.0, 1.0) var volume: float = 0 ## The volume of the [member sound_effect].
@export_range(0.0, 4.0, .01) var pitch_scale: float = 1.0 ## The pitch scale of the [member sound_effect].

@export_range(0.0, 1.0, .01) var pitch_randomness: float = 0.0 ## The pitch randomness setting of the [member sound_effect].

var audio_count: int = 0 ## The instances of this [AudioStreamMP3] currently playing.


## Takes [param amount] to change the [member audio_count]. 
func change_audio_count(amount: int) -> void:
	audio_count = max(0, audio_count + amount)


## Checkes whether the audio limit is reached. Returns true if the [member audio_count] is less than the [member limit].
func has_open_limit() -> bool:
	return audio_count < limit


## Connected to the [member sound_effect]'s finished signal to decrement the [member audio_count].
func on_audio_finished() -> void:
	change_audio_count(-1)