class_name LaserBeamCluster
extends Node2D

# Player number to identify the laser beam
@export var player_num: int = 0
# Player ship to avoid self-collision
@export var source_ship: Ship = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$LaserBeamA.player_num = player_num
	$LaserBeamA.source_ship = source_ship
	$LaserBeamB.player_num = player_num
	$LaserBeamB.source_ship = source_ship
	$LaserBeamC.player_num = player_num
	$LaserBeamC.source_ship = source_ship
	$LaserBeamD.player_num = player_num
	$LaserBeamD.source_ship = source_ship
	$LaserBeamE.player_num = player_num
	$LaserBeamE.source_ship = source_ship
