// Port of screen.frag: screen-blends the sprite onto a sampled destination texture (manual blend;
// always writes dst-derived output, so no alpha discard).

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);
Texture2D destination : register(t1, space2);
SamplerState destinationSampler : register(s1, space2);

cbuffer Uniforms : register(b0, space3) {
	float4 destRect; // offset 0, xy = pos, zw = size, in destination pixels
	float2 destSize; // offset 16
};                   // total size 32

float3 screenBlend(float3 base, float3 blend) {
	return 1.0 - (1.0 - base)*(1.0 - blend);
}

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float4 src = tex.Sample(texSampler, uv)*color;

	float2 destUV = (destRect.xy + uv*destRect.zw)/destSize;
	float4 dst = destination.Sample(destinationSampler, destUV);

	return float4(lerp(dst.rgb, screenBlend(dst.rgb, src.rgb), src.a), dst.a);
}
