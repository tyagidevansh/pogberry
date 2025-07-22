@echo off
setlocal enabledelayedexpansion

set PGBIN=..\pogberry
set PASS=0
set FAIL=0

for %%F in (*.pb) do (
    set NAME=%%~nF
    %PGBIN% %%F > actual.tmp 2>&1
    fc actual.tmp !NAME!.out >nul
    if !errorlevel! equ 0 (
        echo [PASS] %%F
        set /a PASS+=1
    ) else (
        echo [FAIL] %%F
        set /a FAIL+=1
    )
)

echo.
echo Passed: %PASS%, Failed: %FAIL%
