// Suelo de tarima: tablas con vetas, sin texturas.
shader_type spatial;

uniform vec4 light_wood : source_color = vec4(0.62, 0.43, 0.27, 1.0);
uniform vec4 dark_wood : source_color = vec4(0.42, 0.27, 0.16, 1.0);
uniform float plank_width = 0.22;

varying vec3 wpos;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	float row = floor(wpos.x / plank_width);
	float z = wpos.z + hash(row) * 3.0;
	float plank = floor(z / 1.8);
	float id = hash(row * 13.1 + plank * 7.7);
	vec2 f = vec2(fract(wpos.x / plank_width), fract(z / 1.8));
	float seam = smoothstep(0.0, 0.03, f.x) * smoothstep(1.0, 0.97, f.x) * smoothstep(0.0, 0.006, f.y) * smoothstep(1.0, 0.994, f.y);
	float grain = sin(wpos.x * 90.0 + sin(z * 3.0 + id * 10.0) * 2.0) * 0.5 + 0.5;
	vec3 c = mix(dark_wood.rgb, light_wood.rgb, id * 0.6 + grain * 0.25);
	ALBEDO = c * mix(0.45, 1.0, seam);
	ROUGHNESS = 0.45;
	SPECULAR = 0.4;
}
