param(
    [string]$shaderName
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = "$ScriptDir\..\..\.." | Convert-Path

if($shaderName -eq ""){ 
	Write-Host "Error! No component name was entered."
	exit 
}

# Shaders are HLSL now, and there are only two vertex shaders in the engine (the quad and mesh pullers),
# so a new shader is a fragment shader only.
$fragPath = Join-Path -Path $ProjectDir -ChildPath "shaders/$shaderName.frag.hlsl"

if(Test-Path $fragPath){
	Write-Host "ERROR: Shader already exists!"
	exit
}

# Binding conventions are fixed by SDL_shadercross: fragment textures/samplers in space2 (t0/s0 is the
# draw's own texture, extras follow in declaration order), fragment uniforms in one cbuffer at b0/space3.
# The builder parses that cbuffer and generates a matching Sh_<PascalCaseName> struct into shaderIDs.g.odin.
$fragContent = @"
Texture2D tex : register(t0, space2);
SamplerState texSampler : register(s0, space2);

// cbuffer Uniforms : register(b0, space3) {
// 	float time;
// };

float4 main(float4 color : TEXCOORD0, float2 uv : TEXCOORD1) : SV_Target0 {
	return tex.Sample(texSampler, uv) * color;
}
"@

$fragContent | Out-File -FilePath $fragPath -Encoding UTF8

& code -r $fragPath #open new file in vscode

