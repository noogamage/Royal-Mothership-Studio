<# :
@echo off
title AltVault 1920x1009 20-Second Preloaded Multi-Sheet HD Video Companion
cd /d "%~dp0"
powershell.exe -NoProfile -Sta -WindowStyle Hidden -ExecutionPolicy Bypass -Command "$scriptDir = '%~dp0'.TrimEnd('\'); Invoke-Expression ([System.IO.File]::ReadAllText('%~f0'))"
exit /b
#>
# ============================================================================
# FILE: AltVault_Companion.bat (SINGLE-FILE HYBRID LAUNCHER + GUI!)
# OPTION A: 20-SECOND PRELOADED MULTI-SHEET GPU STACK (UP TO 16 SHEETS = 512 FRAMES)
# Each Sheet (_V01.._V16.tga) = 4096x4096 32-Bit TGA (4x8 Grid = 32 Frames @ 1024x512 HD)
# ============================================================================
Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;

$AddonDir = ($PSScriptRoot);
if (-not ($AddonDir)) { $AddonDir = ($scriptDir); }
if (-not ($AddonDir)) { $AddonDir = ((Get-Location).Path); }
$AddonDir = (($AddonDir).TrimEnd('\')).TrimEnd('"');

$SnapDir = Join-Path ($AddonDir) "Snapshots";
if (-not (Test-Path ($SnapDir))) {
    New-Item -ItemType Directory -Path ($SnapDir) -Force | Out-Null;
}

$VaultDir = Join-Path ($AddonDir) "MyPicsVault";
if (-not (Test-Path ($VaultDir))) {
    New-Item -ItemType Directory -Path ($VaultDir) -Force | Out-Null;
}

$IgnoredFile = Join-Path ($SnapDir) "IgnoredAlts.txt";

$FlavorRoot = Split-Path (Split-Path ($AddonDir) -Parent) -Parent;
$MainWowRoot = Split-Path ($FlavorRoot) -Parent;

$ScreenshotsDir = Join-Path ($FlavorRoot) "Screenshots";
if (-not (Test-Path ($ScreenshotsDir))) {
    $AltShot = Join-Path ($MainWowRoot) "Screenshots";
    if (Test-Path ($AltShot)) {
        $ScreenshotsDir = ($AltShot);
    } else {
        New-Item -ItemType Directory -Path ($ScreenshotsDir) -Force | Out-Null;
    }
}

$MAX_REEL_SHEETS = 16;

# ============================================================================
# INLINE C# FAST 32-BIT UNCOMPRESSED .TGA WRITER (EXACT WOW 0x28 TOP-LEFT SPEC)
# ============================================================================
$CSharpTgaSource = @"
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

public static class WowNativeTgaWriter {
    public static void WriteUncompressed32BitTga(Bitmap srcBmp, string destTgaPath) {
        int width = srcBmp.Width;
        int height = srcBmp.Height;

        Rectangle rect = new Rectangle(0, 0, width, height);
        BitmapData bmpData = srcBmp.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        int stride = bmpData.Stride;
        byte[] buffer = new byte[stride * height];
        Marshal.Copy(bmpData.Scan0, buffer, 0, buffer.Length);
        srcBmp.UnlockBits(bmpData);

        for (int idx = 3; idx < buffer.Length; idx += 4) {
            buffer[idx] = 255;
        }

        using (FileStream fs = new FileStream(destTgaPath, FileMode.Create, FileAccess.Write, FileShare.None, 262144))
        using (BinaryWriter bw = new BinaryWriter(fs)) {
            byte[] header = new byte[18];
            header[2]  = 2;
            header[12] = (byte)(width & 0xFF);
            header[13] = (byte)((width >> 8) & 0xFF);
            header[14] = (byte)(height & 0xFF);
            header[15] = (byte)((height >> 8) & 0xFF);
            header[16] = 32;
            header[17] = 0x28;
            bw.Write(header);

            int rowBytes = width * 4;
            for (int y = 0; y < height; y++) {
                int rowOffset = y * stride;
                bw.Write(buffer, rowOffset, rowBytes);
            }
        }
    }
}
"@

Add-Type -TypeDefinition ($CSharpTgaSource) -ReferencedAssemblies "System.Drawing";

function Get-SanitizedCharTag([string]$RawName) {
    if (-not ($RawName)) { return "Player"; }
    $clean = ($RawName) -replace '\s+', '';
    $clean = ($clean) -replace '[^a-zA-Z0-9_\-]', '';
    if (-not ($clean)) { $clean = "Player"; }
    return ($clean);
}

function Test-IsAltIgnored([string]$CharName) {
    if (-not (Test-Path ($IgnoredFile))) { return ($false); }
    $target = (($CharName).Trim()).ToLower();
    $lines = @(Get-Content ($IgnoredFile) -ErrorAction SilentlyContinue);
    for ($i = 0; ($i) -lt (($lines).Count); $i++) {
        if ((((($lines)[$i]).Trim()).ToLower()) -eq ($target)) {
            return ($true);
        }
    }
    return ($false);
}

function Unignore-AltName([string]$CharName) {
    if (-not (Test-Path ($IgnoredFile))) { return; }
    $target = (($CharName).Trim()).ToLower();
    $lines = @(Get-Content ($IgnoredFile) -ErrorAction SilentlyContinue);
    $keep = @();
    for ($i = 0; ($i) -lt (($lines).Count); $i++) {
        $ln = (($lines)[$i]).Trim();
        if (($ln) -and (($ln.ToLower()) -ne ($target))) {
            $keep += ($ln);
        }
    }
    Set-Content -Path ($IgnoredFile) -Value ($keep) -ErrorAction SilentlyContinue;
}

function Ensure-CharacterSlotFiles([string]$CharName, [bool]$ForceWipeAll) {
    $tag = Get-SanitizedCharTag ($CharName);
    $blankBmp = New-Object System.Drawing.Bitmap(64, 64, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb);
    $gBlank = [System.Drawing.Graphics]::FromImage(($blankBmp));
    ($gBlank).Clear([System.Drawing.Color]::FromArgb(255, 18, 22, 32));
    ($gBlank).Dispose();

    for ($i = 1; ($i) -le 12; $i++) {
        $baseSlotName = ("{0}_Slot{1:D2}" -f ($tag), ($i));
        $tgaPath = Join-Path ($SnapDir) (($baseSlotName) + ".tga");
        $blpPath = Join-Path ($SnapDir) (($baseSlotName) + ".blp");
        if (Test-Path ($blpPath)) {
            Remove-Item -Path ($blpPath) -Force -ErrorAction SilentlyContinue;
        }
        if (($ForceWipeAll) -or (-not (Test-Path ($tgaPath)))) {
            [WowNativeTgaWriter]::WriteUncompressed32BitTga(($blankBmp), ($tgaPath));
        }
        for ($s = 1; ($s) -le ($MAX_REEL_SHEETS); $s++) {
            $vPath = Join-Path ($SnapDir) ("{0}_Slot{1:D2}_V{2:D2}.tga" -f ($tag), ($i), ($s));
            if (($ForceWipeAll) -or (-not (Test-Path ($vPath)))) {
                [WowNativeTgaWriter]::WriteUncompressed32BitTga(($blankBmp), ($vPath));
            }
        }
    }
    ($blankBmp).Dispose();
}

function Wipe-SingleCharacterSlot([string]$CharName, [int]$SlotNum) {
    $tag = Get-SanitizedCharTag ($CharName);
    $blankBmp = New-Object System.Drawing.Bitmap(64, 64, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb);
    $gBlank = [System.Drawing.Graphics]::FromImage(($blankBmp));
    ($gBlank).Clear([System.Drawing.Color]::FromArgb(255, 18, 22, 32));
    ($gBlank).Dispose();

    $basePath = Join-Path ($SnapDir) ("{0}_Slot{1:D2}.tga" -f ($tag), ($SlotNum));
    [WowNativeTgaWriter]::WriteUncompressed32BitTga(($blankBmp), ($basePath));
    for ($s = 1; ($s) -le ($MAX_REEL_SHEETS); $s++) {
        $vPath = Join-Path ($SnapDir) ("{0}_Slot{1:D2}_V{2:D2}.tga" -f ($tag), ($SlotNum), ($s));
        [WowNativeTgaWriter]::WriteUncompressed32BitTga(($blankBmp), ($vPath));
    }
    ($blankBmp).Dispose();
}

function Write-StaticSlotTextureFiles([System.Drawing.Bitmap]$Bmp, [string]$CharTag, [int]$SlotNum) {
    $baseSlotName = ("{0}_Slot{1:D2}" -f ($CharTag), ($SlotNum));
    $tgaPath = Join-Path ($SnapDir) (($baseSlotName) + ".tga");
    $blpPath = Join-Path ($SnapDir) (($baseSlotName) + ".blp");

    if (Test-Path ($blpPath)) {
        Remove-Item -Path ($blpPath) -Force -ErrorAction SilentlyContinue;
    }
    [WowNativeTgaWriter]::WriteUncompressed32BitTga(($Bmp), ($tgaPath));

    $v01Path = Join-Path ($SnapDir) ("{0}_Slot{1:D2}_V01.tga" -f ($CharTag), ($SlotNum));
    [WowNativeTgaWriter]::WriteUncompressed32BitTga(($Bmp), ($v01Path));
}

function Convert-ImageToSlotTGA([System.Drawing.Image]$SourceImage, [string]$CharTag, [int]$SlotNum, [int]$Size) {
    $bmp = New-Object System.Drawing.Bitmap(($Size), ($Size), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb);
    $g = [System.Drawing.Graphics]::FromImage(($bmp));
    ($g).Clear([System.Drawing.Color]::FromArgb(255, 10, 12, 18));
    ($g).InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;
    ($g).PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality;
    ($g).SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality;
    ($g).CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality;

    $srcRect = New-Object System.Drawing.Rectangle(0, 0, (($SourceImage).Width), (($SourceImage).Height));
    $dstRect = New-Object System.Drawing.Rectangle(0, 0, ($Size), ($Size));
    ($g).DrawImage(($SourceImage), ($dstRect), ($srcRect), [System.Drawing.GraphicsUnit]::Pixel);
    ($g).Dispose();

    Write-StaticSlotTextureFiles ($bmp) ($CharTag) ($SlotNum);
    ($bmp).Dispose();
}

function Set-PreviewFromVaultImage([System.Drawing.Image]$Img, [string]$FileName) {
    if ((($picPreview).Image)) {
        (($picPreview).Image).Dispose();
        ($picPreview).Image = ($null);
    }
    if (-not ($Img)) { return; }

    $cols = 1; $rows = 1;
    if (($FileName) -match '_FLIP32_|_REEL') { $cols = 4; $rows = 8; }
    elseif (($FileName) -match '_FLIP16_') { $cols = 4; $rows = 4; }
    elseif (($FileName) -match '_FLIP64_') { $cols = 8; $rows = 8; }

    if (($cols) -gt 1) {
        $cellW = [Math]::Max(1, [int]((($Img).Width) / ($cols)));
        $cellH = [Math]::Max(1, [int]((($Img).Height) / ($rows)));
        $frame1Bmp = New-Object System.Drawing.Bitmap(($cellW), ($cellH), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb);
        $gF1 = [System.Drawing.Graphics]::FromImage(($frame1Bmp));
        $srcRect = New-Object System.Drawing.Rectangle(0, 0, ($cellW), ($cellH));
        $dstRect = New-Object System.Drawing.Rectangle(0, 0, ($cellW), ($cellH));
        ($gF1).DrawImage(($Img), ($dstRect), ($srcRect), [System.Drawing.GraphicsUnit]::Pixel);
        ($gF1).Dispose();
        ($picPreview).Image = ($frame1Bmp);
    } else {
        ($picPreview).Image = New-Object System.Drawing.Bitmap(($Img));
    }
}

$script:MasterCharList = New-Object System.Collections.Generic.List[string];

function Add-DiscoveredName([string]$RawCandidate) {
    if (-not ($RawCandidate)) { return; }
    $clean = Get-SanitizedCharTag ($RawCandidate);
    if ((-not ($clean)) -or (($clean) -eq "Player") -or (($clean) -eq "SavedVariables") -or (($clean) -eq "Canvas")) { return; }
    if (Test-IsAltIgnored ($clean)) { return; }

    for ($i = 0; ($i) -lt (($script:MasterCharList).Count); $i++) {
        if (((($script:MasterCharList)[$i]).ToLower()) -eq (($clean).ToLower())) { return; }
    }
    [void]($script:MasterCharList).Add(($clean));
}

function Get-AllMacroCacheFiles {
    $localAppData = [Environment]::GetFolderPath("LocalApplicationData");
    $virtualStoreRoot = Join-Path ($localAppData) "VirtualStore\Program Files (x86)\World of Warcraft";
    $wtfRoots = @(
        (Join-Path ($FlavorRoot) "WTF"),
        (Join-Path ($MainWowRoot) "WTF"),
        (Join-Path ($virtualStoreRoot) "_classic_beta_\WTF"),
        (Join-Path ($virtualStoreRoot) "WTF")
    );
    $found = @();
    for ($wIdx = 0; ($wIdx) -lt (($wtfRoots).Count); $wIdx++) {
        $wDir = ($wtfRoots)[$wIdx];
        if (Test-Path ($wDir)) {
            $mFiles = @(Get-ChildItem -Path ($wDir) -Filter "macros-cache*.txt" -Recurse -ErrorAction SilentlyContinue);
            $found += ($mFiles);
        }
    }
    return ($found);
}

function Scan-AllCharacterSources {
    ($script:MasterCharList).Clear();

    $classPattern = "WARRIOR|PALADIN|HUNTER|ROGUE|PRIEST|DEATHKNIGHT|SHAMAN|MAGE|WARLOCK|DRUID|MONK";
    $macroFiles = @(Get-AllMacroCacheFiles);
    for ($mIdx = 0; ($mIdx) -lt (($macroFiles).Count); $mIdx++) {
        $mf = ($macroFiles)[$mIdx];
        $mRaw = Get-Content (($mf).FullName) -Raw -ErrorAction SilentlyContinue;
        if (($mRaw)) {
            $avMatches = [regex]::Matches(($mRaw), ("([A-Za-z]{{2,16}}):(?:{0}):\d+:[HA]:" -f ($classPattern)));
            for ($k = 0; ($k) -lt (($avMatches).Count); $k++) {
                Add-DiscoveredName (((($avMatches)[$k]).Groups[1]).Value);
            }
        }
    }

    $vFiles = @(Get-ChildItem -Path ($VaultDir) -Filter "*.png" -ErrorAction SilentlyContinue);
    for ($i = 0; ($i) -lt (($vFiles).Count); $i++) {
        $vf = ($vFiles)[$i];
        $m = [regex]::Match((($vf).Name), '^([A-Za-z]{2,16})_Slot\d\d_');
        if (($m).Success) {
            Add-DiscoveredName ((($m).Groups[1]).Value);
        }
    }

    for ($cIdx = 0; ($cIdx) -lt (($script:MasterCharList).Count); $cIdx++) {
        Ensure-CharacterSlotFiles (($script:MasterCharList)[$cIdx]) ($false);
    }
}

function Sync-FromInGameSlotChanges {
    $tag = Get-SanitizedCharTag (($cmbChar).Text);
    $macroFiles = @(Get-AllMacroCacheFiles | Sort-Object LastWriteTime -Descending);
    $syncedCount = 0;

    for ($mIdx = 0; ($mIdx) -lt (($macroFiles).Count); $mIdx++) {
        $mf = ($macroFiles)[$mIdx];
        $mRaw = Get-Content (($mf).FullName) -Raw -ErrorAction SilentlyContinue;
        if (-not ($mRaw)) { continue; }

        $syncPattern = "AVSYNC\|" + ($tag) + "\|([0-9=,]+)";
        $m = [regex]::Match(($mRaw), ($syncPattern));
        if (($m).Success) {
            $mapStr = (($m).Groups[1]).Value;
            $pairs = ($mapStr) -split ',';
            for ($p = 0; ($p) -lt (($pairs).Count); $p++) {
                $kv = (($pairs)[$p]) -split '=';
                if ((($kv).Count) -eq 2) {
                    $slotIdx = [int](($kv)[0]);
                    $fileIdx = [int](($kv)[1]);
                    if (($fileIdx) -le 0) {
                        Wipe-SingleCharacterSlot ($tag) ($slotIdx);
                        $syncedCount++;
                    }
                }
            }
            break;
        }
    }

    Refresh-CharacterVaultList;
    [console]::beep(850, 120);
    if (($syncedCount) -gt 0) {
        ($lblStatus).Text = "SYNCED IN-GAME CHANGES FOR " + ($tag) + ": Wiped " + [string]($syncedCount) + " cleared slot(s) from WoW!";
    } else {
        ($lblStatus).Text = "Synced with WoW for " + ($tag) + "! (Tip: /reload in WoW after clearing slots so WoW writes to disk).";
    }
}

# ============================================================================
# OPTION A: 20-SECOND MULTI-SHEET 4x8 HD REEL BUILDER (UP TO 16 SHEETS = 512 FRAMES!)
# Builds _V01.tga .. _V16.tga (each 4096x4096 with 32 frames @ 1024x512 HD)!
# ============================================================================
function Import-Mp4ToCharacterFlipbookSlot([string]$Mp4Path) {
    if (-not (Test-Path ($Mp4Path))) { return; }
    $tag = Get-SanitizedCharTag (($cmbChar).Text);
    $slotNum = [int](($numSlot).Value);
    Unignore-AltName ($tag);
    Ensure-CharacterSlotFiles ($tag) ($false);

    $tempFramesDir = Join-Path ($VaultDir) "_TempMp4Frames";
    if (Test-Path ($tempFramesDir)) {
        Remove-Item -Path ($tempFramesDir) -Recurse -Force -ErrorAction SilentlyContinue;
    }
    New-Item -ItemType Directory -Path ($tempFramesDir) -Force | Out-Null;

    $ffmpegExe = Join-Path ($AddonDir) "ffmpeg.exe";
    if (-not (Test-Path ($ffmpegExe))) {
        $cmd = Get-Command "ffmpeg" -ErrorAction SilentlyContinue;
        if (($cmd)) {
            $ffmpegExe = ($cmd).Source;
        } else {
            $wingetFfmpeg = @(Get-ChildItem -Path (Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "Microsoft\WinGet\Packages") -Filter "ffmpeg.exe" -Recurse -ErrorAction SilentlyContinue);
            if ((($wingetFfmpeg).Count) -gt 0) {
                $ffmpegExe = (($wingetFfmpeg)[0]).FullName;
            }
        }
    }

    if (-not (Test-Path ($ffmpegExe))) {
        [System.Windows.Forms.MessageBox]::Show(
            "Drop ffmpeg.exe into your AltVault folder (or run: winget install Gyan.FFmpeg).",
            "FFmpeg Required",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        );
        return;
    }

    $cols = 4;
    $rows = 8;
    $framesPerSheet = 32;
    $cellW = 1024;
    $cellH = 512;
    $atlasSize = 4096;
    $targetFps = [int](($numFps).Value);
    $maxSec = [int](($numMaxSec).Value);
    $maxFramesToExtract = [Math]::Min(($MAX_REEL_SHEETS * $framesPerSheet), ($targetFps * $maxSec));

    ($lblStatus).Text = "Extracting up to " + [string]($maxFramesToExtract) + " Widescreen HD (1024x512) frames @ " + [string]($targetFps) + " FPS (" + [string]($maxSec) + "s max)...";
    ($form).Refresh();

    $framePattern = "frame_" + [char]37 + "04d.png";
    $outPattern = Join-Path ($tempFramesDir) ($framePattern);
    $vfFilter = "fps=$targetFps,scale=${cellW}:${cellH}:flags=lanczos,unsharp=3:3:0.5:3:3:0.0";
    $ffArgs = "-y -i `"$Mp4Path`" -vf `"$vfFilter`" -frames:v $maxFramesToExtract `"$outPattern`"";
    Start-Process -FilePath ($ffmpegExe) -ArgumentList ($ffArgs) -Wait -NoNewWindow;

    $extracted = @(Get-ChildItem -Path ($tempFramesDir) -Filter "frame_*.png" -ErrorAction SilentlyContinue | Sort-Object Name);
    $extCount = ($extracted).Count;
    if (($extCount) -le 0) {
        ($lblStatus).Text = "Failed to extract frames from video!";
        return;
    }

    $numSheets = [Math]::Max(1, [Math]::Min($MAX_REEL_SHEETS, [int][Math]::Ceiling(($extCount) / 32.0)));
    $stamp = (Get-Date).ToString("yyyyMMdd_HHmmss");
    $reelGroupPrefix = ("{0}_Slot{1:D2}_REEL{2:D2}_{3}FPS_{4}" -f ($tag), ($slotNum), ($numSheets), ($targetFps), ($stamp));

    for ($sIdx = 1; ($sIdx) -le ($numSheets); $sIdx++) {
        ($lblStatus).Text = "Building 4096x4096 HD Sheet " + [string]($sIdx) + " of " + [string]($numSheets) + " (" + [string]($extCount) + " total frames)...";
        ($form).Refresh();

        $atlasBmp = New-Object System.Drawing.Bitmap(($atlasSize), ($atlasSize), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb);
        $gAtlas = [System.Drawing.Graphics]::FromImage(($atlasBmp));
        ($gAtlas).Clear([System.Drawing.Color]::FromArgb(255, 10, 12, 18));
        ($gAtlas).InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;
        ($gAtlas).PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality;

        for ($localF = 0; ($localF) -lt ($framesPerSheet); $localF++) {
            $globalF = (($sIdx - 1) * $framesPerSheet) + $localF;
            $srcIdx = [Math]::Min(($extCount - 1), $globalF);
            $srcFile = ($extracted)[$srcIdx];

            $r = [int]([Math]::Floor(($localF) / ($cols)));
            $c = [int](($localF) - (($r) * ($cols)));
            $dstRect = New-Object System.Drawing.Rectangle((($c) * ($cellW)), (($r) * ($cellH)), ($cellW), ($cellH));

            $fBytes = [System.IO.File]::ReadAllBytes((($srcFile).FullName));
            $fMs = New-Object System.IO.MemoryStream(,$fBytes);
            $fImg = [System.Drawing.Image]::FromStream(($fMs));
            ($gAtlas).DrawImage(($fImg), ($dstRect));
            ($fImg).Dispose();
            ($fMs).Dispose();
        }
        ($gAtlas).Dispose();

        $vTgaPath = Join-Path ($SnapDir) ("{0}_Slot{1:D2}_V{2:D2}.tga" -f ($tag), ($slotNum), ($sIdx));
        [WowNativeTgaWriter]::WriteUncompressed32BitTga(($atlasBmp), ($vTgaPath));

        if (($sIdx) -eq 1) {
            $baseTgaPath = Join-Path ($SnapDir) ("{0}_Slot{1:D2}.tga" -f ($tag), ($slotNum));
            [WowNativeTgaWriter]::WriteUncompressed32BitTga(($atlasBmp), ($baseTgaPath));
            $vaultPngName = ($reelGroupPrefix) + ".png";
            $vaultPngPath = Join-Path ($VaultDir) ($vaultPngName);
            ($atlasBmp).Save(($vaultPngPath), [System.Drawing.Imaging.ImageFormat]::Png);
            Set-PreviewFromVaultImage ($atlasBmp) ($vaultPngName);
        }

        $vaultSheetPng = Join-Path ($VaultDir) ("{0}_V{1:D2}.tmp" -f ($reelGroupPrefix), ($sIdx));
        ($atlasBmp).Save(($vaultSheetPng), [System.Drawing.Imaging.ImageFormat]::Png);
        ($atlasBmp).Dispose();
    }

    Remove-Item -Path ($tempFramesDir) -Recurse -Force -ErrorAction SilentlyContinue;
    Refresh-CharacterVaultList;
    [console]::beep(1000, 140);
    $totalSec = [Math]::Round(($extCount / [double]$targetFps), 1);
    ($lblStatus).Text = "SAVED " + [string]($totalSec) + "s HD VIDEO REEL (" + [string]($numSheets) + " Sheets / " + [string]($extCount) + " frames @ " + [string]($targetFps) + " FPS) -> Slot #" + [string]($slotNum) + "!`nIn WoW: Open Edit Studio on Slot #" + [string]($slotNum) + ", set Sheets=" + [string]($numSheets) + " + FPS=" + [string]($targetFps) + ", + /reload!";
}

# Build Companion GUI
$form = New-Object System.Windows.Forms.Form;
($form).Text = "AltVault 1920x1009 20-Second Preloaded Multi-Sheet HD Video Companion";
($form).Size = New-Object System.Drawing.Size(660, 560);
($form).StartPosition = "Manual";
$screen = ([System.Windows.Forms.Screen]::PrimaryScreen).WorkingArea;
($form).Location = New-Object System.Drawing.Point(((($screen).Width) - 675), ((($screen).Height) - 575));
($form).TopMost = ($false);
($form).BackColor = [System.Drawing.Color]::FromArgb(18, 22, 32);
($form).ForeColor = [System.Drawing.Color]::White;
($form).FormBorderStyle = "FixedSingle";
($form).MaximizeBox = ($false);

$lblHeader = New-Object System.Windows.Forms.Label;
($lblHeader).Text = "AltVault 1920x1009 20-Second Preloaded Multi-Sheet HD Video Vault";
($lblHeader).Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold);
($lblHeader).ForeColor = [System.Drawing.Color]::FromArgb(255, 209, 0);
($lblHeader).Location = New-Object System.Drawing.Point(14, 10);
($lblHeader).Size = New-Object System.Drawing.Size(620, 24);
(($form).Controls).Add(($lblHeader));

$lblChar = New-Object System.Windows.Forms.Label;
($lblChar).Text = "1. Select or Type Alt:";
($lblChar).ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 150);
($lblChar).Location = New-Object System.Drawing.Point(14, 42);
($lblChar).Size = New-Object System.Drawing.Size(130, 22);
(($form).Controls).Add(($lblChar));

