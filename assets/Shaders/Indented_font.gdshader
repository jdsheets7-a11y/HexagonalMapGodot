shader_type canvas_item;

uniform float depth = 0.001

;
uniform vec4 dark_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 light_color: source_color = vec4(0.8, 0.8, 0.8, 1.0);
uniform float darken: hint_range(0.0, 0.1) = 0.05;

void fragment() {
	if (REGION_RECT.z < 1.0) { // cheap trick to make sure we're rendering the font
		float a0 = texture(TEXTURE, UV).a;
		float a1 = texture(TEXTURE, UV - vec2(depth)).a;
		float a2 = texture(TEXTURE, UV + vec2(depth)).a;
		COLOR.a = (a0 - a1) * dark_color.a + (a0 - a2) * light_color.a;
		COLOR.rgb = mix(dark_color.rgb, light_color.rgb, (a0 - a2));
		COLOR.a += darken * a0; // darken the interior sligltly for better feel
		}
}