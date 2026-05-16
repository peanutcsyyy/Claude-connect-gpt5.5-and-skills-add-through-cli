@echo off
setlocal

set "SESSION=%~1"
set "DISTRO=%~2"

if "%SESSION%"=="" (
  echo missing tmux session name
  exit /b 1
)

if "%DISTRO%"=="" set "DISTRO=Ubuntu"

set "SCRIPT_DIR=%~dp0"
set "ATTACH_SCRIPT=%SCRIPT_DIR%..\wsl\attach_tmux.sh"

title Claude Monitor: %SESSION%
wsl.exe -d %DISTRO% -- bash "%ATTACH_SCRIPT:\=/%" "%SESSION%"
