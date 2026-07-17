#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;
uniform sampler2D shadowMap;
uniform vec4 stageRect;
uniform vec4 shadowBlend;
uniform vec4 lightBlend;

uniform bool verticalShading;
uniform bool timeStopEffect;
uniform float timeStopSaturation;

uniform vec4 tpPos; //texture page pos
//uniform vec2 tpSize;
//uniform float baseZ;
uniform vec2 feetPos;

float remap(float old_value, float old_min, float old_max, float new_min, float new_max){
	float old_range = old_max - old_min;
	float new_range = new_max - new_min;
	return ((old_value - old_min)/old_range)*new_range + new_min;
}

float sampleShadowMapX(float xCoord){
	vec2 samplePos;
	samplePos.x = xCoord;
	samplePos.y = feetPos.y;
	vec4 sample = texture2D(shadowMap, (samplePos-stageRect.xy)/stageRect.zw);
	return (sample.r*2.-1.)*sample.a;
}

float overlay(float dst, float src){
	if (dst < 0.5){
		return 2*dst*src;
	}
	else{
		return 1 - 2*(1-dst)*(1-src);
	}
}

void main() {
    vec4 base = texture2D(texture, v_texCoord) * v_color;

	if(verticalShading){
		//distance above floor
		//float dz = remap(v_texCoord.y, tpPos.y/tpSize.y, (tpPos.y+tpPos.w)/tpSize.y, tpPos.w, 0.) + baseZ;

		float left = feetPos.x-tpPos.z/2.;
		float sampleCount = 16.;
		float shadowCount = 0.;
		for(float i=0;i<sampleCount;i++){
			shadowCount += sampleShadowMapX(left + tpPos.z*(i/sampleCount));
		}
		float mask = shadowCount/sampleCount; 

		if (mask <= 0.){
			base.rgb = mix(base.rgb, base.rgb*shadowBlend.rgb, shadowBlend.a*-mask);
		}
		else{
			vec3 overlaid;
			overlaid.r = overlay(base.r, lightBlend.r);
			overlaid.g = overlay(base.g, lightBlend.g);
			overlaid.b = overlay(base.b, lightBlend.b);
			base.rgb = mix(base.rgb, overlaid, lightBlend.a*mask); 
		}
	}

	if(timeStopEffect){
		base.rgb = mix(vec3(dot(base.rgb, vec3(0.299, 0.587, 0.114))), base.rgb, timeStopSaturation);
	}

	gl_FragColor = base;

}