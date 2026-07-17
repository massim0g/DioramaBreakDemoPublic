#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;
uniform int  paletteSize;
uniform vec3 sourceColors[64];
uniform vec3 destColors1[64];
uniform vec3 destColors2[64];
uniform float destMix;

uniform bool alwaysApplyWithShortestDistance;

uniform int blendmode;

#define tolerance 0.004

vec3 hardLight(vec3 base, vec3 blend) {
    // compute the two modes:
    vec3 low  = 2.0 * base * blend;                                 // when blend < 0.5
    vec3 high = 1.0 - 2.0 * (1.0 - base) * (1.0 - blend);          // when blend >= 0.5

    // step(edge, x) returns 0.0 where x < edge, and 1.0 where x >= edge,
    // component‑wise if x and edge are vectors.
    vec3 selector = step(0.5, blend);

    // mix(a, b, t) picks a where t==0, and b where t==1 (also works per‑component).
    return mix(low, high, selector);
}

void main() {

    gl_FragColor = texture2D(texture, v_texCoord);

	vec3 destCol;

	if(gl_FragColor.a == 0.){
		gl_FragColor *= v_color;
		return;
	}

	if(alwaysApplyWithShortestDistance){
		float shortestDist = 2.0;
		int shortestDistIndex = 0;
		for (int i = 0; i < paletteSize; ++i) {
			float dist = distance(gl_FragColor.rgb, sourceColors[i]);
			if (dist < shortestDist) {
				shortestDist = dist;
				shortestDistIndex = i;
			}
		}
		destCol = mix(destColors1[shortestDistIndex], destColors2[shortestDistIndex], destMix);
	}
	else{
		bool broke = false; 
		for (int i = 0; i < paletteSize; ++i) {
			if (distance(gl_FragColor.rgb, sourceColors[i]) < tolerance) {
				destCol = mix(destColors1[i], destColors2[i], destMix);
				broke = true;
				break;
			}
		}
		if(!broke){
			gl_FragColor *= v_color;
			return;
		}
	}
	
	if(blendmode == 0){ //replace
		gl_FragColor.rgb = destCol;
		gl_FragColor *= v_color;
	}
	else if(blendmode == 1){ //multiply
		gl_FragColor *= v_color;
		gl_FragColor.rgb *= destCol;
	}
	else if(blendmode == 2){ //hard light
		gl_FragColor *= v_color;
		gl_FragColor.rgb = hardLight(gl_FragColor.rgb, destCol);
	}
	
}
