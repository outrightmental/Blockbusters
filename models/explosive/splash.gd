extends CPUParticles2D

# Constants
const LIFETIME_SEC: float = 1.0
# Variables
var alive_sec: float = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.emitting = true


# Called at a fixed rate. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	alive_sec += delta
	if alive_sec > LIFETIME_SEC:
		queue_free()
