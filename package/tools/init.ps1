﻿param($installPath, $toolsPath, $package, $project)

$solutiondir = $null

do{
	if($solutiondir)
	{
		$solutiondir = $solutiondir.Parent
	}
	else
	{
		$solutiondir = Get-Item (Get-Location)
	}
	
	$solutiondirDirPath = $solutiondir.FullName
	$solution = (Get-ChildItem *.sln -Path $solutiondirDirPath -Recurse)
	$solution
}
while(!$solution -or $solutiondir -eq $solutiondir.Root)

#$buildps1 = (Get-ChildItem build.ps1 -Path $solutiondir -Recurse -Filter *synthesis*).FullName

$buildps1 = Join-Path $toolsPath 'build.ps1'

Copy-Item $buildps1 -Destination $solutiondir -Force 