/*
Port of palSwap.frag: match each texel against a palette of source colours and replace it with a mix of two destination palettes, so one sprite can be recoloured many ways.
Every palette lives packed in the shared persistent palette buffer (one rgba8 uint per colour, built at asset load); the uniforms carry element offsets into it.
*/

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);
StructuredBuffer<uint> palettes : register(t1, space2); // storage buffers continue the t numbering after the sampled textures

cbuffer Uniforms : register(b0, space3) {
	int   paletteSize;
	float destMix;
	int   alwaysApplyWithShortestDistance; // was a GLSL bool
	int   blendmode;
	int   sourceOff; // element offsets into palette: the source column and the two dest columns being mixed
	int   dest1Off;
	int   dest2Off;
};

static const float PAL_TOLERANCE = 0.004;

float3 palColor(int ind) {
	uint c = palettes[ind];
	return float3(c & 0xFF, (c >> 8) & 0xFF, (c >> 16) & 0xFF)/255.0;
}

float3 hardLight(float3 base, float3 blend) {
	float3 low  = 2.0*base*blend;                       // when blend < 0.5
	float3 high = 1.0 - 2.0*(1.0 - base)*(1.0 - blend); // when blend >= 0.5
	return lerp(low, high, step(0.5, blend));
}

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float4 texel = tex.Sample(texSampler, uv);
	if (texel.a == 0.0) discard;

	float3 destCol = float3(0.0, 0.0, 0.0);

	if (alwaysApplyWithShortestDistance != 0) {
		float shortestDist = 2.0;
		int shortestDistIndex = 0;
		[loop] for (int i = 0; i < paletteSize; ++i) {
			float dist = distance(texel.rgb, palColor(sourceOff + i));
			if (dist < shortestDist) {
				shortestDist = dist;
				shortestDistIndex = i;
			}
		}
		destCol = lerp(palColor(dest1Off + shortestDistIndex), palColor(dest2Off + shortestDistIndex), destMix);
	} else {
		bool broke = false;
		[loop] for (int i = 0; i < paletteSize; ++i) {
			if (distance(texel.rgb, palColor(sourceOff + i)) < PAL_TOLERANCE) {
				destCol = lerp(palColor(dest1Off + i), palColor(dest2Off + i), destMix);
				broke = true;
				break;
			}
		}
		//no palette entry matched, the texel passes through untouched
		if (!broke) return texel*color;
	}

	//the instance colour is applied at a different point per blendmode, exactly as the original did
	float4 outColor = texel;
	if (blendmode == 0) {        // replace
		outColor.rgb = destCol;
		outColor *= color;
	} else if (blendmode == 1) { // multiply
		outColor *= color;
		outColor.rgb *= destCol;
	} else {                     // hard light
		outColor *= color;
		outColor.rgb = hardLight(outColor.rgb, destCol);
	}
	return outColor;
}
