#!/system/bin/sh

dir=${1:-.}
for i in $dir/*; do
	[ -d "$i" ] && continue;
	name=`basename $i`
	echo -n "$name: "
	cat $i
done
