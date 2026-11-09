
shader_type canvas_item;

uniform float highlight_width : hint_range(0.3, 2.0, 0.1) = 0.5;
uniform float shadow_width : hint_range(0.5, 4.0, 0.1) = 2.5;
uniform float bevel_strength : hint_range(0.0, 1.0, 0.05) = 0.75;

uniform vec4 face_color : source_color =
    vec4(0.46, 0.48, 0.47, 1.0);

uniform vec4 highlight_color : source_color =
    vec4(0.84, 0.87, 0.85, 1.0);

uniform vec4 shadow_color : source_color =
    vec4(0.24, 0.27, 0.26, 1.0);

void fragment() {
    if (REGION_RECT.z < 1.0) {

        float a0 = texture(TEXTURE, UV).a;

        // Separate screen-space offsets.
        vec2 dx_light = dFdx(UV) * highlight_width;
        vec2 dy_light = dFdy(UV) * highlight_width;

        vec2 dx_shadow = dFdx(UV) * shadow_width;
        vec2 dy_shadow = dFdy(UV) * shadow_width;

        // Highlight edge.
        float a_left = texture(TEXTURE, UV - dx_light).a;
        float a_up = texture(TEXTURE, UV - dy_light).a;

        // Recessed shadow edge.
        float a_right = texture(TEXTURE, UV + dx_shadow).a;
        float a_down = texture(TEXTURE, UV + dy_shadow).a;

        float light_edge = max(
            a0 - a_left,
            a0 - a_up
        );

        float dark_edge = max(
            a0 - a_right,
            a0 - a_down
        );

        light_edge = smoothstep(0.10, 0.45, light_edge);
        dark_edge = smoothstep(0.10, 0.45, dark_edge);

        vec3 result = face_color.rgb;

        result = mix(
            result,
            highlight_color.rgb,
            light_edge * bevel_strength
        );

        result = mix(
            result,
            shadow_color.rgb,
            dark_edge * bevel_strength
        );

        COLOR = vec4(result, COLOR.a * face_color.a);
    }
}
