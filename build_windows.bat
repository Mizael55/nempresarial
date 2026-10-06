@echo off
REM ==============================================================================
REM Script de Compilación y Generación del Instalador de Windows para Nubiko
REM ==============================================================================

echo [1/3] Obteniendo dependencias de Flutter...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo Error al obtener dependencias.
    pause
    exit /b %ERRORLEVEL%
)

echo [2/3] Compilando la aplicacion para Windows en modo Release...
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo Error durante la compilacion de Windows. Asegurate de tener Visual Studio C++ instalado.
    pause
    exit /b %ERRORLEVEL%
)

echo [3/3] Buscando Inno Setup Compiler (ISCC.exe)...
set ISCC="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if not exist %ISCC% set ISCC="C:\Program Files\Inno Setup 6\ISCC.exe"

if exist %ISCC% (
    echo Empaquetando instalador con Inno Setup...
    %ISCC% windows\installer\nempresarial_setup.iss
    echo.
    echo ==============================================================================
    echo Instalador generado exitosamente en: dist\Nubiko_Empresarial_Setup_Windows.exe
    echo ==============================================================================
) else (
    echo.
    echo [AVISO] Inno Setup no esta instalado en las rutas por defecto.
    echo Los archivos ejecutables se encuentran listos en:
    echo build\windows\x64\runner\Release\
    echo Para generar el instalador .exe unico, descarga Inno Setup gratis desde:
    echo https://jrsoftware.org/isdl.php
)

pause
