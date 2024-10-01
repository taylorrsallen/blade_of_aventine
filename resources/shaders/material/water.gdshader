shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform float murkiness;
uniform vec3 surface_color : source_color;
uniform vec3 depth_color : source_color;
uniform sampler2D caustic_texture;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float proximity_fade_distance;
uniform float point_size : hint_range(0, 128);
uniform float roughness : hint_range(0, 1);
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float specular;
uniform sampler2D texture_refraction : filter_linear_mipmap, repeat_enable;
uniform float refraction : hint_range(-16, 16);
uniform vec4 refraction_texture_channel;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16, 16);
uniform float subsurface_scattering_strength : hint_range(0, 1);
uniform sampler2D texture_subsurface_scattering : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;
uniform float lighting = 1.0;
uniform float emission_mult = 1.0;

uniform vec2 frag_uv_offset;

void vertex() {
	UV = (UV + frag_uv_offset) * uv1_scale.xy + uv1_offset.xy;
	//VERTEX.y = texture(texture_normal, vec2(UV.x + TIME * 0.025, UV.y) * 1.2).r * texture(texture_normal, vec2(UV.x + TIME * -0.025, UV.y)).r;
}

float get_linear_scene_depth(vec2 screen_uv, mat4 inv_projection_matrix) {
	float log_depth = textureLod(depth_texture, screen_uv, 0.0).x;
	vec4 depth_view = inv_projection_matrix * vec4(screen_uv * 2.0 - 1.0, log_depth, 1.0);
	depth_view.xyz /= depth_view.w;
	return -depth_view.z;
}

void fragment() {
	vec2 base_uv = UV;

	float linear_scene_depth = get_linear_scene_depth(SCREEN_UV, INV_PROJECTION_MATRIX);
	linear_scene_depth += VERTEX.z;
	float murkiness_amount = 1.0 - exp(-linear_scene_depth * murkiness);
    vec3 water_color = mix(surface_color.rgb, depth_color.rgb, murkiness_amount);
	ALBEDO = water_color.rgb;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;
	SPECULAR = specular;

	BACKLIGHT *= lighting;

	NORMAL_MAP = (texture(texture_normal, vec2(base_uv.x + TIME * 0.025, base_uv.y)).rgb * texture(texture_normal, vec2(base_uv.x + TIME * -0.025, base_uv.y)).rgb) + 0.25;

	NORMAL_MAP_DEPTH = normal_scale;
	vec3 unpacked_normal = NORMAL_MAP;
	unpacked_normal.xy = unpacked_normal.xy * 2.0 - 1.0;
	unpacked_normal.z = sqrt(max(0.0, 1.0 - dot(unpacked_normal.xy, unpacked_normal.xy)));
	vec3 ref_normal = normalize(mix(NORMAL, TANGENT * unpacked_normal.x + BINORMAL * unpacked_normal.y + NORMAL * unpacked_normal.z, NORMAL_MAP_DEPTH));
	vec2 ref_ofs = SCREEN_UV - ref_normal.xy * dot(texture(texture_refraction, base_uv), refraction_texture_channel) * refraction;
	float ref_amount = 1.0 - albedo.a;
	EMISSION += textureLod(screen_texture, ref_ofs, ROUGHNESS * 8.0).rgb * ref_amount * EXPOSURE * emission_mult;
	ALBEDO *= 1.0 - ref_amount;
	ALPHA = 1.0;
	float depth_tex = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 world_pos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_tex, 1.0);
	world_pos.xyz /= world_pos.w;
	ALPHA *= clamp(1.0 - smoothstep(world_pos.z + proximity_fade_distance, world_pos.z, VERTEX.z), 0.0, 1.0);
	float sss_tex = texture(texture_subsurface_scattering, base_uv).r;
	SSS_STRENGTH = subsurface_scattering_strength * sss_tex;
}