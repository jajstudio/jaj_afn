shader_type canvas_item;

uniform float blending_strength = 0.5;
uniform float blending_length = 0.3;
uniform bool use_top_texture;
uniform bool use_bottom_texture;
uniform bool use_left_texture;
uniform bool use_right_texture;
uniform bool use_top_left_texture;
uniform bool use_top_right_texture;
uniform bool use_bottom_left_texture;
uniform bool use_bottom_right_texture;
uniform sampler2D top_texture;
uniform sampler2D bottom_texture;
uniform sampler2D left_texture;
uniform sampler2D right_texture;
uniform sampler2D top_left_texture;
uniform sampler2D top_right_texture;
uniform sampler2D bottom_left_texture;
uniform sampler2D bottom_right_texture;
uniform vec2 tile_size;
uniform vec2 atlas_size;

vec2 getPixelPosInTile(vec2 uv) {
    float exactPosX = floor(uv.x * atlas_size.x * tile_size.x);
    float exactPosY = floor(uv.y * atlas_size.y * tile_size.y);
    float relativePosX = mod(exactPosX, tile_size.x);
    float relativePosY = mod(exactPosY, tile_size.y);
    return vec2(relativePosX, relativePosY);
}

void fragment() {
    vec4 original_color = texture(TEXTURE, UV);
    vec2 pixel_pos = getPixelPosInTile(UV);
    vec2 normalized_pixel_pos = pixel_pos / tile_size;

    vec4 blended_color = vec4(0.0);
    float total_weight = 0.0;

    // Calculate factors and accumulate blended color and total weight
    if (use_top_left_texture) {
        vec4 top_left_color = texture(top_left_texture, normalized_pixel_pos);
        float factor = smoothstep(0.0, blending_length, length(vec2(pixel_pos.x, pixel_pos.y) / tile_size));
        blended_color += top_left_color * (1.0 - factor);
        total_weight += (1.0 - factor);
    }
    if (use_top_texture) {
        vec4 top_color = texture(top_texture, normalized_pixel_pos);
        float factor = smoothstep(0.0, blending_length, pixel_pos.y / tile_size.y);
        blended_color += top_color * (1.0 - factor);
        total_weight += (1.0 - factor);
    }
    if (use_top_right_texture) {
        vec4 top_right_color = texture(top_right_texture, normalized_pixel_pos);
        float factor = smoothstep(0.0, blending_length, length(vec2(tile_size.x - pixel_pos.x, pixel_pos.y) / tile_size));
        blended_color += top_right_color * (1.0 - factor);
        total_weight += (1.0 - factor);
    }
    if (use_right_texture) {
        vec4 right_color = texture(right_texture, normalized_pixel_pos);
        float factor = smoothstep(0.0, blending_length, (tile_size.x - pixel_pos.x) / tile_size.x);
        blended_color += right_color * (1.0 - factor);
        total_weight += (1.0 - factor);
    }
    if (use_bottom_right_texture) {
        vec4 bottom_right_color = texture(bottom_right_texture, normalized_pixel_pos);
        float factor = smoothstep(0.0, blending_length, length(vec2(tile_size.x - pixel_pos.x, tile_size.y - pixel_pos.y) / tile_size));
        blended_color += bottom_right_color * (1.0 - factor);
        total_weight += (1.0 - factor);
    }
    if (use_bottom_texture) {
        vec4 bottom_color = texture(bottom_texture, normalized_pixel_pos);
        float factor = smoothstep(0.0, blending_length, (tile_size.y - pixel_pos.y) / tile_size.y);
        blended_color += bottom_color * (1.0 - factor);
        total_weight += (1.0 - factor);
    }
    if (use_bottom_left_texture) {
        vec4 bottom_left_color = texture(bottom_left_texture, normalized_pixel_pos);
        float factor = smoothstep(0.0, blending_length, length(vec2(pixel_pos.x, tile_size.y - pixel_pos.y) / tile_size));
        blended_color += bottom_left_color * (1.0 - factor);
        total_weight += (1.0 - factor);
    }
    if (use_left_texture) {
        vec4 left_color = texture(left_texture, normalized_pixel_pos);
        float factor = smoothstep(0.0, blending_length, pixel_pos.x / tile_size.x);
        blended_color += left_color * (1.0 - factor);
        total_weight += (1.0 - factor);
    }

    // Normalize the blended color by the total weight, with clamping to avoid excessive blending
    if (total_weight > 0.0) {
        blended_color /= total_weight;
        total_weight = min(total_weight, 1.0); // Clamp total weight to a maximum of 1.0
    }

    // Mix the original color with the blended color only where there is significant weight
    COLOR = mix(original_color, blended_color, blending_strength * total_weight);
}