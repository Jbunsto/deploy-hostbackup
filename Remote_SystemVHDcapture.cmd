REM **********   MIGRATE *********
SET LOCALSCRIPT=VHD_Capture.cmd

COLOR
@ECHO ###################################################
@ECHO %COMPUTER% - Pinging...
ping -n 1 -l 1 %COMPUTER% | find "Reply" > nul 2>&1
IF %ERRORLEVEL% == 1 GOTO :OFFLINE
IF %ERRORLEVEL% == 0 GOTO :CONTINUE

:CONTINUE
COLOR A
@ECHO %COMPUTER% - Pinging...online!
for /f "tokens=3" %%A in ('ping -n 1 -l 1 %COMPUTER% ^| find /i "reply"') do (set X=%%A)
@ECHO %COMPUTER% - Checking to see if a capture has been performed...
IF EXIST "\\%BACKUPSERVER%\%BACKUPSHARE%\%BACKUPROOT%\%COMPUTER%\%COMPUTER%.vhd" ECHO %COMPUTER% - Checking to see if a capture has been performed...YES, skipping 
IF EXIST "\\%BACKUPSERVER%\%BACKUPSHARE%\%BACKUPROOT%\%COMPUTER%\%COMPUTER%.vhd" GOTO :END
IF NOT EXIST "\\%BACKUPSERVER%\%BACKUPSHARE%\%BACKUPROOT%\%COMPUTER%\%COMPUTER%.vhd" ECHO %COMPUTER% - Checking to see if a capture has been performed...NO, proceeding
@ECHO %COMPUTER% - Copying over the files needed...
IF NOT EXIST "\\%COMPUTER%\c$\%LOCALSCRIPTPATH%\" MKDIR "\\%COMPUTER%\c$\%LOCALSCRIPTPATH%\"
XCOPY /y %LOCALSCRIPT% "\\%COMPUTER%\c$\%LOCALSCRIPTPATH%\"
@ECHO %COMPUTER% - Initiating the file capture process on the target PC
PSEXEC /d /u ORG\%ADMINUSER% /p %ADMINPASS% \\%COMPUTER% cmd /c C:\%LOCALSCRIPTPATH%\%LOCALSCRIPT%
GOTO :END

:OFFLINE
COLOR C
@ECHO %COMPUTER% - Pinging...offline!

:END