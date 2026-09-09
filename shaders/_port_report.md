# GLSL → HLSL port report (SDL_GPU / SDL_shadercross, SM6.0)

All 20 legacy fragment shaders (sources recovered from `git show c7fbcfbb^:shaders/<name>.frag`) were
ported 1:1 to `shaders/<name>.frag.hlsl`. Every file compiles clean through
`shadercross.exe -s HLSL -d SPIRV -t fragment` **and** `-d DXIL`. All cbuffer byte offsets below were
verified against the compiled SPIRV by round-tripping through SPIRV-Cross (`packoffset` output), not
just hand-computed.

Common conventions (match `quad.vert.hlsl` / `sprite.frag.hlsl`):
- Inputs: `float4 color : TEXCOORD0`, `float2 uv : TEXCOORD1`, plus `float4 svPos : SV_Position`
  only where the GLSL used `gl_FragCoord` (actionTarget, stageTint).
- Main texture: `tex`/`texSampler` at `t0/s0, space2`. Extra textures at t1/s1, t2/s2, ... in GLSL
  declaration order. One `cbuffer Uniforms : register(b0, space3)` per shader (fragment uniform slot 0
  for `SDL_PushGPUFragmentUniformData`).
- GLSL `bool` uniforms became `int` (nonzero = true). GLSL `vec3` uniforms/arrays became `float4`
  (.rgb used, .w padding). CPU-side Odin structs must reproduce the exact offsets/padding listed below.

## Per-shader details

### actionTarget
Samplers: `tex` t0 (target sprite), `stencilTex` t1, `floorTex` t2, `mainTex` t3.
cbuffer (48 bytes):
| field | type | offset |
|---|---|---|
| texSize | float2 | 0 |
| stencilTexSize | float2 | 8 |
| centerPos | float2 | 16 |
| stencilOffset | float2 | 24 |
| floorTexSize | float2 | 32 |
| outlineRevealAngle | float | 40 |
| drawMode | int | 44 |

**FLAGGED (Y-axis)**: drawMode 2 (silhouette) computed `screenUV = gl_FragCoord.xy/floorTexSize` then
flipped Y (`1 - y`) — i.e. the GL code converted bottom-left fragcoords to top-left UVs into the
pre/post scene textures. SV_Position is already top-left, so the port uses `svPos.xy/floorTexSize`
with **no flip**. If the old flip was *also* compensating an FBO row-order quirk (unknowable from the
shader alone), the sampled row will be mirrored — verify visually; the fix would be re-adding
`screenUV.y = 1 - screenUV.y`.
Other notes: `mod(angle, 90)` kept as `fmod` (angle is always in [0,360)). `pre == post` vec4 equality
→ `all(pre == post)`.

### addFade
Samplers: `tex` t0. cbuffer (16 bytes): `float add` @ 0.
Added `if (a == 0) discard` (sprite.frag.hlsl depth convention; GLSL relied on blending).

### aimingRings
Samplers: `tex` t0 (ring sprite), `destination` t1 (manual-blend destination, same UVs).
cbuffer (32 bytes):
| field | type | offset |
|---|---|---|
| texSize | float2 | 0 |
| centerPos | float2 | 8 |
| outlineRevealAngle | float | 16 |

Manual-blend shader (writes dst when src alpha is 0) — **no** discard added. `atan(-y,x)` → `atan2`.

### blendTest
Samplers: `tex` t0 (sprite), `mask` t1 (lighting). No uniforms (no cbuffer).
Debug shader: live GLSL path only visualized `textureSize(mask)`; ported faithfully
(`GetDimensions`). A never-firing guard (`if (b.a < -1 || m.a < -1) discard`) keeps both Sample calls
alive — otherwise DXC culls `tex` entirely and demotes `mask` (GetDimensions-only) to a *storage
texture* in reflection, breaking the t0/s0 + t1/s1 sampler binding convention.

### colorOnly
Samplers: `tex` t0. No uniforms. Added `if (a == 0) discard`.

### combatCursor
**No textures/samplers** (the GLSL's `sampler2D texture` was commented out; reflection = 0 samplers,
so the CPU side must create this shader with `num_samplers = 0` and skip texture binds).
cbuffer (16 bytes): `float2 rectSize` @ 0, `float time` @ 8.
`mod` → floored-mod helper (operand can touch 0/negative edge cases). Interior pixels `discard` as before.

### gridBase
Samplers: `tex` t0. cbuffer (32 bytes):
| field | type | offset |
|---|---|---|
| texSize | float2 | 0 |
| tileSize | float2 | 8 |
| gridDisplayPos | float2 | 16 |
| time | int | 24 |

