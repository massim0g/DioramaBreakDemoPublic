// Port of shadowLayer.frag: applies a shadow/light mask texture onto a sampled destination texture.
// Near-white mask pixels apply lightBlend as overlay; darker ones multiply in shadowBlend.
// Manual-blend shader: always writes dst-derived output, so no alpha discard.

Texture2D tex : register(t0, space2);         // shadow/light mask
SamplerState texSampler : register(s0, space2);
Texture2D destination : register(t1, space2); // scene copy, same UV space as tex
SamplerState destinationSampler : register(s1, space2);

cbuffer Uniforms : register(b0, space3) {
	float4 shadowBlend; // offset 0
	float4 lightBlend;  // offset 16
};                      // total size 32

float overlay(float dst, float src) {
	if (dst < 0.5) {
		return 2.0*dst*src;
	} else {
		return 1.0 - 2.0*(1.0 - dst)*(1.0 - src);
	}
}

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float4 src = tex.Sample(texSampler, uv);
	float4 dst = destination.Sample(destinationSampler, uv);

	if (src.a == 0.0) {
		return dst;
	}

	float4 outColor;
	if (distance(src.rgb, float3(1.0, 1.0, 1.0)) < distance(src.rgb, float3(0.0, 0.0, 0.0))) { // light
		float3 overlaid;
		overlaid.r = overlay(dst.r, lightBlend.r);
		overlaid.g = overlay(dst.g, lightBlend.g);
		overlaid.b = overlay(dst.b, lightBlend.b);
		float k = lightBlend.a*src.a;
		outColor.rgb = lerp(dst.rgb, overlaid, k);
	} else { // shadow
		float k = shadowBlend.a*src.a;
		outColor.rgb = lerp(dst.rgb, dst.rgb*shadowBlend.rgb, k);
	}
	outColor.a = dst.a;
	return outColor;
}
