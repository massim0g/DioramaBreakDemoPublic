// Port of indoorColorTest.frag: modulate by instance color and inputCols[0].
// The GLSL's rgb2hsv/hsv2rgb helpers were dead code and are not ported.

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

cbuffer Uniforms : register(b0, space3) {
	float4 inputCols[4]; // offset 0, stride 16; only [0] is used
};                       // total size 64

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float4 outColor = tex.Sample(texSampler, uv)*color;
	outColor *= inputCols[0];
	// keep fully transparent pixels from writing depth (sprite.frag.hlsl convention; GLSL relied on blending)
	if (outColor.a == 0.0) discard;
	return outColor;
}
