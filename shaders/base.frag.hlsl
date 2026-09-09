/*
The base fragment shader: what draws use when no shader is pushed.
SDL_Renderer used to provide this implicitly, so it has to reproduce exactly what a plain RenderTexture
did -- sample the texture, modulate by the per-instance colour, nothing else.
*/

Texture2D<float4> tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	return tex.Sample(texSampler, uv) * color;
}
