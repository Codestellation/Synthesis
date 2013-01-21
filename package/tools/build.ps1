$ErrorActionPreference = 'Stop'

$invname = $MyInvocation.InvocationName
$scriptPath = Split-Path $MyInvocation.InvocationName

if($scriptPath)
{
    Set-Location $scriptPath    
}

write "Restore solution-wide packages"

.\.nuget\nuget.exe install .\.nuget\packages.config -o packages

$psakeModule = Get-ChildItem psake.psm1 -Path $scriptPath -Recurse

Import-Module $psakeModule.FullName -force

$default = (Get-ChildItem synthesis.ps1 -Path $scriptPath -Recurse).FullName
$basedir =  (Get-Item(Get-Location)).FullName
$outputdir = Join-Path $basedir 'Build'
$nugetdir = Join-Path $basedir 'Nuget'

Invoke-psake -framework '4.0' -buildFile $default -properties @{basedir="$basedir";outputdir="$outputdir";nugetdir="$nugetdir"}