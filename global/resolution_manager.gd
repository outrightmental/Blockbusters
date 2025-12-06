extends Node

# Resolution Manager - handles dynamic display resolution adaptation
# Provides scaling and positioning utilities for adapting game content to any display size

# Signal for after the display resolution changes
signal display_resolution_changed
# Base design resolution (logical coordinates)
const BASE_WIDTH: float        = 1024.0
const BASE_HEIGHT: float       = 576.0
const BASE_ASPECT_RATIO: float = BASE_WIDTH / BASE_HEIGHT  # 16:9 = 1.778
# Bleed margin percentage (10% on all sides)
const BLEED_MARGIN: float = 0.1
# Cached values
var _viewport_size: Vector2  = Vector2.ZERO
var _effective_size: Vector2 = Vector2.ZERO
var _scale_factor: float     = 1.0
var _offset: Vector2         = Vector2.ZERO
var _center: Vector2         = Vector2.ZERO
# Store display resolution options in an array
const DISPLAY_RESOLUTION_OPTIONS: Array[ConfigManager.DisplayResolution] = [
																		   ConfigManager.DisplayResolution.LoFi,
																		   ConfigManager.DisplayResolution.Full,
																		   ]
# Store the string names of each display resolution value
const DISPLAY_RESOLUTION_NAMES: Dictionary = {
												 ConfigManager.DisplayResolution.LoFi: "LoFi (~580p)",
												 ConfigManager.DisplayResolution.Full: "Full (Unlimited)",
											 }


# Cycle the current display resolution option
func cycle_display_resolution() -> void:
	var current_index: int = DISPLAY_RESOLUTION_OPTIONS.find(ConfigManager.display_resolution)
	var next_index: int    = (current_index + 1) % DISPLAY_RESOLUTION_OPTIONS.size()
	ConfigManager.set_display_resolution(DISPLAY_RESOLUTION_OPTIONS[next_index])
	print("[ResolutionManager] Display resolution set to: %s" % get_name_of_display_resolution(ConfigManager.display_resolution))
	_setup_then_broadcast()


# Get the string representation of a display resolution option
func get_name_of_display_resolution(resolution: ConfigManager.DisplayResolution) -> String:
	if DISPLAY_RESOLUTION_NAMES.has(resolution):
		return DISPLAY_RESOLUTION_NAMES[resolution]
	return "Unknown"


# Check if current display resolution is Full
func is_full_resolution() -> bool:
	return ConfigManager.display_resolution == ConfigManager.DisplayResolution.Full


# Called when the node enters the scene tree
# Connect to window size changes
# Do initial calculation
func _ready() -> void:
	var tree: SceneTree = get_tree()
	if tree:
		tree.root.size_changed.connect(_setup_then_broadcast)
	_setup_then_broadcast()


# Calculate scaling factors and effective viewport size
func _setup_then_broadcast() -> void:
	_setup()
	display_resolution_changed.emit()


# Calculate scaling factors and effective viewport size
func _setup() -> void:
	if is_full_resolution():
		get_window().content_scale_mode = Window.ContentScaleMode.CONTENT_SCALE_MODE_CANVAS_ITEMS
	else:
		get_window().content_scale_mode = Window.ContentScaleMode.CONTENT_SCALE_MODE_VIEWPORT

	# Get current viewport size
	_viewport_size = get_viewport().get_visible_rect().size

	# Calculate scale factor to fit base resolution in viewport
	var scale_x: float = _viewport_size.x / BASE_WIDTH
	var scale_y: float = _viewport_size.y / BASE_HEIGHT

	# Use the smaller scale to maintain aspect ratio (letterbox/pillarbox)
	_scale_factor = min(scale_x, scale_y)

	# Calculate effective size (scaled base resolution)
	_effective_size = Vector2(BASE_WIDTH, BASE_HEIGHT) * _scale_factor

	# Calculate offset to center the content
	# Offset the board (which is 16x9) to be centered in the viewport, depending on whether the viewport has extra width or extra height, the board will either have y=0 or x=0
	var viewport_width: float  = _viewport_size.x
	var viewport_height: float = _viewport_size.y
	var board_offset_x: float  = 0.0
	var board_offset_y: float  = 0.0
	if viewport_width / viewport_height >= BASE_ASPECT_RATIO:
		# Viewport is wider than 16:9, so center horizontally
		board_offset_x = (viewport_width - (viewport_height * BASE_ASPECT_RATIO)) * 0.5
	else:
		# Viewport is taller than 16:9, so center vertically
		board_offset_y = (viewport_height - (viewport_width / BASE_ASPECT_RATIO)) * 0.5
	_offset = Vector2(board_offset_x, board_offset_y)

	# Calculate center point
	_center = _offset + (_effective_size * 0.5)

	# Set the window's content scale factor
	get_window().content_scale_factor = 1/_scale_factor

	# Debug output
	print("[ResolutionManager] Viewport: %s, Scale: %.2f, Effective: %s, Offset: %s" % [_viewport_size, _scale_factor, _effective_size, _offset])


# Get the current viewport size (physical display size)
func get_viewport_size() -> Vector2:
	return _viewport_size


# Get the effective game area size (scaled base resolution)
func get_effective_size() -> Vector2:
	return _effective_size


# Get the scale factor (physical pixels per logical pixel)
func get_scale_factor() -> float:
	return _scale_factor


# Get the offset for centering content
func get_offset() -> Vector2:
	return _offset


# Get the center point of the effective area
func get_center() -> Vector2:
	return _center


# Convert logical coordinates to physical screen coordinates
func logical_to_physical(logical_pos: Vector2) -> Vector2:
	return logical_pos * _scale_factor + _offset


# Convert physical screen coordinates to logical coordinates
func physical_to_logical(physical_pos: Vector2) -> Vector2:
	return (physical_pos - _offset) / _scale_factor


# Get safe area bounds (accounting for 10% bleed margin)
func get_safe_area_rect() -> Rect2:
	var margin_x: float = BASE_WIDTH * BLEED_MARGIN
	var margin_y: float = BASE_HEIGHT * BLEED_MARGIN
	return Rect2(
		margin_x,
		margin_y,
		BASE_WIDTH - (margin_x * 2.0),
		BASE_HEIGHT - (margin_y * 2.0)
	)


# Get bleed area bounds (full area including margins)
func get_bleed_area_rect() -> Rect2:
	return Rect2(0, 0, BASE_WIDTH, BASE_HEIGHT)


# Clamp position to safe area
func clamp_to_safe_area(pos: Vector2) -> Vector2:
	var safe_area: Rect2 = get_safe_area_rect()
	return Vector2(
		clamp(pos.x, safe_area.position.x, safe_area.position.x + safe_area.size.x),
		clamp(pos.y, safe_area.position.y, safe_area.position.y + safe_area.size.y)
	)


# Get half viewport size for table mode (each player gets half the screen)
func get_table_mode_half_size() -> Vector2:
	return Vector2(_viewport_size.x * 0.5, _viewport_size.y)


# Get effective size for table mode viewport (each SubViewport)
func get_table_mode_effective_size() -> Vector2:
	# Each player gets half the physical display width
	var half_width: float = _viewport_size.x * 0.5

	# Calculate scale for half-width
	var scale_x: float = half_width / BASE_WIDTH
	var scale_y: float = _viewport_size.y / BASE_HEIGHT

	# Use smaller scale to maintain aspect ratio
	var table_scale: float = min(scale_x, scale_y)

	return Vector2(BASE_WIDTH, BASE_HEIGHT) * table_scale
