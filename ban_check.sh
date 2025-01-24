#! /usr/bin/bash
for i in `fail2ban-client status |
	egrep -e '.*Jail list:' |
	sed 's/.*Jail list:[ \t] *//' |
	sed 's/,//g'`;do fail2ban-client status  $i
done