`mod(floor(rel), tileSize)` → floored-mod helper (`rel` can be negative). GLSL wrote `vec4(0)` for
non-grid pixels and `inCol*v_color` with a==0 for transparent input; both became `discard`
(equivalent under alpha blending, depth-safe).

### indoorColorTest
Samplers: `tex` t0. cbuffer (64 bytes): `float4 inputCols[4]` @ 0, stride 16 (only [0] used).
Dead rgb2hsv/hsv2rgb helpers not ported. Added `if (a == 0) discard`.

### leaves
Samplers: `tex` t0. cbuffer (16 bytes): `float4 lightColor` @ 0 (**.rgb used, .w = padding**; GLSL vec3).
Full-screen bloom pass, always writes alpha 1 — no discard.

### meditationBG
Samplers: `tex` t0. cbuffer (16 bytes): `float time` @ 0, `float strength` @ 4, `float scale` @ 8.
Procedural noise; ignores texture color (GLSL sampled it into an unused variable — a never-firing
guard keeps the t0/s0 binding alive through DXC DCE). Preserved bug-for-bug: `roundStep` is 0 when
strength == 0 → division by zero/NaN, exactly as in GLSL; don't draw with strength exactly 0.

### palSwap
Samplers: `tex` t0. cbuffer (**3088 bytes**):
| field | type | offset |
|---|---|---|
| paletteSize | int | 0 |
| destMix | float | 4 |
| alwaysApplyWithShortestDistance | int (was bool) | 8 |
| blendmode | int | 12 |
| sourceColors[64] | float4, stride 16 | 16 |
| destColors1[64] | float4, stride 16 | 1040 |
| destColors2[64] | float4, stride 16 | 2064 |

All three arrays were GLSL `vec3[64]` → **float4[64], .rgb used, .w padding per element** (Odin:
`[64][4]f32` or `[64]Vec4`). Early-out for texel alpha 0 became `discard` (GLSL returned alpha 0).

### perspective — **FLAGGED for verification**
Samplers: `tex` t0. cbuffer (64 bytes):
| field | type | offset |
|---|---|---|
| transform | float3x3 **column_major** | 0 |
| screenSize | float2 | 48 |

Matrix layout (verified in SPIRV): 3 **columns**, each at 16-byte stride — column j occupies bytes
16*j .. 16*j+11, byte 12–15 of each column is padding. This matches GLSL `uniformMatrix3fv`
(column-major) with each column padded to 16 bytes; CPU side uploads 12 floats
(c0x c0y c0z pad, c1x c1y c1z pad, c2x c2y c2z pad). `mul(transform, v)` == GLSL `transform * v`.
Verification concern: the homography maps `uv*screenSize` (quad-local pixel coords, y-down top-left
under the new pipeline) into unit UV space. The matrix is CPU-computed and its Y convention was tied
to the GL pipeline — if output appears vertically flipped/skewed, the CPU matrix must be rebuilt for
y-down input and/or y-down output UVs. `texColor == vec4(1,1,1,0)` → `all(...)`.

### screen
Samplers: `tex` t0, `destination` t1. cbuffer (32 bytes): `float4 destRect` @ 0, `float2 destSize` @ 16.
Manual-blend shader (always writes dst-derived output) — no discard.
Note: `destRect.xy` is the sprite's position inside the destination texture; under the new top-left
pipeline this is naturally top-left based — worth a one-time visual check that dst UVs line up.

### sdf
Samplers: `tex` t0 (only its *size* is used, plus a never-firing anchor sample to keep the binding).
cbuffer (**2064 bytes**):
| field | type | offset |
|---|---|---|
| offset | float2 | 0 |
| k | float | 8 |
| shapeCount | int | 12 |
| shapeTags[64] | int, **stride 16** | 16 |
| shapes[64] | float4, stride 16 | 1040 |

**`int shapeTags[64]` occupies 16 bytes per element** (HLSL cbuffer array rule): element i lives at
byte 16 + 16*i, only the first 4 bytes meaningful. Odin struct must pad each tag to 16 bytes
(e.g. `[64]struct { tag: i32, _pad: [3]i32 }` or `[64][4]i32` using [0]).

### shadowLayer
Samplers: `tex` t0 (shadow/light mask), `destination` t1. cbuffer (32 bytes):
`float4 shadowBlend` @ 0, `float4 lightBlend` @ 16.
Manual-blend shader — no discard. No gl_FragCoord use (despite prior suspicion), no Y concerns:
mask and destination share the quad's UVs.

