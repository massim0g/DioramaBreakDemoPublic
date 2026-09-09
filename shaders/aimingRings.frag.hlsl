// Port of aimingRings.frag: overlay-blends the ring sprite onto a sampled destination texture,
// with an angular outline reveal drawn opaque. Manual-blend shader: always writes dst-derived output,
// so no alpha discard here.

Texture2D tex : register(t0, space2);            // ring sprite
SamplerState texSampler : register(s0, space2);
Texture2D destination : register(t1, space2);    // destination/scene copy, same UV space as tex
SamplerState destinationSampler : register(s1, space2);

cbuffer Uniforms : register(b0, space3) {
	float2 texSize;            // offset 0
	float2 centerPos;          // offset 8, relative to camera pos
	float  outlineRevealAngle; // offset 16, 0-90
};                             // total size 32

static const float PI = 3.1415926538;

float overlay(float dst, float src) {
	if (dst < 0.5) {
		return 2.0*dst*src;
	} else {
		return 1.0 - 2.0*(1.0 - dst)*(1.0 - src);
	}
}

int valCheck(float4 src, float4 check) {
	float srcTot = src.r + src.g + src.b;
	float checkTot = check.r + check.g + check.b;
	return (srcTot > checkTot || check.a == 0.0) ? 1 : 0;
}

float vec2_angle(float2 v) {
	float a = atan2(-v.y, v.x)*(180.0/PI);
	if (a < 0.0) {
		a += 360.0;
	}
	return a;
}

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	float4 src = tex.Sample(texSampler, uv);
	float4 dst = destination.Sample(destinationSampler, uv);

	float alpha = src.a*color.a;
	if (alpha == 0.0) {
		return dst;
	}

	float2 pos = uv*texSize;
	int darkerNeighbours = (
		valCheck(src, tex.Sample(texSampler, float2(pos.x+1.0, pos.y)/texSize)) +
		valCheck(src, tex.Sample(texSampler, float2(pos.x+1.0, pos.y-1.0)/texSize)) +
		valCheck(src, tex.Sample(texSampler, float2(pos.x,     pos.y-1.0)/texSize)) +
		valCheck(src, tex.Sample(texSampler, float2(pos.x-1.0, pos.y-1.0)/texSize)) +
		valCheck(src, tex.Sample(texSampler, float2(pos.x-1.0, pos.y)/texSize)) +
		valCheck(src, tex.Sample(texSampler, float2(pos.x-1.0, pos.y+1.0)/texSize)) +
		valCheck(src, tex.Sample(texSampler, float2(pos.x,     pos.y+1.0)/texSize)) +
		valCheck(src, tex.Sample(texSampler, float2(pos.x+1.0, pos.y+1.0)/texSize))
	);
	if (darkerNeighbours > 0) {
		// vec2_angle result is always in [0, 360), so fmod is safe here
		float angle = fmod(vec2_angle(pos - centerPos), 90.0);
		if (angle <= outlineRevealAngle) {
			return float4(src.rgb, dst.a);
		}
	}

	float3 overlaid;
	overlaid.r = overlay(dst.r, src.r);
	overlaid.g = overlay(dst.g, src.g);
	overlaid.b = overlay(dst.b, src.b);
	float k = alpha*alpha;
	return float4(lerp(dst.rgb, overlaid, k), dst.a);
}
