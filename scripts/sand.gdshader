// Arena: color con ruido y zona mojada cerca del agua.
shader_type spatial;
uniform vec4 dry : source_color = vec4(0.93, 0.83, 0.62, 1.0);
uniform vec4 wet : source_color = vec4(0.62, 0.52, 0.38, 1.0);
uniform float shore_z = -6.0;
varying vec3 wpos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float g = vnoise(wpos.xz * 9.0) * 0.5 + vnoise(wpos.xz * 1.5) * 0.5;
	float wetness = 1.0 - smoothstep(shore_z, shore_z + 5.0 + sin(TIME * 0.9 + wpos.x * 0.05) * 0.8, wpos.z);
	vec3 c = mix(dry.rgb, wet.rgb, wetness) * (0.85 + g * 0.25);
	ALBEDO = c;
	ROUGHNESS = mix(0.95, 0.35, wetness);
	SPECULAR = mix(0.2, 0.5, wetness);
}
