// Port of meditationBG.frag: animated fBm Perlin noise mapped through a black->midtone->white ramp,
// quantized. Ignores the bound texture's color (the GLSL sampled it into an unused variable).
// NOTE: like the GLSL, roundStep is 0 when strength == 0 (division by zero -> NaN); CPU side presumably
// never draws this with strength exactly 0, preserved bug-for-bug.

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

cbuffer Uniforms : register(b0, space3) {
	float time;     // offset 0, seconds (or any time base)
	float strength; // offset 4, 0..1
	float scale;    // offset 8, noise frequency scale (e.g. 2.0..6.0)
};                  // total size 16

// ----- 3D Perlin (value-compatible) -----
float fade(float t) { return t*t*t*(t*(t*6.0 - 15.0) + 10.0); }

float hash3(float3 p) {
	// Lattice hash.
	// The fmod bounds the coords so precision never degrades and the noise tiles seamlessly every 289 cells.
	p = fmod(p, 289.0);
	p = frac(p*float3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yzx + 33.33);
	return frac((p.x + p.y)*p.z);
}

float3 grad3(float h) {
	int i = int(fmod(floor(h*12.0), 12.0)); // h >= 0, fmod safe
	if (i == 0) return float3( 1, 1, 0);
	if (i == 1) return float3(-1, 1, 0);
	if (i == 2) return float3( 1,-1, 0);
	if (i == 3) return float3(-1,-1, 0);
	if (i == 4) return float3( 1, 0, 1);
	if (i == 5) return float3(-1, 0, 1);
	if (i == 6) return float3( 1, 0,-1);
	if (i == 7) return float3(-1, 0,-1);
	if (i == 8) return float3( 0, 1, 1);
	if (i == 9) return float3( 0,-1, 1);
	if (i == 10) return float3( 0, 1,-1);
	return float3( 0,-1,-1);
}

float perlin(float3 p) {
	float3 pi = floor(p);
	float3 pf = p - pi;

	float3 f = float3(fade(pf.x), fade(pf.y), fade(pf.z));

	// Corner hashes -> gradients
	float n000 = hash3(pi + float3(0.0, 0.0, 0.0));
	float n100 = hash3(pi + float3(1.0, 0.0, 0.0));
	float n010 = hash3(pi + float3(0.0, 1.0, 0.0));
	float n110 = hash3(pi + float3(1.0, 1.0, 0.0));
	float n001 = hash3(pi + float3(0.0, 0.0, 1.0));
	float n101 = hash3(pi + float3(1.0, 0.0, 1.0));
	float n011 = hash3(pi + float3(0.0, 1.0, 1.0));
	float n111 = hash3(pi + float3(1.0, 1.0, 1.0));

	float3 g000 = grad3(n000), g100 = grad3(n100);
	float3 g010 = grad3(n010), g110 = grad3(n110);
	float3 g001 = grad3(n001), g101 = grad3(n101);
	float3 g011 = grad3(n011), g111 = grad3(n111);

	float d000 = dot(g000, pf - float3(0, 0, 0));
	float d100 = dot(g100, pf - float3(1, 0, 0));
	float d010 = dot(g010, pf - float3(0, 1, 0));
	float d110 = dot(g110, pf - float3(1, 1, 0));
	float d001 = dot(g001, pf - float3(0, 0, 1));
	float d101 = dot(g101, pf - float3(1, 0, 1));
	float d011 = dot(g011, pf - float3(0, 1, 1));
	float d111 = dot(g111, pf - float3(1, 1, 1));

	float x00 = lerp(d000, d100, f.x);
	float x10 = lerp(d010, d110, f.x);
	float x01 = lerp(d001, d101, f.x);
	float x11 = lerp(d011, d111, f.x);

	float y0 = lerp(x00, x10, f.y);
	float y1 = lerp(x01, x11, f.y);

	// Range roughly [-1,1]
	return lerp(y0, y1, f.z);
}

// Simple fBm for richer structure
float fbm(float3 p) {
	float a = 0.5;
	float sum = 0.0;
	float norm = 0.0;
	for (int i = 0; i < 4; ++i) {
		sum += a*perlin(p);
		norm += a;
		p *= 2.0;
		a *= 0.5;
	}
	return sum/norm*0.5 + 0.5; // map to [0,1]
}

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float s = clamp(strength, 0.0, 1.0);

	// Sample a moving 2D slice through 3D noise
	float freq = max(scale, 0.0001);
	float2 noiseUV = uv*freq;
	float z = time*0.003; // slice speed
	float n = fbm(float3(noiseUV, z)); // 0..1

	float3 midTone = float3(70.0/255.0, 80.0/255.0, 87.0/255.0);
	float3 white = float3(247.0/255.0, 242.0/255.0, 216.0/255.0);

	float a = clamp(s*2.0, 0.0, 1.0);         // 0..0.5 phase (visibility up to purple)
	float b = clamp((s - 0.5)*2.0, 0.0, 1.0); // 0.5..1 phase (fade tips to white)

	float i0 = 0.5*a*n;            // 0..~0.5
	float i = lerp(i0, 1.0, b*n);  // move tips along ramp to white
	i = lerp(i, 1.0, b);

	float3 outRGB;

	if (i < 0.5) {
		float k = i*2.0;           // 0..1 : black -> purple
		outRGB = lerp(float3(0.0, 0.0, 0.0), midTone, k);
	} else {
		float k = (i - 0.5)*2.0;   // 0..1 : purple -> white
		outRGB = lerp(midTone, white, k);
	}

	float roundStep = lerp(0.0, 0.07, s);
	outRGB = round(outRGB/roundStep)*roundStep;

	// GLSL sampled the texture into an unused variable; keep a live use so the t0/s0 binding survives
	// DXC dead-code elimination (guard never fires for real texture data).
	if (tex.Sample(texSampler, uv).a < -1.0) discard;

	return float4(outRGB, color.a);
}