$cmbChar = New-Object System.Windows.Forms.ComboBox;
($cmbChar).Location = New-Object System.Drawing.Point(146, 39);
($cmbChar).Size = New-Object System.Drawing.Size(120, 24);
($cmbChar).DropDownStyle = "DropDown";
(($form).Controls).Add(($cmbChar));

$btnRefreshChars = New-Object System.Windows.Forms.Button;
($btnRefreshChars).Text = "Scan Alts";
($btnRefreshChars).Location = New-Object System.Drawing.Point(272, 38);
($btnRefreshChars).Size = New-Object System.Drawing.Size(80, 25);
($btnRefreshChars).BackColor = [System.Drawing.Color]::FromArgb(45, 58, 85);
($btnRefreshChars).ForeColor = [System.Drawing.Color]::White;
($btnRefreshChars).FlatStyle = "Flat";
(($form).Controls).Add(($btnRefreshChars));

$btnSyncInGame = New-Object System.Windows.Forms.Button;
($btnSyncInGame).Text = "Sync In-Game Slots";
($btnSyncInGame).Location = New-Object System.Drawing.Point(356, 38);
($btnSyncInGame).Size = New-Object System.Drawing.Size(128, 25);
($btnSyncInGame).BackColor = [System.Drawing.Color]::FromArgb(25, 110, 130);
($btnSyncInGame).ForeColor = [System.Drawing.Color]::White;
($btnSyncInGame).FlatStyle = "Flat";
(($form).Controls).Add(($btnSyncInGame));

