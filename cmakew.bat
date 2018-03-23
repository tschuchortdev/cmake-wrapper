@echo off
setlocal ENABLEEXTENSIONS
setlocal enableDelayedExpansion

@rem set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set "CMAKE_VERSION=3.10.3"

@reg extract semantic version codes
for /f "tokens=1,2,3 delims=." %%a in ("%CMAKE_VERSION%") do set CMAKE_VERSION_MAJOR=%%a&set CMAKE_VERSION_MINOR=%%b&set CMAKE_VERSION_PATCH=%%c

@rem get script directory name
set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.

@rem strip trailing backslash from DIRNAME path to make it easier to work with
IF %DIRNAME:~-1%==\ SET DIRNAME=%DIRNAME:~0,-1%

@rem get OS bitness
echo (ignore reg error, I don't know where it comes from)
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OS_BITNESS=32BIT || set OS_BITNESS=64BIT

set UNZIP_EXE=%DIRNAME%\.cmakew\7zip\7z.exe

@rem require 7zip to unzip the cmake dist because windows sucks
if not exist %UNZIP_EXE% (
    echo Downloading 7zip...

    if %OS_BITNESS%==64BIT (
        call :downloadFile https://www.7-zip.org/a/7z1801-x64.exe %TEMP%\7zInstall.exe
    ) else (
        call :downloadFile https://www.7-zip.org/a/7z1801.exe %TEMP%\7zInstall.exe   
    )

    echo Installing 7zip

    @rem don't forget the trailing backslash here because 7zip is too stupid to deal with paths and just removes the last char
    %TEMP%\7zInstall.exe /S /D=%DIRNAME%\.cmakew\7zip\
    del %TEMP%\7zInstall.exe
)

set CMAKE_DIR=%DIRNAME%\.cmakew\cmake-%CMAKE_VERSION%
set CMAKE_ZIP=%TEMP%\cmake-%CMAKE_VERSION%.zip
set CMAKE_EXE=%CMAKE_DIR%\bin\cmake.exe

@rem require correct cmake version
if not exist %CMAKE_EXE% (
    echo Downloading cmake version %CMAKE_VERSION%...

    if %OS_BITNESS%==64BIT (
        call :downloadFile https://cmake.org/files/v%CMAKE_VERSION_MAJOR%.%CMAKE_VERSION_MINOR%/cmake-%CMAKE_VERSION%-win64-x64.zip %CMAKE_ZIP%
    ) else (
        call :downloadFile https://cmake.org/files/v%CMAKE_VERSION_MAJOR%.%CMAKE_VERSION_MINOR%/cmake-%CMAKE_VERSION%-win32-x86.zip %CMAKE_ZIP%
    )

    echo Installing cmake

    %UNZIP_EXE% x %CMAKE_ZIP% -o%DIRNAME%\.cmakew -y
    del %CMAKE_ZIP%
    
    if %OS_BITNESS%==64BIT (
        ren %DIRNAME%\.cmakew\cmake-%CMAKE_VERSION%-win64-x64 cmake-%CMAKE_VERSION%
    ) else (
        ren %DIRNAME%\.cmakew\cmake-%CMAKE_VERSION%-win32-x86 cmake-%CMAKE_VERSION%
    )
)

@rem parse cli args to pass them to cmWake

if not "%OS%" == "Windows_NT" goto win9xME_args
if "%@eval[2+2]" == "4" goto 4NT_args

:win9xME_args
@rem Slurp the command line arguments.
set CMD_LINE_ARGS=
set _SKIP=2

:win9xME_args_slurp
if "x%~1" == "x" goto runCmake

set CMD_LINE_ARGS=%*
goto runCmake

:4NT_args
@rem Get arguments from the 4NT Shell from JP Software
set CMD_LINE_ARGS=%$

:runCmake
%CMAKE_EXE% %CMD_LINE_ARGS%
goto end


@rem args: fileUrl, filePath
:downloadFile
powershell -Command "(New-Object Net.WebClient).DownloadFile('%~1', '%~2')" 
EXIT /B 0

:end
if "%OS%"=="Windows_NT" endlocal