	if ! [ -z $1 ]
	then
		git log --pretty=$1
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local osname osver version_file version_files
	case "$OSTYPE" in
		(darwin*) osname=$(command sw_vers -productName) 
			osver=$(command sw_vers -productVersion) 
			builtin echo "OS Version: $osname $osver build $(sw_vers -buildVersion)" ;;
		(cygwin) command systeminfo | command head -4 | command tail -2 ;;
	esac
	if builtin which lsb_release > /dev/null
	then
		builtin echo "OS Release: $(command lsb_release -s -d)"
	fi
	version_files=(/etc/*-release(N) /etc/*-version(N) /etc/*_version(N)) 
	for version_file in $version_files
	do
		builtin echo "$version_file:"
		command cat "$version_file"
		builtin echo
	done builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	for code in {000..255}
	do
		print -P -- "$code: %{$BG[$code]%}$ZSH_SPECTRUM_TEXT%{$reset_color%}"
	done builtin autoload -XU builtin autoload -XU builtin autoload -XU 	if [ "$1" -le 0 ] 2> /dev/null || [ "$1" -gt 0 ] 2> /dev/null
	then
		return 1
	else
		return 0
	fi 	ITERM2_PRECMD_PS1="$PS1" 
	ITERM2_SHOULD_DECORATE_PROMPT="" 
	local PREFIX="" 
	if [[ $PS1 == *"$(iterm2_prompt_mark)"* ]]
	then
		PREFIX="" 
	elif [[ "${ITERM2_SQUELCH_MARK-}" != "" ]]
	then
		PREFIX="" 
	else
		PREFIX="%{$(iterm2_prompt_mark)%}" 
	fi
	PS1="$PREFIX$PS1%{$(iterm2_prompt_end)%}"  builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	(( $+commands[hg] )) || return
	local rev st branch
	if $(hg id >/dev/null 2>&1)
	then
		if $(hg prompt >/dev/null 2>&1)
		then
			if [[ $(hg prompt "{status|unknown}") = "?" ]]
			then
				prompt_segment red white
				st='±' 
			elif [[ -n $(hg prompt "{status|modified}") ]]
			then
				prompt_segment yellow black
				st='±' 
			else
				prompt_segment green $CURRENT_FG
			fi
			echo -n $(hg prompt "☿ {rev}@{branch}") $st
		else
			st="" 
			rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g') 
			branch=$(hg id -b 2>/dev/null) 
			if `hg st | grep -q "^\?"`
			then
				prompt_segment red black
				st='±' 
			elif `hg st | grep -q "^[MA]"`
			then
				prompt_segment yellow black
				st='±' 
			else
				prompt_segment green $CURRENT_FG
			fi
			echo -n "☿ $rev@$branch" $st
		fi
	fi builtin autoload -XU 	if command git rev-parse --git-dir &> /dev/null
	then
		local commits="$(git rev-list --count @{upstream}..HEAD 2>/dev/null)" 
		if [[ -n "$commits" && "$commits" != 0 ]]
		then
			echo "$ZSH_THEME_GIT_COMMITS_AHEAD_PREFIX$commits$ZSH_THEME_GIT_COMMITS_AHEAD_SUFFIX"
		fi
	fi builtin autoload -XU builtin autoload -XU 	git log --pretty=format: --name-status | cut -f2- | sort -u builtin autoload -XU 	local IFS=$' 	
 ' 
	eval "$_comp_setup"
	local func funcs ret=1 tmp _compskip format nm call match min max i num _completers _completer _completer_num curtag _comp_force_list _matchers _matcher _c_matcher _matcher_num _comp_tags _comp_mesg mesg str context state state_descr line opt_args val_args curcontext="$curcontext" _last_nmatches=-1 _last_menu_style _def_menu_style _menu_style sel _tags_level=0 _saved_exact="${compstate[exact]}" _saved_lastprompt="${compstate[last_prompt]}" _saved_list="${compstate[list]}" _saved_insert="${compstate[insert]}" _saved_colors="$ZLS_COLORS" _saved_colors_set=${+ZLS_COLORS} _ambiguous_color='' 
	local _comp_priv_prefix
	unset _comp_priv_prefix
	local -a precommands
	typeset -U _lastdescr _comp_ignore _comp_colors
	{
		[[ -z "$curcontext" ]] && curcontext=::: 
		zstyle -s ":completion:${curcontext}:" insert-tab tmp || tmp=yes 
		if [[ ( "$tmp" = *pending(|[[:blank:]]*) && PENDING -gt 0 ) || ( "$tmp" = *pending=(#b)([0-9]##)(|[[:blank:]]*) && PENDING -ge $match[1] ) ]]
		then
			compstate[insert]=tab 
			return 0
		fi
		if [[ "$compstate[insert]" = tab* ]]
		then
			if [[ "$tmp" = (|*[[:blank:]])(yes|true|on|1)(|[[:blank:]]*) ]]
			then
				if [[ "$curcontext" != :* || -z "$compstate[vared]" ]] || zstyle -t ":completion:vared${curcontext}:" insert-tab
				then
					return 0
				fi
			fi
			compstate[insert]="${compstate[insert]//tab /}" 
		fi
		if [[ "$compstate[pattern_match]" = "*" && "$_lastcomp[unambiguous]" = "$PREFIX" && -n "$_lastcomp[unambiguous_cursor]" ]]
		then
			integer upos="$_lastcomp[unambiguous_cursor]" 
			SUFFIX="$PREFIX[upos,-1]$SUFFIX" 
			PREFIX="$PREFIX[1,upos-1]" 
		fi
		if [[ -z "$compstate[quote]" ]]
		then
			if [[ -o equals ]] && compset -P 1 '='
			then
				compstate[context]=equal 
			elif [[ "$PREFIX" != */* && "$PREFIX[1]" = '~' ]]
			then
				compset -p 1
				compstate[context]=tilde 
			fi
		fi
		_setup default
		_def_menu_style=("$_last_menu_style[@]") 
		_last_menu_style=() 
		if zstyle -s ":completion:${curcontext}:default" list-prompt tmp
		then
			LISTPROMPT="$tmp" 
			zmodload -i zsh/complist
		fi
		if zstyle -s ":completion:${curcontext}:default" select-prompt tmp
		then
			MENUPROMPT="$tmp" 
			zmodload -i zsh/complist
		fi
		if zstyle -s ":completion:${curcontext}:default" select-scroll tmp
		then
			MENUSCROLL="$tmp" 
			zmodload -i zsh/complist
		fi
		if (( $# ))
		then
			if [[ "$1" = - ]]
			then
				if [[ $# -lt 3 ]]
				then
					_completers=() 
				else
					_completers=("$2") 
					call=yes 
				fi
			else
				_completers=("$@") 
			fi
		else
			zstyle -a ":completion:${curcontext}:" completer _completers || _completers=(_complete _ignored) 
		fi
		_completer_num=1 
		integer SECONDS=0 
		TRAPINT () {
			zle -M "Killed by signal in ${funcstack[2]} after ${SECONDS}s"
			zle -R
			return 130
		}
		TRAPQUIT () {
			zle -M "Killed by signal in ${funcstack[2]} after ${SECONDS}s"
			zle -R
			return 131
		}
		funcs=("$compprefuncs[@]") 
		compprefuncs=() 
		for func in "$funcs[@]"
		do
			"$func"
		done
		for tmp in "$_completers[@]"
		do
			if [[ -n "$call" ]]
			then
				_completer="${tmp}" 
			elif [[ "$tmp" = *:-* ]]
			then
				_completer="${${tmp%:*}[2,-1]//_/-}${tmp#*:}" 
				tmp="${tmp%:*}" 
			elif [[ $tmp = *:* ]]
			then
				_completer="${tmp#*:}" 
				tmp="${tmp%:*}" 
			else
				_completer="${tmp[2,-1]//_/-}" 
			fi
			curcontext="${curcontext/:[^:]#:/:${_completer}:}" 
			zstyle -t ":completion:${curcontext}:" show-completer && zle -R "Trying completion for :completion:${curcontext}"
			zstyle -a ":completion:${curcontext}:" matcher-list _matchers || _matchers=('') 
			_matcher_num=1 
			_matcher='' 
			for _c_matcher in "$_matchers[@]"
			do
				if [[ "$_c_matcher" == +* ]]
				then
					_matcher="$_matcher $_c_matcher[2,-1]" 
				else
					_matcher="$_c_matcher" 
				fi
				_comp_mesg= 
				if [[ -n "$call" ]]
				then
					if "${(@)argv[3,-1]}"
					then
						ret=0 
						break 2
					fi
				elif "$tmp"
				then
					ret=0 
					break 2
				fi
				(( _matcher_num++ ))
			done
			[[ -n "$_comp_mesg" ]] && break
			(( _completer_num++ ))
		done
		curcontext="${curcontext/:[^:]#:/::}" 
		if [[ $compstate[old_list] = keep ]]
		then
			nm=$_lastcomp[nmatches] 
		else
			nm=$compstate[nmatches] 
		fi
		if [[ $compstate[old_list] = keep || nm -gt 1 ]]
		then
			[[ _last_nmatches -ge 0 && _last_nmatches -ne nm ]] && _menu_style=("$_last_menu_style[@]" "$_menu_style[@]") 
			tmp=$(( compstate[list_lines] + BUFFERLINES + 1 )) 
			_menu_style=("$_menu_style[@]" "$_def_menu_style[@]") 
			if [[ "$compstate[list]" = *list && tmp -gt LINES && ( -n "$_menu_style[(r)select=long-list]" || -n "$_menu_style[(r)(yes|true|on|1)=long-list]" ) ]]
			then
				compstate[insert]=menu 
			elif [[ "$compstate[insert]" = "$_saved_insert" ]]
			then
				if [[ -n "$compstate[insert]" && -n "$_menu_style[(r)(yes|true|1|on)=long]" && tmp -gt LINES ]]
				then
					compstate[insert]=menu 
				else
					sel=("${(@M)_menu_style:#(yes|true|1|on)*}") 
					if (( $#sel ))
					then
						min=9999999 
						for i in "$sel[@]"
						do
							if [[ "$i" = *\=[0-9]* ]]
							then
								num="${i#*\=}" 
								[[ num -lt 0 ]] && num=0 
							elif [[ "$i" != *\=* ]]
							then
								num=0 
							else
								num=9999999 
							fi
							[[ num -lt min ]] && min="$num" 
							(( min )) || break
						done
					fi
					sel=("${(@M)_menu_style:#(no|false|0|off)*}") 
					if (( $#sel ))
					then
						max=9999999 
						for i in "$sel[@]"
						do
							if [[ "$i" = *\=[0-9]* ]]
							then
								num="${i#*\=}" 
								[[ num -lt 0 ]] && num=0 
							elif [[ "$i" != *\=* ]]
							then
								num=0 
							else
								num=9999999 
							fi
							[[ num -lt max ]] && max="$num" 
							(( max )) || break
						done
					fi
					if [[ ( -n "$min" && nm -ge min && ( -z "$max" || nm -lt max ) ) || ( -n "$_menu_style[(r)auto*]" && "$compstate[insert]" = automenu ) ]]
					then
						compstate[insert]=menu 
					elif [[ -n "$max" && nm -ge max ]]
					then
						compstate[insert]=unambiguous 
					elif [[ -n "$_menu_style[(r)auto*]" && "$compstate[insert]" != automenu ]]
					then
						compstate[insert]=automenu-unambiguous 
					fi
				fi
			fi
			if [[ "$compstate[insert]" = *menu* ]]
			then
				[[ "$MENUSELECT" = 00 ]] && MENUSELECT=0 
				if [[ -n "$_menu_style[(r)no-select*]" ]]
				then
					unset MENUSELECT
				elif [[ -n "$_menu_style[(r)select=long*]" ]]
				then
					if [[ tmp -gt LINES ]]
					then
						zmodload -i zsh/complist
						MENUSELECT=00 
					fi
				fi
				if [[ "$MENUSELECT" != 00 ]]
				then
					sel=("${(@M)_menu_style:#select*}") 
					if (( $#sel ))
					then
						min=9999999 
						for i in "$sel[@]"
						do
							if [[ "$i" = *\=[0-9]* ]]
							then
								num="${i#*\=}" 
								[[ num -lt 0 ]] && num=0 
							elif [[ "$i" != *\=* ]]
							then
								num=0 
							else
								num=9999999 
							fi
							[[ num -lt min ]] && min="$num" 
							(( min )) || break
						done
						zmodload -i zsh/complist
						MENUSELECT="$min" 
					else
						unset MENUSELECT
					fi
				fi
				if [[ -n "$MENUSELECT" ]]
				then
					if [[ -n "$_menu_style[(r)interactive*]" ]]
					then
						MENUMODE=interactive 
					elif [[ -n "$_menu_style[(r)search*]" ]]
					then
						if [[ -n "$_menu_style[(r)*backward*]" ]]
						then
							MENUMODE=search-backward 
						else
							MENUMODE=search-forward 
						fi
					else
						unset MENUMODE
					fi
				fi
			fi
		elif [[ nm -lt 1 && -n "$_comp_mesg" ]]
		then
			compstate[insert]='' 
			compstate[list]='list force' 
		elif [[ nm -eq 0 && -z "$_comp_mesg" && $#_lastdescr -ne 0 && $compstate[old_list] != keep ]] && zstyle -s ":completion:${curcontext}:warnings" format format
		then
			compstate[list]='list force' 
			compstate[insert]='' 
			tmp=("\`${(@)^_lastdescr:#}'") 
			case $#tmp in
				(1) str="$tmp[1]"  ;;
				(2) str="$tmp[1] or $tmp[2]"  ;;
				(*) str="${(j:, :)tmp[1,-2]}, or $tmp[-1]"  ;;
			esac
			_setup warnings
			zformat -f mesg "$format" "d:$str" "D:${(F)${(@)_lastdescr:#}}"
			compadd -x "$mesg"
		fi
		if [[ -n "$_ambiguous_color" ]]
		then
			local toquote='[=\(\)\|~^?*[\]#<>]' 
			local prefix=${${compstate[unambiguous]}[1,${compstate[unambiguous_cursor]}-1]} 
			[[ -n $prefix ]] && _comp_colors+=("=(#i)${prefix[1,-2]//?/(}${prefix[1,-2]//(#m)?/${MATCH/$~toquote/\$MATCH}|)}${prefix[-1]//(#m)$~toquote/\$MATCH}(#b)(?|)*==$_ambiguous_color") 
		fi
		[[ "$_comp_force_list" = always || ( "$_comp_force_list" = ?* && nm -ge _comp_force_list ) ]] && compstate[list]="${compstate[list]//messages} force" 
	} always {
		if [[ "$compstate[old_list]" = keep ]]
		then
			if [[ $_saved_colors_set = 1 ]]
			then
				ZLS_COLORS="$_saved_colors" 
			else
				unset ZLS_COLORS
			fi
		elif (( $#_comp_colors ))
		then
			ZLS_COLORS="${(j.:.)_comp_colors}" 
		else
			unset ZLS_COLORS
		fi
	}
	funcs=("$comppostfuncs[@]") 
	comppostfuncs=() 
	for func in "$funcs[@]"
	do
		"$func"
	done
	_lastcomp=("${(@kv)compstate}") 
	_lastcomp[nmatches]=$nm 
	_lastcomp[completer]="$_completer" 
	_lastcomp[prefix]="$PREFIX" 
	_lastcomp[suffix]="$SUFFIX" 
	_lastcomp[iprefix]="$IPREFIX" 
	_lastcomp[isuffix]="$ISUFFIX" 
	_lastcomp[qiprefix]="$QIPREFIX" 
	_lastcomp[qisuffix]="$QISUFFIX" 
	_lastcomp[tags]="$_comp_tags" 
	return ret builtin autoload -XU builtin autoload -XU 	set +e 	_alternative 'files: :_files' 'urls: :_urls' 	local INDEX STATUS
	INDEX=$(command git status --porcelain -b 2> /dev/null) 
	STATUS="" 
	if $(echo "$INDEX" | command grep -E '^\?\? ' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_UNTRACKED$STATUS" 
	fi
	if $(echo "$INDEX" | grep '^A  ' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_ADDED$STATUS" 
	elif $(echo "$INDEX" | grep '^M  ' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_ADDED$STATUS" 
	elif $(echo "$INDEX" | grep '^MM ' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_ADDED$STATUS" 
	fi
	if $(echo "$INDEX" | grep '^ M ' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_MODIFIED$STATUS" 
	elif $(echo "$INDEX" | grep '^AM ' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_MODIFIED$STATUS" 
	elif $(echo "$INDEX" | grep '^MM ' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_MODIFIED$STATUS" 
	elif $(echo "$INDEX" | grep '^ T ' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_MODIFIED$STATUS" 
	fi
	if $(echo "$INDEX" | grep '^R  ' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_RENAMED$STATUS" 
	fi
	if $(echo "$INDEX" | grep '^ D ' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_DELETED$STATUS" 
	elif $(echo "$INDEX" | grep '^D  ' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_DELETED$STATUS" 
	elif $(echo "$INDEX" | grep '^AD ' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_DELETED$STATUS" 
	fi
	if $(command git rev-parse --verify refs/stash >/dev/null 2>&1)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_STASHED$STATUS" 
	fi
	if $(echo "$INDEX" | grep '^UU ' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_UNMERGED$STATUS" 
	fi
	if $(echo "$INDEX" | grep '^## [^ ]\+ .*ahead' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_AHEAD$STATUS" 
	fi
	if $(echo "$INDEX" | grep '^## [^ ]\+ .*behind' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_BEHIND$STATUS" 
	fi
	if $(echo "$INDEX" | grep '^## [^ ]\+ .*diverged' &> /dev/null)
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_DIVERGED$STATUS" 
	fi
	echo $STATUS 	if command git rev-parse --git-dir &> /dev/null
	then
		local commits="$(git rev-list --count HEAD..@{upstream} 2>/dev/null)" 
		if [[ -n "$commits" && "$commits" != 0 ]]
		then
			echo "$ZSH_THEME_GIT_COMMITS_BEHIND_PREFIX$commits$ZSH_THEME_GIT_COMMITS_BEHIND_SUFFIX"
		fi
	fi builtin autoload -XU 	emulate -L zsh
	local encoded_url=$1 
	local caller_encoding=$langinfo[CODESET] 
	local LC_ALL=C 
	export LC_ALL
	local tmp=${encoded_url:gs/+/ /} 
	tmp=${tmp:gs/\/\\/} 
	tmp=${tmp:gs/%/\x/} 
	local decoded
	eval "decoded=\$'$tmp'"
	local safe_encodings
	safe_encodings=(UTF-8 utf8 US-ASCII) 
	if [[ -z ${safe_encodings[(r)$caller_encoding]} ]]
	then
		decoded=$(echo -E "$decoded" | iconv -f UTF-8 -t $caller_encoding) 
		if [[ $? != 0 ]]
		then
			echo "Error converting string from UTF-8 to $caller_encoding" >&2
			return 1
		fi
	fi
	echo -E "$decoded" builtin autoload -XU builtin autoload -XU 	for i in {0..15}
	do
		if [ $i -eq 10 ]
		then
			i=A 
		elif [ $i -eq 11 ]
		then
			i=B 
		elif [ $i -eq 12 ]
		then
			i=C 
		elif [ $i -eq 13 ]
		then
			i=D 
		elif [ $i -eq 14 ]
		then
			i=E 
		elif [ $i -eq 15 ]
		then
			i=F 
		fi
		echo "0x$i"
	done 	TARGET="$HOME/Desktop/LINKS/" 
	if [ -n "$2" ]
	then
		TARGET="$TARGET/$2" 
		echo $TARGET
		if ! [ -d " $TARGET" ]
		then
			mkdir $(dirname $TARGET)
		fi
	fi
	echo "$TARGET"
	createlink "$1" "$TARGET" builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	pARRAY="$1" 
	IFS=$'
' 
	echo "${pARRAY[@]}" builtin autoload -XU builtin autoload -XU builtin autoload -XU 	fmp2 () {
		nautilus "$@"
	}
	for fname in "$@"
	do
		fmp2 "$fname"
	done 	if [[ -n $1 ]]
	then
		dirs "$@"
	else
		dirs -v | head -10
	fi builtin autoload -XU 	touch "/var/log/find/$1.log"
	if [ $# -eq 1 ]
	then
		find . -iname "*$1*" | tee -a "/var/log/find/$1.log"
	fi
	PARAM=$1 
	f_it () {
		touch "/var/log/find/$PARAM.log"
		find "$@" -iname "*$PARAM*" | tee -a "/var/log/find/$PARAM.log"
	}
	shift
	for fname in "$@"
	do
		f_it "$fname"
	done 	for i in "$@"
	do
		[ -d "$i" ] && echo "$i is directory" || echo "$i is file"
	done builtin autoload -XU 	echo -e "\033[1;36m[INFO]\033[0m  $*" builtin autoload -XU builtin autoload -XU 	PARAM=$1 
	r_it () {
		grep -irl $PARAM "$@"
	}
	shift
	for fname in "$@"
	do
		r_it "$fname"
	done builtin autoload -XU 	local expl pattern fakes faked tmp pfilt
	if compset -P '*:'
	then
		_history_modifiers p
		return
	fi
	pattern=(-g \*) 
	zparseopts -D -K -E g:=pattern
	fakes=() 
	faked=() 
	if zstyle -a ":completion:${curcontext}:" fake-parameters tmp
	then
		for i in "$tmp[@]"
		do
			if [[ "$i" = *:* ]]
			then
				faked=("$faked[@]" "$i") 
			else
				fakes=("$fakes[@]" "$i") 
			fi
		done
	fi
	zstyle -t ":completion:${curcontext}:parameters" prefix-needed && [[ $PREFIX != [_.]* ]] && pfilt='[^_.]' 
	_wanted parameters expl parameter compadd "$@" -Q - "${(@M)${(@k)parameters[(R)${pattern[2]}~*local*]}:#${~pfilt}*}" "$fakes[@]" "${(@)${(@M)faked:#${~pattern[2]}}%%:*}" builtin autoload -XU builtin autoload -XU 	emulate -L zsh
	zparseopts -D -E -a opts r m P
	local in_str=$1 
	local url_str="" 
	local spaces_as_plus
	if [[ -z $opts[(r)-P] ]]
	then
		spaces_as_plus=1 
	fi
	local str="$in_str" 
	local encoding=$langinfo[CODESET] 
	local safe_encodings
	safe_encodings=(UTF-8 utf8 US-ASCII) 
	if [[ -z ${safe_encodings[(r)$encoding]} ]]
	then
		str=$(echo -E "$str" | iconv -f $encoding -t UTF-8) 
		if [[ $? != 0 ]]
		then
			echo "Error converting string from $encoding to UTF-8" >&2
			return 1
		fi
	fi
	local i byte ord LC_ALL=C 
	export LC_ALL
	local reserved=';/?:@&=+$,' 
	local mark='_.!~*''()-' 
	local dont_escape="[A-Za-z0-9" 
	if [[ -z $opts[(r)-r] ]]
	then
		dont_escape+=$reserved 
	fi
	if [[ -z $opts[(r)-m] ]]
	then
		dont_escape+=$mark 
	fi
	dont_escape+="]" 
	local url_str="" 
	for ((i = 1; i <= ${#str}; ++i )) do
		byte="$str[i]" 
		if [[ "$byte" =~ "$dont_escape" ]]
		then
			url_str+="$byte" 
		else
			if [[ "$byte" == " " && -n $spaces_as_plus ]]
			then
				url_str+="+" 
			else
				ord=$(( [##16] #byte )) 
				url_str+="%$ord" 
			fi
		fi
	done
	echo -E "$url_str" 	local file=$1 
	if [[ -f $file || -h $file ]]
	then
		builtin echo "========== $file =========="
		if [[ -h $file ]]
		then
			builtin echo "==========    ( => ${file:A} )   =========="
		fi
		command cat $file
		builtin echo "========== end $file =========="
		builtin echo
	elif [[ -d $file ]]
	then
		builtin echo "File '$file' is a directory"
	elif [[ ! -e $file ]]
	then
		builtin echo "File '$file' does not exist"
	else
		command ls -lad "$file"
	fi builtin autoload -XU 	echo "cannot $*"
	sleep 1
	die "$*" builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	emulate -L zsh
	local file=$1 
	if [[ $OSTYPE == darwin* ]]
	then
		if [[ -z $file ]]
		then
			pbcopy
		else
			cat $file | pbcopy
		fi
	elif [[ $OSTYPE == cygwin* ]]
	then
		if [[ -z $file ]]
		then
			cat > /dev/clipboard
		else
			cat $file > /dev/clipboard
		fi
	else
		if (( $+commands[xclip] ))
		then
			if [[ -z $file ]]
			then
				xclip -in -selection clipboard
			else
				xclip -in -selection clipboard $file
			fi
		elif (( $+commands[xsel] ))
		then
			if [[ -z $file ]]
			then
				xsel --clipboard --input
			else
				cat "$file" | xsel --clipboard --input
			fi
		else
			print "clipcopy: Platform $OSTYPE not supported or xclip/xsel not installed" >&2
			return 1
		fi
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	(( $+commands[bzr] )) || return
	if (
			bzr status > /dev/null 2>&1
		)
	then
		status_mod=`bzr status | head -n1 | grep "modified" | wc -m` 
		status_all=`bzr status | head -n1 | wc -m` 
		revision=`bzr log | head -n2 | tail -n1 | sed 's/^revno: //'` 
		if [[ $status_mod -gt 0 ]]
		then
			prompt_segment yellow black
			echo -n "bzr@"$revision "✚ "
		else
			if [[ $status_all -gt 0 ]]
			then
				prompt_segment yellow black
				echo -n "bzr@"$revision
			else
				prompt_segment green black
				echo -n "bzr@"$revision
			fi
		fi
	fi builtin autoload -XU 	cp -i *.imageset/*.$1 $2 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	builtin echo "Core command check:"
	local redefined name builtins externals reserved_words
	redefined=() 
	reserved_words=(do done esac then elif else fi for case if while function repeat time until select coproc nocorrect foreach end '!' '[[' '{' '}') 
	builtins=(alias autoload bg bindkey break builtin bye cd chdir command comparguments compcall compctl compdescribe compfiles compgroups compquote comptags comptry compvalues continue dirs disable disown echo echotc echoti emulate enable eval exec exit false fc fg functions getln getopts hash jobs kill let limit log logout noglob popd print printf pushd pushln pwd r read rehash return sched set setopt shift source suspend test times trap true ttyctl type ulimit umask unalias unfunction unhash unlimit unset unsetopt vared wait whence where which zcompile zle zmodload zparseopts zregexparse zstyle) 
	if is-at-least 5.1
	then
		reserved_word+=(declare export integer float local readonly typeset) 
	else
		builtins+=(declare export integer float local readonly typeset) 
	fi
	builtins_fatal=(builtin command local) 
	externals=(zsh) 
	for name in $reserved_words
	do
		if [[ $(builtin whence -w $name) != "$name: reserved" ]]
		then
			builtin echo "reserved word '$name' has been redefined"
			builtin which $name
			redefined+=$name 
		fi
	done
	for name in $builtins
	do
		if [[ $(builtin whence -w $name) != "$name: builtin" ]]
		then
			builtin echo "builtin '$name' has been redefined"
			builtin which $name
			redefined+=$name 
		fi
	done
	for name in $externals
	do
		if [[ $(builtin whence -w $name) != "$name: command" ]]
		then
			builtin echo "command '$name' has been redefined"
			builtin which $name
			redefined+=$name 
		fi
	done
	if [[ -n "$redefined" ]]
	then
		builtin echo "SOME CORE COMMANDS HAVE BEEN REDEFINED: $redefined"
	else
		builtin echo "All core commands are defined normally"
	fi builtin autoload -XU 	iterm2_set_user_var gitBranch $((git branch 2> /dev/null) | grep \* | cut -c3-) builtin autoload -XU builtin autoload -XU 	local opt autol type func delete eval new i ret=0 cmd svc 
	local -a match mbegin mend
	emulate -L zsh
	setopt extendedglob
	if (( ! $# ))
	then
		print -u2 "$0: I need arguments"
		return 1
	fi
	while getopts "anpPkKde" opt
	do
		case "$opt" in
			(a) autol=yes  ;;
			(n) new=yes  ;;
			([pPkK]) if [[ -n "$type" ]]
				then
					print -u2 "$0: type already set to $type"
					return 1
				fi
				if [[ "$opt" = p ]]
				then
					type=pattern 
				elif [[ "$opt" = P ]]
				then
					type=postpattern 
				elif [[ "$opt" = K ]]
				then
					type=widgetkey 
				else
					type=key 
				fi ;;
			(d) delete=yes  ;;
			(e) eval=yes  ;;
		esac
	done
	shift OPTIND-1
	if (( ! $# ))
	then
		print -u2 "$0: I need arguments"
		return 1
	fi
	if [[ -z "$delete" ]]
	then
		if [[ -z "$eval" ]] && [[ "$1" = *\=* ]]
		then
			while (( $# ))
			do
				if [[ "$1" = *\=* ]]
				then
					cmd="${1%%\=*}" 
					svc="${1#*\=}" 
					func="$_comps[${_services[(r)$svc]:-$svc}]" 
					[[ -n ${_services[$svc]} ]] && svc=${_services[$svc]} 
					[[ -z "$func" ]] && func="${${_patcomps[(K)$svc][1]}:-${_postpatcomps[(K)$svc][1]}}" 
					if [[ -n "$func" ]]
					then
						_comps[$cmd]="$func" 
						_services[$cmd]="$svc" 
					else
						print -u2 "$0: unknown command or service: $svc"
						ret=1 
					fi
				else
					print -u2 "$0: invalid argument: $1"
					ret=1 
				fi
				shift
			done
			return ret
		fi
		func="$1" 
		[[ -n "$autol" ]] && autoload -Uz "$func"
		shift
		case "$type" in
			(widgetkey) while [[ -n $1 ]]
				do
					if [[ $# -lt 3 ]]
					then
						print -u2 "$0: compdef -K requires <widget> <comp-widget> <key>"
						return 1
					fi
					[[ $1 = _* ]] || 1="_$1" 
					[[ $2 = .* ]] || 2=".$2" 
					[[ $2 = .menu-select ]] && zmodload -i zsh/complist
					zle -C "$1" "$2" "$func"
					if [[ -n $new ]]
					then
						bindkey "$3" | IFS=$' 	' read -A opt
						[[ $opt[-1] = undefined-key ]] && bindkey "$3" "$1"
					else
						bindkey "$3" "$1"
					fi
					shift 3
				done ;;
			(key) if [[ $# -lt 2 ]]
				then
					print -u2 "$0: missing keys"
					return 1
				fi
				if [[ $1 = .* ]]
				then
					[[ $1 = .menu-select ]] && zmodload -i zsh/complist
					zle -C "$func" "$1" "$func"
				else
					[[ $1 = menu-select ]] && zmodload -i zsh/complist
					zle -C "$func" ".$1" "$func"
				fi
				shift
				for i
				do
					if [[ -n $new ]]
					then
						bindkey "$i" | IFS=$' 	' read -A opt
						[[ $opt[-1] = undefined-key ]] || continue
					fi
					bindkey "$i" "$func"
				done ;;
			(*) while (( $# ))
				do
					if [[ "$1" = -N ]]
					then
						type=normal 
					elif [[ "$1" = -p ]]
					then
						type=pattern 
					elif [[ "$1" = -P ]]
					then
						type=postpattern 
					else
						case "$type" in
							(pattern) if [[ $1 = (#b)(*)=(*) ]]
								then
									_patcomps[$match[1]]="=$match[2]=$func" 
								else
									_patcomps[$1]="$func" 
								fi ;;
							(postpattern) if [[ $1 = (#b)(*)=(*) ]]
								then
									_postpatcomps[$match[1]]="=$match[2]=$func" 
								else
									_postpatcomps[$1]="$func" 
								fi ;;
							(*) if [[ "$1" = *\=* ]]
								then
									cmd="${1%%\=*}" 
									svc=yes 
								else
									cmd="$1" 
									svc= 
								fi
								if [[ -z "$new" || -z "${_comps[$1]}" ]]
								then
									_comps[$cmd]="$func" 
									[[ -n "$svc" ]] && _services[$cmd]="${1#*\=}" 
								fi ;;
						esac
					fi
					shift
				done ;;
		esac
	else
		case "$type" in
			(pattern) unset "_patcomps[$^@]" ;;
			(postpattern) unset "_postpatcomps[$^@]" ;;
			(key) print -u2 "$0: cannot restore key bindings"
				return 1 ;;
			(*) unset "_comps[$^@]" ;;
		esac
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	return [ -d "$1" ] builtin autoload -XU 	[[ "$#" != 1 ]] && local b="$(git_current_branch)" 
	git push --force-with-lease origin "${b:=$1}" builtin autoload -XU builtin autoload -XU 	DEBUG=$TRUE  builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local stat f elt what dir
	local -a stylevals
	integer ok
	listfiles=() 
	listopts=() 
	zstyle -a ":completion:${curcontext}:" file-list stylevals || return 1
	case $WIDGETSTYLE in
		(*complete*) what=insert  ;;
		(*) what=list  ;;
	esac
	for elt in $stylevals
	do
		case $elt in
			(*($what|all|true|1|yes)*=<->) (( ${(P)#1} <= ${elt##*=} )) && (( ok = 1 ))
				break ;;
			([^=]#($what|all|true|1|yes)[^=]#) (( ok = 1 ))
				break ;;
		esac
	done
	(( ok )) || return 1
	zmodload -F zsh/stat b:zstat 2> /dev/null || return 1
	dir=${2:+$2/} 
	dir=${(Q)dir} 
	for f in ${(PQ)1}
	do
		if [[ ! -e "$dir$f" ]]
		then
			listfiles+=("$dir$f") 
			continue
		fi
		zstat -s -H stat -F "%b %e %H:%M" - "$dir$f" > /dev/null 2>&1
		listfiles+=("$stat[mode] ${(l:3:)stat[nlink]} ${(r:8:)stat[uid]}  ${(r:8:)stat[gid]} ${(l:8:)stat[size]} $stat[mtime] $f") 
	done
	(( ${#listfiles} )) && listopts=(-d listfiles -l -o) 
	return 0 	SP='./' 
	echo "$1"
	echo "$2"
	if [ -z $1 ]
	then
		echo "-z $1 true"
	else
		echo "-z $1 false"
	fi
	if [ -z $2 ]
	then
		echo "-z $2 true"
	else
		echo "-z $2 false"
	fi
	if [ -n $1 ]
	then
		echo "-n $1 true"
	else
		echo "-n $1 false"
	fi
	if [ -n $2 ]
	then
		echo "-n $2 true"
	else
		echo "-n $2 false"
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	_command_names
	local ret=$? 
	[[ -o autocd ]] && _cd || return ret builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local clear list
	zparseopts -E c=clear l=list
	if [[ -n "$clear" ]]
	then
		echo -n >| "$HISTFILE"
		echo History file deleted. Reload the session to see its effects. >&2
	elif [[ -n "$list" ]]
	then
		builtin fc "$@"
	else
		[[ ${@[-1]-} = *[0-9]* ]] && builtin fc -l "$@" || builtin fc -l "$@" 1
	fi builtin autoload -XU 	printf "]133;B" builtin autoload -XU builtin autoload -XU 	(( ${${(@f):-$(typeset +xg)}[(I)$1]} )) && return 0
	export "$1=$2" && return 3 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	_parameters -e builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	echo $(( $1 * -1  )) builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local -a args
	if _pick_variant gnu=GNU unix --version
	then
		args=('(-A --show-all)'{-A,--show-all}'[equivalent to -vET]' '(-b --number-nonblank -n --number)'{-b,--number-nonblank}'[number nonempty output lines, overrides -n]' '-e[equivalent to -vE]' '(-E --show-ends)'{-E,--show-ends}'[display $ at end of each line]' '(-n --number)'{-n,--number}'[number all output lines]' '(-s --squeeze-blank)'{-s,--squeeze-blank}'[suppress repeated empty output lines]' '-t[equivalent to -vT]' '(-T --show-tabs)'{-T,--show-tabs}'[display TAB characters as ^I]' '-u[ignored]' '(-v --show-nonprinting)'{-v,--show-nonprinting}'[use ^ and M- notation, except for LFD and TAB]' '(- : *)--help[display help and exit]' '(- : *)--version[output version information and exit]' '*: :_files') 
	elif [[ "$OSTYPE" == (*bsd|dragonfly|darwin)* ]]
	then
		args=(-A "-*" '(-n)-b[number non-blank output lines]' '(-v)-e[display $ at the end of each line (implies -v)]' '-n[number all output lines]' '-s[squeeze multiple blank lines into one]' '(-v)-t[display tab as ^I (implies -v)]' '-u[do not buffer output]' '-v[display non-printing chars as ^X or M-a]' '*: :_files') 
		[[ $OSTYPE = (free|net)bsd* ]] && args+=('-l[set a lock on the stdout file descriptor]') 
		[[ $OSTYPE = netbsd* ]] && args+=('-B+[read with buffer of specified size]:size (bytes)' '-f[only attempt to display regular files]') 
	elif [[ $OSTYPE = solaris* ]]
	then
		args=(-A "-*" '(-b)-n[number all output lines]' '(-n)-b[number non-blank output lines]' "-u[don't buffer output]" '-s[be silent about non-existent files]' '-v[display non-printing chars as ^X or M-a]' '-e[display $ at the end of each line (requires -v)]' '-t[display tab as ^I and formfeeds and ^L (requires -v)]' '*: :_files') 
	else
		args=('-n[number all output lines]' '-u[do not buffer output]' '*: :_files') 
	fi
	_arguments -s -S $args 	return 1 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local -a match mbegin mend
	local splitchars
	if zstyle -s ":completion:${curcontext}:" file-split-chars splitchars
	then
		compset -P "*[${(q)splitchars}]"
	fi
	if _have_glob_qual $PREFIX
	then
		local ret=1 
		compset -p ${#match[1]}
		compset -S '[^\)\|\~]#(|\))'
		if [[ $_comp_caller_options[extendedglob] == on ]] && compset -P '\#'
		then
			_globflags && ret=0 
		else
			if [[ $_comp_caller_options[extendedglob] == on ]]
			then
				local -a flags
				flags=('#:introduce glob flag') 
				_describe -t globflags "glob flag" flags -Q -S '' && ret=0 
			fi
			_globquals && ret=0 
		fi
		return ret
	fi
	local linepath realpath donepath prepath testpath exppath skips skipped
	local tmp1 tmp2 tmp3 tmp4 i orig eorig pre suf tpre tsuf opre osuf cpre
	local pats haspats ignore pfx pfxsfx sopt gopt opt sdirs ignpar cfopt listsfx
	local nm=$compstate[nmatches] menu matcher mopts sort mid accex fake 
	local listfiles listopts tmpdisp origtmp1 Uopt
	local accept_exact_dirs path_completion
	integer npathcheck
	local -a Mopts
	typeset -U prepaths exppaths
	exppaths=() 
	zparseopts -a mopts 'P:=pfx' 'S:=pfxsfx' 'q=pfxsfx' 'r:=pfxsfx' 'R:=pfxsfx' 'W:=prepaths' 'F:=ignore' 'M+:=matcher' J+: V+: X+: 1 2 n 'f=tmp1' '/=tmp1' 'g+:-=tmp1'
	sopt="-${(@j::M)${(@)tmp1#-}#?}" 
	(( $tmp1[(I)-[/g]*] )) && haspats=yes 
	(( $tmp1[(I)-g*] )) && gopt=yes 
	if (( $tmp1[(I)-/] ))
	then
		pats="${(@)${(@M)tmp1:#-g*}#-g}" 
		pats=('*(-/)' ${${(z):-x $pats}[2,-1]}) 
	else
		pats="${(@)${(@M)tmp1:#-g*}#-g}" 
		pats=(${${(z):-x $pats}[2,-1]}) 
	fi
	pats=("${(@)pats:# #}") 
	if (( $#pfx ))
	then
		compset -P "${(b)pfx[2]}" || pfxsfx=("$pfx[@]" "$pfxsfx[@]") 
	fi
	if (( $#prepaths ))
	then
		tmp1="${prepaths[2]}" 
		if [[ "$tmp1[1]" = '(' ]]
		then
			prepaths=(${^=tmp1[2,-2]%/}/) 
		elif [[ "$tmp1[1]" = '/' ]]
		then
			prepaths=("${tmp1%/}/") 
		else
			prepaths=(${(P)^tmp1%/}/) 
			(( ! $#prepaths )) && prepaths=(${tmp1%/}/) 
		fi
		(( ! $#prepaths )) && prepaths=('') 
	else
		prepaths=('') 
	fi
	if (( $#ignore ))
	then
		if [[ "${ignore[2]}" = \(* ]]
		then
			ignore=(${=ignore[2][2,-2]}) 
		else
			ignore=(${(P)ignore[2]}) 
		fi
	fi
	if [[ "$sopt" = -(f|) ]]
	then
		if [[ -z "$gopt" ]]
		then
			sopt='-f' 
			pats=('*') 
		else
			unset sopt
		fi
	fi
	if (( ! $mopts[(I)-[JVX]] ))
	then
		local expl
		if [[ -z "$gopt" && "$sopt" = -/ ]]
		then
			_description directories expl directory
		else
			_description files expl file
		fi
		tmp1=$expl[(I)-M*] 
		if (( tmp1 ))
		then
			if (( $#matcher ))
			then
				matcher[2]="$matcher[2] $expl[1+tmp1]" 
			else
				matcher=(-M "$expl[1+tmp1]") 
			fi
		fi
		mopts=("$mopts[@]" "$expl[@]") 
	fi
	[[ -z "$_comp_no_ignore" && $#ignore -eq 0 && ( -z $gopt || "$pats" = \ #\*\ # ) && -n $FIGNORE ]] && ignore=("?*${^fignore[@]}") 
	if (( $#ignore ))
	then
		_comp_ignore=("$_comp_ignore[@]" "$ignore[@]") 
		(( $mopts[(I)-F] )) || mopts=("$mopts[@]" -F _comp_ignore) 
	fi
	if [[ $#matcher -eq 0 && -o nocaseglob ]]
	then
		matcher=(-M 'm:{a-zA-Z}={A-Za-z}') 
	fi
	if (( $#matcher ))
	then
		mopts=("$mopts[@]" "$matcher[@]") 
	fi
	if zstyle -s ":completion:${curcontext}:" file-sort tmp1
	then
		case "$tmp1" in
			(*size*) sort=oL  ;;
			(*links*) sort=ol  ;;
			(*(time|date|modi)*) sort=om  ;;
			(*access*) sort=oa  ;;
			(*(inode|change)*) sort=oc  ;;
			(*) sort=on  ;;
		esac
		[[ "$tmp1" = *rev* ]] && sort[1]=O 
		[[ "$tmp1" = *follow* ]] && sort="-${sort}-" 
		if [[ "$sort" = on ]]
		then
			sort= 
		else
			mopts=("${(@)mopts/#-J/-V}") 
			tmp2=() 
			for tmp1 in "$pats[@]"
			do
				if _have_glob_qual "$tmp1" complete
				then
					tmp2+=("${match[1]}#q${sort})(${match[5]})") 
				else
					tmp2+=("${tmp1}(${sort})") 
				fi
			done
			pats=("$tmp2[@]") 
		fi
	fi
	if zstyle -t ":completion:${curcontext}:paths" squeeze-slashes
	then
		skips='((.|..|)/)##' 
	else
		skips='((.|..)/)##' 
	fi
	zstyle -s ":completion:${curcontext}:paths" special-dirs sdirs
	zstyle -t ":completion:${curcontext}:paths" list-suffixes && listsfx=yes 
	[[ "$pats" = ((|*[[:blank:]])\*(|[[:blank:]]*|\([^[:blank:]]##\))|*\([^[:blank:]]#/[^[:blank:]]#\)*) ]] && sopt=$sopt/ 
	zstyle -a ":completion:${curcontext}:paths" accept-exact accex
	zstyle -a ":completion:${curcontext}:" fake-files fake
	zstyle -s ":completion:${curcontext}:" ignore-parents ignpar
	zstyle -t ":completion:${curcontext}:paths" accept-exact-dirs && accept_exact_dirs=1 
	zstyle -T ":completion:${curcontext}:paths" path-completion && path_completion=1 
	if [[ -n "$compstate[pattern_match]" ]]
	then
		if {
				[[ -z "$SUFFIX" ]] && _have_glob_qual "$PREFIX" complete
			} || _have_glob_qual "$SUFFIX" complete
		then
			tmp3=${match[5]} 
			if [[ -n "$SUFFIX" ]]
			then
				SUFFIX=${match[2]} 
			else
				PREFIX=${match[2]} 
			fi
			tmp2=() 
			for tmp1 in "$pats[@]"
			do
				if _have_glob_qual "$tmp1" complete
				then
					tmp2+=("${match[1]}${tmp3}${match[5]})") 
				else
					tmp2+=("${tmp1}(${tmp3})") 
				fi
			done
			pats=("$tmp2[@]") 
		fi
	fi
	pre="$PREFIX" 
	suf="$SUFFIX" 
	opre="$PREFIX" 
	osuf="$SUFFIX" 
	orig="${PREFIX}${SUFFIX}" 
	eorig="$orig" 
	[[ $compstate[insert] = (*menu|[0-9]*) || -n "$_comp_correct" || ( -n "$compstate[pattern_match]" && "${orig#\~}" != (|*[^\])[][*?#~^\|\<\>]* ) ]] && menu=yes 
	if [[ -n "$_comp_correct" ]]
	then
		cfopt=- 
		Uopt=-U 
	else
		Mopts=(-M "r:|/=* r:|=*") 
	fi
	if [[ "$pre" = [^][*?#^\|\<\>\]#(\`[^\`]#\`|\$)*/* && "$compstate[quote]" != \' ]]
	then
		linepath="${(M)pre##*\$[^/]##/}" 
		() {
			setopt localoptions nounset
			eval 'realpath=${(e)~linepath}' 2> /dev/null
		}
		[[ -z "$realpath" || "$realpath" = "$linepath" ]] && return 1
		pre="${pre#${linepath}}" 
		i='[^/]' 
		i="${#linepath//$i}" 
		orig="${orig[1,(in:i:)/][1,-2]}" 
		donepath= 
		prepaths=('') 
	elif [[ "$pre[1]" = \~ && "$compstate[quote]" = (|\`) ]]
	then
		linepath="${pre[2,-1]%%/*}" 
		if [[ -z "$linepath" ]]
		then
			realpath="${HOME%/}/" 
		elif [[ "$linepath" = ([-+]|)[0-9]## ]]
		then
			if [[ "$linepath" != [-+]* ]]
			then
				tmp1="$linepath" 
			else
				if [[ "$linepath" = -* ]]
				then
					tmp1=$(( $#dirstack $linepath )) 
				else
					tmp1=$linepath[2,-1] 
				fi
				[[ -o pushdminus ]] && tmp1=$(( $#dirstack - $tmp1 )) 
			fi
			if (( ! tmp1 ))
			then
				realpath=$PWD/ 
			elif [[ tmp1 -le $#dirstack ]]
			then
				realpath=$dirstack[tmp1]/ 
			else
				_message 'not enough directory stack entries'
				return 1
			fi
		elif [[ "$linepath" = [-+] ]]
		then
			realpath=${~:-\~$linepath}/ 
		else
			eval "realpath=~${linepath}/" 2> /dev/null
			if [[ -z "$realpath" ]]
			then
				_message "unknown user \`$linepath'"
				return 1
			fi
		fi
		linepath="~${linepath}/" 
		[[ "$realpath" = "$linepath" ]] && return 1
		pre="${pre#*/}" 
		orig="${orig#*/}" 
		donepath= 
		prepaths=('') 
	else
		linepath= 
		realpath= 
		if zstyle -s ":completion:${curcontext}:" preserve-prefix tmp1 && [[ -n "$tmp1" && "$pre" = (#b)(${~tmp1})* ]]
		then
			pre="$pre[${#match[1]}+1,-1]" 
			orig="$orig[${#match[1]}+1,-1]" 
			donepath="$match[1]" 
			prepaths=('') 
		elif [[ "$pre[1]" = / ]]
		then
			pre="$pre[2,-1]" 
			orig="$orig[2,-1]" 
			donepath='/' 
			prepaths=('') 
		else
			[[ "$pre" = (.|..)/* ]] && prepaths=('') 
			donepath= 
		fi
	fi
	for prepath in "$prepaths[@]"
	do
		skipped= 
		cpre= 
		if [[ ( -n $accept_exact_dirs || -z $path_completion ) && ${pre} = (#b)(*)/([^/]#) ]]
		then
			tmp1=${match[1]} 
			tpre=${match[2]} 
			tmp2=$tmp1 
			tmp1=${tmp1//(#b)\(?)/$match[1]} 
			tpre=${tpre//(#b)\([^\\]\[\^\~\(\)\#\*\?])/$match[1]} 
			tmp3=${donepath//(#b)\(?)/$match[1]} 
			while true
			do
				if [[ -z $path_completion || -d $prepath$realpath$tmp3$tmp2 ]]
				then
					tmp3=$tmp3$tmp1/ 
					donepath=${tmp3//(#b)([\\]\[\^\~\(\)\#\*\?])/\$match[1]} 
					pre=$tpre 
					break
				elif [[ $tmp1 = (#b)(*)/([^/]#) ]]
				then
					tmp1=$match[1] 
					tpre=$match[2]/$tpre 
				else
					break
				fi
			done
		fi
		tpre="$pre" 
		tsuf="$suf" 
		testpath="${donepath//(#b)\([\\]\[\^\~\(\)\#\*\?])/$match[1]}" 
		tmp2="${(M)tpre##${~skips}}" 
		tpre="${tpre#$tmp2}" 
		tmp1=("$prepath$realpath$donepath$tmp2") 
		(( npathcheck = 0 ))
		while true
		do
			origtmp1=("${tmp1[@]}") 
			if [[ "$tpre" = */* ]]
			then
				PREFIX="${tpre%%/*}" 
				SUFFIX= 
			else
				PREFIX="${tpre}" 
				SUFFIX="${tsuf%%/*}" 
			fi
			tmp2=("$tmp1[@]") 
			if [[ "$tpre$tsuf" = (#b)*/(*) ]]
			then
				if [[ -n "$fake${match[1]}" ]]
				then
					compfiles -P$cfopt tmp1 accex "$skipped" "$_matcher $matcher[2]" "$sdirs" fake
				else
					compfiles -P$cfopt tmp1 accex "$skipped" "$_matcher $matcher[2]" '' fake
				fi
			elif [[ "$sopt" = *[/f]* ]]
			then
				compfiles -p$cfopt tmp1 accex "$skipped" "$_matcher $matcher[2]" "$sdirs" fake "$pats[@]"
			else
				compfiles -p$cfopt tmp1 accex "$skipped" "$_matcher $matcher[2]" '' fake "$pats[@]"
			fi
			tmp1=($~tmp1)  2> /dev/null
			if [[ -n "$PREFIX$SUFFIX" ]]
			then
				if (( ! $#tmp1 && npathcheck == 0 ))
				then
					(( npathcheck = 1 ))
					for tmp3 in "$tmp2[@]"
					do
						if [[ -n $tmp3 && $tmp3 != */ ]]
						then
							tmp3+=/ 
						fi
						if [[ -e "$tmp3${(Q)PREFIX}${(Q)SUFFIX}" ]]
						then
							(( npathcheck = 2 ))
						fi
					done
					if (( npathcheck == 2 ))
					then
						tmp1=("$origtmp1[@]") 
						continue
					fi
				fi
				if (( ! $#tmp1 ))
				then
					tmp2=(${^${tmp2:#/}}/$PREFIX$SUFFIX) 
				elif [[ "$tmp1[1]" = */* ]]
				then
					if [[ -n "$_comp_correct" ]]
					then
						tmp2=("$tmp1[@]") 
						builtin compadd -D tmp1 "$matcher[@]" - "${(@)tmp1:t}"
						if [[ $#tmp1 -eq 0 ]]
						then
							tmp1=("$tmp2[@]") 
							compadd -D tmp1 "$matcher[@]" - "${(@)tmp2:t}"
						fi
					else
						tmp2=("$tmp1[@]") 
						compadd -D tmp1 "$matcher[@]" - "${(@)tmp1:t}"
					fi
				else
					tmp2=('') 
					compadd -D tmp1 "$matcher[@]" -a tmp1
				fi
				if (( ! $#tmp1 ))
				then
					if [[ "$tmp2[1]" = */* ]]
					then
						tmp2=("${(@)tmp2#${prepath}${realpath}}") 
						if [[ "$tmp2[1]" = */* ]]
						then
							tmp2=("${(@)tmp2:h}") 
							compquote tmp2
							if [[ "$tmp2" = */ ]]
							then
								exppaths=("$exppaths[@]" ${^tmp2}${tpre}${tsuf}) 
							else
								exppaths=("$exppaths[@]" ${^tmp2}/${tpre}${tsuf}) 
							fi
						elif [[ ${tpre}${tsuf} = */* ]]
						then
							exppaths=("$exppaths[@]" ${tpre}${tsuf}) 
						fi
					fi
					continue 2
				fi
			elif (( ! $#tmp1 ))
			then
				if [[ -z "$tpre$tsuf" && -n "$pre$suf" ]]
				then
					pfxsfx=(-S '' "$pfxsfx[@]") 
				elif [[ -n "$haspats" && -z "$tpre$tsuf$suf" && "$pre" = */ ]]
				then
					PREFIX="${opre}" 
					SUFFIX="${osuf}" 
					compadd -nQS '' - "$linepath$donepath$orig"
					tmp4=- 
				fi
				continue 2
			fi
			if [[ -n "$ignpar" && -z "$_comp_no_ignore" && "$tpre$tsuf" != */* && $#tmp1 -ne 0 && ( "$ignpar" != *dir* || "$pats" = '*(-/)' ) && ( "$ignpar" != *..* || "$tmp1[1]" = *../* ) ]]
			then
				compfiles -i tmp1 ignore "$ignpar" "$prepath$realpath$donepath"
				_comp_ignore+=(${(@)ignore#$prepath$realpath$donepath}) 
				(( $#_comp_ignore && ! $mopts[(I)-F] )) && mopts=("$mopts[@]" -F _comp_ignore) 
			fi
			if [[ "$tpre" = */* ]]
			then
				tpre="${tpre#*/}" 
			elif [[ "$tsuf" = */* ]]
			then
				tpre="${tsuf#*/}" 
				tsuf= 
			else
				break
			fi
			tmp2="${(M)tpre##${~skips}}" 
			if [[ -n "$tmp2" ]]
			then
				skipped="/$tmp2" 
				tpre="${tpre#$tmp2}" 
			else
				skipped=/ 
			fi
			(( npathcheck = 0 ))
		done
		tmp3="$pre$suf" 
		tpre="$pre" 
		tsuf="$suf" 
		if [[ -n "${prepath}${realpath}${testpath}" ]]
		then
			if [[ -o nocaseglob ]]
			then
				tmp1=("${(@)tmp1#(#i)${prepath}${realpath}${testpath}}") 
			else
				tmp1=("${(@)tmp1#${prepath}${realpath}${testpath}}") 
			fi
		fi
		while true
		do
			compfiles -r tmp1 "${(Q)tmp3}"
			tmp4=$? 
			if [[ "$tpre" = */* ]]
			then
				tmp2="${cpre}${tpre%%/*}" 
				PREFIX="${linepath}${donepath}${tmp2}" 
				SUFFIX="/${tpre#*/}${tsuf#*/}" 
			else
				tmp2="${cpre}${tpre}" 
				PREFIX="${linepath}${donepath}${tmp2}" 
				SUFFIX="${tsuf}" 
			fi
			if (( tmp4 ))
			then
				tmp2="$testpath" 
				if [[ -n "$linepath" ]]
				then
					compquote -p tmp2 tmp1
				elif [[ -n "$tmp2" ]]
				then
					compquote -p tmp1
					compquote tmp2
				else
					compquote tmp1 tmp2
				fi
				if [[ -z "$_comp_correct" && "$compstate[pattern_match]" = \* && -n "$listsfx" && "$tmp2" = (|*[^\])[][*?#~^\|\<\>]* ]]
				then
					PREFIX="$opre" 
					SUFFIX="$osuf" 
				fi
				if [[ -z "$compstate[insert]" ]] || {
						! zstyle -t ":completion:${curcontext}:paths" expand suffix && [[ -z "$listsfx" && ( -n "$_comp_correct" || -z "$compstate[pattern_match]" || "$SUFFIX" != */* || "${SUFFIX#*/}" = (|*[^\])[][*?#~^\|\<\>]* ) ]]
					}
				then
					(( tmp4 )) && zstyle -t ":completion:${curcontext}:paths" ambiguous && compstate[to_end]= 
					if [[ "$tmp3" = */* ]]
					then
						if [[ -z "$listsfx" || "$tmp3" != */?* ]]
						then
							tmp1=("${(@)tmp1%%/*}") 
							_list_files tmp1 "$prepath$realpath$testpath"
							compadd $Uopt -Qf "$mopts[@]" -p "${Uopt:+$IPREFIX}$linepath$tmp2" -s "/${tmp3#*/}${Uopt:+$ISUFFIX}" -W "$prepath$realpath$testpath" "$pfxsfx[@]" $Mopts $listopts -a tmp1
						else
							tmp1=("${(@)^tmp1%%/*}/${tmp3#*/}") 
							_list_files tmp1 "$prepath$realpath$testpath"
							compadd $Uopt -Qf "$mopts[@]" -p "${Uopt:+$IPREFIX}$linepath$tmp2" -s "${Uopt:+$ISUFFIX}" -W "$prepath$realpath$testpath" "$pfxsfx[@]" $Mopts $listopts -a tmp1
						fi
					else
						_list_files tmp1 "$prepath$realpath$testpath"
						compadd $Uopt -Qf "$mopts[@]" -p "${Uopt:+$IPREFIX}$linepath$tmp2" -s "${Uopt:+$ISUFFIX}" -W "$prepath$realpath$testpath" "$pfxsfx[@]" $Mopts $listopts -a tmp1
					fi
				else
					if [[ "$tmp3" = */* ]]
					then
						tmp4=($Uopt -Qf "$mopts[@]" -p "${Uopt:+$IPREFIX}$linepath$tmp2" -W "$prepath$realpath$testpath" "$pfxsfx[@]" $Mopts) 
						if [[ -z "$listsfx" ]]
						then
							for i in "$tmp1[@]"
							do
								tmpdisp=("$i") 
								_list_files tmpdisp "$prepath$realpath$testpath"
								compadd "$tmp4[@]" -s "${Uopt:+$ISUFFIX}" $listopts - "$tmpdisp"
							done
						else
							[[ -n "$compstate[pattern_match]" ]] && SUFFIX="${SUFFIX:s./.*/}*" 
							for i in "$tmp1[@]"
							do
								_list_files i "$prepath$realpath$testpath"
								compadd "$tmp4[@]" $listopts - "$i"
							done
						fi
					else
						_list_files tmp1 "$prepath$realpath$testpath"
						compadd $Uopt -Qf "$mopts[@]" -p "${Uopt:+$IPREFIX}$linepath$tmp2" -s "${Uopt:+$ISUFFIX}" -W "$prepath$realpath$testpath" "$pfxsfx[@]" $Mopts $listopts -a tmp1
					fi
				fi
				tmp4=- 
				break
			fi
			if [[ "$tmp3" != */* ]]
			then
				tmp4= 
				break
			fi
			testpath="${testpath}${tmp1[1]%%/*}/" 
			tmp3="${tmp3#*/}" 
			if [[ "$tpre" = */* ]]
			then
				if [[ -z "$_comp_correct" && -n "$compstate[pattern_match]" && "$tmp2" = (|*[^\])[][*?#~^\|\<\>]* ]]
				then
					cpre="${cpre}${tmp1[1]%%/*}/" 
				else
					cpre="${cpre}${tpre%%/*}/" 
				fi
				tpre="${tpre#*/}" 
			elif [[ "$tsuf" = */* ]]
			then
				[[ "$tsuf" != /* ]] && mid="$testpath" 
				if [[ -z "$_comp_correct" && -n "$compstate[pattern_match]" && "$tmp2" = (|*[^\])[][*?#~^\|\<\>]* ]]
				then
					cpre="${cpre}${tmp1[1]%%/*}/" 
				else
					cpre="${cpre}${tpre}/" 
				fi
				tpre="${tsuf#*/}" 
				tsuf= 
			else
				tpre= 
				tsuf= 
			fi
			tmp1=("${(@)tmp1#*/}") 
		done
		if [[ -z "$tmp4" ]]
		then
			if [[ "$mid" = */ ]]
			then
				PREFIX="${opre}" 
				SUFFIX="${osuf}" 
				tmp4="${testpath#${mid}}" 
				if [[ $mid = */*/* ]]
				then
					tmp3="${mid%/*/}" 
					tmp2="${${mid%/}##*/}" 
					if [[ -n "$linepath" ]]
					then
						compquote -p tmp3
					else
						compquote tmp3
					fi
					compquote tmp4 tmp2 tmp1
					for i in "$tmp1[@]"
					do
						_list_files tmp2 "$prepath$realpath${mid%/*/}"
						compadd $Uopt -Qf "$mopts[@]" -p "${Uopt:+$IPREFIX}$linepath$tmp3/" -s "/$tmp4$i${Uopt:+$ISUFFIX}" -W "$prepath$realpath${mid%/*/}/" "$pfxsfx[@]" $Mopts $listopts - "$tmp2"
					done
				else
					tmp2="${${mid%/}##*/}" 
					compquote tmp4 tmp2 tmp1
					for i in "$tmp1[@]"
					do
						_list_files tmp2 "$prepath$realpath${mid%/*/}"
						compadd $Uopt -Qf "$mopts[@]" -p "${Uopt:+$IPREFIX}$linepath" -s "/$tmp4$i${Uopt:+$ISUFFIX}" -W "$prepath$realpath" "$pfxsfx[@]" $Mopts $listopts - "$tmp2"
					done
				fi
			else
				if [[ "$osuf" = */* ]]
				then
					PREFIX="${opre}${osuf}" 
					SUFFIX= 
				else
					PREFIX="${opre}" 
					SUFFIX="${osuf}" 
				fi
				tmp4="$testpath" 
				if [[ -n "$linepath" ]]
				then
					compquote -p tmp4 tmp1
				elif [[ -n "$tmp4" ]]
				then
					compquote -p tmp1
					compquote tmp4
				else
					compquote tmp4 tmp1
				fi
				if [[ -z "$_comp_correct" && -n "$compstate[pattern_match]" && "${PREFIX#\~}$SUFFIX" = (|*[^\])[][*?#~^\|\<\>]* ]]
				then
					tmp1=("$linepath$tmp4${(@)^tmp1}") 
					_list_files tmp1 "$prepath$realpath"
					compadd -Qf -W "$prepath$realpath" "$pfxsfx[@]" "$mopts[@]" -M "r:|/=* r:|=*" $listopts -a tmp1
				else
					_list_files tmp1 "$prepath$realpath$testpath"
					compadd $Uopt -Qf -p "${Uopt:+$IPREFIX}$linepath$tmp4" -s "${Uopt:+$ISUFFIX}" -W "$prepath$realpath$testpath" "$pfxsfx[@]" "$mopts[@]" $Mopts $listopts -a tmp1
				fi
			fi
		fi
	done
	if [[ _matcher_num -eq ${#_matchers} ]] && zstyle -t ":completion:${curcontext}:paths" expand prefix && [[ nm -eq compstate[nmatches] && $#exppaths -ne 0 && "$linepath$exppaths" != "$eorig" ]]
	then
		PREFIX="${opre}" 
		SUFFIX="${osuf}" 
		compadd -Q "$mopts[@]" -S '' -M "r:|/=* r:|=*" -p "$linepath" -a exppaths
	fi
	[[ nm -ne compstate[nmatches] ]] builtin autoload -XU builtin autoload -XU builtin autoload -XU 	PATH2REPO='.' 
	if [ $# -eq 1 ]
	then
		PATH2REPO="$@" 
	fi
	cat $PATH2REPO/.git/config | grep -i email | cut -d'=' -f 2 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	COMMAND="$1" 
	docker $COMMAND --help builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	return 1 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	git_current_branch builtin autoload -XU builtin autoload -XU builtin autoload -XU 	emulate -L zsh
	local qstyle
	zstyle -s :bracketed-paste-magic:finish quote-style qstyle && NUMERIC=1 
	case $qstyle in
		(b) PASTED=${(b)PASTED}  ;;
		(q-) PASTED=${(q-)PASTED}  ;;
		(\|q) PASTED=${(q)PASTED}  ;;
		(\'|qq) PASTED=${(qq)PASTED}  ;;
		(\"|qqq) PASTED=${(qqq)PASTED}  ;;
		(\$|qqqq) PASTED=${(qqqq)PASTED}  ;;
		(Q) PASTED=${(Q)PASTED}  ;;
	esac builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	if [[ "$USER" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]
	then
		prompt_segment black default "%(!.%{%F{yellow}%}.)%n@%m"
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local -a args globbed localschema otherschema reply
	local arg command="$1" 
	shift
	zstyle -s :urlglobber url-local-schema localschema '|'
	zstyle -s :urlglobber url-other-schema otherschema '|'
	for arg
	do
		case "${arg}" in
			((${~localschema}):/(|/localhost)/*) globbed=(${~${arg##ftp://(localhost|)}}) 
				args[$#args+1]=("${(M)arg##(${~localchema})://(localhost|)}${(@)^globbed}")  ;;
			((${~otherschema}):*) args[${#args}+1]="$arg"  ;;
			(*) args[${#args}+1]=(${~arg})  ;;
		esac
	done
	"$command" "${(@)args}" builtin autoload -XU builtin autoload -XU builtin autoload -XU 	open "http://android-docs.local/$1" 	export STANDARD_FOLDER=~/Documents/Tätigkeitsnachweis 
	if [ ${#1} -ne 0 ] && [ -r $1 ]
	then
		CURRENT_PATH=$1 
	elif [ "$1" == "-h" ]
	then
		echo "usage: $FUNCNAME [<path to folder containing excel sheets>]"
		echo "Help: finds the last edited excel sheet in the folder"
		echo "      if no folder is given, then \"$STANDARD_FOLDER\" is used"
		return 0
	else
		CURRENT_PATH=$STANDARD_FOLDER 
	fi
	CURRENT_DOC=$(ls -td $CURRENT_PATH/*.xls* 2> /dev/null | head -n 1) 
	NUM=$(ls $CURRENT_PATH/*.xls* 2> /dev/null | wc -l) 
	if [ $NUM -eq 0 ]
	then
		echo "No Excel Sheet found"
		echo "usage: $FUNCNAME [<path to folder containing excel sheet>]"
		echo
		return 1
	fi
	PATH2DOC=$CURRENT_DOC 
	open /Applications/Microsoft\ Excel.app $PATH2DOC builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	command git config user.name 2> /dev/null builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local ref
	ref=$(command git symbolic-ref --quiet HEAD 2> /dev/null) 
	local ret=$? 
	if [[ $ret != 0 ]]
	then
		[[ $ret == 128 ]] && return
		ref=$(command git rev-parse --short HEAD 2> /dev/null)  || return
	fi
	echo ${ref#refs/heads/} builtin autoload -XU 	exit $1 	local curcontext="$curcontext" state line expl args variant ret=1 
	typeset -A opt_args
	args=('(-m --mode)'{-m,--mode=}'[set permission mode]: :_file_modes' '(-p --parents)'{-p,--parents}'[make parent directories as needed]' '(-)*: :->directories') 
	if (( ${+precommands[(r)command]} ))
	then
		_mkdir_command () {
			command mkdir "$@"
		}
		_pick_variant -c _mkdir_command -r variant gnu=gnu unix --help
		unfunction _mkdir_command
	elif (( ${+precommands[(r)builtin]} )) || (( ${+builtins[mkdir]} )) || [[ "$(type -w mkdir)" == "*: builtin" ]]
	then
		variant=zsh 
	else
		_pick_variant -r variant gnu=gnu zsh='\(eval\)' $OSTYPE --help
	fi
	case $variant in
		(gnu | freebsd* | dragonfly* | darwin*) args+=('(-v --verbose)'{-v,--verbose}'[print message for each created directory]')  ;|
		(gnu) if [[ $OSTYPE == linux* ]]
			then
				args+=('(-Z --context)'{-Z,--context=}'[set SELinux context]:SELinux context') 
			fi
			args+=('(- :)--help[display help information]' '(- :)--version[display version information]')  ;;
		(*) args=(${${${args:#(|*\))--*}//--[^ )]#/}/\( #\)/})  ;;
	esac
	_arguments -C -s $args && ret=0 
	case "$state" in
		(directories) _wanted directories expl 'parent directory (alternatively specify name of directory)' _path_files -/ && ret=0  ;;
	esac
	return ret builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	PS1="$ITERM2_PRECMD_PS1" 
	ITERM2_SHOULD_DECORATE_PROMPT="1" 
	iterm2_before_cmd_executes builtin autoload -XU builtin autoload -XU 	echo "$1" | wc -c builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	if [ -d "$1" ]
	then
		return 0
	else
		return 1
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	echo "$@"
	echo $1
	echo "####################"
	chparam_a2 () {
		echo "2: $(abspath $@)"
	}
	for fname in `ls "$@"`
	do
		echo "$fname"
		chparam_a2 "$fname"
		echo "##########"
	done builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	mkdir -p $@ && cd ${@:$#} builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	RETVAL=$? 
	prompt_status
	prompt_virtualenv
	prompt_aws
	prompt_context
	prompt_dir
	prompt_git
	prompt_bzr
	prompt_hg
	prompt_end builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	set -e builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	printf "]133;C;" builtin autoload -XU builtin autoload -XU builtin autoload -XU 	echo "$1" | tr '[:upper:]' '[:lower:]' builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local ref
	if [[ "$(command git config --get oh-my-zsh.hide-status 2>/dev/null)" != "1" ]]
	then
		ref=$(command git symbolic-ref HEAD 2> /dev/null)  || ref=$(command git rev-parse --short HEAD 2> /dev/null)  || return 0
		echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_SUFFIX"
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	DEBUG=$TRUE  builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local output cmd pat
	local -a var
	local -A opts
	(( $+_cmd_variant )) || typeset -gA _cmd_variant
	zparseopts -D -A opts b: c: r:
	: ${opts[-c]:=$words[1]}
	while [[ $1 = *=* ]]
	do
		var+=("${1%%\=*}" "${1#*=}") 
		shift
	done
	if (( $+_cmd_variant[$opts[-c]] ))
	then
		(( $+opts[-r] )) && eval "${opts[-r]}=${_cmd_variant[$opts[-c]]}"
		[[ $_cmd_variant[$opts[-c]] = "$1" ]] && return 1
		return 0
	fi
	if [[ $+opts[-b] -eq 1 && -n $builtins[$opts[-c]] ]]
	then
		_cmd_variant[$opts[-c]]=$opts[-b] 
		(( $+opts[-r] )) && eval "${opts[-r]}=${_cmd_variant[$opts[-c]]}"
		return 0
	fi
	output="$(_call_program variant $opts[-c] "${@[2,-1]}" </dev/null 2>&1)" 
	for cmd pat in "$var[@]"
	do
		if [[ $output = *$~pat* ]]
		then
			(( $+opts[-r] )) && eval "${opts[-r]}=$cmd"
			_cmd_variant[$opts[-c]]="$cmd" 
			return 0
		fi
	done
	(( $+opts[-r] )) && eval "${opts[-r]}=$1"
	_cmd_variant[$opts[-c]]="$1" 
	return 1 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	return 1 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	PATH=/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH  builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	echoti smkx builtin autoload -XU 	if [ "$DEBUG" -eq $TRUE ] 2> /dev/null || [ "$DEBUG" = $TRUE ]
	then
		return 0
	else
		return 1
	fi builtin autoload -XU builtin autoload -XU 	LINECOUNT=5 
	WHERE=$PWD 
	if [ -n "$1" ]
	then
		LINECOUNT=$1 
	fi
	if [ -n "$2" ]
	then
		WHERE="$2" 
	fi
	echo $LINECOUNT
	echo $WHERE
	ls -lhFaGct "$WHERE/" | head -n "$(($LINECOUNT+1))" 	LETTER="$1" 
	alias | grep -e "^$LETTER" builtin autoload -XU 	date +"%s" 	for i in $(ls $@)
	do
		[ -d "$i" ] && echo "$i is directory" || echo "$i is file"
	done builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local complete
	[[ $2 = complete ]] && complete=")" 
	[[ -z $compstate[quote] && ( ( $_comp_caller_options[bareglobqual] == on && $1 = (#b)(((*[^\\$]|)(\\)#)\()([^\)\|\~]#)$complete && ${#match[1]} -gt 1 ) || ( $_comp_caller_options[extendedglob] == on && $1 = (#b)(((*[^\\$]|)(\\)#)"(#q")([^\)]#)$complete ) ) ]] builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	BROWSER=/Applications/Firefox.app 
	if [ -n "$1" ]
	then
		BROWSER="$1" 
	fi
	web-ext run --firefox="$BROWSER/Contents/MacOS/firefox-bin" builtin autoload -XU builtin autoload -XU 	local ipre scheme host user uhosts ret=1 expl match glob suf 
	local localhttp
	zstyle -a ":completion:${curcontext}:urls" local localhttp
	local localhttp_servername="$localhttp[1]" 
	local localhttp_documentroot="$localhttp[2]" 
	local localhttp_userdir="$localhttp[3]" 
	zstyle -a ":completion:${curcontext}:urls" urls urls
	if [[ $#urls -gt 1 || ( $#urls -eq 1 && ! -d $urls[1] ) ]]
	then
		[[ $#urls -eq 1 && -f $urls[1] ]] && urls=($(< $urls[1])) 
		_wanted urls expl 'URL' compadd "$@" -a urls && return 0
		urls=() 
	fi
	urls="$urls[1]" 
	glob=(-g '*(^/)') 
	zparseopts -D -K -E 'g:=glob'
	ipre="$IPREFIX" 
	if ! compset -P '(#b)([-+.a-z0-9]#):'
	then
		_tags -C argument prefixes
		while _tags
		do
			while _next_label prefixes expl 'URL prefix' -S '' "$@"
			do
				compset -S '[^:/]*' && compstate[to_end]='' 
				[[ -d $urls/bookmark ]] && compadd "$expl[@]" bookmark: && ret=0 
				compadd "$expl[@]" file: ftp:// gopher:// http:// https:// && ret=0 
			done
			(( ret )) || return 0
		done
		return 1
	fi
	scheme="$match[1]" 
	case "$scheme" in
		(http(|s)|(|s)ftp|scp|gopher) if ! compset -P //
			then
				_wanted -C "$scheme" prefixes expl 'end of prefix' compadd -S '' "$@" //
				return
			fi ;;
		(file | unix) [[ -prefix //(127.0.0.1|localhost)/ ]] && compset -P '//(127.0.0.1|localhost)'
			[[ -prefix /// ]] && compset -P //
			if ! compset -P //
			then
				_tags -C file files
				while _tags
				do
					while _next_label files expl 'local file'
					do
						if [[ -prefix / ]]
						then
							_path_files "$expl[@]" -S '' "${glob[@]}" && ret=0 
							_path_files "$expl[@]" -S/ -r '/' -/ && ret=0 
						elif [[ -z "$PREFIX" ]]
						then
							compadd -S '/' -r '/' "$expl[@]" "$@" - "${PWD%/}" && ret=0 
						fi
					done
					(( ret )) || return 0
				done
				return 1
			fi ;;
		(bookmark) if [[ -f "$urls/$scheme/${(Q)PREFIX}${(Q)SUFFIX}" && -s "$urls/$scheme/${(Q)PREFIX}${(Q)SUFFIX}" ]]
			then
				_wanted -C bookmark bookmarks expl bookmarks compadd "$@" -U - "$ipre$(<"$urls/$scheme/${(Q)PREFIX}${(Q)SUFFIX}")" && ret=0 
			else
				_tags -C bookmark files
				while _tags
				do
					while _next_label files expl 'bookmark'
					do
						_path_files -W "$urls/$scheme" "$expl[@]" -S '' "${glob[@]}" && ret=0 
						_path_files -W "$urls/$scheme" -S/ -r '/' "$expl[@]" -/ && ret=0 
					done
					(( ret )) || return 0
				done
			fi
			return ret ;;
	esac
	if ! compset -P '(#b)([^:/]#)([:/])'
	then
		uhosts=($urls/$scheme/$PREFIX*$SUFFIX(/:t)) 
		_tags hosts
		while _tags
		do
			while _next_label hosts expl host
			do
				compset -S '[:/]*' || suf="/" 
				(( $#uhosts )) || _hosts -S "$suf" -r '/:' "$expl[@]" && ret=0 
				[[ "$scheme" = http ]] && uhosts=($uhosts $localhttp_servername) 
				compadd -S "$suf" -r '/:' "$expl[@]" -a uhosts && ret=0 
			done
			(( ret )) || return 0
		done
		return 1
	fi
	host="$match[1]" 
	[[ $match[2] = ':' ]] && ! compset -P '<->/' && _message -e ports 'port number' && return 0
	_tags remote-files files || return 1
	if [[ "$localhttp_servername" = "$host" ]]
	then
		if compset -P \~
		then
			if ! compset -P '(#b)([^/]#)/'
			then
				_users -S/ "$@"
				return
			fi
			user="$match[1]" 
			while _tags
			do
				while _next_label files expl 'local file'
				do
					_path_files "$expl[@]" "$@" -W ~$user/$localhttp_userdir "${glob[@]}" && ret=0 
					_path_files -S/ -r '/' "$expl[@]" -W ~$user/$localhttp_userdir-/ && ret=0 
				done
				(( ret )) || return 0
			done
		else
			while _tags
			do
				while _next_label files expl 'local file'
				do
					_path_files "$expl[@]" "$@" -W $localhttp_documentroot "${glob[@]}" && ret=0 
					_path_files -S/ -r '/' "$expl[@]" -W $localhttp_documentroot -/ && ret=0 
				done
				(( ret )) || return 0
			done
		fi
	else
		while _tags
		do
			(( $#urls )) && while _next_label files expl 'local file'
			do
				_path_files "$expl[@]" "$@" -W $urls/$scheme/$host "${glob[@]}" && ret=0 
				_path_files -S/ -r '/' "$expl[@]" -W $urls/$scheme/$host -/ && ret=0 
			done
			[[ $scheme = (scp|sftp) ]] && _requested remote-files && _remote_files -h $host -- ssh && ret=0 
			(( ret )) || return 0
		done
	fi
	return $ret builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local _comp_command1 _comp_command2 _comp_command skip
	if [[ "$1" = -s ]]
	then
		skip=(-s) 
	else
		skip=() 
		_compskip='' 
	fi
	if [[ -o BANG_HIST && ( ( $words[CURRENT] = \!*: && -z $compstate[quote] ) || ( $words[CURRENT] = \"\!*: && $compstate[all_quotes] = \" ) ) ]]
	then
		PREFIX=${PREFIX//\!/!} 
		compset -P '*:'
		_history_modifiers h
		return
	fi
	if [[ CURRENT -eq 1 ]]
	then
		curcontext="${curcontext%:*:*}:-command-:" 
		comp="$_comps[-command-]" 
		[[ -n "$comp" ]] && eval "$comp" && return
		return 1
	fi
	_set_command
	_dispatch "$skip[@]" "$_comp_command" "$_comp_command1" "$_comp_command2" -default- builtin autoload -XU 	local __gopt __len __tmp __pre __suf __ret=1 __descr __spec __prev 
	if [[ "$1" = - ]]
	then
		__prev=- 
		shift
	fi
	__gopt=() 
	zparseopts -D -a __gopt 1 2 V J x
	__tmp=${argv[(ib:4:)-]} 
	__len=$# 
	if [[ __tmp -lt __len ]]
	then
		__pre=$(( __tmp-1 )) 
		__suf=$__tmp 
	elif [[ __tmp -eq $# ]]
	then
		__pre=-2 
		__suf=$(( __len+1 )) 
	else
		__pre=4 
		__suf=5 
	fi
	while comptags "-A$__prev" "$1" curtag __spec
	do
		(( $#funcstack > _tags_level )) && _comp_tags="${_comp_tags% * }" 
		_tags_level=$#funcstack 
		_comp_tags="$_comp_tags $__spec " 
		if [[ "$curtag" = *[^\]:* ]]
		then
			zformat -f __descr "${curtag#*:}" "d:$3"
			_description "$__gopt[@]" "${curtag%:*}" "$2" "$__descr"
			curtag="${curtag%:*}" 
			"$4" "${(P@)2}" "${(@)argv[5,-1]}" && __ret=0 
		else
			_description "$__gopt[@]" "$curtag" "$2" "$3"
			"${(@)argv[4,__pre]}" "${(P@)2}" "${(@)argv[__suf,-1]}" && __ret=0 
		fi
	done
	return __ret builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	DEBUG=$FALSE  	re='^[0-9]+$' 
	if ! [[ $1 =~ $re ]]
	then
		return 1
	else
		return 0
	fi builtin autoload -XU builtin autoload -XU 	echo "$1" | tr '[:lower:]' '[:upper:]' builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local garbage
	zparseopts -K -D -a garbage M: J: V: 1 2 n F: X:
	[[ "$PREFIX$SUFFIX" != $~1 ]] && return 1
	shift
	_message -e "$*"
	[[ -n "$PREFIX$SUFFIX" ]] builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local file
	local -a oldp dbfiles
	oldp=("$1"(Nmw+1)) 
	(( $#oldp )) && return 0
	dbfiles=(/usr/share/man/index.(bt|db|dir|pag)(N) /usr/man/index.(bt|db|dir|pag)(N) /var/cache/man/index.(bt|db|dir|pag)(N) /var/catman/index.(bt|db|dir|pag)(N) /usr/share/man/*/whatis(N)) 
	for file in $dbfiles
	do
		[[ $file -nt $1 ]] && return 0
	done
	return 1 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	if [ $# -eq 2 ]
	then
		COUNT=$1 
	else
		COUNT=45 
	fi
	checkfile_it () {
		while true
		do
			clear
			tail -$COUNT "$@"
			sleep 1
		done
	}
	if [ $# -eq 2 ]
	then
		shift
	fi
	for fname in "$@"
	do
		checkfile_it "$fname"
	done builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local STATUS
	local -a FLAGS
	FLAGS=('--porcelain') 
	if [[ "$(command git config --get oh-my-zsh.hide-dirty)" != "1" ]]
	then
		if [[ "$DISABLE_UNTRACKED_FILES_DIRTY" == "true" ]]
		then
			FLAGS+='--untracked-files=no' 
		fi
		case "$GIT_STATUS_IGNORE_SUBMODULES" in
			(git)  ;;
			(*) FLAGS+="--ignore-submodules=${GIT_STATUS_IGNORE_SUBMODULES:-dirty}"  ;;
		esac
		STATUS=$(command git status ${FLAGS} 2> /dev/null | tail -n1) 
	fi
	if [[ -n $STATUS ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_DIRTY"
	else
		echo "$ZSH_THEME_GIT_PROMPT_CLEAN"
	fi builtin autoload -XU builtin autoload -XU 	local curcontext="${curcontext}" tmp err_fd=-1 clocale='_comp_locale;' 
	local -a prefix
	if [[ "$1" = -p ]]
	then
		shift
		if (( $#_comp_priv_prefix ))
		then
			curcontext="${curcontext%:*}/${${(@M)_comp_priv_prefix:#^*[^\]=*}[1]}:" 
			zstyle -t ":completion:${curcontext}:${1}" gain-privileges && prefix=($_comp_priv_prefix) 
		fi
	elif [[ "$1" = -l ]]
	then
		shift
		clocale='' 
	fi
	if (( ${debug_fd:--1} > 2 )) || [[ ! -t 2 ]]
	then
		exec {err_fd}>&2
	else
		exec {err_fd}> /dev/null
	fi
	{
		if zstyle -s ":completion:${curcontext}:${1}" command tmp
		then
			if [[ "$tmp" = -* ]]
			then
				eval $clocale "$tmp[2,-1]" "$argv[2,-1]"
			else
				eval $clocale $prefix "$tmp"
			fi
		else
			eval $clocale $prefix "$argv[2,-1]"
		fi 2>&$err_fd
	} always {
		exec {err_fd}>&-
	} 	local -a match mbegin mend
	local ret=1 
	if _have_glob_qual $PREFIX
	then
		compset -p ${#match[1]}
		compset -S '[^\)\|\~]#(|\))'
		if [[ $_comp_caller_options[extendedglob] == on ]] && compset -P '\#'
		then
			_globflags && ret=0 
		else
			if [[ $_comp_caller_options[extendedglob] == on ]]
			then
				_describe -t globflags "glob flag" '(\#:introduce\ glob\ flag)' -Q -S '' && ret=0 
			fi
			_globquals && ret=0 
		fi
		return ret
	elif [[ $_comp_caller_options[extendedglob] == on && $PREFIX = \(\#[^\)]# ]] && compset -P '\(\#'
	then
		_globflags && return
	fi
	local opts tmp glob pat pats expl tag i def descr end ign tried
	local type sdef ignvars ignvar prepath oprefix rfiles rfile
	zparseopts -a opts '/=tmp' 'f=tmp' 'g+:-=tmp' q n 1 2 P: S: r: R: W: X+: M+: F: J+: V+:
	type="${(@j::M)${(@)tmp#-}#?}" 
	if (( $tmp[(I)-g*] ))
	then
		glob="${${${(@)${(@M)tmp:#-g*}#-g}##[[:blank:]]#}%%[[:blank:]]#}" 
		[[ "$glob" = *[^\][[:blank:]]* ]] && glob="{${glob//(#b)([^\])[[:blank:]]##/${match[1]},}}" 
		[[ "$glob" = (#b)(*\()([^\|\~]##\)) && $match[2] != \#q* ]] && glob="${match[1]}#q${match[2]}" 
	elif [[ $type = */* ]]
	then
		glob="*(#q-/)" 
	fi
	tmp=$opts[(I)-F] 
	if (( tmp ))
	then
		ignvars=($=opts[tmp+1]) 
		if [[ $ignvars = _comp_ignore ]]
		then
			ign=($_comp_ignore) 
		elif [[ $ignvars = \(* ]]
		then
			ign=(${=ignvars[2,-2]}) 
		else
			ign=() 
			for ignvar in $ignvars
			do
				ign+=(${(P)ignvar}) 
			done
			opts[tmp+1]=_comp_ignore 
		fi
	else
		ign=() 
	fi
	if zstyle -a ":completion:${curcontext}:" file-patterns tmp
	then
		pats=() 
		for i in ${tmp//\%p/${${glob:-\*}//:/\:}}
		do
			if [[ $i = *[^\]:* ]]
			then
				pats+=(" $i ") 
			else
				pats+=(" ${i}:files ") 
			fi
		done
	elif zstyle -t ":completion:${curcontext}:" list-dirs-first
	then
		pats=(" *(-/):directories:directory ${${glob:-*}//:/\:}(#q^-/):globbed-files" '*:all-files') 
	else
		pats=("${${glob:-*}//:/\:}:globbed-files *(-/):directories" '*:all-files ') 
	fi
	tried=() 
	for def in "$pats[@]"
	do
		eval "def=( ${${def//\:/\\\:}//(#b)([][()|*?^#~<>])/\${match[1]}} )"
		tmp="${(@M)def#*[^\]:}" 
		(( $tried[(I)${(q)tmp}] )) && continue
		tried=("$tried[@]" "$tmp") 
		for sdef in "$def[@]"
		do
			tag="${${sdef#*[^\]:}%%:*}" 
			pat="${${sdef%%:${tag}*}//\:/:}" 
			if [[ "$sdef" = *:${tag}:* ]]
			then
				descr="${(Q)sdef#*:${tag}:}" 
			else
				if (( $opts[(I)-X] ))
				then
					descr= 
				else
					descr=file 
				fi
				end=yes 
			fi
			_tags "$tag"
			while _tags
			do
				_comp_ignore=() 
				while _next_label "$tag" expl "$descr"
				do
					_comp_ignore=($_comp_ignore $ign) 
					if [[ -n "$end" ]]
					then
						if _path_files -g "$pat" "$opts[@]" "$expl[@]"
						then
							ret=0 
						elif [[ $PREFIX$SUFFIX != */* ]] && zstyle -a ":completion:${curcontext}:$tag" recursive-files rfiles
						then
							local subtree
							for rfile in $rfiles
							do
								if [[ $PWD/ = ${~rfile} ]]
								then
									if [[ -z $subtree ]]
									then
										subtree=(**/*(/)) 
									fi
									for prepath in $subtree
									do
										oprefix=$PREFIX 
										PREFIX=$prepath/$PREFIX 
										_path_files -g "$pat" "$opts[@]" "$expl[@]" && ret=0 
										PREFIX=$oprefix 
									done
									break
								fi
							done
						fi
					else
						_path_files "$expl[@]" -g "$pat" "$opts[@]" && ret=0 
					fi
				done
				(( ret )) || break
			done
			[[ "$pat" = '*' ]] && return ret
		done
		(( ret )) || return 0
	done
	return 1 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	return 1 builtin autoload -XU 	local __gopt __descr __spec
	__gopt=() 
	zparseopts -D -a __gopt 1 2 V J x
	if comptags -A "$1" curtag __spec
	then
		(( $#funcstack > _tags_level )) && _comp_tags="${_comp_tags% * }" 
		_tags_level=$#funcstack 
		_comp_tags="$_comp_tags $__spec " 
		if [[ "$curtag" = *[^\]:* ]]
		then
			zformat -f __descr "${curtag#*:}" "d:$3"
			_description "$__gopt[@]" "${curtag%:*}" "$2" "$__descr"
			curtag="${curtag%:*}" 
			set -A $2 "${(P@)2}" "${(@)argv[4,-1]}"
		else
			_description "$__gopt[@]" "$curtag" "$2" "$3"
			set -A $2 "${(@)argv[4,-1]}" "${(P@)2}"
		fi
		return 0
	fi
	return 1 builtin autoload -XU builtin autoload -XU 	[[ -z "$AWS_PROFILE" ]] && return
	case "$AWS_PROFILE" in
		(*-prod | *production*) prompt_segment red yellow "AWS: $AWS_PROFILE" ;;
		(*) prompt_segment green black "AWS: $AWS_PROFILE" ;;
	esac builtin autoload -XU 	pARRAY="$1" 
	IFS=$'
' 
	echo "${pARRAY[*]}" 	local SHA
	SHA=$(command git rev-parse --short HEAD 2> /dev/null)  && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER" 	if [ "$1" -eq "$1" ] 2> /dev/null
	then
		return 0
	else
		return 1
	fi builtin autoload -XU builtin autoload -XU 	_arguments -s '-q[quiet, no output or use of hooks]' '-s[refuse to use paths with symlinks]' '(-P)-L[retain symbolic links ignoring CHASE_LINKS]' '(-L)-P[resolve symbolic links as CHASE_LINKS]' builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local comp name oldcontext ret=1 service 
	typeset -T curcontext="$curcontext" ccarray 
	oldcontext="$curcontext" 
	if [[ -n "$compcontext" ]]
	then
		if [[ "${(t)compcontext}" = *array* ]]
		then
			local expl
			_wanted values expl value compadd -a - compcontext
		elif [[ "${(t)compcontext}" = *assoc* ]]
		then
			local expl tmp i
			tmp=() 
			for i in "${(@k)compcontext[(R)*[^[:blank:]]]}"
			do
				tmp=("$tmp[@]" "${i}:${compcontext[$i]}") 
			done
			tmp=("$tmp[@]" "${(k@)compcontext[(R)[[:blank:]]#]}") 
			_describe -t values value tmp
		elif [[ "$compcontext" = *:*:* ]]
		then
			local tag="${${compcontext%%:*}:-values}" 
			local descr="${${${compcontext#${tag}:}%%:*}:-value}" 
			local action="${compcontext#${tag}:${descr}:}" expl ws ret=1 
			case "$action" in
				(\ #) _message -e "$tag" "$descr" ;;
				(\(\(*\)\)) eval ws\=\( "${action[3,-3]}" \)
					_describe -t "$tag" "$descr" ws ;;
				(\(*\)) eval ws\=\( "${action[2,-2]}" \)
					_wanted "$tag" expl "$descr" compadd -a - ws ;;
				(\{*\}) _tags "$tag"
					while _tags
					do
						while _next_label "$tag" expl "$descr"
						do
							eval "$action[2,-2]" && ret=0 
						done
						(( ret )) || break
					done ;;
				(\ *) eval ws\=\( "$action" \)
					_tags "$tag"
					while _tags
					do
						while _next_label "$tag" expl "$descr"
						do
							"$ws[@]"
						done
						(( ret )) || break
					done ;;
				(*) eval ws\=\( "$action" \)
					_tags "$tag"
					while _tags
					do
						while _next_label "$tag" expl "$descr"
						do
							"$ws[1]" "$expl[@]" "${(@)ws[2,-1]}"
						done
						(( ret )) || break
					done ;;
			esac
		else
			ccarray[3]="$compcontext" 
			comp="$_comps[$compcontext]" 
			[[ -n "$comp" ]] && eval "$comp"
		fi
		return
	fi
	comp="$_comps[-first-]" 
	if [[ -n "$comp" ]]
	then
		service="${_services[-first-]:--first-}" 
		ccarray[3]=-first- 
		eval "$comp" && ret=0 
		if [[ "$_compskip" = all ]]
		then
			_compskip= 
			return ret
		fi
	fi
	[[ -n $compstate[vared] ]] && compstate[context]=vared 
	ret=1 
	if [[ "$compstate[context]" = command ]]
	then
		curcontext="$oldcontext" 
		_normal -s && ret=0 
	else
		local cname="-${compstate[context]:s/_/-/}-" 
		ccarray[3]="$cname" 
		comp="$_comps[$cname]" 
		service="${_services[$cname]:-$cname}" 
		if [[ -z "$comp" ]]
		then
			if [[ "$_compskip" = *default* ]]
			then
				_compskip= 
				return 1
			fi
			comp="$_comps[-default-]" 
			service="${_services[-default-]:--default-}" 
		fi
		[[ -n "$comp" ]] && eval "$comp" && ret=0 
	fi
	_compskip= 
	return ret builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	[[ -f "$NVM_DIR/nvm.sh" ]] || return
	local nvm_prompt
	nvm_prompt=$(node -v 2>/dev/null) 
	[[ "${nvm_prompt}x" == "x" ]] && return
	nvm_prompt=${nvm_prompt:1} 
	echo "${ZSH_THEME_NVM_PROMPT_PREFIX}${nvm_prompt}${ZSH_THEME_NVM_PROMPT_SUFFIX}" builtin autoload -XU builtin autoload -XU 	[ -f $HOME/.rvm/bin/rvm-prompt ] || return 1
	local rvm_prompt
	rvm_prompt=$($HOME/.rvm/bin/rvm-prompt ${=ZSH_THEME_RVM_PROMPT_OPTIONS} 2>/dev/null) 
	[[ -z "${rvm_prompt}" ]] && return 1
	echo "${ZSH_THEME_RUBY_PROMPT_PREFIX}${rvm_prompt}${ZSH_THEME_RUBY_PROMPT_SUFFIX}" 	emulate -L zsh
	setopt prompt_subst
	[[ "$EMACS" == *term* ]] && return
	: ${2=$1}
	case "$TERM" in
		(cygwin | xterm* | putty* | rxvt* | ansi) print -Pn "]2;$2:q"
			print -Pn "]1;$1:q" ;;
		(screen* | tmux*) print -Pn "k$1:q\" ;;
		(*) if [[ "$TERM_PROGRAM" == "iTerm.app" ]]
			then
				print -Pn "]2;$2:q"
				print -Pn "]1;$1:q"
			else
				if [[ -n "$terminfo[fsl]" ]] && [[ -n "$terminfo[tsl]" ]]
				then
					echoti tsl
					print -Pn "$1"
					echoti fsl
				fi
			fi ;;
	esac builtin autoload -XU 	emulate -L zsh
	if [[ "$DISABLE_AUTO_TITLE" == true ]]
	then
		return
	fi
	title $ZSH_THEME_TERM_TAB_TITLE_IDLE $ZSH_THEME_TERM_TITLE_IDLE builtin autoload -XU 	local command
	command="$words[1]" 
	[[ -z "$command" ]] && return
	if (( $+builtins[$command] + $+functions[$command] ))
	then
		_comp_command1="$command" 
		_comp_command="$_comp_command1" 
	elif [[ "$command[1]" = '=' ]]
	then
		eval _comp_command2\=$command
		_comp_command1="$command[2,-1]" 
		_comp_command="$_comp_command2" 
	elif [[ "$command" = ..#/* ]]
	then
		_comp_command1="${PWD}/$command" 
		_comp_command2="${command:t}" 
		_comp_command="$_comp_command2" 
	elif [[ "$command" = */* ]]
	then
		_comp_command1="$command" 
		_comp_command2="${command:t}" 
		_comp_command="$_comp_command2" 
	else
		_comp_command1="$command" 
		_comp_command2="$commands[$command]" 
		_comp_command="$_comp_command1" 
	fi 	ls -lahF `which "$1"` builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	PC=2 
	echo "count $#"
	echo "\$0 $0"
	echo "0 ${@:0}"
	echo "1 ${@:1}"
	echo "2 ${@:2}"
	echo "3 ${@:3}"
	echo "$PC ${@:PC}"
	echo "$1" ${@:2} -R . builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	chparam2 () {
		echo "$@"
	}
	for fname in "$@"
	do
		chparam2 "$fname"
	done builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local program programs progfile md5
	builtin echo oh-my-zsh diagnostic dump
	builtin echo
	builtin echo $outfile
	builtin echo
	command date
	command uname -a
	builtin echo OSTYPE=$OSTYPE
	builtin echo ZSH_VERSION=$ZSH_VERSION
	builtin echo User: $USER
	builtin echo umask: $(umask)
	builtin echo
	_omz_diag_dump_os_specific_version
	builtin echo
	programs=(sh zsh ksh bash sed cat grep ls find git posh) 
	local progfile="" extra_str="" sha_str="" 
	for program in $programs
	do
		extra_str="" sha_str="" 
		progfile=$(builtin which $program) 
		if [[ $? == 0 ]]
		then
			if [[ -e $progfile ]]
			then
				if builtin whence shasum &> /dev/null
				then
					sha_str=($(command shasum $progfile)) 
					sha_str=$sha_str[1] 
					extra_str+=" SHA $sha_str" 
				fi
				if [[ -h "$progfile" ]]
				then
					extra_str+=" ( -> ${progfile:A} )" 
				fi
			fi
			builtin printf '%-9s %-20s %s
' "$program is" "$progfile" "$extra_str"
		else
			builtin echo "$program: not found"
		fi
	done
	builtin echo
	builtin echo Command Versions:
	builtin echo "zsh: $(zsh --version)"
	builtin echo "this zsh session: $ZSH_VERSION"
	builtin echo "bash: $(bash --version | command grep bash)"
	builtin echo "git: $(git --version)"
	builtin echo "grep: $(grep --version)"
	builtin echo
	_omz_diag_dump_check_core_commands || return 1
	builtin echo
	builtin echo Process state:
	builtin echo pwd: $PWD
	if builtin whence pstree &> /dev/null
	then
		builtin echo Process tree for this shell:
		pstree -p $$
	else
		ps -fT
	fi
	builtin set | command grep -a '^\(ZSH\|plugins\|TERM\|LC_\|LANG\|precmd\|chpwd\|preexec\|FPATH\|TTY\|DISPLAY\|PATH\)\|OMZ'
	builtin echo
	builtin echo Exported:
	builtin echo $(builtin export | command sed 's/=.*//')
	builtin echo
	builtin echo Locale:
	command locale
	builtin echo
	builtin echo Zsh configuration:
	builtin echo setopt: $(builtin setopt)
	builtin echo
	builtin echo zstyle:
	builtin zstyle
	builtin echo
	builtin echo 'compaudit output:'
	compaudit
	builtin echo
	builtin echo '$fpath directories:'
	command ls -lad $fpath
	builtin echo
	builtin echo oh-my-zsh installation:
	command ls -ld ~/.z*
	command ls -ld ~/.oh*
	builtin echo
	builtin echo oh-my-zsh git state:
	(
		cd $ZSH && builtin echo "HEAD: $(git rev-parse HEAD)" && git remote -v && git status | command grep "[^[:space:]]"
	)
	if [[ $verbose -ge 1 ]]
	then
		(
			cd $ZSH && git reflog --date=default | command grep pull
		)
	fi
	builtin echo
	if [[ -e $ZSH_CUSTOM ]]
	then
		local custom_dir=$ZSH_CUSTOM 
		if [[ -h $custom_dir ]]
		then
			custom_dir=$(cd $custom_dir && pwd -P) 
		fi
		builtin echo "oh-my-zsh custom dir:"
		builtin echo "   $ZSH_CUSTOM ($custom_dir)"
		(
			cd ${custom_dir:h} && command find ${custom_dir:t} -name .git -prune -o -print
		)
		builtin echo
	fi
	if [[ $verbose -ge 1 ]]
	then
		builtin echo "bindkey:"
		builtin bindkey
		builtin echo
		builtin echo "infocmp:"
		command infocmp -L
		builtin echo
	fi
	local zdotdir=${ZDOTDIR:-$HOME} 
	builtin echo "Zsh configuration files:"
	local cfgfile cfgfiles
	cfgfiles=(/etc/zshenv /etc/zprofile /etc/zshrc /etc/zlogin /etc/zlogout $zdotdir/.zshenv $zdotdir/.zprofile $zdotdir/.zshrc $zdotdir/.zlogin $zdotdir/.zlogout ~/.zsh.pre-oh-my-zsh /etc/bashrc /etc/profile ~/.bashrc ~/.profile ~/.bash_profile ~/.bash_logout) 
	command ls -lad $cfgfiles 2>&1
	builtin echo
	if [[ $verbose -ge 1 ]]
	then
		for cfgfile in $cfgfiles
		do
			_omz_diag_dump_echo_file_w_header $cfgfile
		done
	fi
	builtin echo
	builtin echo "Zsh compdump files:"
	local dumpfile dumpfiles
	command ls -lad $zdotdir/.zcompdump*
	dumpfiles=($zdotdir/.zcompdump*(N)) 
	if [[ $verbose -ge 2 ]]
	then
		for dumpfile in $dumpfiles
		do
			_omz_diag_dump_echo_file_w_header $dumpfile
		done
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	export ex_code=$? 
	(( $SAVED_OPT_E )) && set +e
	return $ex_code 	env ZSH=$ZSH sh $ZSH/tools/uninstall.sh builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local arguments matchers command variant
	if [[ $service = *GREP_OPT* ]]
	then
		compset -q
		words=(fake "$words[@]") 
		(( CURRENT++ ))
		command=grep 
	else
		arguments=('(-e --regexp -f --file)1: :_guard "^-*" pattern') 
		if [[ $service = z* ]]
		then
			arguments+=('*: :_files -g "*.gz(-.)"') 
		elif [[ $service = bz* ]]
		then
			arguments+=('*: :_files -g "*.bz2(-.)"') 
		else
			arguments+=('*: :_files') 
		fi
		command="$words[1]" 
	fi
	if [[ $service != (|g|z|gz|bz)[ef]grep ]]
	then
		matchers='(--extended-regexp --fixed-strings --basic-regexp --perl-regexp -E -F -G -P)' 
		arguments+=($matchers{--extended-regexp,-E}'[use extended regular expression]' $matchers{--fixed-strings,-F}'[use literal strings]' $matchers{--basic-regexp,-G}'[use basic regular expression]') 
	fi
	arguments+=('(--after-context -A)'{--after-context=,-A+}'[specify lines of trailing context]:lines' '(--text -a --binary-files -I)'{--text,-a}'[process binary file as if it were text]' '(--before-context -B)'{--before-context=,-B+}'[specify lines of leading context]:lines' '(--context -C)'{--context=,-C-}'[specify lines of context]:lines' '(--color --colour)--'{color,colour}'=-[distinguish matching string]::when:(always never auto)' '(--byte-offset -b -c)'{--byte-offset,-b}'[print the byte offset with output lines]' '(--text -a -I)--binary-files=[specify type to assume for binary files]:file type:(binary without-match text)' '(--count -c --byte-offset -b --line-number -n)'{--count,-c}'[only print a count of matching lines]' '(--directories -d -r --recursive)'{--directories=,-d+}'[specify handling of directories]:action on directory:(read skip recurse)' '(--devices -D)'{--devices=,-D+}'[specify handling of devices, FIFOs and sockets]:action on device:(read skip)' '(1)*'{--regexp=,-e+}'[specify pattern]:pattern' '(1)*'{--file=,-f+}'[specify pattern file]:file:_files' '(--with-filename -H --no-filename -h)'{--with-filename,-H}'[print filename with each match]' '(--no-filename -h --with-filename -H --null -Z --files-without-match -L --file-with-matches -l)'{--no-filename,-h}'[suppress printing of filenames]' '--label=[provide filename to print for stdin]:filename label for stdin' '--line-buffered[flush output on every line]' '(--text -a --binary-files)-I[process binary files as if non-matching]' '(--ignore-case -i -y)'{--ignore-case,-i,-y}'[case-insensitive]' '(--files-without-match -L --file-with-matches -l --no-filename -h -o --only-matching)'{--files-without-match,-L}"[output non-matching files' names only]" '(--files-with-matches -l --files-without-match -L --no-filename -h -o --only-matching)'{--files-with-matches,-l}"[output matching files' names only]" '(--max-count -m)'{--max-count=,-m+}'[stop after specified no of matches in each file]:max number of matches' '(--line-number -n -c)'{--line-number,-n}'[prefix output with line numbers]' '(--only-matching -o --files-with-matches -l --files-without-match -L)'{--only-matching,-o}'[show only matching part of line]' '(--quiet --silent -q)'{--quiet,--silent,-q}'[suppress normal output]' '(--recursive -r --dereference-recursive -R -d --directories)'{--recursive,-r}'[recurse subdirectories]' '*--include=[examine files matching specified pattern]:file pattern' '*--exclude=[skip files matching specified pattern]:file pattern' '*--exclude-dir=[skip directories matching specified pattern]:directory pattern' '(--no-messages -s)'{--no-messages,-s}'[suppress messages about unreadable]' '(--version -V)'{--version,-V}'[display version info]' '(--invert-match -v)'{--invert-match,-v}'[select non-matching lines]' '(--word-regexp -w --line-regexp -x)'{--word-regexp,-w}'[force pattern to match only whole words]' '(--line-regexp -x --word-regexp -w)'{--line-regexp,-x}'[force pattern to match only whole lines]' '(-)--help[display help information]') 
	_pick_variant -r variant -c "$command" gnu=gnu gpl2=2.5.1 unix --version
	case $variant:$OSTYPE in
		((gnu:*|gpl2:freebsd*)) [[ $service != (|g|z|gz|bz)[ef]grep ]] && arguments+=($matchers{--perl-regexp,-P}'[use perl regular expression]')  ;|
		((gnu:*|gpl2:(free|net)bsd*)) arguments+=('*--exclude-from=[skip files matching pattern in specified file]:file:_files' '(-z --null-data)'{-z,--null-data}'[input data separated by 0 byte, not newline]')  ;|
		(gpl2:(freebsd|darwin)*) arguments+=('(--null --no-filename -h)--null[print 0 byte after each filename]' '(-Z --decompress -J --bz2decompress)'{-J,--bz2decompress}"[decompress bzip2'ed input before searching]" '(-Z --decompress -J --bz2decompress)'{-Z,--decompress}"[decompress gzip'ed input before searching]")  ;|
		(gpl2:darwin*) arguments+=('(-p -S)-O[follow symlinks on the command line]' '(-O -S)-p[do not follow symlinks]' '(-O -p)-S[follow all symlinks]' '*--include-dir=[only search directories matching specified pattern]:directory pattern')  ;|
		((gnu:*|gpl2:netbsd*)) arguments+=('(--null -Z --no-filename -h)'{--null,-Z}'[print 0 byte after each filename]')  ;|
		(gnu:*) arguments+=('(--no-group-separator)--group-separator=[specify separator between blocks of context]:separator [--]' "(--group-separator)--no-group-separator[don't separate context blocks]" '(-T --initial-tab)'{-T,--initial-tab}'[make tabs line up (if needed)]' '(--recursive -r --dereference-recursive -R -d --directories)'{--dereference-recursive,-R}'[recurse subdirectories, following symlinks]')  ;;
		(gpl2:*) arguments=(${${arguments:#*\)-r}/\)-r/\)-R})  ;;
		(*:openbsd*) arguments=(${(M)arguments:#((#s)|*\))--(context|binary-files|line-buffered)*} ${${arguments:#((#s)|*\))(\*|)-[d-]*}/\)-r/\)-R} "-U[search binary files but don't print them]" '-Z[behave as zgrep]')  ;;
		(*) arguments=(${arguments:#((#s)|*\))(\*|)-[aABCdDfGHILmorVy-]*})  ;;
	esac
	_arguments -S -s $arguments[@] builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local need_desc expl ret=1 
	if zstyle -t ":completion:${curcontext}:" extra-verbose
	then
		local update_policy first
		if [[ $+_command_descriptions -eq 0 ]]
		then
			first=yes 
			typeset -A -g _command_descriptions
		fi
		zstyle -s ":completion:${curcontext}:" cache-policy update_policy
		[[ -z "$update_policy" ]] && zstyle ":completion:${curcontext}:" cache-policy _path_commands_caching_policy
		if (
				[[ -n $first ]] || _cache_invalid command-descriptions
			) && ! _retrieve_cache command-descriptions
		then
			local line
			for line in "${(f)$(_call_program command-descriptions _call_whatis -s 1 -r .\\*\; _call_whatis -s 6 -r .\\* 2>/dev/null)}"
			do
				[[ -n ${line:#(#b)([^ ]#) #\([^ ]#\)( #\[[^ ]#\]|)[ -]#(*)} ]] && continue
				[[ -z $match[1] || -z $match[3] || -z ${${match[1]}:#*:*} ]] && continue
				_command_descriptions[$match[1]]=$match[3] 
			done
			_store_cache command-descriptions _command_descriptions
		fi
		(( $#_command_descriptions )) && need_desc=yes 
	fi
	if [[ -n $need_desc ]]
	then
		typeset -a dcmds descs cmds matches
		local desc cmd sep
		compadd "$@" -O matches -k commands
		for cmd in $matches
		do
			desc=$_command_descriptions[$cmd] 
			if [[ -z $desc ]]
			then
				cmds+=$cmd 
			else
				dcmds+=$cmd 
				descs+="$cmd:$desc" 
			fi
		done
		zstyle -s ":completion:${curcontext}:" list-separator sep || sep=-- 
		zformat -a descs " $sep " $descs
		descs=("${(@r:COLUMNS-1:)descs}") 
		_wanted commands expl 'external command' compadd "$@" -ld descs -a dcmds && ret=0 
		_wanted commands expl 'external command' compadd "$@" -a cmds && ret=0 
	else
		_wanted commands expl 'external command' compadd "$@" -k commands && ret=0 
	fi
	if [[ -o path_dirs ]]
	then
		local -a path_dirs
		path_dirs=(${^path}/*(/N:t)) 
		(( ${#path_dirs} )) && _wanted path-dirs expl 'directory in path' compadd "$@" -a path_dirs && ret=0 
		if [[ $PREFIX$SUFFIX = */* ]]
		then
			_wanted commands expl 'external command' _path_files -W path -g '*(*)' && ret=0 
		fi
	fi
	return $ret builtin autoload -XU builtin autoload -XU builtin autoload -XU 	DEPTH=1 
	if [ $# -gt 1 ]
	then
		DEPTH=$2 
	fi
	du -h -d $DEPTH "$1" | grep '[0-9]G\>' builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local -a symbols
	[[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘" 
	[[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡" 
	[[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙" 
	[[ -n "$symbols" ]] && prompt_segment black default "$symbols" builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	fmp_helperx () {
		echo "$@"
	}
	for fname in "$@"
	do
		fmp_helperx "$fname"
	done
	fmp_helper () {
		echo "$@"
	} builtin autoload -XU builtin autoload -XU 	emulate -L zsh
	typeset -Ag color colour
	color=(00 none 01 bold 02 faint 22 normal 03 standout 23 no-standout 04 underline 24 no-underline 05 blink 25 no-blink 07 reverse 27 no-reverse 08 conceal 28 no-conceal 30 black 40 bg-black 31 red 41 bg-red 32 green 42 bg-green 33 yellow 43 bg-yellow 34 blue 44 bg-blue 35 magenta 45 bg-magenta 36 cyan 46 bg-cyan 37 white 47 bg-white 39 default 49 bg-default) 
	local k
	for k in ${(k)color}
	do
		color[${color[$k]}]=$k 
	done
	for k in ${color[(I)3?]}
	do
		color[fg-${color[$k]}]=$k 
	done
	color[grey]=${color[black]} 
	color[fg-grey]=${color[grey]} 
	color[bg-grey]=${color[bg-black]} 
	colour=(${(kv)color}) 
	local lc=$'[' rc=m 
	typeset -Hg reset_color bold_color
	reset_color="$lc${color[none]}$rc" 
	bold_color="$lc${color[bold]}$rc" 
	typeset -AHg fg fg_bold fg_no_bold
	for k in ${(k)color[(I)fg-*]}
	do
		fg[${k#fg-}]="$lc${color[$k]}$rc" 
		fg_bold[${k#fg-}]="$lc${color[bold]};${color[$k]}$rc" 
		fg_no_bold[${k#fg-}]="$lc${color[normal]};${color[$k]}$rc" 
	done
	typeset -AHg bg bg_bold bg_no_bold
	for k in ${(k)color[(I)bg-*]}
	do
		bg[${k#bg-}]="$lc${color[$k]}$rc" 
		bg_bold[${k#bg-}]="$lc${color[bold]};${color[$k]}$rc" 
		bg_no_bold[${k#bg-}]="$lc${color[normal]};${color[$k]}$rc" 
	done builtin autoload -XU builtin autoload -XU builtin autoload -XU 	if [ -d "$1" ]
	then
		return 1
	else
		return 0
	fi builtin autoload -XU builtin autoload -XU 	git diff -w "$@" | view - builtin autoload -XU 	emulate -L zsh
	builtin echo "Generating diagnostic dump; please be patient..."
	local thisfcn=omz_diagnostic_dump 
	local -A opts
	local opt_verbose opt_noverbose opt_outfile
	local timestamp=$(date +%Y%m%d-%H%M%S) 
	local outfile=omz_diagdump_$timestamp.txt 
	builtin zparseopts -A opts -D -- "v+=opt_verbose" "V+=opt_noverbose"
	local verbose n_verbose=${#opt_verbose} n_noverbose=${#opt_noverbose} 
	(( verbose = 1 + n_verbose - n_noverbose ))
	if [[ ${#*} > 0 ]]
	then
		opt_outfile=$1 
	fi
	if [[ ${#*} > 1 ]]
	then
		builtin echo "$thisfcn: error: too many arguments" >&2
		return 1
	fi
	if [[ -n "$opt_outfile" ]]
	then
		outfile="$opt_outfile" 
	fi
	_omz_diag_dump_one_big_text &> "$outfile"
	if [[ $? != 0 ]]
	then
		builtin echo "$thisfcn: error while creating diagnostic dump; see $outfile for details"
	fi
	builtin echo
	builtin echo Diagnostic dump file created at: "$outfile"
	builtin echo
	builtin echo To share this with OMZ developers, post it as a gist on GitHub
	builtin echo at "https://gist.github.com" and share the link to the gist.
	builtin echo
	builtin echo "WARNING: This dump file contains all your zsh and omz configuration files,"
	builtin echo "so don't share it publicly if there's sensitive information in them."
	builtin echo builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	printf "]1337;SetUserVar=%s=%s" "$1" $(printf "%s" "$2" | base64 | tr -d '
') builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	echo "$1" >> /Users/sedatkilinc/__Places/paths.txt 	echo foo > "$HOME/unutmalist/foo$1.tmp"
	tail -n +1 ~/unutmalist/**/*$1* | sed '/foo/d'
	rm -i -f "$HOME/unutmalist/foo$1.tmp" 	$1 $2 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	for i in $(ls -1 "$1")
	do
		[ -e "$i/.git" ] && echo "$i is a repo" && giturlp $i || echo "$i is a NOT repo"
	done builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	[[ "$#" != 1 ]] && local b="$(git_current_branch)" 
	git push --force origin "${b:=$1}" 	export fff=vedat  builtin autoload -XU 	printf "]1337;RemoteHost=%s@%s" "$USER" "${iterm2_hostname-}"
	printf "]1337;CurrentDir=%s" "$PWD"
	iterm2_print_user_vars 	echo -e "\033[1;33m[WARNING]\033[0m  $*" 	if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]
	then
		git pull origin "${*}"
	else
		[[ "$#" == 0 ]] && local b="$(git_current_branch)" 
		git pull origin "${b:=$1}"
	fi 	if [ -n "$__EXECUTED_GIT_COMMAND" ] || [ ! -n "$ZSH_THEME_GIT_PROMPT_CACHE" ]
	then
		update_current_git_vars
		unset __EXECUTED_GIT_COMMAND
	fi 	if [ "$1" = $TRUE ]
	then
		return 0
	else
		return 1
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]
	then
		git push origin "${*}"
	else
		[[ "$#" == 0 ]] && local b="$(git_current_branch)" 
		git push origin "${b:=$1}"
	fi builtin autoload -XU builtin autoload -XU 	[[ "$#" != 1 ]] && local b="$(git_current_branch)" 
	git pull --rebase origin "${b:=$1}" builtin autoload -XU builtin autoload -XU builtin autoload -XU 	echo $(rvm_prompt_info || rbenv_prompt_info || chruby_prompt_info) builtin autoload -XU 	local val nm="$compstate[nmatches]" 
	[[ $# -eq 1 ]] && 2="$1" 
	if zstyle -a ":completion:${curcontext}:$1" list-colors val
	then
		zmodload -i zsh/complist
		if [[ "$1" = default ]]
		then
			_comp_colors=("$val[@]") 
		else
			_comp_colors+=("(${2})${(@)^val:#(|\(*\)*)}" "${(M@)val:#\(*\)*}") 
		fi
	elif [[ "$1" = default ]]
	then
		unset ZLS_COLORS ZLS_COLOURS
	fi
	if zstyle -s ":completion:${curcontext}:$1" show-ambiguity val
	then
		zmodload -i zsh/complist
		[[ $val = (yes|true|on) ]] && _ambiguous_color=4  || _ambiguous_color=$val 
	fi
	if zstyle -t ":completion:${curcontext}:$1" list-packed
	then
		compstate[list]="${compstate[list]} packed" 
	elif [[ $? -eq 1 ]]
	then
		compstate[list]="${compstate[list]:gs/packed//}" 
	else
		compstate[list]="$_saved_list" 
	fi
	if zstyle -t ":completion:${curcontext}:$1" list-rows-first
	then
		compstate[list]="${compstate[list]} rows" 
	elif [[ $? -eq 1 ]]
	then
		compstate[list]="${compstate[list]:gs/rows//}" 
	else
		compstate[list]="$_saved_list" 
	fi
	if zstyle -t ":completion:${curcontext}:$1" last-prompt
	then
		compstate[last_prompt]=yes 
	elif [[ $? -eq 1 ]]
	then
		compstate[last_prompt]='' 
	else
		compstate[last_prompt]="$_saved_lastprompt" 
	fi
	if zstyle -t ":completion:${curcontext}:$1" accept-exact
	then
		compstate[exact]=accept 
	elif [[ $? -eq 1 ]]
	then
		compstate[exact]='' 
	else
		compstate[exact]="$_saved_exact" 
	fi
	[[ _last_nmatches -ge 0 && _last_nmatches -ne nm ]] && _menu_style=("$_last_menu_style[@]" "$_menu_style[@]") 
	if zstyle -a ":completion:${curcontext}:$1" menu val
	then
		_last_nmatches=$nm 
		_last_menu_style=("$val[@]") 
	else
		_last_nmatches=-1 
	fi
	[[ "$_comp_force_list" != always ]] && zstyle -s ":completion:${curcontext}:$1" force-list val && [[ "$val" = always || ( "$val" = [0-9]## && ( -z "$_comp_force_list" || _comp_force_list -gt val ) ) ]] && _comp_force_list="$val"  builtin autoload -XU 	for code in {000..255}
	do
		print -P -- "$code: %{$FG[$code]%}$ZSH_SPECTRUM_TEXT%{$reset_color%}"
	done builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local format raw gopt
	if [[ "$1" = -e ]]
	then
		local expl ret=1 tag 
		_comp_mesg=yes 
		if (( $# > 2 ))
		then
			tag="$2" 
			shift
		else
			tag="$curtag" 
		fi
		_tags "$tag" && while _next_label "$tag" expl "$2"
		do
			compadd ${expl:/-X/-x}
			ret=0 
		done
		(( ! $compstate[nmatches] )) && [[ $compstate[insert] = *unambiguous* ]] && compstate[insert]= 
		return ret
	fi
	gopt=() 
	zparseopts -D -a gopt 1 2 V J
	_tags messages || return 1
	if [[ "$1" = -r ]]
	then
		raw=yes 
		shift
		format="$1" 
	else
		zstyle -s ":completion:${curcontext}:messages" format format || zstyle -s ":completion:${curcontext}:descriptions" format format
	fi
	if [[ -n "$format$raw" ]]
	then
		[[ -z "$raw" ]] && zformat -f format "$format" "d:$1" "${(@)argv[2,-1]}"
		builtin compadd "$gopt[@]" -x "$format"
		_comp_mesg=yes 
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	env ZSH=$ZSH sh $ZSH/tools/upgrade.sh builtin autoload -XU 	printf "]133;D;%s" "$STATUS"
	iterm2_print_state_data 	if [[ "$LASTWIDGET" = *vi-set-buffer ]]
	then
		zle .bracketed-paste
		return
	else
		local PASTED REPLY
		zle .bracketed-paste PASTED
	fi
	local bpm_emulate="$(emulate)" bpm_opts="$-" 
	emulate -L zsh
	local -a bpm_hooks bpm_inactive
	local bpm_func bpm_active bpm_keymap=$KEYMAP 
	if zstyle -a :bracketed-paste-magic paste-init bpm_hooks
	then
		for bpm_func in $bpm_hooks
		do
			if (( $+functions[$bpm_func] ))
			then
				() {
					emulate -L $bpm_emulate
					set -$bpm_opts
					$bpm_func || break
				}
			fi
		done
	fi
	zstyle -a :bracketed-paste-magic inactive-keys bpm_inactive
	if zstyle -s :bracketed-paste-magic active-widgets bpm_active '|'
	then
		integer bpm_mark=$MARK bpm_region=$REGION_ACTIVE 
		integer bpm_numeric=${NUMERIC:-1} 
		integer bpm_limit=$UNDO_LIMIT_NO bpm_undo=$UNDO_CHANGE_NO 
		zle .split-undo
		UNDO_LIMIT_NO=$UNDO_CHANGE_NO 
		BUFFER= 
		CURSOR=1 
		fc -p -a /dev/null 0 0
		if [[ $bmp_keymap = vicmd ]]
		then
			zle -K viins
		fi
		NUMERIC=1 
		zle -U - $PASTED
		while [[ -n $PASTED ]] && zle .read-command
		do
			PASTED=${PASTED#$KEYS} 
			if [[ $KEYS = ${(~j:|:)${(b)bpm_inactive}} ]]
			then
				zle .self-insert
			else
				case $REPLY in
					(${~bpm_active}) () {
							emulate -L $bpm_emulate
							set -$bpm_opts
							zle $REPLY -w
						} ;;
					(*) zle .self-insert ;;
				esac
			fi
		done
		PASTED=$BUFFER 
		zle -K $bpm_keymap
		fc -P
		MARK=$bpm_mark 
		REGION_ACTIVE=$bpm_region 
		NUMERIC=$bpm_numeric 
		zle .undo $bpm_undo
		UNDO_LIMIT_NO=$bpm_limit 
	fi
	if zstyle -a :bracketed-paste-magic paste-finish bpm_hooks
	then
		for bpm_func in $bpm_hooks
		do
			if (( $+functions[$bpm_func] ))
			then
				() {
					emulate -L $bpm_emulate
					set -$bpm_opts
					$bpm_func || break
				}
			fi
		done
	fi
	zle -U - $PASTED$'[201~'
	zle .bracketed-paste -- "$@"
	zle .split-undo
	if [[ -z $zle_highlight || -n ${(M)zle_highlight:#paste:*} ]]
	then
		zle -R
		zle .read-command && zle -U - $KEYS
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	date "+%Y%m%d" builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	_cd_options () {
		_arguments -s '-q[quiet, no output or use of hooks]' '-s[refuse to use paths with symlinks]' '(-P)-L[retain symbolic links ignoring CHASE_LINKS]' '(-L)-P[resolve symbolic links as CHASE_LINKS]'
	}
	setopt localoptions nonomatch
	local expl ret=1 curarg 
	integer argstart=2 noopts match mbegin mend 
	if (( CURRENT > 1 ))
	then
		while [[ $words[$argstart] = -* && argstart -lt CURRENT ]]
		do
			curarg=$words[$argstart] 
			[[ $curarg = -<-> ]] && break
			(( argstart++ ))
			[[ $curarg = -- ]] && noopts=1  && break
		done
	fi
	if [[ CURRENT -eq $((argstart+1)) ]]
	then
		local rep
		rep=(${~PWD/$words[$argstart]/*}~$PWD(-/)) 
		rep=(${${rep#${PWD%%$words[$argstart]*}}%${PWD#*$words[$argstart]}}) 
		(( $#rep )) && _wanted -C replacement strings expl replacement compadd -a rep
	else
		if [[ "$PREFIX" == (#b)(\~|)[^/]# && ( -n "$match[1]" || ( CURRENT -gt 1 && ! -o cdablevars ) ) ]]
		then
			_directory_stack && ret=0 
		fi
		local -a tmpWpath
		if [[ $PREFIX = (|*/)../* ]]
		then
			local tmpprefix
			tmpprefix=$(cd ${PREFIX%/*} >&/dev/null && print $PWD) 
			if [[ -n $tmpprefix ]]
			then
				tmpWpath=(-W $tmpprefix) 
				IPREFIX=${IPREFIX}${PREFIX%/*}/ 
				PREFIX=${PREFIX##*/} 
			fi
		fi
		if [[ $PREFIX != (\~|/|./|../)* && $IPREFIX != ../* ]]
		then
			local tmpcdpath alt
			alt=() 
			tmpcdpath=(${${(@)cdpath:#.}:#$PWD}) 
			(( $#tmpcdpath )) && alt=('path-directories:directory in cdpath:_path_files -W tmpcdpath -/') 
			if [[ -o cdablevars && -n "$PREFIX" && "$PREFIX" != <-> ]]
			then
				if [[ "$PREFIX" != */* ]]
				then
					alt=("$alt[@]" 'named-directories: : _tilde') 
				else
					local oipre="$IPREFIX" opre="$PREFIX" dirpre dir 
					dirpre="${PREFIX%%/*}/" 
					IPREFIX="$IPREFIX$dirpre" 
					eval "dir=( ~$dirpre )"
					PREFIX="${PREFIX#*/}" 
					[[ $#dir -eq 1 && "$dir[1]" != "~$dirpre" ]] && _wanted named-directories expl 'directory after cdablevar' _path_files -W dir -/ && ret=0 
					PREFIX="$opre" 
					IPREFIX="$oipre" 
				fi
			fi
			[[ CURRENT -ne 1 || ( -z "$path[(r).]" && $PREFIX != */* ) ]] && alt=("${cdpath+local-}directories:${cdpath+local }directory:_path_files ${(j: :)${(@q)tmpWpath}} -/" "$alt[@]") 
			if [[ CURRENT -eq argstart && noopts -eq 0 && $PREFIX = -* ]] && zstyle -t ":completion:${curcontext}:options" complete-options
			then
				alt=("$service-options:$service option:_cd_options" "$alt[@]") 
			fi
			_alternative "$alt[@]" && ret=0 
			return ret
		fi
		[[ CURRENT -ne 1 ]] && _wanted directories expl directory _path_files $tmpWpath -/ && ret=0 
		return ret
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	case "$2" in
		(git* | hub* | gh* | stg*) __EXECUTED_GIT_COMMAND=1  ;;
	esac builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local base_dir=$1 
	local name=$2 
	test -f $base_dir/plugins/$name/$name.plugin.zsh || test -f $base_dir/plugins/$name/_$name builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local SHA
	SHA=$(command git rev-parse HEAD 2> /dev/null)  && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER" builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	return 1 builtin autoload -XU 	unset __CURRENT_GIT_STATUS
	if [[ "$GIT_PROMPT_EXECUTABLE" == "python" ]]
	then
		local gitstatus="$__GIT_PROMPT_DIR/gitstatus.py" 
		_GIT_STATUS=`python ${gitstatus} 2>/dev/null` 
	fi
	if [[ "$GIT_PROMPT_EXECUTABLE" == "haskell" ]]
	then
		_GIT_STATUS=`git status --porcelain --branch &> /dev/null | $__GIT_PROMPT_DIR/src/.bin/gitstatus` 
	fi
	__CURRENT_GIT_STATUS=("${(@s: :)_GIT_STATUS}") 
	GIT_BRANCH=$__CURRENT_GIT_STATUS[1] 
	GIT_AHEAD=$__CURRENT_GIT_STATUS[2] 
	GIT_BEHIND=$__CURRENT_GIT_STATUS[3] 
	GIT_STAGED=$__CURRENT_GIT_STATUS[4] 
	GIT_CONFLICTS=$__CURRENT_GIT_STATUS[5] 
	GIT_CHANGED=$__CURRENT_GIT_STATUS[6] 
	GIT_UNTRACKED=$__CURRENT_GIT_STATUS[7]  builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	eval "export $1=$2" 	update_current_git_vars 	DEBUG=$FALSE  builtin autoload -XU 	mkdir "$LINKS/$1" builtin autoload -XU builtin autoload -XU builtin autoload -XU 	[[ $- = *e* ]]
	SAVED_OPT_E=$? 
	set +e builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	if [[ -n $CURRENT_BG ]]
	then
		echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
	else
		echo -n "%{%k%}"
	fi
	echo -n "%{%f%}"
	CURRENT_BG=''  builtin autoload -XU 	setopt localoptions noksharrays extendedglob
	local qkey="${(q)KEYS}" 
	local -a reply match mbegin mend
	if [[ "$KEYS" != "$qkey" ]]
	then
		local lbuf="$LBUFFER$qkey" 
		if [[ "${(Q)LBUFFER}$KEYS" == "${(Q)lbuf}" ]]
		then
			local -a words
			words=("${(@Q)${(z)lbuf}}") 
			local urlseps urlmetas urlglobbers localschema otherschema
			if [[ "$words[-1]" == (#b)([^:]##):* ]]
			then
				zstyle -s ":url-quote-magic:$match[1]" url-seps urlseps ''
				zstyle -s ":url-quote-magic:$match[1]" url-metas urlmetas ''
			fi
			zstyle -s :url-quote-magic url-globbers urlglobbers '|'
			zstyle -s :urlglobber url-other-schema otherschema '|'
			if [[ "$words[1]" == ${~urlglobbers} ]]
			then
				zstyle -s :urlglobber url-local-schema localschema '|'
			else
				localschema=' ' 
			fi
			case "$words[-1]" in
				(*[\'\"]*)  ;;
				((${~localschema}):/(|/localhost)/*) [[ "$urlseps" == *"$KEYS"* ]] && LBUFFER="$LBUFFER\"  ;;
				((${~otherschema}):*) [[ "$urlseps$urlmetas" == *"$KEYS"* ]] && LBUFFER="$LBUFFER\"  ;;
			esac
		fi
	fi
	zle .self-insert builtin autoload -XU builtin autoload -XU 	(( $+aliases[$1] )) && echo $aliases[$1] 	PATH2REPO='.' 
	if [ $# -eq 1 ]
	then
		PATH2REPO="$@" 
	fi
	cat $PATH2REPO/.git/config | grep -i url | cut -d'=' -f 2 builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local expl curcontext
	zstyle -T ":completion:${curcontext}:files" prefix-needed && [[ "$PREFIX" != [/~]* && compstate[nmatches] -ne 0 ]] && return 1
	_wanted files expl 'application file' _path_files -P "$PREFIX[1]" -W / builtin autoload -XU 	local curcontext=$curcontext ret=1 
	local -a context expl line state state_descr tmp
	local -A opt_args val_args
	_arguments -s -C : '(-a -b -e -f -R -t)-a+[specify application name]: :->applications' '(: * -)--args[pass remaining arguments to application]:*:::argument' '(-a -b -e -f -R -t)-b+[specify application bundle identifier]: :->bundle-ids' '(-a -b -e -f -R -t)-e[open with TextEdit]' '(-h)-f[open standard input with TextEdit or specified application]' '(-R)-F[open application with fresh state]' '-g[do not bring application to foreground]' '(-f)-h[open library header file]' '(-R)-n[always open new instance of application]' '(-a -b -e -f -F -n -s -t -W --args)-R[reveal in Finder]' '(-R)-s+[specify SDK name/version]: :->sdks' '(-a -b -e -f -R -t)-t[open with default text editor]' '(-R)-W[wait for application to exit]' '(-f)*: :->files' && ret=0 
	case $state in
		(applications) _alternative "commands: :_mac_applications" "files:: _open_absolute_application_path" && ret=0  ;;
		(bundle-ids) autoload -Uz zargs
			_retrieve_mac_apps
			tmp=(${(@)_mac_apps:#/System/Library/(Private|)Frameworks/*}) 
			tmp=(${(0)"$(
        _call_program bundle-ids \
          zargs -n300 -P2 -- ${(@q)tmp} -- mdls -rn kMDItemCFBundleIdentifier
      )"}) 
			tmp=(${(@)tmp:#\(null\)}) 
			_values 'bundle identifier' $tmp com.apple.TextEdit && ret=0  ;;
		(files) if (( $+opt_args[-h] ))
			then
				tmp=(/System/Library/Frameworks/*/Headers/*.h(#q-.N:t) /usr/local/include/**/*.h(#q-.N:t) /usr/include/**/*.h(#q-.N:t)) 
				_describe -t headers 'header file' tmp && ret=0 
			else
				_webbrowser && ret=0 
			fi ;;
		(sdks) tmp=(/Library/Developer/CommandLineTools/SDKs/*.*.sdk(#qN:t:r)) 
			if (( $#tmp ))
			then
				_describe -t sdks 'SDK name/version' tmp && ret=0 
			else
				_message -e sdks 'SDK name/version' && ret=0 
			fi ;;
	esac
	return ret builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	alias_value "$1" || echo "$1" builtin autoload -XU 	open http://borkware.com/quickies/one?topic=$1 builtin autoload -XU 	if [[ $1 = hosts ]]
	then
		sed 's/#.*//' /etc/$1 | grep -w $2
	elif [[ $2 = <-> ]]
	then
		grep ":$2:[^:]*$" /etc/$1
	else
		grep "^$2:" /etc/$1
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	if [[ -n "$(command git rev-list HEAD..origin/$(git_current_branch) 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_BEHIND"
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	PARAM1="$1" 
	PARAM2="$2" 
	lna_it () {
		for file in `ls $1`
		do
			ln -s $1/$file $2/$file
		done
	}
	lna_it "$PARAM1" "$PARAM2" 	if [[ "$#" == 0 ]]
	then
		ggl && ggp
	else
		ggl "${*}" && ggp "${*}"
	fi 	local tags def expl descr action mesgs nm="$compstate[nmatches]" subopts 
	local opt ws curcontext="$curcontext" 
	subopts=() 
	while getopts 'O:C:' opt
	do
		case "$opt" in
			(O) subopts=("${(@P)OPTARG}")  ;;
			(C) curcontext="${curcontext%:*}:$OPTARG"  ;;
		esac
	done
	shift OPTIND-1
	[[ "$1" = -(|-) ]] && shift
	mesgs=() 
	_tags "${(@)argv%%:*}"
	while _tags
	do
		for def
		do
			if _requested "${def%%:*}"
			then
				descr="${${def#*:}%%:*}" 
				action="${def#*:*:}" 
				_description "${def%%:*}" expl "$descr"
				if [[ "$action" = \ # ]]
				then
					mesgs=("$mesgs[@]" "${def%%:*}:$descr") 
				elif [[ "$action" = \(\(*\)\) ]]
				then
					eval ws\=\( "${action[3,-3]}" \)
					_describe -t "${def%%:*}" "$descr" ws -M 'r:|[_-]=* r:|=*' "$subopts[@]"
				elif [[ "$action" = \(*\) ]]
				then
					eval ws\=\( "${action[2,-2]}" \)
					_all_labels "${def%%:*}" expl "$descr" compadd "$subopts[@]" -a - ws
				elif [[ "$action" = \{*\} ]]
				then
					while _next_label "${def%%:*}" expl "$descr"
					do
						eval "$action[2,-2]"
					done
				elif [[ "$action" = \ * ]]
				then
					eval "action=( $action )"
					while _next_label "${def%%:*}" expl "$descr"
					do
						"$action[@]"
					done
				else
					eval "action=( $action )"
					while _next_label "${def%%:*}" expl "$descr"
					do
						"$action[1]" "$subopts[@]" "$expl[@]" "${(@)action[2,-1]}"
					done
				fi
			fi
		done
		[[ nm -ne compstate[nmatches] ]] && return 0
	done
	for descr in "$mesgs[@]"
	do
		_message -e "${descr%%:*}" "${descr#*:}"
	done
	return 1 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	PARAM=$1 
	r2_it () {
		grep -irl $PARAM "$@"
	}
	shift
	callfunction r2_it "$@" builtin autoload -XU builtin autoload -XU builtin autoload -XU 	OPT='' 
	if [ -n $3 ]
	then
		OPT=$3 
	fi
	ln -s$OPT "$PWD/$1" $2 builtin autoload -XU builtin autoload -XU builtin autoload -XU 	for i in $(ls -1 "$1")
	do
		[ -e "$i/.git" ] && echo "$i is a repo" && giturlp "$i" || echo "$i is a NOT repo"
	done 	tail -n 1 ~/unutmalist/*$1* builtin autoload -XU builtin autoload -XU 	if [[ -n "$(command git rev-list origin/$(git_current_branch)..HEAD 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_AHEAD"
	fi builtin autoload -XU builtin autoload -XU 	printf "]133;A" builtin autoload -XU builtin autoload -XU builtin autoload -XU 	if [ ! $1 ]
	then
		echo "Usage: lsgit branchname"
		return 1
	else
		git ls-tree -r $1 --name-only
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local expl pat
	(( ${#saliases} )) || return 1
	if (( ${#saliases} == 1 ))
	then
		pat="*.${(kq)saliases}" 
	else
		local -a tmpa
		tmpa=(${(kq)saliases}) 
		pat="*.(${(kj.|.)tmpa})" 
	fi
	_path_files "$@" -g $pat builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	tail -n +1 ~/unutmalist/**/*$1* builtin autoload -XU builtin autoload -XU builtin autoload -XU 	[[ _matcher_num -gt 1 || $compstate[ignored] -eq 0 ]] && return 1
	local comp
	integer ind
	if ! zstyle -a ":completion:${curcontext}:" completer comp
	then
		comp=("${(@)_completers[1,_completer_num-1]}") 
		ind=${comp[(I)_ignored(|:*)]} 
		(( ind )) && comp=("${(@)comp[ind,-1]}") 
	fi
	local _comp_no_ignore=yes tmp expl _completer _completer_num _matcher _c_matcher _matchers _matcher_num 
	_completer_num=1 
	for tmp in "$comp[@]"
	do
		if [[ "$tmp" = *:-* ]]
		then
			_completer="${${tmp%:*}[2,-1]//_/-}${tmp#*:}" 
			tmp="${tmp%:*}" 
		elif [[ $tmp = *:* ]]
		then
			_completer="${tmp#*:}" 
			tmp="${tmp%:*}" 
		else
			_completer="${tmp[2,-1]//_/-}" 
		fi
		curcontext="${curcontext/:[^:]#:/:${_completer}:}" 
		zstyle -a ":completion:${curcontext}:" matcher-list _matchers || _matchers=('') 
		_matcher_num=1 
		_matcher='' 
		for _c_matcher in "$_matchers[@]"
		do
			if [[ "$_c_matcher" == +* ]]
			then
				_matcher="$_matcher $_c_matcher[2,-1]" 
			else
				_matcher="$_c_matcher" 
			fi
			if [[ "$tmp" != _ignored ]] && "$tmp"
			then
				if zstyle -s ":completion:${curcontext}:" single-ignored tmp && [[ $compstate[old_list] != shown && $compstate[nmatches] -eq 1 ]]
				then
					case "$tmp" in
						(show) compstate[insert]='' compstate[list]='list force' tmp=''  ;;
						(menu) compstate[insert]=menu 
							_description original expl original
							compadd "$expl[@]" -S '' - "$PREFIX$SUFFIX" ;;
					esac
				fi
				return 0
			fi
			(( _matcher_num++ ))
		done
		(( _completer_num++ ))
	done
	return 1 builtin autoload -XU 	return 1 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local expl disp jobs job jids pfx='%' desc how expls sep 
	if [[ "$1" = -t ]]
	then
		zstyle -T ":completion:${curcontext}:jobs" prefix-needed && [[ "$PREFIX" != %* && compstate[nmatches] -ne 0 ]] && return 1
		shift
	fi
	zstyle -t ":completion:${curcontext}:jobs" prefix-hidden && pfx='' 
	zstyle -T ":completion:${curcontext}:jobs" verbose && desc=yes 
	if [[ "$1" = -r ]]
	then
		jids=("${(@k)jobstates[(R)running*]}") 
		shift
		expls='running job' 
	elif [[ "$1" = -s ]]
	then
		jids=("${(@k)jobstates[(R)suspended*]}") 
		shift
		expls='suspended job' 
	else
		[[ "$1" = - ]] && shift
		jids=("${(@k)jobtexts}") 
		expls=job 
	fi
	if [[ -n "$desc" ]]
	then
		disp=() 
		zstyle -s ":completion:${curcontext}:jobs" list-separator sep || sep=-- 
		for job in "$jids[@]"
		do
			[[ -n "$desc" ]] && disp=("$disp[@]" "${pfx}${(r:2:: :)job} $sep ${(r:COLUMNS-8:: :)jobtexts[$job]}") 
		done
	fi
	zstyle -s ":completion:${curcontext}:jobs" numbers how
	if [[ "$how" = (yes|true|on|1) ]]
	then
		jobs=("$jids[@]") 
	else
		local texts i text str tmp num max=0 
		texts=("$jobtexts[@]") 
		jobs=() 
		for i in "$jids[@]"
		do
			text="$jobtexts[$i]" 
			str="${text%% *}" 
			if [[ "$text" = *\ * ]]
			then
				text="${text#* }" 
			else
				text="" 
			fi
			tmp=("${(@M)texts:#${str}*}") 
			num=1 
			while [[ -n "$text" && $#tmp -ge 2 ]]
			do
				str="${str} ${text%% *}" 
				if [[ "$text" = *\ * ]]
				then
					text="${text#* }" 
				else
					text="" 
				fi
				tmp=("${(@M)texts:#${str}*}") 
				(( num++ ))
			done
			[[ num -gt max ]] && max="$num" 
			jobs=("$jobs[@]" "$str") 
		done
		if [[ "$how" = [0-9]## && max -gt how ]]
		then
			jobs=("$jids[@]") 
		else
			[[ -z "$pfx" && -n "$desc" ]] && disp=("${(@)disp#%}") 
		fi
	fi
	if [[ -n "$desc" ]]
	then
		_wanted jobs expl "$expls" compadd "$@" -ld disp - "%$^jobs[@]"
	else
		_wanted jobs expl "$expls" compadd "$@" - "%$^jobs[@]"
	fi builtin autoload -XU 	local virtualenv_path="$VIRTUAL_ENV" 
	if [[ -n $virtualenv_path && -n $VIRTUAL_ENV_DISABLE_PROMPT ]]
	then
		prompt_segment blue black "(`basename $virtualenv_path`)"
	fi builtin autoload -XU 	yell "$*"
	exit 111 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	TARGET='' 
	if [ -n $2 ]
	then
		TARGET="$2" 
		mkdirlinks $(dirname $TARGET)
	fi
	createlink "$1" ~/Desktop/LINKS/$TARGET 	"$@" || (
		[ $0 == "-bash" ] || dying "cannot $*"
	) 	emulate -L zsh
	integer bep_mark=$MARK bep_region=$REGION_ACTIVE 
	if (( REGION_ACTIVE && MARK < CURSOR ))
	then
		zle .exchange-point-and-mark
	fi
	if (( CURSOR ))
	then
		local -a bep_words=(${(z)LBUFFER}) 
		if [[ -n $bep_words[-1] && $LBUFFER = *$bep_words[-1] ]]
		then
			PASTED=$bep_words[-1]$PASTED 
			LBUFFER=${LBUFFER%${bep_words[-1]}} 
		fi
	fi
	if (( MARK > bep_mark ))
	then
		zle .exchange-point-and-mark
	fi
	REGION_ACTIVE=$bep_region  	local arguments is_gnu datef
	if ! _pick_variant gnu=gnu unix --help
	then
		arguments=('(-A)-a[list entries starting with .]' '(-a)-A[list all except . and ..]' '-d[list directory entries instead of contents]' '-L[list referenced file for sym link]' '-R[list subdirectories recursively]' '(-k)-h[print sizes in human readable form]' '(-h)-k[print sizes in kilobytes]' '-i[print file inode numbers]' '(-l -g -1 -C -m -x)-l[long listing]' '(-l -g -C -m -x)-1[single column output]' '(-l -g -1 -m -x)-C[list entries in columns sorted vertically]' '(-l -g -1 -C -x)-m[comma separated]' '(-l -g -1 -C -m)-x[sort horizontally]' '-s[display size of each file in blocks]' '(-u)-c[status change time]' '(-c)-u[access time]' '-r[reverse sort order]' '(-t)-S[sort by size]' '(-S)-t[sort by modification time]' '(-p)-F[append file type indicators]' '(-F)-p[append file type indicators for directory]' '-n[numeric uid, gid]' '(-B -b -w -q)-q[hide control chars]' '*: :_files') 
		if [[ "$OSTYPE" = (netbsd*|dragonfly*|freebsd*|openbsd*|darwin*) ]]
		then
			arguments+=('-T[show complete time information]' '(-a -A -r -S -t)-f[output is not sorted]') 
		fi
		if [[ $OSTYPE = (netbsd*|dragonfly*|freebsd*|openbsd*) ]]
		then
			arguments+=('-o[display file flags]') 
		fi
		if [[ $OSTYPE = (netbsd*|dragonfly*|freebsd*|darwin*) ]]
		then
			arguments+=('(-B -b -w -q)-B[print octal escapes for control characters]' '(-B -b -w -q)-b[as -B, but use C escape codes whenever possible]' '(-B -b -w -q)-w[print raw characters]' '-W[display whiteouts when scanning directories]') 
		fi
		if [[ $OSTYPE = (netbsd*|openbsd*|darwin*|solaris*) ]]
		then
			arguments+=('(-l -1 -C -m -x)-g[long listing but without owner information]') 
		fi
		if [[ $OSTYPE = netbsd* ]]
		then
			arguments+=('-M[output file sizes in comma-separated form]' '-O[output only leaf (non-directory) files]' '-P[print full pathname for each file]' "-X[don't cross mount points when recursing]") 
		fi
		if [[ $OSTYPE = (dragonfly*|freebsd*|openbsd*|darwin*) ]]
		then
			arguments+=('-H[follow symlinks on the command line]') 
		fi
		if [[ $OSTYPE = (dragonfly*|freebsd*|darwin*) ]]
		then
			arguments+=('-G[enable colorized output]' '-P[do not follow symlinks]') 
		fi
		if [[ $OSTYPE = (dragonfly*|freebsd*) ]]
		then
			arguments+=('(-A)-I[prevent -A from being automatically set for the super-user]') 
		fi
		if [[ $OSTYPE = dragonfly* ]]
		then
			arguments+=('-y[display FSMID in long listing]') 
		fi
		if [[ $OSTYPE = (freebsd*|darwin*) ]]
		then
			arguments+=('(-c -u)-U[file creation time]') 
		fi
		if [[ $OSTYPE = freebsd* ]]
		then
			arguments+=('-,[print file sizes grouped and separated by thousands]' '-D+[specify format for date]:format: _date_formats' '-y[with -t, sort filenames in the same order as the time]' '-Z[display MAC label]') 
		fi
		if [[ $OSTYPE = darwin* ]]
		then
			arguments+=('-@[display extended attribute keys and sizes in long listing]' '-e[display ACL in long listing]' '(-l -1 -C -m -x)-o[long listing but without group information]' '-O[display file flags]' '-v[print raw characters]') 
		fi
		if [[ $OSTYPE = solaris* ]]
		then
			arguments+=('(-q)-b[print octal escapes for control characters]' '(-l -1 -C -m -x)-o[long listing but without group information]' '(-l -t -s -r -a)-f[interpret each argument as a directory]' '(-E -l)-e[long listing with full and consistent date/time]' '(-e -l)-E[long listing with ISO format date/time]' '-H[follow symlinks on the command line]' '-v[long listing with verbose ACL information]' '-V[long listing with compact ACL information]' '-@[long listing with marker for extended attribute information]') 
		fi
	else
		[[ $PREFIX = *+* ]] && datef='formats:format: _date_formats' 
		arguments=('(--all -a -A --almost-all)'{--all,-a}'[list entries starting with .]' '(--almost-all -A -a --all)'{--almost-all,-A}'[list all except . and ..]' '--author[print the author of each file]' '(--ignore-backups -B)'{--ignore-backups,-B}"[don't list entries ending with ~]" '(--directory -d)'{--directory,-d}'[list directory entries instead of contents]' '(--dired -D)'{--dired,-D}"[generate output designed for Emacs' dired mode]" '*'{--ignore=,-I+}"[don't list entries matching pattern]:pattern: " '(--dereference -L --dereference-command-line -H --dereference-command-line-symlink-to-dir)'{--dereference,-L}'[list referenced file for sym link]' '(--dereference -L --dereference-command-line -H --dereference-command-line-symlink-to-dir)'{--dereference-command-line,-H}'[follow symlink on the command line]' '(--dereference -L --dereference-command-line -H)'--dereference-command-line-symlink-to-dir '(--recursive -R)'{--recursive,-R}'[list subdirectories recursively]' '(--no-group -G)'{--no-group,-G}'[inhibit display of group information]' '(--block-size --human-readable -h --si --kilobytes -k)'{--human-readable,-h}'[print sizes in human readable form]' '(--block-size --human-readable -h --si --kilobytes -k)--si[sizes in human readable form; powers of 1000]' '(--inode -i)'{--inode,-i}'[print file inode numbers]' '(--format -l -g -o -1 -C -m -x)-l[long listing]' '(--format -l -1 -C -m -x)-g[long listing but without owner information]' --group-directories-first '(--format -l --no-group -G -1 -C -m -x)-o[no group, long]' '(--format -l -g -o -C -m -x)-1[single column output]' '(--format -l -g -o -1 -m -x)-C[list entries in columns sorted vertically]' '(--format -l -g -o -1 -C -x)-m[comma separated]' '(--format -l -g -o -1 -C -m)-x[sort horizontally]' '(-l -g -o -1 -C -m -x)--format=[specify output format]:format:(verbose long commas horizontal across vertical single-column)' '(--size -s -f)'{--size,-s}'[display size of each file in blocks]' '(--time -u)-c[status change time]' '(--time -c)-u[access time]' '(-c -u)--time=[specify time to show]:time:(ctime status use atime access)' '--time-style=[show times using specified style]:style: _alternative "time-styles\:time style\:(full-iso long-iso iso locale)" $datef' '(-a --all -U -l --format -s --size -t --sort --full-time)-f[unsorted, all, short list]' '(--reverse -r -U -f)'{--reverse,-r}'[reverse sort order]' '(--sort -t -U -v -X)-S[sort by size]' '(--sort -S -U -v -X)-t[sort by modification time]' '(--sort -S -t -v -X)-U[unsorted]' '(--sort -S -t -U -X)-v[sort by version (filename treated numerically)]' '(--sort -S -t -U -v)-X[sort by extension]' '(-S -t -U -v -X)--sort=[specify sort key]:sort key:(size time none version extension)' '--color=-[control use of color]:color:(never always auto)' "*--hide=[like -I, but overridden by -a or -A]:pattern: " '--hyperlink=[output terminal codes to link files using file::// URI]::when:(none auto always)' '(--classify -F --indicator-style -p --file-type)'{--classify,-F}'[append file type indicators]' '(--file-type -p --indicator-style -F --classify)--file-type[append file type indicators except *]' '(--file-type -p --indicator-style -F --classify)-p[append / to directories]' '(-F --classify -p --file-type)--indicator-style=[specify indicator style]:indicator style:(none file-type classify slash)' '(-f)--full-time[list both full date and full time]' '(--block-size --human-readable -h --si --kilobytes -k)'{--kilobytes,-k}'[use block size of 1k]' '(--human-readable -h --si --kilobytes -k)--block-size=[specify block size]:block size (bytes):(K M G T P E Z Y KB MB TB PB EB ZB YB)' '(--numeric-uid-gid -n)'{--numeric-uid-gid,-n}'[numeric uid, gid]' '(--tabsize -T)'{--tabsize=,-T+}'[specify tab size]:tab size' '(--width -w)'{--width=,-w+}'[specify screen width]:screen width' '(--quoting-style -b --escape -N --literal -Q --quote-name)'{--escape,-b}'[print octal escapes for control characters]' '(--quoting-style -b --escape -N --literal -Q --quote-name)'{--literal,-N}'[print entry names without quoting]' '(--quoting-style -b --escape -N --literal -Q --quote-name)'{--quote-name,-Q}'[quote names]' '(-b --escape -N --literal -Q --quote-name)--quoting-style=[specify quoting style]:quoting style:(literal shell shell-always c escape clocale locale)' '(--hide-control-chars -q --show-control-chars)'{--hide-control-chars,-q}'[hide control chars]' '(-q --hide-control-chars)--show-control-chars' '(- :)--help[display help information]' '(- :)--version[display version information]' '*:files:_files') 
		if [[ $OSTYPE = linux* ]]
		then
			arguments+=('(-Z --context)'{-Z,--context}'[print any security context of each file]') 
		fi
	fi
	_arguments -s -S : $arguments builtin autoload -XU builtin autoload -XU 	echo -e "\033[1;31m[FATAL]\033[0m  $*"
	echo "shell is about to get closed."
	echo "Exiting in 3 seconds"
	echo "CTRL-C to interrupt exiting"
	sleep 3
	exit 1 	emulate -L zsh
	local -a hooktypes
	hooktypes=(chpwd precmd preexec periodic zshaddhistory zshexit zsh_directory_name) 
	local usage="Usage: add-zsh-hook hook function
Valid hooks are:
  $hooktypes" 
	local opt
	local -a autoopts
	integer del list help
	while getopts "dDhLUzk" opt
	do
		case $opt in
			(d) del=1  ;;
			(D) del=2  ;;
			(h) help=1  ;;
			(L) list=1  ;;
			([Uzk]) autoopts+=(-$opt)  ;;
			(*) return 1 ;;
		esac
	done
	shift $(( OPTIND - 1 ))
	if (( list ))
	then
		typeset -mp "(${1:-${(@j:|:)hooktypes}})_functions"
		return $?
	elif (( help || $# != 2 || ${hooktypes[(I)$1]} == 0 ))
	then
		print -u$(( 2 - help )) $usage
		return $(( 1 - help ))
	fi
	local hook="${1}_functions" 
	local fn="$2" 
	if (( del ))
	then
		if (( ${(P)+hook} ))
		then
			if (( del == 2 ))
			then
				set -A $hook ${(P)hook:#${~fn}}
			else
				set -A $hook ${(P)hook:#$fn}
			fi
			if (( ! ${(P)#hook} ))
			then
				unset $hook
			fi
		fi
	else
		if (( ${(P)+hook} ))
		then
			if (( ${${(P)hook}[(I)$fn]} == 0 ))
			then
				typeset -ga $hook
				set -A $hook ${(P)hook} $fn
			fi
		else
			typeset -ga $hook
			set -A $hook $fn
		fi
		autoload $autoopts -- $fn
	fi 	dscl . -list /Users | while read user
	do
		printf "$user "
		dsmemberutil checkmembership -U "$user" -G "$*"
	done | grep "is a member" | cut -d " " -f 1 builtin autoload -XU 	echo "run"
	: ${TMPDIR=/Users/sedatkilinc/tmp}
	{
		tmp=$TMPDIR 
	} 	echoti rmkx 	local comp pat val name i ret=1 _compskip="$_compskip" 
	local curcontext="$curcontext" service str noskip 
	local -a match mbegin mend
	if [[ "$1" = -s ]]
	then
		noskip=yes 
		shift
	fi
	[[ -z "$noskip" ]] && _compskip= 
	curcontext="${curcontext%:*:*}:${1}:" 
	shift
	if [[ "$_compskip" != (all|*patterns*) ]]
	then
		for str in "$@"
		do
			[[ -n "$str" ]] || continue
			service="${_services[$str]:-$str}" 
			for i in "${(@)_patcomps[(K)$str]}"
			do
				if [[ $i = (#b)"="([^=]#)"="(*) ]]
				then
					service=$match[1] 
					i=$match[2] 
				fi
				eval "$i" && ret=0 
				if [[ "$_compskip" = *patterns* ]]
				then
					break
				elif [[ "$_compskip" = all ]]
				then
					_compskip='' 
					return ret
				fi
			done
		done
	fi
	ret=1 
	for str in "$@"
	do
		[[ -n "$str" ]] || continue
		str=${(Q)str} 
		name="$str" 
		comp="${_comps[$str]}" 
		service="${_services[$str]:-$str}" 
		[[ -z "$comp" ]] || break
	done
	if [[ -n "$comp" && "$name" != "${argv[-1]}" ]]
	then
		_compskip=patterns 
		eval "$comp" && ret=0 
		[[ "$_compskip" = (all|*patterns*) ]] && return ret
	fi
	if [[ "$_compskip" != (all|*patterns*) ]]
	then
		for str
		do
			[[ -n "$str" ]] || continue
			service="${_services[$str]:-$str}" 
			for i in "${(@)_postpatcomps[(K)$str]}"
			do
				_compskip=default 
				eval "$i" && ret=0 
				if [[ "$_compskip" = *patterns* ]]
				then
					break
				elif [[ "$_compskip" = all ]]
				then
					_compskip='' 
					return ret
				fi
			done
		done
	fi
	[[ "$name" = "${argv[-1]}" && -n "$comp" && "$_compskip" != (all|*default*) ]] && service="${_services[$name]:-$name}"  && eval "$comp" && ret=0 
	_compskip='' 
	return ret builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local long cmd="$words[1]" descr odescr mesg subopts opt opt2 usecc autod 
	local oldcontext="$curcontext" hasopts rawret optarg singopt alwopt 
	local setnormarg start rest
	local -a match mbegin mend
	subopts=() 
	singopt=() 
	while [[ "$1" = -([AMO]*|[CRSWnsw]) ]]
	do
		case "$1" in
			(-C) usecc=yes 
				shift ;;
			(-O) subopts=("${(@P)2}") 
				shift 2 ;;
			(-O*) subopts=("${(@P)${1[3,-1]}}") 
				shift ;;
			(-R) rawret=yes 
				shift ;;
			(-n) setnormarg=yes 
				NORMARG=-1 
				shift ;;
			(-w) optarg=yes 
				shift ;;
			(-W) alwopt=arg 
				shift ;;
			(-[Ss]) singopt+=($1) 
				shift ;;
			(-[AM]) singopt+=($1 $2) 
				shift 2 ;;
			(-[AM]*) singopt+=($1) 
				shift ;;
		esac
	done
	[[ $1 = ':' ]] && shift
	singopt+=(':') 
	[[ "$PREFIX" = [-+] ]] && alwopt=arg 
	long=$argv[(I)--] 
	if (( long ))
	then
		local name tmp tmpargv
		tmpargv=("${(@)argv[1,long-1]}") 
		name=${~words[1]}  2> /dev/null
		[[ "$name" = [^/]*/* ]] && name="$PWD/$name" 
		name="_args_cache_${name}" 
		name="${name//[^a-zA-Z0-9_]/_}" 
		if (( ! ${(P)+name} ))
		then
			local iopts sopts lflag pattern tmpo dir cur cache
			typeset -Ua lopts
			cache=() 
			set -- "${(@)argv[long+1,-1]}"
			iopts=() 
			sopts=() 
			while [[ "$1" = -[lis]* ]]
			do
				if [[ "$1" = -l ]]
				then
					lflag='-l' 
					shift
					continue
				fi
				if [[ "$1" = -??* ]]
				then
					tmp="${1[3,-1]}" 
					cur=1 
				else
					tmp="$2" 
					cur=2 
				fi
				if [[ "$tmp[1]" = '(' ]]
				then
					tmp=(${=tmp[2,-2]}) 
				else
					tmp=("${(@P)tmp}") 
				fi
				if [[ "$1" = -i* ]]
				then
					iopts+=("$tmp[@]") 
				else
					sopts+=("$tmp[@]") 
				fi
				shift cur
			done
			tmp=() 
			_call_program $lflag options ${~words[1]} --help 2>&1 | while IFS= read -r opt
			do
				if (( ${#tmp} ))
				then
					if [[ $opt = [[:space:]][[:space:]][[:space:]]*[[:alpha:]]* ]]
					then
						opt=${opt##[[:space:]]##} 
						lopts+=("${^tmp[@]}":${${${opt//:/-}//\[/(}//\]/)}) 
						tmp=() 
						continue
					else
						lopts+=("${^tmp[@]}":) 
						tmp=() 
					fi
				fi
				while [[ $opt = [,[:space:]]#(#b)(-[^,[:space:]]#)(*) ]]
				do
					start=${match[1]} 
					rest=${match[2]} 
					if [[ -z ${tmp[(r)${start%%[^a-zA-Z0-9_-]#}]} ]]
					then
						if [[ $start = (#b)(*)\[(*)\](*) ]]
						then
							tmp+=("${match[1]}${match[2]}${match[3]}" "${match[1]}${match[3]}") 
						else
							tmp+=($start) 
						fi
					fi
					opt=$rest 
				done
				opt=${opt## [^[:space:]]##  } 
				opt=${opt##[[:space:]]##} 
				if [[ -n $opt ]]
				then
					lopts+=("${^tmp[@]}":${${${opt//:/-}//\[/(}//\]/)}) 
					tmp=() 
				fi
			done
			if (( ${#tmp} ))
			then
				lopts+=("${^tmp[@]}":) 
			fi
			tmp=() 
			for opt in "${(@)${(@)lopts:#--}%%[\[:=]*}"
			do
				let "$tmpargv[(I)(|\([^\)]#\))(|\*)${opt}(|[-+]|=(|-))(|\[*\])(|:*)]" || tmp+=("$lopts[(r)$opt(|[\[:=]*)]") 
			done
			lopts=("$tmp[@]") 
			while (( $#iopts ))
			do
				lopts=(${lopts:#$~iopts[1](|[\[:=]*)}) 
				shift iopts
			done
			while (( $#sopts ))
			do
				lopts+=(${lopts/$~sopts[1]/$sopts[2]}) 
				shift 2 sopts
			done
			argv+=('*=FILE*:file:_files' '*=(DIR|PATH)*:directory:_files -/' '*=*:=: ' '*: :  ') 
			while (( $# ))
			do
				pattern="${${${(M)1#*[^\]:}[1,-2]}//\\:/:}" 
				descr="${1#${pattern}}" 
				if [[ "$pattern" = *\(-\) ]]
				then
					pattern="$pattern[1,-4]" 
					dir=- 
				else
					dir= 
				fi
				shift
				tmp=("${(@M)lopts:##$~pattern:*}") 
				lopts=("${(@)lopts:##$~pattern:*}") 
				(( $#tmp )) || continue
				opt='' 
				tmp=("${(@)tmp%:}") 
				tmpo=("${(@M)tmp:#[^:]##\[\=*}") 
				if (( $#tmpo ))
				then
					tmp=("${(@)tmp:#[^:]##\[\=*}") 
					for opt in "$tmpo[@]"
					do
						if [[ $opt = (#b)(*):([^:]#) ]]
						then
							opt=$match[1] 
							odescr="[${match[2]}]" 
						else
							odescr= 
						fi
						if [[ $opt = (#b)(*)\[\=* ]]
						then
							opt2=${${match[1]}//[^a-zA-Z0-9_-]}=-${dir}${odescr} 
						else
							opt2=${${opt}//[^a-zA-Z0-9_-]}=${dir}${odescr} 
						fi
						if [[ "$descr" = :\=* ]]
						then
							cache+=("${opt2}::${(L)${opt%\]}#*\=}: ") 
						elif [[ "$descr" = ::* ]]
						then
							cache+=("${opt2}${descr}") 
						else
							cache+=("${opt2}:${descr}") 
						fi
					done
				fi
				tmpo=("${(@M)tmp:#[^:]##\=*}") 
				if (( $#tmpo ))
				then
					tmp=("${(@)tmp:#[^:]##\=*}") 
					for opt in "$tmpo[@]"
					do
						if [[ $opt = (#b)(*):([^:]#) ]]
						then
							opt=$match[1] 
							odescr="[${match[2]}]" 
						else
							odescr= 
						fi
						opt2="${${opt%%\=*}//[^a-zA-Z0-9_-]}=${dir}${odescr}" 
						if [[ "$descr" = :\=* ]]
						then
							cache+=("${opt2}:${(L)${opt%\]}#*\=}: ") 
						else
							cache+=("${opt2}${descr}") 
						fi
					done
				fi
				if (( $#tmp ))
				then
					tmp=("${(@)^${(@)tmp:#^*:*}//:/[}]" "${(@)${(@)tmp:#*:*}//[^a-zA-Z0-9_-]}") 
					if [[ -n "$descr" && "$descr" != ': :  ' ]]
					then
						cache+=("${(@)^tmp}${descr}") 
					else
						cache+=("$tmp[@]") 
					fi
				fi
			done
			set -A "$name" "${(@)cache:# #}"
		fi
		set -- "$tmpargv[@]" "${(@P)name}"
	fi
	zstyle -s ":completion:${curcontext}:options" auto-description autod
	if (( $# )) && comparguments -i "$autod" "$singopt[@]" "$@"
	then
		local action noargs aret expl local tried ret=1 
		local next direct odirect equal single matcher matched ws tmp1 tmp2 tmp3
		local opts subc tc prefix suffix descrs actions subcs anum
		local origpre="$PREFIX" origipre="$IPREFIX" nm="$compstate[nmatches]" 
		if comparguments -D descrs actions subcs
		then
			if comparguments -O next direct odirect equal
			then
				opts=yes 
				_tags "$subcs[@]" options
			else
				_tags "$subcs[@]"
			fi
		else
			if comparguments -a
			then
				noargs='no more arguments' 
			else
				noargs='no arguments' 
			fi
			if comparguments -O next direct odirect equal
			then
				opts=yes 
				_tags options
			elif [[ $? -eq 2 ]]
			then
				compadd -Q - "${PREFIX}${SUFFIX}"
				return 0
			else
				_message "$noargs"
				return 1
			fi
		fi
		comparguments -M matcher
		context=() 
		state=() 
		state_descr=() 
		while true
		do
			while _tags
			do
				anum=1 
				if [[ -z "$tried" ]]
				then
					while [[ anum -le $#descrs ]]
					do
						action="$actions[anum]" 
						descr="$descrs[anum]" 
						subc="$subcs[anum++]" 
						if [[ $subc = argument* && -n $setnormarg ]]
						then
							comparguments -n NORMARG
						fi
						if [[ -n "$matched" ]] || _requested "$subc"
						then
							curcontext="${oldcontext%:*}:$subc" 
							_description "$subc" expl "$descr"
							if [[ "$action" = \=\ * ]]
							then
								action="$action[3,-1]" 
								words=("$subc" "$words[@]") 
								(( CURRENT++ ))
							fi
							if [[ "$action" = -\>* ]]
							then
								action="${${action[3,-1]##[ 	]#}%%[ 	]#}" 
								if (( ! $state[(I)$action] ))
								then
									comparguments -W line opt_args
									state+=("$action") 
									state_descr+=("$descr") 
									if [[ -n "$usecc" ]]
									then
										curcontext="${oldcontext%:*}:$subc" 
									else
										context+=("$subc") 
									fi
									compstate[restore]='' 
									aret=yes 
								fi
							else
								if [[ -z "$local" ]]
								then
									local line
									typeset -A opt_args
									local=yes 
								fi
								comparguments -W line opt_args
								if [[ "$action" = \ # ]]
								then
									_message -e "$subc" "$descr"
									mesg=yes 
									tried=yes 
									alwopt=${alwopt:-yes} 
								elif [[ "$action" = \(\(*\)\) ]]
								then
									eval ws\=\( "${action[3,-3]}" \)
									_describe -t "$subc" "$descr" ws -M "$matcher" "$subopts[@]" || alwopt=${alwopt:-yes} 
									tried=yes 
								elif [[ "$action" = \(*\) ]]
								then
									eval ws\=\( "${action[2,-2]}" \)
									_all_labels "$subc" expl "$descr" compadd "$subopts[@]" -a - ws || alwopt=${alwopt:-yes} 
									tried=yes 
								elif [[ "$action" = \{*\} ]]
								then
									while _next_label "$subc" expl "$descr"
									do
										eval "$action[2,-2]" && ret=0 
									done
									(( ret )) && alwopt=${alwopt:-yes} 
									tried=yes 
								elif [[ "$action" = \ * ]]
								then
									eval "action=( $action )"
									while _next_label "$subc" expl "$descr"
									do
										"$action[@]" && ret=0 
									done
									(( ret )) && alwopt=${alwopt:-yes} 
									tried=yes 
								else
									eval "action=( $action )"
									while _next_label "$subc" expl "$descr"
									do
										"$action[1]" "$subopts[@]" "$expl[@]" "${(@)action[2,-1]}" && ret=0 
									done
									(( ret )) && alwopt=${alwopt:-yes} 
									tried=yes 
								fi
							fi
						fi
					done
				fi
				if _requested options && [[ -z "$hasopts" && -z "$matched" && ( -z "$aret" || "$PREFIX" = "$origpre" ) ]] && {
						! zstyle -T ":completion:${oldcontext%:*}:options" prefix-needed || [[ "$origpre" = [-+]* || -z "$aret$mesg$tried" ]]
					}
				then
					local prevpre="$PREFIX" previpre="$IPREFIX" prevcontext="$curcontext" 
					curcontext="${oldcontext%:*}:options" 
					hasopts=yes 
					PREFIX="$origpre" 
					IPREFIX="$origipre" 
					if [[ -z "$alwopt" || -z "$tried" || "$alwopt" = arg ]] && comparguments -s single
					then
						if [[ "$single" = direct ]]
						then
							_all_labels options expl option compadd -QS '' - "${PREFIX}${SUFFIX}"
						elif [[ -z "$optarg" && "$single" = next ]]
						then
							_all_labels options expl option compadd -Q - "${PREFIX}${SUFFIX}"
						elif [[ "$single" = equal ]]
						then
							_all_labels options expl option compadd -QqS= - "${PREFIX}${SUFFIX}"
						else
							tmp1=("$next[@]" "$direct[@]" "$odirect[@]" "$equal[@]") 
							[[ "$PREFIX" = [-+]* ]] && tmp1=("${(@M)tmp1:#${PREFIX[1]}*}") 
							[[ "$single" = next ]] && tmp1=("${(@)tmp1:#[-+]${PREFIX[-1]}((#e)|:*)}") 
							[[ "$PREFIX" != --* ]] && tmp1=("${(@)tmp1:#--*}") 
							tmp3=("${(M@)tmp1:#[-+]?[^:]*}") 
							tmp1=("${(M@)tmp1:#[-+]?(|:*)}") 
							tmp2=("${PREFIX}${(@M)^${(@)${(@)tmp1%%:*}#[-+]}:#?}") 
							_describe -O option tmp1 tmp2 -Q -S '' -- tmp3 -Q
							[[ -n "$optarg" && "$single" = next && nm -eq $compstate[nmatches] ]] && _all_labels options expl option compadd -Q - "${PREFIX}${SUFFIX}"
						fi
						single=yes 
					else
						next+=("$odirect[@]") 
						_describe -O option next -Q -M "$matcher" -- direct -QS '' -M "$matcher" -- equal -QqS= -M "$matcher"
					fi
					PREFIX="$prevpre" 
					IPREFIX="$previpre" 
					curcontext="$prevcontext" 
				fi
				[[ -n "$tried" && "${${alwopt:+$origpre}:-$PREFIX}" != [-+]* ]] && break
			done
			if [[ -n "$opts" && -z "$aret" && -z "$matched" && ( -z "$tried" || -n "$alwopt" ) && nm -eq compstate[nmatches] ]]
			then
				PREFIX="$origpre" 
				IPREFIX="$origipre" 
				prefix="${PREFIX#*\=}" 
				suffix="$SUFFIX" 
				PREFIX="${PREFIX%%\=*}" 
				SUFFIX='' 
				compadd -M "$matcher" -D equal - "${(@)equal%%:*}"
				if [[ $#equal -eq 1 ]]
				then
					PREFIX="$prefix" 
					SUFFIX="$suffix" 
					IPREFIX="${IPREFIX}${equal[1]%%:*}=" 
					matched=yes 
					comparguments -L "${equal[1]%%:*}" descrs actions subcs
					_tags "$subcs[@]"
					continue
				fi
			fi
			break
		done
		[[ -z "$aret" || -z "$usecc" ]] && curcontext="$oldcontext" 
		if [[ -n "$aret" ]]
		then
			[[ -n $rawret ]] && return 300
		else
			[[ -n "$noargs" && nm -eq "$compstate[nmatches]" ]] && _message "$noargs"
		fi
		[[ nm -ne "$compstate[nmatches]" ]]
	else
		return 1
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	mkdir -p "$@" && cd "$_" builtin autoload -XU builtin autoload -XU 	local args
	if _pick_variant gnu=GNU unix --version
	then
		args=('(-b --backup -n --no-clobber)--backup=[make a backup of each existing destination file]: : _values "backup type"
      {none,off}"[never make backups]"
      {numbered,t}"[make numbered backups]"
      {existing,nil}"[numbered backups, if they already exist]"
      {simple,never}"[always make simple backups]"' '(-b --backup -n --no-clobber)-b[make a backup of each existing destination file]' '(-f --force -i --interactive -n --no-clobber)'{-f,--force}"[don't prompt before overwriting]" '(-f --force -i --interactive -n --no-clobber)'{-i,--interactive}'[prompt before overwriting existing file]' '--strip-trailing-slashes[remove any trailing slashes from each source argument]' '(-S --suffix)'{-S+,--suffix=}'[specify the backup suffix]:backup suffix [~]' '(-t --target-directory)'{-t+,--target-directory=}'[move all source arguments into specified directory]:directory:_directories' '(-T --no-target-directory)'{-T,--no-target-directory}'[treat final argument as a normal file]' '(-u --update)'{-u,--update}'[move only when destination file is older or missing]' '(-v --verbose)'{-v,--verbose}'[show file names after they are moved]' '(- *)--help[display usage information]' '(- *)--version[display version information]') 
		[[ $OSTYPE = linux* ]] && args+=('(-Z --context)'{-Z,--context}'[set SELinux security context of destination file to default type]') 
	else
		local pattern arg
		args=("(-i -n)-f[don't prompt before overwriting]" '(-f -n)-i[prompt before overwriting existing file]') 
		for pattern arg in '(darwin|dragonfly|freebsd)*' "(-f -i)-n[don't overwrite existing file]" '(darwin|dragonfly|*bsd)*' '-v[show file names after they are moved]' '(dragonfly|freebsd)*' "-h[if target is a symlink to a directory, don't follow it]"
		do
			[[ $OSTYPE = $~pattern ]] && args+=($arg) 
		done
	fi
	_arguments -s -S $args '*:file:_files' 	fc -l 1 | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl | head -n20 builtin autoload -XU builtin autoload -XU 	local ctl
	if {
			zstyle -s ":completion:${curcontext}:" use-compctl ctl || zmodload -e zsh/compctl
		} && [[ "$ctl" != (no|false|0|off) ]]
	then
		local opt
		opt=() 
		[[ "$ctl" = *first* ]] && opt=(-T) 
		[[ "$ctl" = *default* ]] && opt=("$opt[@]" -D) 
		compcall "$opt[@]" || return 0
	fi
	_files "$@" && return 0
	if [[ -o magicequalsubst && "$PREFIX" = *\=* ]]
	then
		compstate[parameter]="${PREFIX%%\=*}" 
		compset -P 1 '*='
		_value "$@"
	else
		return 1
	fi builtin autoload -XU builtin autoload -XU 	(( $+commands[git] )) || return
	if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]
	then
		return
	fi
	local PL_BRANCH_CHAR
	() {
		local LC_ALL="" LC_CTYPE="en_US.UTF-8" 
		PL_BRANCH_CHAR=$'' 
	}
	local ref dirty mode repo_path
	if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1)
	then
		repo_path=$(git rev-parse --git-dir 2>/dev/null) 
		dirty=$(parse_git_dirty) 
		ref=$(git symbolic-ref HEAD 2> /dev/null)  || ref="➦ $(git rev-parse --short HEAD 2> /dev/null)" 
		if [[ -n $dirty ]]
		then
			prompt_segment yellow black
		else
			prompt_segment green $CURRENT_FG
		fi
		if [[ -e "${repo_path}/BISECT_LOG" ]]
		then
			mode=" <B>" 
		elif [[ -e "${repo_path}/MERGE_HEAD" ]]
		then
			mode=" >M<" 
		elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]
		then
			mode=" >R>" 
		fi
		setopt promptsubst
		autoload -Uz vcs_info
		zstyle ':vcs_info:*' enable git
		zstyle ':vcs_info:*' get-revision true
		zstyle ':vcs_info:*' check-for-changes true
		zstyle ':vcs_info:*' stagedstr '✚'
		zstyle ':vcs_info:*' unstagedstr '●'
		zstyle ':vcs_info:*' formats ' %u%c'
		zstyle ':vcs_info:*' actionformats ' %u%c'
		vcs_info
		echo -n "${ref/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
	fi 	emulate -L zsh
	if [[ $OSTYPE == darwin* ]]
	then
		pbpaste
	elif [[ $OSTYPE == cygwin* ]]
	then
		cat /dev/clipboard
	else
		if (( $+commands[xclip] ))
		then
			xclip -out -selection clipboard
		elif (( $+commands[xsel] ))
		then
			xsel --clipboard --output
		else
			print "clipcopy: Platform $OSTYPE not supported or xclip/xsel not installed" >&2
			return 1
		fi
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	echo "$1" | tr -d - builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local -aU insecure_dirs
	insecure_dirs=(${(f@):-"$(compaudit 2>/dev/null)"}) 
	[[ -z "${insecure_dirs}" ]] && return
	print "[oh-my-zsh] Insecure completion-dependent directories detected:"
	ls -ld "${(@)insecure_dirs}"
	cat <<EOD

[oh-my-zsh] For safety, we will not load completions from these directories until
[oh-my-zsh] you fix their permissions and ownership and restart zsh.
[oh-my-zsh] See the above list for directories with group or other writability.

[oh-my-zsh] To fix your permissions you can do so by disabling
[oh-my-zsh] the write permission of "group" and "others" and making sure that the
[oh-my-zsh] owner of these directories is either root or your current user.
[oh-my-zsh] The following command may help:
[oh-my-zsh]     compaudit | xargs chmod g-w,o-w

[oh-my-zsh] If the above didn't help or you want to skip the verification of
[oh-my-zsh] insecure directories you can set the variable ZSH_DISABLE_COMPFIX to
[oh-my-zsh] "true" before oh-my-zsh is sourced in your zshrc file.

EOD builtin autoload -XU builtin autoload -XU 	[ -n "$1" ] && SP="$1"  || SP="." 
	[ -n "$2" ] && EXT="$2"  || EXT=".*" 
	find "$SP" -maxdepth 1 ! -type l | grep -e "$EXT$" builtin autoload -XU 	STATE="off" 
	if [ "$DEBUG" = $TRUE ]
	then
		STATE="on" 
	fi
	echo "DEBUG is $STATE" builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	command git config user.email 2> /dev/null builtin autoload -XU builtin autoload -XU 	local remote ahead behind git_remote_status git_remote_status_detailed
	remote=${$(command git rev-parse --verify ${hook_com[branch]}@{upstream} --symbolic-full-name 2>/dev/null)/refs\/remotes\/} 
	if [[ -n ${remote} ]]
	then
		ahead=$(command git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l) 
		behind=$(command git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l) 
		if [[ $ahead -eq 0 ]] && [[ $behind -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_EQUAL_REMOTE" 
		elif [[ $ahead -gt 0 ]] && [[ $behind -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE$((ahead))%{$reset_color%}" 
		elif [[ $behind -gt 0 ]] && [[ $ahead -eq 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE$((behind))%{$reset_color%}" 
		elif [[ $ahead -gt 0 ]] && [[ $behind -gt 0 ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_DIVERGED_REMOTE" 
			git_remote_status_detailed="$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_AHEAD_REMOTE$((ahead))%{$reset_color%}$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE_COLOR$ZSH_THEME_GIT_PROMPT_BEHIND_REMOTE$((behind))%{$reset_color%}" 
		fi
		if [[ -n $ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_DETAILED ]]
		then
			git_remote_status="$ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_PREFIX$remote$git_remote_status_detailed$ZSH_THEME_GIT_PROMPT_REMOTE_STATUS_SUFFIX" 
		fi
		echo $git_remote_status
	fi builtin autoload -XU builtin autoload -XU 	precmd_update_git_vars
	if [ -n "$__CURRENT_GIT_STATUS" ]
	then
		STATUS="$ZSH_THEME_GIT_PROMPT_PREFIX$ZSH_THEME_GIT_PROMPT_BRANCH$GIT_BRANCH%{${reset_color}%}" 
		if [ "$GIT_BEHIND" -ne "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_BEHIND$GIT_BEHIND%{${reset_color}%}" 
		fi
		if [ "$GIT_AHEAD" -ne "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_AHEAD$GIT_AHEAD%{${reset_color}%}" 
		fi
		STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_SEPARATOR" 
		if [ "$GIT_STAGED" -ne "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_STAGED$GIT_STAGED%{${reset_color}%}" 
		fi
		if [ "$GIT_CONFLICTS" -ne "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_CONFLICTS$GIT_CONFLICTS%{${reset_color}%}" 
		fi
		if [ "$GIT_CHANGED" -ne "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_CHANGED$GIT_CHANGED%{${reset_color}%}" 
		fi
		if [ "$GIT_UNTRACKED" -ne "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_UNTRACKED%{${reset_color}%}" 
		fi
		if [ "$GIT_CHANGED" -eq "0" ] && [ "$GIT_CONFLICTS" -eq "0" ] && [ "$GIT_STAGED" -eq "0" ] && [ "$GIT_UNTRACKED" -eq "0" ]
		then
			STATUS="$STATUS$ZSH_THEME_GIT_PROMPT_CLEAN" 
		fi
		STATUS="$STATUS%{${reset_color}%}$ZSH_THEME_GIT_PROMPT_SUFFIX" 
		echo "$STATUS"
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	if [ ! $1 ]
	then
		echo "Usage: scpup2 sourcefile destinationfile"
		return 1
	elif [ ! $2 ]
	then
		DEST=$(basename $1) 
	else
		DEST=$2 
	fi
	echo root@vwebsk.kmundp.de:~/$DEST
	return $?
	scp -r $1 root@vwebsk.kmundp.de:~/$DEST builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	echo -n "DEBUGGING is "
	if isDebug
	then
		echo "on"
	else
		echo "off"
	fi builtin autoload -XU 	case "$(whatis --version)" in
		("whatis from "*) local -A args
			zparseopts -D -A args s: r:
			apropos "${args[-r]:-"$@"}" | fgrep "($args[-s]" ;;
		(*) whatis "$@" ;;
	esac builtin autoload -XU builtin autoload -XU builtin autoload -XU 	return 1 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	(( $+parameters[$1] )) && return 0
	typeset -g "$1"="$2" && return 3 builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local prev
	if [[ "$1" = -- ]]
	then
		prev=- 
		shift
	fi
	if (( $# ))
	then
		local curcontext="$curcontext" order tag nodef tmp 
		if [[ "$1" = -C?* ]]
		then
			curcontext="${curcontext%:*}:${1[3,-1]}" 
			shift
		elif [[ "$1" = -C ]]
		then
			curcontext="${curcontext%:*}:${2}" 
			shift 2
		fi
		[[ "$1" = -(|-) ]] && shift
		zstyle -a ":completion:${curcontext}:" group-order order && compgroups "$order[@]"
		comptags "-i$prev" "$curcontext" "$@"
		if [[ -n "$_sort_tags" ]]
		then
			"$_sort_tags" "$@"
		else
			zstyle -a ":completion:${curcontext}:" tag-order order || (( ! ${@[(I)options]} )) || order=('(|*-)argument-* (|*-)option[-+]* values' options) 
			for tag in $order
			do
				case $tag in
					(-) nodef=yes  ;;
					(\!*) comptry "${(@)argv:#(${(j:|:)~${=~tag[2,-1]}})}" ;;
					(?*) comptry -m "$tag" ;;
				esac
			done
			[[ -z "$nodef" ]] && comptry "$@"
		fi
		comptags "-T$prev"
		return
	fi
	comptags "-N$prev" builtin autoload -XU 	if [[ -n "$(command git show-ref origin/$(git_current_branch) 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_REMOTE_EXISTS"
	else
		echo "$ZSH_THEME_GIT_PROMPT_REMOTE_MISSING"
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	emulate -L zsh
	local IFS=".-" min_cnt=0 ver_cnt=0 part min_ver version order 
	min_ver=(${=1}) 
	version=(${=2:-$ZSH_VERSION} 0) 
	while (( $min_cnt <= ${#min_ver} ))
	do
		while [[ "$part" != <-> ]]
		do
			(( ++ver_cnt > ${#version} )) && return 0
			if [[ ${version[ver_cnt]} = *[0-9][^0-9]* ]]
			then
				order=(${version[ver_cnt]} ${min_ver[ver_cnt]}) 
				if [[ ${version[ver_cnt]} = <->* ]]
				then
					[[ $order != ${${(On)order}} ]] && return 1
				else
					[[ $order != ${${(O)order}} ]] && return 1
				fi
				[[ $order[1] != $order[2] ]] && return 0
			fi
			part=${version[ver_cnt]##*[^0-9]} 
		done
		while true
		do
			(( ++min_cnt > ${#min_ver} )) && return 0
			[[ ${min_ver[min_cnt]} = <-> ]] && break
		done
		(( part > min_ver[min_cnt] )) && return 0
		(( part < min_ver[min_cnt] )) && return 1
		part='' 
	done builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	if $(git log -n 1 2>/dev/null | grep -q -c "\-\-wip\-\-")
	then
		echo "WIP!!"
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local open_cmd
	case "$OSTYPE" in
		(darwin*) open_cmd='open'  ;;
		(cygwin*) open_cmd='cygstart'  ;;
		(linux*) [[ "$(uname -r)" != *icrosoft* ]] && open_cmd='nohup xdg-open'  || {
				open_cmd='cmd.exe /c start ""' 
				[[ -e "$1" ]] && {
					1="$(wslpath -w "${1:a}")"  || return 1
				}
			} ;;
		(msys*) open_cmd='start ""'  ;;
		(*) echo "Platform $OSTYPE not supported"
			return 1 ;;
	esac
	${=open_cmd} "$@" &> /dev/null builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	tail -r -n $(cat "$1" | wc -l) "$1" builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	echo "$# parameters"
	echo Using '$*'
	for p in $*
	do
		echo "[$p]"
	done
	echo Using '"$*"'
	for p in "$*"
	do
		echo "[$p]"
	done
	echo Using '$@'
	for p in $@
	do
		echo "[$p]"
	done
	echo Using '"$@"'
	for p in "$@"
	do
		echo "[$p]"
	done builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	ln -s `pwd`/$1 $2 	OPTIONS="-lhFaGctd" 
	ls $OPTIONS * | head -n "$1" builtin autoload -XU builtin autoload -XU 	local __gopt
	__gopt=() 
	zparseopts -D -a __gopt 1 2 V J x
	if comptags -R "$1"
	then
		if [[ $# -gt 3 ]]
		then
			_all_labels - "$__gopt[@]" "$@" || return 1
		elif [[ $# -gt 1 ]]
		then
			_description "$__gopt[@]" "$@"
		fi
		return 0
	else
		return 1
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU 	echo $*
	/usr/bin/man $* > ~/temp.txt
	if [ -s ~/temp.txt ]
	then
		subl ~/temp.txt
	fi builtin autoload -XU 	emulate -L zsh
	setopt extended_glob
	if [[ "$DISABLE_AUTO_TITLE" == true ]]
	then
		return
	fi
	local CMD=${1[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%} 
	local LINE="${2:gs/%/%%}" 
	title '$CMD' '%100>...>$LINE%<<' 	SP='./' 
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
	printf "${COLOR_Cyan}$CMD" builtin autoload -XU builtin autoload -XU 	local name gropt nopt xopt format gname hidden hide match opts tag sort
	opts=() 
	gropt=(-J) 
	xopt=(-X) 
	nopt=() 
	zparseopts -K -D -a nopt 1 2 V=gropt J=gropt x=xopt
	3="${${3##[[:blank:]]#}%%[[:blank:]]#}" 
	[[ -n "$3" ]] && _lastdescr=("$_lastdescr[@]" "$3") 
	zstyle -s ":completion:${curcontext}:$1" group-name gname && [[ -z "$gname" ]] && gname="$1" 
	_setup "$1" "${gname:--default-}"
	name="$2" 
	zstyle -s ":completion:${curcontext}:$1" format format || zstyle -s ":completion:${curcontext}:descriptions" format format
	if zstyle -s ":completion:${curcontext}:$1" hidden hidden && [[ "$hidden" = (all|yes|true|1|on) ]]
	then
		[[ "$hidden" = all ]] && format='' 
		opts=(-n) 
	fi
	zstyle -s ":completion:${curcontext}:$1" matcher match && opts=($opts -M "$match") 
	[[ -n "$_matcher" ]] && opts=($opts -M "$_matcher") 
	if {
			zstyle -s ":completion:${curcontext}:$1" sort sort || zstyle -s ":completion:${curcontext}:" sort sort
		} && [[ "$gropt" = -J && $sort != menu ]]
	then
		if [[ "$sort" = (yes|true|1|on) ]]
		then
			gropt=(-J) 
		else
			gropt=(-V) 
		fi
	fi
	if [[ -z "$_comp_no_ignore" ]]
	then
		zstyle -a ":completion:${curcontext}:$1" ignored-patterns _comp_ignore || _comp_ignore=() 
		if zstyle -s ":completion:${curcontext}:$1" ignore-line hidden
		then
			local -a qwords
			qwords=(${words//(#m)[\[\]()\*?#<>~\^\|]/\$MATCH}) 
			case "$hidden" in
				(true | yes | on | 1) _comp_ignore+=($qwords)  ;;
				(current) _comp_ignore+=($qwords[CURRENT])  ;;
				(current-shown) [[ "$compstate[old_list]" = *shown* ]] && _comp_ignore+=($qwords[CURRENT])  ;;
				(other) _comp_ignore+=($qwords[1,CURRENT-1] $qwords[CURRENT+1,-1])  ;;
			esac
		fi
		(( $#_comp_ignore )) && opts=(-F _comp_ignore $opts) 
	else
		_comp_ignore=() 
	fi
	tag="$1" 
	shift 2
	if [[ -z "$1" && $# -eq 1 ]]
	then
		format= 
	elif [[ -n "$format" ]]
	then
		zformat -f format "$format" "d:$1" "${(@)argv[2,-1]}"
	fi
	if [[ -n "$gname" ]]
	then
		if [[ -n "$format" ]]
		then
			set -A "$name" "$opts[@]" "$nopt[@]" "$gropt" "$gname" "$xopt" "$format"
		else
			set -A "$name" "$opts[@]" "$nopt[@]" "$gropt" "$gname"
		fi
	else
		if [[ -n "$format" ]]
		then
			set -A "$name" "$opts[@]" "$nopt[@]" "$gropt" -default- "$xopt" "$format"
		else
			set -A "$name" "$opts[@]" "$nopt[@]" "$gropt" -default-
		fi
	fi
	if ! (( ${funcstack[2,-1][(I)_description]} ))
	then
		local fakestyle descr
		for fakestyle in fake fake-always
		do
			zstyle -a ":completion:${curcontext}:$tag" $fakestyle match || continue
			descr=("${(@M)match:#*[^\]:*}") 
			opts=("${(@P)name}") 
			if [[ $fakestyle = fake-always && $opts[1,2] = "-F _comp_ignore" ]]
			then
				shift 2 opts
			fi
			compadd "${(@)opts}" - "${(@)${(@)match:#*[^\]:*}:s/\:/:/}"
			(( $#descr )) && _describe -t "$tag" '' descr "${(@)opts}"
		done
	fi
	return 0 builtin autoload -XU builtin autoload -XU builtin autoload -XU 	emulate -L zsh
	typeset -g __searching __savecursor
	if [[ $LBUFFER == *$'
'* ]]
	then
		zle .up-line-or-history
		__searching='' 
	elif [[ -n $PREBUFFER ]] && zstyle -t ':zle:up-line-or-beginning-search' edit-buffer
	then
		zle .push-line-or-edit
	else
		[[ $LASTWIDGET = $__searching ]] && CURSOR=$__savecursor 
		__savecursor=$CURSOR 
		__searching=$WIDGET 
		zle .history-beginning-search-backward
		zstyle -T ':zle:up-line-or-beginning-search' leave-cursor && zle .end-of-line
	fi builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	echo $(( ($1 - 1) * -1 )) 	local bg fg
	[[ -n $1 ]] && bg="%K{$1}"  || bg="%k" 
	[[ -n $2 ]] && fg="%F{$2}"  || fg="%f" 
	if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]
	then
		echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
	else
		echo -n "%{$bg%}%{$fg%} "
	fi
	CURRENT_BG=$1 
	[[ -n $3 ]] && echo -n $3 	/usr/bin/python -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$0" builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	echo "\$# = $#"
	echo "\$0 = $0, \$1 = $1, \$2 = $2, \$3 = $3, \$4 = $4, \$5 = $5, \$6 = $6"
	while [[ $# -gt 0 ]]
	do
		OPT=$1 
		shift
		echo $OPT
	done 	LINECOUNT=5 
	WHERE=$PWD 
	if [ -n "$1" ]
	then
		LINECOUNT=$1 
	fi
	if [ -n "$2" ]
	then
		WHERE="$2" 
	fi
	echo $LINECOUNT
	echo $WHERE
	ls -lhFaGct "$WHERE" | tail -n "$LINECOUNT" 	echo "$0: $*" >&2 builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	return 1 	prompt_segment blue $CURRENT_FG '%~' builtin autoload -XU builtin autoload -XU builtin autoload -XU 	local -a __targs __gopt
	zparseopts -D -a __gopt 1 2 V J x C:=__targs
	_tags "$__targs[@]" "$1"
	while _tags
	do
		_all_labels "$__gopt[@]" "$@" && return 0
	done
	return 1 builtin autoload -XU builtin autoload -XU 	echo "man $1" >> $mans2read builtin autoload -XU 	local STATUS="$?" 
	if [ -z "${ITERM2_SHOULD_DECORATE_PROMPT-}" ]
	then
		iterm2_before_cmd_executes
	fi
	iterm2_after_cmd_executes "$STATUS"
	if [ -n "$ITERM2_SHOULD_DECORATE_PROMPT" ]
	then
		iterm2_decorate_prompt
	fi builtin autoload -XU builtin autoload -XU 	local args defs ffilt
	zstyle -t ":completion:${curcontext}:commands" rehash && rehash
	zstyle -t ":completion:${curcontext}:functions" prefix-needed && [[ $PREFIX != [_.]* ]] && ffilt='[(I)[^_.]*]' 
	defs=('commands:external command:_path_commands') 
	[[ -n "$path[(r).]" || $PREFIX = */* ]] && defs+=('executables:executable file:_files -g \*\(-\*\)') 
	if [[ "$1" = -e ]]
	then
		shift
	else
		[[ "$1" = - ]] && shift
		defs=("$defs[@]" 'builtins:builtin command:compadd -Qk builtins' "functions:shell function:compadd -k 'functions$ffilt'" 'aliases:alias:compadd -Qk aliases' 'suffix-aliases:suffix alias:_suffix_alias_files' 'reserved-words:reserved word:compadd -Qk reswords' 'jobs:: _jobs -t' 'parameters:: _parameters -g "^*(readonly|association)*" -qS= -r "
	\- =[+"' 'parameters:: _parameters -g "*association*~*readonly*" -qS\[ -r "
	\- =[+"') 
	fi
	args=("$@") 
	local -a cmdpath
	if zstyle -a ":completion:${curcontext}" command-path cmdpath && [[ $#cmdpath -gt 0 ]]
	then
		local -a +h path
		local -A +h commands
		path=($cmdpath) 
	fi
	_alternative -O args "$defs[@]" builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU builtin autoload -XU 	BZR_CB=`bzr nick 2> /dev/null | grep -v "ERROR" | cut -d ":" -f2 | awk -F / '{print "bzr::"$1}'` 
	if [ -n "$BZR_CB" ]
	then
		BZR_DIRTY="" 
		[[ -n `bzr status` ]] && BZR_DIRTY=" %{$fg[red]%} * %{$fg[green]%}" 
		echo "$ZSH_THEME_SCM_PROMPT_PREFIX$BZR_CB$BZR_DIRTY$ZSH_THEME_GIT_PROMPT_SUFFIX"
	fi builtin autoload -XU builtin autoload -XU 	xdg-open $1 & builtin autoload -XU builtin autoload -XU builtin autoload -XU
