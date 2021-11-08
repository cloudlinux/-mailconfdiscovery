#!/bin/bash

REPORT_DIR=results
FILE=$REPORT_DIR/report.txt 

DEFAULT_EXIM_CONF=/etc/exim.conf
EXIM_CONF_COPY=$REPORT_DIR/exim.conf.copy
EMAIL_REGEX="[^@<[ ]+@([^@ ])+\.[^@ >\n]+"

DEFAULT_EXIM_LOG_PATH=/var/log
DEFAULT_EXIM_LOGS=(exim_mainlog exim_paniclog exim_rejectlog)

SMTP_PORTS=(25 465 587 2525)

sec_start() { 
  if [[ $1 == "-n" ]] ; then
	nl=""
	shift
  else 
	nl="-n" 
  fi
  echo $nl $@ ".........."
}
sec_end() {
    echo "done"
}

mkdir -p $REPORT_DIR
if [[ -f $EXIM_CONF_COPY ]] ; then
    rm -f $EXIM_CONF_COPY
fi
cat /dev/null > $FILE

sec_start "OS Detail"
echo "--- UNAME ---" >> $FILE 
uname -a >> $FILE
sec_end 


sec_start "Linux Distro"
# Linux distro info
echo "--- LINUX DISTROS ---" >> $FILE
for f in  /etc/*release ; do
   echo "- $f" >> $FILE
   cat $f >> $FILE
done
echo "" >> $FILE
sec_end

# Exim section
sec_start "Exim conf"
echo "--- EXIM ---" >> $FILE
if EXIM_BIN=`which exim 2>&1` ; then
    echo $EXIM_BIN >> $FILE
    exim --version &>> $FILE
    echo "--- EXIM CONFIG --- " >> $FILE
    # Exim config copy 
    if [[ -f $DEFAULT_EXIM_CONF ]] ; then
	echo $DEFAULT_EXIM_CONF >> $FILE
        if cp $DEFAULT_EXIM_CONF $EXIM_CONF_COPY 2>>$FILE ; then 
            echo "Copied $DEFAULT_EXIM_CONF to $EXIM_CONF_COPY " >> $FILE 
	else 
            echo "Failed to copy $DEFAULT_EXIM_CONF" >> $FILE	
	fi
    else
	echo "$DEFAULT_EXIM_CONF not found" >> $FILE
    fi
else
  echo "Exim not found" >> $FILE
fi    

# Relayhosts
echo "--- RELAYHOSTS ---" >> $FILE
cat /etc/relayhosts >> $FILE


# SkipSMTPChecks
echo "--- SKIP SMTP CHECKS HOSTS ---" >> $FILE
cat /etc/skipsmtpcheckhosts >> $FILE
sec_end

sec_start "Mail logs"
# Mail Logs
echo "--- EXIM MAIL LOGS ---" >> $FILE
for f in ${DEFAULT_EXIM_LOGS[@]} ; do
    sf=$DEFAULT_EXIM_LOG_PATH/$f
    df=$REPORT_DIR/$f-noemail
    if [[ -f $sf ]]; then
        echo "$sf -> $df" >> $FILE
        cat $sf | sed -r "s/$EMAIL_REGEX/$EMAIL_REPLACE_PATTERN/g" > $df
    else 
        echo "$sf NOT FOUND" >> $FILE
    fi
done
sec_end

sec_start -n "Trying direct SMTP"
echo "--- Direct SMTP connections ---" >> $FILE
test_mx_server=`dig +short gmail.com MX | awk '{print $2; exit}'`
for port in ${SMTP_PORTS[@]} ; do 
    echo -n "trying: .... $test_mx_server/$port " | tee -a $FILE
    ( echo "HELO testserver.test" > /dev/tcp/$test_mx_server/$port ) & pid=$!
    ( sleep 5 && kill -HUP $pid ) 2>/dev/null & watcher=$!
    wait $pid 2>/dev/null && pkill -HUP -P $watcher 
    status=$?
    if [ $status -ne 0 ] ; then
        echo "($status) CLOSED" | tee -a $FILE
    else 
	echo "($status) OPEN" | tee -a $FILE
    fi
done
sec_end
