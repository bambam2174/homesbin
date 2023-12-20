#!/bin/zsh

source $HOME/.bash_vars
source $HOME/.bash_aliases
ufunc

SP='./' 
if isDebug
then
	echo $#
fi
PARAMCOUNT=$# 
if [ -n $2 ]
then
	SP=$(abspath $2) 
	PARAMCOUNT=3 
fi
if [ $# -gt 2 ]
then
	_OPTION="-name" 
else
	_OPTION="-iname" 
fi
if isDebug && [ -n "$COLOR_Cyan" ]
then
	printf "${COLOR_LightGreen}find ${COLOR_Yellow}$SP ${COLOR_Cyan}$_OPTION ${COLOR_LightCyan}\"*${COLOR_LightGreen}$1${COLOR_LightCyan}*\"${COLOR_NC} ${@:$PARAMCOUNT}"
elif isDebug
then
	echo "find $SP $_OPTION \"*$1*\" ${@:$PARAMCOUNT}"
fi
echo
CMD=$(find $SP $_OPTION "*$1*"  | tee -a "/var/log/find/$1.log") 
printf "${COLOR_Cyan}$CMD"