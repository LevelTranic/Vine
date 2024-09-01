$currentDirectory = Get-Location

if (Test-Path "$currentDirectory\.git") {
    $gitRepoName = (git rev-parse --show-toplevel | Split-Path -Leaf).ToLower()

    $jarDirectory = Join-Path -Path $currentDirectory -ChildPath "build/libs"

    if (Test-Path $jarDirectory) {
        $regexPattern = "$gitRepoName-bundler-(\d+\.\d+\.\d+)(-[^\-]+)*\.jar"

        Get-ChildItem -Path $jarDirectory -Filter "*.jar" | Where-Object { $_.Name -match $regexPattern } | ForEach-Object {
            Write-Host "Deleting file: $($_.FullName)"
            Remove-Item -Path $_.FullName -Force
        }
    } else {
        Write-Error "Directory 'build/libs' does not exist."
        exit 1
    }
} else {
    Write-Error "Current directory is not a Git repository."
    exit 1
}