$lblSlot = New-Object System.Windows.Forms.Label;
($lblSlot).Text = "Slot (1-12):";
($lblSlot).Location = New-Object System.Drawing.Point(492, 42);
($lblSlot).Size = New-Object System.Drawing.Size(68, 22);
(($form).Controls).Add(($lblSlot));

$numSlot = New-Object System.Windows.Forms.NumericUpDown;
($numSlot).Location = New-Object System.Drawing.Point(562, 39);
($numSlot).Size = New-Object System.Drawing.Size(55, 24);
($numSlot).Minimum = 1;
($numSlot).Maximum = 12;
($numSlot).Value = 1;
(($form).Controls).Add(($numSlot));

$lblMapped = New-Object System.Windows.Forms.Label;
($lblMapped).Text = "Target Texture: Snapshots\Player_Slot01_V01..V16.tga (20-Sec Preloaded 4x8 HD Stack)";
($lblMapped).ForeColor = [System.Drawing.Color]::FromArgb(130, 210, 255);
($lblMapped).Location = New-Object System.Drawing.Point(14, 68);
($lblMapped).Size = New-Object System.Drawing.Size(615, 20);
(($form).Controls).Add(($lblMapped));

$chkPrtSc = New-Object System.Windows.Forms.CheckBox;
($chkPrtSc).Text = "Auto-Catch PrtSc";
($chkPrtSc).Checked = ($true);
($chkPrtSc).Location = New-Object System.Drawing.Point(14, 92);
($chkPrtSc).Size = New-Object System.Drawing.Size(125, 20);
(($form).Controls).Add(($chkPrtSc));

