// Port of actionTarget.frag: action-target overlay with angular outline reveal, stencil-overlap darkening,
// and silhouette mode (drawMode 2) comparing pre/post scene textures at the current screen pixel.

Texture2D tex : register(t0, space2);            // was: uniform sampler2D texture (target sprite)
SamplerState texSampler : register(s0, space2);
Texture2D stencilTex : register(t1, space2);     // overlap-count stencil
SamplerState stencilTexSampler : register(s1, space2);
Texture2D floorTex : register(t2, space2);       // scene before target draw
SamplerState floorTexSampler : register(s2, space2);
Texture2D mainTex : register(t3, space2);        // scene after target draw
SamplerState mainTexSampler : register(s3, space2);

cbuffer Uniforms : register(b0, space3) {
	float2 texSize;            // offset 0
	float2 stencilTexSize;     // offset 8
	float2 centerPos;          // offset 16, relative to camera pos
	float2 stencilOffset;      // offset 24, offset from target draw pos to stencil tex origin, in pixels
	float2 floorTexSize;       // offset 32
	float  outlineRevealAngle; // offset 40, 0-90
	int    drawMode;           // offset 44; 0 = fill only, 1 = outline only, 2 = silhouette
};                             // total size 48

static const float PI = 3.1415926538;

int valCheck(float2 checkPos) {
	return (checkPos.x < 0.0 || checkPos.x >= texSize.x || checkPos.y < 0.0 || checkPos.y >= texSize.y
		|| tex.Sample(texSampler, checkPos/texSize).a == 0.0) ? 1 : 0;
}

float vec2_angle(float2 v) {
	float a = atan2(-v.y, v.x)*(180.0/PI);
	if (a < 0.0) {
		a += 360.0;
	}
	return a;
}

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1, nointerpolation float4 stageShading : TEXCOORD2, float4 svPos : SV_Position) : SV_Target0 {
	float4 src = tex.Sample(texSampler, uv);

	src.rgb *= color.rgb;
	float alpha = src.a*color.a;

	if (src.a != 0.0) {
		float2 pos = uv*texSize;
		int darkerNeighbours = (
			valCheck(float2(pos.x+1.0, pos.y)) +
			valCheck(float2(pos.x+1.0, pos.y-1.0)) +
			valCheck(float2(pos.x,     pos.y-1.0)) +
			valCheck(float2(pos.x-1.0, pos.y-1.0)) +
			valCheck(float2(pos.x-1.0, pos.y)) +
			valCheck(float2(pos.x-1.0, pos.y+1.0)) +
			valCheck(float2(pos.x,     pos.y+1.0)) +
			valCheck(float2(pos.x+1.0, pos.y+1.0))
		);
		bool isOutline = false;
		if (darkerNeighbours > 0) {
			// vec2_angle result is always in [0, 360), so fmod is safe here
			float angle = fmod(vec2_angle(pos - centerPos), 90.0);
			if (angle <= outlineRevealAngle) {
				isOutline = true;
			}
		}

		if (drawMode == 0 && isOutline) discard;
		if (drawMode == 1 && !isOutline) discard;

		float2 stencilUV = (uv*texSize + stencilOffset)/stencilTexSize;
		int overlapCount = (int)(stencilTex.Sample(stencilTexSampler, stencilUV).a*16.0 + 0.5);
		float stencilVal = clamp((overlapCount - 1.0)*(1.0/3.0), 0.0, 1.0);
		src.rgb = lerp(src.rgb, float3(0.11, 0.03, 0.09), stencilVal);

		if (isOutline) {
			alpha = min(alpha*3.0, 1.0);
			float luma = dot(src.rgb, float3(0.299, 0.587, 0.114));
			src.rgb = clamp(lerp(float3(luma, luma, luma), src.rgb, 1.5), 0.0, 1.0);
		}

		if (drawMode == 2) {
			// GLSL did screenUV = gl_FragCoord.xy/floorTexSize then flipped Y (bottom-left -> top-left).
			// SV_Position is already top-left, so no flip. FLAGGED for visual verification.
			float2 screenUV = svPos.xy/floorTexSize;
			float4 pre = floorTex.Sample(floorTexSampler, screenUV);
			float4 post = mainTex.Sample(mainTexSampler, screenUV);
			if (all(pre == post)) discard;
		}
	}

	return float4(src.rgb, alpha);
}
