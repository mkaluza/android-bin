#!/system/bin/sh

#set -x

which bc > /dev/null
if [ $? -gt 0 ]
then
	cat << _EOF
BC binary not found. Please download it from 

https://www.mediafire.com/folder/j6ckpsfpoe0na/bin

to /system/xbin/ dir and set it's attributes to 755
_EOF
	exit 1
fi

gov=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`

if [ "$gov" != "userspace" -a "$gov" != "performance" -a "$gov" != "powersave" ]
then
	echo "Please change governor to userspace, performance or powersave (it's $gov now) and set desired frequency"
	exit 1
fi

REG=`echo $1 | tr a-f A-F`

if [ "$REG" != "0xB" -a "$REG" != "0xC" ]
then
	cat << _EOF
usage: `basename $0` REG
where REG is 0xB for ARM_100_OPP and ARM_MAX_OPP or 0xC for ARM_50_OPP and ARM_EXT_CLK
_EOF
	exit 1
fi

freq=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq`

echo "Testing extreme undervolt for $freq with $REG register"

cd /sys/kernel/debug/ab8500/
echo 4 > register-bank
echo $REG > register-address

start=`cat register-value | tr a-f A-F | sed -e "s/0x//g"`
start=`echo "ibase=16; $start-1" | bc`
delay=60
for V in `seq $start -1 0`
	do Vh=`echo "obase=16; $V" | bc`
	echo "Setting 0x$Vh"
	echo "0x$Vh" > register-value
	for i in `seq $delay -1 1`; do
		echo -n ". "
		sleep 1;
	done
done
