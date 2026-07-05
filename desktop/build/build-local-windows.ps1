# build-local-windows.ps1
#
# A-local entry point: compila o Vulcan Office desktop v9.3.1-vulcan.<N> no
# Windows do dono, do zero, via ONLYOFFICE/build_tools. Duracao esperada:
# 4-6 horas em maquina com MSVC 2022 + Qt 6.7 + 100 GB de disco livre.
#
# Uso:
#   pwsh -File desktop\build\build-local-windows.ps1 -Version 9.3.1-vulcan.4
#
# Este script NAO patcha upstream. Ele:
#   1. Verifica prereqs (VS2022, Qt, Perl, Python, Node, Git).
#   2. Cria workspace em C:\vulcan-build\ (ou -WorkDir customizado).
#   3. Clona build_tools + escreve branding config Vulcan.
#   4. Roda configure.py + make.py com --branding=<nossa pasta>.
#   5. Aplica overlay de branding (icons, About, strings) via apply-branding.sh
#      no checkout de desktop-apps DENTRO do workspace do build_tools.
#   6. Empacota via desktop-apps\package\make.ps1.
#   7. Copia o .exe final para desktop\build\out\ do repo Vulcan.
#   8. Calcula sha256 e escreve build-manifest.txt.

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$Version,

    [string]$WorkDir = "C:\vulcan-build",

    [string]$QtDir = "C:\Qt\6.7.2\msvc2019_64",

    [string]$VSPath,

    [switch]$SkipPrereqCheck,

    [switch]$SkipClone,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Locations relative to this script.
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$DesktopDir = Split-Path -Parent $ScriptDir
$RepoRoot   = Split-Path -Parent $DesktopDir
$OverlayDir = Join-Path $DesktopDir "branding"
$OutDir     = Join-Path $ScriptDir "out"

function Log-Step { param([string]$msg) Write-Host "`n== $msg ==" -ForegroundColor Cyan }
function Log-Info { param([string]$msg) Write-Host "   $msg" -ForegroundColor Gray }
function Log-Err  { param([string]$msg) Write-Host "!! $msg" -ForegroundColor Red }

# --- 1. Prereqs --------------------------------------------------------------

function Check-Prereqs {
    Log-Step "Verificando pre-requisitos"

    $missing = @()

    if (-not (Get-Command git -ErrorAction SilentlyContinue))    { $missing += "git" }
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) { $missing += "python (3.10+)" }
    if (-not (Get-Command perl -ErrorAction SilentlyContinue))   { $missing += "perl (Strawberry)" }
    if (-not (Get-Command node -ErrorAction SilentlyContinue))   { $missing += "node.js (20 LTS)" }
    if (-not (Get-Command npm -ErrorAction SilentlyContinue))    { $missing += "npm" }

    if (-not (Test-Path (Join-Path $QtDir "bin\qmake.exe"))) {
        $missing += "Qt em $QtDir (bin\qmake.exe nao encontrado)"
    }

    # VS 2022 detection via vswhere
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) {
        $missing += "vswhere (Visual Studio 2022)"
    } else {
        $vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if (-not $vs) { $missing += "MSVC v143 toolset em VS 2022" }
        else { Log-Info "VS 2022 em $vs" }
        if (-not $VSPath) {
            $script:VSPath = Join-Path $vs "VC\Auxiliary\Build\vcvars64.bat"
        }
    }

    if (-not (Test-Path "C:\Program Files (x86)\Inno Setup 6\ISCC.exe")) {
        $missing += "Inno Setup 6 (esperado em Program Files (x86))"
    }

    if ($missing.Count -gt 0) {
        Log-Err "Faltando:"
        $missing | ForEach-Object { Log-Err "  - $_" }
        throw "Instale as dependencias antes de retentar."
    }

    Log-Info "Todos os pre-requisitos presentes."

    # Disk space check on drive of $WorkDir
    $drive = (Split-Path -Qualifier $WorkDir).TrimEnd(":") + ":"
    $free  = (Get-PSDrive -Name $drive.TrimEnd(":")).Free
    $freeGB = [math]::Round($free / 1GB, 1)
    Log-Info "Disco $drive: $freeGB GB livres"
    if ($freeGB -lt 80) {
        Log-Err "Precisa de pelo menos 80 GB livres (recomendado 100). Abortando."
        throw "insufficient disk"
    }

    # Long paths
    $longpaths = git config --global --get core.longpaths 2>$null
    if ($longpaths -ne "true") {
        Log-Info "Habilitando core.longpaths = true (necessario para clone)"
        git config --global core.longpaths true
    }
}

