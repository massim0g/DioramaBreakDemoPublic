// Port of stageTint.frag: applies a world-space 4-corner gradient tint (overlay/screen/replace) to the
// sprite based on where the current screen pixel falls inside gradientRect.
// FLAGGED for verification (Y axis): GLSL used gl_FragCoord (bottom-left origin) to build screenUV.
// This port uses SV_Position (top-left origin) directly, assuming viewRect.xy is the TOP-left of the
// view in a y-down world; if the old data assumed y-up (or relied on FBO flip), the gradient will be
// vertically flipped — see _port_report.md.
// NOTE: the GLSL screen() had a stray 2x (1 - 2*(1-base)*(1-blend)); preserved bug-for-bug.

Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

cbuffer Uniforms : register(b0, space3) {
	float4 colors[4];    // offset 0, stride 16: [0]=top-left, [1]=top-right, [2]=bottom-right, [3]=bottom-left
	float4 viewRect;     // offset 64, xy = pos, zw = size, world pixels
	float4 gradientRect; // offset 80, xy = pos, zw = size, world pixels
	float2 viewportSize; // offset 96, render target pixels
	int    clampGradient;// offset 104 (was bool)
	int    tintMode;     // offset 108: 0 = overlay, 1 = screen, 2 = replace
};                       // total size 112

/* Overlay(base, blend) per channel */
float3 overlay3(float3 base, float3 blend) {
	float3 low  = 2.0*base*blend;
	float3 high = 1.0 - 2.0*(1.0 - base)*(1.0 - blend);
	float3 selector = step(float3(0.5, 0.5, 0.5), base);
	return lerp(low, high, selector);
}
float3 screen3(float3 base, float3 blend) {
	return 1.0 - 2.0*(1.0 - base)*(1.0 - blend); // faithful to GLSL (non-standard screen formula)
}

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1, nointerpolation float4 stageShading : TEXCOORD2, float4 svPos : SV_Position) : SV_Target0 {
	float4 src = tex.Sample(texSampler, uv);

	if (src.a == 0.0) {
		// GLSL returned src*v_color with alpha 0; discard per sprite.frag.hlsl depth convention
		discard;
	}

	// GLSL: gl_FragCoord.xy/viewportSize (bottom-left origin). SV_Position is top-left: y = 0 at the
	// TOP of the target, so viewRect.xy must be the top-left corner of the view in world space.
	float2 screenUV = svPos.xy/viewportSize;

	// calc gradient pos in view pos
	float2 viewPos = viewRect.xy;
	float2 viewBr = viewRect.xy + viewRect.zw;
	float2 worldPos = lerp(viewPos, viewBr, screenUV);

	float2 gPos = gradientRect.xy;
	float2 gSize = gradientRect.zw;
	float2 gUV = (worldPos - gPos)/gSize;

	// clamp gradient coord if view is outside gradient rect
	if (clampGradient != 0 && (gUV.x < 0.0 || gUV.x > 1.0 || gUV.y < 0.0 || gUV.y > 1.0)) {
		return src*color;
	} else {
		gUV = clamp(gUV, 0.0, 1.0);
	}

	// calculate and apply gradient
	float4 top = lerp(colors[0], colors[1], gUV.x);
	float4 bot = lerp(colors[3], colors[2], gUV.x);
	float4 grad = lerp(top, bot, gUV.y);

	float k = clamp(grad.a, 0.0, 1.0);

	float3 tinted = float3(0.0, 0.0, 0.0);
	if (tintMode == 0) { tinted = overlay3(src.rgb, grad.rgb); }
	else if (tintMode == 1) { tinted = screen3(src.rgb, grad.rgb); }
	else if (tintMode == 2) { tinted = grad.rgb; }
	float3 res = lerp(src.rgb, tinted, k);

	return float4(res, src.a)*color;
}
