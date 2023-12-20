#!/bin/zsh

echo $(alias | wc -l) > /dev/stdin

alias | grep ${@}
