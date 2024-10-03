shader_type canvas_item;

uniform sampler2D palette : filter_nearest, repeat_disable;
uniform sampler2D palette_damage : filter_nearest, repeat_disable;
uniform bool skip_first_row = true;
uniform float damage_percent = 0.0;

void fragment() {
  vec4 original_color = texture(TEXTURE, UV);
  ivec3 colori = ivec3(round(original_color.rgb * 255.0));

  ivec2 color_count = textureSize(palette, 0);

  // find color index in palette, matching color in the original palette (first row)
  float idx = -1.0;
  for (int i = 0; i < color_count.x; i++) {
    vec3 color2 = texture(palette, vec2(float(i) / float(color_count.x - 1), 0)).rgb;
    ivec3 colori2 = ivec3(round(color2 * 255.0));

    if (colori == colori2) {
      idx = float(i);
      break;
    }
  }

  if (idx >= 0.0) {
    // get sprite color from palette
    vec2 uv = vec2(idx / float(color_count.x - 1), 1.0);
    vec4 palette_color = texture(palette, uv);

    // get sprite color from damage palette
    vec2 uv_damage = vec2(uv.x, 0.0);
    vec4 damage_color = texture(palette_damage, uv_damage);

    // mix colors according to damage percent
    vec4 color = mix(palette_color, damage_color, damage_percent);
    COLOR = vec4(color.rgb, original_color.a);
    // COLOR = vec4(palette_color.rgb, original_color.a);
  } else {
    COLOR = original_color;
  }
}
