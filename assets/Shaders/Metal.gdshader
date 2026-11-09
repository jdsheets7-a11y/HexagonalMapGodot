
shader_type canvas_item;

uniform vec4 steel_color : source_color =
    vec4(0.52, 0.54, 0.53, 1.0);

uniform float grain_strength : hint_range(0.0, 0.08) = 0.025;
uniform float lighting_strength : hint_range(0.0, 0.3) = 0.12;
uniform float grain_scale : hint_range(100.0, 1000.0) = 450.0;
uniform float corner_radius = 20.0;
uniform vec2 rect_size = vec2(375.0, 750.0);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7)))
        * 43758.5453);
}

float rounded_box(vec2 p, vec2 size, float radius) {
    vec2 q = abs(p) - size * 0.5 + radius;
    return length(max(q, vec2(0.0)))
        + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	
	vec2 pixel_pos = UV * rect_size;
	
	float dist = rounded_box(
	    pixel_pos - rect_size * 0.5,
	    rect_size,
	    corner_radius
	);

	float alpha = 1.0 - smoothstep(-1.0, 1.0, dist);

	COLOR.a *= alpha;
    vec2 uv = UV;

    // Directional brushed-metal grain.
    float grain = hash(vec2(
        floor(uv.x * grain_scale),
        floor(uv.y * 180.0)
    ));

    grain = (grain - 0.5) * grain_strength;

    // Subtle upper-left lighting.
    float light = 1.0 - length(
        (uv - vec2(0.25, 0.2)) * vec2(0.7, 0.8)
    );

    light = clamp(light, 0.0, 1.0);

    float shading = (light - 0.5) * lighting_strength;

    vec3 result = steel_color.rgb * (1.0 + shading + grain);

	COLOR = vec4(result, steel_color.a * alpha);
}
