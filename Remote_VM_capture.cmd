setlocal enabledelayedexpansion enableextensions

	IF NOT EXIST %BACKUPDRIVELETTER%:\%SCRIPTSPATH% NET USE %BACKUPDRIVELETTER%: /delete
	IF NOT EXIST %BACKUPDRIVELETTER%:\%SCRIPTSPATH% NET USE %BACKUPDRIVELETTER%: \\%BACKUPSERVER%\%BACKUPSHARE% /persistent:no

REM Check to see if computer is online or offline
COLOR
@ECHO ###################################################
@ECHO %COMPUTER% - Pinging...
ping -n 1 -l 1 %COMPUTER% | find "Reply" > nul 2>&1
IF %ERRORLEVEL% == 1 GOTO OFFLINE
IF %ERRORLEVEL% == 0 GOTO CONTINUE

REM  RoboCopy only if system is online.
:CONTINUE

	
COLOR B
		
:: This loop will check all the user accounts in "\USMT\File\C$\Users" for the current computer.
for /f %%U in ('dir /b /A:D %BACKUPDRIVELETTER%:\%BACKUPROOT%\%COMPUTER%\USMT\File\C$\Users') do (

	REM setting a flag to see if the user account is a valid account.
	Set Flag=good
		
	REM Check the current user account with all accounts in the ignore list
	for /f %%I in (path_users_ignore.txt) do (

		REM If current account is in the ignore list, set flag to ignore (bad).
		IF %%U == %%I (
			Set Flag=bad
		)
		
		REM Take the first three characters of the current account and check if it is an elevated account.
		set str=%%U				
		set str=!str:~0,3%!
		
		REM Check first three string if "itd" then ignore (assume elevated account)
		IF "!str!"=="itd" (
			Set Flag=bad								
		)
			
		REM Check first three string if "ppf" then ignore (assume elevated account)
		IF "!str!"=="ppf" (
			Set Flag=bad								
		)
	)			
		
	REM if flag is good, then it is a valid user account, continue with RoboCopy.
	if !Flag!==good (
	
		Rem setting the destination and source for RoboCopy.
		set destination=%BACKUPDRIVELETTER%:\%BACKUPROOT%\%COMPUTER%\USMT\File\C$\Users\%%U
		REM echo.Destination:  !destination!
				
		set source=\\%COMPUTER%\C$\Users\%%U
		REM echo.Source:  !source!
				
		REM RoboCopy only folders specified in the path_users_folders.txt file.
		For /f %%F in (path_users_folders.txt) do (					
					
			REM  /FFT : Assume FAT File Times (2-second date/time granularity).  So what this does is force Robocopy to use FAT style time stamps which are 2-second granularity.  It allows enough flexibility to account for the way the time is recorded when doing a file copy from NTFS to another file system. 
			robocopy "!source!\%%F" "!destination!\%%F" /s /XO /FFT /R:1 /W:2													
		)				
				
		REM Robocopy Documents folder.
		robocopy "!source!\Documents" "!destination!\Documents" /s /XO /FFT /R:1 /W:2								
	)			
)
	
GOTO END

:OFFLINE

COLOR C
@ECHO %COMPUTER% - Pinging...offline!

REM Pause only if you would like to see which computer is offline and thus which computers RoboCopy failed on.
REM pause

:END
