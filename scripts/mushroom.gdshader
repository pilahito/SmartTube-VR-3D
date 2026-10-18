shader_type spatial;
render_mode specular_disabled;
uniform vec4 cap_color : source_color = vec4(0.35, 0.62, 0.8, 1.0);
void fragment() {
    float pulse = 0.7 + 0.3 * sin(TIME * 0.65 + VERTEX.x * 0.4);
    ALBEDO = cap_color.rgb * 0.35;
    EMISSION = cap_color.rgb * pulse * 0.7;
    ROUGHNESS = 0.85;
}
