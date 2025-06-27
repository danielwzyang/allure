shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float pixelSize : hint_range(1.0, 32.0) = 4.0;

// runs for each pixel to determine its final value
void fragment() {
	// get the dimensions
	vec2 dimensions = vec2(textureSize(SCREEN_TEXTURE, 0));

	// determine how large each block (the big pixel we're drawing) is in uv coordinates
	vec2 blockSize = pixelSize / dimensions;

	// snap the uv to the center of each block
	vec2 uv = (floor(SCREEN_UV / blockSize) + 0.5) * blockSize;

	vec4 color = texture(SCREEN_TEXTURE, uv);

	// force alpha to be either 0 or 1 for hard edges
	color.a = step(0, color.a);

	COLOR = color;
}
