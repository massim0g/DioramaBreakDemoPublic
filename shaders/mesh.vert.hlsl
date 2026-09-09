/*
Mesh-puller vertex shader for arbitrary triangle geometry (circles, rings, godray fans, foliage meshes).
Vertices are pulled from a storage buffer of pre-transformed world-space vertices.
Must match Vertex in render.odin.
*/

struct Vertex {
	float2 pos;   // world pixels, camera applied below
	float2 uv;
	uint   blend; // rgba bytes; hlsl has no 8-bit scalar, so it arrives as a packed uint
	uint   _pad;
};

StructuredBuffer<Vertex> vertices : register(t0, space0);

cbuffer BatchUniforms : register(b0, space1) {
	float2 targetSize;
	float2 camPos;     // current camera position, subtracted from positions
	uint   firstIndex; // first vertex of this batch (uniform for the same backend-divergence reason as quad.vert)
	float  coordScale; // the target's position multiplier, so native-res draws can compose into a window-res target
};

struct Output {
	float4 color : TEXCOORD0;
	float2 uv    : TEXCOORD1;
	nointerpolation float4 stageShading : TEXCOORD2; // stage.frag reads this from every vertex shader; always zero here, meshes never vertical-shade
	float4 position : SV_Position;
};

Output main(uint vertexIndex : SV_VertexID) {
	Vertex v = vertices[firstIndex + vertexIndex];

	float2 ndc = (v.pos - camPos)*coordScale/targetSize*2 - 1;

	Output output;
	output.position = float4(ndc.x, -ndc.y, 0, 1);
	output.uv = v.uv;
	output.color = float4(v.blend & 0xFF, (v.blend >> 8) & 0xFF, (v.blend >> 16) & 0xFF, (v.blend >> 24) & 0xFF) / 255.0;
	output.stageShading = float4(0, 0, 0, 0);
	return output;
}
