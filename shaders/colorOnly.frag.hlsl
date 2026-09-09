/*
Port of colorOnly.frag.
The texture only supplies a mask; the colour comes entirely from the instance.
*/

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float a = tex.Sample(texSampler, uv).a * color.a;
	if (a == 0.0) discard;
	return float4(color.rgb, a);
}
