// Port of gridBase.frag: animated dashed tile-grid lines; segment length is driven by the input alpha.

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

cbuffer Uniforms : register(b0, space3) {
	float2 texSize;        // offset 0
	float2 tileSize;       // offset 8
	float2 gridDisplayPos; // offset 16
	int    time;           // offset 24
};                         // total size 32

float map(float value, float min1, float max1, float min2, float max2) {
	return min2 + (value - min1)*(max2 - min2)/(max1 - min1);
}

// GLSL-style mod (floored); rel can be negative (uv*texSize - gridDisplayPos), so fmod is NOT equivalent
float2 glslMod2(float2 x, float2 y) {
	return x - y*floor(x/y);
}

bool coordInOffsetSegment(float coord, float offset, float length_, float wrap) {
	float coord2 = coord + wrap;
	return (coord >= offset && coord < offset + length_) || (coord2 >= offset && coord2 < offset + length_);
}

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float4 inCol = tex.Sample(texSampler, uv);

	if (inCol.a == 0.0) {
		// GLSL returned inCol*v_color (alpha 0); discard instead per sprite.frag.hlsl depth convention
		discard;
	}

	float2 rel = floor(uv*texSize - gridDisplayPos);

	float2 tileCoord = glslMod2(floor(rel), tileSize);

	float2 offset = floor(float(time % 48)/6.0)*6.0/48.0*tileSize;

	bool draw = false;
	if (tileCoord.y == 0.0 || tileCoord.y == tileSize.y - 1.0) {
		float lengthDrawn = map(inCol.a, 0.1, 0.25, tileSize.x/4.0, tileSize.x/2.0);
		if (coordInOffsetSegment(tileCoord.x, offset.x, lengthDrawn, tileSize.x)) { draw = true; }
	}
	if (tileCoord.x == 0.0 || tileCoord.x == tileSize.x - 1.0) {
		float lengthDrawn = map(inCol.a, 0.1, 0.25, tileSize.y/4.0, tileSize.y/2.0);
		if (coordInOffsetSegment(tileCoord.y, offset.y, lengthDrawn, tileSize.y)) { draw = true; }
	}

	// GLSL wrote vec4(0) for non-drawn pixels; discard is the depth-safe equivalent under blending
	if (!draw) discard;
	return inCol*color;
}
