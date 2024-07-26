#!/usr/bin/env pwsh

function Get-Property {
    param (
        [string]$name
    )
    $line = Select-String -Path "gradle.properties" -Pattern "^[\s]*$name" | Select-Object -First 1
    if ($line) {
        return $line -replace '^[\s]*' -replace "$name\s*=\s*", ""
    }
    return $null
}

$project_id = (git rev-parse --show-toplevel | Split-Path -Leaf).ToLower()
$project_id_b = (git rev-parse --show-toplevel | Split-Path -Leaf)

$commitid = git log --pretty='%h' -1
$mcversion = Get-Property "mcVersion"
$grdversion = Get-Property "version"
$preVersion = Get-Property "preVersion"
$release_tag = "$mcversion-$commitid"
$jarName = "$project_id-$mcversion-paperclip.jar"
$jarName_bundler = "$project_id-$mcversion-bundler.jar"
$jarName_dir = "build/libs/$jarName"
$jarName_bundler_dir = "build/libs/$jarName_bundler"
$make_latest = if ($preVersion -eq "true") { "false" } else { "true" }

Move-Item "build/libs/$project_id_b-paperclip-$grdversion-mojmap.jar" $jarName_dir
Move-Item "build/libs/$project_id_b-bundler-$grdversion-mojmap.jar" $jarName_bundler_dir

Add-Content -Path $env:GITHUB_ENV -Value "project_id=$project_id"
Add-Content -Path $env:GITHUB_ENV -Value "project_id_b=$project_id_b"
Add-Content -Path $env:GITHUB_ENV -Value "commit_id=$commitid"
$commit_msg = git log --pretty='> [%h] %s' -1
Add-Content -Path $env:GITHUB_ENV -Value "commit_msg=$commit_msg"
Add-Content -Path $env:GITHUB_ENV -Value "mcversion=$mcversion"
Add-Content -Path $env:GITHUB_ENV -Value "pre=$preVersion"
Add-Content -Path $env:GITHUB_ENV -Value "tag=$release_tag"
Add-Content -Path $env:GITHUB_ENV -Value "jar=$jarName"
Add-Content -Path $env:GITHUB_ENV -Value "jar_dir=$jarName_dir"
Add-Content -Path $env:GITHUB_ENV -Value "jar_dir_bundler=$jarName_bundler_dir"
Add-Content -Path $env:GITHUB_ENV -Value "make_latest=$make_latest"
