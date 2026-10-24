<#
.SYNOPSIS
    Backup Gemini/Antigravity config directory to a new GitHub repository via GitHub REST API.
    Does not require local Git or GitHub CLI.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$RepoName = "gemini-config",

    [Parameter()]
    [string]$RepoDescription = "Antigravity & Gemini Configuration Backup",

    [Parameter()]
    [switch]$Public = $false,

    [Parameter()]
    [string]$Token = ""
)

$ErrorActionPreference = "Stop"

function Write-Step ($msg) { Write-Host "`n[*] $msg" -ForegroundColor Cyan }
function Write-Success ($msg) { Write-Host "[+] $msg" -ForegroundColor Green }
function Write-WarningMsg ($msg) { Write-Host "[!] $msg" -ForegroundColor Yellow }
function Write-ErrorMsg ($msg) { Write-Host "[-] $msg" -ForegroundColor Red }

# 1. Resolve Token
Write-Step "Resolving GitHub Personal Access Token (PAT)..."
if (-not $Token) {
    if ($env:GITHUB_TOKEN) {
        $Token = $env:GITHUB_TOKEN.Trim()
    } elseif (Test-Path ".env") {
        Get-Content ".env" | ForEach-Object {
            $line = $_.Trim()
            if ($line -match '^GITHUB_TOKEN\s*=\s*(.+)$') {
                $Token = $matches[1].Trim().Trim('"').Trim("'")
            }
        }
    }
}

if (-not $Token) {
    Write-ErrorMsg "GitHub Token not found!"
    Write-Host "Please provide a GitHub Personal Access Token with 'repo' scope." -ForegroundColor Yellow
    Write-Host "You can generate one here: https://github.com/settings/tokens/new?scopes=repo" -ForegroundColor Cyan
    Write-Host "Then run: .\scripts\backup-to-github.ps1 -Token 'your_token_here'" -ForegroundColor Gray
    exit 1
}

$headers = @{
    "Authorization"        = "Bearer $Token"
    "Accept"               = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
    "User-Agent"           = "Antigravity-Config-Backup"
}

# 2. Authenticate
Write-Step "Authenticating with GitHub..."
try {
    $user = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -Method Get
    $username = $user.login
    Write-Success "Logged in as: $username ($($user.name))"
} catch {
    Write-ErrorMsg "Authentication failed: $($_.Exception.Message)"
    exit 1
}

$isPrivate = -not $Public
$RepoName = ($RepoName -replace '[^a-zA-Z0-9_\.-]', '-').ToLower()
Write-Host "  -> Target Repository: $username/$RepoName (Private: $isPrivate)" -ForegroundColor Gray

# 3. Create or Check Repo
Write-Step "Checking repository existence..."
$repoExists = $false
try {
    $existing = Invoke-RestMethod -Uri "https://api.github.com/repos/$username/$RepoName" -Headers $headers -Method Get
    $repoExists = $true
    Write-Success "Repository already exists: $($existing.html_url)"
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 404) {
        Write-Step "Creating new repository '$RepoName'..."
        $body = @{
            name        = $RepoName
            description = $RepoDescription
            private     = $isPrivate
            auto_init   = $true
        } | ConvertTo-Json

        $created = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Headers $headers -Method Post -Body $body
        Write-Success "Created repository: $($created.html_url)"
        Start-Sleep -Seconds 2
        $repoExists = $true
    } else {
        Write-ErrorMsg "Failed to verify repo: $($_.Exception.Message)"
        exit 1
    }
}

# 4. Gather files to upload
Write-Step "Scanning configuration files to upload..."
$root = (Get-Location).Path
$ignoredPatterns = @(".git", ".env", "node_modules", "package-lock.json", ".migrated", "*.log", "deploy.ps1")
$allFiles = Get-ChildItem -Path $root -Recurse -File

$uploadList = @()
foreach ($file in $allFiles) {
    $skip = $false
    foreach ($pat in $ignoredPatterns) {
        if ($file.FullName -like "*\$pat*" -or $file.Name -eq $pat -or $file.Name -like $pat) {
            $skip = $true
            break
        }
    }
    if (-not $skip) {
        $rel = $file.FullName.Substring($root.Length).TrimStart("\").Replace("\", "/")
        $uploadList += [PSCustomObject]@{
            FullName = $file.FullName
            RelPath  = $rel
        }
    }
}

Write-Success "Found $($uploadList.Count) files to backup."

# 5. Upload files
Write-Step "Uploading files to GitHub repository..."
$successCount = 0
foreach ($item in $uploadList) {
    $path = $item.RelPath
    Write-Host "  -> $path ... " -NoNewline -ForegroundColor Gray

    $existingSha = $null
    try {
        $check = Invoke-RestMethod -Uri "https://api.github.com/repos/$username/$RepoName/contents/$path?ref=main" -Headers $headers -Method Get
        $existingSha = $check.sha
    } catch {
        # Not found on repo yet
    }

    $bytes = [System.IO.File]::ReadAllBytes($item.FullName)
    $b64 = [Convert]::ToBase64String($bytes)

    $payload = @{
        message = "Backup config file: $path"
        content = $b64
        branch  = "main"
    }
    if ($existingSha) {
        $payload["sha"] = $existingSha
    }

    $json = $payload | ConvertTo-Json -Compress
    try {
        $null = Invoke-RestMethod -Uri "https://api.github.com/repos/$username/$RepoName/contents/$path" -Headers $headers -Method Put -Body $json
        Write-Host "OK" -ForegroundColor Green
        $successCount++
    } catch {
        Write-Host "FAILED" -ForegroundColor Red
        Write-WarningMsg "Failed to upload $path : $($_.Exception.Message)"
    }
}

Write-Host "`n========================================================" -ForegroundColor Magenta
Write-Success "Backup complete! ($successCount/$($uploadList.Count) files uploaded)"
Write-Host "  Repository URL: https://github.com/$username/$RepoName" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Magenta
