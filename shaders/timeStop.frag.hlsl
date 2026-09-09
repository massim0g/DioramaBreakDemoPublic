// Port of timeStop.frag: fixed 0.5-saturation desaturate. (GLSL marked DEPRECATED, rolled into stage.)

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

// no uniforms

static const float saturation = 0.5;

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float4 outColor = tex.Sample(texSampler, uv)*color;
	float luma = dot(outColor.rgb, float3(0.299, 0.587, 0.114));
	outColor.rgb = lerp(float3(luma, luma, luma), outColor.rgb, saturation);
	// keep fully transparent pixels from writing depth (sprite.frag.hlsl convention; GLSL relied on blending)
	if (outColor.a == 0.0) discard;
	return outColor;
}
