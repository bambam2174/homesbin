#!/bin/zsh


get-n-functions-of-script () {
	n=$(cat  "${1}" | wc -l)
	i=0
	tail -n $(($n - $i + 1)) "${1}" | head -n $( get-line-starts-with '}' "${1}" ${2})
}

get-n-functions-of-scriptb () {
	n=$(cat  "${1}" | wc -l)
	i=0
	head -n $(($n - $i + 1)) "${1}" | tail -n 1640
}

get-line-starts-with () {
	CNT=1 
	[[ -n $3 ]] && CNT=$3 
	grep --color=auto -En '^'${1} "${2}" | head -n $CNT | tail -n 1 | cut -d ':' -f1
}
