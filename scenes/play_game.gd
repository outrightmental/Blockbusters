extends Node2D

# Enum for whether a grid square is empty, block, or gem
enum GridType {
	EMPTY,
	BLOCK,
}
# Constants
# Spawn blocks in a grid pattern, 32 blocks wide and 18 blocks tall, starting at (16, 16) and spaced 32 pixels apart
# The blocks are 32x32 pixels, so the grid is 1024x576 pixels
const BLOCK_CENTER: int              = BLOCK_SIZE/2
const BLOCK_SIZE: int                = 32
const GRID_COLS: int                 = 32
const GRID_ROWS: int                 = 18
const GAP_COL_MAX: int               = 25
const GAP_COUNT: int                 = 60
const GAP_SPACING: int               = 50
const GAP_CLEARANCE_RADIUS: int      = 40
const GAP_CURSOR_ANGLE_DELTA3: float = PI / 20
const HOME_CLEARANCE_RADIUS: int     = 130
# Variables
var grid: Dictionary = {}


# Instantiate a models/ship/ship.gd for each player, so set player_num = 1 or 2 respectively, and Player 1 is 10% in from the left, vertical center, and Player 2 is 10% in from the right, vertical center.
func _ready() -> void:
	SignalBus.reset_game.emit()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_spawn_player_ship(1, Vector2(viewport_size.x * 0.05, viewport_size.y * 0.5), 0)
	_spawn_player_ship(2, Vector2(viewport_size.x * 0.95, viewport_size.y * 0.5), PI)
	var player_home_1: Home            = _spawn_player_home(1, Vector2(0, viewport_size.y * 0.5), 0)
	var player_home_2: Home            = _spawn_player_home(2, Vector2(viewport_size.x, viewport_size.y * 0.5), PI)
	var home_positions: Array[Vector2] = [player_home_1.position, player_home_2.position]

	# Pick locations for gaps by winding a snake through the board
	var gap_cursor_position: Vector2   = player_home_1.position
	var gap_cursor_angle: float        = PI / 4
	var gap_cursor_angle_delta: float  = 0.0
	var gap_cursor_angle_delta2: float = 0.0
	var gap_positions: Array[Vector2]  = []
	for i in range(GAP_COUNT):
		gap_cursor_angle_delta2 += GAP_CURSOR_ANGLE_DELTA3 if randi() % 2 == 0 else -GAP_CURSOR_ANGLE_DELTA3
		gap_cursor_angle_delta += gap_cursor_angle_delta2
		gap_cursor_angle += gap_cursor_angle_delta
		gap_cursor_angle = clamp(gap_cursor_angle, -PI, PI)
		gap_cursor_position += Vector2(GAP_SPACING * cos(gap_cursor_angle), GAP_SPACING * sin(gap_cursor_angle))
		gap_cursor_position.x = wrapf(gap_cursor_position.x, 0, viewport_size.x)
		gap_cursor_position.y = wrapf(gap_cursor_position.y, 0, viewport_size.y)
		gap_positions.append(Vector2(gap_cursor_position.x, gap_cursor_position.y))
		gap_positions.append(Vector2(viewport_size.x - gap_cursor_position.x, viewport_size.y - gap_cursor_position.y))

	#	var grid_pos: Vector2
	for x in range(GRID_COLS):
		for y in range(GRID_ROWS):
			if (!grid.has(x)):
				grid[x] = {}
			if (_is_clear_of_all(HOME_CLEARANCE_RADIUS, _grid_position(x, y), home_positions)
			and _is_clear_of_all(GAP_CLEARANCE_RADIUS, _grid_position(x, y), gap_positions)):
				grid[x][y] = GridType.BLOCK
			else:
				grid[x][y] = GridType.EMPTY

	for x in range(GRID_COLS):
		for y in range(GRID_ROWS):
			if grid[x][y] == GridType.BLOCK:
				# Spawn a block at the grid position
				# The blocks are 32x32 pixels, so the grid is 1024x576 pixels
				# The center of the block is at (BLOCK_CENTER + x * BLOCK_SIZE, BLOCK_CENTER + y * BLOCK_SIZE)
				_spawn_block(_grid_position(x, y))

	pass


func _is_clear_of_all(distance: int, source: Vector2, targets: Array[Vector2]) -> bool:
	for target in targets:
		if not _is_clear_of(distance, source, target):
			return false
	return true


func _is_clear_of(distance: int, source: Vector2, target: Vector2) -> bool:
	return source.distance_to(target) >= distance


func _grid_position(x: int, y: int) -> Vector2:
	# Convert grid coordinates to world coordinates
	return Vector2( BLOCK_CENTER + x * BLOCK_SIZE, BLOCK_CENTER + y * BLOCK_SIZE)


# Spawn a player ship at the given position and rotation
func _spawn_player_ship(num: int, start_position: Vector2, start_rotation: float) -> Ship:
	var ship_scene: Ship = preload('res://models/ship/ship.tscn').instantiate()
	ship_scene.position = start_position
	ship_scene.player_num = num
	ship_scene.rotation = start_rotation
	self.add_child(ship_scene)
	return ship_scene


# Spawn a player home at the given position and rotation
func _spawn_player_home(num: int, start_position: Vector2, start_rotation: float) -> Home:
	var home_scene: Home = preload('res://models/ship/home.tscn').instantiate()
	home_scene.position = start_position
	home_scene.player_num = num
	home_scene.rotation = start_rotation
	home_scene.z_index = -1
	self.add_child(home_scene)
	return home_scene


func _spawn_block(start_position: Vector2) -> Node:
	var block_scene: Block = preload('res://models/block/block.tscn').instantiate()
	block_scene.position = start_position
	self.add_child(block_scene)
	return block_scene
