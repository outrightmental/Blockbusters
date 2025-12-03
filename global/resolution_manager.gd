extends Node

# Resolution Manager - handles dynamic display resolution adaptation
# Provides scaling and positioning utilities for adapting game content to any display size

# Base design resolution (logical coordinates)
const BASE_WIDTH: float = 1024.0
const BASE_HEIGHT: float = 576.0
const BASE_ASPECT_RATIO: float = BASE_WIDTH / BASE_HEIGHT  # 16:9 = 1.778

# Bleed margin percentage (10% on all sides)
const BLEED_MARGIN: float = 0.1

# Cached values
var _viewport_size: Vector2 = Vector2.ZERO
var _effective_size: Vector2 = Vector2.ZERO
var _scale_factor: float = 1.0
var _offset: Vector2 = Vector2.ZERO
var _center: Vector2 = Vector2.ZERO


# Called when the node enters the scene tree
func _ready() -> void:
	# Connect to window size changes
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	# Initial calculation
	_calculate_scaling()


# Calculate scaling factors and effective viewport size
func _calculate_scaling() -> void:
	_viewport_size = get_viewport().get_visible_rect().size
	
	# Calculate scale factor to fit base resolution in viewport
	var scale_x: float = _viewport_size.x / BASE_WIDTH
	var scale_y: float = _viewport_size.y / BASE_HEIGHT
	
	# Use the smaller scale to maintain aspect ratio (letterbox/pillarbox)
	_scale_factor = min(scale_x, scale_y)
	
	# Calculate effective size (scaled base resolution)
	_effective_size = Vector2(BASE_WIDTH, BASE_HEIGHT) * _scale_factor
	
	# Calculate offset to center the content
	_offset = (_viewport_size - _effective_size) * 0.5
	
	# Calculate center point
	_center = _offset + (_effective_size * 0.5)
	
	print("[ResolutionManager] Viewport: %s, Scale: %.2f, Effective: %s, Offset: %s" % [_viewport_size, _scale_factor, _effective_size, _offset])


# Called when viewport size changes
func _on_viewport_size_changed() -> void:
	_calculate_scaling()


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
