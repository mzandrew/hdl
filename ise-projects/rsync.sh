#!/bin/bash -e

declare list=""
#list="$list 2013pi1-idlab"
#list="$list rpi122"
#list="$list rpi173"
#list="$list rpi174" # alphav2-eval
list="$list rpi102" # irsx toupee
#list="$list rpi92" # ampoliros48 revA #2
#list="$list rpi93" # ampoliros48 revA #3
#list="$list rpi88" # ampoliros48 revA #4
#list="$list rpi96" # ampoliros12
#list="$list 2018pi2-idlab"
#list="$list 2018pi3-idlab-xrm"
#list="$list 2021pi0w-idlab"
#list="$list 2021pi0w-idlab-home"
#list="$list /media/mza/writable/mza"

for each in $list; do
	echo "$each"
	rsync -avm --include="*/" --include="*.bit" --include="*.bin" --exclude="*" ./ $each:build/hdl/ise-projects/
	#rsync -avm --include="*/" --include="*.bit" --include="*.bin" --exclude="*" ./ $each/
done

