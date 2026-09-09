// Port of leaves.frag: 5x5 gaussian bloom on pixels matching lightColor, with random intensity variation,
// composited additively over the scene. Full-screen pass; always writes alpha 1.

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

cbuffer Uniforms : register(b0, space3) {
	float4 lightColor; // offset 0; .rgb used, .w is padding (GLSL was vec3)
};                     // total size 16

static const float2 resolution = float2(480.0, 270.0);
static const float bloomIntensity = 1.0;
static const float sigma = 1.0;
static const float bloomRandomVariation = 0.3; // 0-1, makes bloom randomly less intense

// Gaussian weight function: higher sigma = wider blur
float gaussianWeight(float x, float y) {
	return exp(-(x*x + y*y)/(2.0*sigma*sigma));
}

// A simple random function for noise
float random(float2 st) {
	return frac(sin(dot(st.xy, float2(12.9898, 78.233)))*43758.5453123);
}

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	// Sample the original scene color.
	float3 sceneColor = tex.Sample(texSampler, uv).rgb;

	// Brightness mask for the current pixel.
	float3 mask = (distance(sceneColor, lightColor.rgb) < 0.01) ? sceneColor : float3(0.0, 0.0, 0.0);

	// Accumulate a Gaussian-blurred bloom from a 5x5 kernel.
	float3 bloom = float3(0.0, 0.0, 0.0);
	float totalWeight = 0.0;

	for (int i = -2; i <= 2; i++) {
		for (int j = -2; j <= 2; j++) {
			float2 offset = float2(float(i), float(j))/resolution;
			float3 sampleColor = tex.Sample(texSampler, uv + offset).rgb;
			float3 sampleMask = (distance(sampleColor, lightColor.rgb) < 0.01) ? sampleColor : float3(0.0, 0.0, 0.0);
			float weight = gaussianWeight(float(i), float(j));
			bloom += sampleMask*weight;
			totalWeight += weight;
		}
	}

	bloom /= totalWeight;

	// add random noise to bloom intensity
	float noise = random(uv*resolution);
	bloom *= 1.0 - bloomRandomVariation*noise;

	return float4(sceneColor + bloom*(1.0 - sceneColor)*bloomIntensity, 1.0);
}
