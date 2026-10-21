// Cielo nocturno: degradado, estrellas fijas y luna (dirección de la primera luz).
// Sin TIME para que Godot pueda cachear el cielo y no cueste nada en las Quest.
shader_type sky;

uniform vec3 top_color : source_color = vec3(0.005, 0.012, 0.04);
uniform vec3 horizon_color : source_color = vec3(0.04, 0.07, 0.14);
uniform vec3 ground_color : source_color = vec3(0.01, 0.015, 0.03);
uniform float star_density = 0.9965;

float hash3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }

void sky() {
	vec3 d = normalize(EYEDIR);
	float h = clamp(d.y, 0.0, 1.0);
	vec3 col = mix(horizon_color, top_color, pow(h, 0.45));
	// estrellas: una por celda como mucho, más tenues cerca del horizonte
	vec3 p = d * 260.0;
	vec3 cell = floor(p);
	float r = hash3(cell);
	if (r > star_density) {
		vec3 center = cell + vec3(hash3(cell + 1.3), hash3(cell + 2.7), hash3(cell + 4.1));
		float dist = length(p - center);
		float b = smoothstep(0.45, 0.0, dist) * (r - star_density) / (1.0 - star_density);
		col += vec3(0.9, 0.93, 1.0) * b * 2.2 * smoothstep(0.0, 0.25, d.y);
	}
	if (LIGHT0_ENABLED) {
		float m = dot(d, LIGHT0_DIRECTION);
		col += vec3(1.0, 0.97, 0.88) * smoothstep(0.99955, 0.9997, m) * 2.0; // disco de la luna
		col += vec3(0.25, 0.32, 0.45) * pow(max(m, 0.0), 120.0) * 0.6;       // halo
	}
	col = mix(col, ground_color, smoothstep(0.0, -0.05, d.y));
	COLOR = col;
}
