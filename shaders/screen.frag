#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;
uniform sampler2D destination;

uniform vec4 destRect;
uniform vec2 destSize;

vec3 screen(vec3 base, vec3 blend){
    return 1. - (1. - base)*(1. - blend);
}

void main()
{
	vec4 src = texture2D(texture, v_texCoord) * v_color;

	vec2 destUV = (destRect.xy + v_texCoord * destRect.zw) / destSize;
	vec4 dst = texture2D(destination, destUV);

	gl_FragColor.rgb = mix(dst.rgb, screen(dst.rgb, src.rgb), src.a);
	gl_FragColor.a = dst.a;
}
