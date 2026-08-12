@echo off
chcp 65001 >nul 2>&1
title MC 整合包智能更新工具 - 启动器

:: Check if .NET 8 runtime is installed
dotnet --list-runtimes 2>nul | findstr /C:"Microsoft.NETCore.App 8." >nul
if %errorlevel%==0 goto :run

:: .NET 8 not found - ask user to install
echo.
echo ══════════════════════════════════════════════
echo   MC 整合包智能更新工具 — by 小坣
echo ══════════════════════════════════════════════
echo.
echo   检测到您的电脑未安装 .NET 8 运行时。
echo   该运行时是本工具运行的必要组件。
echo.
echo ══════════════════════════════════════════════
echo.

:: Use PowerShell for GUI dialog
powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $result = [System.Windows.Forms.MessageBox]::Show('检测到您的电脑未安装 .NET 8 运行时。' + [Environment]::NewLine + [Environment]::NewLine + '是否自动下载并安装？' + [Environment]::NewLine + [Environment]::NewLine + '安装完成后将自动启动工具。', 'MC 整合包更新工具 - 需要安装运行时', 'YesNo', 'Question'); if ($result -eq 'Yes') { exit 0 } else { exit 1 }"

if %errorlevel%==1 goto :cancel

:: Download .NET 8 Desktop Runtime
echo.
echo   正在下载 .NET 8 Desktop Runtime...
echo.

set "DOTNET_URL=https://download.visualstudio.microsoft.com/download/pr/628c1574-822d-4e0f-a452-c0159f8ab65a/3298e0e5d66d4b129885d1e9df78f556/dotnet-sdk-8.0.412-win-x64.exe"
set "DOTNET_INSTALLER=%TEMP%\dotnet8-installer.exe"

:: Try direct download first
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOTNET_URL%' -OutFile '%DOTNET_INSTALLER%'" 2>nul

if not exist "%DOTNET_INSTALLER%" (
    echo   直接下载失败，尝试通过 GitHub 代理下载...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://ghproxy.net/%DOTNET_URL%' -OutFile '%DOTNET_INSTALLER%'" 2>nul
)

if not exist "%DOTNET_INSTALLER%" (
    echo.
    echo   下载失败！请手动安装 .NET 8 运行时：
    echo   https://dotnet.microsoft.com/download/dotnet/8.0
    echo.
    pause
    exit /b 1
)

echo   下载完成，正在安装（静默模式，可能需要1-2分钟）...
echo.

:: Silent install
"%DOTNET_INSTALLER%" /install /quiet /norestart

:: Verify installation
dotnet --list-runtimes 2>nul | findstr /C:"Microsoft.NETCore.App 8." >nul
if %errorlevel%==0 (
    echo   安装成功！
    echo.
    del "%DOTNET_INSTALLER%" 2>nul
    goto :run
) else (
    echo.
    echo   安装可能需要重启电脑才能生效。
    echo   请重启电脑后重新运行本工具。
    echo.
    del "%DOTNET_INSTALLER%" 2>nul
    pause
    exit /b 1
)

:run
:: Launch the main exe
start "" "%~dp0MCPackUpdater.exe"
exit /b 0

:cancel
echo.
echo   已取消安装。请手动安装 .NET 8 运行时后重试。
echo   下载地址: https://dotnet.microsoft.com/download/dotnet/8.0
echo.
pause
exit /b 1
