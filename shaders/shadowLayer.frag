#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;
uniform sampler2D destination;

uniform vec4 shadowBlend;
uniform vec4 lightBlend;

float overlay(float dst, float src){
	if (dst < 0.5){
		return 2*dst*src;
	}
	else{
		return 1 - 2*(1-dst)*(1-src);
	}
}
void main()
{
	vec4 src = texture2D(texture, v_texCoord);
	vec4 dst = texture2D(destination, v_texCoord);

	if (src.a == 0.){
		gl_FragColor = dst;
		return;
	}

	if (distance(src.rgb, vec3(1.)) < distance(src.rgb, vec3(0.))){ //light
		vec3 overlaid;
		overlaid.r = overlay(dst.r, lightBlend.r);
		overlaid.g = overlay(dst.g, lightBlend.g);
		overlaid.b = overlay(dst.b, lightBlend.b);
		float k = lightBlend.a*src.a;
		gl_FragColor.rgb = mix(dst.rgb, overlaid, k); 
		//gl_FragColor.rgb = (1-lightBlend.a)*dst.rgb + lightBlend.a*overlaid.rgb;
	} 
	else{ //shadow
		float k = shadowBlend.a*src.a;
		gl_FragColor.rgb = mix(dst.rgb, dst.rgb*shadowBlend.rgb, k);
		//gl_FragColor.rgb = (1-shadowBlend.a)*dst.rgb + shadowBlend.a*(dst.rgb*shadowBlend.rgb);
	}
	gl_FragColor.a = dst.a;
}
