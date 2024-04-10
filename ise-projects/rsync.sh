#!/bin/bash -e

declare list=""
#list="$list 2013pi1-idlab"
#list="$list rpi122"
#list="$list rpi173"
#list="$list rpi102"
#list="$list rpi88" # ampoliros48 revA #
list="$list rpi92" # ampoliros48 revA #2
#list="$list rpi96" # ampoliros48 revA #
#list="$list rpi93" # ampoliros48 revA #3
#list="$list 2018pi2-idlab"
#list="$list 2018pi3-idlab-xrm"
#list="$list 2021pi0w-idlab"
#list="$list 2021pi0w-idlab-home"

for each in $list; do
	echo "$each"
	rsync -avm --include="*/" --include="*.bit" --include="*.bin" --exclude="*" ./ $each:build/hdl/ise-projects/
done

