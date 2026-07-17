#version 330 core
// No extensions are needed here since we are not using any modern qualifiers.
varying vec4 v_color;
varying vec2 v_texCoord;

void main()
{
	gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    v_color = gl_Color;
    v_texCoord = vec2(gl_MultiTexCoord0);
}
