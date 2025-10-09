class_name HudEnergy
extends Node2D

# Constants
const AVAILABLE_FILL_COLOR_SV_RATIO: float   = 0.7
const UNAVAILABLE_FILL_COLOR_SV_RATIO: float = 0.45
const BG_COLOR_SV_RATIO: float               = 0.3
const CORNER_RADIUS: int                     = 5
# Styles
var available_fill_style   = StyleBoxFlat.new()
var unavailable_fill_style = StyleBoxFlat.new()
var bg_style               = StyleBoxFlat.new()

# Player number to identify the home
@export var player_num: int = 0

# Reference Progress Bar
@onready var progress_bar: ProgressBar = $ProgressBar

# Track whether the energy is available
var is_available: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.player_energy_updated.connect(_on_update)
	progress_bar.max_value = 1.0
	_set_color()


# Set the colors of the ship based on player_num
func _set_color() -> void:
	if player_num in Constant.PLAYER_COLORS:
		# Setup the available fill style
		available_fill_style.bg_color = Util.color_at_sv_ratio(Constant.PLAYER_COLORS[player_num][0], AVAILABLE_FILL_COLOR_SV_RATIO)
		available_fill_style.set_corner_radius_all(CORNER_RADIUS)
		# Setup the unavailable fill style
		unavailable_fill_style.bg_color = Util.color_at_sv_ratio(Constant.PLAYER_COLORS[player_num][0], UNAVAILABLE_FILL_COLOR_SV_RATIO)
		unavailable_fill_style.set_corner_radius_all(CORNER_RADIUS)
		# Setup the background color
		bg_style.bg_color = Util.color_at_sv_ratio(Constant.PLAYER_COLORS[player_num][0], BG_COLOR_SV_RATIO)
		bg_style.set_corner_radius_all(CORNER_RADIUS)
		progress_bar.set("theme_override_styles/background", bg_style)
		# Set the inital energy level
		_on_update(player_num, 1.0, true)
	else:
		push_error("No colors found for player_num: ", player_num)
	pass


# Update the laser charge for this player
func _on_update(update_player_num: int, charge_ratio: float, _is_available: bool) -> void:
	if update_player_num != player_num:
		return
	progress_bar.value = charge_ratio
	# Update the fill style based on availability
	if is_available == _is_available:
		return
	is_available = _is_available
	if is_available:
		progress_bar.set("theme_override_styles/fill", available_fill_style)
	else:
		progress_bar.set("theme_override_styles/fill", unavailable_fill_style)


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	pass

	
