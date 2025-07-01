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
const PLAYER_SHIP_LASER_FLICKER_RATE: float = 5
const PLAYER_SHIP_FORCE_AMOUNT: int                    = 5000
const PLAYER_SHIP_LINEAR_DAMP: float                   = 0.9
const PLAYER_SHIP_TARGET_ROTATION_FACTOR: float        = 10
const PLAYER_SHIP_DISABLED_MSEC: int                   = 3000
const PLAYER_SHIP_DISABLED_SV_RATIO: float             = 0.38
const PLAYER_SHIP_HEATED_DISABLED_THRESHOLD_SEC: float = 2.0
# blocks
const BLOCK_BREAK_APART_VELOCITY: float = 50
const BLOCK_HALF_BREAK_APART_VELOCITY: float = BLOCK_BREAK_APART_VELOCITY / 2
const BLOCK_HEATED_BREAK_SEC: float = 1.0
const BLOCK_ACTIVATION_HEAT_THRESHOLD: float = 0.5
const BLOCK_INACTIVE_OPACITY: float = 0.38
const BLOCK_HALF_HEATED_BREAK_SEC: float = BLOCK_HEATED_BREAK_SEC / 2
const BLOCK_QUART_HEATED_BREAK_SEC: float = BLOCK_HEATED_BREAK_SEC / 4
# player ship threshold of how long to wait between launching projectile explosives
const PROJECTILE_EXPLOSIVE_COOLDOWN_MSEC: float = 500
# player ship projectile explosive initial velocity, acceleration, and max velocity
const PROJECTILE_EXPLOSIVE_INITIAL_VELOCITY: float = 200.0
const PROJECTILE_EXPLOSIVE_ACCELERATION: float     = 500.0
const PROJECTILE_EXPLOSIVE_MAX_VELOCITY: float     = 2000.0
# pertaining to explosive
const EXPLOSION_LIFETIME_MSEC: int                         = 1000
const EXPLOSION_HEAT_RADIUS_RATIO: float   = 0.7
const EXPLOSION_CRITICAL_RADIUS_BLOCK_BREAK_RATIO: float   = 0.4
const EXPLOSION_CRITICAL_RADIUS_BLOCK_SHATTER_RATIO: float = 0.3
const EXPLOSION_CRITICAL_RADIUS_SHIP_RATIO: float          = 0.4
const EXPLOSION_FORCE: int                       = 8000
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
