param(
    [string]$componentName
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = "$ScriptDir\..\..\.." | Convert-Path

if($componentName -eq ""){ 
	Write-Host "Error! No component name was entered."
	exit 
}

$componentPath = Join-Path -Path $ProjectDir -ChildPath "src/massimodin/co_$componentName.odin"

if(Test-Path $componentPath){
	Write-Host "ERROR: Component already exists!"
	exit
}

$cappedName = $componentName.Substring(0,1).ToUpper() + $componentName.Substring(1)
$template = @"
#+feature using-stmt
package massimodin //@nested-tags:_components/

${cappedName} :: struct{
	using base:ComponentBase,
}

_${componentName}_process_event :: proc(base:^ComponentBase, event:Event, overrideDisabled:=false){
if(!overrideDisabled && event in base.disabledEvents) do return
last_context := entities.context_component
defer cowith(last_context)
cowith(base)
self := cast(^${cappedName})base
using self
#partial switch event{
case .init:
	
case .update:

}}
"@	

$template | Out-File -FilePath $componentPath -Encoding UTF8

& code -r $componentPath #open new file in vscode

