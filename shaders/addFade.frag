#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;

uniform float add;

void main()
{
	vec4 base = texture2D(texture, v_texCoord) * v_color;
	base.rgb += vec3(add);
	gl_FragColor = base;
}
