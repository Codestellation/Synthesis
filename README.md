# Codestellation Synthesis

Codestellation Synthesis is a lightweight conventional build script, based on Psake. It's not extensible, but provides simple project building proccess. 

### Installation


Clone repository, and run Pack.ps1 using powershell console to generate synthesis package. Then put the package in your local nuget feed (I don't want to push it to nuget.org at the moment). Using nuget package manager install-package 
> Note: Codestellation Synthesis has dependencies on nunit.runners and psake packages. But due to nuget bug those packages would not be added to solution wide packages.config automatically. You'd better install them manually. 

It will add build.ps1 to the root solution folder, and it must be persisted in VCS.

### Usage
Run build.ps1 from powershell command line. Your solution will be builded and packaged. 

### Conventions:

1. There is the only .sln file in the root folder.
2. Project are build against 4.0 and 4.5 framework. 
3. *.Tests.csproj are considered as test projects, and will be tested using NUnit. 
4. Every not *.Tests.csproj will be packed into nuget package. It assumes that the only .nuspec file is exists in project folder. 
