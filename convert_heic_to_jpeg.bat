REM ================================================================
REM HEIC to JPEG Converter
REM ================================================================
REM 
REM This script converts all HEIC files in a specified directory to JPEG format
REM using ImageMagick. Requires ImageMagick to be installed and in system PATH.
REM 
REM USAGE:
REM   convert_heic_to_jpeg.bat [folder_path] [delete]
REM   
REM   folder_path - Target directory (optional, defaults to current folder)
REM   delete      - Pass "delete" to remove original HEIC files after conversion
REM 
REM EXAMPLES:
REM   convert_heic_to_jpeg.bat                              - Convert files in current folder
REM   convert_heic_to_jpeg.bat delete                       - Convert and delete originals in current folder
REM   convert_heic_to_jpeg.bat "C:\Users\Name\Pictures"     - Convert files in specified folder
REM   convert_heic_to_jpeg.bat "C:\Users\Name\Pictures" delete - Convert and delete originals in specified folder
REM   convert_heic_to_jpeg.bat ".\Photos" delete            - Convert and delete originals in subfolder
REM 
REM REQUIREMENTS:
REM   - ImageMagick must be installed with HEIC support
REM   - Download from: https://imagemagick.org/script/download.php#windows
REM 
REM OUTPUT:
REM   - Creates JPEG files with same names as original HEIC files
REM   - Original HEIC files are preserved (not deleted)
REM   - JPEG quality is set to 90%
REM 
REM Generated with Claude AI on August 26, 2025
REM ================================================================

@echo off
setlocal enabledelayedexpansion

echo HEIC to JPEG Converter
echo ======================

REM Check if target folder is provided as argument and handle delete option
set "DELETE_ORIGINALS=false"

REM Parse arguments
if "%~1"=="delete" (
    set "TARGET_FOLDER=%cd%"
    set "DELETE_ORIGINALS=true"
    echo Using current directory: %TARGET_FOLDER%
    echo Delete mode: Original HEIC files will be deleted after successful conversion
) else if "%~2"=="delete" (
    set "TARGET_FOLDER=%~1"
    set "DELETE_ORIGINALS=true"
    echo Using specified directory: %TARGET_FOLDER%
    echo Delete mode: Original HEIC files will be deleted after successful conversion
) else if "%~1"=="" (
    set "TARGET_FOLDER=%cd%"
    echo Using current directory: %TARGET_FOLDER%
    echo Preserve mode: Original HEIC files will be kept
) else (
    set "TARGET_FOLDER=%~1"
    echo Using specified directory: %TARGET_FOLDER%
    echo Preserve mode: Original HEIC files will be kept
)

REM Check if the specified folder exists (only if not current directory)
if not "%~1"=="" if not "%~1"=="delete" (
    if not exist "!TARGET_FOLDER!" (
        echo ERROR: Directory "!TARGET_FOLDER!" does not exist
        pause
        exit /b 1
    )
    
    REM Change to the target directory
    pushd "!TARGET_FOLDER!"
    if errorlevel 1 (
        echo ERROR: Cannot access directory "!TARGET_FOLDER!"
        pause
        exit /b 1
    )
)

echo.

REM Check if ImageMagick is installed and accessible
magick -version >nul 2>&1
if errorlevel 1 (
    echo ERROR: ImageMagick not found or not in PATH
    echo Please install ImageMagick and ensure it's in your system PATH
    echo Download from: https://imagemagick.org/script/download.php#windows
    pause
    exit /b 1
)

REM Test HEIC support
echo Testing HEIC support...
magick -list format | findstr -i heic >nul 2>&1
if errorlevel 1 (
    echo WARNING: HEIC format may not be supported by your ImageMagick installation
    echo This could cause conversion errors
    echo.
)

REM Count HEIC files in target directory
set count=0
for %%f in (*.heic *.HEIC) do (
    set /a count+=1
)

if %count%==0 (
    echo No HEIC files found in target directory
    if not "%~1"=="" if not "%~1"=="delete" popd
    pause
    exit /b 0
)

echo Found %count% HEIC file(s) to convert
echo.

REM Convert each HEIC file to JPEG
set converted=0
set failed=0

for %%f in (*.heic *.HEIC) do (
    echo Converting: %%f
    set "filename=%%~nf"
    
    REM Try different conversion approaches
    REM First try: Direct conversion
    magick "%%f" -quality 90 "!filename!.jpg"
    
    REM If that fails, try with explicit format specification
    if !errorlevel! neq 0 (
        echo   Retrying with format specification...
        magick heic:"%%f" -quality 90 "!filename!.jpg"
    )
    
    REM If still failing, try with different options
    if !errorlevel! neq 0 (
        echo   Retrying with alternative options...
        magick "%%f" -auto-orient -quality 90 "!filename!.jpg"
    )
    
    if !errorlevel!==0 (
        echo   SUCCESS: Created !filename!.jpg
        set /a converted+=1
        
        REM Delete original file if delete mode is enabled
        if "!DELETE_ORIGINALS!"=="true" (
            del "%%f"
            if !errorlevel!==0 (
                echo   DELETED: Removed original file %%f
            ) else (
                echo   WARNING: Could not delete original file %%f
            )
        )
    ) else (
        echo   ERROR: Failed to convert %%f
        set /a failed+=1
    )
    echo.
)

echo Conversion complete!
echo Files converted successfully: %converted%
if %failed% gtr 0 (
    echo Files that failed: %failed%
)

REM Return to original directory if we changed it
if not "%~1"=="" if not "%~1"=="delete" popd

pause