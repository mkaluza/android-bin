echo 0x88 > /sys/kernel/prcmu/prcmu_rreg                                                                                                                                                                                                                              

cd /sys/kernel/liveopp
#echo set_volt=1 > arm_step02
#echo set_volt=0 > arm_step06
#echo set_pll=0 > arm_step06
#echo set_volt=0 > arm_step08

cd /sys/devices/system/cpu/cpu0/cpufreq
echo userspace > scaling_governor

min_freq=`cat scaling_min_freq`
max_freq=`cat scaling_max_freq`

freqs=""
for f in `cat scaling_available_frequencies`; do
	[ $f -lt $min_freq ] && continue;
	[ $f -gt $max_freq ] && continue;
	freqs="$freqs $f"
done

if [ "$#" -gt 0 ]; then
	freqs1="$@"
else
	freqs1="$freqs"
fi

SLEEP="usleep 50000"
#SLEEP="sleep 1"

for f1 in $freqs1; do
	echo $f1 > scaling_setspeed
	cat /sys/kernel/prcmu/prcmu_rreg /sys/kernel/liveopp/arm_clk /sys/kernel/liveopp/arm_varm 2>/dev/null
	echo
	for f2 in $freqs; do
		[ "$f1" == $f2 ] && continue
		echo "$f1 -> $f2 "
		echo $f2 > scaling_setspeed
		echo "ok"
		cat /sys/kernel/prcmu/prcmu_rreg /sys/kernel/liveopp/arm_clk /sys/kernel/liveopp/arm_varm 2>/dev/null
		echo
		$SLEEP
		echo "$f2 -> $f1 "
		echo $f1 > scaling_setspeed
		echo "ok"
		cat /sys/kernel/prcmu/prcmu_rreg /sys/kernel/liveopp/arm_clk /sys/kernel/liveopp/arm_varm 2>/dev/null
		echo
		$SLEEP
	done;
done;
