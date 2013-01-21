$utils = (Get-ChildItem -Include utils.ps1 -Recurse).FullName
#Including function from utils. So called dot sourcing (dot and a space before path to script)
. "$utils"

$version = Get-Version
$packageVersion = Generate-Package-Version $version 
$nuspec = 'synthesis.nuspec'
$packagedir = 'package'
$nuget = (Get-ChildItem -Include nuget.exe -Recurse).FullName

& $nuget pack $nuspec -BasePath $packagedir -Version $packageVersion -ExcludeEmptyDirectories
