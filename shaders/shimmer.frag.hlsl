/*
Port of shimmer.frag.
The horizontal offset is scaled by one texel of the source, so the wobble stays the same size on screen
regardless of the page resolution.
*/

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

cbuffer Uniforms : register(b0, space3) {
	float time;
};

static const float PI = 3.1415926535897932384626433832795;

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	uint texW, texH;
	tex.GetDimensions(texW, texH);

	float2 tCoord = uv;
	tCoord.x += sin(uv.y*6000.0*PI + time/5.0)*(1.0/float(texW))*0.6;

	float4 base = tex.Sample(texSampler, tCoord) * color;
	if (base.a == 0.0) discard;
	return base;
}
