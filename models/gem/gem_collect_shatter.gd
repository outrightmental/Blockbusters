extends CPUParticles2D

# Constants
const LIFETIME_MSEC: int = 1000
# Variables
var instantiated_at_ticks_msec: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	instantiated_at_ticks_msec = Time.get_ticks_msec()
	self.emitting = true

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Time.get_ticks_msec() - instantiated_at_ticks_msec > LIFETIME_MSEC:
		queue_free()
