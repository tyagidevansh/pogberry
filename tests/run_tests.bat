@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "TEST_ROOT=%~dp0"
for %%I in ("%TEST_ROOT%..") do set "ROOT_DIR=%%~fI"

set "PGBIN=%ROOT_DIR%\build\pogberry.exe"
set "TEST_DIR=%TEST_ROOT:~0,-1%"

if not "%~1"=="" set "TEST_DIR=%TEST_DIR%\%~1"

if not exist "%PGBIN%" (
    echo Test binary not found: "%PGBIN%"
    exit /b 2
)

if not exist "%TEST_DIR%" (
    echo Test directory not found: "%TEST_DIR%"
    exit /b 2
)

set "ACTUAL=%TEMP%\pogberry-test-%RANDOM%-%RANDOM%.out"
set /a PASS=0
set /a FAIL=0

for /R "%TEST_DIR%" %%F in (*.pb) do call :run_test "%%~fF"

if exist "%ACTUAL%" del "%ACTUAL%"

echo.
echo Passed: %PASS%, Failed: %FAIL%

if %FAIL% neq 0 exit /b 1
exit /b 0

:run_test
set "SOURCE=%~1"
set "EXPECTED=%~dpn1.out"
set "STATUS_FILE=%~dpn1.status"
set "EXPECTED_STATUS=0"

if exist "%STATUS_FILE%" set /p EXPECTED_STATUS=<"%STATUS_FILE%"

if not exist "%EXPECTED%" (
    echo [FAIL] %SOURCE%
    echo   Missing expected-output file: %EXPECTED%
    set /a FAIL+=1
    goto :eof
)

"%PGBIN%" "%SOURCE%" > "%ACTUAL%" 2>&1
set "ACTUAL_STATUS=!ERRORLEVEL!"

fc /b "%ACTUAL%" "%EXPECTED%" >nul
set "OUTPUT_MATCH=!ERRORLEVEL!"

if "!OUTPUT_MATCH!"=="0" if "!ACTUAL_STATUS!"=="!EXPECTED_STATUS!" (
    echo [PASS] %SOURCE%
    set /a PASS+=1
    goto :eof
)

echo [FAIL] %SOURCE%
echo   Expected exit code: !EXPECTED_STATUS!
echo   Actual exit code:   !ACTUAL_STATUS!
echo   Expected output:
type "%EXPECTED%"
echo   Actual output:
type "%ACTUAL%"
echo.
set /a FAIL+=1
goto :eof