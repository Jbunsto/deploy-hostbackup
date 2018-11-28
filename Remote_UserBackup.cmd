REM **********   MIGRATE *********
SET LOCALSCRIPTPATH=setup\usmt
SET LOCALSCRIPT=USMT_Capture.cmd
:: Boundary should be set to the number of concurrent backups the network or server can safely handle
:: once remote backups are started you cannot stop them until they are complete, the the process is killed.
SET BOUNDARY=40

ECHO ###################################################
IF EXIST "\\%BACKUPSERVER%\%BACKUPSHARE%\%BACKUPROOT%\%COMPUTER%\USMT\" ECHO %COMPUTER% - Checking to see if a backup has been performed...YES, checking to see if we still need the backup 
CALL :PING
IF %NETSTATUS% == OFFLINE ECHO %COMPUTER% - Checking to see if a backup has been performed...Yes, but target is offline, will check status on next cycle.
IF %NETSTATUS% == OFFLINE GOTO :OFFLINE
CALL :CHECKOSVER
IF %STATUS% == DONE ECHO %COMPUTER% - Already on target OS Version, no longer needs the backup && GOTO MOVEREDUNDANT
IF EXIST "\\%BACKUPSERVER%\%BACKUPSHARE%\%BACKUPROOT%\%COMPUTER%\USMT\" ECHO %COMPUTER%,Backed-up  >> hosts_backup_log.csv
IF EXIST "\\%BACKUPSERVER%\%BACKUPSHARE%\%BACKUPROOT%\%COMPUTER%\USMT\" GOTO :END
IF NOT EXIST "\\%BACKUPSERVER%\%BACKUPSHARE%\%BACKUPROOT%\%COMPUTER%\USMT\" ECHO %COMPUTER% - Checking to see if a backup has been performed...NO, proceeding
GOTO :CONTINUE


:CONTINUE
COLOR A
ECHO %COMPUTER% - Checking to see if we have access with these credentials
IF NOT EXIST \\%COMPUTER%\c$ ECHO %COMPUTER%,NoAccess >> hosts_backup_log.csv
IF NOT EXIST \\%COMPUTER%\c$ ECHO %COMPUTER% - No access
IF NOT EXIST \\%COMPUTER%\c$ ECHO %COMPUTER% >> hosts_backup_next.txt
IF NOT EXIST \\%COMPUTER%\c$ GOTO :END
:: CHECK BUILD
CALL :CHECKOSVER
IF %STATUS% == DONE ECHO %COMPUTER% - Already on target OS Version, does not need backup && GOTO MOVEREDUNDANT
IF %OSVER% == 10586 ECHO %COMPUTER% - Eligible for upgrade, prepping to backup files
CALL :CHECKBOUNDARY
IF %CHECKBOUNDARY% == OVER GOTO :END
ECHO %COMPUTER% - Copying over the files needed...
IF NOT EXIST "\\%COMPUTER%\c$\%LOCALSCRIPTPATH%\" MKDIR "\\%COMPUTER%\c$\%LOCALSCRIPTPATH%\"
XCOPY /y %LOCALSCRIPT% "\\%COMPUTER%\c$\%LOCALSCRIPTPATH%\"
ECHO %COMPUTER% - Initiating the file capture process on the target PC
PSEXEC /d /u ORG\%ADMINUSER% /p %ADMINPASS% \\%COMPUTER% cmd /c C:\%LOCALSCRIPTPATH%\%LOCALSCRIPT%
ECHO %COMPUTER%,InProgress >> hosts_backup_log.csv
GOTO :END


:CHECKOSVER
SET OSVER=00000
wmic /node:%COMPUTER% os get BuildNumber | find /V "BuildNumber" > %TEMP%\buildnumber.log
SET /P OSVER=<%TEMP%\buildnumber.log
DEL /F %TEMP%\buildnumber.log
IF %OSVER% == 17134 ECHO %COMPUTER% - Version 1803 && SET STATUS=DONE
IF %OSVER% == 16299 ECHO %COMPUTER% - Good - Successfully upgraded to 1709 && SET STATUS=DONE
IF %OSVER% == 15063 ECHO %COMPUTER% - Version 1703 && SET STATUS=UPGRADE
IF %OSVER% == 14393 ECHO %COMPUTER% - Version 1607 && SET STATUS=UPGRADE
IF %OSVER% == 10586 ECHO %COMPUTER% - Version 1511 - Ready for upgrade && SET STATUS=UPGRADE
IF %OSVER% == 00000 ECHO %COMPUTER% - Version Unknown - no access or machine malfunction, skipping && SET STATUS=UNKNOWN
:: Log the OS Version
IF %OSVER% == 17134 ECHO %COMPUTER%,Windows 10^(1803^) >> hosts_backup_log.csv
IF %OSVER% == 16299 ECHO %COMPUTER%,Windows 10^(1709^) >> hosts_backup_log.csv
IF %OSVER% == 15063 ECHO %COMPUTER%,Windows 10^(1703^) >> hosts_backup_log.csv
IF %OSVER% == 14393 ECHO %COMPUTER%,Windows 10^(1607^) >> hosts_backup_log.csv
IF %OSVER% == 00000 ECHO %COMPUTER%,Unknown >> hosts_backup_log.csv
EXIT /B

:MOVEREDUNDANT
IF %STATUS% == DONE IF EXIST D:\migrate\data\%COMPUTER%\USMT\ ECHO %COMPUTER% - Moving existing backups
IF %STATUS% == DONE IF EXIST D:\migrate\data\%COMPUTER%\USMT\ MOVE D:\migrate\data\%COMPUTER% D:\migrate\data-done
GOTO :END

:CHECKBOUNDARY
:: this subroutine ensures we don't try to migrate too many machines at once...
:: this will mark backup candidates as skippable until the next cycle
FOR /F %%D IN ('FIND /C "InProgress" ^< hosts_backup_log.csv') DO (
ECHO %COMPUTER% - The number of concurrent backups is %BOUNDARY%
ECHO Count %%D
IF %%D GEQ %BOUNDARY% ECHO %COMPUTER% - The number of concurrent allowable backups is exceeded, skipping until next pass
IF %%D GEQ %BOUNDARY% ECHO %COMPUTER% >> hosts_backup_next.txt 
IF %%D GEQ %BOUNDARY% SET CHECKBOUNDARY=OVER
IF %%D LSS %BOUNDARY% SET CHECKBOUNDARY=UNDER
)
EXIT /B

:PING
COLOR
ECHO %COMPUTER% - Pinging...
SET NETSTATUS=ONLINE
ping -n 1 -l 1 %COMPUTER% | find "Reply" > nul 2>&1
IF %ERRORLEVEL% NEQ 0 SET NETSTATUS=OFFLINE
:: IF %ERRORLEVEL% EQU 0 SET NETSTATUS=ONLINE
ECHO %COMPUTER% - Pinging...%NETSTATUS%
EXIT /B

:OFFLINE
COLOR C
ECHO %COMPUTER%,Offline >> hosts_backup_log.csv
ECHO %COMPUTER% >> hosts_backup_next.txt
GOTO :END

:END
IF %DEBUG% EQU YES PAUSE

