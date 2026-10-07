@echo off
title XS Prospeccao - Clone Local
echo ========================================================
echo         INICIANDO XS PROSPECCAO - CLONE COMPLETO
echo ========================================================
echo.
echo Iniciando servidor local na porta 3000...
echo O sistema abrira automaticamente no seu navegador.
echo Para fechar o sistema, basta fechar esta janela.
echo.
powershell.exe -ExecutionPolicy Bypass -File "%~dp0server.ps1" -Port 3000
pause
