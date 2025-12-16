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
    set "KEY=%%a"
    set "VAL=%%b"

    rem skip empty keys
    if not "!KEY!"=="" (
        rem skip comments (lines starting with #)
        if not "!KEY:~0,1!"=="#" (
            rem write comma when not the first entry
            if "!FIRST!"=="true" (
                >> "%DEFINES_FILE%" echo   "!KEY!": "!VAL!"
                set "FIRST=false"
            ) else (
                >> "%DEFINES_FILE%" echo ,  "!KEY!": "!VAL!"
            )
        )
    )
)

echo } >> "%DEFINES_FILE%"

echo Created %DEFINES_FILE% from %ENV_FILE%

if not "%SKIP_FLUTTER%"=="1" (
    echo Running Flutter...
    flutter build apk --release --dart-define-from-file="%DEFINES_FILE%"
) else (
    echo SKIP_FLUTTER=1 detected, skipping flutter run.
)