$lblMaxSec = New-Object System.Windows.Forms.Label;
($lblMaxSec).Text = "Max Video Sec:";
($lblMaxSec).ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 150);
($lblMaxSec).Location = New-Object System.Drawing.Point(150, 93);
($lblMaxSec).Size = New-Object System.Drawing.Size(92, 20);
(($form).Controls).Add(($lblMaxSec));

$numMaxSec = New-Object System.Windows.Forms.NumericUpDown;
($numMaxSec).Location = New-Object System.Drawing.Point(244, 90);
($numMaxSec).Size = New-Object System.Drawing.Size(52, 22);
($numMaxSec).Minimum = 2;
($numMaxSec).Maximum = 30;
($numMaxSec).Value = 20;
(($form).Controls).Add(($numMaxSec));

$lblFps = New-Object System.Windows.Forms.Label;
($lblFps).Text = "Video FPS (8-60):";
($lblFps).ForeColor = [System.Drawing.Color]::FromArgb(255, 209, 0);
($lblFps).Location = New-Object System.Drawing.Point(312, 93);
($lblFps).Size = New-Object System.Drawing.Size(105, 20);
(($form).Controls).Add(($lblFps));

$numFps = New-Object System.Windows.Forms.NumericUpDown;
($numFps).Location = New-Object System.Drawing.Point(420, 90);
($numFps).Size = New-Object System.Drawing.Size(52, 22);
($numFps).Minimum = 8;
($numFps).Maximum = 60;
($numFps).Value = 24;
(($form).Controls).Add(($numFps));

