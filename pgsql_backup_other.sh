#!/bin/sh

# Instructions
# Copy this script into a new file, such as autopgsqlbakup.sh, and chmod the file 755.  Put it into /usr/local/bin.

# Make an entry in /etc/crontab for automatically run this script, in particular time, such as: 
# 00 12 * * *      root      autopgsqlbakup.sh
# (it means, do backup at every 12 hour).

 
# Features:
# - Automatic backup of Postgresql database
# - Daily, weekly, monthly
# - Rotation of backup files

# Credits:
# This program is based on automatic MySQL backup script by Harley
# (wipe_out at users.sourceforge.net). Thanks Harley, your script is really nice.
# So, therefore, this program is also released under the GPL which can be obtain
# from http://www.fsf.org

# A little background:
# This program is emerged from the need to have an automatic backup process for
# postgresql database server. After some extensive searching on Google, I came
# across Harley's script. It's for MySQL though. Well, I'm not a bash scriptter,
# so, after some discussion in few lists and experimenting, I managed to get this
# works.

# Note on postgresql settings:
# By default, postgresql setting is not open, which means we must set the authentication
# method for the client first. It is done in /var/lib/pgsql/data/pg_hba.conf file.
# In order to use this program, we can set the method like this:
# host	all	all	192.168.1.100/32	md5
# where 192.168.1.100 is your backup machine IP.
# There is also one trick in order to be able to do automatic backup.
# Postgresql use it's build-in tools to backup, that is: pg_dump and pg_dumpall.
# Because of it's security measure, we cannot specify the password in the pg_dump option.
# There is a way though, we can create a file called .pgpass in user directory who runs
# this script, with this content:
# dbhost:5432:dbname:username:password, (dbhost is your porstgresql server's IP, so in this program,
# the .pgpass would look like this: 192.168.1.200:5432:dbname:username:password
# Don't forget to chmod the file 600.

# Terjemahan Indonesia:
# Kredit:
# Program ini dibuat berdasarkan script backup MySQL otomatis dari Harley
# (wipe_out at users.sourceforge.net). Terima kasih Harley, script kamu benar2 sip.
# Oleh karena itu, program ini dirilis juga dibawah lisensi GPL yang dapat kita
# peroleh dari http://www.fsf.org

# Sedikit latar belakang:
# Program ini berawal dari kebutuhan akan proses backup otomatis untuk database server
# Postgresql. Setelah mencari2 di Google, ketemulah script Harley itu, namun diperuntukkan
# bagi database MySQL. Yah, saya bukan seorang programming bash script, jadinya setelah
# bertanya2 di milis dan beberapa eksperimen, akhirnya jadi juga program ini.

# Catatan untuk setting postgresql:
# Secara default, settingan postgresql adalah tertutup, dalam arti kita mesti menyetel
# metode otentifikasinya terlebih dahulu sebelum dapat digunakan. Kita menyetelnya di file
# /var/lib/pgsql/data/pg_hba.conf. Untuk menggunakan program ini, kita dapat menyetelnya seperti ini:
# host	all	all	192.168.1.100/32	md5
# Dimana 192.168.1.100 itu adalah IP tempat kita melakukan backup.
# Ada pula satu buah trick agar kita dapat melakukan backup otomatis di postgresql.
# Postgresql menggunakan utility build-innya untuk melakukan backup yaitu pg_dump dan pg_dumpall.
# Karena tingkat securitynya yang tinggi, kita tidak dapat menyebutkan password postgresql di dalam
# option pg_dump. Beruntungnya, postgresql telah menyediakan mekanisme password ini melalui file
# bername .pgpass. Isi dari file ini adalah: dbhost:5432:dbname:username:password (dbhost adalah
# IP dari server postgresql kita. Jadi, sehubungan dengan program ini, file .pgpass ini akan berisi:
# 192.168.1.200:5432:dbname:username:password
# Jangan lupa untuk me-chmod file ini 600.


###############################
# START SCRIPT - MULAI SCRIPT #
###############################

#!/bin/bash
USERNAME=usernamekamu # username for the connection. username utk koneksinya
DBHOST=192.168.1.200 # match your pgsql server IP. sesuaikan dengan IP server pgsql kamu
DBNAMES=namadatabase # the database name. nama databasenya
BACKUPDIR="/home/backup" # the location to put the backup files. tempat backup files
MAILCONTENT="stdout"
MAILADDR=" me@ohmymy.com"
COMP=gzip

OPT="all"
# What do we want to backup.
# Apa yg mau di backup:
# "all" = schema + data
# "schema" = schema
# "data" = data

SEPDIR="yes"

DOWEEKLY=6
# On what day we want the weekly backup to be done. 1 = Monday
# Pada hari apa kita ingin backup mingguan dilakukan, 1 = Senin


