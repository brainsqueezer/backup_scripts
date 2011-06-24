AutoMySQLBackup Script Features:

Backup mutiple MySQL databases with one script. (Now able to backup ALL databases on a server easily. no longer need to specify each database seperately)
Backup all databases to a single backup file or to a seperate directory and file for each database.
Automatically compress the backup files to save disk space using either gzip or bzip2 compression.
Can backup remote MySQL servers to a central server.
Runs automatically using cron or can be run manually.
Can e-mail the backup log to any specified e-mail address instead of “root”. (Great for hosted websites and databases).
Can email the compressed database backup files to the specified email address.
Can specify maximun size backup to email.
Can be set to run PRE and POST backup commands.
Choose which day of the week to run weekly backups.
 

-------------------------------------
Create folder for backup:

mkdir -p /srv/backup/db
 

Place the script on the server in your /usr/local/sbin/ folder and make symlink to the script:

ln -s automysqlbackup-2.5.1-01.sh amb.sh
 
-------------------------------------
Edit the script with your settings:

nano  automysqlbackup-2.5.1-01.sh
 

Settings:

# Username to access the MySQL server e.g. dbuser
USERNAME=dbuser

# Password to access the MySQL server e.g. password
PASSWORD=dbpassword

# Host name (or IP address) of MySQL server e.g localhost
DBHOST=localhost

# List of DBNAMES for Daily/Weekly Backup e.g. "DB1 DB2 DB3"
DBNAMES="all"

# Backup directory location e.g /backups
BACKUPDIR="/srv/backup/db"

# Mail setup
# What would you like to be mailed to you?
# - log   : send only log file
# - files : send log file and sql files as attachments (see docs)
# - stdout : will simply output the log to the screen if run manually.
# - quiet : Only send logs if an error occurs to the MAILADDR.
MAILCONTENT="quiet"

# Set the maximum allowed email size in k. (4000 = approx 5MB email [see docs])
MAXATTSIZE="4000"

# Email Address to send mail to? (user@domain.com)
MAILADDR="your@mail.com"
 

-------------------------------------







Add the backup job to your crontab:

crontab -e
 

-------------------------------------


This example makes a backup every night at 3.15pm:

PATH=/bin/:/sbin/:/usr/bin/:/usr/sbin/:/usr/local/sbin/:/usr/local/bin
# m h  dom mon dow   command
20  15   * * *   root    /usr/local/sbin/amb.sh > /dev/null 2>$1