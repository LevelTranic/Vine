param (
    [string]$buildInfoPath,
    [string]$gitInfoPath,
    [string]$token,
    [Int16]$build
)

$buildInfo = Get-Content -Path $buildInfoPath | ConvertFrom-Json
$gitInfo = Get-Content -Path $gitInfoPath | ConvertFrom-Json

Write-Host $buildInfo

$tempFile = [System.IO.Path]::GetTempFileName()

$uploadData = @{
    project = $gitInfo.RepoName
    version = $buildInfo.Version
    build = $build
    file = $buildInfo.Files
}

$uploadData | ConvertTo-Json -Depth 10 | Set-Content -Path $tempFile -Force

$uploadUrl = "https://mars.tranic.one/v2/new/external_download"

$curlCommand = @"
curl -X POST "$uploadUrl" -H "Content-Type: application/json" -H "Cookie: mars_token=$token" -H "User-Agent: Mars-Utils/v1" -d "@$tempFile"
"@

try {
    $uploadResponse = Invoke-Expression $curlCommand
    Write-Output "Upload response: $uploadResponse"
} catch {
    Write-Error "Failed to execute curl command."
    Write-Error $_.Exception.Message
} finally {
    Remove-Item -Path $tempFile -Force
}
