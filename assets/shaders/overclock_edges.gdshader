shader_type canvas_item;
render_mode blend_add;

uniform vec3 neon_color : source_color = vec3(1.0, 0.9, 0.1);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float glitch : hint_range(0.0, 1.0) = 0.0;
uniform float time_scale : hint_range(0.1, 60.0) = 18.0;
uniform float edge_size : hint_range(0.02, 0.5) = 0.18;
uniform float pulse_speed : hint_range(0.5, 30.0) = 9.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float bolts(float coord, float perp, float seed) {
	float band = floor(coord * 80.0);
	float r = hash(vec2(band, seed + floor(TIME * time_scale * 0.5)));
	float spark = step(0.965, r);
	float shimmer = 0.55 + 0.45 * sin(TIME * pulse_speed + band * 1.7);
	float thickness = smoothstep(0.0, edge_size, perp) * (1.0 - smoothstep(edge_size, edge_size * 1.8, perp));
	return spark * shimmer * thickness;
}

void fragment() {
	vec2 uv = UV;
	float jitter = (hash(vec2(floor(TIME * 40.0), 0.0)) - 0.5) * 0.04 * glitch;
	uv.x += jitter;

	float left = uv.x;
	float right = 1.0 - uv.x;
	float top = uv.y;
	float bottom = 1.0 - uv.y;

	float edge_dist = min(min(left, right), min(top, bottom));
	float glow = pow(clamp(1.0 - edge_dist / edge_size, 0.0, 1.0), 2.2);

	float pulse = 0.65 + 0.35 * sin(TIME * pulse_speed);
	glow *= pulse;

	float bolt_l = bolts(uv.y, left, 1.0);
	float bolt_r = bolts(uv.y, right, 2.0);
	float bolt_t = bolts(uv.x, top, 3.0);
	float bolt_b = bolts(uv.x, bottom, 4.0);
	float bolt_sum = bolt_l + bolt_r + bolt_t + bolt_b;

	float glitch_flash = step(0.93, hash(vec2(floor(TIME * 22.0), 7.0))) * glitch * 0.7;

	vec3 col = neon_color * (glow * 1.4 + bolt_sum * 2.0 + glitch_flash);
	float alpha = clamp(glow + bolt_sum + glitch_flash, 0.0, 1.0) * intensity;
	COLOR = vec4(col * intensity, alpha);
}
