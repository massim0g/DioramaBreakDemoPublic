#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;
uniform float time;

#define PI 3.14159265

void main()
{
	vec2 texSize = vec2(textureSize(texture, 0));
	vec2 pixel = 1.0 / texSize;

	vec2 tCoord = v_texCoord;
	tCoord.x += sin(v_texCoord.y * 6000.0 * PI + time/5.) * pixel.x * 0.6;
	
	gl_FragColor = texture2D(texture, tCoord) * v_color;
}
