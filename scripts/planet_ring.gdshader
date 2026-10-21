// Anillos del planeta sobre un plano: bandas concéntricas semitransparentes.
shader_type spatial;
render_mode cull_disabled, unshaded, blend_mix, depth_draw_never;

uniform vec4 ring_color : source_color = vec4(0.85, 0.78, 0.66, 1.0);
uniform float inner = 0.55;
uniform float outer = 1.0;

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float in_ring = smoothstep(inner, inner + 0.02, r) * smoothstep(outer, outer - 0.02, r);
	float bands = 0.55 + 0.45 * sin(r * 140.0) * sin(r * 37.0);
	float gap = smoothstep(0.004, 0.012, abs(r - 0.8));
	ALBEDO = ring_color.rgb * (0.6 + 0.4 * bands);
	ALPHA = in_ring * gap * (0.35 + 0.5 * bands) * 0.8;
}
