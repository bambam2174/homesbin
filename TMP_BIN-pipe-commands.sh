#==> /Users/sedatkilinc/bin/tmp/pipe-exec <==
#!/bin/zsh

SCRIPT_DIR="$(filedir ${0})"
export PATH="${SCRIPT_DIR}:${PATH}"

. pipeout-test # sets INPUT_PIPE

echo "${INPUT_PIPE}"

==> /Users/sedatkilinc/bin/tmp/pipe-stuff <==
#!/bin/zsh

SCRIPT_DIR="$(filedir ${0})"
export PATH="${SCRIPT_DIR}:${PATH}"

. pipeout-test # sets INPUT_PIPE

echo "${INPUT_PIPE}"

==> /Users/sedatkilinc/bin/tmp/pipedo <==
#!/bin/zsh

isDebug && echo ${@}

if [[ ${#} -gt 0 ]]
then
    local CNT=0
    for TMP_PATH in "${@}"
    do
        isDebug && echo "Pfad Nr.$((CNT+=1)) ${TMP_PATH}"
        ARR_PATH=("${TMP_PATH}")
    done
else
    INPUT_PIPE="$(cat < /dev/stdin)"
    [[ -n ${INPUT_PIPE} ]] && ARR_PATH=($(echo ${INPUT_PIPE}))
fi

for currPath in ${ARR_PATH}
do
    original dirname ${currPath}
done



==> /Users/sedatkilinc/bin/tmp/pipeout-test <==
#!/bin/zsh

INPUT_PIPE="$(cat < /dev/stdin)"

#echo ${INPUT_PIPE} # | rev | cut -d ' ' -f1 | rev
