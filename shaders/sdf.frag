#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;

uniform vec2 offset;
uniform float k;
uniform int shapeCount;
uniform int shapeTags[64];
uniform vec4 shapes[64];

//quadratic polynomial smooth min
float smin(float a, float b){
    float h = max(k*4-abs(a-b), 0.)/(k*4);
    return min(a,b) - h*h*k;
}

float sdf(vec2 pos, vec4 shape, int shapeTag){
	if(shapeTag == 1){ //circle
		return distance(pos, shape.xy) - shape.z;
	}

	return 0.;
}

float sdf_union(vec2 pos){
	float res = sdf(pos, shapes[0], shapeTags[0]);
	for(int i=1; i<shapeCount;i+=1){
		res = smin(res, sdf(pos, shapes[i], shapeTags[i]));
	}
	return res;
}

void main()
{
	vec2 pixelPos = offset + v_texCoord*textureSize(texture, 0);
	if(sdf_union(pixelPos) > 0.){discard;} 
	gl_FragColor = v_color;
}
