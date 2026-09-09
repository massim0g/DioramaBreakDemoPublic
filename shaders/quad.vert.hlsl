/*
Universal quad-puller vertex shader: no vertex buffers, quads are pulled from a storage buffer of instance records.
Draw with DrawGPUPrimitives(quadCount*6); each 6 consecutive vertex ids form one quad.
Must match Quad in render.odin.
Structured buffer stride is the struct size rounded up to its alignment, and uvRect's float4 makes that 16, so the struct has to stay a multiple of 16 bytes.
*/

struct Instance {
	float4 uvRect;    // normalized min.xy / max.zw
	float4 worldRect; // xy = top-left in world pixels (camera applied below), zw = size
	float2 feetPos;   // center-bottom world position where the entity touches the floor, for the stage shader's shadow sampling
	float2 pivot;     // rotation pivot relative to pos, in pixels
	float  rotation;  // radians, about pivot
	uint   blend;     // rgba bytes; hlsl has no 8-bit scalar, so it arrives as a packed uint
	uint   flags;     // bit0 flipX, bit1 flipY, bit2 fullscreen, bit3 verticalShading
	float  _pad0;
};

StructuredBuffer<Instance> instances   : register(t0, space0);
StructuredBuffer<uint>     quadIndices : register(t1, space0); // instance indices in depth-sorted draw order

cbuffer BatchUniforms : register(b0, space1) {
	float2 targetSize; // logical pixel size of the current render target
	float2 camPos;     // current camera position, subtracted from positions
	uint   firstIndex; // start of this batch in the index stream.
	                   // a uniform because D3D12's SV_VertexID ignores the draw's base offset while Vulkan's includes it
	float  coordScale; // the target's position multiplier, so native-res draws can compose into a window-res target
};

static const float2 QUAD[6] = {
	float2(0, 0), float2(1, 0), float2(0, 1),
	float2(1, 0), float2(1, 1), float2(0, 1),
};

struct Output {
	float4 color : TEXCOORD0;
	float2 uv    : TEXCOORD1;
	nointerpolation float4 stageShading : TEXCOORD2; // xy = feetPos, z = drawn width, w = verticalShading flag
	float4 position : SV_Position;
};

Output main(uint vertexIndex : SV_VertexID) {
	Instance inst = instances[quadIndices[firstIndex + vertexIndex/6]];
	float2 corner = QUAD[vertexIndex%6];

	// flips mirror the sampled UVs, geometry stays put
	float2 uvCorner = corner;
	if (inst.flags & 1) uvCorner.x = 1 - uvCorner.x;
	if (inst.flags & 2) uvCorner.y = 1 - uvCorner.y;

	float2 p;
	if (inst.flags & 4) { // fullscreen: cover the target, camera-independent
		p = corner*targetSize;
	}
	else {
		p = corner*inst.worldRect.zw;
		if (inst.rotation != 0) {
			float s, c;
			sincos(inst.rotation, s, c);
			float2 rel = p - inst.pivot;
			p = inst.pivot + float2(rel.x*c - rel.y*s, rel.x*s + rel.y*c);
		}
		p += inst.worldRect.xy - camPos;
		p *= coordScale;
	}

	float2 ndc = p/targetSize*2 - 1;

	Output output;
	// NDC is +y up with origin at the center, pixel coords are +y down
	output.position = float4(ndc.x, -ndc.y, 0, 1);
	output.uv = lerp(inst.uvRect.xy, inst.uvRect.zw, uvCorner);
	output.color = float4(inst.blend & 0xFF, (inst.blend >> 8) & 0xFF, (inst.blend >> 16) & 0xFF, (inst.blend >> 24) & 0xFF) / 255.0;
	output.stageShading = float4(inst.feetPos, inst.worldRect.z, float((inst.flags >> 3) & 1));
	return output;
}
