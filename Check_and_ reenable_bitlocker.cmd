ECHO OFF
CD /D %CD%

FOR /F %%A IN (notebooks.txt) do (
SET COMPUTER=%%A
COLOR
ECHO ###################################################
ping -n 1 -l 1 %%A | find "Reply" > nul 2>&1
IF %ERRORLEVEL% == 1 CALL :OFFLINE
IF %ERRORLEVEL% == 0 CALL :CONTINUE
	)

PAUSE
EXIT

:CONTINUE
COLOR A
IF NOT EXIST \\%COMPUTER%\c$ ECHO %COMPUTER% - No access && EXIT /B
manage-bde -cn %COMPUTER% -status | find /i "Conversion Status" | find /i "Fully Encrypted"
IF %ERRORLEVEL% == 1 EXIT /B
manage-bde -cn %COMPUTER% -status | find /i "Protection Status" | find /i "Protection Off"
IF %ERRORLEVEL% == 1 ECHO %COMPUTER% - Bitlocker is enabled
IF %ERRORLEVEL% == 0 ECHO %COMPUTER% - Bitlocker is OFF...reenabling
IF %ERRORLEVEL% == 0 manage-bde -cn %COMPUTER% c: -on
EXIT /B

:OFFLINE
COLOR C
ECHO %COMPUTER% - offline!
EXIT /B
