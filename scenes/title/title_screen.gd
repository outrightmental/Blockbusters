extends Node2D

# Constants
const GAME_START_DELAY_SECONDS: float = 1.0
const OPTION_NA: String               = "n/a"
const OPTION_BOOL_TRUE: String        = "on"
const OPTION_BOOL_FALSE: String       = "off"
const OPTIONS_MENU_TITLE: String      = "OPTIONS"

# Main menu items
@onready var MAIN_MENU_ITEMS: Array[Dictionary] = [
													  {"label": "START", "action": Callable(self, "do_start")},
													  {"label": "OPTIONS", "action": Callable(self, "do_open_options_menu")},
													  {"label": "EXIT", "action": Callable(self, "do_exit")},
												  ]

# Options menu items
@onready var OPTIONS_MENU_ITEMS: Array[Dictionary] = [
														 {"label": "LIGHTING FX", "action": Callable(self, "do_toggle_lighting_fx"), "value": Callable(self, "render_lighting_fx_value"), "active": Callable(self, "get_lighting_fx_value")},
														 {"label": "SHADOW FX", "action": Callable(self, "do_toggle_shadow_fx"), "value": Callable(self, "render_shadow_fx_value"), "active": Callable(self, "get_shadow_fx_value"), "disabled": Callable(self, "get_shadow_fx_disabled")},
														 {"label": "DONE", "action": Callable(self, "do_close_options_menu"), "small": true},
													 ]

@onready var main_menu = $MainMenu
@onready var options_menu = $OptionsMenuContainer/OptionsMenu
@onready var options_menu_container = $OptionsMenuContainer


# Start the game
func do_start() -> void:
	Util.goto_scene("res://scenes/game/game_board_screen.tscn")


# Exit the game
func do_exit() -> void:
	get_tree().quit()


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
	return OPTION_BOOL_TRUE if Game.is_lighting_fx_enabled else OPTION_BOOL_FALSE


# Get readable value for whether shadow FX is enabled
func render_shadow_fx_value() -> String:
	if not Game.is_lighting_fx_enabled:
		return OPTION_NA
	return OPTION_BOOL_TRUE if Game.is_shadow_fx_enabled else OPTION_BOOL_FALSE


# Get a boolean whether Lighting FX is enabled
func get_lighting_fx_value() -> bool:
	return Game.is_lighting_fx_enabled


# Get a boolean whether Shadow FX is enabled
func get_shadow_fx_value() -> bool:
	return Game.is_shadow_fx_enabled


# Determine if shadow FX option should be disabled
func get_shadow_fx_disabled() -> bool:
	return not Game.is_lighting_fx_enabled


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.player_ready_updated.connect(_on_player_ready_updated)
	main_menu.configure(MAIN_MENU_ITEMS)
	options_menu.configure(OPTIONS_MENU_ITEMS, OPTIONS_MENU_TITLE)
	do_close_options_menu()

	# Setup dynamic scaling
	_setup_dynamic_scaling()
	get_tree().root.size_changed.connect(_setup_dynamic_scaling)


# Setup dynamic scaling for background and menu elements
func _setup_dynamic_scaling() -> void:
	# Scale background to fit screen
	var bg = $TextureRect
	if bg:
		bg.size = ResolutionManager.get_effective_size()
		bg.position = ResolutionManager.get_offset()
	
	# Position menu at right side of screen
	var viewport_size = ResolutionManager.get_effective_size()
	if main_menu:
		main_menu.position = Vector2(viewport_size.x * 0.77, viewport_size.y * 0.47) + ResolutionManager.get_offset()
	
	# Position options menu container
	if options_menu_container:
		options_menu_container.size = viewport_size
		options_menu_container.position = ResolutionManager.get_offset()
		
	# Position options menu
	if options_menu:
		options_menu.position = Vector2(viewport_size.x * 0.49, viewport_size.y * 0.48)


# If both players are ready, start the game
func _on_player_ready_updated() -> void:
	if $ReadyP1.is_ready and $ReadyP2.is_ready:
		await Util.delay(GAME_START_DELAY_SECONDS)
		if $ReadyP1.is_ready and $ReadyP2.is_ready:
			Util.goto_scene("res://scenes/game/game_board_screen.tscn")
