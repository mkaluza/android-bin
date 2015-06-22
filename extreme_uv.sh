#!/system/bin/sh

#set -x

#which bc > /dev/null
BC=/data/bin/bc

if [ $? -gt 0 ]
then
	cat << _EOF
BC binary not found. Please download it from 

https://www.mediafire.com/folder/j6ckpsfpoe0na/bin

to /system/xbin/ dir and set it's attributes to 755
_EOF
	exit 1
fi

echo userspace > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

[ -n "$1" ] && echo ${1}000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed
freq=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq`

step=`grep -l -e "[^0-9]$freq kHz" /sys/kernel/liveopp/arm_step*`
opp=`grep ArmOPP $step | awk '{print $2}'`

if [ $opp == "ARM_EXTCLK" -o "$opp" == "ARM_50_OPP" ]; then
	REG="0x0C"
else
	REG="0x0B"
fi

echo "Testing extreme undervolt for $freq with $REG register"

cd /sys/kernel/debug/ab8500/
echo 4 > register-bank
echo $REG > register-address

start=$2
[ -z "$start" ] && start=`cat register-value `
start=`echo $start | tr a-f A-F | sed -e "s/0x//g"`

start=`echo "ibase=16; $start-1" | $BC`
[ -z "$delay" ] && delay=60
for V in `seq $start -1 0`
	do Vh=`echo "obase=16; $V" | $BC`
	echo "Setting 0x$Vh"
	echo "0x$Vh" > register-value
	for i in `seq $delay -1 1`; do
		echo -n ". "
		sleep 1;
	done
	echo
done
