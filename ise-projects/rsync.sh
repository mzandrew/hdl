#!/bin/bash -e

declare list=""
list="$list 2013pi1-idlab"
list="$list 2017pi2-idlab"
list="$list 2018pi2-idlab"

for each in $list; do
	echo "$each"
	rsync -avm --include="*/" --include="*.bit" --include="*.bin" --exclude="*" ./ $each:build/hdl/ise-projects/
done

