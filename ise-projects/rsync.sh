#!/bin/bash -e

rsync -avm --include="*/" --include="*.bit" --include="*.bin" --exclude="*" ./ mza@2017pi2-idlab:build/hdl/ise-projects/
rsync -avm --include="*/" --include="*.bit" --include="*.bin" --exclude="*" ./ mza@2018pi2-idlab:build/hdl/ise-projects/

