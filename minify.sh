#!/bin/sh

cp dead_mans_slope.p8 dead_mans_slope_fmt.p8
#Remove leading and trailing whitespace
sed -i bak 's/^[ \t]*//;s/[ \t]*$$//' dead_mans_slope_fmt.p8
#Remove all comments
sed -i bak 's:--.*$$::g' dead_mans_slope_fmt.p8
#Delete empty lines
sed -i bak '/^$$/d' dead_mans_slope_fmt.p8


