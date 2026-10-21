// Océano animado: olas Gerstner + espuma en la orilla. Ligero para Quest (renderer móvil).
shader_type spatial;
render_mode cull_disabled, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.02, 0.18, 0.32, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.10, 0.62, 0.66, 1.0);
uniform vec4 foam_color : source_color = vec4(0.95, 0.97, 1.0, 1.0);
uniform float shore_z = -6.0;      // línea de orilla (z del mundo)
uniform float wave_scale = 1.0;
uniform vec3 fresnel_color = vec3(0.35, 0.55, 0.75); // reflejo del cielo

varying vec3 wpos;
varying float crest;

vec3 gerstner(vec2 p, vec2 dir, float steep, float wl, float t, inout vec3 tan, inout vec3 bin) {
	float k = 6.28318 / wl;
	float c = sqrt(9.8 / k);
	vec2 d = normalize(dir);
	float f = k * (dot(d, p) - c * t);
	float a = steep / k;
	tan += vec3(-d.x * d.x * steep * sin(f), d.x * steep * cos(f), -d.x * d.y * steep * sin(f));
	bin += vec3(-d.x * d.y * steep * sin(f), d.y * steep * cos(f), -d.y * d.y * steep * sin(f));
	return vec3(d.x * a * cos(f), a * sin(f), d.y * a * cos(f));
}

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Las olas pierden fuerza al llegar a la orilla
	float near = clamp((shore_z - w.z) / 25.0, 0.15, 1.0) * wave_scale;
	vec3 tan = vec3(1.0, 0.0, 0.0);
	vec3 bin = vec3(0.0, 0.0, 1.0);
	float t = TIME;
	vec3 o = vec3(0.0);
	o += gerstner(w.xz, vec2(0.1, 1.0), 0.22 * near, 14.0, t, tan, bin);
	o += gerstner(w.xz, vec2(0.4, 0.9), 0.16 * near, 7.0, t, tan, bin);
	o += gerstner(w.xz, vec2(-0.3, 1.0), 0.10 * near, 3.5, t, tan, bin);
	o += gerstner(w.xz, vec2(0.8, 0.6), 0.06 * near, 1.7, t, tan, bin);
	VERTEX += o;
	crest = o.y;
	NORMAL = normalize(cross(bin, tan));
	wpos = w + o;
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	float dist = shore_z - wpos.z; // >0 mar adentro
	float depth_mix = clamp(dist / 30.0, 0.0, 1.0);
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, depth_mix);
	float n = vnoise(wpos.xz * 1.3 + vec2(TIME * 0.3, TIME * 0.2)) * 0.6 + vnoise(wpos.xz * 4.0 - TIME * 0.5) * 0.4;
	// espuma en la orilla (franja que va y viene) + crestas
	float surf = sin(TIME * 0.9 + wpos.x * 0.05) * 0.8;
	float shore_foam = smoothstep(3.5, 0.0, dist + surf) * smoothstep(0.35, 0.65, n);
	float crest_foam = smoothstep(0.35, 0.6, crest) * smoothstep(0.45, 0.8, n);
	float foam = clamp(shore_foam + crest_foam, 0.0, 1.0);
	ALBEDO = mix(col, foam_color.rgb, foam);
	ROUGHNESS = mix(0.06, 0.8, foam);
	METALLIC = 0.0;
	SPECULAR = 0.6;
	// Fresnel simple para que el agua refleje el cielo en ángulos rasantes
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	EMISSION = fresnel_color * fres * 0.25 * (1.0 - foam);
}
