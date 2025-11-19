@echo off
setlocal enabledelayedexpansion

set ENV_FILE=.env
set DEFINES_FILE=defines.json

if not exist "%ENV_FILE%" (
    echo .env file not found!
    exit /b 1
)

echo { > "%DEFINES_FILE%"

set FIRST=true

for /f "usebackq tokens=1* delims==" %%a in ("%ENV_FILE%") do (
    set KEY=%%a
    set VAL=%%b

    rem
    if "!KEY!"=="" (
        continue
    )

    rem
    if "!KEY:~0,1!"=="#" (
        continue
    )

    rem
    if "!FIRST!"=="true" (
        echo   "!KEY!": "!VAL!" >> "%DEFINES_FILE%"
        set FIRST=false
    ) else (
        echo ,  "!KEY!": "!VAL!" >> "%DEFINES_FILE%"
    )
)

echo } >> "%DEFINES_FILE%"

echo Generated %DEFINES_FILE%
echo Running Flutter...

flutter run --dart-define-from-file=%DEFINES_FILE%
