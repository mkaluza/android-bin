#!/system/bin/sh

# freq[MHz] [start voltage[hex]]
freq=$1
start=$2

ps=/sys/devices/platform/ab8500-i2c.0/ab8500-fg.0/power_supply/ab8500_fg
set -e

killall busyloop || true

echo userspace > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo $((freq*1000)) > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed

cd /d/ab8500
echo 4 > register-bank

reg="0x0B"
[ $freq -lt 800 ] && reg="0x0C"
echo $reg > register-address

[ -z "$start" ] && start=`cat register-value`
start=`echo $start | tr a-f A-F | sed -e "s/0[xX]//g"`
start=`echo "ibase=16; $start-1" | bc`

[ -z "$delay" ] && delay=60

nice busyloop &
nice busyloop &

for V in `seq $start -1 0`
do
	Vh=`echo "obase=16; $V" | bc`
	echo "$V = 0x$Vh"
	echo "0x$Vh" > register-value
	for s in `seq $((delay/10)) -1 0`; do
		v=`cat $ps/voltage_now`
		v=$((v/1000))
		ia=`cat $ps/current_avg`
		ia=$((ia/(-1000)))
		in=`cat $ps/current_now`
		in=$((in/(-1000)))
		echo "$s: V=${v}mV, Ia=${ia}mA, In=${in}mA, Pa=$((v*ia/1000))mW, Pn=$((v*in/1000))mW"
		sleep 10
	done
done   

killall busyloop || true
