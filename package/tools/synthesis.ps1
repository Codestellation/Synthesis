Properties {
	$outputdir = Join-Path $basedir 'Build'
	$nugetdir = Join-Path $basedir 'Nuget'
	$frameworks = '4.0','4.5'
    $version = Get-Version
    
}
$utils = (Get-ChildItem synthesis.utils.ps1  -Path $basedir -Recurse).FullName 
include $utils

Task Default -depends Pack

Task Init {
	Set-Location $basedir
}

Task Clean -depends Init {
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
		$solution = Get-Item -Path $basedir -Include *.sln
    }
    
	$quotedoutputdir = $outputdir = '"' + $outputdir + '"'
    Exec { 
		msbuild $solution /p:OutDir=$quotedoutputdir\ /verbosity:minimal 		
    }
}

Task Test -depends Build {
    
    $nunit = (Get-ChildItem 'nunit-console.exe' -Path $basedir -Recurse).FullName
    $assemblies = @(Get-ChildItem *Tests.dll -Path $outputdir | %{ $_.FullName} )
    
	if($assemblies)    
    {
        $linearAsms = [System.String]::Join(" ", $assemblies)
		Write-Warning $linearAsms
		Write-Warning $nunit
        Exec {
           & $nunit $linearAsms /domain:single /nologo
        }
    }
}

Task Pack -depends Test {
    
    [System.IO.FileInfo[]]$projects = @(Get-ChildItem -Include *.csproj -Exclude *.Tests.csproj, *Sample* -Recurse) | where {!($_.FullName.Contains("Samples")) }
	$nuget = (Get-ChildItem -Path $basedir -Include nuget.exe -Recurse).FullName
    
	foreach($project in $projects)
	{
		$projectfile = $project.FullName
		write "Packing project '$project'"

		$projectdir = $project.Directory.FullName;
        
		$nuspec = (Get-ChildItem -Path $projectdir -Include *.nuspec -Recurse).FullName
		if(!$nuspec)
		{
			continue
		}
        foreach($framework in $frameworks)
		{
			if(!$solution)
			{
				$solution = Get-Item -Path $basedir -Include *.sln
			}
			$config = "Release"
			$projectname = $project.Name.Replace(".csproj", [System.String]::Empty)
			$packagedir = "$nugetdir\$projectname"
			
			$skipCopyLocalPath = (Get-ChildItem SkipCopyLocal.targets -Path . -Recurse).FullName
			$dotlessFramework = $framework.Replace('.','')
			
			$outDir = "$packagedir\lib\net$dotlessFramework"
			$props = "/p:DefineConstants=NET""$dotlessFramework"";TargetFrameworkVersion=$framework;Configuration=$config;OutDir=$outDir\"
			
			Exec{
				msbuild $project /t:Rebuild $props /nologo /verbosity:minimal
            }
            
            Get-ChildItem -Path $outDir -Exclude "*$projectname.???" | del -Force -Recurse
		}

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