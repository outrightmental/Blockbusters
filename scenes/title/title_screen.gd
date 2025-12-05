extends Node2D

# Constants
const GAME_START_DELAY_SECONDS: float     = 1.0
const OPTION_NA: String                   = "n/a"
const OPTION_BOOL_TRUE: String            = "on"
const OPTION_BOOL_FALSE: String           = "off"
const OPTIONS_MENU_TITLE: String          = "OPTIONS"
const BG_MIP_LEVEL_RESOLUTION_FULL: float = 16.0
const BG_MIP_LEVEL_RESOLUTION_LOFI: float = 4.0

# Main menu items
@onready var MAIN_MENU_ITEMS: Array[Dictionary] = [
													  {"label": "START", "action": Callable(self, "do_start")},
													  {"label": "OPTIONS", "action": Callable(self, "do_open_options_menu")},
													  {"label": "EXIT", "action": Callable(self, "do_exit")},
												  ]

# Options menu items
@onready var OPTIONS_MENU_ITEMS: Array[Dictionary] = [
														 {"label": "RESOLUTION", "action": Callable(self, "do_cycle_display_resolution"), "value": Callable(self, "render_display_resolution"), "active": Callable(self, "get_is_display_resolution_active")},
														 {"label": "LIGHTING FX", "action": Callable(self, "do_toggle_lighting_fx"), "value": Callable(self, "render_lighting_fx_value"), "active": Callable(self, "get_is_lighting_fx_active")},
														 {"label": "SHADOW FX", "action": Callable(self, "do_toggle_shadow_fx"), "value": Callable(self, "render_shadow_fx_value"), "active": Callable(self, "get_is_shadow_fx_active"), "disabled": Callable(self, "get_shadow_fx_disabled")},
														 {"label": "SOUND FX", "action": Callable(self, "do_toggle_sound_fx"), "value": Callable(self, "render_sound_fx_value"), "active": Callable(self, "get_is_sound_fx_active")},
														 {"label": "DONE", "action": Callable(self, "do_close_options_menu"), "small": true},
													 ]

@onready var main_menu: Menu = $Container/MainMenu
@onready var options_menu: Menu = $Container/OptionsMenuContainer/OptionsMenu
@onready var options_menu_container: Control = $Container/OptionsMenuContainer
@onready var options_menu_bg: ColorRect = $Container/OptionsMenuContainer/ColorRect


# Start the game
func do_start() -> void:
	Util.goto_scene("res://scenes/game/game_board_screen.tscn")


# Exit the game
func do_exit() -> void:
	var tree: SceneTree = get_tree()
	if not tree:
		return
	tree.quit()


# Toggle display resolution
func do_cycle_display_resolution() -> void:
	ResolutionManager.cycle_display_resolution()
	options_menu.update()
	_setup()
	pass


# Toggle lighting FX
func do_toggle_lighting_fx() -> void:
	Game.toggle_lighting_fx()
	options_menu.update()
	pass


# Toggle shadow FX
func do_toggle_shadow_fx() -> void:
	Game.toggle_shadow_fx()
	options_menu.update()
	pass


# Toggle sound FX
func do_toggle_sound_fx() -> void:
	AudioManager.toggle_sound_fx()
	options_menu.update()
	pass


# Open the options menu
func do_open_options_menu() -> void:
	options_menu_container.show()
	options_menu.reset(true)
	options_menu.call_deferred("activate")
	main_menu.deactivate()


# Close the options menu
func do_close_options_menu() -> void:
	main_menu.call_deferred("activate")
	options_menu.deactivate()
	options_menu_container.hide()


# Get readable value for whether lighting FX is enabled
func render_lighting_fx_value() -> String:
	return OPTION_BOOL_TRUE if ConfigManager.is_lighting_fx_enabled else OPTION_BOOL_FALSE


# Get readable value for current display resolution	
func render_display_resolution() -> String:
	return ResolutionManager.get_name_of_display_resolution(ConfigManager.display_resolution)


# Get readable value for whether shadow FX is enabled
func render_shadow_fx_value() -> String:
	if not ConfigManager.is_lighting_fx_enabled:
		return OPTION_NA
	return OPTION_BOOL_TRUE if ConfigManager.is_shadow_fx_enabled else OPTION_BOOL_FALSE


# Get readable value for whether sound FX is enabled
func render_sound_fx_value() -> String:
	return OPTION_BOOL_TRUE if ConfigManager.is_sound_fx_enabled else OPTION_BOOL_FALSE


# Get a boolean whether Display Resolution option is active (currently always true)
func get_is_display_resolution_active() -> bool:
	return true


# Get a boolean whether Lighting FX is enabled
func get_is_lighting_fx_active() -> bool:
	return ConfigManager.is_lighting_fx_enabled


# Get a boolean whether Shadow FX is enabled
func get_is_shadow_fx_active() -> bool:
	return ConfigManager.is_shadow_fx_enabled


# Determine if shadow FX option should be disabled
func get_shadow_fx_disabled() -> bool:
	return not ConfigManager.is_lighting_fx_enabled


# Get a boolean whether Sound FX is enabled
func get_is_sound_fx_active() -> bool:
	return ConfigManager.is_sound_fx_enabled


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main_menu.configure(MAIN_MENU_ITEMS)
	options_menu.configure(OPTIONS_MENU_ITEMS, OPTIONS_MENU_TITLE)
	do_close_options_menu()
	_setup()


# Setup dynamic scaling for background and menu elements
func _setup() -> void:
	# Scale background to fit screen
	var mip_level: float = BG_MIP_LEVEL_RESOLUTION_FULL if ResolutionManager.is_full_resolution() else BG_MIP_LEVEL_RESOLUTION_LOFI
	options_menu_bg.material.set("shader_parameter/mip_level", mip_level)
	$Container.position = ResolutionManager.get_offset()
	
