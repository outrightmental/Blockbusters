class_name Heatable
extends Collidable

# Variables for being heated
var heat: float         = 0.0
var heat_delta: float   = 0.0
var heat_for_sec: float = 0.0
var heating: bool       = false
var heatable: bool      = true


# Apply heat
func apply_heat(delta: float) -> void:
	if heatable:
		heat_delta += delta
	pass


# If heat has been applied, increase the total heat, or decrease it if no heat has been applied
func _physics_process(delta):
	if heat_delta > 0:
		heat += heat_delta
		heat_delta = 0.0
		heat_for_sec = Constant.HEATING_TIMEOUT_SEC
		heating = true
	elif heat > 0:
		heat -= delta
		if heat < 0:
			heat = 0.0
	elif heating:
		heat_for_sec -= delta
		if heat_for_sec <= 0:
			heating = false
	pass


func _exit_tree() -> void:
	heating = false