$chkTopMost = New-Object System.Windows.Forms.CheckBox;
($chkTopMost).Text = "Keep On Top";
($chkTopMost).Checked = ($false);
($chkTopMost).Location = New-Object System.Drawing.Point(490, 92);
($chkTopMost).Size = New-Object System.Drawing.Size(105, 20);
($chkTopMost).Add_CheckedChanged({ ($form).TopMost = ($chkTopMost).Checked; });
(($form).Controls).Add(($chkTopMost));

$btnManualGrab = New-Object System.Windows.Forms.Button;
($btnManualGrab).Text = "Save Latest Screenshot (Lossless 2048p .TGA)";
($btnManualGrab).Location = New-Object System.Drawing.Point(14, 118);
($btnManualGrab).Size = New-Object System.Drawing.Size(310, 34);
($btnManualGrab).BackColor = [System.Drawing.Color]::FromArgb(28, 120, 68);
($btnManualGrab).ForeColor = [System.Drawing.Color]::White;
($btnManualGrab).FlatStyle = "Flat";
(($form).Controls).Add(($btnManualGrab));

$btnImportMp4 = New-Object System.Windows.Forms.Button;
($btnImportMp4).Text = "Import Full 20s HD Video (.MP4 / .GIF)";
($btnImportMp4).Location = New-Object System.Drawing.Point(332, 118);
($btnImportMp4).Size = New-Object System.Drawing.Size(292, 34);
($btnImportMp4).BackColor = [System.Drawing.Color]::FromArgb(115, 55, 145);
($btnImportMp4).ForeColor = [System.Drawing.Color]::White;
($btnImportMp4).FlatStyle = "Flat";
(($form).Controls).Add(($btnImportMp4));

$lblStatus = New-Object System.Windows.Forms.Label;
($lblStatus).Text = "Ready! Extracts up to 16 Sheets (512 frames = 20+ seconds @ 24 FPS) of 1024x512 Widescreen HD!";
($lblStatus).Location = New-Object System.Drawing.Point(14, 158);
($lblStatus).Size = New-Object System.Drawing.Size(610, 36);
($lblStatus).ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 150);
(($form).Controls).Add(($lblStatus));

$lblVaultList = New-Object System.Windows.Forms.Label;
($lblVaultList).Text = "Selected Alt's Stored Pics / Videos:";
($lblVaultList).ForeColor = [System.Drawing.Color]::FromArgb(255, 209, 0);
($lblVaultList).Location = New-Object System.Drawing.Point(14, 198);
($lblVaultList).Size = New-Object System.Drawing.Size(225, 20);
(($form).Controls).Add(($lblVaultList));

