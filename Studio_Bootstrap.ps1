# ==============================================================================
# DECONSTRUCTION GOD STUDIO v14.2 - NODE [00]: Studio_Bootstrap.ps1
# Reads Studio_Manifest.toc in load order, compiles all C# Nodes, and boots GUI
# ==============================================================================
try {
    Write-Host "[1/3] Loading .NET Windows Forms Assemblies..." -ForegroundColor Cyan;
    Add-Type -AssemblyName System.Windows.Forms;
    Add-Type -AssemblyName System.Drawing;

    ($studioDir) = ($PSScriptRoot);
    if (-not ($studioDir)) { ($studioDir) = ((Get-Location).Path); }

    ($tocFile) = (Join-Path ($studioDir) "Studio_Manifest.toc");
    if (-not (Test-Path ($tocFile))) {
        throw "Missing Studio_Manifest.toc";
    }

    ($sb) = New-Object System.Text.StringBuilder;
    [void]($sb).AppendLine("using System;");
    [void]($sb).AppendLine("using System.IO;");
    [void]($sb).AppendLine("using System.Net;");
    [void]($sb).AppendLine("using System.Text;");
    [void]($sb).AppendLine("using System.Drawing;");
    [void]($sb).AppendLine("using System.Windows.Forms;");
    [void]($sb).AppendLine("using System.Text.RegularExpressions;");
    [void]($sb).AppendLine("using System.Collections.Generic;");

    ($tocLines) = [System.IO.File]::ReadAllLines(($tocFile), [System.Text.Encoding]::UTF8);
    ($count) = 0;

    for (($i) = 0; ($i) -lt ($tocLines).Length; ($i)++) {
        ($t) = (($tocLines)[($i)]).Trim();
        if ((($t).Length -eq 0) -or (($t).StartsWith("#"))) { continue; }

        ($np) = (Join-Path ($studioDir) ($t));
        if (-not (Test-Path ($np))) {
            throw ("Missing Node file listed in Studio_Manifest.toc: " + ($np));
        }

        ($raw) = [System.IO.File]::ReadAllText(($np), [System.Text.Encoding]::UTF8);
        ($clean) = [System.Text.RegularExpressions.Regex]::Replace(($raw), "(?m)^\s*using\s+[A-Za-z0-9_\.]+\s*;\s*$", "");
        [void]($sb).AppendLine(($clean));
        ($count)++;
    }

    Write-Host ("[2/3] Compiling " + ($count) + " Modular C# Nodes from Studio_Manifest.toc...") -ForegroundColor Cyan;

    Add-Type -TypeDefinition (($sb).ToString()) -ReferencedAssemblies @(
        "System.dll",
        "System.Core.dll",
        "System.Drawing.dll",
        "System.Windows.Forms.dll"
    );

    Write-Host "[3/3] Launching Deconstruction God Studio v14.2 (Modular Node System)..." -ForegroundColor Green;
    [System.Windows.Forms.Application]::EnableVisualStyles();
    ($mainForm) = New-Object StudioMainForm(($studioDir));
    [void][System.Windows.Forms.Application]::Run(($mainForm));

} catch {
    Write-Host "================================================================================" -ForegroundColor Red;
    Write-Host "FATAL ERROR IN STUDIO_BOOTSTRAP.PS1:" -ForegroundColor Red;
    Write-Host ($_.Exception.ToString()) -ForegroundColor Yellow;
    Write-Host "================================================================================" -ForegroundColor Red;
    Read-Host "Press Enter to close this window";
}