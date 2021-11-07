#!/bin/bash

REPORT_DIR=results
FILE=$REPORT_DIR/report.txt 
DEFAULT_EXIM_CONF=/etc/exim.conf
EXIM_CONF_COPY=$REPORT_DIR/exim.conf.copy
EMAIL_REGEX="[^@<[ ]+@([^@ ])+\.[^@ >\n]+"

mkdir -p $REPORT_DIR
if [[ -f $EXIM_CONF_COPY ]] ; then
    rm $EXIM_CONF_COPY
fi
cat /dev/null > $FILE

echo "--- UNAME ---" >> $FILE 
uname -a >> $FILE

# Linux distro info
echo "--- LINUX DISTROS ---" >> $FILE
ls /etc/*release >> $FILE

# Exim section
echo "--- EXIM ---" >> $FILE
#echo "DEBUG" 
#if type -t exim ; then
if EXIM_BIN=`which exim 2>&1` ; then
    echo $EXIM_BIN >> $FILE
    exim --version 2>&1 >> $FILE
    echo "---EXIM CONFIG--- " >> $FILE
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

# Mail Logs
echo "--- EXIM MAIL LOGS ---" >> $FILE
if [[ -f /var/log/exim_mainlog ]]; then
    echo "/var/log/exim_mainlog -> exim_mainlog-stripped.txt" >> $FILE
    cat /var/log/exim_mainlog | sed -r "s/$EMAIL_REGEX/$EMAIL_REPLACE_PATTERN/g" > $RESULT_DIR/exim_mainlog-stripped.txt 
else 
    echo "/var/log/exim_mainlog NOT FOUND" >> $FILE
fi

