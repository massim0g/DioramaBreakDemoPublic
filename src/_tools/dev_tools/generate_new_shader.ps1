param(
    [string]$shaderName
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = "$ScriptDir\..\..\.." | Convert-Path

if($shaderName -eq ""){ 
	Write-Host "Error! No component name was entered."
	exit 
}

$fragPath = Join-Path -Path $ProjectDir -ChildPath "shaders/$shaderName.frag"
$vertPath = Join-Path -Path $ProjectDir -ChildPath "shaders/$shaderName.vert"

if(Test-Path $fragPath){
	Write-Host "ERROR: Component already exists!"
	exit
}

$fragContent = @"
#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

uniform sampler2D texture;

void main()
{
	gl_FragColor = texture2D(texture, v_texCoord) * v_color;
}
"@

$vertContent = @"
#version 330 core
varying vec4 v_color;
varying vec2 v_texCoord;

void main()
{
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    v_color = gl_Color;
    v_texCoord = vec2(gl_MultiTexCoord0);
}
"@	

$fragContent | Out-File -FilePath $fragPath -Encoding UTF8
$vertContent | Out-File -FilePath $vertPath -Encoding UTF8

& code -r $fragPath #open new file in vscode