# --- 2. Workspace ------------------------------------------------------------

function Ensure-Workspace {
    Log-Step "Preparando workspace em $WorkDir"
    if (-not (Test-Path $WorkDir)) {
        New-Item -ItemType Directory -Path $WorkDir | Out-Null
    }
    Set-Location $WorkDir
}

# --- 3. build_tools clone + branding config ---------------------------------

function Clone-BuildTools {
    Log-Step "Clonando ONLYOFFICE/build_tools"

    $bt = Join-Path $WorkDir "build_tools"
    if ($SkipClone -and (Test-Path $bt)) {
        Log-Info "SkipClone: reutilizando $bt existente"
        return $bt
    }
    if (Test-Path $bt) {
        Log-Info "Removendo build_tools existente"
        Remove-Item -Recurse -Force $bt
    }
    git clone --depth 1 https://github.com/ONLYOFFICE/build_tools.git $bt
    Log-Info "OK"

    # Copiar nosso branding config para dentro da arvore de scripts do build_tools.
    $brand_src = Join-Path $DesktopDir "context\vulcanoffice-branding.py"
    $brand_dst = Join-Path $bt "scripts\vulcanoffice-branding.py"
    if (Test-Path $brand_src) {
        Copy-Item -Force $brand_src $brand_dst
        Log-Info "Branding config copiado para scripts\vulcanoffice-branding.py"
    } else {
        Log-Err "Branding config nao encontrado em $brand_src"
        throw "missing branding config"
    }

    return $bt
}

# --- 4. Configure + Make ----------------------------------------------------

function Run-Configure {
    param([string]$BuildToolsDir)
    Log-Step "configure.py (win_64, module=desktop, branding=vulcanoffice)"

    Push-Location $BuildToolsDir
    try {
        $args = @(
            "configure.py",
            "--platform=win_64",
            "--module=desktop",
            "--branding=$($DesktopDir -replace '\\','/')/context",
            "--branding-name=vulcanoffice",
            "--qt-dir=$($QtDir | Split-Path -Parent | Split-Path -Parent)",
            "--vs-version=2022",
            "--vs-path=$VSPath",
            "--clean=1",
            "--update=1",
            "--branch=master",
            "--git-protocol=https"
        )
        Log-Info ("python $($args -join ' ')")
        if (-not $DryRun) {
            python @args
            if ($LASTEXITCODE -ne 0) { throw "configure.py exit $LASTEXITCODE" }
        }
    } finally {
        Pop-Location
    }
}

function Run-Make {
    param([string]$BuildToolsDir)
    Log-Step "make.py (build principal, esperado 3-5h)"

    Push-Location $BuildToolsDir
    try {
        Log-Info "Iniciando $(Get-Date -Format o)"
        if (-not $DryRun) {
            python make.py
            if ($LASTEXITCODE -ne 0) { throw "make.py exit $LASTEXITCODE" }
        }
        Log-Info "Finalizado $(Get-Date -Format o)"
    } finally {
        Pop-Location
    }
}

# --- 5. Apply-branding sobre desktop-apps DENTRO do workspace ---------------

function Apply-BrandingOverlay {
    param([string]$BuildToolsDir)
    Log-Step "Aplicando overlay Vulcan em desktop-apps"

    $desktop_apps = Join-Path $BuildToolsDir "..\desktop-apps"
    if (-not (Test-Path $desktop_apps)) {
        # Alguns builds colocam desktop-apps ao lado de build_tools.
        $desktop_apps = Join-Path $BuildToolsDir "desktop-apps"
        if (-not (Test-Path $desktop_apps)) {
            throw "desktop-apps checkout nao encontrado; investigar layout do build_tools"
        }
    }
    Log-Info "Overlay target: $desktop_apps"

    $script = Join-Path $ScriptDir "apply-branding.sh"
    if (-not (Test-Path $script)) { throw "apply-branding.sh sumiu" }

    if ($DryRun) { Log-Info "DryRun: pulando"; return }

    # Rodar via bash do Git for Windows
    $git_bash = Get-Command bash -ErrorAction SilentlyContinue
    if (-not $git_bash) {
        $git_bash = "C:\Program Files\Git\bin\bash.exe"
    } else {
        $git_bash = $git_bash.Source
    }

    & $git_bash "$script" "$desktop_apps"
    if ($LASTEXITCODE -ne 0) { throw "apply-branding.sh exit $LASTEXITCODE" }
}

# --- 6. Package via desktop-apps\package\make.ps1 ---------------------------

