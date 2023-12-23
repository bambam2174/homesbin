#!/bin/zsh
OPTS=()
startsWithDash ${1} && OPTS+=${1} && shift

_handshake () {
	echo ${OPTS} "${1} ${UC_HANDSHAKE} ${2}"
}
_handshake ${@}
