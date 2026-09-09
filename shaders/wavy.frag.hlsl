/*
Port of wavy.frag.
NOTE: the red-channel overwrite below is a debug leftover from the original GLSL. It is preserved
deliberately so the effect keeps looking the way it does in the shipped game.
*/

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

cbuffer Uniforms : register(b0, space3) {
	float time;
};

static const float PI = 3.1415926535897932384626433832795;

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float2 tCoord = uv;
	tCoord.x += sin(tCoord.y/0.5*PI + time/100.0)*0.05;

	float4 base = tex.Sample(texSampler, tCoord) * color;
	base.r = sin(time/1000.0);

	if (base.a == 0.0) discard;
	return base;
}
