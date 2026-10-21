@echo off
setlocal
set "GODOT=G:\Godot\Godot_v4.7.2-stable_win64.exe"
set "XR_RUNTIME_JSON=G:\Dev\tools\MetaXRSimulator\v207.1\meta_openxr_simulator.json"
cd /d "%~dp0"
start "NebulaVR - prueba sin audio" "%GODOT%" --path . --audio-driver Dummy --xr-mode on
