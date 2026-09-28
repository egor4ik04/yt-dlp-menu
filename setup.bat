@echo off
chcp 65001 >nul
setlocal EnableExtensions

cd /d "%~dp0"

set "ROOT=%~dp0"
set "TOOLS=%ROOT%tools"
set "DENO_INSTALL=%TOOLS%\deno"
set "FFMPEG_DIR=%TOOLS%\ffmpeg"
set "PATH=%TOOLS%;%DENO_INSTALL%\bin;%FFMPEG_DIR%\bin;%PATH%"

echo ========================================
echo       YT Downloader - Windows Setup
echo ========================================
echo.

if not exist "%TOOLS%" mkdir "%TOOLS%"
if not exist "%DENO_INSTALL%\bin" mkdir "%DENO_INSTALL%\bin"

echo [1/3] Updating yt-dlp nightly...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';" ^
  "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
  "$url='https://github.com/yt-dlp/yt-dlp-nightly-builds/releases/latest/download/yt-dlp.exe';" ^
  "Invoke-WebRequest -Uri $url -OutFile '%TOOLS%\yt-dlp.exe.tmp';" ^
  "Move-Item -Force '%TOOLS%\yt-dlp.exe.tmp' '%TOOLS%\yt-dlp.exe'"

if errorlevel 1 (
    echo ERROR: Failed to download yt-dlp.
    pause
    exit /b 1
)

echo.
echo [2/3] Installing or updating Deno...

rem Deno is downloaded as a plain zip into tools\deno\bin.
rem The official install.ps1 is NOT used, because it edits the user PATH.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';" ^
  "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
  "$url='https://github.com/denoland/deno/releases/latest/download/deno-x86_64-pc-windows-msvc.zip';" ^
  "$zip='%TOOLS%\deno.zip';" ^
  "Invoke-WebRequest -Uri $url -OutFile $zip;" ^
  "Expand-Archive -Path $zip -DestinationPath '%DENO_INSTALL%\bin' -Force;" ^
  "Remove-Item $zip -Force"

if errorlevel 1 (
    echo ERROR: Failed to install Deno.
    pause
    exit /b 1
)

echo.
echo [3/3] Checking FFmpeg...

if exist "%FFMPEG_DIR%\bin\ffmpeg.exe" if exist "%FFMPEG_DIR%\bin\ffprobe.exe" goto ffmpeg_ok

echo FFmpeg not found in tools\ffmpeg, downloading (this may take a while)...

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';" ^
  "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
  "$url='https://github.com/yt-dlp/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip';" ^
  "$zip='%TOOLS%\ffmpeg.zip'; $tmp='%TOOLS%\ffmpeg_tmp';" ^
  "if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force };" ^
  "Invoke-WebRequest -Uri $url -OutFile $zip;" ^
  "Expand-Archive -Path $zip -DestinationPath $tmp -Force;" ^
  "$src = (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName;" ^
  "New-Item -ItemType Directory -Force '%FFMPEG_DIR%\bin' | Out-Null;" ^
  "Copy-Item (Join-Path $src 'bin\ffmpeg.exe') '%FFMPEG_DIR%\bin' -Force;" ^
  "Copy-Item (Join-Path $src 'bin\ffprobe.exe') '%FFMPEG_DIR%\bin' -Force;" ^
  "Remove-Item $tmp -Recurse -Force; Remove-Item $zip -Force"

if errorlevel 1 (
    echo ERROR: Failed to download FFmpeg.
    pause
    exit /b 1
)
goto ffmpeg_done

:ffmpeg_ok
echo FFmpeg is already installed locally, skipping.
echo To update it, delete the tools\ffmpeg folder and run setup.bat again.

:ffmpeg_done

echo.
echo Checking yt-dlp...

"%TOOLS%\yt-dlp.exe" --version

echo.
echo Checking Deno...

"%DENO_INSTALL%\bin\deno.exe" --version

echo.
echo Checking FFmpeg...

"%FFMPEG_DIR%\bin\ffmpeg.exe" -version | findstr /b /c:"ffmpeg version"

echo.
echo ========================================
echo Setup completed!
echo.
echo You can now launch YT_MENU.bat
echo ========================================
pause