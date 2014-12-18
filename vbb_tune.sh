#!/system/bin/sh

set -x
set -e

dir=/cache/uv

BC=$dir/bin/bc

out=$dir/out
mkdir -p $out

reg=/sys/kernel/debug/ab8500/register

echo userspace > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat $dir/freq > /sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed
vbb=`cat $dir/vbb`

[ "$vbb" -ge 15 ] && exit 0

vbb=$((vbb+1))
echo $vbb > $dir/vbb
vdd=`cat $dir/last_vdd`
vdd=$((vdd+3))
vdd_reg=`cat $dir/vdd_reg`

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

function spinner() {
	[ -z "$2" ] && spinner $1 1&

	_delay=$1
	t_end=`date "+%s"`
	t_end=$((t_end+_delay))
	i=0
	while [ `date +"%s"` -lt $t_end ]; do
		let i=$i+1
	done
}

function logger() {
	end=$1
	for i in `seq -w 1 $end`; do
		fname=$out/${2}_${i}
		for p in `cat /sys/devices/platform/ab8500-i2c.0/ab8500-fg.0/power_supply/ab8500_fg/current_now \
			/sys/devices/platform/ab8500-i2c.0/ab8500-fg.0/power_supply/ab8500_fg/current_avg \
			/sys/devices/platform/ab8500-i2c.0/ab8500-fg.0/power_supply/ab8500_fg/voltage_now \
			/sys/devices/platform/ab8500-i2c.0/ab8500-btemp.0/power_supply/ab8500_btemp/temp \
			/d/ab8500/gpadc/die_temp /d/ab8500/gpadc/btemp_ball \
			/sys/devices/virtual/power_supply/battery/batt_temp_* \
			/sys/devices/platform/ab8500-i2c.0/abx500-temp.0/temp*_input 
			`; do
			echo -n "$p " >> $fname
		done
		echo >> $fname
		sync
		sleep 1
	done
}
set_vdd 50	#0x32

set_vbb $vbb
set_vdd $vdd
#start=`cat register-value | tr a-f A-F | sed -e "s/0x//g"`
#start=`echo "ibase=16; $start-1" | $BC`

dt=120
dt=15
for vdd in `seq $vdd -1 0`; do
	echo $vdd > $dir/last_vdd
	sync
	set_vdd $vdd
	#logger $dt idle_${vbb}_${vdd}

	taskset 1 $dir/bin/busyloop&
	taskset 2 $dir/bin/busyloop&
	logger $dt load_${vbb}_${vdd}
	killall busyloop
done
