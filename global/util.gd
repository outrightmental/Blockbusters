extends Node

# Signal that never happens, in case the tree is unloaded
signal never

# Get a color at a specific saturation ratio relative to the original color
func color_at_sv_ratio(color: Color, s_ratio: float, v_ratio: float = 0) -> Color:
	return Color.from_hsv(color.h, color.s * s_ratio, color.v * (v_ratio if v_ratio > 0 else s_ratio), color.a)


# Get a color at a specific alpha ratio relative to the original color
func color_at_alpha_ratio(color: Color, alpha_ratio: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * alpha_ratio)


# Delay, guarding against the condition that the tree has been unloaded since the calling thread arrived here
func delay(seconds: float) -> Signal:
	if get_tree():
		return get_tree().create_timer(seconds).timeout
	else:
		return never