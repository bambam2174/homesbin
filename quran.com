#!/bin/zsh

SCRIPTNAME="$(filename ${0})"
OPEN_IN_BROWSER=false

usage() {
    ecko "${SCRIPTNAME}  [N\\$UNICODE_ORDINAL_MALE of Sura]  [N\\$UNICODE_ORDINAL_MALE of Ayat]" 12 55
    ecko "Example" 55 12
    ecko "${SCRIPTNAME}  1 2" 13 55
    ecko "for the 1st sura's 2nd ayat (El-Fatiha's 2nd ayat)" 55 13
}
startsWithDash "${1}" && [ ${1/-/} = 'o' -o  ${1/-/} = '-open' ] && OPEN_IN_BROWSER=true && shift 

if [[ ${#} -eq 2 ]] && isNumeric ${1} && isNumeric ${2}
then
    URL2AYAT="https://quran.com/${1}?startingVerse=${2}"
else
    usage && . rexexit 99
fi

${OPEN_IN_BROWSER} && browser "${URL2AYAT}" || echo "${URL2AYAT}"
