#version 330 core

//simple overlay for now

varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;
uniform sampler2D stencilTex;

uniform vec2 texSize;
uniform vec2 stencilTexSize;
uniform float outlineRevealAngle; //0-90
uniform vec2 centerPos; //relative to camera pos
uniform vec2 stencilOffset; //offset from target draw pos to stencil tex origin, in pixels
uniform int drawMode; //0 = fill only, 1 = outline only, 2 = silhouette
uniform sampler2D floorTex;
uniform sampler2D mainTex;
uniform vec2 floorTexSize;

#define PI 3.1415926538

int valCheck(vec2 checkPos){
	return int(checkPos.x < 0. || checkPos.x >= texSize.x || checkPos.y < 0. || checkPos.y >= texSize.y || texture2D(texture, checkPos/texSize).a == 0.);
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

	src.rgb *= v_color.rgb;
	float alpha = src.a*v_color.a;

	if(src.a != 0.){
		vec2 pos = v_texCoord*texSize;
		int darkerNeighbours = (
			valCheck(vec2(pos.x+1.,pos.y)) +
			valCheck(vec2(pos.x+1.,pos.y-1.)) +
			valCheck(vec2(pos.x,pos.y-1.)) +
			valCheck(vec2(pos.x-1.,pos.y-1.)) +
			valCheck(vec2(pos.x-1.,pos.y)) +
			valCheck(vec2(pos.x-1.,pos.y+1.)) +
			valCheck(vec2(pos.x,pos.y+1.)) +
			valCheck(vec2(pos.x+1.,pos.y+1.))
		);
		bool isOutline = false;
		if (darkerNeighbours > 0){
			float angle = mod(vec2_angle(pos-centerPos), 90.);
			if (angle <= outlineRevealAngle){
				isOutline = true;
			}
		}

		if (drawMode == 0 && isOutline) discard;
		if (drawMode == 1 && !isOutline) discard;

		vec2 stencilUV = (v_texCoord * texSize + stencilOffset) / stencilTexSize;
		int overlapCount = int(texture2D(stencilTex, stencilUV).a*16. + 0.5);
		float stencilVal = clamp((overlapCount-1.)*(1./3.), 0, 1);
		src.rgb = mix(src.rgb, vec3(0.11, 0.03, 0.09), stencilVal);

		if (isOutline){
			alpha = min(alpha * 3.0, 1.0);
			float luma = dot(src.rgb, vec3(0.299, 0.587, 0.114));
			src.rgb = clamp(mix(vec3(luma), src.rgb, 1.5), 0.0, 1.0);
		}

		if (drawMode == 2){
			vec2 screenUV = gl_FragCoord.xy / floorTexSize;
			screenUV.y = 1.0 - screenUV.y;
			vec4 pre = texture2D(floorTex, screenUV);
			vec4 post = texture2D(mainTex, screenUV);
			if (pre == post) discard;
		}
	}

	gl_FragColor.rgb = src.rgb;
	gl_FragColor.a = alpha;
}
