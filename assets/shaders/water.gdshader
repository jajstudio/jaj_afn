shader_type canvas_item;
render_mode blend_mix; // Ensures proper alpha blending with what's behind

uniform sampler2D screen_texture: hint_screen_texture;
uniform sampler2D noise_texture: filter_nearest, repeat_enable; // Ensure this is a grayscale or RG noise texture

uniform vec2 speed = vec2(0.6, 0.3); // Reduced speeds for smoother motion
uniform float wave_strength = 0.07; // Controls the strength of the water texture's own waves
uniform float distortion_strength = 0.01; // Controls the strength of the SCREEN_TEXTURE distortion (this is key!)

// Optional: Add a uniform for a water tint color
uniform vec4 water_tint_color : source_color = vec4(0.4, 0.6, 0.8, 0.8); // Light blue, slightly transparent

void fragment() {
    // 1. Get the noise offset.
    // Scale noise to be between -1.0 and 1.0 (already done with 2.0 * ... - 1.0)
    // The .rg channel gives you a 2D vector for displacement.
    vec2 noise_offset = texture(noise_texture, UV * 2.0 + speed * TIME).rg * 2.0 - vec2(1.0);
    // You might want to scale UV slightly for noise texture if it's too stretched/compressed
    // e.g., UV * some_scale_factor

    // 2. Apply wave_strength to the water's OWN texture UVs.
    // This makes the water texture itself appear wavy.
    vec4 water_texture_color = texture(TEXTURE, UV + noise_offset * wave_strength);

    // 3. Calculate the distortion for the SCREEN_TEXTURE.
    // This is the crucial part. Use distortion_strength for this.
    vec2 screen_distortion_offset = noise_offset * distortion_strength;

    // 4. Sample the screen texture with the calculated distortion.
    vec4 distorted_background = texture(screen_texture, SCREEN_UV + screen_distortion_offset);

    // 5. Combine everything.
    // Blend the original water texture's color (possibly tinted) with the distorted background.
    // The 'water_texture_color.a' is important here to ensure the effect only applies
    // where your water tile is opaque, and allows the background to show through transparency.

    // Mix the distorted background with your base water color/texture.
    // The more opaque your base water texture is (water_texture_color.a), the more
    // you see the distorted background mixed with its color.

    // Final color for the pixel
    vec4 final_color;

    // Option A: Water is a distorted window with a tint.
    // The alpha of the water_texture_color controls how much of the water_tint_color and distortion is applied.
    final_color.rgb = mix(distorted_background.rgb, water_texture_color.rgb * water_tint_color.rgb, water_texture_color.a);
    final_color.a = water_texture_color.a * water_tint_color.a; // Preserve overall alpha for blend_mix

    // Option B: More direct refraction effect (often needs a darker water texture itself for contrast)
     //final_color.rgb = mix(water_texture_color.rgb, distorted_background.rgb, water_texture_color.a);
     //final_color.a = water_texture_color.a;


    // Your original shader had this: COLOR *= texture(screen_texture, SCREEN_UV + noise * distortion);
    // This multiplies the colors, which can darken them unexpectedly and doesn't handle transparency well.
    // Instead, we want to BLEND.

    COLOR = final_color;
}