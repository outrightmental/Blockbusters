class_name Heatable
extends Collidable

# Variables for being heated
var heat: float         = 0.0
var heat_delta: float   = 0.0
var last_heated_at: int = 0
var heating: bool       = false
var heatable: bool      = true

# Apply heat
func apply_heat(delta: float) -> void:
	if heatable:
		heat_delta += delta
	pass


# If heat has been applied, increase the total heat, or decrease it if no heat has been applied
func _physics_process(delta):
	super._physics_process(delta)
	if heat_delta > 0:
		heat += heat_delta
		heat_delta = 0.0
		last_heated_at = Time.get_ticks_msec()
		heating = true
	elif heat > 0:
		heat -= delta
		if heat < 0:
			heat = 0.0
	elif heating:
		if Time.get_ticks_msec() - last_heated_at > Constant.HEATING_TIMEOUT_MSEC:
			heating = false
	pass


func _exit_tree() -> void:
	heating = false
