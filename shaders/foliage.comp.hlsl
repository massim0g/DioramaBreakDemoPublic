/*
Foliage wind sim + vertex generation, one thread per NODE, three phases dispatched back to back per component (selected by the phase uniform):
 0: wind spring update (mutates the persistent windForce state)
 1: absolute angle accumulation up the parent chain, written to absAngle
 2: position accumulation up the parent chain + vertex write
The trees are shallow and wide (~15 avg / ~50 max depth), so per-node upward walks are cheap and fully parallel.
This replaced a per-branch serial scan that ran ~30 threads with 4000+ iteration dependency chains and stalled the GPU for ~4.5ms.
Wind gust rolls are pure hash functions of (nodeIndex, frame, rngSalt), so any thread re-evaluating an ancestor's roll gets the same answer; that is what makes the spring phase per-node parallel.
The wind gate from the CPU original is preserved: a node's spring only steps (and its windForce only bends the angle) when its decay differs from its parent's.
Node/Branch must match FoliageBranchUpdateNode/FoliageBranch in co_foliage.odin; Vertex must match render.odin's Vertex / mesh.vert.hlsl.
*/

struct Node {
	float2 size;
	float  angle;           // degrees, relative to parent
	float  windForce;       // persistent spring state
	float  windForceSpeed;  // persistent spring state
	float  absAngle;        // written by phase 1
	uint   parentInd;       // FOLIAGE_NO_PARENT for branch roots and base leaves
	uint   branchInd;
	uint   decay;
	uint   leaf;
};

struct Branch {
	float2 pos;
};

struct Vertex {
	float2 pos;
	float2 uv;
	uint   blend;
	uint   _pad;
};

static const uint FOLIAGE_NO_PARENT = 0xFFFFFFFFu;
static const float DEG = 3.14159265/180.0; // engine angles are degrees

StructuredBuffer<Branch> branches : register(t0, space0);
RWStructuredBuffer<Node> nodes    : register(u0, space1);
RWStructuredBuffer<Vertex> verts  : register(u1, space1);

cbuffer FoliageUniforms : register(b0, space2) {
	float2 baseOffset; // stageEntity pos + parallaxOffset - camPos
	uint   frame;
	uint   windEnabled;
	float  windChance;
	float  windForceCounter;
	float  windForceDamping;
	float  windForceMax;
	float  windForceLeafCounter;
	float  windForceLeafDamping;
	float  windForceLeafMax;
	float  windForceLeafDistributionExponent;
	float2 branchUVMin;
	float2 branchUVMax;
	float2 leafUVMin;
	float2 leafUVMax;
	uint   branchBlend; // packed rgba, alpha 0 when branches are invisible
	uint   leafBlend;
	uint   nodeCount;
	uint   rngSalt;
	uint   phase;
};

uint pcg_hash(uint v) {
	uint s = v*747796405u + 2891336453u;
	uint w = ((s >> ((s >> 28u) + 4u)) ^ s)*277803737u;
	return (w >> 22u) ^ w;
}

float rand01(inout uint seed) {
	seed = pcg_hash(seed);
	return float(seed)*(1.0/4294967296.0);
}

uint node_seed(uint ind) {
	return pcg_hash(ind ^ pcg_hash(frame) ^ rngSalt);
}

Vertex vertex_make(float2 pos, float2 uv, uint blend) {
	Vertex v;
	v.pos = pos;
	v.uv = uv;
	v.blend = blend;
	v._pad = 0;
	return v;
}

