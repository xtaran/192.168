#! /bin/sh

# 192.168.sh (GPL) (CC-by-sa-at-3.0) by Eric Poscher
# This is the shell script needed on the client side for the art project 192.168.epe.at
# Run this script hourly in a cron job!
# For more information, see: http://epe.at/de/portfolio/192168epeat

# check for serverconnection and upload file. Setup ssh public key auth first!
connandcopy() {
    ping -c 1 sym.noone.org && scp -4 index.html abe@sym.noone.org:http/192.168/
}

cd /home/abe/192.168/  # go to working directory

#ip r | grep default | grep 192.168 > /dev/null || exit

export IP="$( ip r |grep "default via" |  awk '{print $5}' | xargs ip addr show |grep "inet " | awk '{printf "%s ", $2}' | sed -e 's/\/[0-9]*//g;s/127\.0\.0\.1//g;s/ *//g')"

if [ "${IP}" = 127.0.0.1 -o "${IP}" = "" ]; then
    exit 0;
fi

if [ "`tail -1 ip-list.txt`" = "$IP" ]; then
    connandcopy;
    exit 0;
fi

echo $IP >> ip-list.txt

export RD=$( echo $IP | sed 's/\./ /g' | awk '{print $2}')
export GD=$( echo $IP | sed 's/\./ /g' | awk '{print $3}')
export BD=$( echo $IP | sed 's/\./ /g' | awk '{print $4}')

echo '<span class="item" style="background-color:rgb('$RD','$GD','$BD')">'$IP'</span>' >> epe.html

#Manage the content:
cat 192.html > index.html
cat 168.html >> epe.html
cat epe.html >> index.html
cat at.html >> index.html
mv epe.html 168.html

connandcopy;

