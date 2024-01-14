shader_type canvas_item;
uniform float radius;
void fragment() {
	// Called for every pixel the material is visible on.
	COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	float dist = distance(UV, vec2(0.5));
	if (dist < radius) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	}
}

