class_name Gem
extends Collidable

# Player number to identify the ship
@export var player_num: int      = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(Game.GEM_GROUP)

	# Disable lighting if not enabled in settings
	if not Game.is_lighting_enabled:
		$PointLight2D.enabled = false


func do_shatter() -> void:
	var shatter: Node = ScenePreloader.explosive_shatter_scene.instantiate()
	shatter.position = position
	self.get_parent().call_deferred("add_child", shatter)
	self.call_deferred("queue_free")
	pass
