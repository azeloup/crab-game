shader_type canvas_item;

uniform vec2 player_pos = vec2(0.0);
uniform float radius : hint_range(0.0, 2000.0) = 120.0;  
uniform float softness : hint_range(0.0, 1000.0) = 60.0;
uniform vec4 dark_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	float d = distance(FRAGCOORD.xy, player_pos);
	float a = smoothstep(radius, radius + softness, d);
	COLOR = vec4(dark_color.rgb, dark_color.a * a);
}