DATE=`date +%Y-%m-%d_%Hh%Mm`	# Datestamp misalnya 2006-03-21
DOW=`date +%A`	 # Day of the week, misalnya Sunday
DNOW=`date +%u`	 # Day number of the week, misalnya Senin = 1
DOM=`date +%d`	 # Date of the month, misalnya 27
M=`date +%B`	 # Bulan, misalnya January
W=`date +%V`	 # Week number, misalnya minggu ke-37

LOGFILE=$BACKUPDIR/$DBHOST-`date +%N`.log	# Nama logfilenya
LOGERR=$BACKUPDIR/ERRORS_$DBHOST-`date +%N`.log	# Nama logfile utk error

BACKUPFILES=""

OPT=""

# Create necessary directory
# Create direktori yang diperlukan
if [ ! -e "$BACKUPDIR" ]
then
mkdir -p "$BACKUPDIR"
fi

if [ ! -e "$BACKUPDIR/daily" ]	 # Check if Daily Directory exists.
then
mkdir -p "$BACKUPDIR/daily"
fi
 
if [ ! -e "$BACKUPDIR/weekly" ]	 # Check if Weekly Directory exists.
then
mkdir -p "$BACKUPDIR/weekly"
fi
 
if [ ! -e "$BACKUPDIR/monthly" ]	# Check if Monthly Directory exists.
then
mkdir -p "$BACKUPDIR/monthly"
fi

# Make logfile
# Membuat logfile
touch $LOGFILE
exec 6>&1
exec > $LOGFILE	 # Link file descriptor #6 with stdout.
# Saves stdout.
touch $LOGERR
exec 7>&2 # Link file descriptor #7 with stderr.
# Saves stderr.
exec 2> $LOGERR # stderr replaced with file $LOGERR.

if [ "$OPT" = "all" ]; then
OPT = ""
elif [ "OPT" = "data" ]; then
OPT = "-a"
elif [ "OPT" = "schema" ]; then
OPT = "-s"
fi




# Database dump function
dbdump () {
pg_dump -O $OPT -U $USERNAME -h $DBHOST -d $1 > $2
return 0
}

# Compression function plus latest copy
SUFFIX=""
compression () {
if [ "$COMP" = "gzip" ]; then
gzip -f "$1"
echo
echo Backup Information for "$1"
gzip -l "$1.gz"
SUFFIX=".gz"
elif [ "$COMP" = "bzip2" ]; then
echo Compression information for "$1.bz2"
bzip2 -f -v $1 2>&1
SUFFIX=".bz2"
else
echo "No compression option set, check advanced settings"
fi
return 0
}

# Hostname for LOG information
if [ "$DBHOST" = "localhost" ]; then
HOST=`hostname`
if [ "$SOCKET" ]; then
OPT="$OPT --socket=$SOCKET"
fi
else
HOST=$DBHOST
fi


# Test is seperate DB backups are required
if [ "$SEPDIR" = "yes" ]; then
echo Backup Start Time `date`
echo ======================================================================
# Monthly Full Backup of all Databases
if [ $DOM = "01" ]; then
for MDB in $MDBNAMES
do
 
# Prepare $DB for using
MDB="`echo $MDB | sed 's/%/ /g'`"

if [ ! -e "$BACKUPDIR/monthly/$MDB" ]	 # Check Monthly DB Directory exists.
then
mkdir -p "$BACKUPDIR/monthly/$MDB"
fi
echo Monthly Backup of $MDB...
dbdump "$MDB" "$BACKUPDIR/monthly/$MDB/${MDB}_$DATE.$M.$MDB.sql"
compression "$BACKUPDIR/monthly/$MDB/${MDB}_$DATE.$M.$MDB.sql"
BACKUPFILES="$BACKUPFILES $BACKUPDIR/monthly/$MDB/${MDB}_$DATE.$M.$MDB.sql$SUFFIX"
echo ----------------------------------------------------------------------
done
fi

for DB in $DBNAMES
do
# Prepare $DB for using
DB="`echo $DB | sed 's/%/ /g'`"
 
# Create Seperate directory for each DB
if [ ! -e "$BACKUPDIR/daily/$DB" ]	 # Check Daily DB Directory exists.
then
mkdir -p "$BACKUPDIR/daily/$DB"
fi
 
if [ ! -e "$BACKUPDIR/weekly/$DB" ]	 # Check Weekly DB Directory exists.
then
mkdir -p "$BACKUPDIR/weekly/$DB"
fi
 
