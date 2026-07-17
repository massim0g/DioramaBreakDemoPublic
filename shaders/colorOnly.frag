#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;

void main()
{
	gl_FragColor = vec4(v_color.rgb, texture2D(texture, v_texCoord).a*v_color.a);
}
