SET DEBUG=NO

IF %DEBUG% EQU YES @ECHO ON
IF %DEBUG% EQU NO @ECHO OFF
COLOR E
SETLOCAL ENABLEDELAYEDEXPANSION
CLS
SET /p ADMINUSER=please type in your elevated rights account ID:
SET /P ADMINPASS=please type in your elevated account password:
CLS
ECHO.
ECHO ..........  User Backup and File Restoration Tool   .............
ECHO.
ECHO Please select your task, or 4 to EXIT.
ECHO. 
ECHO ...............................................
ECHO.
ECHO.  1 - Migrate user data for the first time.
ECHO.
ECHO.  2 - Synchronize changes since last backup.
ECHO.
ECHO.  3 - Restore user data.
ECHO.
ECHO.  4 - Exit Script.
ECHO.
ECHO.
ECHO ...............................................
ECHO.
ECHO.
COLOR

SET BACKUPDRIVELETTER=Y
SET BACKUPSERVER=172.19.116.248
SET BACKUPSHARE=migrate$
SET BACKUPROOT=data
SET BACKUPLOGS=logs
SET BACKUPSTATUS=logs
SET ALLSCRIPTSROOT=Scripts
SET SCRIPTROOT=Backup_UserProfiles
SET LOCALSCRIPTPATH=setup\usmt

	IF NOT EXIST %BACKUPDRIVELETTER%:\%ALLSCRIPTSROOT% NET USE %BACKUPDRIVELETTER%: /delete
	IF NOT EXIST %BACKUPDRIVELETTER%:\%ALLSCRIPTSROOT% NET USE %BACKUPDRIVELETTER%: \\%BACKUPSERVER%\%BACKUPSHARE% /user:css001\backupuser Bkup$1 /persistent:no

SET /P M=Type 1, 2, 3, or 4, then press ENTER: 
IF %M%==1 GOTO MIGRATE
IF %M%==2 GOTO ROBOCOPY
IF %M%==3 GOTO RESTORE
IF %M%==4 GOTO END

:MIGRATE

	CLS
	IF NOT EXIST hosts_backup.txt ECHO #### No input list - please create hosts_backup.txt.
	IF NOT EXIST hosts_backup.txt TIMEOUT 5 && GOTO END 
	IF EXIST hosts_backup_next.txt REN hosts_backup.txt "hosts_backup_%date:~6,4%.%date:~3,2%.%date:~0,2%_%time:~0,2%.%time:~3,2%.%time:~6,2%.txt"
	IF EXIST hosts_backup_next.txt MOVE hosts_backup_next.txt hosts_backup.txt
	IF EXIST hosts_backup_log.csv REN hosts_backup_log.csv "hosts_backup_log_%date:~6,4%.%date:~3,2%.%date:~0,2%_%time:~0,2%.%time:~3,2%.%time:~6,2%.csv"
	IF NOT EXIST hosts_backup_log.csv ECHO sep=, >> hosts_backup_log.csv
		
	FOR /F %%A IN (hosts_backup.txt) do (
		SET COMPUTER=%%A
		CALL Remote_UserBackup.cmd
	
	)
	TIMEOUT 30
	GOTO :MIGRATE

:ROBOCOPY

	CLS
	IF NOT EXIST %BACKUPDRIVELETTER%:\%ALLSCRIPTSROOT% NET USE %BACKUPDRIVELETTER%: /delete
	IF NOT EXIST %BACKUPDRIVELETTER%:\%ALLSCRIPTSROOT% NET USE %BACKUPDRIVELETTER%: \\%BACKUPSERVER%\%BACKUPSHARE% /persistent:no
	:: This loop will check all the computers names in the migrated data folder.

	FOR /F %%C in ('dir /b /A:D %BACKUPDRIVELETTER%:\%BACKUPROOT%') do (
	
		SET COMPUTER=%%C
		CALL Remote_UserSync.cmd

	)
	
	GOTO :END

:RESTORE

	CLS
	IF NOT EXIST %BACKUPDRIVELETTER%:\%ALLSCRIPTSROOT% NET USE %BACKUPDRIVELETTER%: /delete
	IF NOT EXIST %BACKUPDRIVELETTER%:\%ALLSCRIPTSROOT% NET USE %BACKUPDRIVELETTER%: \\%BACKUPSERVER%\%BACKUPSHARE% /persistent:no
	
	REM Delete the log file before checking to see if the function needs to be called.
	IF EXIST .\UM_LOG_offline_computers.txt del /f/q .\UM_LOG_offline_computers.txt
	
	REM Check to see if there are any more computers to restore, if there are no more computers to check then we are done, exit program.
	IF NOT EXIST hosts_restore.txt GOTO END

	REM Check all the computers in the text file.
	FOR /F %%i IN (hosts_restore.txt) do (

		SET COMPUTER=%%i
		CALL Remote_UserRestore.cmd
		
	)
	
	REM If there are no more computers to check then we are done, exit program.
	IF NOT EXIST .\UM_LOG_offline_computers.txt GOTO END

	REM Moving offline computers to computers that need to be checked.
	MOVE .\UM_LOG_offline_computers.txt .\hosts_restore.txt
	GOTO :RESTORE

:CAPTURE

	CLS
	FOR /F %%A IN (hosts_capture.txt) do (

		SET COMPUTER=%%A
		CALL Remote_SystemVHDcapture.cmd
	
	)
	
	GOTO :END

:END	
TIMEOUT 30