### shimmer
Samplers: `tex` t0. cbuffer (16 bytes): `float time` @ 0. `textureSize` → `GetDimensions`.
Added `if (a == 0) discard`.

### stage — **FLAGGED for verification (shadow map V direction)**
Samplers: `tex` t0, `shadowMap` t1. cbuffer (96 bytes):
| field | type | offset |
|---|---|---|
| stageRect | float4 | 0 |
| shadowBlend | float4 | 16 |
| lightBlend | float4 | 32 |
| tpPos | float4 | 48 |
| feetPos | float2 | 64 |
| timeStopSaturation | float | 72 |
| verticalShading | int (was bool) | 76 |
| timeStopEffect | int (was bool) | 80 |

Sampling formula kept verbatim: `V = (feetPos.y - stageRect.y)/stageRect.h`. This is correct if the
shadow map is rendered with the same top-left convention as everything else in the new pipeline. The
old GL FBO the shadow map was rendered into had bottom-up row order, and the GLSL did *not* flip —
meaning either the world data or the FBO write compensated. **If stage shading reads from the wrong
row (shadow appears when the caster is on the opposite side vertically), flip to
`1 - (feetPos.y - stageRect.y)/stageRect.h`.** Added `if (a == 0) discard` after all effects.

### stageTint — **FLAGGED for verification (Y-axis, most likely to differ)**
Samplers: `tex` t0. Uses SV_Position. cbuffer (112 bytes):
| field | type | offset |
|---|---|---|
| colors[4] | float4, stride 16 | 0 |
| viewRect | float4 | 64 |
| gradientRect | float4 | 80 |
| viewportSize | float2 | 96 |
| clampGradient | int (was bool) | 104 |
| tintMode | int | 108 |

GLSL built `screenUV = gl_FragCoord.xy/viewportSize` (bottom-left origin: y=0 at screen BOTTOM) and
mapped it into `viewRect` to get a world position. The port uses `svPos.xy/viewportSize` directly
(top-left origin: y=0 at screen TOP), which is the correct *intent* for a y-down world where
`viewRect.xy` is the camera's top-left corner. Under GL, y=0 mapped `viewRect.y` to the screen
*bottom* — so the old behavior only matched a y-down world if an FBO flip elsewhere compensated.
**Ambiguity noted rather than guessed**: if the gradient comes out vertically mirrored vs. the old
game, either flip screenUV.y in the shader or swap colors[0],[1] ↔ [3],[2] CPU-side.
Also preserved bug-for-bug: the GLSL `screen()` formula had a stray 2×
(`1 - 2*(1-base)*(1-blend)` instead of `1 - (1-base)*(1-blend)`); tintMode 1 reproduces the old
(non-standard) look. Texel alpha 0 early-out became `discard`.

### timeStop
Samplers: `tex` t0. No uniforms. (GLSL header: "DEPRECATED, ROLLED INTO STAGE SHADER".)
Fixed saturation 0.5. Added `if (a == 0) discard`.

### wavy
Samplers: `tex` t0. cbuffer (16 bytes): `float time` @ 0.
Preserved the GLSL's debug leftover that overwrites the red channel with `sin(time/1000)`.
Added `if (a == 0) discard`.

## Summary tables

Extra samplers (beyond tex t0/s0):
| shader | t1 | t2 | t3 |
|---|---|---|---|
| actionTarget | stencilTex | floorTex | mainTex |
| aimingRings | destination | | |
| blendTest | mask | | |
| screen | destination | | |
| shadowLayer | destination | | |
| stage | shadowMap | | |
| combatCursor | *(zero samplers total)* | | |

cbuffer sizes (bytes): actionTarget 48, addFade 16, aimingRings 32, blendTest 0 (none), colorOnly 0,
combatCursor 16, gridBase 32, indoorColorTest 64, leaves 16, meditationBG 16, palSwap 3088,
perspective 64, screen 32, sdf 2064, shadowLayer 32, shimmer 16, stage 96, stageTint 112,
timeStop 0, wavy 16.

Flagged for visual verification (Y-axis / coordinate-convention ambiguity):
1. **stageTint** — screen→world mapping (gl_FragCoord flip vs SV_Position); gradient may be mirrored.
2. **actionTarget** — drawMode 2 silhouette screen UV (old code flipped Y explicitly; port doesn't).
3. **stage** — shadowMap V direction depends on how the shadow map pass writes rows now.
4. **perspective** — homography input/output Y conventions are baked into the CPU matrix.

Manual-blend shaders (sample `destination`, must be drawn with blending DISABLED or the result
double-blends, and must NOT get the alpha-discard treatment): aimingRings, screen, shadowLayer.
