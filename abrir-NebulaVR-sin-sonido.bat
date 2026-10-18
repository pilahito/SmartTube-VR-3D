@echo off
setlocal
cd /d "%~dp0"
start "NebulaVR - sin sonido" "G:\Godot\Godot_v4.7.2-stable_win64.exe" --path . --audio-driver Dummy --xr-mode off
rem Teclas: 1 cine, 2 mundo, 3 inicio, espacio pausa, flechas seek, F curva/plana.
