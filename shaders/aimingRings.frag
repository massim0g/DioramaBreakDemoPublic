#version 330 core

//simple overlay for now

varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;
uniform sampler2D destination;

uniform vec2 texSize;
uniform float outlineRevealAngle; //0-90
uniform vec2 centerPos; //relative to camera pos

#define PI 3.1415926538

float overlay(float dst, float src){
	if (dst < 0.5){
		return 2*dst*src;
	}
	else{
		return 1 - 2*(1-dst)*(1-src);
	}
}

int valCheck(vec4 src, vec4 check){
	float srcTot = src.r+src.g+src.b; 
	float checkTot = check.r+check.g+check.b;
	return int(srcTot > checkTot || check.a == 0.);
} 

float vec2_angle(vec2 v){
	float a = atan(-v.y, v.x)*(180./PI);
	if(a<0.){
		a += 360.;
	}
	return a;
}

void main()
{
	vec4 src = texture2D(texture, v_texCoord);
	vec4 dst = texture2D(destination, v_texCoord);

	float alpha = src.a*v_color.a;
	if (alpha == 0.){
		gl_FragColor = dst;
		return;
	}

	vec2 pos = v_texCoord*texSize; 
	int darkerNeighbours = (
		valCheck(src, texture2D(texture, vec2(pos.x+1.,pos.y)/texSize)) + 
		valCheck(src, texture2D(texture, vec2(pos.x+1.,pos.y-1.)/texSize)) + 
		valCheck(src, texture2D(texture, vec2(pos.x,pos.y-1.)/texSize)) + 
		valCheck(src, texture2D(texture, vec2(pos.x-1.,pos.y-1.)/texSize)) + 
		valCheck(src, texture2D(texture, vec2(pos.x-1.,pos.y)/texSize)) + 
		valCheck(src, texture2D(texture, vec2(pos.x-1.,pos.y+1.)/texSize)) + 
		valCheck(src, texture2D(texture, vec2(pos.x,pos.y+1.)/texSize)) +
		valCheck(src, texture2D(texture, vec2(pos.x+1.,pos.y+1.)/texSize)) 
	);
	if (darkerNeighbours > 0){
		float angle = mod(vec2_angle(pos-centerPos), 90.);
		if (angle <= outlineRevealAngle){
			gl_FragColor.rgb = src.rgb;
			gl_FragColor.a = dst.a;
			return;
		}
	}

	vec3 overlaid;
	overlaid.r = overlay(dst.r, src.r);
	overlaid.g = overlay(dst.g, src.g);
	overlaid.b = overlay(dst.b, src.b);
	float k = alpha*alpha;
	gl_FragColor.rgb = mix(dst.rgb, overlaid, k); 

	gl_FragColor.a = dst.a;
}
