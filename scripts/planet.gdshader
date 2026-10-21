// Planeta gaseoso con bandas y tormentas. Iluminado por la luz direccional (la estrella).
shader_type spatial;

uniform vec4 color_a : source_color = vec4(0.85, 0.62, 0.42, 1.0);
uniform vec4 color_b : source_color = vec4(0.55, 0.32, 0.22, 1.0);
uniform vec4 color_c : source_color = vec4(0.95, 0.88, 0.75, 1.0);
uniform vec4 atmosphere : source_color = vec4(0.5, 0.65, 1.0, 1.0);

varying vec3 lpos;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() { lpos = normalize(VERTEX); }

void fragment() {
	float lat = lpos.y;
	float lon = atan(lpos.z, lpos.x);
	float swirl = vnoise(vec2(lon * 3.0 + TIME * 0.01, lat * 12.0)) * 0.12;
	float bands = sin((lat + swirl) * 22.0) * 0.5 + 0.5;
	float fine = sin((lat + swirl * 1.5) * 61.0) * 0.5 + 0.5;
	vec3 c = mix(color_b.rgb, color_a.rgb, bands);
	c = mix(c, color_c.rgb, fine * 0.25);
	// gran mancha
	float spot = smoothstep(0.16, 0.0, length(vec2((lon - 0.8) * 0.5, (lat + 0.3) * 1.6)));
	c = mix(c, vec3(0.75, 0.3, 0.18), spot * 0.8);
	ALBEDO = c;
	ROUGHNESS = 0.9;
	SPECULAR = 0.1;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = atmosphere.rgb * rim * 0.25;
}
