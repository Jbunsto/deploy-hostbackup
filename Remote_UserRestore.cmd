setlocal enabledelayedexpansion enableextensions

REM Check to see IF computer is online or offline
COLOR
@ECHO ###################################################
@ECHO %COMPUTER% - Pinging...
ping -n 1 -l 1 %COMPUTER% | find "Reply" > nul 2>&1
IF %ERRORLEVEL% == 1 GOTO :OFFLINE
IF %ERRORLEVEL% == 0 GOTO :CONTINUE

REM  RoboCopy only IF system is online.
:CONTINUE

	
COLOR E
		
REM Copy Robocopy.exe to the local system.
REM XCOPY /y robocopy.exe \\%COMPUTER%\c$\windows\system32\

IF EXIST "\\%COMPUTER%\c$\Users\" ECHO %COMPUTER% - Target is intact... 
IF EXIST "\\%COMPUTER%\c$\Users\" GOTO :RESTOREWIN
GOTO :END

:RESTOREWIN
ECHO %COMPUTER% - Target Computer is a Windows system...prepping to restore
FOR /f %%U in ('dir /b /A:D \\%COMPUTER%\C$\Users') do (

	REM setting a flag to see IF the user account is a valid account.
	Set Flag=good
		
	REM Check the current user account with all accounts in the ignore list
	FOR /f %%I in (path_users_ignore.txt) do (

		REM IF current account is in the ignore list, set flag to ignore (bad).
		IF %%U == %%I (
			Set Flag=bad
		)
		
		REM Take the first three characters of the current account and check IF it is an elevated account.
		set str=%%U				
		set str=!str:~0,3%!
		
		REM Check first three string IF "itd" then ignore (assume elevated account)
		IF "!str!"=="itd" (
			Set Flag=bad								
		)
			
		REM Check first three string IF "ppf" then ignore (assume elevated account)
		IF "!str!"=="ppf" (
			Set Flag=bad								
		)

		REM Check first three string IF "ppf" then ignore (assume elevated account)
		IF "!str!"=="adm" (
			Set Flag=bad								
		)

		REM Check first three string IF "ppf" then ignore (assume elevated account)
		IF "!str!"=="tec" (
			Set Flag=bad								
		)

		REM Check first three string IF "ppf" then ignore (assume elevated account)
		IF "!str!"=="def" (
			Set Flag=bad								
		)	)			
		
	REM IF flag is good, then it is a valid user account, continue with restore.
	IF !Flag!==good (
	
		REM Check list of computers in the data folder to see IF the user acount exists, IF it does copy the data to target system.
		FOR /f %%C in ('dir /b /A:D %BACKUPDRIVELETTER%:\%BACKUPROOT%\') do (
								
			REM Setting the path on the source (Data folder) to check.
			IF EXIST %BACKUPDRIVELETTER%:\%BACKUPROOT%\%%C\USMT\File\C$\Users\ Set CHECK_PATH=%BACKUPDRIVELETTER%:\%BACKUPROOT%\%%C\USMT\File\C$\Users\%%U
			IF EXIST %BACKUPDRIVELETTER%:\%BACKUPROOT%\%%C\USMT\File\C$\Users\ Set CHECK_PATH=%BACKUPDRIVELETTER%:\%BACKUPROOT%\%%C\USMT\File\C$\Users\%%U
			
			REM IF the Target Profile is found in the lists of computers in our DATA recovery folder proceed with Robocopy from Data Recovery to target computer
			IF EXIST %CHECK_PATH% (
		
				set destination=\\%COMPUTER%\C$\Users\%%U
				REM echo.Destination:  %destination%
				
				REM RoboCopy only folders specIFied in the path_users_folders.txt file.
				FOR /f %%F in (path_users_folders.txt) do (					
				
					REM Robocopy only IF the folder exists.
					IF EXIST %CHECK_PATH%\%%F (
						REM  /FFT : Assume FAT File Times (2-second date/time granularity).  So what this does is FORce Robocopy to use FAT style time stamps which are 2-second granularity.  It allows enough flexibility to account FOR the way the time is recorded when doing a file copy from NTFS to another file system. 						
						robocopy "%CHECK_PATH%\%%F" "%destination%\%%F" /s /XO /FFT /R:1 /W:2													
					)
					
				)								
				
				set CHECK_PATH2=%CHECK_PATH%\Documents
				
				REM Robocopy only IF the folder exists.
				IF EXIST %CHECK_PATH2% (						
					REM Robocopy Documents folder.
					robocopy "%CHECK_PATH2%" "%destination%\Documents" /s /XO /FFT /R:1 /W:2						
				)
			)

		)			
	)			
)
	
GOTO :END

:OFFLINE

COLOR C
@ECHO %COMPUTER% - Pinging...offline!
@ECHO %COMPUTER%>> .\UM_LOG_offline_computers.txt

REM Pause only IF you would like to see which computer is offline and thus which computers RoboCopy failed on.
REM pause

:END