function Package-Installer {
    param([string]$BuildToolsDir)
    Log-Step "Empacotando com desktop-apps\package\make.ps1"

    $pkg_dir = Join-Path $BuildToolsDir "..\desktop-apps\package"
    if (-not (Test-Path $pkg_dir)) {
        $pkg_dir = Join-Path $BuildToolsDir "desktop-apps\package"
    }

    Push-Location $pkg_dir
    try {
        # Dot-source do branding.vulcanoffice.ps1 (copiado pelo apply-branding.sh)
        . .\branding.vulcanoffice.ps1

        # Chamar upstream make.ps1 apontando o SourceDir para o build tree gerado.
        # O caminho tipico e: build_tools\out\win_64\Vulcan\Vulcan Office\
        $source = Join-Path $BuildToolsDir "out\win_64\$($PackageName -replace ' ','')\$PackageName"
        if (-not (Test-Path $source)) {
            # Cair para valores padrao caso o branding.py nao tenha mapeado 1-1
            $source = (Get-ChildItem -Recurse -Path (Join-Path $BuildToolsDir "out\win_64") -Filter "DesktopEditors.exe" -File | Select-Object -First 1).Directory.FullName
            if (-not $source) { throw "build tree nao encontrado apos make.py" }
        }
        Log-Info "SourceDir: $source"

        if ($DryRun) { Log-Info "DryRun: pulando"; return }
        .\make.ps1 -Version $Version -Arch x64 -SourceDir $source -CompanyName "Vulcan" -ProductName "Vulcan Office"
        if ($LASTEXITCODE -ne 0) { throw "make.ps1 exit $LASTEXITCODE" }
    } finally {
        Pop-Location
    }
}

# --- 7. Coletar .exe + sha256 + manifest ------------------------------------

function Collect-Artifacts {
    param([string]$BuildToolsDir)
    Log-Step "Coletando artefatos"

    if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

    $pkg_build = (Get-ChildItem -Recurse -Path $BuildToolsDir -Filter "VulcanOffice-Setup-*.exe" -File `
        | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
    if (-not $pkg_build) {
        # fallback nome antigo
        $pkg_build = (Get-ChildItem -Recurse -Path $BuildToolsDir -Filter "*Setup*.exe" -File `
            | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
    }
    if (-not $pkg_build) { throw "nenhum installer .exe produzido" }

    $target = Join-Path $OutDir "VulcanOffice-Setup-x64-$Version.exe"
    Copy-Item -Force $pkg_build.FullName $target
    Log-Info "Installer: $target ($([math]::Round($pkg_build.Length / 1MB, 1)) MB)"

    $hash = (Get-FileHash $target -Algorithm SHA256).Hash.ToLower()
    $shafile = Join-Path $OutDir "sha256sums.txt"
    "$hash  $(Split-Path -Leaf $target)" | Out-File -FilePath $shafile -Encoding ASCII

    $manifest = Join-Path $OutDir "build-manifest.txt"
    @(
        "Vulcan Office desktop $Version",
        "Build host: $env:COMPUTERNAME",
        "Build date: $(Get-Date -Format o)",
        "Installer:  $(Split-Path -Leaf $target)",
        "SHA-256:    $hash",
        "Source pin: ver desktop/UPSTREAM.md do repo"
    ) | Out-File -FilePath $manifest -Encoding ASCII

    Log-Info "sha256 $hash"
    Log-Info "manifesto: $manifest"
}

# --- Main --------------------------------------------------------------------

Log-Step "Vulcan Office desktop build local (Windows), versao $Version"
Log-Info "Script: $ScriptDir"
Log-Info "Repo:   $RepoRoot"
Log-Info "Work:   $WorkDir"

if (-not $SkipPrereqCheck) { Check-Prereqs }
Ensure-Workspace
$bt = Clone-BuildTools
Run-Configure -BuildToolsDir $bt
Run-Make -BuildToolsDir $bt
Apply-BrandingOverlay -BuildToolsDir $bt
Package-Installer -BuildToolsDir $bt
Collect-Artifacts -BuildToolsDir $bt

Log-Step "OK. Proximos passos:"
Log-Info "1) Testar $($OutDir)\VulcanOffice-Setup-x64-$Version.exe em Windows limpo."
Log-Info "2) Publicar release:"
Log-Info "     gh release create v$Version --repo freddominugez/vulcan-office-stack \``"
Log-Info "       --title 'Vulcan Office $Version' \``"
Log-Info "       --notes-file desktop\build\out\build-manifest.txt \``"
Log-Info "       desktop\build\out\*"
Log-Info "3) Rodar auditoria D12 via subagent (ver context\HANDOFF-SESSION-1.md)."
