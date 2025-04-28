extends Node

# All available signals -- use these constants to reference them to avoid typos
signal reset_game
signal update_score(score: Dictionary)
signal projectile_explosive_launched(player_num: int, projectile: Node)


