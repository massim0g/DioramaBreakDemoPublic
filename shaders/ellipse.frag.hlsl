// Analytic ellipse/ring renderer: draws one quad and evaluates the rings per pixel instead of CPU-tessellating triangles.
// Rings are concentric ellipse contours from outermost to innermost; each pixel interpolates the blends of the two rings bracketing it along its ray from the center.

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

cbuffer Uniforms : register(b0, space3) {
	float2 rectSize;     // the drawn quad's size in world pixels; the quad is centered on the rings, so uv alone locates the pixel
	float  edgeSoftness; // antialiasing width in pixels at the outermost (and innermost, when above zero radius) ring
	int    ringCount;
	float4 ringRadii[8];  // xy = ring radii, outermost first
	float4 ringBlends[8]; // rgba per ring
};

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	// The shader never uses the texture, but every fragment shader must keep t0/s0 reflected for the binding convention.
	// This guard never fires for real texture data.
	if (tex.Sample(texSampler, uv).a < -1.0) discard;

	float2 p = (uv - 0.5)*rectSize;
	float d = length(p); //pixel's distance from center
	if (d < 1e-3) { p = float2(1e-3, 0.0); d = 1e-3; }

	// distance from the center to each ring along this pixel's ray
	float R[8];
	[loop] for (int i = 0; i < ringCount; i += 1) {
		R[i] = d/length(p/max(ringRadii[i].xy, 1e-4));
	}

	bool hollow = ringRadii[ringCount - 1].x + ringRadii[ringCount - 1].y > 0.0; // an innermost ring above zero radius leaves the center transparent
	float fade = 1.0;
	if (edgeSoftness <= 0.0) { // hard edges: plain in/out test
		if (d > R[0] || (hollow && d < R[ringCount - 1])) discard;
	}
	else { // antialiased edges: alpha ramps over edgeSoftness pixels at the boundaries
		fade = saturate((R[0] - d)/edgeSoftness);
		if (hollow) fade *= saturate((d - R[ringCount - 1])/edgeSoftness);
		if (fade <= 0.0) discard;
	}

	float4 band = ringBlends[ringCount - 1];
	[loop] for (int b = 0; b < ringCount - 1; b += 1) {
		if (d >= R[b + 1]) {
			float t = saturate((d - R[b + 1])/max(R[b] - R[b + 1], 1e-4));
			band = lerp(ringBlends[b + 1], ringBlends[b], t);
			break;
		}
	}

	band.a *= fade;
	return band*color;
}
