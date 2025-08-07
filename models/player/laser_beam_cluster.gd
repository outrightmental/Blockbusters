class_name LaserBeamCluster
extends Node2D

# Player number to identify the laser beam
@export var player_num: int = 0
# Player ship to avoid self-collision
@export var source_ship: Ship = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$LaserBeamA.setup(player_num, source_ship)
	$LaserBeamB.setup(player_num, source_ship)
	$LaserBeamC.setup(player_num, source_ship)
	$LaserBeamD.setup(player_num, source_ship)
	$LaserBeamE.setup(player_num, source_ship)
	
