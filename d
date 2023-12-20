#!/bin/zsh


_d () {
	if [[ -n $1 ]]
	then
		startsWithDash ${1} &&  dirs "$@" && shift
        isNumeric ${1} && { IDX=${1}; ((IDX++)); TARGET_DIR="$(dirs -lp | head -n ${IDX} | tail -n 1)"; cd ${TARGET_DIR} }
	else
		dirs -l -v # | head -n 10
	fi
}
_d ${@}
