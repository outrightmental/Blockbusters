extends Node2D

var instantiated_at_ticks_msec: float = 0.0
const LIFETIME_MSEC: int              = 200
const EXPLOSION_RADIUS: int           = 200
const EXPLOSION_FORCE: int            = 5000


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instantiated_at_ticks_msec = Time.get_ticks_msec()
	# Find all overlapping collidable objects
	var candidates: Array = get_tree().get_nodes_in_group(Global.GROUP_AFFECTED_BY_EXPLOSION)
	for target in candidates:
		var diff = (target.position - position)
		# Check if the collidable is within the explosion radius
		if diff.length() <= EXPLOSION_RADIUS:
			# Apply a force to the collidable
			target.apply_central_force(diff.normalized() * EXPLOSION_FORCE * (1 - diff.length() / EXPLOSION_RADIUS))
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Time.get_ticks_msec() - instantiated_at_ticks_msec > LIFETIME_MSEC:
		queue_free()
