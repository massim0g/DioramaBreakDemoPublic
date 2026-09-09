// Port of combatCursor.frag: animated darkening pulses running around the perimeter of a rect.
// The GLSL had its texture sampler commented out, so no texture is declared here either.

cbuffer Uniforms : register(b0, space3) {
	float2 rectSize; // offset 0, in pixels
	float  time;     // offset 8
};                   // total size 16

static const float loopDuration = 88.0;
static const float trailLength = 8.0;
static const float darkenAmount = 0.75;

float remap(float old_value, float old_min, float old_max, float new_min, float new_max) {
	float old_range = old_max - old_min;
	float new_range = new_max - new_min;
	return ((old_value - old_min)/old_range)*new_range + new_min;
}

// GLSL-style mod (floored); operand can dip to exactly -0 range edges, keep it exact
float glslMod(float x, float y) {
	return x - y*floor(x/y);
}

float getDarkenMul(float darkenPos, float perimPos, float perimSize) {
	float dist = glslMod(darkenPos - perimPos + perimSize, perimSize);
	if (dist > trailLength) { return 1.0; }
	return remap(dist, 0.0, trailLength, darkenAmount, 1.0);
}

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float2 rectPos = floor(uv*rectSize);

	float perimSize = (rectSize.x - 1.0)*2.0 + (rectSize.y - 1.0)*2.0;
	float perimPos = 0.0;
	if (rectPos.y == 0.0) {
		perimPos = rectPos.x;
	} else if (rectPos.x == rectSize.x - 1.0) {
		perimPos = rectSize.x - 1.0 + rectPos.y;
	} else if (rectPos.y == rectSize.y - 1.0) {
		perimPos = (rectSize.x - 1.0)*2.0 + rectSize.y - 1.0 - rectPos.x;
	} else if (rectPos.x == 0.0) {
		perimPos = perimSize - rectPos.y;
	} else {
		discard;
	}

	float t = floor(time/3.0)*3.0;
	float darkenPosA = floor(frac(t/loopDuration)*perimSize);
	float darkenPosB = floor(frac(t/loopDuration + 0.5)*perimSize);

	float4 outColor = color;
	outColor.rgb *= getDarkenMul(darkenPosA, perimPos, perimSize)*getDarkenMul(darkenPosB, perimPos, perimSize);
	return outColor;
}
