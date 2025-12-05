\
extends Node
# ConfigManager class which wraps the Godot ConfigFile functionality and persists all config-able values
# See also: https://docs.godotengine.org/en/stable/classes/class_configfile.html

# Configurable properties
@export var is_sound_fx_enabled: bool = true
@export var display_resolution: DisplayResolution = DisplayResolution.Full
@export var is_lighting_fx_enabled: bool = true
@export var is_shadow_fx_enabled: bool = true
# Path to the config file
const CONFIG_FILE_PATH: String = "user://blockbusters.cfg"
# ConfigFile instance
var _config_file: ConfigFile = ConfigFile.new()

# Default configuration values
var _default_config: Dictionary = {
									  "audio": {
										  "sound_fx_enabled": true,
									  },
									  "graphics": {
										  "display_resolution": DisplayResolution.Full,
										  "lighting_fx_enabled": true,
										  "shadow_fx_enabled": true,
									  },
								  }

# Display resolution options
enum DisplayResolution {
	LoFi = 1,
	Full = 2,
}


# Setter for is_sound_fx_enabled
func set_sound_fx_enabled(value: bool) -> void:
	is_sound_fx_enabled = value
	_set_config_value("audio", "sound_fx_enabled", value)
	_save_config()


# Setter for display resolution
func set_display_resolution(value: DisplayResolution) -> void:
	display_resolution = value
	_set_config_value("graphics", "display_resolution", value)
	_save_config()


# Setter for lighting FX enabled
func set_lighting_fx_enabled(value: bool) -> void:
	is_lighting_fx_enabled = value
	_set_config_value("graphics", "lighting_fx_enabled", value)
	_save_config()


# Setter for shadow FX enabled
func set_shadow_fx_enabled(value: bool) -> void:
	is_shadow_fx_enabled = value
	_set_config_value("graphics", "shadow_fx_enabled", value)
	_save_config()


# Load the configuration from file or create default if not present
func _load_config() -> void:
	var err: int = _config_file.load(CONFIG_FILE_PATH)
	if err != OK:
		print("[ConfigManager] No existing config file found. Creating default config.")
		_save_default_config()
	else:
		print("[ConfigManager] Config file loaded successfully.")
		_apply_loaded_config()


# Parse command line arguments to override config settings
func _parse_command_line_args() -> void:
	var args: Array = OS.get_cmdline_args()
	for arg in args:
		match arg:
			"--display-resolution-lofi":
				set_display_resolution(DisplayResolution.LoFi)
			"--display-resolution-full":
				set_display_resolution(DisplayResolution.Full)
			"--no-lighting-fx":
				set_lighting_fx_enabled(false)
			"--no-shadow-fx":
				set_shadow_fx_enabled(false)
			"--no-sound-fx":
				set_sound_fx_enabled(false)
			_:
				# Ignore unknown arguments
				pass


# Save the current configuration to file
func _save_config() -> void:
	var err: int = _config_file.save(CONFIG_FILE_PATH)
	if err != OK:
		print("[ConfigManager] Error saving config file: %s" % err)
	else:
		print("[ConfigManager] Config file saved successfully.")


# Get a configuration value
func _get_config_value(section: String, key: String) -> Variant:
	if _config_file.has_section_key(section, key):
		return _config_file.get_value(section, key)
	return _default_config[section][key]


# Set a configuration value
func _set_config_value(section: String, key: String, value) -> void:
	_config_file.set_value(section, key, value)


# Save default configuration values to file
func _save_default_config() -> void:
	for section in _default_config.keys():
		for key in _default_config[section].keys():
			_config_file.set_value(section, key, _default_config[section][key])
	_save_config()


# Apply loaded configuration values to the game settings
func _apply_loaded_config() -> void:
	is_sound_fx_enabled = _get_config_value("audio", "sound_fx_enabled")
	display_resolution   = _get_config_value("graphics", "display_resolution")
	is_lighting_fx_enabled = _get_config_value("graphics", "lighting_fx_enabled")
	is_shadow_fx_enabled   = _get_config_value("graphics", "shadow_fx_enabled")


# Called when the node enters the scene tree for the first time
func _ready() -> void:
	_load_config()
	_parse_command_line_args()
