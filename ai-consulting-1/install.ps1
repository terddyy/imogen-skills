# Installs the Imogen AI consulting skills into Claude Code (Windows PowerShell 5.1+ / PowerShell 7).
#   irm https://raw.githubusercontent.com/terddyy/imogen-skills/main/ai-consulting-1/install.ps1 | iex
# Re-run to update. Set $env:CLAUDE_SKILLS_DIR to install somewhere else (e.g. .\.claude\skills for one project).
# Wrapped in a script block so `iex` doesn't leak variables or preferences into the caller's session.
& {
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$repo = 'terddyy/imogen-skills'
$branch = if ($env:IMOGEN_BRANCH) { $env:IMOGEN_BRANCH } else { 'main' }
$dest = if ($env:CLAUDE_SKILLS_DIR) { $env:CLAUDE_SKILLS_DIR } else { Join-Path $HOME '.claude\skills' }
$archiveUrl = if ($env:IMOGEN_ARCHIVE_URL) { $env:IMOGEN_ARCHIVE_URL } else { "https://codeload.github.com/$repo/zip/refs/heads/$branch" }

$tmp = Join-Path ([IO.Path]::GetTempPath()) ("imogen-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    Write-Host "Downloading $repo@$branch..."
    $zip = Join-Path $tmp 'skills.zip'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $archiveUrl -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $tmp -Force

    $src = Get-ChildItem -Path $tmp -Directory |
        ForEach-Object { Join-Path $_.FullName 'ai-consulting-1' } |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1
    if (-not $src) { throw 'ai-consulting-1 not found in the download' }

    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    $count = 0
    foreach ($dir in Get-ChildItem -Path $src -Directory) {
        if (-not (Test-Path (Join-Path $dir.FullName 'SKILL.md'))) { continue }
        $target = Join-Path $dest $dir.Name
        if (Test-Path $target) { Remove-Item -Path $target -Recurse -Force }
        Copy-Item -Path $dir.FullName -Destination $target -Recurse
        Write-Host "  + $($dir.Name)"
        $count++
    }

    Write-Host "Installed $count skills to $dest"
    Write-Host "Start a new Claude Code session, then just describe what you're doing (or run /ask-imogen)."
}
finally {
    Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
}