$lstVault = New-Object System.Windows.Forms.ListBox;
($lstVault).Location = New-Object System.Drawing.Point(14, 220);
($lstVault).Size = New-Object System.Drawing.Size(225, 180);
($lstVault).BackColor = [System.Drawing.Color]::FromArgb(10, 12, 18);
($lstVault).ForeColor = [System.Drawing.Color]::White;
(($form).Controls).Add(($lstVault));

$btnAssignSelected = New-Object System.Windows.Forms.Button;
($btnAssignSelected).Text = "Assign to Slot";
($btnAssignSelected).Location = New-Object System.Drawing.Point(14, 406);
($btnAssignSelected).Size = New-Object System.Drawing.Size(110, 28);
($btnAssignSelected).BackColor = [System.Drawing.Color]::FromArgb(35, 95, 145);
($btnAssignSelected).ForeColor = [System.Drawing.Color]::White;
($btnAssignSelected).FlatStyle = "Flat";
(($form).Controls).Add(($btnAssignSelected));

$btnDeleteSelected = New-Object System.Windows.Forms.Button;
($btnDeleteSelected).Text = "Delete Pic + Slot";
($btnDeleteSelected).Location = New-Object System.Drawing.Point(129, 406);
($btnDeleteSelected).Size = New-Object System.Drawing.Size(110, 28);
($btnDeleteSelected).BackColor = [System.Drawing.Color]::FromArgb(135, 38, 38);
($btnDeleteSelected).ForeColor = [System.Drawing.Color]::White;
($btnDeleteSelected).FlatStyle = "Flat";
(($form).Controls).Add(($btnDeleteSelected));

$btnWipeAllCharSlots = New-Object System.Windows.Forms.Button;
($btnWipeAllCharSlots).Text = "Wipe All 12 Slots Clean";
($btnWipeAllCharSlots).Location = New-Object System.Drawing.Point(14, 440);
($btnWipeAllCharSlots).Size = New-Object System.Drawing.Size(145, 32);
($btnWipeAllCharSlots).BackColor = [System.Drawing.Color]::FromArgb(100, 30, 30);
($btnWipeAllCharSlots).ForeColor = [System.Drawing.Color]::FromArgb(255, 220, 220);
($btnWipeAllCharSlots).FlatStyle = "Flat";
(($form).Controls).Add(($btnWipeAllCharSlots));

$btnRemoveAlt = New-Object System.Windows.Forms.Button;
($btnRemoveAlt).Text = "Remove Alt";
($btnRemoveAlt).Location = New-Object System.Drawing.Point(164, 440);
($btnRemoveAlt).Size = New-Object System.Drawing.Size(75, 32);
($btnRemoveAlt).BackColor = [System.Drawing.Color]::FromArgb(120, 35, 35);
($btnRemoveAlt).ForeColor = [System.Drawing.Color]::White;
($btnRemoveAlt).FlatStyle = "Flat";
(($form).Controls).Add(($btnRemoveAlt));

$lblPreviewTitle = New-Object System.Windows.Forms.Label;
($lblPreviewTitle).Text = "1920x1009 Synchronized Preview (380 x 200 - Exact 1.903:1 Ratio):";
($lblPreviewTitle).ForeColor = [System.Drawing.Color]::FromArgb(130, 210, 255);
($lblPreviewTitle).Location = New-Object System.Drawing.Point(248, 198);
($lblPreviewTitle).Size = New-Object System.Drawing.Size(380, 20);
(($form).Controls).Add(($lblPreviewTitle));

$picPreview = New-Object System.Windows.Forms.PictureBox;
($picPreview).Location = New-Object System.Drawing.Point(248, 220);
($picPreview).Size = New-Object System.Drawing.Size(380, 200);
($picPreview).BorderStyle = "FixedSingle";
($picPreview).BackColor = [System.Drawing.Color]::FromArgb(10, 12, 18);
($picPreview).SizeMode = "StretchImage";
(($form).Controls).Add(($picPreview));

function Refresh-CharacterVaultList {
    $tag = Get-SanitizedCharTag (($cmbChar).Text);$sNum = [int](($numSlot).Value);$extName = ("{0}_Slot{1:D2}_V01..V16.tga" -f ($tag), ($sNum));
    ($lblMapped).Text = "Target Texture: Snapshots\" + ($extName) + " (20s Preloaded 4x8 HD Stack for " + ($tag) + ")";
    ($lblVaultList).Text = ($tag) + "'s Stored Pics / Videos:";

    Ensure-CharacterSlotFiles ($tag) ($false);

    if ((($picPreview).Image)) {
        (($picPreview).Image).Dispose();
        ($picPreview).Image = ($null);
    }

    (($lstVault).Items).Clear();$files = @(Get-ChildItem -Path ($VaultDir) -Filter ("{0}_*.png" -f ($tag)) -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending);
    for ($i = 0; ($i) -lt (($files).Count); $i++) {$f = ($files)[$i];
        [void](($lstVault).Items).Add((($f).Name));
    }
    if ((($lstVault).Items).Count -gt 0) {
        ($lstVault).SelectedIndex = 0;
    }
}

function Populate-CharacterDropdown {
    $currentText = ($cmbChar).Text;
    (($cmbChar).Items).Clear();
    Scan-AllCharacterSources;

    for ($i = 0; ($i) -lt (($script:MasterCharList).Count);$i++) {
        [void](($cmbChar).Items).Add((($script:MasterCharList)[$i]));
    }
    if (($currentText) -and (($cmbChar).Items).Contains(($currentText))) {
        ($cmbChar).Text = ($currentText);
    } elseif ((($cmbChar).Items).Count -gt 0) {
        ($cmbChar).SelectedIndex = 0;
    }
    Refresh-CharacterVaultList;
    ($lblStatus).Text = "Found " + [string]((($script:MasterCharList).Count)) + " AltVault Character(s): " + (($script:MasterCharList) -join ", ");
}

Populate-CharacterDropdown;

($btnRefreshChars).Add_Click({ Populate-CharacterDropdown; });
($btnSyncInGame).Add_Click({ Sync-FromInGameSlotChanges; });

($btnImportMp4).Add_Click({$ofd = New-Object System.Windows.Forms.OpenFileDialog;
    ($ofd).Title = "Select ShareX .MP4 or .GIF Clip (Full 20-Second Preloaded Multi-Sheet 4x8 HD)";
    ($ofd).Filter = "Video and GIF Clips (*.mp4;*.gif;*.webp;*.mkv;*.mov;*.avi)|*.mp4;*.gif;*.webp;*.mkv;*.mov;*.avi|All Files (*.*)|*.*";
    $capturesFolder = Join-Path ([Environment]::GetFolderPath("MyVideos")) "Captures";
    $latestSub = Get-ChildItem -Path ($capturesFolder) -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1;
    if (($latestSub)) {
        ($ofd).InitialDirectory = (($latestSub).FullName);
    } elseif (Test-Path ($capturesFolder)) {
        ($ofd).InitialDirectory = ($capturesFolder);
    }
    if ((($ofd).ShowDialog()) -eq [System.Windows.Forms.DialogResult]::OK) {
        Import-Mp4ToCharacterFlipbookSlot (($ofd).FileName);
    }
});

