// Port of addFade.frag: sample*color plus a flat additive brightness offset.

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

cbuffer Uniforms : register(b0, space3) {
	float add; // offset 0
};             // total size 16 (cbuffer rounds up)

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float4 base = tex.Sample(texSampler, uv)*color;
	// keep fully transparent pixels from writing depth (sprite.frag.hlsl convention; GLSL relied on blending)
	if (base.a == 0.0) discard;
	base.rgb += add.xxx;
	return base;
}