//Phase 0: Wind
void spring_update(uint i) {
	if (windEnabled == 0) return;

	Node node = nodes[i];
	uint parentDecay = node.parentInd == FOLIAGE_NO_PARENT ? 255u : nodes[node.parentInd].decay;
	if (parentDecay == node.decay) return; //only root nodes after a decay can receive wind
	bool leaf = node.leaf != 0;

	//collect any ancestor nodes that are able to receive wind
	uint candidates[8];
	uint candCount = 0;
	uint curInd = node.parentInd;
	if (curInd != FOLIAGE_NO_PARENT) {
		Node cur = nodes[curInd];
		while (true) {
			uint pInd = cur.parentInd;
			uint pDecay = 255u;
			Node par;
			if (pInd != FOLIAGE_NO_PARENT) {
				par = nodes[pInd];
				pDecay = par.decay;
			}
			if (pDecay != cur.decay && cur.decay > 0 && cur.leaf == 0 && candCount < 8) {
				candidates[candCount] = curInd;
				candCount++;
			}
			if (pInd == FOLIAGE_NO_PARENT) break;
			curInd = pInd;
			cur = par;
		}
	}

	//check if any gust candidates received wind this frame, from root to leaf
	float windMul = 0;
	for (int c = int(candCount) - 1; c >= 0; c--) {
		uint seed = node_seed(candidates[c]);
		float rollR = rand01(seed);
		float signR = rand01(seed);
		if (rollR < windChance) {
			windMul = signR < 0.5 ? 1.0 : -1.0;
			break;
		}
	}

	// own roll and impulse; rand order is fixed (roll, sign, impulse) so ancestor re-evaluation stays consistent
	uint seed = node_seed(i);
	float rollR = rand01(seed);
	float signR = rand01(seed);
	if (windMul == 0 && !leaf && rollR < windChance) windMul = signR < 0.5 ? 1.0 : -1.0;
	if (windMul != 0) node.windForceSpeed += windMul*(leaf
		? pow(rand01(seed), windForceLeafDistributionExponent)*windForceLeafMax
		: rand01(seed)*windForceMax*float(node.decay + 1));

	node.windForceSpeed += node.windForce*-(leaf ? windForceLeafCounter : windForceCounter);
	node.windForceSpeed *= leaf ? windForceLeafDamping : windForceDamping;
	node.windForce += node.windForceSpeed;

	nodes[i].windForce = node.windForce;
	nodes[i].windForceSpeed = node.windForceSpeed;
}

// Phase 1. Walks to the root summing each link's angle, plus its windForce where the wind gate is open.
void angle_accumulate(uint i) {
	Node node = nodes[i];
	float sum = node.angle;
	float childWindForce = node.windForce;
	uint childDecay = node.decay;
	uint curInd = node.parentInd;

	while (true) {
		uint parentDecay = 255u;
		Node par;
		if (curInd != FOLIAGE_NO_PARENT) {
			par = nodes[curInd];
			parentDecay = par.decay;
		}
		if (windEnabled != 0 && parentDecay != childDecay) sum += childWindForce;
		if (curInd == FOLIAGE_NO_PARENT) break;

		sum += par.angle;
		childWindForce = par.windForce;
		childDecay = par.decay;
		curInd = par.parentInd;
	}

	nodes[i].absAngle = sum;
}

// Phase 2. Ancestor offsets are plain vector adds (rot(absAngle_k)*size_k.x, i.e. vec2_offset with its -sin), so accumulation order doesn't matter and one upward walk suffices.
void verts_write(uint i) {
	Node node = nodes[i];

	float2 pos = baseOffset + branches[node.branchInd].pos;
	uint curInd = node.parentInd;
	while (curInd != FOLIAGE_NO_PARENT) {
		Node p = nodes[curInd];
		pos += float2(cos(p.absAngle*DEG), -sin(p.absAngle*DEG))*p.size.x;
		curInd = p.parentInd;
	}

	// rotate the base quad by -absAngle about its left edge midpoint, then translate to pos
	float sinA = sin(-node.absAngle*DEG);
	float cosA = cos(-node.absAngle*DEG);
	float2 corners[4] = {
		float2(0, -node.size.y/2),
		float2(node.size.x, -node.size.y/2),
		float2(node.size.x, node.size.y/2),
		float2(0, node.size.y/2)
	};
	float2 q[4];
	for (int k = 0; k < 4; k++) {
		q[k] = float2(corners[k].x*cosA - corners[k].y*sinA, corners[k].x*sinA + corners[k].y*cosA) + pos;
	}

	bool leaf = node.leaf != 0;
	float2 uvMin = leaf ? leafUVMin : branchUVMin;
	float2 uvMax = leaf ? leafUVMax : branchUVMax;
	uint blend = leaf ? leafBlend : branchBlend;

	// two triangles (0,1,2)(0,2,3), matching render_mesh_quads; vertex range = node index*6
	uint v = i*6;
	verts[v + 0] = vertex_make(q[0], uvMin, blend);
	verts[v + 1] = vertex_make(q[1], float2(uvMax.x, uvMin.y), blend);
	verts[v + 2] = vertex_make(q[2], uvMax, blend);
	verts[v + 3] = vertex_make(q[0], uvMin, blend);
	verts[v + 4] = vertex_make(q[2], uvMax, blend);
	verts[v + 5] = vertex_make(q[3], float2(uvMin.x, uvMax.y), blend);
}

[numthreads(64, 1, 1)]
void main(uint3 tid : SV_DispatchThreadID) {
	if (tid.x >= nodeCount) return;

	if (phase == 0) spring_update(tid.x);
	else if (phase == 1) angle_accumulate(tid.x);
	else verts_write(tid.x);
}