($btnRemoveAlt).Add_Click({
    $tag = Get-SanitizedCharTag (($cmbChar).Text);
    if ((-not ($tag)) -or (($tag) -eq "Player")) { return; }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Delete all .TGA slot files and stored pictures for '" + ($tag) + "'?",
        "Remove Alt: " + ($tag),
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    );
    if (($confirm) -ne [System.Windows.Forms.DialogResult]::Yes) { return; }

    if ((($picPreview).Image)) {
        (($picPreview).Image).Dispose();
        ($picPreview).Image = ($null);
    }

    $snaps = @(Get-ChildItem -Path ($SnapDir) -Filter ("{0}_Slot*.*" -f ($tag)) -ErrorAction SilentlyContinue);
    for ($i = 0; ($i) -lt (($snaps).Count);$i++) {
        Remove-Item -Path ((($snaps)[$i]).FullName) -Force -ErrorAction SilentlyContinue;
    }

    $pngs = @(Get-ChildItem -Path ($VaultDir) -Filter ("{0}_*.*" -f ($tag)) -ErrorAction SilentlyContinue);
    for ($i = 0; ($i) -lt (($pngs).Count);$i++) {
        Remove-Item -Path ((($pngs)[$i]).FullName) -Force -ErrorAction SilentlyContinue;
    }

    Add-Content -Path ($IgnoredFile) -Value ($tag) -ErrorAction SilentlyContinue;

    ($cmbChar).Text = "";
    Populate-CharacterDropdown;
    [console]::beep(500, 150);
    ($lblStatus).Text = "Removed '" + ($tag) + "' and deleted their slot files!";
});

($cmbChar).Add_SelectedIndexChanged({
    ($numSlot).Value = 1;
    Refresh-CharacterVaultList;
});
($cmbChar).Add_Leave({
    $typed = Get-SanitizedCharTag (($cmbChar).Text);
    if (($typed)) {
        Unignore-AltName ($typed);
        if (-not (($cmbChar).Items).Contains(($typed))) {
            [void](($cmbChar).Items).Add(($typed));
        }
    }
    Refresh-CharacterVaultList;
});
($numSlot).Add_ValueChanged({ Refresh-CharacterVaultList; });

($lstVault).Add_SelectedIndexChanged({
    $selName = [string](($lstVault).SelectedItem);
    if (($selName)) {$fullPath = Join-Path ($VaultDir) ($selName);
        if (Test-Path ($fullPath)) {
            $bytes = [System.IO.File]::ReadAllBytes(($fullPath));
            $ms = New-Object System.IO.MemoryStream(,$bytes);
            $img = [System.Drawing.Image]::FromStream(($ms));
            Set-PreviewFromVaultImage ($img) ($selName);
            ($img).Dispose();
            ($ms).Dispose();
        }
    }
});

($btnAssignSelected).Add_Click({
    $selName = [string](($lstVault).SelectedItem);
    if (-not ($selName)) {
        ($lblStatus).Text = "Click a picture or video in your Stored Pics list on the left first!";
        return;
    }
    $fullPath = Join-Path ($VaultDir) ($selName);
    if (Test-Path ($fullPath)) {$tag = Get-SanitizedCharTag (($cmbChar).Text);$sNum = [int](($numSlot).Value);$baseNoExt = [System.IO.Path]::GetFileNameWithoutExtension(($selName));$tmpSheets = @(Get-ChildItem -Path ($VaultDir) -Filter ("{0}_V*.tmp" -f ($baseNoExt)) -ErrorAction SilentlyContinue | Sort-Object Name);

        if ((($tmpSheets).Count) -gt 0) {
            for ($sIdx = 1; ($sIdx) -le (($tmpSheets).Count);$sIdx++) {
                $tf = ($tmpSheets)[$sIdx - 1];$tBytes = [System.IO.File]::ReadAllBytes((($tf).FullName));$tMs = New-Object System.IO.MemoryStream(,$tBytes);$tBmp = New-Object System.Drawing.Bitmap(($tMs));$vTga = Join-Path ($SnapDir) ("{0}_Slot{1:D2}_V{2:D2}.tga" -f ($tag), ($sNum), ($sIdx));
                [WowNativeTgaWriter]::WriteUncompressed32BitTga(($tBmp), ($vTga));
                if (($sIdx) -eq 1) {
                    $baseTga = Join-Path ($SnapDir) ("{0}_Slot{1:D2}.tga" -f ($tag), ($sNum));
                    [WowNativeTgaWriter]::WriteUncompressed32BitTga(($tBmp), ($baseTga));
                }
                ($tBmp).Dispose();
                ($tMs).Dispose();
            }
            [console]::beep(900, 100);
            ($lblStatus).Text = "ASSIGNED " + [string]((($tmpSheets).Count)) + "-SHEET HD REEL -> Slot #" + [string]($sNum) + "! Type /reload in WoW!";
        } else {
            $bytes = [System.IO.File]::ReadAllBytes(($fullPath));
            $ms = New-Object System.IO.MemoryStream(,$bytes);
            $img = [System.Drawing.Image]::FromStream(($ms));
            $targetSize = if (($selName) -match '_FLIP') { 4096 } else { 2048 };
            Convert-ImageToSlotTGA ($img) ($tag) ($sNum) ($targetSize);
            ($img).Dispose();
            ($ms).Dispose();
            [console]::beep(900, 100);
            ($lblStatus).Text = "ASSIGNED: " + ($selName) + " -> Snapshots\" + ("{0}_Slot{1:D2}.tga" -f ($tag), ($sNum)) + "! Type /reload in WoW!";
        }
    }
});

