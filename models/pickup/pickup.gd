class_name Pickup
extends Collidable

# Preloaded scene for the splash effect
const splash_scene: PackedScene = preload("res://models/explosive/splash.tscn")
@export var type: Game.InventoryItemType = Game.InventoryItemType.EMPTY


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(Game.PICKUP_GROUP)
	pass


# Pickup item
func do_pickup() -> void:
	var splash: Node = splash_scene.instantiate()
	splash.position = position
	self.get_parent().call_deferred("add_child", splash)
	self.call_deferred("queue_free")
	# Play sound effect
	AudioManager.create_2d_audio_at_location(global_position, SoundEffectSetting.SOUND_EFFECT_TYPE.BLOCK_QUARTER_SHATTER_DUST)
