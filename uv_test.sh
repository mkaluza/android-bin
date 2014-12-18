#!/system/bin/sh

set -e
set -x
echo userspace > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo $(($1*1000)) > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed

cd /d/ab8500
echo 4 > register-bank
echo $3 > register-address

start=`echo $2 | tr a-f A-F | sed -e "s/0[xX]//g"`
start=`echo "ibase=16; $start-1" | bc`
for V in `seq $start -1 0`
do
	Vh=`echo "obase=16; $V" | bc`
	echo "$V: $Vh"
	echo "0x$Vh" > register-value
	sleep 60
	set +x
done   
