#!/system/xbin/bash

declare -a vo
vo[100000]=$((7000+125*23))
vo[200000]=$((7000+125*24))
vo[300000]=$((7000+125*25))
vo[400000]=$((7000+125*26))
vo[500000]=$((7000+125*29))
vo[600000]=$((7000+125*33))
vo[700000]=$((7000+125*36))
vo[800000]=$((7000+125*40))
vo[900000]=$((7000+125*45))
vo[1000000]=$((7000+125*50))
vo[1050000]=$((7000+125*52))
vo[1100000]=$((7000+125*52))
vo[1150000]=$((7000+125*53))
vo[1200000]=$((7000+125*53))
vo[1250000]=$((7000+125*53))
#set -x
set -e

stats_src=/sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state
[ -n "$1" ] && stats_src=$1

declare -a stats

while read freq time_cs; do
	stats[$freq]=$time_cs
done < $stats_src

#echo ${!stats[@]}
#echo ${stats[@]}

declare -a voltages

for i in /sys/kernel/liveopp/arm_step*; do
	freq=`grep "Frequency show:" $i | awk '{print $3}'`
	v=`grep "Varm" $i | awk '{print $2}'`
	voltages[$freq]=$((v/100))
done

#echo ${!voltages[@]}
#echo ${voltages[@]}

declare -a power
declare -a dp
declare -a po
total_power=0
total_power_o=0

for freq in ${!stats[@]}; do
	v=voltages[$freq]
	p=$(( (stats[$freq] * freq) /100000 * v/1000*v/1000))
	power[$freq]=$p
	total_power=$((total_power+p))

	v=$((v-125))
	p=$(( (stats[$freq] * freq) /100000 * v/1000*v/1000))
	dp[$freq]=$p

	v=vo[$freq]
	p=$(( (stats[$freq] * freq) /100000 * v/1000*v/1000))
	po[$freq]=$p-power[$freq]
	total_power_o=$((total_power_o+p))
done

hformat="%5s %8s %8s %8s %8s %10s %17s\n"
format="%5s %8s %8.1f %3s.%04d %3s.%04d %6d.%03d %17s\n"

printf "$hformat" \
	"freq" \
	"time[s]" \
	"P[%]" \
	"V[V]" \
	"Vorig[V]" \
	"P_saved[%]" \
	"delta_P_1[%/1000]" \

for freq in ${!stats[@]}; do
	printf "$format" \
		$((freq/1000)) \
		$((stats[$freq]/100)) \
		$((power[$freq]*100/total_power)).$(((power[$freq]*1000/total_power)%10)) \
		$((voltages[$freq]/10000)) $((voltages[$freq]%10000)) \
		$((vo[$freq]/10000)) $((vo[$freq]%10000)) \
		$((po[$freq]*100/total_power)) $(( (po[$freq]*100*1000/total_power)%1000 )) \
		$(((power[$freq]-dp[$freq])*100*1000/total_power)) \

done

tps=$(( (total_power_o-total_power)*10000/total_power ))
printf "Total power saved: %2d.%02d%%\n" $((tps/100)) $((tps%100))
