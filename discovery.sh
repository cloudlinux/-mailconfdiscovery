#!/bin/bash

FILE=report.txt 
DEFAULT_EXIM_CONF=/etc/exim.conf
EXIM_CONF_COPY=exim.conf.copy

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
    if [[ -f $DEFAULT_EXIM_CONF ]] ; then
	echo $DEFAULT_EXIM_CONF >> $FILE
        if cp $DEFAULT_EXIM_CONF $EXIM_CONF_COPY 2>>$FILE ; then 
            echo "Copied $DEFAULT_EXIM_CONF to $EXIM_CONF_COPY " >> $FILE 
	else 

    else
	echo "$DEFAULT_EXIM_CONF not found" >> $FILE
    fi
else
  echo "Exim not found" >> $FILE
fi    


# Exim config copy 
# Relayhosts
echo "--- RELAYHOSTS ---" >> $FILE
cat /etc/relayhosts >> $FILE
