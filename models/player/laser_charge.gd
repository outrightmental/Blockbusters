class_name LaserCharge
extends Node2D

# Constants
const AVAILABLE_FILL_COLOR_SV_RATIO: float = 0.7
const UNAVAILABLE_FILL_COLOR_SV_RATIO: float = 0.45
const BG_COLOR_SV_RATIO: float = 0.3
const CORNER_RADIUS: int = 5

# Styles
var available_fill_style = StyleBoxFlat.new()
var unavailable_fill_style = StyleBoxFlat.new()
var bg_style             = StyleBoxFlat.new()

# Player number to identify the home
@export var player_num: int = 0

# Reference Progress Bar
@onready var progress_bar: ProgressBar = $ProgressBar

# Cache previous value to determine charge/uncharge state
var previous_value: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game.player_laser_charge_updated.connect(_on_charge_updated)
	progress_bar.max_value = Config.PLAYER_SHIP_LASER_CHARGE_MAX_SEC
	_set_color()


# Set the colors of the ship based on player_num
func _set_color() -> void:
	if player_num in Config.PLAYER_COLORS:
		# Setup the available fill style
		available_fill_style.bg_color = Util.color_at_sv_ratio(Config.PLAYER_COLORS[player_num][0], AVAILABLE_FILL_COLOR_SV_RATIO)
		available_fill_style.set_corner_radius_all(CORNER_RADIUS)
		progress_bar.set("theme_override_styles/fill", available_fill_style)
		# Setup the unavailable fill style
		unavailable_fill_style.bg_color = Util.color_at_sv_ratio(Config.PLAYER_COLORS[player_num][0], UNAVAILABLE_FILL_COLOR_SV_RATIO)
		unavailable_fill_style.set_corner_radius_all(CORNER_RADIUS)
		# Setup the background color
		bg_style.bg_color = Util.color_at_sv_ratio(Config.PLAYER_COLORS[player_num][0], BG_COLOR_SV_RATIO)
		bg_style.set_corner_radius_all(CORNER_RADIUS)
		progress_bar.set("theme_override_styles/background", bg_style)
	else:
		print("No colors found for player_num: ", player_num)
	pass


# Update the laser charge for this player
func _on_charge_updated(update_player_num: int, charge_sec: float) -> void:
	if update_player_num != player_num:
		return
	# Update the progress bar value
	progress_bar.value = charge_sec
	if charge_sec > previous_value:
		if charge_sec >= Config.PLAYER_SHIP_LASER_AVAILABLE_MIN_CHARGE_SEC:
			progress_bar.set("theme_override_styles/fill", available_fill_style)
		else:
			progress_bar.set("theme_override_styles/fill", unavailable_fill_style)
	previous_value = charge_sec

	
# Update the availability of the laser for this player
func _on_availability_updated(update_player_num: int, is_available: bool) -> void:
	if update_player_num != player_num:
		return
	# Update the fill style based on availability
	if is_available:
		progress_bar.set("theme_override_styles/fill", available_fill_style)
	else:
		progress_bar.set("theme_override_styles/fill", unavailable_fill_style)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

	
