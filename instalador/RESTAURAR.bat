@echo off
setlocal
title Restaurar The Turing Test
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Aplicar.ps1" -Acao restaurar
set "resultado=%errorlevel%"
echo.
pause
exit /b %resultado%
