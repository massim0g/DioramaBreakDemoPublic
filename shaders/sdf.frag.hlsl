// Port of sdf.frag: fills pixels inside a smooth-min union of SDF shapes with the instance color.
// Shapes ride in the frame's shape stream buffer, referenced by offset+count, so there is no per-draw shape cap.

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);
StructuredBuffer<float4> sdfShapes : register(t1, space2); // circle: xy = center, z = radius; w = shape tag

cbuffer Uniforms : register(b0, space3) {
	float2 rectPos;    // the drawn quad's world rect, for reconstructing the field position from uv
	float2 rectSize;
	float2 offset;     // added to the field position; shape coords are relative to it
	float  k;          // smooth-min strength
	int    firstShape; // this draw's range in the shape stream
	int    shapeCount;
};

// quadratic polynomial smooth min
float smin(float a, float b) {
	float h = max(k*4.0 - abs(a - b), 0.0)/(k*4.0);
	return min(a, b) - h*h*k;
}

float sdfShape(float2 pos, float4 shape) {
	int tag = int(shape.w);
	if (tag == 1) { // circle
		return distance(pos, shape.xy) - shape.z;
	}
	return 0.0;
}

float sdf_union(float2 pos) {
	float res = sdfShape(pos, sdfShapes[firstShape]);
	[loop] for (int i = 1; i < shapeCount; i += 1) {
		res = smin(res, sdfShape(pos, sdfShapes[firstShape + i]));
	}
	return res;
}

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1, nointerpolation float4 stageShading : TEXCOORD2, float4 position : SV_Position) : SV_Target0 {
	// The shader never uses the texture, but every fragment shader must keep t0/s0 reflected for the binding convention.
	// This guard never fires for real texture data.
	if (tex.Sample(texSampler, uv).a < -1.0) discard;

	float2 pixelPos = offset + rectPos + uv*rectSize;
	if (sdf_union(pixelPos) > 0.0) { discard; }
	return color;
}
