#!/system/bin/sh

zcat `ls /data/local/log/last_kmsg/* | tail -n 1` | less
