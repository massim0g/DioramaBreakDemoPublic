#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

//uniform sampler2D texture;

uniform float time;
uniform vec2 rectSize; //in pixels

#define loopDuration 88.
#define trailLength 8.
#define darkenAmount 0.75

float remap(float old_value, float old_min, float old_max, float new_min, float new_max){
	float old_range = old_max - old_min;
	float new_range = new_max - new_min;
	return ((old_value - old_min)/old_range)*new_range + new_min;
}

float getDarkenMul(float darkenPos, float perimPos, float perimSize){
	float dist = mod(darkenPos - perimPos + perimSize, perimSize);
	if(dist > trailLength){return 1.;}
	return remap(dist, 0., trailLength, darkenAmount, 1.);
} 

void main()
{
	vec2 rectPos = floor(v_texCoord*rectSize);

	float perimSize = (rectSize.x-1.)*2 + (rectSize.y-1.)*2;
	float perimPos = 0.;
	if(rectPos.y == 0.){
		perimPos = rectPos.x;
	}
	else if (rectPos.x == rectSize.x-1.){
		perimPos = rectSize.x-1. + rectPos.y;
	}
	else if(rectPos.y == rectSize.y-1.){
		perimPos = (rectSize.x-1.)*2 + rectSize.y-1. - rectPos.x;
	}
	else if(rectPos.x == 0.){
		perimPos = perimSize - rectPos.y;
	}
	else{discard;}

	float t = floor(time/3.)*3.;
	float darkenPosA = floor(fract(t/loopDuration)*perimSize);
	float darkenPosB = floor(fract(t/loopDuration+0.5)*perimSize);

	gl_FragColor = v_color;
	gl_FragColor.rgb *= getDarkenMul(darkenPosA, perimPos, perimSize)*getDarkenMul(darkenPosB, perimPos, perimSize);
}
