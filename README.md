# deploy-hostbackup
User and machine backup script powered by USMT.

User Migration Tool User Guide

User Migration Tool:
1)	 Run “BULK_Remote_UserMigration.cmd” to start the migration tool.
 
2)  Select 

    1 to migrate user data
    
    2 to Synchronize changes from last backup
    
    3 to restore user data
    
    4 to exit the script

Options: 
1)	Migrating Users Data
    •	This option will migrate all data from a list host names in the WS.txt (ex. j2xd0050228).
    •	Data will be stored in the \\Server.fqdn\share$\storageroot\ folder.
2)	Synchronizing Changes
    •	This option will synchronize changes since the last migration backup.  It looks in the data folder and grabs all valid accounts (ie, not in the ignore list) and synchronize the specified folders.
    •	Requires ignore.txt and folders.txt before running.
    •	The ignore.txt consists of user accounts to ignore and includes all ppf and itd accounts.
    •	The folders.txt contains the list of folders that will be checked for changes (Currently only:  Desktop, Recent, Favorites, and My Documents).
    •	For testing purpose it is currently checking the accounts in the Data_archived folder and not the Data folder.
3)	Restore User Data
    •	This option will run robocopy and restore data to host names specified in the restore.txt file.
