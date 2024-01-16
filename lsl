#!/bin/zsh


_lsl () {
	BNAME=$(dirname ${1}) 
	echo $BNAME
	ls -G -l ${@} | grep --color=auto -oE '[0-9]{5,}.*' | sed -E "s/$(echo ${BNAME//\//\\/})//g"
}
_lsl ${@}
