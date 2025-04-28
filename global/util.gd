extends Node

# Get a color at a specific saturation ratio relative to the original color
func color_at_sv_ratio(color: Color, sv_ratio: float) -> Color:
	return Color.from_hsv(color.h, color.s * sv_ratio, color.v * sv_ratio, color.a)


# Get a color at a specific alpha ratio relative to the original color
func color_at_alpha_ratio(color: Color, alpha_ratio: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * alpha_ratio)
