ECHO OFF
CD /D %CD%
IF EXIST hosts_osver_log.csv DEL /F hosts_osver_log.csv
FOR /F %%A IN (hosts_backup.txt) do (
COLOR
SET COMPUTER=%%A
ECHO ###################################################
ping -n 1 -l 1 %COMPUTER% | find "Reply" > nul 2>&1
IF %ERRORLEVEL% == 1 CALL :OFFLINE
IF %ERRORLEVEL% == 0 CALL :CONTINUE
)

PAUSE
EXIT

:CONTINUE
COLOR A
IF NOT EXIST \\%COMPUTER%\c$ ECHO %COMPUTER% - No access && EXIT /B
for /f %%B in ('wmic /node:%COMPUTER% os get BuildNumber ^| find /V "BuildNumber" ') do ( 
IF %%B==17134 ECHO %COMPUTER% - New - Version 1803
IF %%B==16299 ECHO %COMPUTER% - Good - Successfully upgraded to 1709
IF %%B==15063 ECHO %COMPUTER% - Version 1703 
IF %%B==14393 ECHO %COMPUTER% - Version 1607
IF %%B==10586 ECHO %COMPUTER% - Version 1511

IF %%B==17134 ECHO %COMPUTER%,Windows 10^(1803^) >> hosts_osver_log.csv
IF %%B==17134 ECHO %COMPUTER%,Windows 10^(1803^) >> hosts_osver_log.csv
IF %%B==16299 ECHO %COMPUTER%,Windows 10^(1709^) >> hosts_osver_log.csv
IF %%B==15063 ECHO %COMPUTER%,Windows 10^(1703^) >> hosts_osver_log.csv
IF %%B==14393 ECHO %COMPUTER%,Windows 10^(1607^) >> hosts_osver_log.csv
IF %%B==10586 ECHO %COMPUTER%,Windows 10^(1511^) >> hosts_osver_log.csv
)
EXIT /B

:OFFLINE
COLOR C
ECHO %COMPUTER%,Offline" >> hosts_osver_log.csv
ECHO %COMPUTER% - offline!
EXIT /B
