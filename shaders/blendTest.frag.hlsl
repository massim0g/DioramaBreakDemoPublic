// Port of blendTest.frag: debug shader. The live GLSL code only visualized the mask texture's size
// (the overlay-blend path was commented out); ported faithfully, including the dead helper.

Texture2D tex : register(t0, space2);         // sprite
SamplerState texSampler : register(s0, space2);
Texture2D mask : register(t1, space2);        // lighting mask
SamplerState maskSampler : register(s1, space2);

// no uniforms

float3 overlayBlend(float3 base, float3 m) {
	float3 low  = 2.0*base*m;
	float3 high = 1.0 - 2.0*(1.0 - base)*(1.0 - m);
	return lerp(low, high, step(0.5, base));
}

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float4 b = tex.Sample(texSampler, uv);
	float4 m = mask.Sample(maskSampler, uv);

	// Keep both textures reflected as sampler bindings: without a live use of the Sample results, DXC
	// culls tex entirely and demotes mask (GetDimensions-only) to a storage texture, breaking the
	// t0/s0 + t1/s1 binding convention. This guard never fires for real texture data.
	if (b.a < -1.0 || m.a < -1.0) discard;

	uint maskW, maskH;
	mask.GetDimensions(maskW, maskH);

	float4 outColor;
	outColor.rg = float2(maskW, maskH)/255.0/10.0;
	outColor.ba = float2(0.0, 1.0);
	return outColor;
}