# Weekly Backup
if [ $DNOW = $DOWEEKLY ]; then
echo Weekly Backup of Database \( $DB \)
echo Rotating 5 weeks Backups...
if [ "$W" -le 05 ];then
REMW=`expr 48 + $W`
elif [ "$W" -lt 15 ];then
REMW=0`expr $W - 5`
else
REMW=`expr $W - 5`
fi
eval rm -fv "$BACKUPDIR/weekly/$DB_week.$REMW.*"
echo
dbdump "$DB" "$BACKUPDIR/weekly/$DB/${DB}_week.$W.$DATE.sql"
compression "$BACKUPDIR/weekly/$DB/${DB}_week.$W.$DATE.sql"
BACKUPFILES="$BACKUPFILES $BACKUPDIR/weekly/$DB/${DB}_week.$W.$DATE.sql$SUFFIX"
echo ----------------------------------------------------------------------
 
# Daily Backup
else
echo Daily Backup of Database \( $DB \)
echo Rotating last weeks Backup...
eval rm -fv "$BACKUPDIR/daily/$DB/*.$DOW.sql.*"
echo
dbdump "$DB" "$BACKUPDIR/daily/$DB/${DB}_$DATE.$DOW.sql"
compression "$BACKUPDIR/daily/$DB/${DB}_$DATE.$DOW.sql"
BACKUPFILES="$BACKUPFILES $BACKUPDIR/daily/$DB/${DB}_$DATE.$DOW.sql$SUFFIX"
echo ----------------------------------------------------------------------
fi
done
echo Backup End `date`
echo ======================================================================

echo Total disk space used for backup storage..
echo Size - Location
echo `du -hs "$BACKUPDIR"`
echo


#Clean up IO redirection
exec 1>&6 6>&- # Restore stdout and close file descriptor #6.
exec 1>&7 7>&- # Restore stdout and close file descriptor #7.

if [ "$MAILCONTENT" = "files" ]
then
if [ -s "$LOGERR" ]
then
# Include error log if is larger than zero.
BACKUPFILES="$BACKUPFILES $LOGERR"
ERRORNOTE="WARNING: Error Reported - "
fi
#Get backup size
ATTSIZE=`du -c $BACKUPFILES | grep "[[:digit:][:space:]]total$" |sed s/\s*total//`
if [ $MAXATTSIZE -ge $ATTSIZE ]
then
BACKUPFILES=`echo "$BACKUPFILES" | sed -e "s# # -a #g"`	#enable multiple attachments
mutt -s "$ERRORNOTE MySQL Backup Log and SQL Files for $HOST - $DATE" $BACKUPFILES $MAILADDR < $LOGFILE #send via mutt
else
cat "$LOGFILE" | mail -s "WARNING! - MySQL Backup exceeds set maximum attachment size on $HOST - $DATE" $MAILADDR
fi
elif [ "$MAILCONTENT" = "log" ]
then
cat "$LOGFILE" | mail -s "MySQL Backup Log for $HOST - $DATE" $MAILADDR
if [ -s "$LOGERR" ]
then
cat "$LOGERR" | mail -s "ERRORS REPORTED: MySQL Backup error Log for $HOST - $DATE" $MAILADDR
fi
elif [ "$MAILCONTENT" = "quiet" ]
then
if [ -s "$LOGERR" ]
then
cat "$LOGERR" | mail -s "ERRORS REPORTED: MySQL Backup error Log for $HOST - $DATE" $MAILADDR
cat "$LOGFILE" | mail -s "MySQL Backup Log for $HOST - $DATE" $MAILADDR
fi
else
if [ -s "$LOGERR" ]
then
cat "$LOGFILE"
echo
echo "###### WARNING ######"
echo "Errors reported during AutoMySQLBackup execution.. Backup failed"
echo "Error log below.."
cat "$LOGERR"
else
cat "$LOGFILE"
fi
fi

if [ -s "$LOGERR" ]
then
STATUS=1
else
STATUS=0
fi
fi

# Clean up Logfile
eval rm -f "$LOGFILE"
eval rm -f "$LOGERR"

exit $STATUS

# Well, I'm not a bash scriptter, so I'm sure there must be a much better way to do it, even I'm also quite sure
# that this program has some bug to be found. So, any suggestion is most welcome. Please contact me
# at: fajarpri at arinet dot org, and pls do stop by my website at http://linux2.arinet.org. Thanks.

# Saya bukan programmer bash script, dan karenanya saya yakin banget ada cara yang jauh lebih baik di dalam
# mencapai apa yang diinginkan oleh program ini, dan juga pasti ada beberapa bug di dalam program ini. Oleh karena
# itu, semua saran/koreksi sangat diharapkan. Saya dapat dihubungi melalui email fajarpri at arinet dot org, dan
# website http://linux2.arinet.org

# Knowledge belongs to everyone.
