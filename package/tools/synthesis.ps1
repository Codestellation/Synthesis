Properties {
    $basedir = Get-Location
    $outputdir = Join-Path $basedir 'Build'
	$nugetdir = Join-Path $basedir 'Nuget'
    $quotedoutputdir = '"' + $outputdir + '"'
    $frameworks = '4.0','4.5'
    $version = Get-Version
    $nuget = (Get-ChildItem -Path $basedir -Include nuget.exe -Recurse).FullName
}
$utils = (Get-ChildItem synthesis.util.ps1  -Path $basedir -Recurse).FullName 
include $utils

Task Default -depends Pack

Task Clean {
    if(Test-Path $outputdir)
    {
        Remove-Item -Path $outputdir -Recurse -Force
    }
	
	if(Test-Path $nugetdir)
	{
		Remove-Item -Path $nugetdir -Recurse -Force
	}
}

Task SetVersion {
	
	$SolutionVersion = Generate-Assembly-Info $version["version"] $version["commit"] $version["dirty"]
	$SolutionVersion > SolutionVersion.cs 
}

Task Build -depends Clean, SetVersion {
    if(!$solution)
    {
        $solution = Get-Item -Path .\ -Include *.sln
    }
    
    Exec { 
		msbuild $solution /p:OutDir=$quotedoutputdir\ /verbosity:minimal 		
    }
}

Task Test -depends Build {
    
    $nunit = (Get-ChildItem 'nunit-console.exe' -Path $basedir -Recurse).FullName
    $assemblies = @(Get-ChildItem *.Tests.dll -Path $outputdir | %{ $_.FullName} )
    
	if($assemblies)    
    {
        $linearAsms = [System.String]::Join(" ", $assemblies)
		Write-Warning $linearAsms
		Write-Warning $nunit
        Exec {
           & $nunit $linearAsms /domain:single
        }
    }
}

Task Pack -depends Test {
    
    [System.IO.FileInfo[]]$projects = @(Get-ChildItem -Include *.csproj -Exclude *.Tests.csproj -Recurse)

	foreach($project in $projects)
	{
		foreach($framework in $frameworks)
		{
            $projectname = $project.Name.Replace(".csproj", [System.String]::Empty)
            $projectfile = $project.FullName
            $dotlessFramework = $framework.Replace('.','')
            $packagedir = "$nugetdir\$projectname"
			$libdir = "$packagedir\lib\net$dotlessFramework" + '\'
			$config = "Release"
			#TODO Move this to utils for the sake of incapsulation ugly string concats.
            $props = "/p:TargetFrameworkVersion=$framework;Configuration=$config;OutDir=$libdir;CustomAfterMicrosoftCommonTargets=$basedir\SkipCopyLocal.targets"
            
            Exec {
                msbuild $projectfile  /t:Rebuild $props /verbosity:minimal /nologo
            }
		}
        $projectdir = $project.Directory.FullName;
        
        $nuspec = (Get-ChildItem -Path $projectdir -Include *.nuspec -Recurse).FullName
        
        $nugetVersion = $version['version']
        if($version['dirty'])
        {
            $nugetVersion += '-dirty'
            Write-Warning "Working directory is dirty. Package will be marked as dirty - $nugetVersion"
        }
        write 'Building nuget package '
        Exec {
           & $nuget pack $nuspec -BasePath $packagedir -Version $nugetVersion -Symbols -ExcludeEmptyDirectories
        }
         

	}
}