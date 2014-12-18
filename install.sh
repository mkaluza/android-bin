#!/system/bin/sh

set -x
sysrw
for i in `ls /data/bin/ | grep -v install`; do
	[ -x $i ] && ln -s /data/bin/$i /system/bin/$i
done

rm -f /etc/cron.d/cron.daily/00sqlitespeed
cp /data/bin/cron/00sqlitespeed  /etc/cron/cron.weekly/

rm -f /system/bin/top

rm -f /system/app/NovaThorSettings.apk

