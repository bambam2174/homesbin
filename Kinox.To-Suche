#!/bin/zsh#

source ~/.debug_state
source ~/.bash_aliases

isDebug && echo $#

if [ -n "$1" ]; then
	KEYWORD="$1"
else
	KEYWORD=$(pbpaste)
fi

SEARCH=${KEYWORD// /%20}

URL="https://kinox.to/Search.html?q="
SEARCH_URL="${URL}${SEARCH}"

isDebug && echo $SEARCH_URL

chrome "$SEARCH_URL"