($btnDeleteSelected).Add_Click({
    $selName = [string](($lstVault).SelectedItem);
    $tag = Get-SanitizedCharTag (($cmbChar).Text);
    $sNum = [int](($numSlot).Value);

    if (($selName)) {$fullPath = Join-Path ($VaultDir) ($selName);
        if (Test-Path ($fullPath)) {
            if ((($picPreview).Image)) {
                (($picPreview).Image).Dispose();
                ($picPreview).Image = ($null);
            }
            Remove-Item -Path ($fullPath) -Force -ErrorAction SilentlyContinue;
        }
        $baseNoExt = [System.IO.Path]::GetFileNameWithoutExtension(($selName));$tmpSheets = @(Get-ChildItem -Path ($VaultDir) -Filter ("{0}_V*.tmp" -f ($baseNoExt)) -ErrorAction SilentlyContinue);
        for ($i = 0; ($i) -lt (($tmpSheets).Count);$i++) {
            Remove-Item -Path ((($tmpSheets)[$i]).FullName) -Force -ErrorAction SilentlyContinue;
        }
        $slotMatch = [regex]::Match(($selName), '_Slot(\d\d)_');
        if (($slotMatch).Success) {
            $parsedSlot = [int]((($slotMatch).Groups[1]).Value);
            Wipe-SingleCharacterSlot ($tag) ($parsedSlot);
        } else {
            Wipe-SingleCharacterSlot ($tag) ($sNum);
        }
    } else {
        Wipe-SingleCharacterSlot ($tag) ($sNum);
    }

    Refresh-CharacterVaultList;
    [console]::beep(600, 120);
    ($lblStatus).Text = "Deleted pic + wiped " + ($tag) + "'s slot clean! Type /reload in WoW!";
});

($btnWipeAllCharSlots).Add_Click({
    $tag = Get-SanitizedCharTag (($cmbChar).Text);
    Ensure-CharacterSlotFiles ($tag) ($true);
    if ((($picPreview).Image)) {
        (($picPreview).Image).Dispose();
        ($picPreview).Image = ($null);
    }
    $pngs = @(Get-ChildItem -Path ($VaultDir) -Filter ("{0}_*.*" -f ($tag)) -ErrorAction SilentlyContinue);
    for ($i = 0; ($i) -lt (($pngs).Count);$i++) {
        Remove-Item -Path ((($pngs)[$i]).FullName) -Force -ErrorAction SilentlyContinue;
    }
    ($numSlot).Value = 1;
    Refresh-CharacterVaultList;
    [console]::beep(500, 150);
    ($lblStatus).Text = "WIPED ALL 12 SLOTS FOR " + ($tag) + " CLEAN!`nType /reload in WoW!";
});

$script:lastShotFile = "";
if (($ScreenshotsDir) -and (Test-Path ($ScreenshotsDir))) {
    $latest = Get-ChildItem -Path ($ScreenshotsDir) -Filter "WoWScrnShot*.*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1;
    if (($latest)) { $script:lastShotFile = (($latest).FullName) + "_" + ((($latest).LastWriteTime).Ticks); }
}

$script:lastClipSig = "";
if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
    $cImg = [System.Windows.Forms.Clipboard]::GetImage();
    if (($cImg)) {
        $script:lastClipSig = [string](($cImg).Width) + "x" + [string](($cImg).Height);
        ($cImg).Dispose();
    }
}

function Save-ToCharacterVaultAndSlot([System.Drawing.Image]$Img, [string]$SourceTag) {
    $tag = Get-SanitizedCharTag (($cmbChar).Text);
    $slotNum = [int](($numSlot).Value);
    Unignore-AltName ($tag);
    Ensure-CharacterSlotFiles ($tag) ($false);

    $stamp = (Get-Date).ToString("yyyyMMdd_HHmmss");
    $vaultPngName = ("{0}_Slot{1:D2}_{2}.png" -f ($tag), ($slotNum), ($stamp));
    $vaultPngPath = Join-Path ($VaultDir) ($vaultPngName);
    ($Img).Save(($vaultPngPath), [System.Drawing.Imaging.ImageFormat]::Png);

    Convert-ImageToSlotTGA ($Img) ($tag) ($slotNum) 2048;
    Set-PreviewFromVaultImage ($Img) ($vaultPngName);

    Refresh-CharacterVaultList;
    [console]::beep(900, 100);
    ($lblStatus).Text = "SAVED LOSSLESS 2048p 32-BIT .TGA FOR " + ($tag) + " -> Snapshots\" + ("{0}_Slot{1:D2}.tga" -f ($tag), ($slotNum)) + "!`nIn WoW: Open " + ($tag) + "'s Album + type /reload!";

    if (($slotNum) -lt 12) {
        ($numSlot).Value = ($slotNum) + 1;
    } else {
        ($numSlot).Value = 1;
    }
}

($btnManualGrab).Add_Click({
    if (($ScreenshotsDir) -and (Test-Path ($ScreenshotsDir))) {
        $latest = Get-ChildItem -Path ($ScreenshotsDir) -Filter "WoWScrnShot*.*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1;
        if (($latest)) {
            $srcImg = [System.Drawing.Image]::FromFile((($latest).FullName));
            Save-ToCharacterVaultAndSlot ($srcImg) "WoWScrnShot";
            ($srcImg).Dispose();
            return;
        }
    }
    if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
        $clipImg = [System.Windows.Forms.Clipboard]::GetImage();
        if (($clipImg)) {
            Save-ToCharacterVaultAndSlot ($clipImg) "Clipboard";
            ($clipImg).Dispose();
            return;
        }
    }
    ($lblStatus).Text = "No screenshot found yet!";
});

$timer = New-Object System.Windows.Forms.Timer;
($timer).Interval = 700; ($timer).Add_Tick({
    if (($ScreenshotsDir) -and (Test-Path ($ScreenshotsDir))) {
        $latest = Get-ChildItem -Path ($ScreenshotsDir) -Filter "WoWScrnShot*.*" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1;
        if (($latest)) {$sig = (($latest).FullName) + "_" + ((($latest).LastWriteTime).Ticks);
            if (($sig) -ne ($script:lastShotFile)) {
                $script:lastShotFile = ($sig);
                Start-Sleep -Milliseconds 350;
                try {
                    $srcImg = [System.Drawing.Image]::FromFile((($latest).FullName));
                    Save-ToCharacterVaultAndSlot ($srcImg) "In-Game Snap";
                    ($srcImg).Dispose();
                } catch {}
            }
        }
    }

    if ((($chkPrtSc).Checked) -and ([System.Windows.Forms.Clipboard]::ContainsImage())) {$cImg = [System.Windows.Forms.Clipboard]::GetImage();
        if (($cImg)) {
            $b = New-Object System.Drawing.Bitmap(($cImg));
            $halfW = [int]((($b).Width) / 2);
            $halfH = [int]((($b).Height) / 2);
            $p1 = (($b).GetPixel(($halfW), ($halfH))).ToArgb();
            $cSig = [string](($b).Width) + "x" + [string](($b).Height) + "_" + [string]($p1);
            ($b).Dispose();
            if (($cSig) -ne ($script:lastClipSig)) {
                $script:lastClipSig = ($cSig);
                Save-ToCharacterVaultAndSlot ($cImg) "PrtSc";
            }
            ($cImg).Dispose();
        }
    }
});
($timer).Start();

[void](($form).ShowDialog());
# === END OF ALTVAULT_COMPANION.BAT ===