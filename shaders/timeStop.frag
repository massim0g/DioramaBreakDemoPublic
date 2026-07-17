#version 330 core

//DEPRECATED, ROLLED INTO STAGE SHADER

varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;

#define saturation 0.5
void main()
{
	gl_FragColor = texture2D(texture, v_texCoord) * v_color;
	gl_FragColor.rgb = mix(vec3(dot(gl_FragColor.rgb, vec3(0.299, 0.587, 0.114))), gl_FragColor.rgb, saturation);
}
