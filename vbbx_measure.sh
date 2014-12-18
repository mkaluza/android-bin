#!/system/bin/sh

#set -x
set -u

dir=/cache/uv

BC=$dir/bin/bc

out=$dir/out
mkdir -p $out

/sbin/mount -t debugfs none /sys/kernel/debug
ln -s /sys/kernel/debug /d

set -e

reg=/sys/kernel/debug/ab8500/register

echo off > /sys/kernel/abb-charger/charger_hw
echo userspace > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

echo 0x04 > $reg-bank

function set_vbb() {
	echo 0x11 > $reg-address
	hex=`echo "obase=16; $1*16+$1" | $BC`
	echo "Setting vbbx to 0x$hex"
	echo "0x$hex" > $reg-value
}

function set_vdd() {
	echo $vdd_reg > $reg-address
	hex=`echo "obase=16; $1" | $BC`
	echo "Setting vdd to 0x$hex"
	echo "0x$hex" > $reg-value
}

function logger() {
	end=$1
	step=1
	for i in `seq -w 1 $step $end`; do
		fname=$out/${2}
		for p in $i `cat \
			/sys/devices/platform/ab8500-i2c.0/ab8500-fg.0/power_supply/ab8500_fg/voltage_now \
			/sys/devices/platform/ab8500-i2c.0/ab8500-fg.0/power_supply/ab8500_fg/current_now \
			/sys/devices/platform/ab8500-i2c.0/ab8500-fg.0/power_supply/ab8500_fg/current_avg \
			/sys/devices/platform/ab8500-i2c.0/ab8500-btemp.0/power_supply/ab8500_btemp/temp \
			/d/ab8500/gpadc/die_temp /d/ab8500/gpadc/btemp_ball \
			/sys/devices/virtual/power_supply/battery/batt_temp_* \
			/sys/devices/platform/ab8500-i2c.0/abx500-temp.0/temp*_input 
			`; do
			echo -n "$p " >> $fname
		done
		echo >> $fname
		sync
		echo -n "$i "
		sleep $step
	done
	echo
}

dt=60
for s in `cat $dir/ranges`; do
	data=( ${s//,/ } )
	freq=${data[0]}
	vdd_reg=${data[1]}
	mode=${data[2]}
	vbb=${data[3]}
	vdd_min=${data[4]}
	vdd_max=${data[5]}
	set_vdd 50	#0x32

	echo $((freq*1000)) > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed
	set_vbb $vbb
	set_vdd $vdd_min
	delay=$dt
	if [ "$mode" == "load" ]; then
		$dir/bin/busyloop&
		$dir/bin/busyloop&
#		delay=$dt
#	else
#		delay=$((dt*2))
	fi
	sleep $((2*delay))
	for vdd in `seq $vdd_min $vdd_max`; do
		set_vdd $vdd
		logger $delay ${freq}_${mode}_${vbb}_${vdd}
	done
	killall busyloop || true
done

reboot
