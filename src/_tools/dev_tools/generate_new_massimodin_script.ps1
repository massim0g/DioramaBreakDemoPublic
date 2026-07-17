param(
    [string]$scriptName
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = "$ScriptDir\..\..\.." | Convert-Path

if($scriptName -eq ""){ 
	Write-Host "Error! No script name was entered."
	exit 
}

$scriptPath = Join-Path -Path $ProjectDir -ChildPath "src/massimodin/sc_$scriptName.odin"

if(Test-Path $scriptPath){
	Write-Host "ERROR: Component already exists!"
	exit
}

$template = @"
package massimodin //@nested-tags:_scripts/

$scriptName :: proc(){

}

"@	

$template | Out-File -FilePath $scriptPath -Encoding UTF8

& code -r $scriptPath #open new file in vscode

