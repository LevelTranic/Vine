param(
    [bool]$promoted = $false,
    [string]$channel = "default"
)

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

    $file = $files[0].Name
    if ($file -match ".*-(\d+\.\d+\.\d+)-.*") {
        $version = $matches[1]
        $family = $version -replace "\.\d+$"
    } else {
        Write-Error "Could not extract version information from file name"
        exit 1
    }

    return @{
        Files = $files
        Version = $version
        Family = $family
    }
}

function Send-JsonData {
    param (
        [string]$url,
        [string]$cookie,
        [string]$userAgent,
        [hashtable]$data
    )

    $jsonData = $data | ConvertTo-Json
    $headers = @{
        "Cookie" = $cookie
        "User-Agent" = $userAgent
        "Content-Type" = "application/json"
    }

    $response = Invoke-RestMethod -Uri $url -Method Post -Body $jsonData -Headers $headers
    return $response
}


function Upload-Files {
    param (
        [string]$url,
        [string]$cookie,
        [string]$userAgent,
        [array]$files
    )

    $multipartContent = [System.Net.Http.MultipartFormDataContent]::new()
    foreach ($file in $files) {
        $fileContent = [System.Net.Http.StreamContent]::new($file.OpenRead())

        $fileNameParts = $file.BaseName -split "-"
        if ($fileNameParts.Count -ge 2) {
            $fieldName = $fileNameParts[1]
        } else {
            Write-Error "Invalid file name format: $($file.Name)"
            exit 1
        }

        $fileContent.Headers.ContentDisposition = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
        $fileContent.Headers.ContentDisposition.Name = '"' + $fieldName + '"'
        $fileContent.Headers.ContentDisposition.FileName = '"' + $file.Name + '"'
        $multipartContent.Add($fileContent)
    }

    $httpClient = [System.Net.Http.HttpClient]::new()
    $httpClient.DefaultRequestHeaders.Add("Cookie", $cookie)
    $httpClient.DefaultRequestHeaders.Add("User-Agent", $userAgent)

    try {
        $response = $httpClient.PostAsync($url, $multipartContent).Result
        if ($response -eq $null) {
            Write-Error "Failed to get a valid response from the server."
            exit 1
        }

        $responseContent = $response.Content.ReadAsStringAsync().Result
        Write-Output "Received response from file upload:"
        Write-Output $responseContent
    } catch {
        Write-Error "Failed to upload files to API. $_"
        exit 1
    }

    return $responseContent
}

$gitInfo = Get-GitInfo
$buildInfo = Get-BuildInfo

$jsonData = @{
    project = $gitInfo.RepoName
    version = $buildInfo.Version
    family = $buildInfo.Family
    channel = $channel
    promoted = $promoted
    changes = @(
        @{
            commit = $gitInfo.Commit
            summary = $gitInfo.Title
            message = $gitInfo.Message
        }
    )
}

$apiUrl = "http://127.0.0.1:7743/v2/new/build"
$cookie = "mars_token=WlVReVcySkRNRUJoVERrbFlrZzBLbUZJTTBCb1FqQmVZMFV3Sm1OS01WNWhRak4r"
$userAgent = "Mars-Utils/v1"

$response = Send-JsonData -url $apiUrl -cookie $cookie -userAgent $userAgent -data $jsonData
Write-Output $response

if ($response -is [string]) {
    Write-Error "API response is not a valid JSON object."
    exit 1
}

$responseObj = $response

if ($responseObj -and $responseObj.build_id -ne 0) {
    $buildId = $responseObj.build_id

    $uploadUrl = "http://127.0.0.1:7743/v2/new/download?project=$($gitInfo.RepoName)&version=$($buildInfo.Version)&build=$buildId"
    $uploadResponse = Upload-Files -url $uploadUrl -cookie $cookie -userAgent $userAgent -files $buildInfo.Files

    Write-Output "Upload response: $uploadResponse"
} else {
    Write-Error "Failed to get valid build_id from API response"
    exit 1
}