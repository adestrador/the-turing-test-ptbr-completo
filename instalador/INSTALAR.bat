@echo off
setlocal
title The Turing Test - PT-BR Completo
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Aplicar.ps1" -Acao instalar
set "resultado=%errorlevel%"
echo.
pause
exit /b %resultado%
