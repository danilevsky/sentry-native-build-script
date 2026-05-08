@echo off
set WORKING_DIRECTORY=%cd%

echo WORKING_DIRECTORY:%WORKING_DIRECTORY%

set VC_DIRECTORY=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\
set CMAKE_VC_VERSION="Visual Studio 17 2022"

set BUILD_LIB_TYPES=Shared Static
set BUILD_CRT_TYPES=CRT_Static CRT_Shared
set PLATFORMS=x86 x64
set BUILD_TYPES=Release Debug

rem set PLATFORMS=x86
rem set BUILD_TYPES=Debug

for %%L in (%BUILD_LIB_TYPES%) do (
	for %%M in (%BUILD_CRT_TYPES%) do (
		for %%P in (%PLATFORMS%) do (
			for %%T in (%BUILD_TYPES%) do (
				echo.
				echo ============================================================
				echo  Building %%L / %%M / %%P / %%T
				echo ============================================================
				call :build %%L %%M %%P %%T
			)
		)
	)
)

echo.
echo All builds finished.
goto :eof


rem ---------------------------------------------------------------
rem  :build <arch> <build_type>
rem ---------------------------------------------------------------
:build
setlocal

rem Shared Static
set BUILD_LIB_TYPE=%~1

rem CRT_Static CRT_Shared
set BUILD_CRT_TYPE=%~2

rem x86 x64
set BUILD_ARCH=%~3

rem Release Debug
set BUILD_TYPE=%~4

rem select vcvars script per architecture
if /I "%BUILD_ARCH%"=="x86" (
    set ENV_BAT=vcvars32.bat
	set CMAKE_VC_ARCH=Win32
) else if /I "%BUILD_ARCH%"=="x64" (
    set ENV_BAT=vcvars64.bat
	set CMAKE_VC_ARCH=x64
) else (
    echo Unknown architecture: %BUILD_ARCH%
    endlocal & exit /b 1
)

if /I "%BUILD_LIB_TYPE%"=="Shared" (
	set SENTRY_BUILD_SHARED_LIBS=ON
) else if /I "%BUILD_LIB_TYPE%"=="Static" (
	set SENTRY_BUILD_SHARED_LIBS=OFF
) else (
	echo Unknown lib type: %BUILD_LIB_TYPE%
    endlocal & exit /b 1
)

if /I "%BUILD_CRT_TYPE%"=="CRT_Static" (
	set SENTRY_BUILD_RUNTIMESTATIC=ON
) else if /I "%BUILD_CRT_TYPE%"=="CRT_Shared" (
	set SENTRY_BUILD_RUNTIMESTATIC=OFF
) else (
	echo Unknown crt type: %BUILD_CRT_TYPE%
    endlocal & exit /b 1
)

rem map BUILD_TYPE to a CMake config name
if /I "%BUILD_TYPE%"=="Release" (
    set CMAKE_CONFIG=RelWithDebInfo
) else if /I "%BUILD_TYPE%"=="Debug" (
    set CMAKE_CONFIG=Debug
) else (
    echo Unknown build type: %BUILD_TYPE%
    endlocal & exit /b 1
)

set BUILD_CONFIG=build-%BUILD_LIB_TYPE%-%BUILD_CRT_TYPE%-%BUILD_ARCH%-%BUILD_TYPE%
set INSTALL_DIRECTORY=%WORKING_DIRECTORY%/output/%BUILD_LIB_TYPE%-%BUILD_CRT_TYPE%/%BUILD_ARCH%/%BUILD_TYPE%


echo BUILD_ARCH: %BUILD_ARCH%
echo BUILD_TYPE: %BUILD_TYPE%
echo ENV_BAT:%ENV_BAT%
echo CMAKE_VC_ARCH:%CMAKE_VC_ARCH%
echo SENTRY_BUILD_SHARED_LIBS:%SENTRY_BUILD_SHARED_LIBS%

echo BUILD_ARCH:        %BUILD_ARCH%
echo BUILD_TYPE:        %BUILD_TYPE%
echo CMAKE_CONFIG:      %CMAKE_CONFIG%
echo BUILD_CONFIG:      %BUILD_CONFIG%
echo INSTALL_DIRECTORY: %INSTALL_DIRECTORY%

cd /d "%WORKING_DIRECTORY%"
cd sentry-native

rem set VS environment (scoped to this setlocal block)
call "%VC_DIRECTORY%\%ENV_BAT%"
if errorlevel 1 (
    echo Failed to set up VS environment for %BUILD_ARCH%
    endlocal & exit /b 1
)

rem configure the project
cmake -G %CMAKE_VC_VERSION% -A %CMAKE_VC_ARCH% -B %BUILD_CONFIG% -DSENTRY_BUILD_RUNTIMESTATIC=%SENTRY_BUILD_RUNTIMESTATIC% -DSENTRY_BUILD_SHARED_LIBS=%SENTRY_BUILD_SHARED_LIBS% -DSENTRY_BACKEND=crashpad -DSENTRY_TRANSPORT=winhttp -DCMAKE_BUILD_TYPE=%CMAKE_CONFIG% -DSENTRY_BUILD_TESTS=OFF -DSENTRY_BUILD_EXAMPLES=OFF
if errorlevel 1 (
    echo CMake configure failed for %BUILD_ARCH% / %BUILD_TYPE%
    endlocal & exit /b 1
)

rem build the project
cmake --build %BUILD_CONFIG% --config %CMAKE_CONFIG% --parallel
if errorlevel 1 (
    echo Build failed for %BUILD_ARCH% / %BUILD_TYPE%
    endlocal & exit /b 1
)

rem install
cmake --install %BUILD_CONFIG% --config %CMAKE_CONFIG% --prefix "%INSTALL_DIRECTORY%"
if errorlevel 1 (
    echo Install failed for %BUILD_ARCH% / %BUILD_TYPE%
    endlocal & exit /b 1
)

endlocal
goto :eof