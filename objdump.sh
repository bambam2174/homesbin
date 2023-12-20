#!/bin/bash
args=${@}
ELEMENTS=${#args[@]}
#echo $args
#echo $ELEMENTS
#exit

if [ -z $1 ]; then
	echo "Usage: `basename $0` File [Lines] "
	exit
fi

if [ -z "$2" ]; then 
	#N=80; 
	otool -tV $1
else 
	N=$2;
	otool -tV $1 | grep -A$N main:
fi
#otool -tV $1 | grep -A$N main:
