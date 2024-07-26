#!/usr/bin/env pwsh

# This script is applicable to Mars API.
# You can get Mars API from Release (https://github.com/LevelTranic/Mars) and deploy it.
param(
    [string]$mcVersion,
    [string]$token,
    [string]$channel = "default"
)

$api = "https://mars.tranic.one"

if (-not $token) {
    $token = $env:MARS_TOKEN
    if (-not $token)
    {
        Write-Error 'Mars Token cannot be empty, you need to set $MARS_TOKEN="YOUR_MARS_API_TOKEN" in the environment variable'
        exit 1
    }
}

function Get-GitInfo {
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

function Get-BuildInfo {
    $buildLibsDir = "build/libs"
    $filePattern = "$buildLibsDir/*.jar"
    $files = Get-ChildItem -Path $filePattern

    if ($files.Count -eq 0) {
        Write-Error "No jar files found in $buildLibsDir"
        exit 1
    }

    $fileInfo = @{}
    foreach ($file in $files) {
        if ($file.Name -match "vine-(bundler|paperclip)-(\d+\.\d+\.\d+)-.*\.jar") {
            $key = $matches[1]
            $version = $matches[2]
            $commitHash = (git log -1 --pretty=format:"%H")[0..6] -join ""
            $fileHash = Get-FileHash $file.FullName SHA256
            $fileInfo[$key] = @{
                name = $file.Name
                sha256 = $fileHash.Hash
                url = "https://github.com/LevelTranic/$($gitInfo.RepoName)/releases/download/$mcVersion-$commitHash/$($file.Name)"
            }
        }
    }

    if ($fileInfo.Count -eq 0) {
        Write-Error "No valid jar files found in $buildLibsDir"
        exit 1
    }

    return @{
        Files = $fileInfo
        Version = $version
        Family = $version -replace "\.\d+$"
    }
}

function ConvertTo-JsonString {
    param (
        [hashtable]$data
    )

    return $data | ConvertTo-Json -Depth 10
}

function Send-JsonData {
    param (
        [string]$url,
        [string]$cookie,
        [string]$userAgent,
        [string]$jsonData
    )

    $headers = @{
        "Cookie" = $cookie
        "User-Agent" = $userAgent
        "Content-Type" = "application/json"
    }

    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Body $jsonData -Headers $headers
        return $response
    } catch {
        Write-Error "Failed to send POST request to $url $_"
        throw $_
    }
}

# Main Execution
try {
    Write-Output "Getting Git Info"
    $gitInfo = Get-GitInfo
    Write-Output "Git Info: $($gitInfo | ConvertTo-Json -Depth 10)"

    Write-Output "Getting Build Info"
    $buildInfo = Get-BuildInfo
    Write-Output "Build Info: $($buildInfo | ConvertTo-Json -Depth 10)"

    # First API call to create a new build
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

    Write-Output "Converting JSON data for the first API call"
    $jsonString = ConvertTo-JsonString -data $jsonData

    Write-Output "Starting first API call to $apiUrl"
    $response = Send-JsonData -url $apiUrl -cookie $cookie -userAgent $userAgent -jsonData $jsonString
    Write-Output "First API call response: $($response | ConvertTo-Json -Depth 10)"

    if ($response -is [string]) {
        Write-Error "API response is not a valid JSON object."
        exit 1
    }

    $responseObj = $response

    if ($responseObj -and $responseObj.build_id -ne 0) {
        $buildId = $responseObj.build_id

        # Send the file info to the external download API
        $uploadData = @{
            project = $gitInfo.RepoName
            version = $buildInfo.Version
            build = $buildId
            file = $buildInfo.Files
        }

        Write-Output "Converting JSON data for the upload request"
        $uploadJsonString = ConvertTo-JsonString -data $uploadData

        $uploadUrl = "$api/v2/new/external_download"
        Write-Output "Preparing to send upload request to $uploadUrl"

        $uploadResponse = Send-JsonData -url $uploadUrl -cookie $cookie -userAgent $userAgent -jsonData $uploadJsonString

        Write-Output "Upload response: $($uploadResponse | ConvertTo-Json -Depth 10)"
    } else {
        Write-Error "Failed to get valid build_id from API response"
        exit 1
    }
} catch {
    Write-Error "An unexpected error occurred: $_"
    exit 1
}
