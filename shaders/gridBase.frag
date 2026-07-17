#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;
uniform vec2 texSize;
uniform vec2 tileSize;
uniform vec2 gridDisplayPos;
uniform int time;

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

bool coordInOffsetSegment(float coord, float offset, float length, float wrap){
	float coord2 = coord+wrap;
	return (coord >= offset && coord < offset+length) || (coord2 >= offset && coord2 < offset+length);
}

void main()
{
	vec4 inCol = texture2D(texture, v_texCoord);

	if(inCol.a == 0.){
		gl_FragColor = inCol*v_color;
		return;
	} 

	vec2 rel = floor(v_texCoord * texSize - gridDisplayPos);

	vec2 tileCoord = mod(floor(rel), tileSize);

	vec2 offset = floor(float(time%48)/6.)*6./48.*tileSize;

	bool draw = false;
	if(tileCoord.y == 0. || tileCoord.y == tileSize.y-1.){
		float lengthDrawn = map(inCol.a, 0.1, 0.25, tileSize.x/4., tileSize.x/2.);
		if (coordInOffsetSegment(tileCoord.x, offset.x, lengthDrawn, tileSize.x)){ draw = true;}
	}
	if(tileCoord.x == 0. || tileCoord.x == tileSize.x-1.){
		float lengthDrawn = map(inCol.a, 0.1, 0.25, tileSize.y/4., tileSize.y/2.);
		if (coordInOffsetSegment(tileCoord.y, offset.y, lengthDrawn, tileSize.y)){ draw = true;}
	}

	gl_FragColor = draw ? inCol*v_color : vec4(0);

	// gl_FragColor = inCol;
	// if(!draw) gl_FragColor.a *= 0.85;
	// gl_FragColor*=v_color;

}
