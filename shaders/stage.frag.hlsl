/*
Port of stage.frag: the world-sprite shader that applies the stage's shadow map and the time-stop desaturation.
Samples a row of the shadow map at the quad's feetPos, across the quad's drawn width, and blends toward shadowBlend (multiply) or lightBlend (overlay) depending on the sign of the sampled mask.
The per-quad data (feetPos, width, the verticalShading toggle) rides in the instance record and arrives as flat varyings, so shaded entities can batch.

FLAGGED for verification: the V coordinate assumes the shadow map is rendered with the same top-left convention as everything else.
If shading appears on the wrong side vertically, flip to 1 - (feetPos.y - stageRect.y)/stageRect.w. See shaders/_port_report.md.
*/

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);
Texture2D shadowMap : register(t1, space2);
SamplerState shadowMapSampler : register(s1, space2);

cbuffer Uniforms : register(b0, space3) {
	float4 stageRect;          // xy = pos, zw = size, the world rect the shadow map covers
	float4 shadowBlend;
	float4 lightBlend;
	float  timeStopSaturation;
	int    timeStopEffect;     // was a GLSL bool
};

float sampleShadowMap(float2 samplePos) {
	float4 smp = shadowMap.Sample(shadowMapSampler, (samplePos - stageRect.xy)/stageRect.zw);
	return (smp.r*2.0 - 1.0)*smp.a;
}

float overlay(float dst, float src) {
	if (dst < 0.5) {
		return 2.0*dst*src;
	} else {
		return 1.0 - 2.0*(1.0 - dst)*(1.0 - src);
	}
}

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1, nointerpolation float4 stageShading : TEXCOORD2) : SV_Target0 {
	float4 base = tex.Sample(texSampler, uv) * color;

	if (stageShading.w != 0) {
		float2 feetPos = stageShading.xy;
		float width = stageShading.z;
		float left = feetPos.x - width/2.0;
		float sampleCount = 16.0;
		float shadowCount = 0.0;
		for (float i = 0.0; i < sampleCount; i++) {
			shadowCount += sampleShadowMap(float2(left + width*(i/sampleCount), feetPos.y));
		}
		float mask = shadowCount/sampleCount;

		if (mask <= 0.0) {
			base.rgb = lerp(base.rgb, base.rgb*shadowBlend.rgb, shadowBlend.a*-mask);
		} else {
			float3 overlaid;
			overlaid.r = overlay(base.r, lightBlend.r);
			overlaid.g = overlay(base.g, lightBlend.g);
			overlaid.b = overlay(base.b, lightBlend.b);
			base.rgb = lerp(base.rgb, overlaid, lightBlend.a*mask);
		}
	}

	if (timeStopEffect != 0) {
		float luma = dot(base.rgb, float3(0.299, 0.587, 0.114));
		base.rgb = lerp(float3(luma, luma, luma), base.rgb, timeStopSaturation);
	}

	return base;
}
