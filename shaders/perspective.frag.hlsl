// Port of perspective.frag: homography-projects the quad's screen-space position through a 3x3 transform
// into unit UV space, sampling the texture there.
// FLAGGED for verification: the transform matrix is CPU-computed; its coordinate conventions
// (Y direction of the "screen coord" input space) were tied to the GL pipeline. See _port_report.md.

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

cbuffer Uniforms : register(b0, space3) {
	// column_major (DXC cbuffer default), matching GLSL uniformMatrix3fv layout:
	// upload 3 columns of 3 floats, each column padded to 16 bytes (offsets 0, 16, 32; 12 bytes used each)
	float3x3 transform;  // offset 0, size 44 (padded region ends at 48)
	float2   screenSize; // offset 48
};                       // total size 64

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float3 screen_coord = float3(uv*screenSize, 1.0);
	float3 unit_coord = mul(transform, screen_coord); // == GLSL transform * screen_coord
	unit_coord /= unit_coord.z;
	float2 puv = unit_coord.xy;

	// Discard fragments outside the unit square.
	if (puv.x < 0.0 || puv.x > 1.0 || puv.y < 0.0 || puv.y > 1.0) {
		discard;
	}

	float4 texColor = tex.Sample(texSampler, puv);
	if (all(texColor == float4(1.0, 1.0, 1.0, 0.0))) {
		puv = round(puv*screenSize)/screenSize;
		texColor = tex.Sample(texSampler, puv);
	}
	return texColor*color;
}
