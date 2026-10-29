# Installs the Imogen AI consulting skills for Claude Code, Codex and Cursor (Windows PowerShell 5.1+ / PowerShell 7).
#   irm https://raw.githubusercontent.com/terddyy/imogen-skills/main/ai-consulting-1/install.ps1 | iex
# Re-run to update.
#   $env:IMOGEN_TOOLS = 'claude,codex,cursor'    pick tools instead of auto-detecting
#   $env:IMOGEN_SKILLS_DIR = '.agents\skills'    install into one folder only (e.g. a single project)
# Wrapped in a script block so `iex` doesn't leak variables or preferences into the caller's session.
& {
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$repo = 'terddyy/imogen-skills'
$branch = if ($env:IMOGEN_BRANCH) { $env:IMOGEN_BRANCH } else { 'main' }
$archiveUrl = if ($env:IMOGEN_ARCHIVE_URL) { $env:IMOGEN_ARCHIVE_URL } else { "https://codeload.github.com/$repo/zip/refs/heads/$branch" }

function Test-Tool($name) {
    (Test-Path (Join-Path $HOME ".$name")) -or [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

# Claude Code reads ~/.claude/skills, Codex reads ~/.agents/skills, and Cursor reads both
# (plus ~/.cursor/skills). Pick the fewest folders that cover the tools in use, so Cursor
# doesn't list every skill twice unless Claude and Codex are both installed.
if ($env:IMOGEN_SKILLS_DIR) {
    $targets = @($env:IMOGEN_SKILLS_DIR)
}
else {
    if ($env:IMOGEN_TOOLS) {
        $tools = @($env:IMOGEN_TOOLS -split ',' | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })
    }
    else {
        $tools = @('claude', 'codex', 'cursor' | Where-Object { Test-Tool $_ })
    }
    if ($tools.Count -eq 0) {
        Write-Host 'No Claude Code, Codex or Cursor install found; installing for all three.'
        $tools = @('claude', 'codex', 'cursor')
    }
    $targets = @()
    if ($tools -contains 'claude') { $targets += Join-Path $HOME '.claude\skills' }
    if ($tools -contains 'codex') { $targets += Join-Path $HOME '.agents\skills' }
    if (($tools -contains 'cursor') -and $targets.Count -eq 0) { $targets += Join-Path $HOME '.cursor\skills' }
    if ($targets.Count -eq 0) { throw 'IMOGEN_TOOLS must list claude, codex and/or cursor' }
    Write-Host "Installing for: $($tools -join ', ')"
}

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

    foreach ($dest in $targets) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        $count = 0
        foreach ($dir in Get-ChildItem -Path $src -Directory) {
            if (-not (Test-Path (Join-Path $dir.FullName 'SKILL.md'))) { continue }
            $target = Join-Path $dest $dir.Name
            if (Test-Path $target) { Remove-Item -Path $target -Recurse -Force }
            Copy-Item -Path $dir.FullName -Destination $target -Recurse
            $count++
        }
        Write-Host "  $count skills -> $dest"
    }

    Write-Host "Done. Start a new session, then describe what you're doing or call ask-imogen"
    Write-Host '(Claude Code / Cursor: /ask-imogen   Codex: $ask-imogen).'
}
finally {
    Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
}
