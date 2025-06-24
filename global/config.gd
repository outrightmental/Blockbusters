extends Node

# This is a dictionary of player colors, where the key is the player ID and the value is an array of two colors.
const PLAYER_COLORS: Dictionary = {
									  1: [Color(1.0, 0.0, 0.894, 1.0), Color(0.733, 0.0, 0.655, 1.0)], # Pink
									  2: [Color(0.0, 0.722, 1.0, 1.0), Color(0.0, 0.529, 0.733, 1.0)]   # Blue
								  }
# player ship threshold that's rotation only (strafe) before applying force
const PLAYER_SHIP_STRAFE_THRESHOLD_MSEC: float = 500
# player ship laser
const PLAYER_SHIP_LASER_CHARGE_MAX_SEC: float = 3
const PLAYER_SHIP_LASER_RECHARGE_RATE: float = 0.5
const PLAYER_SHIP_LASER_AVAILABLE_MIN_CHARGE_SEC: float = 1
# player ship threshold of how long to wait between launching projectile explosives
const PLAYER_SHIP_PROJECTILE_EXPLOSIVE_COOLDOWN_MSEC: float = 500
# player ship projectile explosive initial velocity, acceleration, and max velocity
const PLAYER_SHIP_PROJECTILE_EXPLOSIVE_INITIAL_VELOCITY: float = 200.0
const PLAYER_SHIP_PROJECTILE_EXPLOSIVE_ACCELERATION: float     = 500.0
const PLAYER_SHIP_PROJECTILE_EXPLOSIVE_MAX_VELOCITY: float     = 2000.0
# player initial score
const PLAYER_INITIAL_SCORE: int      = 3
const PLAYER_VICTORY_SCORE: int      = 10
const PLAYER_COLLECT_GEM_VALUE: int  = 2
const PLAYER_DISABLE_SHIP_VALUE: int = 0
# Formatting template for player input
const player_input_mapping_format: Dictionary = {
													"left": "p%d_left",
													"right": "p%d_right",
													"up": "p%d_up",
													"down": "p%d_down",
													"action_a": "p%d_action_a",
													"action_b": "p%d_action_b",
													"start": "p%d_start",
												}
