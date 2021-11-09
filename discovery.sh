#!/bin/bash

VERSION=0.1

REPORT_DIR=mailconfdiscovery
FILE=$REPORT_DIR/report.txt 

DEFAULT_CPANEL_DIR=/usr/local/cpanel

DEFAULT_EXIM_CONF=/etc/exim.conf
EXIM_CONF_COPY=$REPORT_DIR/exim.conf.copy
EMAIL_REGEX="[^@<[ ]+@([^@ ])+\.[^@ >\n]+"

DEFAULT_EXIM_LOG_PATH=/var/log
DEFAULT_EXIM_LOGS=(exim_mainlog exim_paniclog exim_rejectlog)

# which ports to check and how many seconds to wait before killing tcp connection
SMTP_PORTS=(25 465 587 2525)
TCP_CONN_TIMEOUT=5

DATE_FORMAT="%Y%m%d%H%M%z"

printUsage() {
    cat <<EOF

Mailconfdiscovery $VERSION

Collects mail system related configuration, including
    * OS version
    * Linux Distibution name
    * cpanel version
    * Exim version and configuration ($DEFAULT_EXIM_CONF)
    * Exim mail logs (${DEFAULT_EXIM_LOGS[@]})

EOF
}

sec_start() { 
  if [[ $1 == "-n" ]] ; then
	nl=""
	shift
  else 
	nl="-n" 
  fi
  echo "--- $@ ----" >> $FILE
  echo $nl $@ ".........."
}
sec_end() {
    echo >> $FILE
    echo "done"
}

if [[ $# -ne 0 ]] ; then
   printUsage
   exit 1
fi

# preparing report dir, removing old conf copies, nulling a report file
mkdir -p $REPORT_DIR
if [[ -f $EXIM_CONF_COPY ]] ; then
    rm -f $EXIM_CONF_COPY
fi
cat /dev/null > $FILE

# OS Details
sec_start "OS Detail"
uname -a >> $FILE
sec_end 


# Linux distro info
sec_start "Linux Distro"
for f in  /etc/*release ; do
    echo "- $f" >> $FILE
    cat $f >> $FILE
done
echo "" >> $FILE
sec_end

# cPanel 
sec_start "cPanel"
if [[ -x $DEFAULT_CPANEL_DIR/cpanel ]] ; then 
    $DEFAULT_CPANEL_DIR/cpanel -V &>> $FILE   
else 
    echo "$DEFAULT_CPANEL_DIR/cpanel can't be executed" >> $FILE
fi
sec_end

# Exim section
sec_start "Exim conf"
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

sec_start -n "Direct SMTP connections "
test_mx_server=`dig +short gmail.com MX | awk '{print $2; exit}'`
for port in ${SMTP_PORTS[@]} ; do 
    echo -n "trying: .... $test_mx_server/$port " | tee -a $FILE
    ( echo "HELO testserver.test" > /dev/tcp/$test_mx_server/$port ) & pid=$!
    ( sleep $TCP_CONN_TIMEOUT && kill -HUP $pid ) 2>/dev/null & watcher=$!
    wait $pid 2>/dev/null && pkill -HUP -P $watcher 
    status=$?
    if [ $status -ne 0 ] ; then
        echo "($status) CLOSED" | tee -a $FILE
    else 
	echo "($status) OPEN" | tee -a $FILE
    fi
done
sec_end

ARCHIVE_NAME=$REPORT_DIR-`hostname`-`date +$DATE_FORMAT`.tar.gz 
sec_start "Packaging results $ARCHIVE_NAME"
tar cfz $ARCHIVE_NAME $REPORT_DIR
sec_end

