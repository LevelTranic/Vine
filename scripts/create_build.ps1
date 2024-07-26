#!/usr/bin/env pwsh

# This is a temporary version and I will roll it back soon.
# Because of a server-side bug, I found the problem only after six hours of troubleshooting.

param(
    [string]$mcVersion,
    [string]$token,
    [string]$channel = "default"
)

$api = "https://mars.tranic.one"

if (-not $token)
{
    $token = $env:MARS_TOKEN
    if (-not $token)
    {
        Write-Error 'Mars Token cannot be empty, you need to set $MARS_TOKEN="YOUR_MARS_API_TOKEN" in the environment variable'
        exit 1
    }
}

function Get-GitInfo
{
    $commit = git log -1 --pretty=format:"%H"
    $title = git log -1 --pretty=format:"%s"
    $message = git log -1 --pretty=format:"%b"
    $repoName = (git rev-parse --show-toplevel | Split-Path -Leaf).ToLower()

    return @{
        Commit = $commit
        Title = $title
        Message = $message
        RepoName = $repoName
    }
}

function Get-BuildInfo
{
    $buildLibsDir = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "../build") -ChildPath "libs"
    $filePattern = "$buildLibsDir/*.jar"
    $files = Get-ChildItem -Path $filePattern

    if ($files.Count -eq 0)
    {
        Write-Error "No jar files found in $buildLibsDir"
        exit 1
    }

    $fileInfo = @{ }
    foreach ($file in $files)
    {
        if ($file.Name -match "vine-(bundler|paperclip)-(\d+\.\d+\.\d+)(-[^\-]+)*\.jar")
        {
            $key = $matches[1]
            $version = $matches[2]
            $commitHash = (git log -1 --pretty=format:"%H")[0..6] -join ""
            $fileHash = Get-FileHash $file.FullName SHA256
            $fileInfo[$key] = @{
                name = $file.Name
                sha256 = $fileHash.Hash
                url = "https://github.com/LevelTranic/$( $gitInfo.RepoName )/releases/download/$mcVersion-$commitHash/$( $file.Name )"
            }
        }
    }

    if ($fileInfo.Count -eq 0)
    {
        Write-Error "No valid jar files found in $buildLibsDir"
        exit 1
    }

    return @{
        Files = $fileInfo
        Version = $version
        Family = $version -replace "\.\d+$"
    }
}

function Send-JsonData
{
    param (
        [string]$url,
        [string]$cookie,
        [string]$userAgent,
        [hashtable]$data
    )

    $jsonData = $data | ConvertTo-Json -Depth 10
    $headers = @{
        "Cookie" = $cookie
        "User-Agent" = $userAgent
        "Content-Type" = "application/json"
    }

    try
    {
        Write-Output "Sending POST request to $url"
        Write-Output "Headers: $( $headers | ConvertTo-Json -Depth 10 )"
        Write-Output "Data: $jsonData"

        $response = Invoke-RestMethod -Uri $url -Method Post -Body $jsonData -Headers $headers
        return $response
    }
    catch
    {
        Write-Error "Failed to send POST request to $url"
        Write-Error "Exception message: $_"
        Write-Error "StackTrace: $( $_.ScriptStackTrace )"
        throw $_
    }
}

$gitInfo = Get-GitInfo
$buildInfo = Get-BuildInfo

$jsonData = @{
    project = $gitInfo.RepoName
    version = $buildInfo.Version
    family = $buildInfo.Family
    channel = $channel
    changes = @(
        @{
            commit = $gitInfo.Commit
            summary = $gitInfo.Title
            message = $gitInfo.Message
        }
    )
}

$apiUrl = "$api/v2/new/build"
$cookie = "mars_token=$token"
$userAgent = "Mars-Utils/v1"

Write-Output "Starting first API call to $apiUrl"
$response = Send-JsonData -url $apiUrl -cookie $cookie -userAgent $userAgent -data $jsonData
Write-Output "First API call response: $response"

if ($response -is [string])
{
    Write-Error "API response is not a valid JSON object."
    exit 1
}

$responseObj = $response

if ($responseObj -and $responseObj.build_id -ne 0)
{

    $buildInfoJson = $buildInfo | ConvertTo-Json -Depth 10
    $gitInfoJson = $gitInfo | ConvertTo-Json -Depth 10

    try
    {
        $uploadData = @{
            project = $gitInfoJson.RepoName
            version = $buildInfoJson.Version
            build = $responseObj.build_id
            file = $buildInfoJson.Files
        }

        $tempFile = [System.IO.Path]::GetTempFileName()

        $uploadData | ConvertTo-Json -Depth 10 | Set-Content -Path $tempFile -Force

        $uploadUrl = "https://mars.tranic.one/v2/new/external_download"

        $curlCommand = @"
curl -X POST "$uploadUrl" -H "Content-Type: application/json" -H "Cookie: mars_token=$token" -H "User-Agent: Mars-Utils/v1" -d "@$tempFile"
"@

        try
        {
            $uploadResponse = Invoke-Expression $curlCommand
            Write-Output "Upload response: $uploadResponse"
        }
        catch
        {
            Write-Error "Failed to execute curl command."
            Write-Error $_.Exception.Message
        }
        finally
        {
            Remove-Item -Path $tempFile -Force
        }
    }
    catch
    {
        Write-Error "Failed to execute upload_files.ps1"
        Write-Error "Exception message: $_"
        Write-Error "StackTrace: $( $_.ScriptStackTrace )"
        exit 1
    }
}
else
{
    Write-Error "Failed to get valid build_id from API response"
    exit 1
}

Remove-Item $buildInfoPath
Remove-Item $gitInfoPath