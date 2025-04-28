extends Node2D

# Enum for whether a grid square is empty, block, or gem
enum GridType {
	BLOCK,
	GEM,
}
# Constants
# Spawn blocks in a grid pattern, 32 blocks wide and 18 blocks tall, starting at (16, 16) and spaced 32 pixels apart
# The blocks are 32x32 pixels, so the grid is 1024x576 pixels
const GRID_COLS: int             = 32
const GRID_COUNT_MAX: int        = GRID_COLS * GRID_ROWS
const GRID_ROWS: int             = 18
const HOME_CLEARANCE_RADIUS: int = 130
const BLOCK_CENTER: int          = BLOCK_SIZE/2
const BLOCK_COUNT_MAX: int       = GRID_COUNT_MAX * BLOCK_COUNT_RATIO
const BLOCK_COUNT_RATIO: float   = 0.3 # ratio of the grid that is filled with blocks
const BLOCK_SIZE: int            = 32
const GEM_COUNT_RATIO: float     = 0.05 # ratio of the grid that is filled with gems
const GEM_COUNT_MAX: int         = GRID_COUNT_MAX * GEM_COUNT_RATIO
# Variables
var grid: Dictionary = {}
var block_count: int = 0
var gem_count: int   = 0


# Instantiate a models/ship/ship.gd for each player, so set player_num = 1 or 2 respectively, and Player 1 is 10% in from the left, vertical center, and Player 2 is 10% in from the right, vertical center.
func _ready() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_spawn_player_ship(1, Vector2(viewport_size.x * 0.08, viewport_size.y * 0.5), 0)
	_spawn_player_ship(2, Vector2(viewport_size.x * 0.92, viewport_size.y * 0.5), PI)
	_spawn_player_score(1, Vector2(viewport_size.x * 0.03, viewport_size.y * 0.5), PI/2)
	_spawn_player_score(2, Vector2(viewport_size.x * 0.97, viewport_size.y * 0.5), -PI/2)
	var player_home_1: Home            = _spawn_player_home(1, Vector2(0, viewport_size.y * 0.5), 0)
	var player_home_2: Home            = _spawn_player_home(2, Vector2(viewport_size.x, viewport_size.y * 0.5), PI)
	var home_positions: Array[Vector2] = [player_home_1.position, player_home_2.position]

	while block_count < BLOCK_COUNT_MAX:
		var x: int = randi() % GRID_COLS
		var y: int = randi() % GRID_ROWS
		if not grid.has(x):
			grid[x] = {}
		if grid[x].has(y):
			continue
		if _is_clear_of_all(HOME_CLEARANCE_RADIUS, _grid_position(x, y), home_positions):
			block_count += 1
			if gem_count < GEM_COUNT_MAX:
				grid[x][y] = GridType.GEM
				gem_count += 1
			else:
				grid[x][y] = GridType.BLOCK

	for x in range(GRID_COLS):
		for y in range(GRID_ROWS):
			if grid[x].has(y):
				_spawn_block(_grid_position(x, y), grid[x][y] == GridType.GEM)

	Game.reset_game.emit()
	pass


func _process(_delta: float) -> void:
	# if the escape key is pressed, navigate to this scene to reset the game
	if Input.is_action_just_pressed('ui_cancel'):
		print("Escape key pressed, navigating to main menu")
		get_tree().change_scene_to_file('res://scenes/play_game.tscn')
		return


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
	var ship_scene: Ship = preload('res://models/player/ship.tscn').instantiate()
	ship_scene.position = start_position
	ship_scene.player_num = num
	ship_scene.rotation = start_rotation
	self.add_child(ship_scene)
	return ship_scene


# Spawn a player home at the given position and rotation
func _spawn_player_home(num: int, start_position: Vector2, start_rotation: float) -> Home:
	var home_scene: Home = preload('res://models/player/home.tscn').instantiate()
	home_scene.position = start_position
	home_scene.player_num = num
	home_scene.rotation = start_rotation
	home_scene.z_index = -1
	self.add_child(home_scene)
	return home_scene


# Spawn a player score at the given position and rotation
func _spawn_player_score(num: int, start_position: Vector2, start_rotation: float) -> Score:
	var score_scene: Score = preload('res://models/player/score.tscn').instantiate()
	score_scene.position = start_position
	score_scene.player_num = num
	score_scene.rotation = start_rotation
	score_scene.z_index = -1
	self.add_child(score_scene)
	return score_scene


func _spawn_block(start_position: Vector2, has_gem: bool) -> Node:
	var block_scene: Block = preload('res://models/block/block.tscn').instantiate()
	block_scene.position = start_position
	block_scene.has_gem = has_gem
	self.add_child(block_scene)
	return block_scene
