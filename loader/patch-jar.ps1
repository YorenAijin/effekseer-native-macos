# Adds macOS support to EffekseerCraft-DEFINITIVE.jar:
#  - native/macos/x86_64/libEffekseerNativeForJava.dylib (artifact of the GitHub Actions build)
#  - EffekSeer4J$Library classes compiled from loader/EffekSeer4J.java (loads that dylib on macOS)
# Everything else in the jar is left untouched.
#
# .\patch-jar.ps1 -Jar <original jar> -Dylib <libEffekseerNativeForJava.dylib> -Out <new jar> -JdkBin <JDK bin folder>
param(
    [Parameter(Mandatory)] [string] $Jar,
    [Parameter(Mandatory)] [string] $Dylib,
    [Parameter(Mandatory)] [string] $Out,
    [Parameter(Mandatory)] [string] $JdkBin
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$work = Join-Path ([IO.Path]::GetTempPath()) ("efs-patch-" + [Guid]::NewGuid().ToString('N'))
$pkg = Join-Path $work 'src\com\github\mrmks\efkseer4j'
New-Item -ItemType Directory -Force $pkg, (Join-Path $work 'out') | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'EffekSeer4J.java') $pkg

& (Join-Path $JdkBin 'javac.exe') --release 8 -nowarn -cp $Jar -d (Join-Path $work 'out') (Join-Path $pkg 'EffekSeer4J.java')
if ($LASTEXITCODE -ne 0) { throw 'javac failed' }

$classDir = Join-Path $work 'out\com\github\mrmks\efkseer4j'
$replace = @{
    'com/github/mrmks/efkseer4j/EffekSeer4J$Library.class' = Join-Path $classDir 'EffekSeer4J$Library.class'
    'com/github/mrmks/efkseer4j/EffekSeer4J$Library$1RuntimeExceptionNonStack.class' = Join-Path $classDir 'EffekSeer4J$Library$1RuntimeExceptionNonStack.class'
    'native/macos/x86_64/libEffekseerNativeForJava.dylib' = (Resolve-Path $Dylib).Path
}

# The JDK "jar" tool writes the archive (not .NET's ZipArchive: its STORED entries carry a data
# descriptor that java.util.zip.ZipInputStream rejects, e.g. Nebula's Claritas).
$stage = Join-Path $work 'stage'
foreach ($name in $replace.Keys) {
    $dst = Join-Path $stage ($name -replace '/', '\')
    New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
    Copy-Item -LiteralPath $replace[$name] -Destination $dst
    Write-Output "  + $name"
}
Copy-Item $Jar $Out -Force
& (Join-Path $JdkBin 'jar.exe') uf $Out -C $stage com -C $stage native
if ($LASTEXITCODE -ne 0) { throw 'jar update failed' }
Remove-Item -Recurse -Force $work
Write-Output "Written $Out"
