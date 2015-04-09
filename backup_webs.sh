#!/bin/bash
#######################################
### PARAMETERS TO CUSTOMIZE THE SCRIPT
#######################################
### Generic Label for the server ###
MLABEL="ueb_b52"
### MySQL Server Login Info ###
MUSER="ueb"
MPASS="MainHeadB52"
MHOST="localhost"
### FTP SERVER Login info ###
FTPU="ftpuser"
FTPP="ftppass"
FTPS="ftpserver"
FTPF="./backups/b52"
NOWD=$(date +"%Y-%m-%d")
NOWT=$(date +"%H_%M_%S")
## Some paths defined
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
BAKPATH="/home/ueb" # TODO: make the folliwng paths relative to this one
BAK="backup_webs_b52"
TIKIFILESABSPATH="/var/www/tiki_files"
# Relative paths to backup folders
RBAK1="mysql"
RBAK2="tikifiles"
RBAK3="serverfiles"
EMAILF="ueb@vhir.org"
EMAILT="xavier.depedro@vhir.org"
SMTP="servirmta1.ir.vhebron.net"

#### End of parameters
#######################################


# Base path for backup folders
BBAK=$BAKPATH/$BAK/$NOWD
# Absolute paths to backup folders (base path + relative path)
ABAK1=$BBAK/$RBAK1
ABAK2=$BBAK/$RBAK2
ABAK3=$BBAK/$RBAK3
# Other variables used
GZIP="$(which gzip)"
# Relative paths for each log file
RLOGF=log-$MLABEL-SUM.$NOWD.txt
RLOGF1=log-$MLABEL-$RBAK1.$NOWD.txt
RLOGF2=log-$MLABEL-$RBAK2.$NOWD.txt
RLOGF3=log-$MLABEL-$RBAK3.$NOWD.txt
# Base log path (set by default to the same base path for backups)
BLOGF=$BBAK
# Absolute path for log files
ALOGF=$BLOGF/$RLOGF
ALOGF1=$BLOGF/$RLOGF1
ALOGF2=$BLOGF/$RLOGF2
ALOGF3=$BLOGF/$RLOGF3


### These next parts (1) & (2) are related to the removal of previous files in these folders if they exist, and create dirs as needed for new set of periodic backups ###

## (1) To remove all previous backups locally at the server and at the same base backup folder, uncomment the following line
#[ ! -d $BAKPATH/$BAK ] && mkdir -p $BAKPATH/$BAK || /bin/rm -f $BAKPATH/$BAK/*

## (2) To avoid removing previous backups from teh same day locally, keep the last part commeted out (with ## just in front of "|| /bin/rm -f ..." )
[ ! -d $ABAK1 ] && mkdir -p $ABAK1 || /bin/rm -f $ABAK1/*
[ ! -d $ABAK2 ] && mkdir -p $ABAK2 || /bin/rm -f $ABAK2/*
[ ! -d $ABAK3 ] && mkdir -p $ABAK3 || /bin/rm -f $ABAK3/*
### [ ! -d "$BAK" ] && mkdir -p "$BAK" ###
 
DBS="$($MYSQL -u $MUSER -h $MHOST -p$MPASS -Bse 'show databases')"
for db in $DBS
do
 FILE=$ABAK1/$db.$NOWD-$NOWT.gz
 $MYSQLDUMP -u $MUSER -h $MHOST -p$MPASS $db | $GZIP -9 > $FILE
done
 
### Backup tikifiles ###
tar -chzvf $ABAK2/00-$RBAK2-$MLABEL.$NOWD-$NOWT.tgz $TIKIFILESABSPATH/* >  $ALOGF2

### Backup serverfiles ###
tar -chzvf $ABAK3/00-$RBAK3-$MLABEL.$NOWD-$NOWT.tgz /etc/* /root/.* >  $ALOGF3

### Send files over ftp ###
#lftp -u $FTPU,$FTPP -e "mkdir $FTPF/$NOWD;cd $FTPF/$NOWD; mput $ABAK1/*.gz; mput $ABAK2/*.tgz; mput $ABAK3/*.tgz; quit" $FTPS > $ALOGF
cd $ABAK1;ls -lh * > $ALOGF1
# Add a short summary with partial dir sizes and append all partial log files into one ($LOGF)
cd $BBAK;du -h $RBAK1 $RBAK2 $RBAK3 > $ALOGF;echo "" >> $ALOGF;echo "--- $RBAK2 uncompressed: ---------------" >> $ALOGF;du $TIKIFILESABSPATH -h --max-depth=2 >> $ALOGF

### Compress and Send log files ###
tar -czvf $ALOGF1.tgz -C $BLOGF $RLOGF1
#tar -czvf $ALOGF2.tgz -C $BLOGF $RLOGF2
tar -czvf $ALOGF3.tgz -C $BLOGF $RLOGF3
#lftp -u $FTPU,$FTPP -e "cd $FTPF/$NOWD; put $ALOGF1.tgz; put $ALOGF2.tgz; put $ALOGF3.tgz; quit" $FTPS

### Send report through email ###
sendemail -f $EMAILF -t $EMAILT -u '[B52 webs Backups Report]' -m 'Short report attached' -a $ALOGF -a $ALOGF1 -s $SMTP -o tls=no


