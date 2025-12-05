extends Node
# ConfigManager class which wraps the Godot ConfigFile functionality and persists all config-able values
# See also: https://docs.godotengine.org/en/stable/classes/class_configfile.html

class_name ConfigManager
# Path to the config file
const CONFIG_FILE_PATH: String = "user://config.cfg"
# ConfigFile instance
var _config_file: ConfigFile = ConfigFile.new()

# Default configuration values
var _default_config: Dictionary = {
									  "audio": {
										  "enabled": true,
									  },
									  "graphics": {
										  "resolution": DisplayResolution.Full,
										  "lighting_fx_enabled": true,
										  "shadow_fx_enabled": true,
									  },
								  }

# Display resolution options
enum DisplayResolution {
	LoFi = 1,
	Full = 2,
}


# Load the configuration from file or create default if not present
func load_config() -> void:
	var err: int = _config_file.load(CONFIG_FILE_PATH)
	if err != OK:
		print("[ConfigManager] No existing config file found. Creating default config.")
		_save_default_config()
	else:
		print("[ConfigManager] Config file loaded successfully.")
		_apply_loaded_config()


# Save the current configuration to file
func save_config() -> void:
	var err: int = _config_file.save(CONFIG_FILE_PATH)
	if err != OK:
		print("[ConfigManager] Error saving config file: %s" % err)
	else:
		print("[ConfigManager] Config file saved successfully.")


# Get a configuration value
func get_config_value(section: String, key: String) -> Variant:
	if _config_file.has_section_key(section, key):
		return _config_file.get_value(section, key)
	return null


# Set a configuration value
func set_config_value(section: String, key: String, value) -> void:
	_config_file.set_value(section, key, value)


# Save default configuration values to file
func _save_default_config() -> void:
	for section in _default_config.keys():
		for key in _default_config[section].keys():
			_config_file.set_value(section, key, _default_config[section][key])
	save_config()


# Apply loaded configuration values to the game settings
func _apply_loaded_config() -> void:
	# Audio settings
	var audio_enabled: bool = get_config_value("audio", "enabled")
	if audio_enabled != null:
		AudioManager.set_sound_fx_enabled(audio_enabled)
	# Graphics settings
	var resolution: int = get_config_value("graphics", "resolution")
	if resolution != null:
		ResolutionManager.set_display_resolution(resolution)
	var lighting_fx_enabled: bool = get_config_value("graphics", "lighting_fx_enabled")
	if lighting_fx_enabled != null:
		Game.set_lighting_fx_enabled(lighting_fx_enabled)
	var shadow_fx_enabled: bool = get_config_value("graphics", "shadow_fx_enabled")
	if shadow_fx_enabled != null:
		Game.set_shadow_fx_enabled(shadow_fx_enabled)


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	load_config()