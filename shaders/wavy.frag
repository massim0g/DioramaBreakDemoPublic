#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;
uniform float time;

#define PI 3.1415926535897932384626433832795

void main()
{
	vec2 tCoord = v_texCoord;
	tCoord.x += sin(tCoord.y/0.5*PI+time/100.)*0.05;
    gl_FragColor = texture2D(texture, tCoord) * v_color;
	gl_FragColor.r = sin(time/1000.);
}