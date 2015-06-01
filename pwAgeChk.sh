#!/bin/bash
# $Id: pwAgeChk.sh 115 2013-05-22 20:09:37Z ohare2 $
# $URL: https://corbin.llnl.gov/repos/admin/scripts/pwAgeChk.sh $
# pwAgeChk.sh
usr=`id -un`
entry=`getent shadow $usr`
if [ $? != 0 ]; then
	echo "Not a local account"
	exit 0
fi
IFS=':' read -a array <<< "$entry"
today=`date +%s`
today=$((today / 60 / 60 / 24))
#echo "${array[2]} + ${array[4]} - $today"
daysleft=$((${array[2]} + ${array[4]} - $today))
if (( $daysleft <= 14 )); then
	echo "Password expires in $daysleft days"
fi
