vi-git-aheadbehind () {
	local ahead behind
	local -a gitstatus
	ahead="$(git rev-list --count "${hook_com[branch]}"@{upstream}..HEAD 2>/dev/null)"
	(( ahead )) && gitstatus+=(" $(print_icon 'VCS_OUTGOING_CHANGES_ICON')${ahead// /}")
	behind="$(git rev-list --count HEAD.."${hook_com[branch]}"@{upstream} 2>/dev/null)"
	(( behind )) && gitstatus+=(" $(print_icon 'VCS_INCOMING_CHANGES_ICON')${behind// /}")
	hook_com[misc]+=${(j::)gitstatus}
}
+vi-git-remotebranch () {
	local remote
	local branch_name="${hook_com[branch]}"
	remote="$(git rev-parse --verify HEAD@{upstream} --symbolic-full-name 2>/dev/null)"
	remote=${remote/refs\/(remotes|heads)\/}
	if (( $+_POWERLEVEL9K_VCS_SHORTEN_LENGTH && $+_POWERLEVEL9K_VCS_SHORTEN_MIN_LENGTH ))
	then
		if (( ${#hook_com[branch]} > _POWERLEVEL9K_VCS_SHORTEN_MIN_LENGTH && ${#hook_com[branch]} > _POWERLEVEL9K_VCS_SHORTEN_LENGTH ))
		then
			case $_POWERLEVEL9K_VCS_SHORTEN_STRATEGY in
				(truncate_middle) hook_com[branch]="${branch_name:0:$_POWERLEVEL9K_VCS_SHORTEN_LENGTH}${_POWERLEVEL9K_VCS_SHORTEN_DELIMITER}${branch_name: -$_POWERLEVEL9K_VCS_SHORTEN_LENGTH}"  ;;
				(truncate_from_right) hook_com[branch]="${branch_name:0:$_POWERLEVEL9K_VCS_SHORTEN_LENGTH}${_POWERLEVEL9K_VCS_SHORTEN_DELIMITER}"  ;;
			esac
		fi
	fi
	if (( _POWERLEVEL9K_HIDE_BRANCH_ICON ))
	then
		hook_com[branch]="${hook_com[branch]}"
	else
		hook_com[branch]="$(print_icon 'VCS_BRANCH_ICON')${hook_com[branch]}"
	fi
	if [[ -n ${remote} ]] && [[ "${remote#*/}" != "${branch_name}" ]]
	then
		hook_com[branch]+="$(print_icon 'VCS_REMOTE_BRANCH_ICON')${remote// /}"
	fi
}
+vi-git-stash () {
	if [[ -s "${vcs_comm[gitdir]}/logs/refs/stash" ]]
	then
		local -a stashes=("${(@f)"$(<${vcs_comm[gitdir]}/logs/refs/stash)"}")
		hook_com[misc]+=" $(print_icon 'VCS_STASH_ICON')${#stashes}"
	fi
}
+vi-git-tagname () {
	if (( !_POWERLEVEL9K_VCS_HIDE_TAGS ))
	then
		local tag
		tag="$(git describe --tags --exact-match HEAD 2>/dev/null)"
		if [[ -n "${tag}" ]]
		then
			if [[ -z "$(git symbolic-ref HEAD 2>/dev/null)" ]]
			then
				local revision
				revision="$(git rev-list -n 1 --abbrev-commit --abbrev=${_POWERLEVEL9K_CHANGESET_HASH_LENGTH} HEAD)"
				if (( _POWERLEVEL9K_HIDE_BRANCH_ICON ))
				then
					hook_com[branch]="${revision} $(print_icon 'VCS_TAG_ICON')${tag}"
				else
					hook_com[branch]="$(print_icon 'VCS_BRANCH_ICON')${revision} $(print_icon 'VCS_TAG_ICON')${tag}"
				fi
			else
				hook_com[branch]+=" $(print_icon 'VCS_TAG_ICON')${tag}"
			fi
		fi
	fi
}
+vi-git-untracked () {
	[[ -z "${vcs_comm[gitdir]}" || "${vcs_comm[gitdir]}" == "." ]] && return
	local repoTopLevel="$(git rev-parse --show-toplevel 2> /dev/null)"
	[[ $? != 0 || -z $repoTopLevel ]] && return
	local untrackedFiles="$(git ls-files --others --exclude-standard "${repoTopLevel}" 2> /dev/null)"
	if [[ -z $untrackedFiles && $_POWERLEVEL9K_VCS_SHOW_SUBMODULE_DIRTY == 1 ]]
	then
		untrackedFiles+="$(git submodule foreach --quiet --recursive 'git ls-files --others --exclude-standard' 2> /dev/null)"
	fi
	[[ -z $untrackedFiles ]] && return
	hook_com[unstaged]+=" $(print_icon 'VCS_UNTRACKED_ICON')"
	VCS_WORKDIR_HALF_DIRTY=true
}
+vi-hg-bookmarks () {
	if [[ -n "${hgbmarks[@]}" ]]
	then
		hook_com[hg-bookmark-string]=" $(print_icon 'VCS_BOOKMARK_ICON')${hgbmarks[@]}"
		ret=1
		return 0
	fi
}
+vi-svn-detect-changes () {
	local svn_status="$(svn status)"
	if [[ -n "$(echo "$svn_status" | \grep \^\?)" ]]
	then
		hook_com[unstaged]+=" $(print_icon 'VCS_UNTRACKED_ICON')"
		VCS_WORKDIR_HALF_DIRTY=true
	fi
	if [[ -n "$(echo "$svn_status" | \grep \^\M)" ]]
	then
		hook_com[unstaged]+=" $(print_icon 'VCS_UNSTAGED_ICON')"
		VCS_WORKDIR_DIRTY=true
	fi
	if [[ -n "$(echo "$svn_status" | \grep \^\A)" ]]
	then
		hook_com[staged]+=" $(print_icon 'VCS_STAGED_ICON')"
		VCS_WORKDIR_DIRTY=true
	fi
}
+vi-vcs-detect-changes () {
	if [[ "${hook_com[vcs]}" == "git" ]]
	then
		local remote="$(git ls-remote --get-url 2> /dev/null)"
		if [[ "$remote" =~ "github" ]]
		then
			vcs_visual_identifier='VCS_GIT_GITHUB_ICON'
		elif [[ "$remote" =~ "bitbucket" ]]
		then
			vcs_visual_identifier='VCS_GIT_BITBUCKET_ICON'
		elif [[ "$remote" =~ "stash" ]]
		then
			vcs_visual_identifier='VCS_GIT_BITBUCKET_ICON'
		elif [[ "$remote" =~ "gitlab" ]]
		then
			vcs_visual_identifier='VCS_GIT_GITLAB_ICON'
		else
			vcs_visual_identifier='VCS_GIT_ICON'
		fi
	elif [[ "${hook_com[vcs]}" == "hg" ]]
	then
		vcs_visual_identifier='VCS_HG_ICON'
	elif [[ "${hook_com[vcs]}" == "svn" ]]
	then
		vcs_visual_identifier='VCS_SVN_ICON'
	fi
	if [[ -n "${hook_com[staged]}" ]] || [[ -n "${hook_com[unstaged]}" ]]
	then
		VCS_WORKDIR_DIRTY=true
	else
		VCS_WORKDIR_DIRTY=false
	fi
}
FileOrDirectory () {
	for i in $(ls $@)
	do
		[ -d "$i" ] && echo "$i is directory" || echo "$i is file"
	done
}
FileOrDirectory2 () {
	for i in "$@"
	do
		[ -d "$i" ] && echo "$i is directory" || echo "$i is file"
	done
}
Pink () {
	echo "${COLOR_Purple}${1}${W}"
}
_SUSEconfig () {
	# undefined
	builtin autoload -XUz
}
__add_sys_prefix_to_path () {
	if [ -n "${_CE_CONDA}" ] && [ -n "${WINDIR+x}" ]
	then
		SYSP=$(\dirname "${CONDA_EXE}")
	else
		SYSP=$(\dirname "${CONDA_EXE}")
		SYSP=$(\dirname "${SYSP}")
	fi
	if [ -n "${WINDIR+x}" ]
	then
		PATH="${SYSP}/bin:${PATH}"
		PATH="${SYSP}/Scripts:${PATH}"
		PATH="${SYSP}/Library/bin:${PATH}"
		PATH="${SYSP}/Library/usr/bin:${PATH}"
		PATH="${SYSP}/Library/mingw-w64/bin:${PATH}"
		PATH="${SYSP}:${PATH}"
	else
		PATH="${SYSP}/bin:${PATH}"
	fi
	\export PATH
}
__conda_activate () {
	if [ -n "${CONDA_PS1_BACKUP:+x}" ]
	then
		PS1="$CONDA_PS1_BACKUP"
		\unset CONDA_PS1_BACKUP
	fi
	\local ask_conda
	ask_conda="$(PS1="${PS1:-}" __conda_exe shell.posix "$@")"  || \return
	\eval "$ask_conda"
	__conda_hashr
}
__conda_exe () {
	(
		__add_sys_prefix_to_path
		"$CONDA_EXE" $_CE_M $_CE_CONDA "$@"
	)
}
__conda_hashr () {
	if [ -n "${ZSH_VERSION:+x}" ]
	then
		\rehash
	elif [ -n "${POSH_VERSION:+x}" ]
	then
		:
	else
		\hash -r
	fi
}
__conda_reactivate () {
	\local ask_conda
	ask_conda="$(PS1="${PS1:-}" __conda_exe shell.posix reactivate)"  || \return
	\eval "$ask_conda"
	__conda_hashr
}
__youtube_dl () {
	local cur prev opts fileopts diropts keywords
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	opts="--help --version --update --ignore-errors --abort-on-error --dump-user-agent --list-extractors --extractor-descriptions --force-generic-extractor --default-search --ignore-config --config-location --flat-playlist --mark-watched --no-mark-watched --no-color --proxy --socket-timeout --source-address --force-ipv4 --force-ipv6 --geo-verification-proxy --cn-verification-proxy --geo-bypass --no-geo-bypass --geo-bypass-country --geo-bypass-ip-block --playlist-start --playlist-end --playlist-items --match-title --reject-title --max-downloads --min-filesize --max-filesize --date --datebefore --dateafter --min-views --max-views --match-filter --no-playlist --yes-playlist --age-limit --download-archive --include-ads --limit-rate --retries --fragment-retries --skip-unavailable-fragments --abort-on-unavailable-fragment --keep-fragments --buffer-size --no-resize-buffer --http-chunk-size --test --playlist-reverse --playlist-random --xattr-set-filesize --hls-prefer-native --hls-prefer-ffmpeg --hls-use-mpegts --external-downloader --external-downloader-args --batch-file --id --output --output-na-placeholder --autonumber-size --autonumber-start --restrict-filenames --auto-number --title --literal --no-overwrites --continue --no-continue --no-part --no-mtime --write-description --write-info-json --write-annotations --load-info-json --cookies --cache-dir --no-cache-dir --rm-cache-dir --write-thumbnail --write-all-thumbnails --list-thumbnails --quiet --no-warnings --simulate --skip-download --get-url --get-title --get-id --get-thumbnail --get-description --get-duration --get-filename --get-format --dump-json --dump-single-json --print-json --newline --no-progress --console-title --verbose --dump-pages --write-pages --youtube-print-sig-code --print-traffic --call-home --no-call-home --encoding --no-check-certificate --prefer-insecure --user-agent --referer --add-header --bidi-workaround --sleep-interval --max-sleep-interval --format --all-formats --prefer-free-formats --list-formats --youtube-include-dash-manifest --youtube-skip-dash-manifest --merge-output-format --write-sub --write-auto-sub --all-subs --list-subs --sub-format --sub-lang --username --password --twofactor --netrc --video-password --ap-mso --ap-username --ap-password --ap-list-mso --extract-audio --audio-format --audio-quality --recode-video --postprocessor-args --keep-video --no-post-overwrites --embed-subs --embed-thumbnail --add-metadata --metadata-from-title --xattrs --fixup --prefer-avconv --prefer-ffmpeg --ffmpeg-location --exec --convert-subs"
	keywords=":ytfavorites :ytrecommended :ytsubscriptions :ytwatchlater :ythistory"
	fileopts="-a|--batch-file|--download-archive|--cookies|--load-info"
	diropts="--cache-dir"
	if [[ ${prev} =~ ${fileopts} ]]
	then
		COMPREPLY=($(compgen -f -- ${cur}))
		return 0
	elif [[ ${prev} =~ ${diropts} ]]
	then
		COMPREPLY=($(compgen -d -- ${cur}))
		return 0
	fi
	if [[ ${cur} =~ : ]]
	then
		COMPREPLY=($(compgen -W "${keywords}" -- ${cur}))
		return 0
	elif [[ ${cur} == * ]]
	then
		COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
		return 0
	fi
}
_a2ps () {
	# undefined
	builtin autoload -XUz
}
_a2utils () {
	# undefined
	builtin autoload -XUz
}
_aap () {
	# undefined
	builtin autoload -XUz
}
_absolute_command_paths () {
	# undefined
	builtin autoload -XUz
}
_ack () {
	# undefined
	builtin autoload -XUz
}
_acpi () {
	# undefined
	builtin autoload -XUz
}
_acpitool () {
	# undefined
	builtin autoload -XUz
}
_acroread () {
	# undefined
	builtin autoload -XUz
}
_adb () {
	# undefined
	builtin autoload -XUz
}
_add-zle-hook-widget () {
	# undefined
	builtin autoload -XUz
}
_add-zsh-hook () {
	# undefined
	builtin autoload -XUz
}
_alias () {
	# undefined
	builtin autoload -XUz
}
_aliases () {
	# undefined
	builtin autoload -XUz
}
_all_labels () {
	local __gopt __len __tmp __pre __suf __ret=1 __descr __spec __prev
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
		if [[ "$curtag" = *[^\\]:* ]]
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
	return __ret
}
_all_matches () {
	# undefined
	builtin autoload -XUz
}
_alternative () {
	local tags def expl descr action mesgs nm="$compstate[nmatches]" subopts
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
	return 1
}
_analyseplugin () {
	# undefined
	builtin autoload -XUz
}
_ansible () {
	# undefined
	builtin autoload -XUz
}
_ant () {
	# undefined
	builtin autoload -XUz
}
_antiword () {
	# undefined
	builtin autoload -XUz
}
_apachectl () {
	# undefined
	builtin autoload -XUz
}
_apm () {
	# undefined
	builtin autoload -XUz
}
_approximate () {
	# undefined
	builtin autoload -XUz
}
_apt () {
	# undefined
	builtin autoload -XUz
}
_apt-file () {
	# undefined
	builtin autoload -XUz
}
_apt-move () {
	# undefined
	builtin autoload -XUz
}
_apt-show-versions () {
	# undefined
	builtin autoload -XUz
}
_aptitude () {
	# undefined
	builtin autoload -XUz
}
_arch_archives () {
	# undefined
	builtin autoload -XUz
}
_arch_namespace () {
	# undefined
	builtin autoload -XUz
}
_arg_compile () {
	# undefined
	builtin autoload -XUz
}
_arguments () {
	local long cmd="$words[1]" descr odescr mesg subopts opt opt2 usecc autod
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
				pattern="${${${(M)1#*[^\\]:}[1,-2]}//\\\\:/:}"
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
	fi
}
_arp () {
	# undefined
	builtin autoload -XUz
}
_arping () {
	# undefined
	builtin autoload -XUz
}
_arrays () {
	# undefined
	builtin autoload -XUz
}
_asciidoctor () {
	# undefined
	builtin autoload -XUz
}
_asciinema () {
	# undefined
	builtin autoload -XUz
}
_assign () {
	# undefined
	builtin autoload -XUz
}
_at () {
	# undefined
	builtin autoload -XUz
}
_attr () {
	# undefined
	builtin autoload -XUz
}
_augeas () {
	# undefined
	builtin autoload -XUz
}
_auto-apt () {
	# undefined
	builtin autoload -XUz
}
_autocd () {
	_command_names
	local ret=$?
	[[ -o autocd ]] && _cd || return ret
}
_awk () {
	# undefined
	builtin autoload -XUz
}
_axi-cache () {
	# undefined
	builtin autoload -XUz
}
_base64 () {
	# undefined
	builtin autoload -XUz
}
_basename () {
	# undefined
	builtin autoload -XUz
}
_bash () {
	# undefined
	builtin autoload -XUz
}
_bash_complete () {
	local ret=1
	local -a suf matches
	local -x COMP_POINT COMP_CWORD
	local -a COMP_WORDS COMPREPLY BASH_VERSINFO
	local -x COMP_LINE="$words"
	local -A savejobstates savejobtexts
	(( COMP_POINT = 1 + ${#${(j. .)words[1,CURRENT-1]}} + $#QIPREFIX + $#IPREFIX + $#PREFIX ))
	(( COMP_CWORD = CURRENT - 1))
	COMP_WORDS=($words)
	BASH_VERSINFO=(2 05b 0 1 release)
	savejobstates=(${(kv)jobstates})
	savejobtexts=(${(kv)jobtexts})
	[[ ${argv[${argv[(I)nospace]:-0}-1]} = -o ]] && suf=(-S '')
	matches=(${(f)"$(compgen $@ -- ${words[CURRENT]})"})
	if [[ -n $matches ]]
	then
		if [[ ${argv[${argv[(I)filenames]:-0}-1]} = -o ]]
		then
			compset -P '*/' && matches=(${matches##*/})
			compset -S '/*' && matches=(${matches%%/*})
			compadd -Q -f "${suf[@]}" -a matches && ret=0
		else
			compadd -Q "${suf[@]}" -a matches && ret=0
		fi
	fi
	if (( ret ))
	then
		if [[ ${argv[${argv[(I)default]:-0}-1]} = -o ]]
		then
			_default "${suf[@]}" && ret=0
		elif [[ ${argv[${argv[(I)dirnames]:-0}-1]} = -o ]]
		then
			_directories "${suf[@]}" && ret=0
		fi
	fi
	return ret
}
_bash_completions () {
	# undefined
	builtin autoload -XUz
}
_baudrates () {
	# undefined
	builtin autoload -XUz
}
_baz () {
	# undefined
	builtin autoload -XUz
}
_bazel () {
	# undefined
	builtin autoload -XUz
}
_be_name () {
	# undefined
	builtin autoload -XUz
}
_beadm () {
	# undefined
	builtin autoload -XUz
}
_beep () {
	# undefined
	builtin autoload -XUz
}
_bibtex () {
	# undefined
	builtin autoload -XUz
}
_bind_addresses () {
	# undefined
	builtin autoload -XUz
}
_bindkey () {
	# undefined
	builtin autoload -XUz
}
_bison () {
	# undefined
	builtin autoload -XUz
}
_bittorrent () {
	# undefined
	builtin autoload -XUz
}
_bogofilter () {
	# undefined
	builtin autoload -XUz
}
_bpf_filters () {
	# undefined
	builtin autoload -XUz
}
_bpython () {
	# undefined
	builtin autoload -XUz
}
_br () {
	# undefined
	builtin autoload -XUz
}
_brace_parameter () {
	# undefined
	builtin autoload -XUz
}
_brctl () {
	# undefined
	builtin autoload -XUz
}
_brew () {
	# undefined
	builtin autoload -XUz
}
_brew_cask () {
	# undefined
	builtin autoload -XUz
}
_broot () {
	# undefined
	builtin autoload -XUz
}
_bsd_pkg () {
	# undefined
	builtin autoload -XUz
}
_bsdconfig () {
	# undefined
	builtin autoload -XUz
}
_bsdinstall () {
	# undefined
	builtin autoload -XUz
}
_btrfs () {
	# undefined
	builtin autoload -XUz
}
_bts () {
	# undefined
	builtin autoload -XUz
}
_bug () {
	# undefined
	builtin autoload -XUz
}
_builtin () {
	# undefined
	builtin autoload -XUz
}
_bzip2 () {
	# undefined
	builtin autoload -XUz
}
_bzr () {
	# undefined
	builtin autoload -XUz
}
_cabal () {
	# undefined
	builtin autoload -XUz
}
_cache_invalid () {
	# undefined
	builtin autoload -XUz
}
_caffeinate () {
	# undefined
	builtin autoload -XUz
}
_cal () {
	# undefined
	builtin autoload -XUz
}
_calendar () {
	# undefined
	builtin autoload -XUz
}
_call_function () {
	# undefined
	builtin autoload -XUz
}
_call_program () {
	local curcontext="${curcontext}" tmp err_fd=-1 clocale='_comp_locale;'
	local -a prefix
	if [[ "$1" = -p ]]
	then
		shift
		if (( $#_comp_priv_prefix ))
		then
			curcontext="${curcontext%:*}/${${(@M)_comp_priv_prefix:#^*[^\\]=*}[1]}:"
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
	}
}
_call_whatis () {
	case "$(whatis --version)" in
		("whatis from "*) local -A args
			zparseopts -D -A args s: r:
			apropos "${args[-r]:-"$@"}" | fgrep "($args[-s]" ;;
		(*) whatis "$@" ;;
	esac
}
_canonical_paths () {
	# undefined
	builtin autoload -XUz
}
_cargo () {
	# undefined
	builtin autoload -XUz
}
_carthage () {
	# undefined
	builtin autoload -XUz
}
_cat () {
	# undefined
	builtin autoload -XUz
}
_ccal () {
	# undefined
	builtin autoload -XUz
}
_cd () {
	_cd_options () {
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
	fi
}
_cd_options () {
	_arguments -s '-q[quiet, no output or use of hooks]' '-s[refuse to use paths with symlinks]' '(-P)-L[retain symbolic links ignoring CHASE_LINKS]' '(-L)-P[resolve symbolic links as CHASE_LINKS]'
}
_cdbs-edit-patch () {
	# undefined
	builtin autoload -XUz
}
_cdcd () {
	# undefined
	builtin autoload -XUz
}
_cdr () {
	# undefined
	builtin autoload -XUz
}
_cdrdao () {
	# undefined
	builtin autoload -XUz
}
_cdrecord () {
	# undefined
	builtin autoload -XUz
}
_chattr () {
	# undefined
	builtin autoload -XUz
}
_chflags () {
	# undefined
	builtin autoload -XUz
}
_chkconfig () {
	# undefined
	builtin autoload -XUz
}
_chmod () {
	# undefined
	builtin autoload -XUz
}
_chown () {
	# undefined
	builtin autoload -XUz
}
_chroot () {
	# undefined
	builtin autoload -XUz
}
_chrt () {
	# undefined
	builtin autoload -XUz
}
_chsh () {
	# undefined
	builtin autoload -XUz
}
_cksum () {
	# undefined
	builtin autoload -XUz
}
_clay () {
	# undefined
	builtin autoload -XUz
}
_cmdambivalent () {
	# undefined
	builtin autoload -XUz
}
_cmdstring () {
	# undefined
	builtin autoload -XUz
}
_cmp () {
	# undefined
	builtin autoload -XUz
}
_code () {
	# undefined
	builtin autoload -XUz
}
_column () {
	# undefined
	builtin autoload -XUz
}
_combination () {
	# undefined
	builtin autoload -XUz
}
_comm () {
	# undefined
	builtin autoload -XUz
}
_command () {
	# undefined
	builtin autoload -XUz
}
_command_exists () {
	WHICHRESULT=$(builtin which "$1" | head -n 1)
	if string_contains $WHICHRESULT 'not found'
	then
		return 1
	else
		return 0
	fi
}
_command_names () {
	local args defs ffilt
	zstyle -t ":completion:${curcontext}:commands" rehash && rehash
	zstyle -t ":completion:${curcontext}:functions" prefix-needed && [[ $PREFIX != [_.]* ]] && ffilt='[(I)[^_.]*]'
	defs=('commands:external command:_path_commands')
	[[ -n "$path[(r).]" || $PREFIX = */* ]] && defs+=('executables:executable file:_files -g \*\(-\*\)')
	if [[ "$1" = -e ]]
	then
		shift
	else
		[[ "$1" = - ]] && shift
		defs=("$defs[@]" 'builtins:builtin command:compadd -Qk builtins' "functions:shell function:compadd -k 'functions$ffilt'" 'aliases:alias:compadd -Qk aliases' 'suffix-aliases:suffix alias:_suffix_alias_files' 'reserved-words:reserved word:compadd -Qk reswords' 'jobs:: _jobs -t' 'parameters:: _parameters -g "^*(readonly|association)*" -qS= -r "\n\t\- =[+"' 'parameters:: _parameters -g "*association*~*readonly*" -qS\[ -r "\n\t\- =[+"')
	fi
	args=("$@")
	local -a cmdpath
	if zstyle -a ":completion:${curcontext}" command-path cmdpath && [[ $#cmdpath -gt 0 ]]
	then
		local -a +h path
		local -A +h commands
		path=($cmdpath)
	fi
	_alternative -O args "$defs[@]"
}
_comp_locale () {
	# undefined
	builtin autoload -XUz
}
_compadd () {
	# undefined
	builtin autoload -XUz
}
_compdef () {
	# undefined
	builtin autoload -XUz
}
_complete () {
	local comp name oldcontext ret=1 service
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
	return ret
}
_complete_debug () {
	# undefined
	builtin autoload -XUz
}
_complete_help () {
	# undefined
	builtin autoload -XUz
}
_complete_help_generic () {
	# undefined
	builtin autoload -XUz
}
_complete_tag () {
	# undefined
	builtin autoload -XUz
}
_completers () {
	# undefined
	builtin autoload -XUz
}
_composer () {
	# undefined
	builtin autoload -XUz
}
_compress () {
	# undefined
	builtin autoload -XUz
}
_condition () {
	# undefined
	builtin autoload -XUz
}
_configure () {
	# undefined
	builtin autoload -XUz
}
_coreadm () {
	# undefined
	builtin autoload -XUz
}
_correct () {
	# undefined
	builtin autoload -XUz
}
_correct_filename () {
	# undefined
	builtin autoload -XUz
}
_correct_word () {
	# undefined
	builtin autoload -XUz
}
_cowsay () {
	# undefined
	builtin autoload -XUz
}
_cp () {
	# undefined
	builtin autoload -XUz
}
_cpio () {
	# undefined
	builtin autoload -XUz
}
_cplay () {
	# undefined
	builtin autoload -XUz
}
_cpupower () {
	# undefined
	builtin autoload -XUz
}
_crontab () {
	# undefined
	builtin autoload -XUz
}
_cryptsetup () {
	# undefined
	builtin autoload -XUz
}
_cscope () {
	# undefined
	builtin autoload -XUz
}
_cssh () {
	# undefined
	builtin autoload -XUz
}
_csup () {
	# undefined
	builtin autoload -XUz
}
_ctags_tags () {
	# undefined
	builtin autoload -XUz
}
_cu () {
	# undefined
	builtin autoload -XUz
}
_curl () {
	# undefined
	builtin autoload -XUz
}
_cut () {
	# undefined
	builtin autoload -XUz
}
_cvs () {
	# undefined
	builtin autoload -XUz
}
_cvsup () {
	# undefined
	builtin autoload -XUz
}
_cygcheck () {
	# undefined
	builtin autoload -XUz
}
_cygpath () {
	# undefined
	builtin autoload -XUz
}
_cygrunsrv () {
	# undefined
	builtin autoload -XUz
}
_cygserver () {
	# undefined
	builtin autoload -XUz
}
_cygstart () {
	# undefined
	builtin autoload -XUz
}
_dak () {
	# undefined
	builtin autoload -XUz
}
_darcs () {
	# undefined
	builtin autoload -XUz
}
_date () {
	# undefined
	builtin autoload -XUz
}
_date_formats () {
	# undefined
	builtin autoload -XUz
}
_dates () {
	# undefined
	builtin autoload -XUz
}
_dbus () {
	# undefined
	builtin autoload -XUz
}
_dchroot () {
	# undefined
	builtin autoload -XUz
}
_dchroot-dsa () {
	# undefined
	builtin autoload -XUz
}
_dconf () {
	# undefined
	builtin autoload -XUz
}
_dcop () {
	# undefined
	builtin autoload -XUz
}
_dcut () {
	# undefined
	builtin autoload -XUz
}
_dd () {
	# undefined
	builtin autoload -XUz
}
_deb_architectures () {
	# undefined
	builtin autoload -XUz
}
_deb_codenames () {
	# undefined
	builtin autoload -XUz
}
_deb_packages () {
	# undefined
	builtin autoload -XUz
}
_debbugs_bugnumber () {
	# undefined
	builtin autoload -XUz
}
_debchange () {
	# undefined
	builtin autoload -XUz
}
_debcheckout () {
	# undefined
	builtin autoload -XUz
}
_debdiff () {
	# undefined
	builtin autoload -XUz
}
_debfoster () {
	# undefined
	builtin autoload -XUz
}
_deborphan () {
	# undefined
	builtin autoload -XUz
}
_debsign () {
	# undefined
	builtin autoload -XUz
}
_debug () {
	STATE="off"
	if [ "$DEBUG" = $TRUE ]
	then
		STATE="on"
	fi
	echo "DEBUG is $STATE"
}
_debuild () {
	# undefined
	builtin autoload -XUz
}
_default () {
	local ctl
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
	fi
}
_defaults () {
	# undefined
	builtin autoload -XUz
}
_delimiters () {
	# undefined
	builtin autoload -XUz
}
_describe () {
	# undefined
	builtin autoload -XUz
}
_description () {
	local name gropt nopt xopt format gname hidden hide match opts tag sort
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
			qwords=(${words//(#m)[\[\]()\\*?#<>~\^\|]/\\$MATCH})
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
			descr=("${(@M)match:#*[^\\]:*}")
			opts=("${(@P)name}")
			if [[ $fakestyle = fake-always && $opts[1,2] = "-F _comp_ignore" ]]
			then
				shift 2 opts
			fi
			compadd "${(@)opts}" - "${(@)${(@)match:#*[^\\]:*}:s/\\:/:/}"
			(( $#descr )) && _describe -t "$tag" '' descr "${(@)opts}"
		done
	fi
	return 0
}
_devtodo () {
	# undefined
	builtin autoload -XUz
}
_df () {
	# undefined
	builtin autoload -XUz
}
_dhclient () {
	# undefined
	builtin autoload -XUz
}
_dhcpinfo () {
	# undefined
	builtin autoload -XUz
}
_dict () {
	# undefined
	builtin autoload -XUz
}
_dict_words () {
	# undefined
	builtin autoload -XUz
}
_diff () {
	# undefined
	builtin autoload -XUz
}
_diff3 () {
	# undefined
	builtin autoload -XUz
}
_diff_options () {
	# undefined
	builtin autoload -XUz
}
_diffstat () {
	# undefined
	builtin autoload -XUz
}
_dig () {
	# undefined
	builtin autoload -XUz
}
_dir_list () {
	# undefined
	builtin autoload -XUz
}
_directories () {
	# undefined
	builtin autoload -XUz
}
_directory_stack () {
	# undefined
	builtin autoload -XUz
}
_dirs () {
	# undefined
	builtin autoload -XUz
}
_disable () {
	# undefined
	builtin autoload -XUz
}
_dispatch () {
	local comp pat val name i ret=1 _compskip="$_compskip"
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
	return ret
}
_django () {
	# undefined
	builtin autoload -XUz
}
_dkms () {
	# undefined
	builtin autoload -XUz
}
_dladm () {
	# undefined
	builtin autoload -XUz
}
_dlocate () {
	# undefined
	builtin autoload -XUz
}
_dmesg () {
	# undefined
	builtin autoload -XUz
}
_dmidecode () {
	# undefined
	builtin autoload -XUz
}
_dnf () {
	# undefined
	builtin autoload -XUz
}
_dns_types () {
	# undefined
	builtin autoload -XUz
}
_doas () {
	# undefined
	builtin autoload -XUz
}
_domains () {
	# undefined
	builtin autoload -XUz
}
_dos2unix () {
	# undefined
	builtin autoload -XUz
}
_dpatch-edit-patch () {
	# undefined
	builtin autoload -XUz
}
_dpkg () {
	# undefined
	builtin autoload -XUz
}
_dpkg-buildpackage () {
	# undefined
	builtin autoload -XUz
}
_dpkg-cross () {
	# undefined
	builtin autoload -XUz
}
_dpkg-repack () {
	# undefined
	builtin autoload -XUz
}
_dpkg_source () {
	# undefined
	builtin autoload -XUz
}
_dput () {
	# undefined
	builtin autoload -XUz
}
_drill () {
	# undefined
	builtin autoload -XUz
}
_dsh () {
	# undefined
	builtin autoload -XUz
}
_dtrace () {
	# undefined
	builtin autoload -XUz
}
_dtruss () {
	# undefined
	builtin autoload -XUz
}
_du () {
	# undefined
	builtin autoload -XUz
}
_dumpadm () {
	# undefined
	builtin autoload -XUz
}
_dumper () {
	# undefined
	builtin autoload -XUz
}
_dupload () {
	# undefined
	builtin autoload -XUz
}
_dvi () {
	# undefined
	builtin autoload -XUz
}
_dynamic_directory_name () {
	# undefined
	builtin autoload -XUz
}
_e2label () {
	# undefined
	builtin autoload -XUz
}
_ecasound () {
	# undefined
	builtin autoload -XUz
}
_echotc () {
	# undefined
	builtin autoload -XUz
}
_echoti () {
	# undefined
	builtin autoload -XUz
}
_ed () {
	# undefined
	builtin autoload -XUz
}
_elfdump () {
	# undefined
	builtin autoload -XUz
}
_elinks () {
	# undefined
	builtin autoload -XUz
}
_elm () {
	# undefined
	builtin autoload -XUz
}
_email_addresses () {
	# undefined
	builtin autoload -XUz
}
_emulate () {
	# undefined
	builtin autoload -XUz
}
_enable () {
	# undefined
	builtin autoload -XUz
}
_enscript () {
	# undefined
	builtin autoload -XUz
}
_entr () {
	# undefined
	builtin autoload -XUz
}
_env () {
	# undefined
	builtin autoload -XUz
}
_eog () {
	# undefined
	builtin autoload -XUz
}
_equal () {
	# undefined
	builtin autoload -XUz
}
_espeak () {
	# undefined
	builtin autoload -XUz
}
_etags () {
	# undefined
	builtin autoload -XUz
}
_ethtool () {
	# undefined
	builtin autoload -XUz
}
_evince () {
	# undefined
	builtin autoload -XUz
}
_exec () {
	# undefined
	builtin autoload -XUz
}
_expand () {
	# undefined
	builtin autoload -XUz
}
_expand_alias () {
	# undefined
	builtin autoload -XUz
}
_expand_word () {
	# undefined
	builtin autoload -XUz
}
_extensions () {
	# undefined
	builtin autoload -XUz
}
_external_pwds () {
	# undefined
	builtin autoload -XUz
}
_fakeroot () {
	# undefined
	builtin autoload -XUz
}
_fbsd_architectures () {
	# undefined
	builtin autoload -XUz
}
_fc () {
	# undefined
	builtin autoload -XUz
}
_feh () {
	# undefined
	builtin autoload -XUz
}
_fetch () {
	# undefined
	builtin autoload -XUz
}
_fetchmail () {
	# undefined
	builtin autoload -XUz
}
_ffmpeg () {
	# undefined
	builtin autoload -XUz
}
_figlet () {
	# undefined
	builtin autoload -XUz
}
_file_descriptors () {
	# undefined
	builtin autoload -XUz
}
_file_flags () {
	# undefined
	builtin autoload -XUz
}
_file_modes () {
	# undefined
	builtin autoload -XUz
}
_file_systems () {
	# undefined
	builtin autoload -XUz
}
_files () {
	local -a match mbegin mend
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
		[[ "$glob" = *[^\\][[:blank:]]* ]] && glob="{${glob//(#b)([^\\])[[:blank:]]##/${match[1]},}}"
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
		for i in ${tmp//\%p/${${glob:-\*}//:/\\:}}
		do
			if [[ $i = *[^\\]:* ]]
			then
				pats+=(" $i ")
			else
				pats+=(" ${i}:files ")
			fi
		done
	elif zstyle -t ":completion:${curcontext}:" list-dirs-first
	then
		pats=(" *(-/):directories:directory ${${glob:-*}//:/\\:}(#q^-/):globbed-files" '*:all-files')
	else
		pats=("${${glob:-*}//:/\\:}:globbed-files *(-/):directories" '*:all-files ')
	fi
	tried=()
	for def in "$pats[@]"
	do
		eval "def=( ${${def//\\:/\\\\\\:}//(#b)([][()|*?^#~<>])/\\${match[1]}} )"
		tmp="${(@M)def#*[^\\]:}"
		(( $tried[(I)${(q)tmp}] )) && continue
		tried=("$tried[@]" "$tmp")
		for sdef in "$def[@]"
		do
			tag="${${sdef#*[^\\]:}%%:*}"
			pat="${${sdef%%:${tag}*}//\\:/:}"
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
	return 1
}
_find () {
	# undefined
	builtin autoload -XUz
}
_find_net_interfaces () {
	# undefined
	builtin autoload -XUz
}
_finger () {
	# undefined
	builtin autoload -XUz
}
_fink () {
	# undefined
	builtin autoload -XUz
}
_first () {

}
_flac () {
	# undefined
	builtin autoload -XUz
}
_flasher () {
	# undefined
	builtin autoload -XUz
}
_flex () {
	# undefined
	builtin autoload -XUz
}
_floppy () {
	# undefined
	builtin autoload -XUz
}
_flowadm () {
	# undefined
	builtin autoload -XUz
}
_fmadm () {
	# undefined
	builtin autoload -XUz
}
_fmt () {
	# undefined
	builtin autoload -XUz
}
_fold () {
	# undefined
	builtin autoload -XUz
}
_fortune () {
	# undefined
	builtin autoload -XUz
}
_freebsd-update () {
	# undefined
	builtin autoload -XUz
}
_fs_usage () {
	# undefined
	builtin autoload -XUz
}
_fsh () {
	# undefined
	builtin autoload -XUz
}
_fstat () {
	# undefined
	builtin autoload -XUz
}
_functions () {
	# undefined
	builtin autoload -XUz
}
_fuse_arguments () {
	# undefined
	builtin autoload -XUz
}
_fuse_values () {
	# undefined
	builtin autoload -XUz
}
_fuser () {
	# undefined
	builtin autoload -XUz
}
_fusermount () {
	# undefined
	builtin autoload -XUz
}
_fw_update () {
	# undefined
	builtin autoload -XUz
}
_gcc () {
	# undefined
	builtin autoload -XUz
}
_gcore () {
	# undefined
	builtin autoload -XUz
}
_gdb () {
	# undefined
	builtin autoload -XUz
}
_geany () {
	# undefined
	builtin autoload -XUz
}
_gem () {
	# undefined
	builtin autoload -XUz
}
_generic () {
	# undefined
	builtin autoload -XUz
}
_genisoimage () {
	# undefined
	builtin autoload -XUz
}
_getclip () {
	# undefined
	builtin autoload -XUz
}
_getconf () {
	# undefined
	builtin autoload -XUz
}
_getent () {
	# undefined
	builtin autoload -XUz
}
_getfacl () {
	# undefined
	builtin autoload -XUz
}
_getmail () {
	# undefined
	builtin autoload -XUz
}
_getopt () {
	# undefined
	builtin autoload -XUz
}
_ghostscript () {
	# undefined
	builtin autoload -XUz
}
_git () {
	# undefined
	builtin autoload -XUz
}
_git-buildpackage () {
	# undefined
	builtin autoload -XUz
}
_git_log_prettily () {
	if ! [ -z $1 ]
	then
		git log --pretty=$1
	fi
}
_gitstatus_cleanup_POWERLEVEL9K-_p9k_ () {
	emulate -L zsh -o no_aliases -o extended_glob -o typeset_silent
	local pair=${${(%):-%N}#_gitstatus_cleanup_}
	local name=${pair%%-*}
	local fsuf=${pair#*-}
	(( _GITSTATUS_CLIENT_PID_$name == sysparams[pid] )) || return
	gitstatus_stop$fsuf $name
}
_gitstatus_clear_p9k_ () {
	unset VCS_STATUS_{WORKDIR,COMMIT,LOCAL_BRANCH,REMOTE_BRANCH,REMOTE_NAME,REMOTE_URL,ACTION,INDEX_SIZE,NUM_STAGED,NUM_UNSTAGED,NUM_CONFLICTED,NUM_UNTRACKED,HAS_STAGED,HAS_UNSTAGED,HAS_CONFLICTED,HAS_UNTRACKED,COMMITS_AHEAD,COMMITS_BEHIND,STASHES,TAG,NUM_UNSTAGED_DELETED,NUM_STAGED_NEW,NUM_STAGED_DELETED,PUSH_REMOTE_NAME,PUSH_REMOTE_URL,PUSH_COMMITS_AHEAD,PUSH_COMMITS_BEHIND,NUM_SKIP_WORKTREE,NUM_ASSUME_UNCHANGED}
}
_gitstatus_daemon_p9k_ () {
	local -i pipe_fd
	exec <&- {pipe_fd}>&1 >> $daemon_log 2>&1 || return
	local pgid=$sysparams[pid]
	[[ $pgid == <1-> ]] || return
	builtin cd -q / || return
	{
		{
			trap '' PIPE
			local uname_sm
			uname_sm="${${(L)$(command uname -sm)}//ı/i}"  || return
			[[ $uname_sm == [^' ']##' '[^' ']## ]] || return
			local uname_s=${uname_sm% *}
			local uname_m=${uname_sm#* }
			if [[ $GITSTATUS_NUM_THREADS == <1-> ]]
			then
				args+=(-t $GITSTATUS_NUM_THREADS)
			else
				local cpus
				if (( ! $+commands[sysctl] )) || [[ $uname_s == linux ]] || ! cpus="$(command sysctl -n hw.ncpu)"
				then
					if (( ! $+commands[getconf] )) || ! cpus="$(command getconf _NPROCESSORS_ONLN)"
					then
						cpus=8
					fi
				fi
				args+=(-t $((cpus > 16 ? 32 : cpus > 0 ? 2 * cpus : 16)))
			fi
			command mkfifo -- $file_prefix.fifo || return
			print -rnu $pipe_fd -- ${(l:20:)pgid} || return
			exec < $file_prefix.fifo || return
			zf_rm -- $file_prefix.fifo || return
			local _gitstatus_zsh_daemon _gitstatus_zsh_version _gitstatus_zsh_downloaded
			_gitstatus_set_daemon$fsuf () {
				_gitstatus_zsh_daemon="$1"
				_gitstatus_zsh_version="$2"
				_gitstatus_zsh_downloaded="$3"
			}
			local gitstatus_plugin_dir_var=_gitstatus_plugin_dir$fsuf
			local gitstatus_plugin_dir=${(P)gitstatus_plugin_dir_var}
			builtin set -- -d $gitstatus_plugin_dir -s $uname_s -m $uname_m -p "printf '\\001' >&$pipe_fd" -e $pipe_fd -- _gitstatus_set_daemon$fsuf
			[[ ${GITSTATUS_AUTO_INSTALL:-1} == (|-|+)<1-> ]] || builtin set -- -n "$@"
			builtin source $gitstatus_plugin_dir/install || return
			[[ -n $_gitstatus_zsh_daemon ]] || return
			[[ -n $_gitstatus_zsh_version ]] || return
			[[ $_gitstatus_zsh_downloaded == [01] ]] || return
			if (( UID == EUID ))
			then
				local home=~
			else
				local user
				user="$(command id -un)"  || return
				local home=${userdirs[$user]}
				[[ -n $home ]] || return
			fi
			if [[ -x $_gitstatus_zsh_daemon ]]
			then
				HOME=$home $_gitstatus_zsh_daemon -G $_gitstatus_zsh_version "${(@)args}" >&$pipe_fd
				local -i ret=$?
				[[ $ret == (0|129|130|131|137|141|143|159) ]] && return ret
			fi
			(( ! _gitstatus_zsh_downloaded )) || return
			[[ ${GITSTATUS_AUTO_INSTALL:-1} == (|-|+)<1-> ]] || return
			[[ $_gitstatus_zsh_daemon == ${GITSTATUS_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/gitstatus}/* ]] || return
			builtin set -- -f "$@"
			_gitstatus_zsh_daemon=
			_gitstatus_zsh_version=
			_gitstatus_zsh_downloaded=
			builtin source $gitstatus_plugin_dir/install || return
			[[ -n $_gitstatus_zsh_daemon ]] || return
			[[ -n $_gitstatus_zsh_version ]] || return
			[[ $_gitstatus_zsh_downloaded == 1 ]] || return
			HOME=$home $_gitstatus_zsh_daemon -G $_gitstatus_zsh_version "${(@)args}" >&$pipe_fd
		} always {
			local -i ret=$?
			zf_rm -f -- $file_prefix.lock $file_prefix.fifo
			kill -- -$pgid
		}
	} &|
	(( lock_fd == -1 )) && return
	{
		if zsystem flock -- $file_prefix.lock && command sleep 5 && [[ -e $file_prefix.lock ]]
		then
			zf_rm -f -- $file_prefix.lock $file_prefix.fifo
			kill -- -$pgid
		fi
	} &|
}
_gitstatus_process_response_POWERLEVEL9K-_p9k_ () {
	emulate -L zsh -o no_aliases -o extended_glob -o typeset_silent
	local pair=${${(%):-%N}#_gitstatus_process_response_}
	local name=${pair%%-*}
	local fsuf=${pair#*-}
	[[ $name == POWERLEVEL9K && $fsuf == _p9k_ ]] && eval $__p9k_intro_base
	if (( ARGC == 1 ))
	then
		_gitstatus_process_response$fsuf $name 0 ''
	else
		gitstatus_stop$fsuf $name
	fi
}
_gitstatus_process_response_p9k_ () {
	local name=$1 timeout req_id=$3 buf
	local -i resp_fd=_GITSTATUS_RESP_FD_$name
	local -i dirty_max_index_size=_GITSTATUS_DIRTY_MAX_INDEX_SIZE_$name
	(( $2 >= 0 )) && timeout=-t$2  && [[ -t $resp_fd ]]
	sysread $timeout -i $resp_fd 'buf[$#buf+1]' || {
		if (( $? == 4 ))
		then
			if [[ -n $req_id ]]
			then
				typeset -g VCS_STATUS_RESULT=tout
				_gitstatus_clear$fsuf
			fi
			return 0
		else
			gitstatus_stop$fsuf $name
			return 1
		fi
	}
	while [[ $buf != *$'\x1e' ]]
	do
		if ! sysread -i $resp_fd 'buf[$#buf+1]'
		then
			gitstatus_stop$fsuf $name
			return 1
		fi
	done
	local s
	for s in ${(ps:\x1e:)buf}
	do
		local -a resp=("${(@ps:\x1f:)s}")
		if (( resp[2] ))
		then
			if [[ $resp[1] == $req_id' '* ]]
			then
				typeset -g VCS_STATUS_RESULT=ok-sync
			else
				typeset -g VCS_STATUS_RESULT=ok-async
			fi
			for VCS_STATUS_WORKDIR VCS_STATUS_COMMIT VCS_STATUS_LOCAL_BRANCH VCS_STATUS_REMOTE_BRANCH VCS_STATUS_REMOTE_NAME VCS_STATUS_REMOTE_URL VCS_STATUS_ACTION VCS_STATUS_INDEX_SIZE VCS_STATUS_NUM_STAGED VCS_STATUS_NUM_UNSTAGED VCS_STATUS_NUM_CONFLICTED VCS_STATUS_NUM_UNTRACKED VCS_STATUS_COMMITS_AHEAD VCS_STATUS_COMMITS_BEHIND VCS_STATUS_STASHES VCS_STATUS_TAG VCS_STATUS_NUM_UNSTAGED_DELETED VCS_STATUS_NUM_STAGED_NEW VCS_STATUS_NUM_STAGED_DELETED VCS_STATUS_PUSH_REMOTE_NAME VCS_STATUS_PUSH_REMOTE_URL VCS_STATUS_PUSH_COMMITS_AHEAD VCS_STATUS_PUSH_COMMITS_BEHIND VCS_STATUS_NUM_SKIP_WORKTREE VCS_STATUS_NUM_ASSUME_UNCHANGED VCS_STATUS_COMMIT_ENCODING VCS_STATUS_COMMIT_SUMMARY in "${(@)resp[3,29]}"
			do

			done
			typeset -gi VCS_STATUS_{INDEX_SIZE,NUM_STAGED,NUM_UNSTAGED,NUM_CONFLICTED,NUM_UNTRACKED,COMMITS_AHEAD,COMMITS_BEHIND,STASHES,NUM_UNSTAGED_DELETED,NUM_STAGED_NEW,NUM_STAGED_DELETED,PUSH_COMMITS_AHEAD,PUSH_COMMITS_BEHIND,NUM_SKIP_WORKTREE,NUM_ASSUME_UNCHANGED}
			typeset -gi VCS_STATUS_HAS_STAGED=$((VCS_STATUS_NUM_STAGED > 0))
			if (( dirty_max_index_size >= 0 && VCS_STATUS_INDEX_SIZE > dirty_max_index_size ))
			then
				typeset -gi VCS_STATUS_HAS_UNSTAGED=-1 VCS_STATUS_HAS_CONFLICTED=-1 VCS_STATUS_HAS_UNTRACKED=-1
			else
				typeset -gi VCS_STATUS_HAS_UNSTAGED=$((VCS_STATUS_NUM_UNSTAGED > 0)) VCS_STATUS_HAS_CONFLICTED=$((VCS_STATUS_NUM_CONFLICTED > 0)) VCS_STATUS_HAS_UNTRACKED=$((VCS_STATUS_NUM_UNTRACKED > 0))
			fi
		else
			if [[ $resp[1] == $req_id' '* ]]
			then
				typeset -g VCS_STATUS_RESULT=norepo-sync
			else
				typeset -g VCS_STATUS_RESULT=norepo-async
			fi
			_gitstatus_clear$fsuf
		fi
		(( --_GITSTATUS_NUM_INFLIGHT_$name ))
		[[ $VCS_STATUS_RESULT == *-async ]] && emulate zsh -c "${resp[1]#* }"
	done
	return 0
}
_global () {
	# undefined
	builtin autoload -XUz
}
_global_tags () {
	# undefined
	builtin autoload -XUz
}
_globflags () {
	# undefined
	builtin autoload -XUz
}
_globqual_delims () {
	# undefined
	builtin autoload -XUz
}
_globquals () {
	# undefined
	builtin autoload -XUz
}
_gnome-gv () {
	# undefined
	builtin autoload -XUz
}
_gnu_generic () {
	# undefined
	builtin autoload -XUz
}
_gnupod () {
	# undefined
	builtin autoload -XUz
}
_gnutls () {
	# undefined
	builtin autoload -XUz
}
_go () {
	# undefined
	builtin autoload -XUz
}
_gpasswd () {
	# undefined
	builtin autoload -XUz
}
_gpg () {
	# undefined
	builtin autoload -XUz
}
_gphoto2 () {
	# undefined
	builtin autoload -XUz
}
_gprof () {
	# undefined
	builtin autoload -XUz
}
_gqview () {
	# undefined
	builtin autoload -XUz
}
_gradle () {
	# undefined
	builtin autoload -XUz
}
_graphicsmagick () {
	# undefined
	builtin autoload -XUz
}
_grep () {
	# undefined
	builtin autoload -XUz
}
_grep-excuses () {
	# undefined
	builtin autoload -XUz
}
_groff () {
	# undefined
	builtin autoload -XUz
}
_groups () {
	# undefined
	builtin autoload -XUz
}
_growisofs () {
	# undefined
	builtin autoload -XUz
}
_gsettings () {
	# undefined
	builtin autoload -XUz
}
_gstat () {
	# undefined
	builtin autoload -XUz
}
_guard () {
	# undefined
	builtin autoload -XUz
}
_guilt () {
	# undefined
	builtin autoload -XUz
}
_gv () {
	# undefined
	builtin autoload -XUz
}
_gzip () {
	# undefined
	builtin autoload -XUz
}
_hash () {
	# undefined
	builtin autoload -XUz
}
_have_glob_qual () {
	local complete
	[[ $2 = complete ]] && complete=")"
	[[ -z $compstate[quote] && ( ( $_comp_caller_options[bareglobqual] == on && $1 = (#b)(((*[^\\\$]|)(\\\\)#)\()([^\)\|\~]#)$complete && ${#match[1]} -gt 1 ) || ( $_comp_caller_options[extendedglob] == on && $1 = (#b)(((*[^\\\$]|)(\\\\)#)"(#q")([^\)]#)$complete ) ) ]]
}
_hdiutil () {
	# undefined
	builtin autoload -XUz
}
_head () {
	# undefined
	builtin autoload -XUz
}
_hexdump () {
	# undefined
	builtin autoload -XUz
}
_hg () {
	# undefined
	builtin autoload -XUz
}
_history () {
	# undefined
	builtin autoload -XUz
}
_history_complete_word () {
	# undefined
	builtin autoload -XUz
}
_history_modifiers () {
	# undefined
	builtin autoload -XUz
}
_host () {
	# undefined
	builtin autoload -XUz
}
_hostname () {
	# undefined
	builtin autoload -XUz
}
_hosts () {
	# undefined
	builtin autoload -XUz
}
_htop () {
	# undefined
	builtin autoload -XUz
}
_hwinfo () {
	# undefined
	builtin autoload -XUz
}
_iconv () {
	# undefined
	builtin autoload -XUz
}
_iconvconfig () {
	# undefined
	builtin autoload -XUz
}
_id () {
	# undefined
	builtin autoload -XUz
}
_ifconfig () {
	# undefined
	builtin autoload -XUz
}
_iftop () {
	# undefined
	builtin autoload -XUz
}
_ignored () {
	[[ _matcher_num -gt 1 || $compstate[ignored] -eq 0 ]] && return 1
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
	return 1
}
_imagemagick () {
	# undefined
	builtin autoload -XUz
}
_in_vared () {
	# undefined
	builtin autoload -XUz
}
_inetadm () {
	# undefined
	builtin autoload -XUz
}
_init_d () {
	# undefined
	builtin autoload -XUz
}
_initctl () {
	# undefined
	builtin autoload -XUz
}
_install () {
	# undefined
	builtin autoload -XUz
}
_invoke-rc.d () {
	# undefined
	builtin autoload -XUz
}
_ionice () {
	# undefined
	builtin autoload -XUz
}
_iostat () {
	# undefined
	builtin autoload -XUz
}
_ip () {
	# undefined
	builtin autoload -XUz
}
_ipadm () {
	# undefined
	builtin autoload -XUz
}
_ipsec () {
	# undefined
	builtin autoload -XUz
}
_ipset () {
	# undefined
	builtin autoload -XUz
}
_iptables () {
	# undefined
	builtin autoload -XUz
}
_irssi () {
	# undefined
	builtin autoload -XUz
}
_isTrue () {
	if [ "$1" = $TRUE ]
	then
		return 0
	else
		return 1
	fi
}
_ispell () {
	# undefined
	builtin autoload -XUz
}
_iwconfig () {
	# undefined
	builtin autoload -XUz
}
_jail () {
	# undefined
	builtin autoload -XUz
}
_jails () {
	# undefined
	builtin autoload -XUz
}
_java () {
	# undefined
	builtin autoload -XUz
}
_java_class () {
	# undefined
	builtin autoload -XUz
}
_jexec () {
	# undefined
	builtin autoload -XUz
}
_jls () {
	# undefined
	builtin autoload -XUz
}
_jobs () {
	local expl disp jobs job jids pfx='%' desc how expls sep
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
	fi
}
_jobs_bg () {
	# undefined
	builtin autoload -XUz
}
_jobs_builtin () {
	# undefined
	builtin autoload -XUz
}
_jobs_fg () {
	# undefined
	builtin autoload -XUz
}
_joe () {
	# undefined
	builtin autoload -XUz
}
_join () {
	# undefined
	builtin autoload -XUz
}
_jot () {
	# undefined
	builtin autoload -XUz
}
_jq () {
	# undefined
	builtin autoload -XUz
}
_kdeconnect () {
	# undefined
	builtin autoload -XUz
}
_kfmclient () {
	# undefined
	builtin autoload -XUz
}
_kill () {
	# undefined
	builtin autoload -XUz
}
_killall () {
	# undefined
	builtin autoload -XUz
}
_kld () {
	# undefined
	builtin autoload -XUz
}
_knock () {
	# undefined
	builtin autoload -XUz
}
_kpartx () {
	# undefined
	builtin autoload -XUz
}
_kvno () {
	# undefined
	builtin autoload -XUz
}
_last () {
	# undefined
	builtin autoload -XUz
}
_ld_debug () {
	# undefined
	builtin autoload -XUz
}
_ldap () {
	# undefined
	builtin autoload -XUz
}
_ldconfig () {
	# undefined
	builtin autoload -XUz
}
_ldd () {
	# undefined
	builtin autoload -XUz
}
_less () {
	# undefined
	builtin autoload -XUz
}
_lha () {
	# undefined
	builtin autoload -XUz
}
_libvirt () {
	# undefined
	builtin autoload -XUz
}
_lighttpd () {
	# undefined
	builtin autoload -XUz
}
_limit () {
	# undefined
	builtin autoload -XUz
}
_limits () {
	# undefined
	builtin autoload -XUz
}
_links () {
	# undefined
	builtin autoload -XUz
}
_links-grep () {
	{
		[[ ${#} -gt 1 ]] && SZ_REGEX="${2}${1}${2}"  || SZ_REGEX="${1}"
		isDebug && echo "${SZ_REGEX}"
		grep --color=auto -ril . $LINKS | grep --color=auto "${SZ_REGEX}"
	} 2> /dev/null
}
_lintian () {
	# undefined
	builtin autoload -XUz
}
_list () {
	# undefined
	builtin autoload -XUz
}
_list_files () {
	local stat f elt what dir
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
	return 0
}
_list_user_groups () {
	IFS=$DELIMITER_ENDL
	listit $(groups $1) $" "
	IFS=$IFS_ORIG
}
_lldb () {
	# undefined
	builtin autoload -XUz
}
_ln () {
	# undefined
	builtin autoload -XUz
}
_loadkeys () {
	# undefined
	builtin autoload -XUz
}
_locale () {
	# undefined
	builtin autoload -XUz
}
_localedef () {
	# undefined
	builtin autoload -XUz
}
_locales () {
	# undefined
	builtin autoload -XUz
}
_locate () {
	# undefined
	builtin autoload -XUz
}
_logical_volumes () {
	# undefined
	builtin autoload -XUz
}
_look () {
	# undefined
	builtin autoload -XUz
}
_lp () {
	# undefined
	builtin autoload -XUz
}
_ls () {
	local arguments is_gnu datef
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
	_arguments -s -S : $arguments
}
_lsattr () {
	# undefined
	builtin autoload -XUz
}
_lsblk () {
	# undefined
	builtin autoload -XUz
}
_lscfg () {
	# undefined
	builtin autoload -XUz
}
_lsdev () {
	# undefined
	builtin autoload -XUz
}
_lslv () {
	# undefined
	builtin autoload -XUz
}
_lsof () {
	# undefined
	builtin autoload -XUz
}
_lspv () {
	# undefined
	builtin autoload -XUz
}
_lsusb () {
	# undefined
	builtin autoload -XUz
}
_lsvg () {
	# undefined
	builtin autoload -XUz
}
_ltrace () {
	# undefined
	builtin autoload -XUz
}
_lua () {
	# undefined
	builtin autoload -XUz
}
_luarocks () {
	# undefined
	builtin autoload -XUz
}
_lynx () {
	# undefined
	builtin autoload -XUz
}
_lz4 () {
	# undefined
	builtin autoload -XUz
}
_lzop () {
	# undefined
	builtin autoload -XUz
}
_mac_applications () {
	# undefined
	builtin autoload -XUz
}
_mac_files_for_application () {
	# undefined
	builtin autoload -XUz
}
_madison () {
	# undefined
	builtin autoload -XUz
}
_mail () {
	# undefined
	builtin autoload -XUz
}
_mailboxes () {
	# undefined
	builtin autoload -XUz
}
_main_complete () {
	local IFS=$' \t\n\0'
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
			[[ -n $prefix ]] && _comp_colors+=("=(#i)${prefix[1,-2]//?/(}${prefix[1,-2]//(#m)?/${MATCH/$~toquote/\\$MATCH}|)}${prefix[-1]//(#m)$~toquote/\\$MATCH}(#b)(?|)*==$_ambiguous_color")
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
	return ret
}
_make () {
	# undefined
	builtin autoload -XUz
}
_make-kpkg () {
	# undefined
	builtin autoload -XUz
}
_man () {
	# undefined
	builtin autoload -XUz
}
_match () {
	# undefined
	builtin autoload -XUz
}
_math () {
	# undefined
	builtin autoload -XUz
}
_math_params () {
	# undefined
	builtin autoload -XUz
}
_matlab () {
	# undefined
	builtin autoload -XUz
}
_md5sum () {
	# undefined
	builtin autoload -XUz
}
_mdadm () {
	# undefined
	builtin autoload -XUz
}
_mdfind () {
	# undefined
	builtin autoload -XUz
}
_mdls () {
	# undefined
	builtin autoload -XUz
}
_mdutil () {
	# undefined
	builtin autoload -XUz
}
_members () {
	# undefined
	builtin autoload -XUz
}
_mencal () {
	# undefined
	builtin autoload -XUz
}
_menu () {
	# undefined
	builtin autoload -XUz
}
_mere () {
	# undefined
	builtin autoload -XUz
}
_mergechanges () {
	# undefined
	builtin autoload -XUz
}
_message () {
	# undefined
	builtin autoload -XUz
}
_mh () {
	# undefined
	builtin autoload -XUz
}
_mii-tool () {
	# undefined
	builtin autoload -XUz
}
_mime_types () {
	# undefined
	builtin autoload -XUz
}
_mixerctl () {
	# undefined
	builtin autoload -XUz
}
_mkdir () {
	# undefined
	builtin autoload -XUz
}
_mkfifo () {
	# undefined
	builtin autoload -XUz
}
_mknod () {
	# undefined
	builtin autoload -XUz
}
_mkshortcut () {
	# undefined
	builtin autoload -XUz
}
_mktemp () {
	# undefined
	builtin autoload -XUz
}
_mkzsh () {
	# undefined
	builtin autoload -XUz
}
_module () {
	# undefined
	builtin autoload -XUz
}
_module-assistant () {
	# undefined
	builtin autoload -XUz
}
_module_math_func () {
	# undefined
	builtin autoload -XUz
}
_modutils () {
	# undefined
	builtin autoload -XUz
}
_mondo () {
	# undefined
	builtin autoload -XUz
}
_monotone () {
	# undefined
	builtin autoload -XUz
}
_moosic () {
	# undefined
	builtin autoload -XUz
}
_mosh () {
	# undefined
	builtin autoload -XUz
}
_most_recent_file () {
	# undefined
	builtin autoload -XUz
}
_mount () {
	# undefined
	builtin autoload -XUz
}
_mozilla () {
	# undefined
	builtin autoload -XUz
}
_mpc () {
	# undefined
	builtin autoload -XUz
}
_mplayer () {
	# undefined
	builtin autoload -XUz
}
_mt () {
	# undefined
	builtin autoload -XUz
}
_mtools () {
	# undefined
	builtin autoload -XUz
}
_mtr () {
	# undefined
	builtin autoload -XUz
}
_multi_parts () {
	# undefined
	builtin autoload -XUz
}
_mupdf () {
	# undefined
	builtin autoload -XUz
}
_mutt () {
	# undefined
	builtin autoload -XUz
}
_mv () {
	# undefined
	builtin autoload -XUz
}
_my_accounts () {
	# undefined
	builtin autoload -XUz
}
_mysql_utils () {
	# undefined
	builtin autoload -XUz
}
_mysqldiff () {
	# undefined
	builtin autoload -XUz
}
_n-lines-from-m () {
	usage $0 $# 0 "<path to file: string> [<line to start from=0: number> [<count of lines to show:    number>]]" "displays n lines from m-th line of an ASCII file (cat-like)\n (shell not miaow)\n1st   param is the path to a file (mandatory)\n2nd argument is m, defaults to 0 and indicates the        starting line \n3rd argument is n, defaults to 10 and indicates to count of lines to be            displayed\na command like \"head\" or \"tail\" starting anywhere but the start (head) or the end   (tail) of a file" || return 1
	M=0
	N=10
	[[ -n $2 ]] && M=$2
	[[ -n $3 ]] && N=$3
	CNTLNS=$(cat "${1}" | wc -l)
	tail -n $(($CNTLNS-$M)) "${1}" | head -n $N
}
_nautilus () {
	# undefined
	builtin autoload -XUz
}
_nbsd_architectures () {
	# undefined
	builtin autoload -XUz
}
_ncftp () {
	# undefined
	builtin autoload -XUz
}
_nedit () {
	# undefined
	builtin autoload -XUz
}
_negate () {
	echo $(( ($1 - 1) * -1 ))
}
_net_interfaces () {
	# undefined
	builtin autoload -XUz
}
_netcat () {
	# undefined
	builtin autoload -XUz
}
_netscape () {
	# undefined
	builtin autoload -XUz
}
_netstat () {
	# undefined
	builtin autoload -XUz
}
_networkmanager () {
	# undefined
	builtin autoload -XUz
}
_networksetup () {
	# undefined
	builtin autoload -XUz
}
_newsgroups () {
	# undefined
	builtin autoload -XUz
}
_next_label () {
	local __gopt __descr __spec
	__gopt=()
	zparseopts -D -a __gopt 1 2 V J x
	if comptags -A "$1" curtag __spec
	then
		(( $#funcstack > _tags_level )) && _comp_tags="${_comp_tags% * }"
		_tags_level=$#funcstack
		_comp_tags="$_comp_tags $__spec "
		if [[ "$curtag" = *[^\\]:* ]]
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
	return 1
}
_next_tags () {
	# undefined
	builtin autoload -XUz
}
_nginx () {
	# undefined
	builtin autoload -XUz
}
_ngrep () {
	# undefined
	builtin autoload -XUz
}
_nice () {
	# undefined
	builtin autoload -XUz
}
_ninja () {
	# undefined
	builtin autoload -XUz
}
_nkf () {
	# undefined
	builtin autoload -XUz
}
_nl () {
	# undefined
	builtin autoload -XUz
}
_nm () {
	# undefined
	builtin autoload -XUz
}
_nmap () {
	# undefined
	builtin autoload -XUz
}
_normal () {
	local _comp_command1 _comp_command2 _comp_command skip
	if [[ "$1" = -s ]]
	then
		skip=(-s)
	else
		skip=()
		_compskip=''
	fi
	if [[ -o BANG_HIST && ( ( $words[CURRENT] = \!*: && -z $compstate[quote] ) || ( $words[CURRENT] = \"\!*: && $compstate[all_quotes] = \" ) ) ]]
	then
		PREFIX=${PREFIX//\\!/!}
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
	_dispatch "$skip[@]" "$_comp_command" "$_comp_command1" "$_comp_command2" -default-
}
_nothing () {
	# undefined
	builtin autoload -XUz
}
_notmuch () {
	# undefined
	builtin autoload -XUz
}
_npm () {
	# undefined
	builtin autoload -XUz
}
_nslookup () {
	# undefined
	builtin autoload -XUz
}
_numfmt () {
	# undefined
	builtin autoload -XUz
}
_nvram () {
	# undefined
	builtin autoload -XUz
}
_objdump () {
	# undefined
	builtin autoload -XUz
}
_object_classes () {
	# undefined
	builtin autoload -XUz
}
_object_files () {
	# undefined
	builtin autoload -XUz
}
_obsd_architectures () {
	# undefined
	builtin autoload -XUz
}
_od () {
	# undefined
	builtin autoload -XUz
}
_okular () {
	# undefined
	builtin autoload -XUz
}
_oldlist () {
	# undefined
	builtin autoload -XUz
}
_omz_diag_dump_check_core_commands () {
	builtin echo "Core command check:"
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
	fi
}
_omz_diag_dump_echo_file_w_header () {
	local file=$1
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
	fi
}
_omz_diag_dump_one_big_text () {
	local program programs progfile md5
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
			builtin printf '%-9s %-20s %s\n' "$program is" "$progfile" "$extra_str"
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
	fi
}
_omz_diag_dump_os_specific_version () {
	local osname osver version_file version_files
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
	done
}
_open () {
	# undefined
	builtin autoload -XUz
}
_openstack () {
	# undefined
	builtin autoload -XUz
}
_opkg () {
	# undefined
	builtin autoload -XUz
}
_options () {
	# undefined
	builtin autoload -XUz
}
_options_set () {
	# undefined
	builtin autoload -XUz
}
_options_unset () {
	# undefined
	builtin autoload -XUz
}
_osascript () {
	# undefined
	builtin autoload -XUz
}
_osc () {
	# undefined
	builtin autoload -XUz
}
_other_accounts () {
	# undefined
	builtin autoload -XUz
}
_otool () {
	# undefined
	builtin autoload -XUz
}
_p9k_all_params_eq () {
	local key
	for key in ${parameters[(I)${~1}]}
	do
		[[ ${(P)key} == $2 ]] || return
	done
}
_p9k_asdf_check_meta () {
	[[ -n $_p9k_asdf_meta_sig ]] || return
	[[ -z $^_p9k_asdf_meta_non_files(#qN) ]] || return
	local -a stat
	if (( $#_p9k_asdf_meta_files ))
	then
		zstat -A stat +mtime -- $_p9k_asdf_meta_files 2> /dev/null || return
	fi
	[[ $_p9k_asdf_meta_sig == $ASDF_CONFIG_FILE$'\0'$ASDF_DATA_DIR$'\0'${(pj:\0:)stat} ]] || return
}
_p9k_asdf_init_meta () {
	local last_sig=$_p9k_asdf_meta_sig
	{
		local -a files
		local -i legacy_enabled
		_p9k_asdf_plugins=()
		_p9k_asdf_file_info=()
		local cfg=${ASDF_CONFIG_FILE:-~/.asdfrc}
		files+=$cfg
		if [[ -f $cfg && -r $cfg ]]
		then
			local lines=(${(@M)${(@)${(f)"$(<$cfg)"}%$'\r'}:#[[:space:]]#legacy_version_file[[:space:]]#=*})
			if [[ $#lines == 1 && ${${(s:=:)lines[1]}[2]} == [[:space:]]#yes[[:space:]]# ]]
			then
				legacy_enabled=1
			fi
		fi
		local root=${ASDF_DATA_DIR:-~/.asdf}
		files+=$root/plugins
		if [[ -d $root/plugins ]]
		then
			local plugin
			for plugin in $root/plugins/[^[:space:]]##(/N)
			do
				files+=$root/installs/${plugin:t}
				local -aU installed=($root/installs/${plugin:t}/[^[:space:]]##(/N:t) system)
				_p9k_asdf_plugins[${plugin:t}]=${(j:|:)${(@b)installed}}
				(( legacy_enabled )) || continue
				if [[ ! -e $plugin/bin ]]
				then
					files+=$plugin/bin
				else
					local list_names=$plugin/bin/list-legacy-filenames
					files+=$list_names
					if [[ -x $list_names ]]
					then
						local parse=$plugin/bin/parse-legacy-file
						local -i has_parse=0
						files+=$parse
						[[ -x $parse ]] && has_parse=1
						local name
						for name in ${$($list_names 2>/dev/null)%$'\r'}
						do
							[[ $name == (*/*|.tool-versions) ]] && continue
							_p9k_asdf_file_info[$name]+="${plugin:t} $has_parse "
						done
					fi
				fi
			done
		fi
		_p9k_asdf_meta_files=($^files(N))
		_p9k_asdf_meta_non_files=(${files:|_p9k_asdf_meta_files})
		local -a stat
		if (( $#_p9k_asdf_meta_files ))
		then
			zstat -A stat +mtime -- $_p9k_asdf_meta_files 2> /dev/null || return
		fi
		_p9k_asdf_meta_sig=$ASDF_CONFIG_FILE$'\0'$ASDF_DATA_DIR$'\0'${(pj:\0:)stat}
		_p9k__asdf_dir2files=()
		_p9k_asdf_file2versions=()
	} always {
		if (( $? == 0 ))
		then
			_p9k__state_dump_scheduled=1
			return
		fi
		[[ -n $last_sig ]] && _p9k__state_dump_scheduled=1
		_p9k_asdf_meta_files=()
		_p9k_asdf_meta_non_files=()
		_p9k_asdf_meta_sig=
		_p9k_asdf_plugins=()
		_p9k_asdf_file_info=()
		_p9k__asdf_dir2files=()
		_p9k_asdf_file2versions=()
	}
}
_p9k_asdf_parse_version_file () {
	local file=$1
	local is_legacy=$2
	local -a stat
	zstat -A stat +mtime $file 2> /dev/null || return
	if (( is_legacy ))
	then
		local plugin has_parse
		for plugin has_parse in $=_p9k_asdf_file_info[$file:t]
		do
			local cached=$_p9k_asdf_file2versions[$plugin:$file]
			if [[ $cached == $stat[1]:* ]]
			then
				local v=${cached#*:}
			else
				if (( has_parse ))
				then
					local v=($(${ASDF_DATA_DIR:-~/.asdf}/plugins/$plugin/bin/parse-legacy-file $file 2>/dev/null))
				else
					{
						local v=($(<$file))
					} 2> /dev/null
				fi
				v=(${v%$'\r'})
				v=${v[(r)$_p9k_asdf_plugins[$plugin]]:-$v[1]}
				_p9k_asdf_file2versions[$plugin:$file]=$stat[1]:"$v"
				_p9k__state_dump_scheduled=1
			fi
			[[ -n $v ]] && : ${versions[$plugin]="$v"}
		done
	else
		local cached=$_p9k_asdf_file2versions[:$file]
		if [[ $cached == $stat[1]:* ]]
		then
			local file_versions=(${(0)${cached#*:}})
		else
			local file_versions=()
			{
				local lines=(${(@)${(@)${(f)"$(<$file)"}%$'\r'}/\#*})
			} 2> /dev/null
			local line
			for line in $lines
			do
				local words=($=line)
				(( $#words > 1 )) || continue
				local installed=$_p9k_asdf_plugins[$words[1]]
				[[ -n $installed ]] || continue
				file_versions+=($words[1] ${${words:1}[(r)$installed]:-$words[2]})
			done
			_p9k_asdf_file2versions[:$file]=$stat[1]:${(pj:\0:)file_versions}
			_p9k__state_dump_scheduled=1
		fi
		local plugin version
		for plugin version in $file_versions
		do
			: ${versions[$plugin]=$version}
		done
	fi
	return 0
}
_p9k_async_segments_compute () {
	_p9k_gcloud_prefetch
	_p9k_worker_invoke load _p9k_prompt_load_compute
}
_p9k_background () {
	[[ -n $1 ]] && _p9k__ret="%K{$1}"  || _p9k__ret="%k"
}
_p9k_build_gap_post () {
	if [[ $1 == 1 ]]
	then
		local kind_l=first kind_u=FIRST
	else
		local kind_l=newline kind_u=NEWLINE
	fi
	_p9k_get_icon '' MULTILINE_${kind_u}_PROMPT_GAP_CHAR
	local char=${_p9k__ret:- }
	_p9k_prompt_length $char
	if (( _p9k__ret != 1 || $#char != 1 ))
	then
		print -rP -- "%F{red}WARNING!%f %BMULTILINE_${kind_u}_PROMPT_GAP_CHAR%b is not one character long. Will use ' '." >&2
		print -rP -- "Either change the value of %BPOWERLEVEL9K_MULTILINE_${kind_u}_PROMPT_GAP_CHAR%b or remove it." >&2
		char=' '
	fi
	local style
	_p9k_color prompt_multiline_${kind_l}_prompt_gap BACKGROUND ""
	[[ -n $_p9k__ret ]] && _p9k_background $_p9k__ret
	style+=$_p9k__ret
	_p9k_color prompt_multiline_${kind_l}_prompt_gap FOREGROUND ""
	[[ -n $_p9k__ret ]] && _p9k_foreground $_p9k__ret
	style+=$_p9k__ret
	_p9k_escape_style $style
	style=$_p9k__ret
	local exp=_POWERLEVEL9K_MULTILINE_${kind_u}_PROMPT_GAP_EXPANSION
	(( $+parameters[$exp] )) && exp=${(P)exp}  || exp='${P9K_GAP}'
	[[ $char == '.' ]] && local s=','  || local s='.'
	_p9k__ret=$'${${_p9k__g+\n}:-'$style'${${${_p9k__m:#-*}:+'
	_p9k__ret+='${${_p9k__'$1'g+${(pl.$((_p9k__m+1)).. .)}}:-'
	if [[ $exp == '${P9K_GAP}' ]]
	then
		_p9k__ret+='${(pl'$s'$((_p9k__m+1))'$s$s$char$s')}'
	else
		_p9k__ret+='${${P9K_GAP::=${(pl'$s'$((_p9k__m+1))'$s$s$char$s')}}+}'
		_p9k__ret+='${:-"'$exp'"}'
		style=1
	fi
	_p9k__ret+='}'
	if (( __p9k_ksh_arrays ))
	then
		_p9k__ret+=$'$_p9k__rprompt${_p9k_t[$((!_p9k__ind))]}}:-\n}'
	else
		_p9k__ret+=$'$_p9k__rprompt${_p9k_t[$((1+!_p9k__ind))]}}:-\n}'
	fi
	[[ -n $style ]] && _p9k__ret+='%b%k%f'
	_p9k__ret+='}'
}
_p9k_build_test_stats () {
	local code_amount="$2"
	local tests_amount="$3"
	local headline="$4"
	(( code_amount > 0 )) || return
	local -F 2 ratio=$(( 100. * tests_amount / code_amount ))
	(( ratio >= 75 )) && _p9k_prompt_segment "${1}_GOOD" "cyan" "$_p9k_color1" "$5" 0 '' "$headline: $ratio%%"
	(( ratio >= 50 && ratio < 75 )) && _p9k_prompt_segment "$1_AVG" "yellow" "$_p9k_color1" "$5" 0 '' "$headline: $ratio%%"
	(( ratio < 50 )) && _p9k_prompt_segment "$1_BAD" "red" "$_p9k_color1" "$5" 0 '' "$headline: $ratio%%"
}
_p9k_cache_ephemeral_get () {
	_p9k__cache_key="${(pj:\0:)*}"
	local v=$_p9k__cache_ephemeral[$_p9k__cache_key]
	[[ -n $v ]] && _p9k__cache_val=("${(@0)${v[1,-2]}}")
}
_p9k_cache_ephemeral_set () {
	_p9k__cache_ephemeral[$_p9k__cache_key]="${(pj:\0:)*}0"
	_p9k__cache_val=("$@")
}
_p9k_cache_get () {
	_p9k__cache_key="${(pj:\0:)*}"
	local v=$_p9k_cache[$_p9k__cache_key]
	[[ -n $v ]] && _p9k__cache_val=("${(@0)${v[1,-2]}}")
}
_p9k_cache_set () {
	_p9k_cache[$_p9k__cache_key]="${(pj:\0:)*}0"
	_p9k__cache_val=("$@")
	_p9k__state_dump_scheduled=1
}
_p9k_cache_stat_get () {
	local -H stat
	local label=$1 f
	shift
	_p9k__cache_stat_meta=
	_p9k__cache_stat_fprint=
	for f
	do
		if zstat -H stat -- $f 2> /dev/null
		then
			_p9k__cache_stat_meta+="${(q)f} $stat[inode] $stat[mtime] $stat[size] $stat[mode]; "
		fi
	done
	if _p9k_cache_get $0 $label meta "$@"
	then
		if [[ $_p9k__cache_val[1] == $_p9k__cache_stat_meta ]]
		then
			_p9k__cache_stat_fprint=$_p9k__cache_val[2]
			local -a key=($0 $label fprint "$@" "$_p9k__cache_stat_fprint")
			_p9k__cache_fprint_key="${(pj:\0:)key}"
			shift 2 _p9k__cache_val
			return 0
		else
			local -a key=($0 $label fprint "$@" "$_p9k__cache_val[2]")
			_p9k__cache_ephemeral[${(pj:\0:)key}]="${(pj:\0:)_p9k__cache_val[3,-1]}0"
		fi
	fi
	if (( $+commands[md5] ))
	then
		_p9k__cache_stat_fprint="$(md5 -- $* 2>&1)"
	elif (( $+commands[md5sum] ))
	then
		_p9k__cache_stat_fprint="$(md5sum -b -- $* 2>&1)"
	else
		return 1
	fi
	local meta_key=$_p9k__cache_key
	if _p9k_cache_ephemeral_get $0 $label fprint "$@" "$_p9k__cache_stat_fprint"
	then
		_p9k__cache_fprint_key=$_p9k__cache_key
		_p9k__cache_key=$meta_key
		_p9k_cache_set "$_p9k__cache_stat_meta" "$_p9k__cache_stat_fprint" "$_p9k__cache_val[@]"
		shift 2 _p9k__cache_val
		return 0
	fi
	_p9k__cache_fprint_key=$_p9k__cache_key
	_p9k__cache_key=$meta_key
	return 1
}
_p9k_cache_stat_set () {
	_p9k_cache_set "$_p9k__cache_stat_meta" "$_p9k__cache_stat_fprint" "$@"
	_p9k__cache_key=$_p9k__cache_fprint_key
	_p9k_cache_ephemeral_set "$@"
}
_p9k_cached_cmd () {
	local cmd=$commands[$3]
	[[ -n $cmd ]] || return
	if ! _p9k_cache_stat_get $0" ${(q)*}" $2 $cmd
	then
		local out
		if (( $1 ))
		then
			out="$($cmd "${@:4}" 2>&1)"
		else
			out="$($cmd "${@:4}" 2>/dev/null)"
		fi
		_p9k_cache_stat_set $(( ! $? )) "$out"
	fi
	(( $_p9k__cache_val[1] )) || return
	_p9k__ret=$_p9k__cache_val[2]
}
_p9k_can_configure () {
	[[ $1 == '-q' ]] && local -i q=1  || local -i q=0
	$0_error () {
		(( q )) || print -rP "%1F[ERROR]%f %Bp10k configure%b: $1" >&2
	}
	typeset -g __p9k_cfg_path_o=${POWERLEVEL9K_CONFIG_FILE:=${ZDOTDIR:-~}/.p10k.zsh}
	typeset -g __p9k_cfg_basename=${__p9k_cfg_path_o:t}
	typeset -g __p9k_cfg_path=${__p9k_cfg_path_o:A}
	typeset -g __p9k_cfg_path_u=${${${(q)__p9k_cfg_path_o}/#(#b)${(q)HOME}(|\/*)/'~'$match[1]}//\%/%%}
	{
		[[ -o multibyte ]] || {
			$0_error "multibyte option is not set"
			return 1
		}
		[[ -e $__p9k_zd ]] || {
			$0_error "$__p9k_zd_u does not exist"
			return 1
		}
		[[ -d $__p9k_zd ]] || {
			$0_error "$__p9k_zd_u is not a directory"
			return 1
		}
		[[ ! -d $__p9k_cfg_path ]] || {
			$0_error "$__p9k_cfg_path_u is a directory"
			return 1
		}
		[[ ! -d $__p9k_zshrc ]] || {
			$0_error "$__p9k_zshrc_u is a directory"
			return 1
		}
		local dir=${__p9k_cfg_path:h}
		while [[ ! -e $dir && $dir != ${dir:h} ]]
		do
			dir=${dir:h}
		done
		if [[ ! -d $dir ]]
		then
			$0_error "cannot create $__p9k_cfg_path_u because ${dir//\%/%%} is not a directory"
			return 1
		fi
		if [[ ! -w $dir ]]
		then
			$0_error "cannot create $__p9k_cfg_path_u because ${dir//\%/%%} is readonly"
			return 1
		fi
		[[ ! -e $__p9k_cfg_path || -f $__p9k_cfg_path || -h $__p9k_cfg_path ]] || {
			$0_error "$__p9k_cfg_path_u is a special file"
			return 1
		}
		[[ ! -e $__p9k_zshrc || -f $__p9k_zshrc || -h $__p9k_zshrc ]] || {
			$0_error "$__p9k_zshrc_u a special file"
			return 1
		}
		[[ ! -e $__p9k_zshrc || -r $__p9k_zshrc ]] || {
			$0_error "$__p9k_zshrc_u is not readable"
			return 1
		}
		local style
		for style in lean lean-8colors classic rainbow pure
		do
			[[ -r $__p9k_root_dir/config/p10k-$style.zsh ]] || {
				$0_error "$__p9k_root_dir_u/config/p10k-$style.zsh is not readable"
				return 1
			}
		done
		(( LINES >= __p9k_wizard_lines && COLUMNS >= __p9k_wizard_columns )) || {
			$0_error "terminal size too small; must be at least $__p9k_wizard_columns columns by $__p9k_wizard_lines lines"
			return 1
		}
		[[ -t 0 && -t 1 ]] || {
			$0_error "no TTY"
			return 2
		}
		return 0
	} always {
		unfunction $0_error
	}
}
_p9k_check_visual_mode () {
	[[ ${KEYMAP:-} == vicmd ]] || return 0
	local region=${${REGION_ACTIVE:-0}/2/1}
	[[ $region != $_p9k__region_active ]] || return 0
	_p9k__region_active=$region
	__p9k_reset_state=2
}
_p9k_clear_instant_prompt () {
	if (( $+__p9k_fd_0 ))
	then
		exec <&$__p9k_fd_0 {__p9k_fd_0}>&-
		unset __p9k_fd_0
	fi
	exec >&$__p9k_fd_1 2>&$__p9k_fd_2 {__p9k_fd_1}>&- {__p9k_fd_2}>&-
	unset __p9k_fd_1 __p9k_fd_2
	zshexit_functions=(${zshexit_functions:#_p9k_instant_prompt_cleanup})
	if (( _p9k__can_hide_cursor ))
	then
		echoti civis
		_p9k__cursor_hidden=1
	fi
	if [[ -s $__p9k_instant_prompt_output ]]
	then
		{
			local content
			[[ $_POWERLEVEL9K_INSTANT_PROMPT == verbose ]] && content="$(<$__p9k_instant_prompt_output)"
			local mark="${(e)${PROMPT_EOL_MARK-%B%S%#%s%b}}"
			_p9k_prompt_length $mark
			local -i fill=$((COLUMNS > _p9k__ret ? COLUMNS - _p9k__ret : 0))
			local cr=$'\r'
			local sp="${(%):-%b%k%f%s%u$mark${(pl.$fill.. .)}$cr%b%k%f%s%u%E}"
			if (( _z4h_can_save_restore_screen == 1 && __p9k_instant_prompt_sourced >= 35 ))
			then
				-z4h-restore-screen
				unset _z4h_saved_screen
			fi
			print -rn -- $terminfo[rc]${(%):-%b%k%f%s%u}$terminfo[ed]
			local unexpected=${${${(S)content//$'\e[?'<->'c'}//$'\e['<->' q'}//$'\e'[^$'\a\e']#($'\a'|$'\e\\')}
			if [[ -n $unexpected ]]
			then
				local omz1='[Oh My Zsh] Would you like to update? [Y/n]: '
				local omz2='Updating Oh My Zsh'
				local omz3='https://shop.planetargon.com/collections/oh-my-zsh'
				local omz4='There was an error updating. Try again later?'
				if [[ $unexpected != ($omz1|)$omz2*($omz3|$omz4)[^$'\n']#($'\n'|) ]]
				then
					echo -E - ""
					echo -E - "${(%):-[%3FWARNING%f]: Console output during zsh initialization detected.}"
					echo -E - ""
					echo -E - "${(%):-When using Powerlevel10k with instant prompt, console output during zsh}"
					echo -E - "${(%):-initialization may indicate issues.}"
					echo -E - ""
					echo -E - "${(%):-You can:}"
					echo -E - ""
					echo -E - "${(%):-  - %BRecommended%b: Change %B$__p9k_zshrc_u%b so that it does not perform console I/O}"
					echo -E - "${(%):-    after the instant prompt preamble. See the link below for details.}"
					echo -E - ""
					echo -E - "${(%):-    * You %Bwill not%b see this error message again.}"
					echo -E - "${(%):-    * Zsh will start %Bquickly%b and prompt will update %Bsmoothly%b.}"
					echo -E - ""
					echo -E - "${(%):-  - Suppress this warning either by running %Bp10k configure%b or by manually}"
					echo -E - "${(%):-    defining the following parameter:}"
					echo -E - ""
					echo -E - "${(%):-      %3Ftypeset%f -g POWERLEVEL9K_INSTANT_PROMPT=quiet}"
					echo -E - ""
					echo -E - "${(%):-    * You %Bwill not%b see this error message again.}"
					echo -E - "${(%):-    * Zsh will start %Bquickly%b but prompt will %Bjump down%b after initialization.}"
					echo -E - ""
					echo -E - "${(%):-  - Disable instant prompt either by running %Bp10k configure%b or by manually}"
					echo -E - "${(%):-    defining the following parameter:}"
					echo -E - ""
					echo -E - "${(%):-      %3Ftypeset%f -g POWERLEVEL9K_INSTANT_PROMPT=off}"
					echo -E - ""
					echo -E - "${(%):-    * You %Bwill not%b see this error message again.}"
					echo -E - "${(%):-    * Zsh will start %Bslowly%b.}"
					echo -E - ""
					echo -E - "${(%):-  - Do nothing.}"
					echo -E - ""
					echo -E - "${(%):-    * You %Bwill%b see this error message every time you start zsh.}"
					echo -E - "${(%):-    * Zsh will start %Bquickly%b but prompt will %Bjump down%b after initialization.}"
					echo -E - ""
					echo -E - "${(%):-For details, see:}"
					if (( _p9k_term_has_href ))
					then
						echo - "${(%):-\e]8;;https://github.com/romkatv/powerlevel10k/blob/master/README.md#instant-prompt\ahttps://github.com/romkatv/powerlevel10k/blob/master/README.md#instant-prompt\e]8;;\a}"
					else
						echo - "${(%):-https://github.com/romkatv/powerlevel10k/blob/master/README.md#instant-prompt}"
					fi
					echo -E - ""
					echo - "${(%):-%3F-- console output produced during zsh initialization follows --%f}"
					echo -E - ""
				fi
			fi
			command cat -- $__p9k_instant_prompt_output
			echo -nE - $sp
			zf_rm -f -- $__p9k_instant_prompt_output
		} 2> /dev/null
	else
		zf_rm -f -- $__p9k_instant_prompt_output 2> /dev/null
		if (( _z4h_can_save_restore_screen == 1 && __p9k_instant_prompt_sourced >= 35 ))
		then
			-z4h-restore-screen
			unset _z4h_saved_screen
		fi
		print -rn -- $terminfo[rc]${(%):-%b%k%f%s%u}$terminfo[ed]
	fi
	prompt_opts=(percent subst sp cr)
	if [[ $_POWERLEVEL9K_DISABLE_INSTANT_PROMPT == 0 && $__p9k_instant_prompt_active == 2 ]]
	then
		echo -E - "" >&2
		echo -E - "${(%):-[%1FERROR%f]: When using Powerlevel10k with instant prompt, %Bprompt_cr%b must be unset.}" >&2
		echo -E - "" >&2
		echo -E - "${(%):-You can:}" >&2
		echo -E - "" >&2
		echo -E - "${(%):-  - %BRecommended%b: call %Bp10k finalize%b at the end of %B$__p9k_zshrc_u%b.}" >&2
		echo -E - "${(%):-    You can do this by running the following command:}" >&2
		echo -E - "" >&2
		echo -E - "${(%):-      %2Fecho%f %3F'(( ! \${+functions[p10k]\} )) || p10k finalize'%f >>! $__p9k_zshrc_u}" >&2
		echo -E - "" >&2
		echo -E - "${(%):-    * You %Bwill not%b see this error message again.}" >&2
		echo -E - "${(%):-    * Zsh will start %Bquickly%b and %Bwithout%b prompt flickering.}" >&2
		echo -E - "" >&2
		echo -E - "${(%):-  - Find where %Bprompt_cr%b option gets sets in your zsh configs and stop setting it.}" >&2
		echo -E - "" >&2
		echo -E - "${(%):-    * You %Bwill not%b see this error message again.}" >&2
		echo -E - "${(%):-    * Zsh will start %Bquickly%b and %Bwithout%b prompt flickering.}" >&2
		echo -E - "" >&2
		echo -E - "${(%):-  - Disable instant prompt either by running %Bp10k configure%b or by manually}" >&2
		echo -E - "${(%):-    defining the following parameter:}" >&2
		echo -E - "" >&2
		echo -E - "${(%):-      %3Ftypeset%f -g POWERLEVEL9K_INSTANT_PROMPT=off}" >&2
		echo -E - "" >&2
		echo -E - "${(%):-    * You %Bwill not%b see this error message again.}" >&2
		echo -E - "${(%):-    * Zsh will start %Bslowly%b.}" >&2
		echo -E - "" >&2
		echo -E - "${(%):-  - Do nothing.}" >&2
		echo -E - "" >&2
		echo -E - "${(%):-    * You %Bwill%b see this error message every time you start zsh.}" >&2
		echo -E - "${(%):-    * Zsh will start %Bquckly%b but %Bwith%b prompt flickering.}" >&2
		echo -E - "" >&2
	fi
}
_p9k_color () {
	local key="_p9k_color ${(pj:\0:)*}"
	_p9k__ret=$_p9k_cache[$key]
	if [[ -n $_p9k__ret ]]
	then
		_p9k__ret[-1,-1]=''
	else
		_p9k_param "$@"
		_p9k_translate_color $_p9k__ret
		_p9k_cache[$key]=${_p9k__ret}.
	fi
}
_p9k_custom_prompt () {
	local segment_name=${1:u}
	local command=_POWERLEVEL9K_CUSTOM_${segment_name}
	command=${(P)command}
	local parts=("${(@z)command}")
	local cmd="${(Q)parts[1]}"
	(( $+functions[$cmd] || $+commands[$cmd] )) || return
	local content="$(eval $command)"
	[[ -n $content ]] || return
	_p9k_prompt_segment "prompt_custom_$1" $_p9k_color2 $_p9k_color1 "CUSTOM_${segment_name}_ICON" 0 '' "$content"
}
_p9k_declare () {
	local -i set=$+parameters[$2]
	(( ARGC > 2 || set )) || return 0
	case $1 in
		(-b) if (( set ))
			then
				[[ ${(P)2} == true ]] && typeset -gi _$2=1 || typeset -gi _$2=0
			else
				typeset -gi _$2=$3
			fi ;;
		(-a) local -a v=("${(@P)2}")
			if (( set ))
			then
				eval "typeset -ga _${(q)2}=(${(@qq)v})"
			else
				if [[ $3 != '--' ]]
				then
					echo "internal error in _p9k_declare " "${(qqq)@}" >&2
				fi
				eval "typeset -ga _${(q)2}=(${(@qq)*[4,-1]})"
			fi ;;
		(-i) (( set )) && typeset -gi _$2=$2 || typeset -gi _$2=$3 ;;
		(-F) (( set )) && typeset -gF _$2=$2 || typeset -gF _$2=$3 ;;
		(-s) (( set )) && typeset -g _$2=${(P)2} || typeset -g _$2=$3 ;;
		(-e) if (( set ))
			then
				local v=${(P)2}
				typeset -g _$2=${(g::)v}
			else
				typeset -g _$2=${(g::)3}
			fi ;;
		(*) echo "internal error in _p9k_declare " "${(qqq)@}" >&2 ;;
	esac
}
_p9k_deinit () {
	(( $+functions[_p9k_preinit] )) && unfunction _p9k_preinit
	(( $+functions[gitstatus_stop_p9k_] )) && gitstatus_stop_p9k_ POWERLEVEL9K
	_p9k_worker_stop
	if (( _p9k__state_dump_fd ))
	then
		zle -F $_p9k__state_dump_fd
		exec {_p9k__state_dump_fd}>&-
	fi
	if (( _p9k__restore_prompt_fd ))
	then
		zle -F $_p9k__restore_prompt_fd
		exec {_p9k__restore_prompt_fd}>&-
	fi
	if (( _p9k__redraw_fd ))
	then
		zle -F $_p9k__redraw_fd
		exec {_p9k__redraw_fd}>&-
	fi
	(( $+_p9k__iterm2_precmd )) && functions[iterm2_precmd]=$_p9k__iterm2_precmd
	(( $+_p9k__iterm2_decorate_prompt )) && functions[iterm2_decorate_prompt]=$_p9k__iterm2_decorate_prompt
	unset -m '(_POWERLEVEL9K_|P9K_|_p9k_)*~(P9K_SSH|P9K_TOOLBOX_NAME|P9K_TTY|_P9K_TTY)'
	[[ -n $__p9k_locale ]] || unset __p9k_locale
}
_p9k_delete_instant_prompt () {
	local user=${(%):-%n}
	local root_dir=${__p9k_dump_file:h}
	zf_rm -f -- $root_dir/p10k-instant-prompt-$user.zsh{,.zwc} ${root_dir}/p10k-$user/prompt-*(N) 2> /dev/null
}
_p9k_deschedule_redraw () {
	(( _p9k__redraw_fd )) || return
	zle -F $_p9k__redraw_fd
	exec {_p9k__redraw_fd}>&-
	_p9k__redraw_fd=0
}
_p9k_display_segment () {
	[[ $_p9k__display_v[$1] == $3 ]] && return
	_p9k__display_v[$1]=$3
	[[ $3 == hide ]] && typeset -g $2= || unset $2
	__p9k_reset_state=2
}
_p9k_do_dump () {
	eval "$__p9k_intro"
	zle -F $1
	exec {1}>&-
	(( _p9k__state_dump_fd )) || return
	if (( ! _p9k__instant_prompt_disabled ))
	then
		_p9k__instant_prompt_sig=$_p9k__cwd:$P9K_SSH:${(%):-%#}
		_p9k_set_instant_prompt
		_p9k_dump_instant_prompt
		_p9k_dumped_instant_prompt_sigs[$_p9k__instant_prompt_sig]=1
	fi
	_p9k_dump_state
	_p9k__state_dump_scheduled=0
	_p9k__state_dump_fd=0
}
_p9k_do_nothing () {
	true
}
_p9k_dump_instant_prompt () {
	local user=${(%):-%n}
	local root_dir=${__p9k_dump_file:h}
	local prompt_dir=${root_dir}/p10k-$user
	local root_file=$root_dir/p10k-instant-prompt-$user.zsh
	local prompt_file=$prompt_dir/prompt-${#_p9k__cwd}
	[[ -d $prompt_dir ]] || mkdir -p $prompt_dir || return
	[[ -w $root_dir && -w $prompt_dir ]] || return
	if [[ ! -e $root_file ]]
	then
		local tmp=$root_file.tmp.$$
		local -i fd
		sysopen -a -m 600 -o creat,trunc -u fd -- $tmp || return
		{
			[[ $TERM == (screen*|tmux*) ]] && local screen='-n'  || local screen='-z'
			local -a display_v=("${_p9k__display_v[@]}")
			local -i i
			for ((i = 6; i <= $#display_v; i+=2)) do
				display_v[i]=show
			done
			display_v[2]=hide
			display_v[4]=hide
			local gitstatus_dir=${${_POWERLEVEL9K_GITSTATUS_DIR:A}:-${__p9k_root_dir}/gitstatus}
			local gitstatus_header
			if [[ -r $gitstatus_dir/install.info ]]
			then
				IFS= read -r gitstatus_header < $gitstatus_dir/install.info || return
			fi
			print -r -- '[[ -t 0 && -t 1 && -t 2 && -o interactive && -o zle && -o no_xtrace ]] &&
  ! (( ${+__p9k_instant_prompt_disabled} || ZSH_SUBSHELL || ${+ZSH_SCRIPT} || ${+ZSH_EXECUTION_STRING} )) || return 0' >&$fd
			print -r -- "() {
  $__p9k_intro_no_locale
  typeset -gi __p9k_instant_prompt_disabled=1
  [[ \$ZSH_VERSION == ${(q)ZSH_VERSION} && \$ZSH_PATCHLEVEL == ${(q)ZSH_PATCHLEVEL} &&
     $screen \${(M)TERM:#(screen*|tmux*)} &&
     \${#\${(M)VTE_VERSION:#(<1-4602>|4801)}} == ${#${(M)VTE_VERSION:#(<1-4602>|4801)}} &&
     \$POWERLEVEL9K_DISABLE_INSTANT_PROMPT != 'true' &&
     \$POWERLEVEL9K_INSTANT_PROMPT != 'off' ]] || return
  typeset -g __p9k_instant_prompt_param_sig=${(q+)_p9k__param_sig}
  local gitstatus_dir=${(q)gitstatus_dir}
  local gitstatus_header=${(q)gitstatus_header}
  local -i ZLE_RPROMPT_INDENT=${ZLE_RPROMPT_INDENT:-1}
  local PROMPT_EOL_MARK=${(q)PROMPT_EOL_MARK-%B%S%#%s%b}
  [[ -n \$SSH_CLIENT || -n \$SSH_TTY || -n \$SSH_CONNECTION ]] && local ssh=1 || local ssh=0
  local cr=\$'\r' lf=\$'\n' esc=\$'\e[' rs=$'\x1e' us=$'\x1f'
  local -i height=${_POWERLEVEL9K_INSTANT_PROMPT_COMMAND_LINES-1}
  local prompt_dir=${(q)prompt_dir}" >&$fd
			if (( ! ${+_POWERLEVEL9K_INSTANT_PROMPT_COMMAND_LINES} ))
			then
				print -r -- '
  (( _z4h_can_save_restore_screen == 1 )) && height=0' >&$fd
			fi
			print -r -- '
  local real_gitstatus_header
  if [[ -r $gitstatus_dir/install.info ]]; then
    IFS= read -r real_gitstatus_header <$gitstatus_dir/install.info || real_gitstatus_header=borked
  fi
  [[ $real_gitstatus_header == $gitstatus_header ]] || return
  zmodload zsh/langinfo zsh/terminfo zsh/system || return
  if [[ $langinfo[CODESET] != (utf|UTF)(-|)8 ]]; then
    local loc_cmd=$commands[locale]
    [[ -z $loc_cmd ]] && loc_cmd='${(q)commands[locale]}'
    if [[ -x $loc_cmd ]]; then
      local -a locs
      if locs=(${(@M)$(locale -a 2>/dev/null):#*.(utf|UTF)(-|)8}) && (( $#locs )); then
        local loc=${locs[(r)(#i)C.UTF(-|)8]:-${locs[(r)(#i)en_US.UTF(-|)8]:-$locs[1]}}
        [[ -n $LC_ALL ]] && local LC_ALL=$loc || local LC_CTYPE=$loc
      fi
    fi
  fi
  (( terminfo[colors] == '${terminfo[colors]:-0}' )) || return
  (( $+terminfo[cuu] && $+terminfo[cuf] && $+terminfo[ed] && $+terminfo[sc] && $+terminfo[rc] )) || return
  local pwd=${(%):-%/}
  [[ $pwd == /* ]] || return
  local prompt_file=$prompt_dir/prompt-${#pwd}
  local key=$pwd:$ssh:${(%):-%#}
  local content
  if [[ ! -e $prompt_file ]]; then
    typeset -gi __p9k_instant_prompt_sourced='$__p9k_instant_prompt_version'
    return 1
  fi
  { content="$(<$prompt_file)" } 2>/dev/null || return
  local tail=${content##*$rs$key$us}
  if (( ${#tail} == ${#content} )); then
    typeset -gi __p9k_instant_prompt_sourced='$__p9k_instant_prompt_version'
    return 1
  fi
  local _p9k__ipe
  local P9K_PROMPT=instant
  if [[ -z $P9K_TTY || $P9K_TTY == old && -n ${_P9K_TTY:#$TTY} ]]; then' >&$fd
			if (( _POWERLEVEL9K_NEW_TTY_MAX_AGE_SECONDS < 0 ))
			then
				print -r -- '    typeset -gx P9K_TTY=new' >&$fd
			else
				print -r -- '
    typeset -gx P9K_TTY=old
    zmodload -F zsh/stat b:zstat || return
    zmodload zsh/datetime || return
    local -a stat
    if zstat -A stat +ctime -- $TTY 2>/dev/null &&
      (( EPOCHREALTIME - stat[1] < '$_POWERLEVEL9K_NEW_TTY_MAX_AGE_SECONDS' )); then
      P9K_TTY=new
    fi' >&$fd
			fi
			print -r -- '  fi
  typeset -gx _P9K_TTY=$TTY
  local -i _p9k__empty_line_i=3 _p9k__ruler_i=3
  local -A _p9k_display_k=('${(j: :)${(@q)${(kv)_p9k_display_k}}}')
  local -a _p9k__display_v=('${(j: :)${(@q)display_v}}')
  function p10k() {
    '$__p9k_intro'
    [[ $1 == display ]] || return
    shift
    local -i k dump
    local opt prev new pair list name var
    while getopts ":ha" opt; do
      case $opt in
        a) dump=1;;
        h) return 0;;
        ?) return 1;;
      esac
    done
    if (( dump )); then
      reply=()
      shift $((OPTIND-1))
      (( ARGC )) || set -- "*"
      for opt; do
        for k in ${(u@)_p9k_display_k[(I)$opt]:/(#m)*/$_p9k_display_k[$MATCH]}; do
          reply+=($_p9k__display_v[k,k+1])
        done
      done
      return 0
    fi
    for opt in "${@:$OPTIND}"; do
      pair=(${(s:=:)opt})
      list=(${(s:,:)${pair[2]}})
      if [[ ${(b)pair[1]} == $pair[1] ]]; then
        local ks=($_p9k_display_k[$pair[1]])
      else
        local ks=(${(u@)_p9k_display_k[(I)$pair[1]]:/(#m)*/$_p9k_display_k[$MATCH]})
      fi
      for k in $ks; do
        if (( $#list == 1 )); then
          [[ $_p9k__display_v[k+1] == $list[1] ]] && continue
          new=$list[1]
        else
          new=${list[list[(I)$_p9k__display_v[k+1]]+1]:-$list[1]}
          [[ $_p9k__display_v[k+1] == $new ]] && continue
        fi
        _p9k__display_v[k+1]=$new
        name=$_p9k__display_v[k]
        if [[ $name == (empty_line|ruler) ]]; then
          var=_p9k__${name}_i
          [[ $new == hide ]] && typeset -gi $var=3 || unset $var
        elif [[ $name == (#b)(<->)(*) ]]; then
          var=_p9k__${match[1]}${${${${match[2]//\/}/#left/l}/#right/r}/#gap/g}
          [[ $new == hide ]] && typeset -g $var= || unset $var
        fi
      done
    done
  }' >&$fd
			if (( _POWERLEVEL9K_PROMPT_ADD_NEWLINE ))
			then
				print -r -- '  [[ $P9K_TTY == old ]] && { unset _p9k__empty_line_i; _p9k__display_v[2]=print }' >&$fd
			fi
			if (( _POWERLEVEL9K_SHOW_RULER ))
			then
				print -r -- '[[ $P9K_TTY == old ]] && { unset _p9k__ruler_i; _p9k__display_v[4]=print }' >&$fd
			fi
			if (( $+functions[p10k-on-init] ))
			then
				print -r -- '
  p10k-on-init() { '$functions[p10k-on-init]' }' >&$fd
			fi
			if (( $+functions[p10k-on-pre-prompt] ))
			then
				print -r -- '
  p10k-on-pre-prompt() { '$functions[p10k-on-pre-prompt]' }' >&$fd
			fi
			if (( $+functions[p10k-on-post-prompt] ))
			then
				print -r -- '
  p10k-on-post-prompt() { '$functions[p10k-on-post-prompt]' }' >&$fd
			fi
			if (( $+functions[p10k-on-post-widget] ))
			then
				print -r -- '
  p10k-on-post-widget() { '$functions[p10k-on-post-widget]' }' >&$fd
			fi
			if (( $+functions[p10k-on-init] ))
			then
				print -r -- '
  p10k-on-init' >&$fd
			fi
			local pat idx var
			for pat idx var in $_p9k_show_on_command
			do
				print -r -- "
  local $var=
  _p9k__display_v[$idx]=hide" >&$fd
			done
			if (( $+functions[p10k-on-pre-prompt] ))
			then
				print -r -- '
  p10k-on-pre-prompt' >&$fd
			fi
			if (( $+functions[p10k-on-init] ))
			then
				print -r -- '
  unfunction p10k-on-init' >&$fd
			fi
			if (( $+functions[p10k-on-pre-prompt] ))
			then
				print -r -- '
  unfunction p10k-on-pre-prompt' >&$fd
			fi
			if (( $+functions[p10k-on-post-prompt] ))
			then
				print -r -- '
  unfunction p10k-on-post-prompt' >&$fd
			fi
			if (( $+functions[p10k-on-post-widget] ))
			then
				print -r -- '
  unfunction p10k-on-post-widget' >&$fd
			fi
			print -r -- '
  () {
'$functions[_p9k_init_toolbox]'
  }
  trap "unset -m _p9k__\*; unfunction p10k" EXIT
  local -a _p9k_t=("${(@ps:$us:)${tail%%$rs*}}")
  if [[ $+VTE_VERSION == 1 || $TERM_PROGRAM == Hyper ]] && (( $+commands[stty] )); then
    if [[ $TERM_PROGRAM == Hyper ]]; then
      local bad_lines=40 bad_columns=100
    else
      local bad_lines=24 bad_columns=80
    fi
    if (( LINES == bad_lines && COLUMNS == bad_columns )); then
      zmodload -F zsh/stat b:zstat || return
      zmodload zsh/datetime || return
      local -a tty_ctime
      if ! zstat -A tty_ctime +ctime -- $TTY 2>/dev/null || (( tty_ctime[1] + 2 > EPOCHREALTIME )); then
        local -F deadline=$((EPOCHREALTIME+0.025))
        local tty_size
        while true; do
          if (( EPOCHREALTIME > deadline )) || ! tty_size="$(command stty size 2>/dev/null)" || [[ $tty_size != <->" "<-> ]]; then
            (( $+_p9k__ruler_i )) || local -i _p9k__ruler_i=1
            local _p9k__g= _p9k__'$#_p9k_line_segments_right'r= _p9k__'$#_p9k_line_segments_right'r_frame=
            break
          fi
          if [[ $tty_size != "$bad_lines $bad_columns" ]]; then
            local lines_columns=(${=tty_size})
            local LINES=$lines_columns[1]
            local COLUMNS=$lines_columns[2]
            break
          fi
        done
      fi
    fi
  fi' >&$fd
			(( __p9k_ksh_arrays )) && print -r -- '  setopt ksh_arrays' >&$fd
			(( __p9k_sh_glob )) && print -r -- '  setopt sh_glob' >&$fd
			print -r -- '  typeset -ga __p9k_used_instant_prompt=("${(@e)_p9k_t[-3,-1]}")' >&$fd
			(( __p9k_ksh_arrays )) && print -r -- '  unsetopt ksh_arrays' >&$fd
			(( __p9k_sh_glob )) && print -r -- '  unsetopt sh_glob' >&$fd
			print -r -- '
  local -i prompt_height=${#${__p9k_used_instant_prompt[1]//[^$lf]}}
  (( height += prompt_height ))
  local _p9k__ret
  function _p9k_prompt_length() {
    local -i COLUMNS=1024
    local -i x y=${#1} m
    if (( y )); then
      while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
        x=y
        (( y *= 2 ))
      done
      while (( y > x + 1 )); do
        (( m = x + (y - x) / 2 ))
        (( ${${(%):-$1%$m(l.x.y)}[-1]} = m ))
      done
    fi
    typeset -g _p9k__ret=$x
  }
  local out=${(%):-%b%k%f%s%u}
  if [[ $P9K_TTY == old && ( $+VTE_VERSION == 0 && $TERM_PROGRAM != Hyper || $+_p9k__g == 0 ) ]]; then
    local mark=${(e)PROMPT_EOL_MARK}
    [[ $mark == "%B%S%#%s%b" ]] && _p9k__ret=1 || _p9k_prompt_length $mark
    local -i fill=$((COLUMNS > _p9k__ret ? COLUMNS - _p9k__ret : 0))
    out+="${(%):-$mark${(pl.$fill.. .)}$cr%b%k%f%s%u%E}"
  else
    out+="${(%):-$cr%E}"
  fi
  if (( _z4h_can_save_restore_screen != 1 )); then
    (( height )) && out+="${(pl.$height..$lf.)}$esc${height}A"
    out+="$terminfo[sc]"
  fi
  out+=${(%):-"$__p9k_used_instant_prompt[1]$__p9k_used_instant_prompt[2]"}
  if [[ -n $__p9k_used_instant_prompt[3] ]]; then
    _p9k_prompt_length "$__p9k_used_instant_prompt[2]"
    local -i left_len=_p9k__ret
    _p9k_prompt_length "$__p9k_used_instant_prompt[3]"
    if (( _p9k__ret )); then
      local -i gap=$((COLUMNS - left_len - _p9k__ret - ZLE_RPROMPT_INDENT))
      if (( gap >= 40 )); then
        out+="${(pl.$gap.. .)}${(%):-${__p9k_used_instant_prompt[3]}%b%k%f%s%u}$cr$esc${left_len}C"
      fi
    fi
  fi
  if (( _z4h_can_save_restore_screen == 1 )); then
    if (( height )); then
      out+="$cr${(pl:$((height-prompt_height))::\n:)}$esc${height}A$terminfo[sc]$out"
    else
      out+="$cr${(pl:$((height-prompt_height))::\n:)}$terminfo[sc]$out"
    fi
  fi
  if [[ -n "$TMPDIR" && ( ( -d "$TMPDIR" && -w "$TMPDIR" ) || ! ( -d /tmp && -w /tmp ) ) ]]; then
    local tmpdir=$TMPDIR
  else
    local tmpdir=/tmp
  fi
  typeset -g __p9k_instant_prompt_output=$tmpdir/p10k-instant-prompt-output-${(%):-%n}-$$
  { : > $__p9k_instant_prompt_output } || return
  print -rn -- "${out}${esc}?2004h" || return
  if (( $+commands[stty] )); then
    command stty -icanon 2>/dev/null
  fi
  local fd_null
  sysopen -ru fd_null /dev/null || return
  exec {__p9k_fd_0}<&0 {__p9k_fd_1}>&1 {__p9k_fd_2}>&2 0<&$fd_null 1>$__p9k_instant_prompt_output
  exec 2>&1 {fd_null}>&-
  typeset -gi __p9k_instant_prompt_active=1
  if (( _z4h_can_save_restore_screen == 1 )); then
    typeset -g _z4h_saved_screen
    -z4h-save-screen
  fi
  typeset -g __p9k_instant_prompt_dump_file=${XDG_CACHE_HOME:-~/.cache}/p10k-dump-${(%):-%n}.zsh
  if builtin source $__p9k_instant_prompt_dump_file 2>/dev/null && (( $+functions[_p9k_preinit] )); then
    _p9k_preinit
  fi
  function _p9k_instant_prompt_cleanup() {
    (( ZSH_SUBSHELL == 0 && ${+__p9k_instant_prompt_active} )) || return 0
    '$__p9k_intro_no_locale'
    unset __p9k_instant_prompt_active
    exec 0<&$__p9k_fd_0 1>&$__p9k_fd_1 2>&$__p9k_fd_2 {__p9k_fd_0}>&- {__p9k_fd_1}>&- {__p9k_fd_2}>&-
    unset __p9k_fd_0 __p9k_fd_1 __p9k_fd_2
    typeset -gi __p9k_instant_prompt_erased=1
    if (( _z4h_can_save_restore_screen == 1 && __p9k_instant_prompt_sourced >= 35 )); then
      -z4h-restore-screen
      unset _z4h_saved_screen
    fi
    print -rn -- $terminfo[rc]${(%):-%b%k%f%s%u}$terminfo[ed]
    if [[ -s $__p9k_instant_prompt_output ]]; then
      command cat $__p9k_instant_prompt_output 2>/dev/null
      if (( $1 )); then
        local _p9k__ret mark="${(e)${PROMPT_EOL_MARK-%B%S%#%s%b}}"
        _p9k_prompt_length $mark
        local -i fill=$((COLUMNS > _p9k__ret ? COLUMNS - _p9k__ret : 0))
        echo -nE - "${(%):-%b%k%f%s%u$mark${(pl.$fill.. .)}$cr%b%k%f%s%u%E}"
      fi
    fi
    zshexit_functions=(${zshexit_functions:#_p9k_instant_prompt_cleanup})
    zmodload -F zsh/files b:zf_rm || return
    local user=${(%):-%n}
    local root_dir=${__p9k_instant_prompt_dump_file:h}
    zf_rm -f -- $__p9k_instant_prompt_output $__p9k_instant_prompt_dump_file{,.zwc} $root_dir/p10k-instant-prompt-$user.zsh{,.zwc} $root_dir/p10k-$user/prompt-*(N) 2>/dev/null
  }
  function _p9k_instant_prompt_precmd_first() {
    '$__p9k_intro'
    function _p9k_instant_prompt_sched_last() {
      (( ${+__p9k_instant_prompt_active} )) || return 0
      _p9k_instant_prompt_cleanup 1
      setopt no_local_options prompt_cr prompt_sp
    }
    zmodload zsh/sched
    sched +0 _p9k_instant_prompt_sched_last
    precmd_functions=(${(@)precmd_functions:#_p9k_instant_prompt_precmd_first})
  }
  zshexit_functions=(_p9k_instant_prompt_cleanup $zshexit_functions)
  precmd_functions=(_p9k_instant_prompt_precmd_first $precmd_functions)
  DISABLE_UPDATE_PROMPT=true
} && unsetopt prompt_cr prompt_sp && typeset -gi __p9k_instant_prompt_sourced='$__p9k_instant_prompt_version' ||
  typeset -gi __p9k_instant_prompt_sourced=${__p9k_instant_prompt_sourced:-0}' >&$fd
		} always {
			exec {fd}>&-
		}
		{
			(( ! $? )) || return
			zf_rm -f -- $root_file.zwc || return
			zf_mv -f -- $tmp $root_file || return
			zcompile -R -- $tmp.zwc $root_file || return
			zf_mv -f -- $tmp.zwc $root_file.zwc || return
		} always {
			(( $? )) && zf_rm -f -- $tmp $tmp.zwc 2> /dev/null
		}
	fi
	local tmp=$prompt_file.tmp.$$
	zf_mv -f -- $prompt_file $tmp 2> /dev/null
	if [[ "$(<$tmp)" == *$'\x1e'$_p9k__instant_prompt_sig$'\x1f'* ]] 2> /dev/null
	then
		echo -n > $tmp || return
	fi
	local -i fd
	sysopen -a -m 600 -o creat -u fd -- $tmp || return
	{
		{
			print -rnu $fd -- $'\x1e'$_p9k__instant_prompt_sig$'\x1f'${(pj:\x1f:)_p9k_t}$'\x1f'$_p9k__instant_prompt || return
		} always {
			exec {fd}>&-
		}
		zf_mv -f -- $tmp $prompt_file || return
	} always {
		(( $? )) && zf_rm -f -- $tmp 2> /dev/null
	}
}
_p9k_dump_state () {
	local dir=${__p9k_dump_file:h}
	[[ -d $dir ]] || mkdir -p -- $dir || return
	[[ -w $dir ]] || return
	local tmp=$__p9k_dump_file.tmp.$$
	local -i fd
	sysopen -a -m 600 -o creat,trunc -u fd -- $tmp || return
	{
		{
			typeset -g __p9k_cached_param_pat=$_p9k__param_pat
			typeset -g __p9k_cached_param_sig=$_p9k__param_sig
			typeset -pm __p9k_cached_param_pat __p9k_cached_param_sig >&$fd || return
			unset __p9k_cached_param_pat __p9k_cached_param_sig
			(( $+_p9k_preinit )) && {
				print -r -- $_p9k_preinit >&$fd || return
			}
			print -r -- '_p9k_restore_state_impl() {' >&$fd || return
			typeset -pm '_POWERLEVEL9K_*|_p9k_[^_]*|icons' >&$fd || return
			print -r -- '}' >&$fd || return
		} always {
			exec {fd}>&-
		}
		zf_rm -f -- $__p9k_dump_file.zwc || return
		zf_mv -f -- $tmp $__p9k_dump_file || return
		zcompile -R -- $tmp.zwc $__p9k_dump_file || return
		zf_mv -f -- $tmp.zwc $__p9k_dump_file.zwc || return
	} always {
		(( $? )) && zf_rm -f -- $tmp $tmp.zwc 2> /dev/null
	}
}
_p9k_escape () {
	[[ $1 == *["~!#\`\$^&*()\\\"'<>?{}[]"]* ]] && _p9k__ret="\${(Q)\${:-${(qqq)${(q)1}}}}"  || _p9k__ret=$1
}
_p9k_escape_style () {
	[[ $1 == *'}'* ]] && _p9k__ret='${:-"'$1'"}'  || _p9k__ret=$1
}
_p9k_fetch_cwd () {
	if [[ $PWD == /* && $PWD -ef . ]]
	then
		_p9k__cwd=$PWD
	else
		_p9k__cwd=${${${:-.}:a}:-.}
	fi
	_p9k__cwd_a=${${_p9k__cwd:A}:-.}
	case $_p9k__cwd in
		(/ | .) _p9k__parent_dirs=()
			_p9k__parent_mtimes=()
			_p9k__parent_mtimes_i=()
			_p9k__parent_mtimes_s=
			return ;;
		(~ | ~/*) local parent=${${${:-~/..}:a}%/}/
			local parts=(${(s./.)_p9k__cwd#$parent})  ;;
		(*) local parent=/
			local parts=(${(s./.)_p9k__cwd})  ;;
	esac
	local MATCH
	_p9k__parent_dirs=(${(@)${:-{$#parts..1}}/(#m)*/$parent${(pj./.)parts[1,MATCH]}})
	if ! zstat -A _p9k__parent_mtimes +mtime -- $_p9k__parent_dirs 2> /dev/null
	then
		_p9k__parent_mtimes=(${(@)parts/*/-1})
	fi
	_p9k__parent_mtimes_i=(${(@)${:-{1..$#parts}}/(#m)*/$MATCH:$_p9k__parent_mtimes[MATCH]})
	_p9k__parent_mtimes_s="$_p9k__parent_mtimes_i"
}
_p9k_fetch_nordvpn_status () {
	setopt err_return no_multi_byte
	local REPLY
	zsocket /run/nordvpn/nordvpnd.sock
	local -i fd=REPLY
	{
		print -nu $fd 'PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n\0\0\0\4\1\0\0\0\0\0\0;\1\4\0\0\0\1\203\206E\213b\270\327\2762\322z\230\326j\246A\206\240\344\35\23\235\t_\213\35u\320b\r&=LMedz\212\232\312\310\264\307`+\262\332\340@\2te\206M\2035\5\261\37\0\0\5\0\1\0\0\0\1\0\0\0\0\0\0\0\25\1\4\0\0\0\3\203\206E\215b\270\327\2762\322z\230\334\221\246\324\177\302\301\300\277\0\0\5\0\1\0\0\0\3\0\0\0\0\0'
		local val
		local -i len n wire tag
		{
			IFS='' read -t 0.25 -r val
			val=$'\n'
			while true
			do
				tag=$((#val))
				wire='tag & 7'
				(( (tag >>= 3) && tag <= $#__p9k_nordvpn_tag )) || break
				if (( wire == 0 ))
				then
					sysread -s 1 -t 0.25 val
					n=$((#val))
					(( n < 128 )) || break
					if (( tag == 2 ))
					then
						case $n in
							(1) typeset -g P9K_NORDVPN_TECHNOLOGY=OPENVPN  ;;
							(2) typeset -g P9K_NORDVPN_TECHNOLOGY=NORDLYNX  ;;
							(3) typeset -g P9K_NORDVPN_TECHNOLOGY=SKYLARK  ;;
							(*) typeset -g P9K_NORDVPN_TECHNOLOGY=UNKNOWN  ;;
						esac
					elif (( tag == 3 ))
					then
						case $n in
							(1) typeset -g P9K_NORDVPN_PROTOCOL=UDP  ;;
							(2) typeset -g P9K_NORDVPN_PROTOCOL=TCP  ;;
							(*) typeset -g P9K_NORDVPN_PROTOCOL=UNKNOWN  ;;
						esac
					else
						break
					fi
				else
					(( wire == 2 )) || break
					(( tag != 2 && tag != 3 )) || break
					[[ -t $fd ]] || true
					sysread -s 1 -t 0.25 val
					len=$((#val))
					val=
					while (( $#val < len ))
					do
						[[ -t $fd ]] || true
						sysread -s $(( len - $#val )) -t 0.25 'val[$#val+1]'
					done
					typeset -g $__p9k_nordvpn_tag[tag]=$val
				fi
				[[ -t $fd ]] || true
				sysread -s 1 -t 0.25 val
			done
		} <&$fd
	} always {
		exec {fd}>&-
	}
}
_p9k_foreground () {
	[[ -n $1 ]] && _p9k__ret="%F{$1}"  || _p9k__ret="%f"
}
_p9k_fvm_new () {
	_p9k_upglob .fvm && return 1
	local sdk=$_p9k__parent_dirs[$?]/.fvm/flutter_sdk
	if [[ -L $sdk ]]
	then
		if [[ ${sdk:A} == (#b)*/versions/([^/]##) ]]
		then
			_p9k_prompt_segment prompt_fvm blue $_p9k_color1 FLUTTER_ICON 0 '' ${match[1]//\%/%%}
			return 0
		fi
	fi
	return 1
}
_p9k_fvm_old () {
	_p9k_upglob fvm && return 1
	local fvm=$_p9k__parent_dirs[$?]/fvm
	if [[ -L $fvm ]]
	then
		if [[ ${fvm:A} == (#b)*/versions/([^/]##)/bin/flutter ]]
		then
			_p9k_prompt_segment prompt_fvm blue $_p9k_color1 FLUTTER_ICON 0 '' ${match[1]//\%/%%}
			return 0
		fi
	fi
	return 1
}
_p9k_gcloud_prefetch () {
	unset P9K_GCLOUD_CONFIGURATION P9K_GCLOUD_ACCOUNT P9K_GCLOUD_PROJECT P9K_GCLOUD_PROJECT_ID P9K_GCLOUD_PROJECT_NAME
	(( $+commands[gcloud] )) || return
	_p9k_read_word ~/.config/gcloud/active_config || return
	P9K_GCLOUD_CONFIGURATION=$_p9k__ret
	if ! _p9k_cache_stat_get $0 ~/.config/gcloud/configurations/config_$P9K_GCLOUD_CONFIGURATION
	then
		local pair account project_id
		pair="$(gcloud config configurations describe $P9K_GCLOUD_CONFIGURATION \
      --format=$'value[separator="\1"](properties.core.account,properties.core.project)')"
		(( ! $? )) && IFS=$'\1' read account project_id <<< $pair
		_p9k_cache_stat_set "$account" "$project_id"
	fi
	if [[ -n $_p9k__cache_val[1] ]]
	then
		P9K_GCLOUD_ACCOUNT=$_p9k__cache_val[1]
	fi
	if [[ -n $_p9k__cache_val[2] ]]
	then
		P9K_GCLOUD_PROJECT_ID=$_p9k__cache_val[2]
		P9K_GCLOUD_PROJECT=$P9K_GCLOUD_PROJECT_ID
	fi
	if [[ $P9K_GCLOUD_CONFIGURATION == $_p9k_gcloud_configuration && $P9K_GCLOUD_ACCOUNT == $_p9k_gcloud_account && $P9K_GCLOUD_PROJECT_ID == $_p9k_gcloud_project_id ]]
	then
		[[ -n $_p9k_gcloud_project_name ]] && P9K_GCLOUD_PROJECT_NAME=$_p9k_gcloud_project_name
		if (( _POWERLEVEL9K_GCLOUD_REFRESH_PROJECT_NAME_SECONDS < 0 ||
          _p9k__gcloud_last_fetch_ts + _POWERLEVEL9K_GCLOUD_REFRESH_PROJECT_NAME_SECONDS > EPOCHREALTIME ))
		then
			return
		fi
	else
		_p9k_gcloud_configuration=$P9K_GCLOUD_CONFIGURATION
		_p9k_gcloud_account=$P9K_GCLOUD_ACCOUNT
		_p9k_gcloud_project_id=$P9K_GCLOUD_PROJECT_ID
		_p9k_gcloud_project_name=
		_p9k__state_dump_scheduled=1
	fi
	[[ -n $P9K_GCLOUD_CONFIGURATION && -n $P9K_GCLOUD_ACCOUNT && -n $P9K_GCLOUD_PROJECT_ID ]] || return
	_p9k__gcloud_last_fetch_ts=EPOCHREALTIME
	_p9k_worker_invoke gcloud "_p9k_prompt_gcloud_compute ${(q)commands[gcloud]} ${(q)P9K_GCLOUD_CONFIGURATION} ${(q)P9K_GCLOUD_ACCOUNT} ${(q)P9K_GCLOUD_PROJECT_ID}"
}
_p9k_get_icon () {
	local key="_p9k_get_icon ${(pj:\0:)*}"
	_p9k__ret=$_p9k_cache[$key]
	if [[ -n $_p9k__ret ]]
	then
		_p9k__ret[-1,-1]=''
	else
		if [[ $2 == $'\1'* ]]
		then
			_p9k__ret=${2[2,-1]}
		else
			_p9k_param "$1" "$2" ${icons[$2]-$'\1'$3}
			if [[ $_p9k__ret == $'\1'* ]]
			then
				_p9k__ret=${_p9k__ret[2,-1]}
			else
				_p9k__ret=${(g::)_p9k__ret}
				[[ $_p9k__ret != $'\b'? ]] || _p9k__ret="%{$_p9k__ret%}"
			fi
		fi
		_p9k_cache[$key]=${_p9k__ret}.
	fi
}
_p9k_glob () {
	local dir=$_p9k__parent_dirs[$1]
	local cached=$_p9k__glob_cache[$dir/$2]
	if [[ $cached == $_p9k__parent_mtimes[$1]:* ]]
	then
		return ${cached##*:}
	fi
	local -a stat
	zstat -A stat +mtime -- $dir 2> /dev/null || stat=(-1)
	local files=($dir/$~2(N:t))
	_p9k__glob_cache[$dir/$2]="$stat[1]:$#files"
	return $#files
}
_p9k_goenv_global_version () {
	_p9k_read_pyenv_like_version_file ${GOENV_ROOT:-$HOME/.goenv}/version go- || _p9k__ret=system
}
_p9k_haskell_stack_version () {
	if ! _p9k_cache_stat_get $0 $1 ${STACK_ROOT:-~/.stack}/{pantry/pantry.sqlite3,stack.sqlite3}
	then
		local v
		v="$(STACK_YAML=$1 stack \
      --silent                 \
      --no-install-ghc         \
      --skip-ghc-check         \
      --no-terminal            \
      --color=never            \
      --lock-file=read-only    \
      query compiler actual)"  || v=
		_p9k_cache_stat_set "$v"
	fi
	_p9k__ret=$_p9k__cache_val[1]
}
_p9k_human_readable_bytes () {
	typeset -F n=$1
	local suf
	for suf in $__p9k_byte_suffix
	do
		(( n < 1024 )) && break
		(( n /= 1024 ))
	done
	if (( n >= 100 ))
	then
		printf -v _p9k__ret '%.0f.' $n
	elif (( n >= 10 ))
	then
		printf -v _p9k__ret '%.1f' $n
	else
		printf -v _p9k__ret '%.2f' $n
	fi
	_p9k__ret=${${_p9k__ret%%0#}%.}$suf
}
_p9k_init () {
	_p9k_init_vars
	_p9k_restore_state || _p9k_init_cacheable
	typeset -g P9K_OS_ICON=$_p9k_os_icon
	local -a _p9k__async_segments_compute
	local -i i
	local elem
	_p9k__prompt_side=left
	_p9k__segment_index=1
	for i in {1..$#_p9k_line_segments_left}
	do
		for elem in ${${(@0)_p9k_line_segments_left[i]}%_joined}
		do
			local f_init=_p9k_prompt_${elem}_init
			(( $+functions[$f_init] )) && $f_init
			(( ++_p9k__segment_index ))
		done
	done
	_p9k__prompt_side=right
	_p9k__segment_index=1
	for i in {1..$#_p9k_line_segments_right}
	do
		for elem in ${${(@0)_p9k_line_segments_right[i]}%_joined}
		do
			local f_init=_p9k_prompt_${elem}_init
			(( $+functions[$f_init] )) && $f_init
			(( ++_p9k__segment_index ))
		done
	done
	if [[ -n $_POWERLEVEL9K_PUBLIC_IP_VPN_INTERFACE || -n $_POWERLEVEL9K_IP_INTERFACE || -n $_POWERLEVEL9K_VPN_IP_INTERFACE ]]
	then
		_p9k_prompt_net_iface_init
	fi
	if [[ -n $_p9k__async_segments_compute ]]
	then
		functions[_p9k_async_segments_compute]=${(pj:\n:)_p9k__async_segments_compute}
		_p9k_worker_start
	fi
	local k v
	for k v in ${(kv)_p9k_display_k}
	do
		[[ $k == -* ]] && continue
		_p9k__display_v[v]=$k
		_p9k__display_v[v+1]=show
	done
	_p9k__display_v[2]=hide
	_p9k__display_v[4]=hide
	if (( $+functions[iterm2_decorate_prompt] ))
	then
		_p9k__iterm2_decorate_prompt=$functions[iterm2_decorate_prompt]
		iterm2_decorate_prompt () {
			typeset -g ITERM2_PRECMD_PS1=$PROMPT
			typeset -g ITERM2_SHOULD_DECORATE_PROMPT=
		}
	fi
	if (( $+functions[iterm2_precmd] ))
	then
		_p9k__iterm2_precmd=$functions[iterm2_precmd]
		functions[iterm2_precmd]='local _p9k_status=$?; zle && return; () { return $_p9k_status; }; '$_p9k__iterm2_precmd
	fi
	if (( _POWERLEVEL9K_TERM_SHELL_INTEGRATION  &&
        ! $+_z4h_iterm_cmd                    &&
        ! $+functions[iterm2_decorate_prompt] &&
        ! $+functions[iterm2_precmd] ))
	then
		typeset -gi _p9k__iterm_cmd=0
	fi
	if _p9k_segment_in_use todo
	then
		if [[ -n ${_p9k__todo_command::=${commands[todo.sh]}} ]]
		then
			local todo_global=/etc/todo/config
		elif [[ -n ${_p9k__todo_command::=${commands[todo-txt]}} ]]
		then
			local todo_global=/etc/todo-txt/config
		fi
		if [[ -n $_p9k__todo_command ]]
		then
			_p9k__todo_file="$(exec -a $_p9k__todo_command ${commands[bash]:-:} 3>&1 &>/dev/null -c "
        [ -e \"\$TODOTXT_CFG_FILE\" ] || TODOTXT_CFG_FILE=\$HOME/.todo/config
        [ -e \"\$TODOTXT_CFG_FILE\" ] || TODOTXT_CFG_FILE=\$HOME/todo.cfg
        [ -e \"\$TODOTXT_CFG_FILE\" ] || TODOTXT_CFG_FILE=\$HOME/.todo.cfg
        [ -e \"\$TODOTXT_CFG_FILE\" ] || TODOTXT_CFG_FILE=\${XDG_CONFIG_HOME:-\$HOME/.config}/todo/config
        [ -e \"\$TODOTXT_CFG_FILE\" ] || TODOTXT_CFG_FILE=${(qqq)_p9k__todo_command:h}/todo.cfg
        [ -e \"\$TODOTXT_CFG_FILE\" ] || TODOTXT_CFG_FILE=\${TODOTXT_GLOBAL_CFG_FILE:-${(qqq)todo_global}}
        [ -r \"\$TODOTXT_CFG_FILE\" ] || exit
        source \"\$TODOTXT_CFG_FILE\"
        printf "%s" \"\$TODO_FILE\" >&3")"
		fi
	fi
	if _p9k_segment_in_use dir && [[ $_POWERLEVEL9K_SHORTEN_STRATEGY == truncate_with_package_name && $+commands[jq] == 0 ]]
	then
		print -rP -- '%F{yellow}WARNING!%f %BPOWERLEVEL9K_SHORTEN_STRATEGY=truncate_with_package_name%b requires %F{green}jq%f.'
		print -rP -- 'Either install %F{green}jq%f or change the value of %BPOWERLEVEL9K_SHORTEN_STRATEGY%b.'
	fi
	_p9k_init_vcs
	if (( _p9k__instant_prompt_disabled ))
	then
		(( _POWERLEVEL9K_DISABLE_INSTANT_PROMPT )) && unset __p9k_instant_prompt_erased
		_p9k_delete_instant_prompt
		_p9k_dumped_instant_prompt_sigs=()
	fi
	if (( $+__p9k_instant_prompt_sourced && __p9k_instant_prompt_sourced != __p9k_instant_prompt_version ))
	then
		_p9k_delete_instant_prompt
		_p9k_dumped_instant_prompt_sigs=()
	fi
	if (( $+__p9k_instant_prompt_erased ))
	then
		unset __p9k_instant_prompt_erased
		if [[ -w $TTY ]]
		then
			local tty=$TTY
		elif [[ -w /dev/tty ]]
		then
			local tty=/dev/tty
		else
			local tty=/dev/null
		fi
		{
			echo -E - "" >&2
			echo -E - "${(%):-[%1FERROR%f]: When using instant prompt, Powerlevel10k must be loaded before the first prompt.}" >&2
			echo -E - "" >&2
			echo -E - "${(%):-You can:}" >&2
			echo -E - "" >&2
			echo -E - "${(%):-  - %BRecommended%b: Change the way Powerlevel10k is loaded from %B$__p9k_zshrc_u%b.}" >&2
			if (( _p9k_term_has_href ))
			then
				echo - "${(%):-    See \e]8;;https://github.com/romkatv/powerlevel10k/blob/master/README.md#installation\ahttps://github.com/romkatv/powerlevel10k/blob/master/README.md#installation\e]8;;\a.}" >&2
			else
				echo - "${(%):-    See https://github.com/romkatv/powerlevel10k/blob/master/README.md#installation.}" >&2
			fi
			if (( $+zsh_defer_options ))
			then
				echo -E - "" >&2
				echo -E - "${(%):-    NOTE: Do not use %1Fzsh-defer%f to load %Upowerlevel10k.zsh-theme%u.}" >&2
			elif (( $+functions[zinit] ))
			then
				echo -E - "" >&2
				echo -E - "${(%):-    NOTE: If using %2Fzinit%f to load %3F'romkatv/powerlevel10k'%f, %Bdo not apply%b %1Fice wait%f.}" >&2
			elif (( $+functions[zplugin] ))
			then
				echo -E - "" >&2
				echo -E - "${(%):-    NOTE: If using %2Fzplugin%f to load %3F'romkatv/powerlevel10k'%f, %Bdo not apply%b %1Fice wait%f.}" >&2
			fi
			echo -E - "" >&2
			echo -E - "${(%):-    * You %Bwill not%b see this error message again.}" >&2
			echo -E - "${(%):-    * Zsh will start %Bquickly%b.}" >&2
			echo -E - "" >&2
			echo -E - "${(%):-  - Disable instant prompt either by running %Bp10k configure%b or by manually}" >&2
			echo -E - "${(%):-    defining the following parameter:}" >&2
			echo -E - "" >&2
			echo -E - "${(%):-      %3Ftypeset%f -g POWERLEVEL9K_INSTANT_PROMPT=off}" >&2
			echo -E - "" >&2
			echo -E - "${(%):-    * You %Bwill not%b see this error message again.}" >&2
			echo -E - "${(%):-    * Zsh will start %Bslowly%b.}" >&2
			echo -E - "" >&2
			echo -E - "${(%):-  - Do nothing.}" >&2
			echo -E - "" >&2
			echo -E - "${(%):-    * You %Bwill%b see this error message every time you start zsh.}" >&2
			echo -E - "${(%):-    * Zsh will start %Bslowly%b.}" >&2
			echo -E - "" >&2
		} 2>> $tty
	fi
}
_p9k_init_cacheable () {
	_p9k_init_icons
	_p9k_init_params
	_p9k_init_prompt
	_p9k_init_display
	if [[ $VTE_VERSION != (<1-4602>|4801) ]]
	then
		_p9k_term_has_href=1
	fi
	local elem func
	local -i i=0
	for i in {1..$#_p9k_line_segments_left}
	do
		for elem in ${${${(@0)_p9k_line_segments_left[i]}%_joined}//-/_}
		do
			local var=POWERLEVEL9K_${${(U)elem}//İ/I}_SHOW_ON_COMMAND
			(( $+parameters[$var] )) || continue
			_p9k_show_on_command+=($'(|*[/\0])('${(j.|.)${(P)var}}')' $((1+_p9k_display_k[$i/left/$elem])) _p9k__${i}l$elem)
		done
		for elem in ${${${(@0)_p9k_line_segments_right[i]}%_joined}//-/_}
		do
			local var=POWERLEVEL9K_${${(U)elem}//İ/I}_SHOW_ON_COMMAND
			(( $+parameters[$var] )) || continue
			local cmds=(${(P)var})
			_p9k_show_on_command+=($'(|*[/\0])('${(j.|.)${(P)var}}')' $((1+$_p9k_display_k[$i/right/$elem])) _p9k__${i}r$elem)
		done
	done
	if [[ $_POWERLEVEL9K_TRANSIENT_PROMPT != off ]]
	then
		local sep=$'\1'
		_p9k_transient_prompt='%b%k%s%u%(?'$sep
		_p9k_color prompt_prompt_char_OK_VIINS FOREGROUND 76
		_p9k_foreground $_p9k__ret
		_p9k_transient_prompt+=$_p9k__ret
		_p9k_transient_prompt+='${${P9K_CONTENT::="❯"}+}'
		_p9k_param prompt_prompt_char_OK_VIINS CONTENT_EXPANSION '${P9K_CONTENT}'
		_p9k_transient_prompt+='${:-"'$_p9k__ret'"}'
		_p9k_transient_prompt+=$sep
		_p9k_color prompt_prompt_char_ERROR_VIINS FOREGROUND 196
		_p9k_foreground $_p9k__ret
		_p9k_transient_prompt+=$_p9k__ret
		_p9k_transient_prompt+='${${P9K_CONTENT::="❯"}+}'
		_p9k_param prompt_prompt_char_ERROR_VIINS CONTENT_EXPANSION '${P9K_CONTENT}'
		_p9k_transient_prompt+='${:-"'$_p9k__ret'"}'
		_p9k_transient_prompt+=')%b%k%f%s%u '
		if (( _POWERLEVEL9K_TERM_SHELL_INTEGRATION ))
		then
			_p9k_transient_prompt=$'%{\e]133;A\a%}'$_p9k_transient_prompt$'%{\e]133;B\a%}'
			if (( $+_z4h_iterm_cmd && _z4h_can_save_restore_screen == 1 ))
			then
				_p9k_transient_prompt=$'%{\ePtmux;\e\e]133;A\a\e\\%}'$_p9k_transient_prompt$'%{\ePtmux;\e\e]133;B\a\e\\%}'
			fi
		fi
	fi
	_p9k_uname="$(uname)"
	[[ $_p9k_uname == Linux ]] && _p9k_uname_o="$(uname -o 2>/dev/null)"
	_p9k_uname_m="$(uname -m)"
	if [[ $_p9k_uname == Linux && $_p9k_uname_o == Android ]]
	then
		_p9k_set_os Android ANDROID_ICON
	else
		case $_p9k_uname in
			(SunOS) _p9k_set_os Solaris SUNOS_ICON ;;
			(Darwin) _p9k_set_os OSX APPLE_ICON ;;
			(CYGWIN* | MSYS* | MINGW*) _p9k_set_os Windows WINDOWS_ICON ;;
			(FreeBSD | OpenBSD | DragonFly) _p9k_set_os BSD FREEBSD_ICON ;;
			(Linux) _p9k_os='Linux'
				local os_release_id
				if [[ -r /etc/os-release ]]
				then
					local lines=(${(f)"$(</etc/os-release)"})
					lines=(${(@M)lines:#ID=*})
					(( $#lines == 1 )) && os_release_id=${lines[1]#ID=}
				elif [[ -e /etc/artix-release ]]
				then
					os_release_id=artix
				fi
				case $os_release_id in
					(*arch*) _p9k_set_os Linux LINUX_ARCH_ICON ;;
					(*debian*) _p9k_set_os Linux LINUX_DEBIAN_ICON ;;
					(*raspbian*) _p9k_set_os Linux LINUX_RASPBIAN_ICON ;;
					(*ubuntu*) _p9k_set_os Linux LINUX_UBUNTU_ICON ;;
					(*elementary*) _p9k_set_os Linux LINUX_ELEMENTARY_ICON ;;
					(*fedora*) _p9k_set_os Linux LINUX_FEDORA_ICON ;;
					(*coreos*) _p9k_set_os Linux LINUX_COREOS_ICON ;;
					(*gentoo*) _p9k_set_os Linux LINUX_GENTOO_ICON ;;
					(*mageia*) _p9k_set_os Linux LINUX_MAGEIA_ICON ;;
					(*centos*) _p9k_set_os Linux LINUX_CENTOS_ICON ;;
					(*opensuse* | *tumbleweed*) _p9k_set_os Linux LINUX_OPENSUSE_ICON ;;
					(*sabayon*) _p9k_set_os Linux LINUX_SABAYON_ICON ;;
					(*slackware*) _p9k_set_os Linux LINUX_SLACKWARE_ICON ;;
					(*linuxmint*) _p9k_set_os Linux LINUX_MINT_ICON ;;
					(*alpine*) _p9k_set_os Linux LINUX_ALPINE_ICON ;;
					(*aosc*) _p9k_set_os Linux LINUX_AOSC_ICON ;;
					(*nixos*) _p9k_set_os Linux LINUX_NIXOS_ICON ;;
					(*devuan*) _p9k_set_os Linux LINUX_DEVUAN_ICON ;;
					(*manjaro*) _p9k_set_os Linux LINUX_MANJARO_ICON ;;
					(*void*) _p9k_set_os Linux LINUX_VOID_ICON ;;
					(*artix*) _p9k_set_os Linux LINUX_ARTIX_ICON ;;
					(*rhel*) _p9k_set_os Linux LINUX_RHEL_ICON ;;
					(amzn) _p9k_set_os Linux LINUX_AMZN_ICON ;;
					(*) _p9k_set_os Linux LINUX_ICON ;;
				esac ;;
		esac
	fi
	if [[ $_POWERLEVEL9K_COLOR_SCHEME == light ]]
	then
		_p9k_color1=7
		_p9k_color2=0
	else
		_p9k_color1=0
		_p9k_color2=7
	fi
	_p9k_battery_states=('LOW' 'red' 'CHARGING' 'yellow' 'CHARGED' 'green' 'DISCONNECTED' "$_p9k_color2")
	local -a left_segments=(${(@0)${(pj:\0:)_p9k_line_segments_left}})
	_p9k_left_join=(1)
	for ((i = 2; i <= $#left_segments; ++i)) do
		elem=$left_segments[i]
		if [[ $elem == *_joined ]]
		then
			_p9k_left_join+=$_p9k_left_join[((i-1))]
		else
			_p9k_left_join+=$i
		fi
	done
	local -a right_segments=(${(@0)${(pj:\0:)_p9k_line_segments_right}})
	_p9k_right_join=(1)
	for ((i = 2; i <= $#right_segments; ++i)) do
		elem=$right_segments[i]
		if [[ $elem == *_joined ]]
		then
			_p9k_right_join+=$_p9k_right_join[((i-1))]
		else
			_p9k_right_join+=$i
		fi
	done
	case $_p9k_os in
		(OSX) (( $+commands[sysctl] )) && _p9k_num_cpus="$(sysctl -n hw.logicalcpu 2>/dev/null)"  ;;
		(BSD) (( $+commands[sysctl] )) && _p9k_num_cpus="$(sysctl -n hw.ncpu 2>/dev/null)"  ;;
		(*) (( $+commands[nproc]  )) && _p9k_num_cpus="$(nproc 2>/dev/null)"  ;;
	esac
	(( _p9k_num_cpus )) || _p9k_num_cpus=1
	if _p9k_segment_in_use dir
	then
		if (( $+_POWERLEVEL9K_DIR_CLASSES ))
		then
			local -i i=3
			for ((; i <= $#_POWERLEVEL9K_DIR_CLASSES; i+=3)) do
				_POWERLEVEL9K_DIR_CLASSES[i]=${(g::)_POWERLEVEL9K_DIR_CLASSES[i]}
			done
		else
			typeset -ga _POWERLEVEL9K_DIR_CLASSES=()
			_p9k_get_icon prompt_dir_ETC ETC_ICON
			_POWERLEVEL9K_DIR_CLASSES+=('/etc|/etc/*' ETC "$_p9k__ret")
			_p9k_get_icon prompt_dir_HOME HOME_ICON
			_POWERLEVEL9K_DIR_CLASSES+=('~' HOME "$_p9k__ret")
			_p9k_get_icon prompt_dir_HOME_SUBFOLDER HOME_SUB_ICON
			_POWERLEVEL9K_DIR_CLASSES+=('~/*' HOME_SUBFOLDER "$_p9k__ret")
			_p9k_get_icon prompt_dir_DEFAULT FOLDER_ICON
			_POWERLEVEL9K_DIR_CLASSES+=('*' DEFAULT "$_p9k__ret")
		fi
	fi
	if _p9k_segment_in_use status
	then
		typeset -g _p9k_exitcode2str=({0..255})
		local -i i=2
		if (( !_POWERLEVEL9K_STATUS_HIDE_SIGNAME ))
		then
			for ((; i <= $#signals; ++i)) do
				local sig=$signals[i]
				(( _POWERLEVEL9K_STATUS_VERBOSE_SIGNAME )) && sig="SIG${sig}($((i-1)))"
				_p9k_exitcode2str[$((128+i))]=$sig
			done
		fi
	fi
	if [[ $#_POWERLEVEL9K_VCS_BACKENDS == 1 && $_POWERLEVEL9K_VCS_BACKENDS[1] == git ]]
	then
		local elem line
		local -i i=0 line_idx=0
		for line in $_p9k_line_segments_left
		do
			(( ++line_idx ))
			for elem in ${${(0)line}%_joined}
			do
				(( ++i ))
				if [[ $elem == vcs ]]
				then
					if (( _p9k_vcs_index ))
					then
						_p9k_vcs_index=-1
					else
						_p9k_vcs_index=i
						_p9k_vcs_line_index=line_idx
						_p9k_vcs_side=left
					fi
				fi
			done
		done
		i=0
		line_idx=0
		for line in $_p9k_line_segments_right
		do
			(( ++line_idx ))
			for elem in ${${(0)line}%_joined}
			do
				(( ++i ))
				if [[ $elem == vcs ]]
				then
					if (( _p9k_vcs_index ))
					then
						_p9k_vcs_index=-1
					else
						_p9k_vcs_index=i
						_p9k_vcs_line_index=line_idx
						_p9k_vcs_side=right
					fi
				fi
			done
		done
		if (( _p9k_vcs_index > 0 ))
		then
			local state
			for state in ${(k)__p9k_vcs_states}
			do
				_p9k_param prompt_vcs_$state CONTENT_EXPANSION x
				if [[ -z $_p9k__ret ]]
				then
					_p9k_vcs_index=-1
					break
				fi
			done
		fi
		if (( _p9k_vcs_index == -1 ))
		then
			_p9k_vcs_index=0
			_p9k_vcs_line_index=0
			_p9k_vcs_side=
		fi
	fi
}
_p9k_init_display () {
	_p9k_display_k=(empty_line 1 ruler 3)
	local -i n=3 i
	local name
	for i in {1..$#_p9k_line_segments_left}
	do
		local -i j=$((-$#_p9k_line_segments_left+i-1))
		_p9k_display_k+=($i $((n+=2)) $j $n $i/left_frame $((n+=2)) $j/left_frame $n $i/right_frame $((n+=2)) $j/right_frame $n $i/left $((n+=2)) $j/left $n $i/right $((n+=2)) $j/right $n $i/gap $((n+=2)) $j/gap $n)
		for name in ${${(@0)_p9k_line_segments_left[i]}%_joined}
		do
			_p9k_display_k+=($i/left/$name $((n+=2)) $j/left/$name $n)
		done
		for name in ${${(@0)_p9k_line_segments_right[i]}%_joined}
		do
			_p9k_display_k+=($i/right/$name $((n+=2)) $j/right/$name $n)
		done
	done
}
_p9k_init_icons () {
	[[ -n ${POWERLEVEL9K_MODE-} || ${langinfo[CODESET]} == (utf|UTF)(-|)8 ]] || local POWERLEVEL9K_MODE=ascii
	[[ $_p9k__icon_mode == $POWERLEVEL9K_MODE/$POWERLEVEL9K_LEGACY_ICON_SPACING/$POWERLEVEL9K_ICON_PADDING ]] && return
	typeset -g _p9k__icon_mode=$POWERLEVEL9K_MODE/$POWERLEVEL9K_LEGACY_ICON_SPACING/$POWERLEVEL9K_ICON_PADDING
	if [[ $POWERLEVEL9K_LEGACY_ICON_SPACING == true ]]
	then
		local s=
		local q=' '
	else
		local s=' '
		local q=
	fi
	case $POWERLEVEL9K_MODE in
		('flat' | 'awesome-patched') icons=(RULER_CHAR '\u2500' LEFT_SEGMENT_SEPARATOR '\uE0B0' RIGHT_SEGMENT_SEPARATOR '\uE0B2' LEFT_SEGMENT_END_SEPARATOR ' ' LEFT_SUBSEGMENT_SEPARATOR '\uE0B1' RIGHT_SUBSEGMENT_SEPARATOR '\uE0B3' CARRIAGE_RETURN_ICON '\u21B5'$s ROOT_ICON '\uE801' SUDO_ICON '\uE0A2' RUBY_ICON '\uE847 ' AWS_ICON '\uE895'$s AWS_EB_ICON '\U1F331'$q BACKGROUND_JOBS_ICON '\uE82F ' TEST_ICON '\uE891'$s TODO_ICON '\u2611' BATTERY_ICON '\uE894'$s DISK_ICON '\uE1AE ' OK_ICON '\u2714' FAIL_ICON '\u2718' SYMFONY_ICON 'SF' NODE_ICON '\u2B22'$s NODEJS_ICON '\u2B22'$s MULTILINE_FIRST_PROMPT_PREFIX '\u256D\U2500' MULTILINE_NEWLINE_PROMPT_PREFIX '\u251C\U2500' MULTILINE_LAST_PROMPT_PREFIX '\u2570\U2500 ' APPLE_ICON '\uE26E'$s WINDOWS_ICON '\uE26F'$s FREEBSD_ICON '\U1F608'$q ANDROID_ICON '\uE270'$s LINUX_ICON '\uE271'$s LINUX_ARCH_ICON '\uE271'$s LINUX_DEBIAN_ICON '\uE271'$s LINUX_RASPBIAN_ICON '\uE271'$s LINUX_UBUNTU_ICON '\uE271'$s LINUX_CENTOS_ICON '\uE271'$s LINUX_COREOS_ICON '\uE271'$s LINUX_ELEMENTARY_ICON '\uE271'$s LINUX_MINT_ICON '\uE271'$s LINUX_FEDORA_ICON '\uE271'$s LINUX_GENTOO_ICON '\uE271'$s LINUX_MAGEIA_ICON '\uE271'$s LINUX_NIXOS_ICON '\uE271'$s LINUX_MANJARO_ICON '\uE271'$s LINUX_DEVUAN_ICON '\uE271'$s LINUX_ALPINE_ICON '\uE271'$s LINUX_AOSC_ICON '\uE271'$s LINUX_OPENSUSE_ICON '\uE271'$s LINUX_SABAYON_ICON '\uE271'$s LINUX_SLACKWARE_ICON '\uE271'$s LINUX_VOID_ICON '\uE271'$s LINUX_ARTIX_ICON '\uE271'$s LINUX_RHEL_ICON '\uE271'$s LINUX_AMZN_ICON '\uE271'$s SUNOS_ICON '\U1F31E'$q HOME_ICON '\uE12C'$s HOME_SUB_ICON '\uE18D'$s FOLDER_ICON '\uE818'$s NETWORK_ICON '\uE1AD'$s ETC_ICON '\uE82F'$s LOAD_ICON '\uE190 ' SWAP_ICON '\uE87D'$s RAM_ICON '\uE1E2 ' SERVER_ICON '\uE895'$s VCS_UNTRACKED_ICON '\uE16C'$s VCS_UNSTAGED_ICON '\uE17C'$s VCS_STAGED_ICON '\uE168'$s VCS_STASH_ICON '\uE133 ' VCS_INCOMING_CHANGES_ICON '\uE131 ' VCS_OUTGOING_CHANGES_ICON '\uE132 ' VCS_TAG_ICON '\uE817 ' VCS_BOOKMARK_ICON '\uE87B' VCS_COMMIT_ICON '\uE821 ' VCS_BRANCH_ICON '\uE220 ' VCS_REMOTE_BRANCH_ICON '\u2192' VCS_LOADING_ICON '' VCS_GIT_ICON '\uE20E ' VCS_GIT_GITHUB_ICON '\uE20E ' VCS_GIT_BITBUCKET_ICON '\uE20E ' VCS_GIT_GITLAB_ICON '\uE20E ' VCS_HG_ICON '\uE1C3 ' VCS_SVN_ICON 'svn'$q RUST_ICON 'R' PYTHON_ICON '\uE63C'$s SWIFT_ICON 'Swift' GO_ICON 'Go' GOLANG_ICON 'Go' PUBLIC_IP_ICON 'IP' LOCK_ICON '\UE138' NORDVPN_ICON '\UE138' EXECUTION_TIME_ICON '\UE89C'$s SSH_ICON 'ssh' VPN_ICON '\UE138' KUBERNETES_ICON '\U2388'$s DROPBOX_ICON '\UF16B'$s DATE_ICON '\uE184'$s TIME_ICON '\uE12E'$s JAVA_ICON '\U2615' LARAVEL_ICON '' RANGER_ICON '\u2B50' MIDNIGHT_COMMANDER_ICON 'mc' VIM_ICON 'vim' TERRAFORM_ICON 'tf' PROXY_ICON '\u2194' DOTNET_ICON '.NET' DOTNET_CORE_ICON '.NET' AZURE_ICON '\u2601' DIRENV_ICON '\u25BC' FLUTTER_ICON 'F' GCLOUD_ICON 'G' LUA_ICON 'lua' PERL_ICON 'perl' NNN_ICON 'nnn' XPLR_ICON 'xplr' TIMEWARRIOR_ICON 'tw' TASKWARRIOR_ICON 'task' NIX_SHELL_ICON 'nix' WIFI_ICON 'WiFi' ERLANG_ICON 'erl' ELIXIR_ICON 'elixir' POSTGRES_ICON 'postgres' PHP_ICON 'php' HASKELL_ICON 'hs' PACKAGE_ICON 'pkg' JULIA_ICON 'jl' SCALA_ICON 'scala' TOOLBOX_ICON '\u2B22')  ;;
		('awesome-fontconfig') icons=(RULER_CHAR '\u2500' LEFT_SEGMENT_SEPARATOR '\uE0B0' RIGHT_SEGMENT_SEPARATOR '\uE0B2' LEFT_SEGMENT_END_SEPARATOR ' ' LEFT_SUBSEGMENT_SEPARATOR '\uE0B1' RIGHT_SUBSEGMENT_SEPARATOR '\uE0B3' CARRIAGE_RETURN_ICON '\u21B5' ROOT_ICON '\uF201'$s SUDO_ICON '\uF09C'$s RUBY_ICON '\uF219 ' AWS_ICON '\uF270'$s AWS_EB_ICON '\U1F331'$q BACKGROUND_JOBS_ICON '\uF013 ' TEST_ICON '\uF291'$s TODO_ICON '\u2611' BATTERY_ICON '\U1F50B' DISK_ICON '\uF0A0 ' OK_ICON '\u2714' FAIL_ICON '\u2718' SYMFONY_ICON 'SF' NODE_ICON '\u2B22' NODEJS_ICON '\u2B22' MULTILINE_FIRST_PROMPT_PREFIX '\u256D\U2500' MULTILINE_NEWLINE_PROMPT_PREFIX '\u251C\U2500' MULTILINE_LAST_PROMPT_PREFIX '\u2570\U2500 ' APPLE_ICON '\uF179'$s WINDOWS_ICON '\uF17A'$s FREEBSD_ICON '\U1F608'$q ANDROID_ICON '\uE17B'$s LINUX_ICON '\uF17C'$s LINUX_ARCH_ICON '\uF17C'$s LINUX_DEBIAN_ICON '\uF17C'$s LINUX_RASPBIAN_ICON '\uF17C'$s LINUX_UBUNTU_ICON '\uF17C'$s LINUX_CENTOS_ICON '\uF17C'$s LINUX_COREOS_ICON '\uF17C'$s LINUX_ELEMENTARY_ICON '\uF17C'$s LINUX_MINT_ICON '\uF17C'$s LINUX_FEDORA_ICON '\uF17C'$s LINUX_GENTOO_ICON '\uF17C'$s LINUX_MAGEIA_ICON '\uF17C'$s LINUX_NIXOS_ICON '\uF17C'$s LINUX_MANJARO_ICON '\uF17C'$s LINUX_DEVUAN_ICON '\uF17C'$s LINUX_ALPINE_ICON '\uF17C'$s LINUX_AOSC_ICON '\uF17C'$s LINUX_OPENSUSE_ICON '\uF17C'$s LINUX_SABAYON_ICON '\uF17C'$s LINUX_SLACKWARE_ICON '\uF17C'$s LINUX_VOID_ICON '\uF17C'$s LINUX_ARTIX_ICON '\uF17C'$s LINUX_RHEL_ICON '\uF17C'$s LINUX_AMZN_ICON '\uF17C'$s SUNOS_ICON '\uF185 ' HOME_ICON '\uF015'$s HOME_SUB_ICON '\uF07C'$s FOLDER_ICON '\uF115'$s ETC_ICON '\uF013 ' NETWORK_ICON '\uF09E'$s LOAD_ICON '\uF080 ' SWAP_ICON '\uF0E4'$s RAM_ICON '\uF0E4'$s SERVER_ICON '\uF233'$s VCS_UNTRACKED_ICON '\uF059'$s VCS_UNSTAGED_ICON '\uF06A'$s VCS_STAGED_ICON '\uF055'$s VCS_STASH_ICON '\uF01C ' VCS_INCOMING_CHANGES_ICON '\uF01A ' VCS_OUTGOING_CHANGES_ICON '\uF01B ' VCS_TAG_ICON '\uF217 ' VCS_BOOKMARK_ICON '\uF27B ' VCS_COMMIT_ICON '\uF221 ' VCS_BRANCH_ICON '\uF126 ' VCS_REMOTE_BRANCH_ICON '\u2192' VCS_LOADING_ICON '' VCS_GIT_ICON '\uF1D3 ' VCS_GIT_GITHUB_ICON '\uF113 ' VCS_GIT_BITBUCKET_ICON '\uF171 ' VCS_GIT_GITLAB_ICON '\uF296 ' VCS_HG_ICON '\uF0C3 ' VCS_SVN_ICON 'svn'$q RUST_ICON '\uE6A8' PYTHON_ICON '\uE63C'$s SWIFT_ICON 'Swift' GO_ICON 'Go' GOLANG_ICON 'Go' PUBLIC_IP_ICON 'IP' LOCK_ICON '\UF023' NORDVPN_ICON '\UF023' EXECUTION_TIME_ICON '\uF253'$s SSH_ICON 'ssh' VPN_ICON '\uF023' KUBERNETES_ICON '\U2388' DROPBOX_ICON '\UF16B'$s DATE_ICON '\uF073 ' TIME_ICON '\uF017 ' JAVA_ICON '\U2615' LARAVEL_ICON '' RANGER_ICON '\u2B50' MIDNIGHT_COMMANDER_ICON 'mc' VIM_ICON 'vim' TERRAFORM_ICON 'tf' PROXY_ICON '\u2194' DOTNET_ICON '.NET' DOTNET_CORE_ICON '.NET' AZURE_ICON '\u2601' DIRENV_ICON '\u25BC' FLUTTER_ICON 'F' GCLOUD_ICON 'G' LUA_ICON 'lua' PERL_ICON 'perl' NNN_ICON 'nnn' XPLR_ICON 'xplr' TIMEWARRIOR_ICON 'tw' TASKWARRIOR_ICON 'task' NIX_SHELL_ICON 'nix' WIFI_ICON 'WiFi' ERLANG_ICON 'erl' ELIXIR_ICON 'elixir' POSTGRES_ICON 'postgres' PHP_ICON 'php' HASKELL_ICON 'hs' PACKAGE_ICON 'pkg' JULIA_ICON 'jl' SCALA_ICON 'scala' TOOLBOX_ICON '\u2B22')  ;;
		('awesome-mapped-fontconfig') if [ -z "$AWESOME_GLYPHS_LOADED" ]
			then
				echo "Powerlevel9k warning: Awesome-Font mappings have not been loaded.
          Source a font mapping in your shell config, per the Awesome-Font docs
          (https://github.com/gabrielelana/awesome-terminal-fonts),
          Or use a different Powerlevel9k font configuration."
			fi
			icons=(RULER_CHAR '\u2500' LEFT_SEGMENT_SEPARATOR '\uE0B0' RIGHT_SEGMENT_SEPARATOR '\uE0B2' LEFT_SEGMENT_END_SEPARATOR ' ' LEFT_SUBSEGMENT_SEPARATOR '\uE0B1' RIGHT_SUBSEGMENT_SEPARATOR '\uE0B3' CARRIAGE_RETURN_ICON '\u21B5' ROOT_ICON "${CODEPOINT_OF_OCTICONS_ZAP:+\\u$CODEPOINT_OF_OCTICONS_ZAP}" SUDO_ICON "${CODEPOINT_OF_AWESOME_UNLOCK:+\\u$CODEPOINT_OF_AWESOME_UNLOCK$s}" RUBY_ICON "${CODEPOINT_OF_OCTICONS_RUBY:+\\u$CODEPOINT_OF_OCTICONS_RUBY }" AWS_ICON "${CODEPOINT_OF_AWESOME_SERVER:+\\u$CODEPOINT_OF_AWESOME_SERVER$s}" AWS_EB_ICON '\U1F331'$q BACKGROUND_JOBS_ICON "${CODEPOINT_OF_AWESOME_COG:+\\u$CODEPOINT_OF_AWESOME_COG }" TEST_ICON "${CODEPOINT_OF_AWESOME_BUG:+\\u$CODEPOINT_OF_AWESOME_BUG$s}" TODO_ICON "${CODEPOINT_OF_AWESOME_CHECK_SQUARE_O:+\\u$CODEPOINT_OF_AWESOME_CHECK_SQUARE_O$s}" BATTERY_ICON "${CODEPOINT_OF_AWESOME_BATTERY_FULL:+\\U$CODEPOINT_OF_AWESOME_BATTERY_FULL$s}" DISK_ICON "${CODEPOINT_OF_AWESOME_HDD_O:+\\u$CODEPOINT_OF_AWESOME_HDD_O }" OK_ICON "${CODEPOINT_OF_AWESOME_CHECK:+\\u$CODEPOINT_OF_AWESOME_CHECK$s}" FAIL_ICON "${CODEPOINT_OF_AWESOME_TIMES:+\\u$CODEPOINT_OF_AWESOME_TIMES}" SYMFONY_ICON 'SF' NODE_ICON '\u2B22' NODEJS_ICON '\u2B22' MULTILINE_FIRST_PROMPT_PREFIX '\u256D\U2500' MULTILINE_NEWLINE_PROMPT_PREFIX '\u251C\U2500' MULTILINE_LAST_PROMPT_PREFIX '\u2570\U2500 ' APPLE_ICON "${CODEPOINT_OF_AWESOME_APPLE:+\\u$CODEPOINT_OF_AWESOME_APPLE$s}" FREEBSD_ICON '\U1F608'$q LINUX_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_ARCH_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_DEBIAN_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_RASPBIAN_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_UBUNTU_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_CENTOS_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_COREOS_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_ELEMENTARY_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_MINT_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_FEDORA_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_GENTOO_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_MAGEIA_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_NIXOS_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_MANJARO_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_DEVUAN_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_ALPINE_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_AOSC_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_OPENSUSE_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_SABAYON_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_SLACKWARE_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_VOID_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_ARTIX_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_RHEL_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" LINUX_AMZN_ICON "${CODEPOINT_OF_AWESOME_LINUX:+\\u$CODEPOINT_OF_AWESOME_LINUX$s}" SUNOS_ICON "${CODEPOINT_OF_AWESOME_SUN_O:+\\u$CODEPOINT_OF_AWESOME_SUN_O }" HOME_ICON "${CODEPOINT_OF_AWESOME_HOME:+\\u$CODEPOINT_OF_AWESOME_HOME$s}" HOME_SUB_ICON "${CODEPOINT_OF_AWESOME_FOLDER_OPEN:+\\u$CODEPOINT_OF_AWESOME_FOLDER_OPEN$s}" FOLDER_ICON "${CODEPOINT_OF_AWESOME_FOLDER_O:+\\u$CODEPOINT_OF_AWESOME_FOLDER_O$s}" ETC_ICON "${CODEPOINT_OF_AWESOME_COG:+\\u$CODEPOINT_OF_AWESOME_COG }" NETWORK_ICON "${CODEPOINT_OF_AWESOME_RSS:+\\u$CODEPOINT_OF_AWESOME_RSS$s}" LOAD_ICON "${CODEPOINT_OF_AWESOME_BAR_CHART:+\\u$CODEPOINT_OF_AWESOME_BAR_CHART }" SWAP_ICON "${CODEPOINT_OF_AWESOME_DASHBOARD:+\\u$CODEPOINT_OF_AWESOME_DASHBOARD$s}" RAM_ICON "${CODEPOINT_OF_AWESOME_DASHBOARD:+\\u$CODEPOINT_OF_AWESOME_DASHBOARD$s}" SERVER_ICON "${CODEPOINT_OF_AWESOME_SERVER:+\\u$CODEPOINT_OF_AWESOME_SERVER$s}" VCS_UNTRACKED_ICON "${CODEPOINT_OF_AWESOME_QUESTION_CIRCLE:+\\u$CODEPOINT_OF_AWESOME_QUESTION_CIRCLE$s}" VCS_UNSTAGED_ICON "${CODEPOINT_OF_AWESOME_EXCLAMATION_CIRCLE:+\\u$CODEPOINT_OF_AWESOME_EXCLAMATION_CIRCLE$s}" VCS_STAGED_ICON "${CODEPOINT_OF_AWESOME_PLUS_CIRCLE:+\\u$CODEPOINT_OF_AWESOME_PLUS_CIRCLE$s}" VCS_STASH_ICON "${CODEPOINT_OF_AWESOME_INBOX:+\\u$CODEPOINT_OF_AWESOME_INBOX }" VCS_INCOMING_CHANGES_ICON "${CODEPOINT_OF_AWESOME_ARROW_CIRCLE_DOWN:+\\u$CODEPOINT_OF_AWESOME_ARROW_CIRCLE_DOWN }" VCS_OUTGOING_CHANGES_ICON "${CODEPOINT_OF_AWESOME_ARROW_CIRCLE_UP:+\\u$CODEPOINT_OF_AWESOME_ARROW_CIRCLE_UP }" VCS_TAG_ICON "${CODEPOINT_OF_AWESOME_TAG:+\\u$CODEPOINT_OF_AWESOME_TAG }" VCS_BOOKMARK_ICON "${CODEPOINT_OF_OCTICONS_BOOKMARK:+\\u$CODEPOINT_OF_OCTICONS_BOOKMARK}" VCS_COMMIT_ICON "${CODEPOINT_OF_OCTICONS_GIT_COMMIT:+\\u$CODEPOINT_OF_OCTICONS_GIT_COMMIT }" VCS_BRANCH_ICON "${CODEPOINT_OF_OCTICONS_GIT_BRANCH:+\\u$CODEPOINT_OF_OCTICONS_GIT_BRANCH }" VCS_REMOTE_BRANCH_ICON "${CODEPOINT_OF_OCTICONS_REPO_PUSH:+\\u$CODEPOINT_OF_OCTICONS_REPO_PUSH$s}" VCS_LOADING_ICON '' VCS_GIT_ICON "${CODEPOINT_OF_AWESOME_GIT:+\\u$CODEPOINT_OF_AWESOME_GIT }" VCS_GIT_GITHUB_ICON "${CODEPOINT_OF_AWESOME_GITHUB_ALT:+\\u$CODEPOINT_OF_AWESOME_GITHUB_ALT }" VCS_GIT_BITBUCKET_ICON "${CODEPOINT_OF_AWESOME_BITBUCKET:+\\u$CODEPOINT_OF_AWESOME_BITBUCKET }" VCS_GIT_GITLAB_ICON "${CODEPOINT_OF_AWESOME_GITLAB:+\\u$CODEPOINT_OF_AWESOME_GITLAB }" VCS_HG_ICON "${CODEPOINT_OF_AWESOME_FLASK:+\\u$CODEPOINT_OF_AWESOME_FLASK }" VCS_SVN_ICON 'svn'$q RUST_ICON '\uE6A8' PYTHON_ICON '\U1F40D' SWIFT_ICON '\uE655'$s PUBLIC_IP_ICON "${CODEPOINT_OF_AWESOME_GLOBE:+\\u$CODEPOINT_OF_AWESOME_GLOBE$s}" LOCK_ICON "${CODEPOINT_OF_AWESOME_LOCK:+\\u$CODEPOINT_OF_AWESOME_LOCK}" NORDVPN_ICON "${CODEPOINT_OF_AWESOME_LOCK:+\\u$CODEPOINT_OF_AWESOME_LOCK}" EXECUTION_TIME_ICON "${CODEPOINT_OF_AWESOME_HOURGLASS_END:+\\u$CODEPOINT_OF_AWESOME_HOURGLASS_END$s}" SSH_ICON 'ssh' VPN_ICON "${CODEPOINT_OF_AWESOME_LOCK:+\\u$CODEPOINT_OF_AWESOME_LOCK}" KUBERNETES_ICON '\U2388' DROPBOX_ICON "${CODEPOINT_OF_AWESOME_DROPBOX:+\\u$CODEPOINT_OF_AWESOME_DROPBOX$s}" DATE_ICON '\uF073 ' TIME_ICON '\uF017 ' JAVA_ICON '\U2615' LARAVEL_ICON '' RANGER_ICON '\u2B50' MIDNIGHT_COMMANDER_ICON 'mc' VIM_ICON 'vim' TERRAFORM_ICON 'tf' PROXY_ICON '\u2194' DOTNET_ICON '.NET' DOTNET_CORE_ICON '.NET' AZURE_ICON '\u2601' DIRENV_ICON '\u25BC' FLUTTER_ICON 'F' GCLOUD_ICON 'G' LUA_ICON 'lua' PERL_ICON 'perl' NNN_ICON 'nnn' XPLR_ICON 'xplr' TIMEWARRIOR_ICON 'tw' TASKWARRIOR_ICON 'task' NIX_SHELL_ICON 'nix' WIFI_ICON 'WiFi' ERLANG_ICON 'erl' ELIXIR_ICON 'elixir' POSTGRES_ICON 'postgres' PHP_ICON 'php' HASKELL_ICON 'hs' PACKAGE_ICON 'pkg' JULIA_ICON 'jl' SCALA_ICON 'scala' TOOLBOX_ICON '\u2B22')  ;;
		('nerdfont-complete' | 'nerdfont-fontconfig') icons=(RULER_CHAR '\u2500' LEFT_SEGMENT_SEPARATOR '\uE0B0' RIGHT_SEGMENT_SEPARATOR '\uE0B2' LEFT_SEGMENT_END_SEPARATOR ' ' LEFT_SUBSEGMENT_SEPARATOR '\uE0B1' RIGHT_SUBSEGMENT_SEPARATOR '\uE0B3' CARRIAGE_RETURN_ICON '\u21B5' ROOT_ICON '\uE614'$q SUDO_ICON '\uF09C'$s RUBY_ICON '\uF219 ' AWS_ICON '\uF270'$s AWS_EB_ICON '\UF1BD'$q$q BACKGROUND_JOBS_ICON '\uF013 ' TEST_ICON '\uF188'$s TODO_ICON '\u2611' BATTERY_ICON '\UF240 ' DISK_ICON '\uF0A0'$s OK_ICON '\uF00C'$s FAIL_ICON '\uF00D' SYMFONY_ICON '\uE757' NODE_ICON '\uE617 ' NODEJS_ICON '\uE617 ' MULTILINE_FIRST_PROMPT_PREFIX '\u256D\U2500' MULTILINE_NEWLINE_PROMPT_PREFIX '\u251C\U2500' MULTILINE_LAST_PROMPT_PREFIX '\u2570\U2500 ' APPLE_ICON '\uF179' WINDOWS_ICON '\uF17A'$s FREEBSD_ICON '\UF30C ' ANDROID_ICON '\uF17B' LINUX_ARCH_ICON '\uF303' LINUX_CENTOS_ICON '\uF304'$s LINUX_COREOS_ICON '\uF305'$s LINUX_DEBIAN_ICON '\uF306' LINUX_RASPBIAN_ICON '\uF315' LINUX_ELEMENTARY_ICON '\uF309'$s LINUX_FEDORA_ICON '\uF30a'$s LINUX_GENTOO_ICON '\uF30d'$s LINUX_MAGEIA_ICON '\uF310' LINUX_MINT_ICON '\uF30e'$s LINUX_NIXOS_ICON '\uF313'$s LINUX_MANJARO_ICON '\uF312'$s LINUX_DEVUAN_ICON '\uF307'$s LINUX_ALPINE_ICON '\uF300'$s LINUX_AOSC_ICON '\uF301'$s LINUX_OPENSUSE_ICON '\uF314'$s LINUX_SABAYON_ICON '\uF317'$s LINUX_SLACKWARE_ICON '\uF319'$s LINUX_VOID_ICON '\uF17C' LINUX_ARTIX_ICON '\uF17C' LINUX_UBUNTU_ICON '\uF31b'$s LINUX_RHEL_ICON '\uF316'$s LINUX_AMZN_ICON '\uF270'$s LINUX_ICON '\uF17C' SUNOS_ICON '\uF185 ' HOME_ICON '\uF015'$s HOME_SUB_ICON '\uF07C'$s FOLDER_ICON '\uF115'$s ETC_ICON '\uF013'$s NETWORK_ICON '\uF50D'$s LOAD_ICON '\uF080 ' SWAP_ICON '\uF464'$s RAM_ICON '\uF0E4'$s SERVER_ICON '\uF0AE'$s VCS_UNTRACKED_ICON '\uF059'$s VCS_UNSTAGED_ICON '\uF06A'$s VCS_STAGED_ICON '\uF055'$s VCS_STASH_ICON '\uF01C ' VCS_INCOMING_CHANGES_ICON '\uF01A ' VCS_OUTGOING_CHANGES_ICON '\uF01B ' VCS_TAG_ICON '\uF02B ' VCS_BOOKMARK_ICON '\uF461 ' VCS_COMMIT_ICON '\uE729 ' VCS_BRANCH_ICON '\uF126 ' VCS_REMOTE_BRANCH_ICON '\uE728 ' VCS_LOADING_ICON '' VCS_GIT_ICON '\uF1D3 ' VCS_GIT_GITHUB_ICON '\uF113 ' VCS_GIT_BITBUCKET_ICON '\uE703 ' VCS_GIT_GITLAB_ICON '\uF296 ' VCS_HG_ICON '\uF0C3 ' VCS_SVN_ICON '\uE72D'$q RUST_ICON '\uE7A8'$q PYTHON_ICON '\UE73C ' SWIFT_ICON '\uE755' GO_ICON '\uE626' GOLANG_ICON '\uE626' PUBLIC_IP_ICON '\UF0AC'$s LOCK_ICON '\UF023' NORDVPN_ICON '\UF023' EXECUTION_TIME_ICON '\uF252'$s SSH_ICON '\uF489'$s VPN_ICON '\UF023' KUBERNETES_ICON '\U2388' DROPBOX_ICON '\UF16B'$s DATE_ICON '\uF073 ' TIME_ICON '\uF017 ' JAVA_ICON '\uE738' LARAVEL_ICON '\ue73f'$q RANGER_ICON '\uF00b ' MIDNIGHT_COMMANDER_ICON 'mc' VIM_ICON '\uE62B' TERRAFORM_ICON '\uF1BB ' PROXY_ICON '\u2194' DOTNET_ICON '\uE77F' DOTNET_CORE_ICON '\uE77F' AZURE_ICON '\uFD03' DIRENV_ICON '\u25BC' FLUTTER_ICON 'F' GCLOUD_ICON '\uF7B7' LUA_ICON '\uE620' PERL_ICON '\uE769' NNN_ICON 'nnn' XPLR_ICON 'xplr' TIMEWARRIOR_ICON '\uF49B' TASKWARRIOR_ICON '\uF4A0 ' NIX_SHELL_ICON '\uF313 ' WIFI_ICON '\uF1EB ' ERLANG_ICON '\uE7B1 ' ELIXIR_ICON '\uE62D' POSTGRES_ICON '\uE76E' PHP_ICON '\uE608' HASKELL_ICON '\uE61F' PACKAGE_ICON '\uF8D6' JULIA_ICON '\uE624' SCALA_ICON '\uE737' TOOLBOX_ICON '\uE20F'$s)  ;;
		(ascii) icons=(RULER_CHAR '-' LEFT_SEGMENT_SEPARATOR '' RIGHT_SEGMENT_SEPARATOR '' LEFT_SEGMENT_END_SEPARATOR ' ' LEFT_SUBSEGMENT_SEPARATOR '|' RIGHT_SUBSEGMENT_SEPARATOR '|' CARRIAGE_RETURN_ICON '' ROOT_ICON '#' SUDO_ICON '' RUBY_ICON 'rb' AWS_ICON 'aws' AWS_EB_ICON 'eb' BACKGROUND_JOBS_ICON '%%' TEST_ICON '' TODO_ICON 'todo' BATTERY_ICON 'battery' DISK_ICON 'disk' OK_ICON 'ok' FAIL_ICON 'err' SYMFONY_ICON 'symphony' NODE_ICON 'node' NODEJS_ICON 'node' MULTILINE_FIRST_PROMPT_PREFIX '' MULTILINE_NEWLINE_PROMPT_PREFIX '' MULTILINE_LAST_PROMPT_PREFIX '' APPLE_ICON 'mac' WINDOWS_ICON 'win' FREEBSD_ICON 'bsd' ANDROID_ICON 'android' LINUX_ICON 'linux' LINUX_ARCH_ICON 'arch' LINUX_DEBIAN_ICON 'debian' LINUX_RASPBIAN_ICON 'pi' LINUX_UBUNTU_ICON 'ubuntu' LINUX_CENTOS_ICON 'centos' LINUX_COREOS_ICON 'coreos' LINUX_ELEMENTARY_ICON 'elementary' LINUX_MINT_ICON 'mint' LINUX_FEDORA_ICON 'fedora' LINUX_GENTOO_ICON 'gentoo' LINUX_MAGEIA_ICON 'mageia' LINUX_NIXOS_ICON 'nixos' LINUX_MANJARO_ICON 'manjaro' LINUX_DEVUAN_ICON 'devuan' LINUX_ALPINE_ICON 'alpine' LINUX_AOSC_ICON 'aosc' LINUX_OPENSUSE_ICON 'suse' LINUX_SABAYON_ICON 'sabayon' LINUX_SLACKWARE_ICON 'slack' LINUX_VOID_ICON 'void' LINUX_ARTIX_ICON 'artix' LINUX_RHEL_ICON 'rhel' LINUX_AMZN_ICON 'amzn' SUNOS_ICON 'sunos' HOME_ICON '' HOME_SUB_ICON '' FOLDER_ICON '' ETC_ICON '' NETWORK_ICON 'ip' LOAD_ICON 'cpu' SWAP_ICON 'swap' RAM_ICON 'ram' SERVER_ICON '' VCS_UNTRACKED_ICON '?' VCS_UNSTAGED_ICON '!' VCS_STAGED_ICON '+' VCS_STASH_ICON '#' VCS_INCOMING_CHANGES_ICON '<' VCS_OUTGOING_CHANGES_ICON '>' VCS_TAG_ICON '' VCS_BOOKMARK_ICON '^' VCS_COMMIT_ICON '@' VCS_BRANCH_ICON '' VCS_REMOTE_BRANCH_ICON ':' VCS_LOADING_ICON '' VCS_GIT_ICON '' VCS_GIT_GITHUB_ICON '' VCS_GIT_BITBUCKET_ICON '' VCS_GIT_GITLAB_ICON '' VCS_HG_ICON '' VCS_SVN_ICON '' RUST_ICON 'rust' PYTHON_ICON 'py' SWIFT_ICON 'swift' GO_ICON 'go' GOLANG_ICON 'go' PUBLIC_IP_ICON 'ip' LOCK_ICON '!w' NORDVPN_ICON 'nordvpn' EXECUTION_TIME_ICON '' SSH_ICON 'ssh' VPN_ICON 'vpn' KUBERNETES_ICON 'kube' DROPBOX_ICON 'dropbox' DATE_ICON '' TIME_ICON '' JAVA_ICON 'java' LARAVEL_ICON '' RANGER_ICON 'ranger' MIDNIGHT_COMMANDER_ICON 'mc' VIM_ICON 'vim' TERRAFORM_ICON 'tf' PROXY_ICON 'proxy' DOTNET_ICON '.net' DOTNET_CORE_ICON '.net' AZURE_ICON 'az' DIRENV_ICON 'direnv' FLUTTER_ICON 'flutter' GCLOUD_ICON 'gcloud' LUA_ICON 'lua' PERL_ICON 'perl' NNN_ICON 'nnn' XPLR_ICON 'xplr' TIMEWARRIOR_ICON 'tw' TASKWARRIOR_ICON 'task' NIX_SHELL_ICON 'nix' WIFI_ICON 'wifi' ERLANG_ICON 'erlang' ELIXIR_ICON 'elixir' POSTGRES_ICON 'postgres' PHP_ICON 'php' HASKELL_ICON 'hs' PACKAGE_ICON 'pkg' JULIA_ICON 'jl' SCALA_ICON 'scala' TOOLBOX_ICON 'toolbox')  ;;
		(*) icons=(RULER_CHAR '\u2500' LEFT_SEGMENT_SEPARATOR '\uE0B0' RIGHT_SEGMENT_SEPARATOR '\uE0B2' LEFT_SEGMENT_END_SEPARATOR ' ' LEFT_SUBSEGMENT_SEPARATOR '\uE0B1' RIGHT_SUBSEGMENT_SEPARATOR '\uE0B3' CARRIAGE_RETURN_ICON '\u21B5' ROOT_ICON '\u26A1' SUDO_ICON '' RUBY_ICON 'Ruby' AWS_ICON 'AWS' AWS_EB_ICON '\U1F331'$q BACKGROUND_JOBS_ICON '\u2699' TEST_ICON '' TODO_ICON '\u2206' BATTERY_ICON '\U1F50B' DISK_ICON 'hdd' OK_ICON '\u2714' FAIL_ICON '\u2718' SYMFONY_ICON 'SF' NODE_ICON 'Node' NODEJS_ICON 'Node' MULTILINE_FIRST_PROMPT_PREFIX '\u256D\U2500' MULTILINE_NEWLINE_PROMPT_PREFIX '\u251C\U2500' MULTILINE_LAST_PROMPT_PREFIX '\u2570\U2500 ' APPLE_ICON 'OSX' WINDOWS_ICON 'WIN' FREEBSD_ICON 'BSD' ANDROID_ICON 'And' LINUX_ICON 'Lx' LINUX_ARCH_ICON 'Arc' LINUX_DEBIAN_ICON 'Deb' LINUX_RASPBIAN_ICON 'RPi' LINUX_UBUNTU_ICON 'Ubu' LINUX_CENTOS_ICON 'Cen' LINUX_COREOS_ICON 'Cor' LINUX_ELEMENTARY_ICON 'Elm' LINUX_MINT_ICON 'LMi' LINUX_FEDORA_ICON 'Fed' LINUX_GENTOO_ICON 'Gen' LINUX_MAGEIA_ICON 'Mag' LINUX_NIXOS_ICON 'Nix' LINUX_MANJARO_ICON 'Man' LINUX_DEVUAN_ICON 'Dev' LINUX_ALPINE_ICON 'Alp' LINUX_AOSC_ICON 'Aos' LINUX_OPENSUSE_ICON 'OSu' LINUX_SABAYON_ICON 'Sab' LINUX_SLACKWARE_ICON 'Sla' LINUX_VOID_ICON 'Vo' LINUX_ARTIX_ICON 'Art' LINUX_RHEL_ICON 'RH' LINUX_AMZN_ICON 'Amzn' SUNOS_ICON 'Sun' HOME_ICON '' HOME_SUB_ICON '' FOLDER_ICON '' ETC_ICON '\u2699' NETWORK_ICON 'IP' LOAD_ICON 'L' SWAP_ICON 'SWP' RAM_ICON 'RAM' SERVER_ICON '' VCS_UNTRACKED_ICON '?' VCS_UNSTAGED_ICON '\u25CF' VCS_STAGED_ICON '\u271A' VCS_STASH_ICON '\u235F' VCS_INCOMING_CHANGES_ICON '\u2193' VCS_OUTGOING_CHANGES_ICON '\u2191' VCS_TAG_ICON '' VCS_BOOKMARK_ICON '\u263F' VCS_COMMIT_ICON '' VCS_BRANCH_ICON '\uE0A0 ' VCS_REMOTE_BRANCH_ICON '\u2192' VCS_LOADING_ICON '' VCS_GIT_ICON '' VCS_GIT_GITHUB_ICON '' VCS_GIT_BITBUCKET_ICON '' VCS_GIT_GITLAB_ICON '' VCS_HG_ICON '' VCS_SVN_ICON '' RUST_ICON 'R' PYTHON_ICON 'Py' SWIFT_ICON 'Swift' GO_ICON 'Go' GOLANG_ICON 'Go' PUBLIC_IP_ICON 'IP' LOCK_ICON '\UE0A2' NORDVPN_ICON '\UE0A2' EXECUTION_TIME_ICON '' SSH_ICON 'ssh' VPN_ICON 'vpn' KUBERNETES_ICON '\U2388' DROPBOX_ICON 'Dropbox' DATE_ICON '' TIME_ICON '' JAVA_ICON '\U2615' LARAVEL_ICON '' RANGER_ICON '\u2B50' MIDNIGHT_COMMANDER_ICON 'mc' VIM_ICON 'vim' TERRAFORM_ICON 'tf' PROXY_ICON '\u2194' DOTNET_ICON '.NET' DOTNET_CORE_ICON '.NET' AZURE_ICON '\u2601' DIRENV_ICON '\u25BC' FLUTTER_ICON 'F' GCLOUD_ICON 'G' LUA_ICON 'lua' PERL_ICON 'perl' NNN_ICON 'nnn' XPLR_ICON 'xplr' TIMEWARRIOR_ICON 'tw' TASKWARRIOR_ICON 'task' NIX_SHELL_ICON 'nix' WIFI_ICON 'WiFi' ERLANG_ICON 'erl' ELIXIR_ICON 'elixir' POSTGRES_ICON 'postgres' PHP_ICON 'php' HASKELL_ICON 'hs' PACKAGE_ICON 'pkg' JULIA_ICON 'jl' SCALA_ICON 'scala' TOOLBOX_ICON '\u2B22')  ;;
	esac
	case $POWERLEVEL9K_MODE in
		('flat') icons[LEFT_SEGMENT_SEPARATOR]=''
			icons[RIGHT_SEGMENT_SEPARATOR]=''
			icons[LEFT_SUBSEGMENT_SEPARATOR]='|'
			icons[RIGHT_SUBSEGMENT_SEPARATOR]='|'  ;;
		('compatible') icons[LEFT_SEGMENT_SEPARATOR]='\u2B80'
			icons[RIGHT_SEGMENT_SEPARATOR]='\u2B82'
			icons[VCS_BRANCH_ICON]='@'  ;;
	esac
	if [[ $POWERLEVEL9K_ICON_PADDING == none && $POWERLEVEL9K_MODE != ascii ]]
	then
		icons=("${(@kv)icons%% #}")
		icons[LEFT_SEGMENT_END_SEPARATOR]+=' '
		icons[MULTILINE_LAST_PROMPT_PREFIX]+=' '
		icons[VCS_TAG_ICON]+=' '
		icons[VCS_BOOKMARK_ICON]+=' '
		icons[VCS_COMMIT_ICON]+=' '
		icons[VCS_BRANCH_ICON]+=' '
		icons[VCS_REMOTE_BRANCH_ICON]+=' '
	fi
}
_p9k_init_lines () {
	local -a left_segments=($_POWERLEVEL9K_LEFT_PROMPT_ELEMENTS)
	local -a right_segments=($_POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS)
	if (( _POWERLEVEL9K_PROMPT_ON_NEWLINE ))
	then
		left_segments+=(newline _p9k_internal_nothing)
	fi
	local -i num_left_lines=$((1 + ${#${(@M)left_segments:#newline}}))
	local -i num_right_lines=$((1 + ${#${(@M)right_segments:#newline}}))
	if (( num_right_lines > num_left_lines ))
	then
		repeat $((num_right_lines - num_left_lines))
		do
			left_segments=(newline $left_segments)
		done
		local -i num_lines=num_right_lines
	else
		if (( _POWERLEVEL9K_RPROMPT_ON_NEWLINE ))
		then
			repeat $((num_left_lines - num_right_lines))
			do
				right_segments=(newline $right_segments)
			done
		else
			repeat $((num_left_lines - num_right_lines))
			do
				right_segments+=newline
			done
		fi
		local -i num_lines=num_left_lines
	fi
	local -i i
	for i in {1..$num_lines}
	do
		local -i left_end=${left_segments[(i)newline]}
		local -i right_end=${right_segments[(i)newline]}
		_p9k_line_segments_left+="${(pj:\0:)left_segments[1,left_end-1]}"
		_p9k_line_segments_right+="${(pj:\0:)right_segments[1,right_end-1]}"
		(( left_end > $#left_segments )) && left_segments=()  || shift left_end left_segments
		(( right_end > $#right_segments )) && right_segments=()  || shift right_end right_segments
		_p9k_get_icon '' LEFT_SEGMENT_SEPARATOR
		_p9k_get_icon 'prompt_empty_line' LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL $_p9k__ret
		_p9k_escape $_p9k__ret
		_p9k_line_prefix_left+='${_p9k__'$i'l-${${:-${_p9k__bg::=NONE}${_p9k__i::=0}${_p9k__sss::=%f'$_p9k__ret'}}+}'
		_p9k_line_suffix_left+='%b%k$_p9k__sss%b%k%f'
		_p9k_escape ${(g::)_POWERLEVEL9K_EMPTY_LINE_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL}
		[[ -n $_p9k__ret ]] && _p9k_line_never_empty_right+=1  || _p9k_line_never_empty_right+=0
		_p9k_line_prefix_right+='${_p9k__'$i'r-${${:-${_p9k__bg::=NONE}${_p9k__i::=0}${_p9k__sss::='$_p9k__ret'}}+}'
		_p9k_line_suffix_right+='$_p9k__sss%b%k%f}'
		if (( i == num_lines ))
		then
			_p9k_prompt_length ${(e)_p9k__ret}
			(( _p9k__ret )) || _p9k_line_never_empty_right[-1]=0
		fi
	done
	_p9k_get_icon '' LEFT_SEGMENT_END_SEPARATOR
	if [[ -n $_p9k__ret ]]
	then
		_p9k__ret+=%b%k%f
		_p9k__ret='${:-"'$_p9k__ret'"}'
		if (( _POWERLEVEL9K_PROMPT_ON_NEWLINE ))
		then
			_p9k_line_suffix_left[-2]+=$_p9k__ret
		else
			_p9k_line_suffix_left[-1]+=$_p9k__ret
		fi
	fi
	for i in {1..$num_lines}
	do
		_p9k_line_suffix_left[i]+='}'
	done
	if (( num_lines > 1 ))
	then
		for i in {1..$((num_lines-1))}
		do
			_p9k_build_gap_post $i
			_p9k_line_gap_post+=$_p9k__ret
		done
		if [[ $+_POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX == 1 || $_POWERLEVEL9K_PROMPT_ON_NEWLINE == 1 ]]
		then
			_p9k_get_icon '' MULTILINE_FIRST_PROMPT_PREFIX
			if [[ -n $_p9k__ret ]]
			then
				[[ _p9k__ret == *%* ]] && _p9k__ret+=%b%k%f
				_p9k__ret='${_p9k__1l_frame-"'$_p9k__ret'"}'
				_p9k_line_prefix_left[1]=$_p9k__ret$_p9k_line_prefix_left[1]
			fi
		fi
		if [[ $+_POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX == 1 || $_POWERLEVEL9K_PROMPT_ON_NEWLINE == 1 ]]
		then
			_p9k_get_icon '' MULTILINE_LAST_PROMPT_PREFIX
			if [[ -n $_p9k__ret ]]
			then
				[[ _p9k__ret == *%* ]] && _p9k__ret+=%b%k%f
				_p9k__ret='${_p9k__'$num_lines'l_frame-"'$_p9k__ret'"}'
				_p9k_line_prefix_left[-1]=$_p9k__ret$_p9k_line_prefix_left[-1]
			fi
		fi
		_p9k_get_icon '' MULTILINE_FIRST_PROMPT_SUFFIX
		if [[ -n $_p9k__ret ]]
		then
			[[ _p9k__ret == *%* ]] && _p9k__ret+=%b%k%f
			_p9k_line_suffix_right[1]+='${_p9k__1r_frame-'${(qqq)_p9k__ret}'}'
			_p9k_line_never_empty_right[1]=1
		fi
		_p9k_get_icon '' MULTILINE_LAST_PROMPT_SUFFIX
		if [[ -n $_p9k__ret ]]
		then
			[[ _p9k__ret == *%* ]] && _p9k__ret+=%b%k%f
			_p9k_line_suffix_right[-1]+='${_p9k__'$num_lines'r_frame-'${(qqq)_p9k__ret}'}'
			_p9k_prompt_length $_p9k__ret
			(( _p9k__ret )) && _p9k_line_never_empty_right[-1]=1
		fi
		if (( num_lines > 2 ))
		then
			if [[ $+_POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX == 1 || $_POWERLEVEL9K_PROMPT_ON_NEWLINE == 1 ]]
			then
				_p9k_get_icon '' MULTILINE_NEWLINE_PROMPT_PREFIX
				if [[ -n $_p9k__ret ]]
				then
					[[ _p9k__ret == *%* ]] && _p9k__ret+=%b%k%f
					for i in {2..$((num_lines-1))}
					do
						_p9k_line_prefix_left[i]='${_p9k__'$i'l_frame-"'$_p9k__ret'"}'$_p9k_line_prefix_left[i]
					done
				fi
			fi
			_p9k_get_icon '' MULTILINE_NEWLINE_PROMPT_SUFFIX
			if [[ -n $_p9k__ret ]]
			then
				[[ _p9k__ret == *%* ]] && _p9k__ret+=%b%k%f
				for i in {2..$((num_lines-1))}
				do
					_p9k_line_suffix_right[i]+='${_p9k__'$i'r_frame-'${(qqq)_p9k__ret}'}'
				done
				_p9k_line_never_empty_right[2,-2]=${(@)_p9k_line_never_empty_right[2,-2]/0/1}
			fi
		fi
	fi
}
_p9k_init_locale () {
	if (( ! $+__p9k_locale ))
	then
		typeset -g __p9k_locale=
		(( $+commands[locale] )) || return
		local -a loc
		loc=(${(@M)$(locale -a 2>/dev/null):#*.(utf|UTF)(-|)8})  || return
		(( $#loc )) || return
		typeset -g __p9k_locale=${loc[(r)(#i)C.UTF(-|)8]:-${loc[(r)(#i)en_US.UTF(-|)8]:-$loc[1]}}
	fi
	[[ -n $__p9k_locale ]]
}
_p9k_init_params () {
	_p9k_declare -F POWERLEVEL9K_GCLOUD_REFRESH_PROJECT_NAME_SECONDS 60
	_p9k_declare -s POWERLEVEL9K_INSTANT_PROMPT
	if [[ $_POWERLEVEL9K_INSTANT_PROMPT == off ]]
	then
		typeset -gi _POWERLEVEL9K_DISABLE_INSTANT_PROMPT=1
	else
		_p9k_declare -b POWERLEVEL9K_DISABLE_INSTANT_PROMPT 0
		if (( _POWERLEVEL9K_DISABLE_INSTANT_PROMPT ))
		then
			_POWERLEVEL9K_INSTANT_PROMPT=off
		elif [[ $_POWERLEVEL9K_INSTANT_PROMPT != quiet ]]
		then
			_POWERLEVEL9K_INSTANT_PROMPT=verbose
		fi
	fi
	(( _POWERLEVEL9K_DISABLE_INSTANT_PROMPT )) && _p9k__instant_prompt_disabled=1
	_p9k_declare -s POWERLEVEL9K_TRANSIENT_PROMPT off
	[[ $_POWERLEVEL9K_TRANSIENT_PROMPT == (off|always|same-dir) ]] || _POWERLEVEL9K_TRANSIENT_PROMPT=off
	_p9k_declare -b POWERLEVEL9K_TERM_SHELL_INTEGRATION 0
	if [[ __p9k_force_term_shell_integration -eq 1 || $ITERM_SHELL_INTEGRATION_INSTALLED == Yes ]]
	then
		_POWERLEVEL9K_TERM_SHELL_INTEGRATION=1
	fi
	_p9k_declare -s POWERLEVEL9K_WORKER_LOG_LEVEL
	_p9k_declare -i POWERLEVEL9K_COMMANDS_MAX_TOKEN_COUNT 64
	_p9k_declare -a POWERLEVEL9K_HOOK_WIDGETS --
	_p9k_declare -b POWERLEVEL9K_TODO_HIDE_ZERO_TOTAL 0
	_p9k_declare -b POWERLEVEL9K_TODO_HIDE_ZERO_FILTERED 0
	_p9k_declare -b POWERLEVEL9K_DISABLE_HOT_RELOAD 0
	_p9k_declare -F POWERLEVEL9K_NEW_TTY_MAX_AGE_SECONDS 5
	_p9k_declare -i POWERLEVEL9K_INSTANT_PROMPT_COMMAND_LINES
	_p9k_declare -a POWERLEVEL9K_LEFT_PROMPT_ELEMENTS -- context dir vcs
	_p9k_declare -a POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS -- status root_indicator background_jobs history time
	_p9k_declare -b POWERLEVEL9K_DISABLE_RPROMPT 0
	_p9k_declare -b POWERLEVEL9K_PROMPT_ADD_NEWLINE 0
	_p9k_declare -b POWERLEVEL9K_PROMPT_ON_NEWLINE 0
	_p9k_declare -b POWERLEVEL9K_RPROMPT_ON_NEWLINE 0
	_p9k_declare -b POWERLEVEL9K_SHOW_RULER 0
	_p9k_declare -i POWERLEVEL9K_PROMPT_ADD_NEWLINE_COUNT 1
	_p9k_declare -s POWERLEVEL9K_COLOR_SCHEME dark
	_p9k_declare -s POWERLEVEL9K_GITSTATUS_DIR ""
	_p9k_declare -s POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN
	_p9k_declare -b POWERLEVEL9K_VCS_SHOW_SUBMODULE_DIRTY 0
	_p9k_declare -i POWERLEVEL9K_VCS_SHORTEN_LENGTH
	_p9k_declare -i POWERLEVEL9K_VCS_SHORTEN_MIN_LENGTH
	_p9k_declare -s POWERLEVEL9K_VCS_SHORTEN_STRATEGY
	if [[ $langinfo[CODESET] == (utf|UTF)(-|)8 ]]
	then
		_p9k_declare -e POWERLEVEL9K_VCS_SHORTEN_DELIMITER '\u2026'
	else
		_p9k_declare -e POWERLEVEL9K_VCS_SHORTEN_DELIMITER '..'
	fi
	_p9k_declare -b POWERLEVEL9K_VCS_CONFLICTED_STATE 0
	_p9k_declare -b POWERLEVEL9K_HIDE_BRANCH_ICON 0
	_p9k_declare -b POWERLEVEL9K_VCS_HIDE_TAGS 0
	_p9k_declare -i POWERLEVEL9K_CHANGESET_HASH_LENGTH 8
	_p9k_declare -i POWERLEVEL9K_MAX_CACHE_SIZE 10000
	_p9k_declare -e POWERLEVEL9K_ANACONDA_LEFT_DELIMITER "("
	_p9k_declare -e POWERLEVEL9K_ANACONDA_RIGHT_DELIMITER ")"
	_p9k_declare -b POWERLEVEL9K_ANACONDA_SHOW_PYTHON_VERSION 1
	_p9k_declare -b POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE 1
	_p9k_declare -b POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE_ALWAYS 0
	_p9k_declare -b POWERLEVEL9K_DISK_USAGE_ONLY_WARNING 0
	_p9k_declare -i POWERLEVEL9K_DISK_USAGE_WARNING_LEVEL 90
	_p9k_declare -i POWERLEVEL9K_DISK_USAGE_CRITICAL_LEVEL 95
	_p9k_declare -i POWERLEVEL9K_BATTERY_LOW_THRESHOLD 10
	_p9k_declare -i POWERLEVEL9K_BATTERY_HIDE_ABOVE_THRESHOLD 999
	_p9k_declare -b POWERLEVEL9K_BATTERY_VERBOSE 1
	_p9k_declare -a POWERLEVEL9K_BATTERY_LEVEL_BACKGROUND --
	_p9k_declare -a POWERLEVEL9K_BATTERY_LEVEL_FOREGROUND --
	case $parameters[POWERLEVEL9K_BATTERY_STAGES] in
		(scalar*) typeset -ga _POWERLEVEL9K_BATTERY_STAGES=("${(@s::)${(g::)POWERLEVEL9K_BATTERY_STAGES}}")  ;;
		(array*) typeset -ga _POWERLEVEL9K_BATTERY_STAGES=("${(@g::)POWERLEVEL9K_BATTERY_STAGES}")  ;;
		(*) typeset -ga _POWERLEVEL9K_BATTERY_STAGES=()  ;;
	esac
	local state
	for state in CHARGED CHARGING LOW DISCONNECTED
	do
		_p9k_declare -i POWERLEVEL9K_BATTERY_${state}_HIDE_ABOVE_THRESHOLD $_POWERLEVEL9K_BATTERY_HIDE_ABOVE_THRESHOLD
		local var=POWERLEVEL9K_BATTERY_${state}_STAGES
		case $parameters[$var] in
			(scalar*) eval "typeset -ga _$var=(${(@qq)${(@s::)${(g::)${(P)var}}}})" ;;
			(array*) eval "typeset -ga _$var=(${(@qq)${(@g::)${(@P)var}}})" ;;
			(*) eval "typeset -ga _$var=(${(@qq)_POWERLEVEL9K_BATTERY_STAGES})" ;;
		esac
		local var=POWERLEVEL9K_BATTERY_${state}_LEVEL_BACKGROUND
		case $parameters[$var] in
			(array*) eval "typeset -ga _$var=(${(@qq)${(@P)var}})" ;;
			(*) eval "typeset -ga _$var=(${(@qq)_POWERLEVEL9K_BATTERY_LEVEL_BACKGROUND})" ;;
		esac
		local var=POWERLEVEL9K_BATTERY_${state}_LEVEL_FOREGROUND
		case $parameters[$var] in
			(array*) eval "typeset -ga _$var=(${(@qq)${(@P)var}})" ;;
			(*) eval "typeset -ga _$var=(${(@qq)_POWERLEVEL9K_BATTERY_LEVEL_FOREGROUND})" ;;
		esac
	done
	_p9k_declare -F POWERLEVEL9K_PUBLIC_IP_TIMEOUT 300
	_p9k_declare -a POWERLEVEL9K_PUBLIC_IP_METHODS -- dig curl wget
	_p9k_declare -e POWERLEVEL9K_PUBLIC_IP_NONE ""
	_p9k_declare -s POWERLEVEL9K_PUBLIC_IP_HOST "https://v4.ident.me/"
	_p9k_declare -s POWERLEVEL9K_PUBLIC_IP_VPN_INTERFACE ""
	_p9k_segment_in_use public_ip || _POWERLEVEL9K_PUBLIC_IP_VPN_INTERFACE=
	_p9k_declare -b POWERLEVEL9K_ALWAYS_SHOW_CONTEXT 0
	_p9k_declare -b POWERLEVEL9K_ALWAYS_SHOW_USER 0
	_p9k_declare -e POWERLEVEL9K_CONTEXT_TEMPLATE "%n@%m"
	_p9k_declare -e POWERLEVEL9K_USER_TEMPLATE "%n"
	_p9k_declare -e POWERLEVEL9K_HOST_TEMPLATE "%m"
	_p9k_declare -F POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD 3
	_p9k_declare -i POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION 2
	_p9k_declare -s POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT "H:M:S"
	_p9k_declare -e POWERLEVEL9K_HOME_FOLDER_ABBREVIATION "~"
	_p9k_declare -b POWERLEVEL9K_DIR_PATH_ABSOLUTE 0
	_p9k_declare -s POWERLEVEL9K_DIR_SHOW_WRITABLE ''
	case $_POWERLEVEL9K_DIR_SHOW_WRITABLE in
		(true) _POWERLEVEL9K_DIR_SHOW_WRITABLE=1  ;;
		(v2) _POWERLEVEL9K_DIR_SHOW_WRITABLE=2  ;;
		(v3) _POWERLEVEL9K_DIR_SHOW_WRITABLE=3  ;;
		(*) _POWERLEVEL9K_DIR_SHOW_WRITABLE=0  ;;
	esac
	typeset -gi _POWERLEVEL9K_DIR_SHOW_WRITABLE
	_p9k_declare -b POWERLEVEL9K_DIR_OMIT_FIRST_CHARACTER 0
	_p9k_declare -b POWERLEVEL9K_DIR_HYPERLINK 0
	_p9k_declare -s POWERLEVEL9K_SHORTEN_STRATEGY ""
	local markers=(.bzr .citc .git .hg .node-version .python-version .ruby-version .shorten_folder_marker .svn .terraform CVS Cargo.toml composer.json go.mod package.json)
	_p9k_declare -s POWERLEVEL9K_SHORTEN_FOLDER_MARKER "(${(j:|:)markers})"
	_p9k_declare -s POWERLEVEL9K_DIR_MAX_LENGTH 0
	_p9k_declare -a POWERLEVEL9K_DIR_PACKAGE_FILES -- package.json composer.json
	_p9k_declare -i POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS 40
	_p9k_declare -F POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT 50
	_p9k_declare -a POWERLEVEL9K_DIR_CLASSES
	_p9k_declare -i POWERLEVEL9K_SHORTEN_DELIMITER_LENGTH
	_p9k_declare -e POWERLEVEL9K_SHORTEN_DELIMITER
	_p9k_declare -s POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER ''
	case $_POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER in
		(first | last) _POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER+=:0  ;;
		((first|last):(|-)<->)  ;;
		(*) _POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=  ;;
	esac
	[[ -z $_POWERLEVEL9K_SHORTEN_FOLDER_MARKER ]] && _POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=
	_p9k_declare -i POWERLEVEL9K_SHORTEN_DIR_LENGTH
	_p9k_declare -s POWERLEVEL9K_IP_INTERFACE ""
	: ${_POWERLEVEL9K_IP_INTERFACE:='.*'}
	_p9k_segment_in_use ip || _POWERLEVEL9K_IP_INTERFACE=
	_p9k_declare -s POWERLEVEL9K_VPN_IP_INTERFACE "(gpd|wg|(.*tun)|tailscale)[0-9]*)|(zt.*)"
	: ${_POWERLEVEL9K_VPN_IP_INTERFACE:='.*'}
	_p9k_segment_in_use vpn_ip || _POWERLEVEL9K_VPN_IP_INTERFACE=
	_p9k_declare -b POWERLEVEL9K_VPN_IP_SHOW_ALL 0
	_p9k_declare -i POWERLEVEL9K_LOAD_WHICH 5
	case $_POWERLEVEL9K_LOAD_WHICH in
		(1) _POWERLEVEL9K_LOAD_WHICH=1  ;;
		(15) _POWERLEVEL9K_LOAD_WHICH=3  ;;
		(*) _POWERLEVEL9K_LOAD_WHICH=2  ;;
	esac
	_p9k_declare -F POWERLEVEL9K_LOAD_WARNING_PCT 50
	_p9k_declare -F POWERLEVEL9K_LOAD_CRITICAL_PCT 70
	_p9k_declare -b POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY 0
	_p9k_declare -b POWERLEVEL9K_PHP_VERSION_PROJECT_ONLY 0
	_p9k_declare -b POWERLEVEL9K_DOTNET_VERSION_PROJECT_ONLY 1
	_p9k_declare -b POWERLEVEL9K_GO_VERSION_PROJECT_ONLY 1
	_p9k_declare -b POWERLEVEL9K_RUST_VERSION_PROJECT_ONLY 1
	_p9k_declare -b POWERLEVEL9K_JAVA_VERSION_PROJECT_ONLY 0
	_p9k_declare -b POWERLEVEL9K_NODENV_PROMPT_ALWAYS_SHOW 0
	_p9k_declare -a POWERLEVEL9K_NODENV_SOURCES -- shell local global
	_p9k_declare -b POWERLEVEL9K_NODENV_SHOW_SYSTEM 1
	_p9k_declare -b POWERLEVEL9K_RBENV_PROMPT_ALWAYS_SHOW 0
	_p9k_declare -a POWERLEVEL9K_RBENV_SOURCES -- shell local global
	_p9k_declare -b POWERLEVEL9K_RBENV_SHOW_SYSTEM 1
	_p9k_declare -b POWERLEVEL9K_SCALAENV_PROMPT_ALWAYS_SHOW 0
	_p9k_declare -a POWERLEVEL9K_SCALAENV_SOURCES -- shell local global
	_p9k_declare -b POWERLEVEL9K_SCALAENV_SHOW_SYSTEM 1
	_p9k_declare -b POWERLEVEL9K_PHPENV_PROMPT_ALWAYS_SHOW 0
	_p9k_declare -a POWERLEVEL9K_PHPENV_SOURCES -- shell local global
	_p9k_declare -b POWERLEVEL9K_PHPENV_SHOW_SYSTEM 1
	_p9k_declare -b POWERLEVEL9K_LUAENV_PROMPT_ALWAYS_SHOW 0
	_p9k_declare -a POWERLEVEL9K_LUAENV_SOURCES -- shell local global
	_p9k_declare -b POWERLEVEL9K_LUAENV_SHOW_SYSTEM 1
	_p9k_declare -b POWERLEVEL9K_JENV_PROMPT_ALWAYS_SHOW 0
	_p9k_declare -a POWERLEVEL9K_JENV_SOURCES -- shell local global
	_p9k_declare -b POWERLEVEL9K_JENV_SHOW_SYSTEM 1
	_p9k_declare -b POWERLEVEL9K_PLENV_PROMPT_ALWAYS_SHOW 0
	_p9k_declare -a POWERLEVEL9K_PLENV_SOURCES -- shell local global
	_p9k_declare -b POWERLEVEL9K_PLENV_SHOW_SYSTEM 1
	_p9k_declare -b POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW 0
	_p9k_declare -b POWERLEVEL9K_PYENV_SHOW_SYSTEM 1
	_p9k_declare -a POWERLEVEL9K_PYENV_SOURCES -- shell local global
	_p9k_declare -b POWERLEVEL9K_GOENV_PROMPT_ALWAYS_SHOW 0
	_p9k_declare -a POWERLEVEL9K_GOENV_SOURCES -- shell local global
	_p9k_declare -b POWERLEVEL9K_GOENV_SHOW_SYSTEM 1
	_p9k_declare -b POWERLEVEL9K_ASDF_PROMPT_ALWAYS_SHOW 0
	_p9k_declare -b POWERLEVEL9K_ASDF_SHOW_SYSTEM 1
	_p9k_declare -a POWERLEVEL9K_ASDF_SOURCES -- shell local global
	local var
	for var in ${parameters[(I)POWERLEVEL9K_ASDF_*_PROMPT_ALWAYS_SHOW]}
	do
		_p9k_declare -b $var $_POWERLEVEL9K_ASDF_PROMPT_ALWAYS_SHOW
	done
	for var in ${parameters[(I)POWERLEVEL9K_ASDF_*_SHOW_SYSTEM]}
	do
		_p9k_declare -b $var $_POWERLEVEL9K_ASDF_SHOW_SYSTEM
	done
	for var in ${parameters[(I)POWERLEVEL9K_ASDF_*_SOURCES]}
	do
		_p9k_declare -a $var -- $_POWERLEVEL9K_ASDF_SOURCES
	done
	_p9k_declare -b POWERLEVEL9K_HASKELL_STACK_PROMPT_ALWAYS_SHOW 1
	_p9k_declare -a POWERLEVEL9K_HASKELL_STACK_SOURCES -- shell local
	_p9k_declare -b POWERLEVEL9K_RVM_SHOW_GEMSET 0
	_p9k_declare -b POWERLEVEL9K_RVM_SHOW_PREFIX 0
	_p9k_declare -b POWERLEVEL9K_CHRUBY_SHOW_VERSION 1
	_p9k_declare -b POWERLEVEL9K_CHRUBY_SHOW_ENGINE 1
	_p9k_declare -b POWERLEVEL9K_STATUS_CROSS 0
	_p9k_declare -b POWERLEVEL9K_STATUS_OK 1
	_p9k_declare -b POWERLEVEL9K_STATUS_OK_PIPE 1
	_p9k_declare -b POWERLEVEL9K_STATUS_ERROR 1
	_p9k_declare -b POWERLEVEL9K_STATUS_ERROR_PIPE 1
	_p9k_declare -b POWERLEVEL9K_STATUS_ERROR_SIGNAL 1
	_p9k_declare -b POWERLEVEL9K_STATUS_SHOW_PIPESTATUS 1
	_p9k_declare -b POWERLEVEL9K_STATUS_HIDE_SIGNAME 0
	_p9k_declare -b POWERLEVEL9K_STATUS_VERBOSE_SIGNAME 1
	_p9k_declare -b POWERLEVEL9K_STATUS_EXTENDED_STATES 0
	_p9k_declare -b POWERLEVEL9K_STATUS_VERBOSE 1
	_p9k_declare -b POWERLEVEL9K_STATUS_OK_IN_NON_VERBOSE 0
	_p9k_declare -e POWERLEVEL9K_DATE_FORMAT "%D{%d.%m.%y}"
	_p9k_declare -s POWERLEVEL9K_VCS_ACTIONFORMAT_FOREGROUND 1
	_p9k_declare -b POWERLEVEL9K_SHOW_CHANGESET 0
	_p9k_declare -e POWERLEVEL9K_VCS_LOADING_TEXT loading
	_p9k_declare -a POWERLEVEL9K_VCS_GIT_HOOKS -- vcs-detect-changes git-untracked git-aheadbehind git-stash git-remotebranch git-tagname
	_p9k_declare -a POWERLEVEL9K_VCS_HG_HOOKS -- vcs-detect-changes
	_p9k_declare -a POWERLEVEL9K_VCS_SVN_HOOKS -- vcs-detect-changes svn-detect-changes
	_p9k_declare -F POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS 0.01
	(( POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS >= 0 )) || (( POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS = 0 ))
	_p9k_declare -a POWERLEVEL9K_VCS_BACKENDS -- git
	(( $+commands[git] )) || _POWERLEVEL9K_VCS_BACKENDS=(${_POWERLEVEL9K_VCS_BACKENDS:#git})
	_p9k_declare -b POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING 0
	_p9k_declare -i POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY -1
	_p9k_declare -i POWERLEVEL9K_VCS_STAGED_MAX_NUM 1
	_p9k_declare -i POWERLEVEL9K_VCS_UNSTAGED_MAX_NUM 1
	_p9k_declare -i POWERLEVEL9K_VCS_UNTRACKED_MAX_NUM 1
	_p9k_declare -i POWERLEVEL9K_VCS_CONFLICTED_MAX_NUM 1
	_p9k_declare -i POWERLEVEL9K_VCS_COMMITS_AHEAD_MAX_NUM -1
	_p9k_declare -i POWERLEVEL9K_VCS_COMMITS_BEHIND_MAX_NUM -1
	_p9k_declare -b POWERLEVEL9K_VCS_RECURSE_UNTRACKED_DIRS 0
	_p9k_declare -b POWERLEVEL9K_DISABLE_GITSTATUS 0
	_p9k_declare -e POWERLEVEL9K_VI_INSERT_MODE_STRING "INSERT"
	_p9k_declare -e POWERLEVEL9K_VI_COMMAND_MODE_STRING "NORMAL"
	_p9k_declare -e POWERLEVEL9K_VI_VISUAL_MODE_STRING
	_p9k_declare -e POWERLEVEL9K_VI_OVERWRITE_MODE_STRING
	_p9k_declare -s POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYENV true
	_p9k_declare -b POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION 1
	_p9k_declare -e POWERLEVEL9K_VIRTUALENV_LEFT_DELIMITER "("
	_p9k_declare -e POWERLEVEL9K_VIRTUALENV_RIGHT_DELIMITER ")"
	_p9k_declare -a POWERLEVEL9K_VIRTUALENV_GENERIC_NAMES -- virtualenv venv .venv env
	_POWERLEVEL9K_VIRTUALENV_GENERIC_NAMES="${(j.|.)_POWERLEVEL9K_VIRTUALENV_GENERIC_NAMES}"
	_p9k_declare -b POWERLEVEL9K_NODEENV_SHOW_NODE_VERSION 1
	_p9k_declare -e POWERLEVEL9K_NODEENV_LEFT_DELIMITER "["
	_p9k_declare -e POWERLEVEL9K_NODEENV_RIGHT_DELIMITER "]"
	_p9k_declare -b POWERLEVEL9K_KUBECONTEXT_SHOW_DEFAULT_NAMESPACE 1
	_p9k_declare -a POWERLEVEL9K_KUBECONTEXT_SHORTEN --
	_p9k_declare -a POWERLEVEL9K_KUBECONTEXT_CLASSES --
	_p9k_declare -a POWERLEVEL9K_AWS_CLASSES --
	_p9k_declare -a POWERLEVEL9K_AZURE_CLASSES --
	_p9k_declare -a POWERLEVEL9K_TERRAFORM_CLASSES --
	_p9k_declare -b POWERLEVEL9K_TERRAFORM_SHOW_DEFAULT 0
	_p9k_declare -a POWERLEVEL9K_GOOGLE_APP_CRED_CLASSES -- 'service_account:*' SERVICE_ACCOUNT
	_p9k_declare -b POWERLEVEL9K_JAVA_VERSION_FULL 1
	_p9k_declare -b POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE 0
	_p9k_declare -e POWERLEVEL9K_TIME_FORMAT "%D{%H:%M:%S}"
	_p9k_declare -b POWERLEVEL9K_TIME_UPDATE_ON_COMMAND 0
	_p9k_declare -b POWERLEVEL9K_EXPERIMENTAL_TIME_REALTIME 0
	local -i i=1
	while (( i <= $#_POWERLEVEL9K_LEFT_PROMPT_ELEMENTS ))
	do
		local segment=${${(U)_POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[i]}//İ/I}
		local var=POWERLEVEL9K_${segment}_LEFT_DISABLED
		(( $+parameters[$var] )) || var=POWERLEVEL9K_${segment}_DISABLED
		if [[ ${(P)var} == true ]]
		then
			_POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[i,i]=()
		else
			(( ++i ))
		fi
	done
	local -i i=1
	while (( i <= $#_POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS ))
	do
		local segment=${${(U)_POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[i]}//İ/I}
		local var=POWERLEVEL9K_${segment}_RIGHT_DISABLED
		(( $+parameters[$var] )) || var=POWERLEVEL9K_${segment}_DISABLED
		if [[ ${(P)var} == true ]]
		then
			_POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[i,i]=()
		else
			(( ++i ))
		fi
	done
	local var
	for var in ${(@)${parameters[(I)POWERLEVEL9K_*]}/(#m)*/${(M)${parameters[_$MATCH]-$MATCH}:#$MATCH}}
	do
		case $parameters[$var] in
			((scalar|integer|float)*) typeset -g _$var=${(P)var} ;;
			(array*) eval 'typeset -ga '_$var'=("${'$var'[@]}")' ;;
		esac
	done
}
_p9k_init_prompt () {
	_p9k_t=($'\n' $'%{\n%}' '')
	_p9k_prompt_overflow_bug && _p9k_t[2]=$'%{%G\n%}'
	_p9k_init_lines
	_p9k_gap_pre='${${:-${_p9k__x::=0}${_p9k__y::=1024}${_p9k__p::=$_p9k__lprompt$_p9k__rprompt}'
	repeat 10
	do
		_p9k_gap_pre+='${_p9k__m::=$(((_p9k__x+_p9k__y)/2))}'
		_p9k_gap_pre+='${_p9k__xy::=${${(%):-$_p9k__p%$_p9k__m(l./$_p9k__m;$_p9k__y./$_p9k__x;$_p9k__m)}##*/}}'
		_p9k_gap_pre+='${_p9k__x::=${_p9k__xy%;*}}'
		_p9k_gap_pre+='${_p9k__y::=${_p9k__xy#*;}}'
	done
	_p9k_gap_pre+='${_p9k__m::=$((_p9k__clm-_p9k__x-_p9k__ind-1))}'
	_p9k_gap_pre+='}+}'
	_p9k_prompt_prefix_left='${${_p9k__clm::=$COLUMNS}+}${${COLUMNS::=1024}+}'
	_p9k_prompt_prefix_right='${_p9k__'$#_p9k_line_segments_left'-${${_p9k__clm::=$COLUMNS}+}${${COLUMNS::=1024}+}'
	_p9k_prompt_suffix_left='${${COLUMNS::=$_p9k__clm}+}'
	_p9k_prompt_suffix_right='${${COLUMNS::=$_p9k__clm}+}}'
	if _p9k_segment_in_use vi_mode || _p9k_segment_in_use prompt_char
	then
		_p9k_prompt_prefix_left+='${${_p9k__keymap::=${KEYMAP:-$_p9k__keymap}}+}'
	fi
	if {
			_p9k_segment_in_use vi_mode && (( $+_POWERLEVEL9K_VI_OVERWRITE_MODE_STRING ))
		} || {
			_p9k_segment_in_use prompt_char && (( _POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE ))
		}
	then
		_p9k_prompt_prefix_left+='${${_p9k__zle_state::=${ZLE_STATE:-$_p9k__zle_state}}+}'
	fi
	_p9k_prompt_prefix_left+='%b%k%f'
	if [[ -n $_p9k_line_segments_right[-1] && $_p9k_line_never_empty_right[-1] == 0 && $ZLE_RPROMPT_INDENT == 0 ]] && _p9k_all_params_eq '_POWERLEVEL9K_*WHITESPACE_BETWEEN_RIGHT_SEGMENTS' ' ' && _p9k_all_params_eq '_POWERLEVEL9K_*RIGHT_RIGHT_WHITESPACE' ' ' && _p9k_all_params_eq '_POWERLEVEL9K_*RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL' '' && ! is-at-least 5.7.2
	then
		_p9k_emulate_zero_rprompt_indent=1
		_p9k_prompt_prefix_left+='${${:-${_p9k__real_zle_rprompt_indent:=$ZLE_RPROMPT_INDENT}${ZLE_RPROMPT_INDENT::=1}${_p9k__ind::=0}}+}'
		_p9k_line_suffix_right[-1]='${_p9k__sss:+${_p9k__sss% }%E}}'
	else
		_p9k_emulate_zero_rprompt_indent=0
		_p9k_prompt_prefix_left+='${${_p9k__ind::=${${ZLE_RPROMPT_INDENT:-1}/#-*/0}}+}'
	fi
	if (( _POWERLEVEL9K_TERM_SHELL_INTEGRATION ))
	then
		_p9k_prompt_prefix_left+=$'%{\e]133;A\a%}'
		_p9k_prompt_suffix_left+=$'%{\e]133;B\a%}'
		if (( $+_z4h_iterm_cmd && _z4h_can_save_restore_screen == 1 ))
		then
			_p9k_prompt_prefix_left+=$'%{\ePtmux;\e\e]133;A\a\e\\%}'
			_p9k_prompt_suffix_left+=$'%{\ePtmux;\e\e]133;B\a\e\\%}'
		fi
	fi
	if (( _POWERLEVEL9K_PROMPT_ADD_NEWLINE_COUNT > 0 ))
	then
		_p9k_t+=${(pl.$_POWERLEVEL9K_PROMPT_ADD_NEWLINE_COUNT..\n.)}
	else
		_p9k_t+=''
	fi
	_p9k_empty_line_idx=$#_p9k_t
	if (( __p9k_ksh_arrays ))
	then
		_p9k_prompt_prefix_left+='${_p9k_t[${_p9k__empty_line_i:-'$#_p9k_t'}-1]}'
	else
		_p9k_prompt_prefix_left+='${_p9k_t[${_p9k__empty_line_i:-'$#_p9k_t'}]}'
	fi
	local -i num_lines=$#_p9k_line_segments_left
	if (( $+terminfo[cuu1] ))
	then
		_p9k_escape $terminfo[cuu1]
		if (( __p9k_ksh_arrays ))
		then
			local scroll=$'${_p9k_t[${_p9k__ruler_i:-1}-1]:+\n'$_p9k__ret'}'
		else
			local scroll=$'${_p9k_t[${_p9k__ruler_i:-1}]:+\n'$_p9k__ret'}'
		fi
		if (( num_lines > 1 ))
		then
			local -i line_index=
			for line_index in {1..$((num_lines-1))}
			do
				scroll='${_p9k__'$line_index-$'\n}'$scroll'${_p9k__'$line_index-$_p9k__ret'}'
			done
		fi
		_p9k_prompt_prefix_left+='%{${_p9k__ipe-'$scroll'}%}'
	fi
	_p9k_get_icon '' RULER_CHAR
	local ruler_char=$_p9k__ret
	_p9k_prompt_length $ruler_char
	(( _p9k__ret == 1 && $#ruler_char == 1 )) || ruler_char=' '
	_p9k_color prompt_ruler BACKGROUND ""
	if [[ -z $_p9k__ret && $ruler_char == ' ' ]]
	then
		local ruler=$'\n'
	else
		_p9k_background $_p9k__ret
		local ruler=%b$_p9k__ret
		_p9k_color prompt_ruler FOREGROUND ""
		_p9k_foreground $_p9k__ret
		ruler+=$_p9k__ret
		[[ $ruler_char == '.' ]] && local sep=','  || local sep='.'
		ruler+='${(pl'$sep'${$((_p9k__clm-_p9k__ind))/#-*/0}'$sep$sep$ruler_char$sep')}%k%f'
		if (( __p9k_ksh_arrays ))
		then
			ruler+='${_p9k_t[$((!_p9k__ind))]}'
		else
			ruler+='${_p9k_t[$((1+!_p9k__ind))]}'
		fi
	fi
	_p9k_t+=$ruler
	_p9k_ruler_idx=$#_p9k_t
	if (( __p9k_ksh_arrays ))
	then
		_p9k_prompt_prefix_left+='${(e)_p9k_t[${_p9k__ruler_i:-'$#_p9k_t'}-1]}'
	else
		_p9k_prompt_prefix_left+='${(e)_p9k_t[${_p9k__ruler_i:-'$#_p9k_t'}]}'
	fi
	(
		_p9k_segment_in_use time && (( _POWERLEVEL9K_TIME_UPDATE_ON_COMMAND ))
	)
	_p9k_reset_on_line_finish=$((!$?))
	_p9k_t+=$_p9k_gap_pre
	_p9k_gap_pre='${(e)_p9k_t['$(($#_p9k_t - __p9k_ksh_arrays))']}'
	_p9k_t+=$_p9k_prompt_prefix_left
	_p9k_prompt_prefix_left='${(e)_p9k_t['$(($#_p9k_t - __p9k_ksh_arrays))']}'
}
_p9k_init_ssh () {
	[[ -n $P9K_SSH ]] && return
	typeset -gix P9K_SSH=0
	if [[ -n $SSH_CLIENT || -n $SSH_TTY || -n $SSH_CONNECTION ]]
	then
		P9K_SSH=1
		return 0
	fi
	(( $+commands[who] )) || return
	local ipv6='(([0-9a-fA-F]+:)|:){2,}[0-9a-fA-F]+'
	local ipv4='([0-9]{1,3}\.){3}[0-9]+'
	local hostname='([.][^. ]+){2}'
	local w
	w="$(who -m 2>/dev/null)"  || w=${(@M)${(f)"$(who 2>/dev/null)"}:#*[[:space:]]${TTY#/dev/}[[:space:]]*}
	[[ $w =~ "\(?($ipv4|$ipv6|$hostname)\)?\$" ]] && P9K_SSH=1
}
_p9k_init_toolbox () {
	[[ -z $P9K_TOOLBOX_NAME ]] || return 0
	if [[ -f /run/.containerenv && -r /run/.containerenv ]]
	then
		local name=(${(Q)${${(@M)${(f)"$(</run/.containerenv)"}:#name=*}#name=}})
		[[ ${#name} -eq 1 && -n ${name[1]} ]] || return 0
		typeset -g P9K_TOOLBOX_NAME=${name[1]}
	elif [[ -n $DISTROBOX_ENTER_PATH && -n $NAME ]]
	then
		local name=${(%):-%m}
		if [[ $name == $NAME* ]]
		then
			typeset -g P9K_TOOLBOX_NAME=$name
		fi
	fi
}
_p9k_init_vars () {
	typeset -gF _p9k__gcloud_last_fetch_ts
	typeset -g _p9k_gcloud_configuration
	typeset -g _p9k_gcloud_account
	typeset -g _p9k_gcloud_project_id
	typeset -g _p9k_gcloud_project_name
	typeset -gi _p9k_term_has_href
	typeset -gi _p9k_vcs_index
	typeset -gi _p9k_vcs_line_index
	typeset -g _p9k_vcs_side
	typeset -ga _p9k_taskwarrior_meta_files
	typeset -ga _p9k_taskwarrior_meta_non_files
	typeset -g _p9k_taskwarrior_meta_sig
	typeset -g _p9k_taskwarrior_data_dir
	typeset -g _p9k__taskwarrior_functional=1
	typeset -ga _p9k_taskwarrior_data_files
	typeset -ga _p9k_taskwarrior_data_non_files
	typeset -g _p9k_taskwarrior_data_sig
	typeset -gA _p9k_taskwarrior_counters
	typeset -gF _p9k_taskwarrior_next_due
	typeset -ga _p9k_asdf_meta_files
	typeset -ga _p9k_asdf_meta_non_files
	typeset -g _p9k_asdf_meta_sig
	typeset -gA _p9k_asdf_plugins
	typeset -gA _p9k_asdf_file_info
	typeset -gA _p9k__asdf_dir2files
	typeset -gA _p9k_asdf_file2versions
	typeset -gA _p9k__read_word_cache
	typeset -gA _p9k__read_pyenv_like_version_file_cache
	typeset -ga _p9k__parent_dirs
	typeset -ga _p9k__parent_mtimes
	typeset -ga _p9k__parent_mtimes_i
	typeset -g _p9k__parent_mtimes_s
	typeset -g _p9k__cwd
	typeset -g _p9k__cwd_a
	typeset -gA _p9k__glob_cache
	typeset -gA _p9k__upsearch_cache
	typeset -g _p9k_timewarrior_dir
	typeset -gi _p9k_timewarrior_dir_mtime
	typeset -gi _p9k_timewarrior_file_mtime
	typeset -g _p9k_timewarrior_file_name
	typeset -gA _p9k__prompt_char_saved
	typeset -g _p9k__worker_pid
	typeset -g _p9k__worker_req_fd
	typeset -g _p9k__worker_resp_fd
	typeset -g _p9k__worker_shell_pid
	typeset -g _p9k__worker_file_prefix
	typeset -gA _p9k__worker_request_map
	typeset -ga _p9k__segment_cond_left
	typeset -ga _p9k__segment_cond_right
	typeset -ga _p9k__segment_val_left
	typeset -ga _p9k__segment_val_right
	typeset -ga _p9k_show_on_command
	typeset -g _p9k__last_buffer
	typeset -ga _p9k__last_commands
	typeset -gi _p9k__fully_initialized
	typeset -gi _p9k__must_restore_prompt
	typeset -gi _p9k__restore_prompt_fd
	typeset -gi _p9k__redraw_fd
	typeset -gi _p9k__can_hide_cursor=$(( $+terminfo[civis] && $+terminfo[cnorm] ))
	typeset -gi _p9k__cursor_hidden
	typeset -gi _p9k__non_hermetic_expansion
	typeset -g _p9k__time
	typeset -g _p9k__date
	typeset -gA _p9k_dumped_instant_prompt_sigs
	typeset -g _p9k__instant_prompt_sig
	typeset -g _p9k__instant_prompt
	typeset -gi _p9k__state_dump_scheduled
	typeset -gi _p9k__state_dump_fd
	typeset -gi _p9k__prompt_idx
	typeset -gi _p9k_reset_on_line_finish
	typeset -gF _p9k__timer_start
	typeset -gi _p9k__status
	typeset -ga _p9k__pipestatus
	typeset -g _p9k__ret
	typeset -g _p9k__cache_key
	typeset -ga _p9k__cache_val
	typeset -g _p9k__cache_stat_meta
	typeset -g _p9k__cache_stat_fprint
	typeset -g _p9k__cache_fprint_key
	typeset -gA _p9k_cache
	typeset -gA _p9k__cache_ephemeral
	typeset -ga _p9k_t
	typeset -g _p9k__n
	typeset -gi _p9k__i
	typeset -g _p9k__bg
	typeset -ga _p9k_left_join
	typeset -ga _p9k_right_join
	typeset -g _p9k__public_ip
	typeset -g _p9k__todo_command
	typeset -g _p9k__todo_file
	typeset -g _p9k__git_dir
	typeset -gA _p9k_git_slow
	typeset -gA _p9k__gitstatus_last
	typeset -gF _p9k__gitstatus_start_time
	typeset -g _p9k__prompt
	typeset -g _p9k__rprompt
	typeset -g _p9k__lprompt
	typeset -g _p9k__prompt_side
	typeset -g _p9k__segment_name
	typeset -gi _p9k__segment_index
	typeset -gi _p9k__line_index
	typeset -g _p9k__refresh_reason
	typeset -gi _p9k__region_active
	typeset -ga _p9k_line_segments_left
	typeset -ga _p9k_line_segments_right
	typeset -ga _p9k_line_prefix_left
	typeset -ga _p9k_line_prefix_right
	typeset -ga _p9k_line_suffix_left
	typeset -ga _p9k_line_suffix_right
	typeset -ga _p9k_line_never_empty_right
	typeset -ga _p9k_line_gap_post
	typeset -g _p9k__xy
	typeset -g _p9k__clm
	typeset -g _p9k__p
	typeset -gi _p9k__x
	typeset -gi _p9k__y
	typeset -gi _p9k__m
	typeset -gi _p9k__d
	typeset -gi _p9k__h
	typeset -gi _p9k__ind
	typeset -g _p9k_gap_pre
	typeset -gi _p9k__ruler_i=3
	typeset -gi _p9k_ruler_idx
	typeset -gi _p9k__empty_line_i=3
	typeset -gi _p9k_empty_line_idx
	typeset -g _p9k_prompt_prefix_left
	typeset -g _p9k_prompt_prefix_right
	typeset -g _p9k_prompt_suffix_left
	typeset -g _p9k_prompt_suffix_right
	typeset -gi _p9k_emulate_zero_rprompt_indent
	typeset -gA _p9k_battery_states
	typeset -g _p9k_os
	typeset -g _p9k_os_icon
	typeset -g _p9k_color1
	typeset -g _p9k_color2
	typeset -g _p9k__s
	typeset -g _p9k__ss
	typeset -g _p9k__sss
	typeset -g _p9k__v
	typeset -g _p9k__c
	typeset -g _p9k__e
	typeset -g _p9k__w
	typeset -gi _p9k__dir_len
	typeset -gi _p9k_num_cpus
	typeset -g _p9k__keymap
	typeset -g _p9k__zle_state
	typeset -g _p9k_uname
	typeset -g _p9k_uname_o
	typeset -g _p9k_uname_m
	typeset -g _p9k_transient_prompt
	typeset -g _p9k__last_prompt_pwd
	typeset -gA _p9k_display_k
	typeset -ga _p9k__display_v
	typeset -gA _p9k__dotnet_stat_cache
	typeset -gA _p9k__dir_stat_cache
	typeset -gi _p9k__expanded
	typeset -gi _p9k__force_must_init
	typeset -g P9K_VISUAL_IDENTIFIER
	typeset -g P9K_CONTENT
	typeset -g P9K_GAP
	typeset -g P9K_PROMPT=regular
}
_p9k_init_vcs () {
	if ! _p9k_segment_in_use vcs || (( ! $#_POWERLEVEL9K_VCS_BACKENDS ))
	then
		(( $+functions[gitstatus_stop_p9k_] )) && gitstatus_stop_p9k_ POWERLEVEL9K
		unset _p9k_preinit
		return
	fi
	_p9k_vcs_info_init
	if (( $+functions[_p9k_preinit] ))
	then
		if (( $+GITSTATUS_DAEMON_PID_POWERLEVEL9K ))
		then
			() {
				trap 'return 130' INT
				{
					gitstatus_start_p9k_ POWERLEVEL9K
				} always {
					trap ':' INT
				}
			}
		fi
		(( $+GITSTATUS_DAEMON_PID_POWERLEVEL9K )) || _p9k__instant_prompt_disabled=1
		return 0
	fi
	(( _POWERLEVEL9K_DISABLE_GITSTATUS )) && return
	(( $_POWERLEVEL9K_VCS_BACKENDS[(I)git] )) || return
	local gitstatus_dir=${_POWERLEVEL9K_GITSTATUS_DIR:-${__p9k_root_dir}/gitstatus}
	typeset -g _p9k_preinit="function _p9k_preinit() {
    (( $+commands[git] )) || { unfunction _p9k_preinit; return 1 }
    [[ \$ZSH_VERSION == ${(q)ZSH_VERSION} ]]                      || return
    [[ -r ${(q)gitstatus_dir}/gitstatus.plugin.zsh ]]             || return
    builtin source ${(q)gitstatus_dir}/gitstatus.plugin.zsh _p9k_ || return
    GITSTATUS_AUTO_INSTALL=${(q)GITSTATUS_AUTO_INSTALL}               GITSTATUS_DAEMON=${(q)GITSTATUS_DAEMON}                         GITSTATUS_CACHE_DIR=${(q)GITSTATUS_CACHE_DIR}                   GITSTATUS_NUM_THREADS=${(q)GITSTATUS_NUM_THREADS}               GITSTATUS_LOG_LEVEL=${(q)GITSTATUS_LOG_LEVEL}                   GITSTATUS_ENABLE_LOGGING=${(q)GITSTATUS_ENABLE_LOGGING}           gitstatus_start_p9k_                                              -s $_POWERLEVEL9K_VCS_STAGED_MAX_NUM                            -u $_POWERLEVEL9K_VCS_UNSTAGED_MAX_NUM                          -d $_POWERLEVEL9K_VCS_UNTRACKED_MAX_NUM                         -c $_POWERLEVEL9K_VCS_CONFLICTED_MAX_NUM                        -m $_POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY                      ${${_POWERLEVEL9K_VCS_RECURSE_UNTRACKED_DIRS:#0}:+-e}           -a POWERLEVEL9K
  }"
	builtin source $gitstatus_dir/gitstatus.plugin.zsh _p9k_ || return
	() {
		trap 'return 130' INT
		{
			gitstatus_start_p9k_ -s $_POWERLEVEL9K_VCS_STAGED_MAX_NUM -u $_POWERLEVEL9K_VCS_UNSTAGED_MAX_NUM -d $_POWERLEVEL9K_VCS_UNTRACKED_MAX_NUM -c $_POWERLEVEL9K_VCS_CONFLICTED_MAX_NUM -m $_POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY ${${_POWERLEVEL9K_VCS_RECURSE_UNTRACKED_DIRS:#0}:+-e} POWERLEVEL9K
		} always {
			trap ':' INT
		}
	}
	(( $+GITSTATUS_DAEMON_PID_POWERLEVEL9K )) || _p9k__instant_prompt_disabled=1
}
_p9k_instant_prompt_cleanup () {
	(( ZSH_SUBSHELL == 0 && ${+__p9k_instant_prompt_active} )) || return 0
	emulate -L zsh -o no_hist_expand -o extended_glob -o no_prompt_bang -o prompt_percent -o no_prompt_subst -o no_aliases -o no_bg_nice -o typeset_silent -o no_rematch_pcre
	(( $+__p9k_trapped )) || {
		local -i __p9k_trapped
		trap : INT
		trap "trap ${(q)__p9k_trapint:--} INT" EXIT
	}
	local -a match reply mbegin mend
	local -i MBEGIN MEND OPTIND
	local MATCH REPLY OPTARG IFS=$' \t\n\0'
	unset __p9k_instant_prompt_active
	exec <&$__p9k_fd_0 >&$__p9k_fd_1 2>&$__p9k_fd_2 {__p9k_fd_0}>&- {__p9k_fd_1}>&- {__p9k_fd_2}>&-
	unset __p9k_fd_0 __p9k_fd_1 __p9k_fd_2
	typeset -gi __p9k_instant_prompt_erased=1
	if (( _z4h_can_save_restore_screen == 1 && __p9k_instant_prompt_sourced >= 35 ))
	then
		-z4h-restore-screen
		unset _z4h_saved_screen
	fi
	print -rn -- $terminfo[rc]${(%):-%b%k%f%s%u}$terminfo[ed]
	if [[ -s $__p9k_instant_prompt_output ]]
	then
		command cat $__p9k_instant_prompt_output 2> /dev/null
		if (( $1 ))
		then
			local _p9k__ret mark="${(e)${PROMPT_EOL_MARK-%B%S%#%s%b}}"
			_p9k_prompt_length $mark
			local -i fill=$((COLUMNS > _p9k__ret ? COLUMNS - _p9k__ret : 0))
			echo -nE - "${(%):-%b%k%f%s%u$mark${(pl.$fill.. .)}$cr%b%k%f%s%u%E}"
		fi
	fi
	zshexit_functions=(${zshexit_functions:#_p9k_instant_prompt_cleanup})
	zmodload -F zsh/files b:zf_rm || return
	local user=${(%):-%n}
	local root_dir=${__p9k_instant_prompt_dump_file:h}
	zf_rm -f -- $__p9k_instant_prompt_output $__p9k_instant_prompt_dump_file{,.zwc} $root_dir/p10k-instant-prompt-$user.zsh{,.zwc} $root_dir/p10k-$user/prompt-*(N) 2> /dev/null
}
_p9k_instant_prompt_precmd_first () {
	emulate -L zsh -o no_hist_expand -o extended_glob -o no_prompt_bang -o prompt_percent -o no_prompt_subst -o no_aliases -o no_bg_nice -o typeset_silent -o no_rematch_pcre
	(( $+__p9k_trapped )) || {
		local -i __p9k_trapped
		trap : INT
		trap "trap ${(q)__p9k_trapint:--} INT" EXIT
	}
	local -a match reply mbegin mend
	local -i MBEGIN MEND OPTIND
	local MATCH REPLY OPTARG IFS=$' \t\n\0'
	[[ $langinfo[CODESET] != (utf|UTF)(-|)8 ]] && _p9k_init_locale && {
		[[ -n $LC_ALL ]] && local LC_ALL=$__p9k_locale  || local LC_CTYPE=$__p9k_locale
	}
	_p9k_instant_prompt_sched_last () {
		(( ${+__p9k_instant_prompt_active} )) || return 0
		_p9k_instant_prompt_cleanup 1
		setopt no_local_options prompt_cr prompt_sp
	}
	zmodload zsh/sched
	sched +0 _p9k_instant_prompt_sched_last
	precmd_functions=(${(@)precmd_functions:#_p9k_instant_prompt_precmd_first})
}
_p9k_iterm2_precmd () {
	builtin zle && return
	if (( _p9k__iterm_cmd )) && [[ -t 1 ]]
	then
		(( _p9k__iterm_cmd == 1 )) && builtin print -n '\e]133;C;\a'
		builtin printf '\e]133;D;%s\a' $1
	fi
	typeset -gi _p9k__iterm_cmd=1
}
_p9k_iterm2_preexec () {
	[[ -t 1 ]] && builtin print -n '\e]133;C;\a'
	typeset -gi _p9k__iterm_cmd=2
}
_p9k_jenv_global_version () {
	_p9k_read_word ${JENV_ROOT:-$HOME/.jenv}/version || _p9k__ret=system
}
_p9k_left_prompt_segment () {
	if ! _p9k_cache_get "$0" "$1" "$2" "$3" "$4" "$_p9k__segment_index"
	then
		_p9k_color $1 BACKGROUND $2
		local bg_color=$_p9k__ret
		_p9k_background $bg_color
		local bg=$_p9k__ret
		_p9k_color $1 FOREGROUND $3
		local fg_color=$_p9k__ret
		_p9k_foreground $fg_color
		local fg=$_p9k__ret
		local style=%b$bg$fg
		local style_=${style//\}/\\\}}
		_p9k_get_icon $1 LEFT_SEGMENT_SEPARATOR
		local sep=$_p9k__ret
		_p9k_escape $_p9k__ret
		local sep_=$_p9k__ret
		_p9k_get_icon $1 LEFT_SUBSEGMENT_SEPARATOR
		_p9k_escape $_p9k__ret
		local subsep_=$_p9k__ret
		local icon_
		if [[ -n $4 ]]
		then
			_p9k_get_icon $1 $4
			_p9k_escape $_p9k__ret
			icon_=$_p9k__ret
		fi
		_p9k_get_icon $1 LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL
		local start_sep=$_p9k__ret
		[[ -n $start_sep ]] && start_sep="%b%k%F{$bg_color}$start_sep"
		_p9k_get_icon $1 LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL $sep
		_p9k_escape $_p9k__ret
		local end_sep_=$_p9k__ret
		_p9k_get_icon $1 WHITESPACE_BETWEEN_LEFT_SEGMENTS ' '
		local space=$_p9k__ret
		_p9k_get_icon $1 LEFT_LEFT_WHITESPACE $space
		local left_space=$_p9k__ret
		[[ $left_space == *%* ]] && left_space+=$style
		_p9k_get_icon $1 LEFT_RIGHT_WHITESPACE $space
		_p9k_escape $_p9k__ret
		local right_space_=$_p9k__ret
		[[ $right_space_ == *%* ]] && right_space_+=$style_
		local s='<_p9k__s>' ss='<_p9k__ss>'
		local -i non_hermetic=0
		local t=$(($#_p9k_t - __p9k_ksh_arrays))
		_p9k_t+=$start_sep$style$left_space
		_p9k_t+=$style
		if [[ -n $fg_color && $fg_color == $bg_color ]]
		then
			if [[ $fg_color == $_p9k_color1 ]]
			then
				_p9k_foreground $_p9k_color2
			else
				_p9k_foreground $_p9k_color1
			fi
			_p9k_t+=%b$bg$_p9k__ret$ss$style$left_space
		else
			_p9k_t+=%b$bg$ss$style$left_space
		fi
		_p9k_t+=%b$bg$s$style$left_space
		local join="_p9k__i>=$_p9k_left_join[$_p9k__segment_index]"
		_p9k_param $1 SELF_JOINED false
		if [[ $_p9k__ret == false ]]
		then
			if (( _p9k__segment_index > $_p9k_left_join[$_p9k__segment_index] ))
			then
				join+="&&_p9k__i<$_p9k__segment_index"
			else
				join=
			fi
		fi
		local p=
		p+="\${_p9k__n::=}"
		p+="\${\${\${_p9k__bg:-0}:#NONE}:-\${_p9k__n::=$((t+1))}}"
		if [[ -n $join ]]
		then
			p+="\${_p9k__n:=\${\${\$(($join)):#0}:+$((t+2))}}"
		fi
		if (( __p9k_sh_glob ))
		then
			p+="\${_p9k__n:=\${\${(M)\${:-x$bg_color}:#x\$_p9k__bg}:+$((t+3))}}"
			p+="\${_p9k__n:=\${\${(M)\${:-x$bg_color}:#x\$${_p9k__bg:-0}}:+$((t+3))}}"
		else
			p+="\${_p9k__n:=\${\${(M)\${:-x$bg_color}:#x(\$_p9k__bg|\${_p9k__bg:-0})}:+$((t+3))}}"
		fi
		p+="\${_p9k__n:=$((t+4))}"
		_p9k_param $1 VISUAL_IDENTIFIER_EXPANSION '${P9K_VISUAL_IDENTIFIER}'
		[[ $_p9k__ret == (|*[^\\])'$('* ]] && non_hermetic=1
		local icon_exp_=${_p9k__ret:+\"$_p9k__ret\"}
		_p9k_param $1 CONTENT_EXPANSION '${P9K_CONTENT}'
		[[ $_p9k__ret == (|*[^\\])'$('* ]] && non_hermetic=1
		local content_exp_=${_p9k__ret:+\"$_p9k__ret\"}
		if [[ ( $icon_exp_ != '"${P9K_VISUAL_IDENTIFIER}"' && $icon_exp_ == *'$'* ) || ( $content_exp_ != '"${P9K_CONTENT}"' && $content_exp_ == *'$'* ) ]]
		then
			p+="\${P9K_VISUAL_IDENTIFIER::=$icon_}"
		fi
		local -i has_icon=-1
		if [[ $icon_exp_ != '"${P9K_VISUAL_IDENTIFIER}"' && $icon_exp_ == *'$'* ]]
		then
			p+='${_p9k__v::='$icon_exp_$style_'}'
		else
			[[ $icon_exp_ == '"${P9K_VISUAL_IDENTIFIER}"' ]] && _p9k__ret=$icon_  || _p9k__ret=$icon_exp_
			if [[ -n $_p9k__ret ]]
			then
				p+="\${_p9k__v::=$_p9k__ret"
				[[ $_p9k__ret == *%* ]] && p+=$style_
				p+="}"
				has_icon=1
			else
				has_icon=0
			fi
		fi
		p+='${_p9k__c::='$content_exp_'}${_p9k__c::=${_p9k__c//'$'\r''}}'
		p+='${_p9k__e::=${${_p9k__'${_p9k__line_index}l${${1#prompt_}%%[A-Z0-9_]#}'+00}:-'
		if (( has_icon == -1 ))
		then
			p+='${${(%):-$_p9k__c%1(l.1.0)}[-1]}${${(%):-$_p9k__v%1(l.1.0)}[-1]}}'
		else
			p+='${${(%):-$_p9k__c%1(l.1.0)}[-1]}'$has_icon'}'
		fi
		p+='}}+}'
		p+='${${_p9k__e:#00}:+${${_p9k_t[$_p9k__n]/'$ss'/$_p9k__ss}/'$s'/$_p9k__s}'
		_p9k_param $1 ICON_BEFORE_CONTENT ''
		if [[ $_p9k__ret != false ]]
		then
			_p9k_param $1 PREFIX ''
			_p9k__ret=${(g::)_p9k__ret}
			_p9k_escape $_p9k__ret
			p+=$_p9k__ret
			[[ $_p9k__ret == *%* ]] && local -i need_style=1  || local -i need_style=0
			if (( has_icon != 0 ))
			then
				_p9k_color $1 VISUAL_IDENTIFIER_COLOR $fg_color
				_p9k_foreground $_p9k__ret
				_p9k__ret=%b$bg$_p9k__ret
				_p9k__ret=${_p9k__ret//\}/\\\}}
				if [[ $_p9k__ret != $style_ ]]
				then
					p+=$_p9k__ret'${_p9k__v}'$style_
				else
					(( need_style )) && p+=$style_
					p+='${_p9k__v}'
				fi
				_p9k_get_icon $1 LEFT_MIDDLE_WHITESPACE ' '
				if [[ -n $_p9k__ret ]]
				then
					_p9k_escape $_p9k__ret
					[[ _p9k__ret == *%* ]] && _p9k__ret+=$style_
					p+='${${(M)_p9k__e:#11}:+'$_p9k__ret'}'
				fi
			elif (( need_style ))
			then
				p+=$style_
			fi
			p+='${_p9k__c}'$style_
		else
			_p9k_param $1 PREFIX ''
			_p9k__ret=${(g::)_p9k__ret}
			_p9k_escape $_p9k__ret
			p+=$_p9k__ret
			[[ $_p9k__ret == *%* ]] && p+=$style_
			p+='${_p9k__c}'$style_
			if (( has_icon != 0 ))
			then
				local -i need_style=0
				_p9k_get_icon $1 LEFT_MIDDLE_WHITESPACE ' '
				if [[ -n $_p9k__ret ]]
				then
					_p9k_escape $_p9k__ret
					[[ $_p9k__ret == *%* ]] && need_style=1
					p+='${${(M)_p9k__e:#11}:+'$_p9k__ret'}'
				fi
				_p9k_color $1 VISUAL_IDENTIFIER_COLOR $fg_color
				_p9k_foreground $_p9k__ret
				_p9k__ret=%b$bg$_p9k__ret
				_p9k__ret=${_p9k__ret//\}/\\\}}
				[[ $_p9k__ret != $style_ || $need_style == 1 ]] && p+=$_p9k__ret
				p+='$_p9k__v'
			fi
		fi
		_p9k_param $1 SUFFIX ''
		_p9k__ret=${(g::)_p9k__ret}
		_p9k_escape $_p9k__ret
		p+=$_p9k__ret
		[[ $_p9k__ret == *%* && -n $right_space_ ]] && p+=$style_
		p+=$right_space_
		p+='${${:-'
		p+="\${_p9k__s::=%F{$bg_color\}$sep_}\${_p9k__ss::=$subsep_}\${_p9k__sss::=%F{$bg_color\}$end_sep_}"
		p+="\${_p9k__i::=$_p9k__segment_index}\${_p9k__bg::=$bg_color}"
		p+='}+}'
		p+='}'
		_p9k_param $1 SHOW_ON_UPGLOB ''
		_p9k_cache_set "$p" $non_hermetic $_p9k__ret
	fi
	if [[ -n $_p9k__cache_val[3] ]]
	then
		_p9k__has_upglob=1
		_p9k_upglob $_p9k__cache_val[3] && return
	fi
	_p9k__non_hermetic_expansion=$_p9k__cache_val[2]
	(( $5 )) && _p9k__ret=\"$7\"  || _p9k_escape $7
	if [[ -z $6 ]]
	then
		_p9k__prompt+="\${\${:-\${P9K_CONTENT::=$_p9k__ret}$_p9k__cache_val[1]"
	else
		_p9k__prompt+="\${\${:-\"$6\"}:+\${\${:-\${P9K_CONTENT::=$_p9k__ret}$_p9k__cache_val[1]}"
	fi
}
_p9k_luaenv_global_version () {
	_p9k_read_word ${LUAENV_ROOT:-$HOME/.luaenv}/version || _p9k__ret=system
}
_p9k_maybe_ignore_git_repo () {
	if [[ $VCS_STATUS_RESULT == ok-* && $VCS_STATUS_WORKDIR == $~_POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN ]]
	then
		VCS_STATUS_RESULT=norepo${VCS_STATUS_RESULT#ok}
	fi
}
_p9k_must_init () {
	(( _POWERLEVEL9K_DISABLE_HOT_RELOAD && !_p9k__force_must_init )) && return 1
	_p9k__force_must_init=0
	local IFS sig
	if [[ -n $_p9k__param_sig ]]
	then
		IFS=$'\2' sig="${(e)_p9k__param_pat}"
		[[ $sig == $_p9k__param_sig ]] && return 1
		_p9k_deinit
	fi
	_p9k__param_pat=$'v134\1'${(q)ZSH_VERSION}$'\1'${(q)ZSH_PATCHLEVEL}$'\1'
	_p9k__param_pat+=$__p9k_force_term_shell_integration$'\1'
	_p9k__param_pat+=$'${#parameters[(I)POWERLEVEL9K_*]}\1${(%):-%n%#}\1$GITSTATUS_LOG_LEVEL\1'
	_p9k__param_pat+=$'$GITSTATUS_ENABLE_LOGGING\1$GITSTATUS_DAEMON\1$GITSTATUS_NUM_THREADS\1'
	_p9k__param_pat+=$'$GITSTATUS_CACHE_DIR\1$GITSTATUS_AUTO_INSTALL\1${ZLE_RPROMPT_INDENT:-1}\1'
	_p9k__param_pat+=$'$__p9k_sh_glob\1$__p9k_ksh_arrays\1$ITERM_SHELL_INTEGRATION_INSTALLED\1'
	_p9k__param_pat+=$'${PROMPT_EOL_MARK-%B%S%#%s%b}\1$+commands[locale]\1$langinfo[CODESET]\1'
	_p9k__param_pat+=$'${(M)VTE_VERSION:#(<1-4602>|4801)}\1$DEFAULT_USER\1$P9K_SSH\1$+commands[uname]\1'
	_p9k__param_pat+=$'$__p9k_root_dir\1$functions[p10k-on-init]\1$functions[p10k-on-pre-prompt]\1'
	_p9k__param_pat+=$'$functions[p10k-on-post-widget]\1$functions[p10k-on-post-prompt]\1'
	_p9k__param_pat+=$'$+commands[git]\1$terminfo[colors]\1${+_z4h_iterm_cmd}\1'
	_p9k__param_pat+=$'$_z4h_can_save_restore_screen'
	local MATCH
	IFS=$'\1' _p9k__param_pat+="${(@)${(@o)parameters[(I)POWERLEVEL9K_*]}:/(#m)*/\${${(q)MATCH}-$IFS\}}"
	IFS=$'\2' _p9k__param_sig="${(e)_p9k__param_pat}"
}
_p9k_nodeenv_version_transform () {
	local dir=${NODENV_ROOT:-$HOME/.nodenv}/versions
	[[ -z $1 || $1 == system ]] && _p9k__ret=$1  && return
	[[ -d $dir/$1 ]] && _p9k__ret=$1  && return
	[[ -d $dir/${1/v} ]] && _p9k__ret=${1/v}  && return
	[[ -d $dir/${1#node-} ]] && _p9k__ret=${1#node-}  && return
	[[ -d $dir/${1#node-v} ]] && _p9k__ret=${1#node-v}  && return
	return 1
}
_p9k_nodenv_global_version () {
	_p9k_read_word ${NODENV_ROOT:-$HOME/.nodenv}/version || _p9k__ret=system
}
_p9k_nvm_ls_current () {
	local node_path=${commands[node]:A}
	[[ -n $node_path ]] || return
	local nvm_dir=${NVM_DIR:A}
	if [[ -n $nvm_dir && $node_path == $nvm_dir/versions/io.js/* ]]
	then
		_p9k_cached_cmd 0 '' iojs --version || return
		_p9k__ret=iojs-v${_p9k__ret#v}
	elif [[ -n $nvm_dir && $node_path == $nvm_dir/* ]]
	then
		_p9k_cached_cmd 0 '' node --version || return
		_p9k__ret=v${_p9k__ret#v}
	else
		_p9k__ret=system
	fi
}
_p9k_nvm_ls_default () {
	local v=default
	local -a seen=($v)
	while [[ -r $NVM_DIR/alias/$v ]]
	do
		local target=
		IFS='' read -r target < $NVM_DIR/alias/$v
		target=${target%$'\r'}
		[[ -z $target ]] && break
		(( $seen[(I)$target] )) && return
		seen+=$target
		v=$target
	done
	case $v in
		(default | N/A) return 1 ;;
		(system | v) _p9k__ret=system
			return 0 ;;
		(iojs-[0-9]*) v=iojs-v${v#iojs-}  ;;
		([0-9]*) v=v$v  ;;
	esac
	if [[ $v == v*.*.* ]]
	then
		if [[ -x $NVM_DIR/versions/node/$v/bin/node || -x $NVM_DIR/$v/bin/node ]]
		then
			_p9k__ret=$v
			return 0
		elif [[ -x $NVM_DIR/versions/io.js/$v/bin/node ]]
		then
			_p9k__ret=iojs-$v
			return 0
		else
			return 1
		fi
	fi
	local -a dirs=()
	case $v in
		(node | node- | stable) dirs=($NVM_DIR/versions/node $NVM_DIR)
			v='(v[1-9]*|v0.*[02468].*)'  ;;
		(unstable) dirs=($NVM_DIR/versions/node $NVM_DIR)
			v='v0.*[13579].*'  ;;
		(iojs*) dirs=($NVM_DIR/versions/io.js)
			v=v${${${v#iojs}#-}#v}'*'  ;;
		(*) dirs=($NVM_DIR/versions/node $NVM_DIR $NVM_DIR/versions/io.js)
			v=v${v#v}'*'  ;;
	esac
	local -a matches=(${^dirs}/${~v}(/N))
	(( $#matches )) || return
	local max path
	for path in ${(Oa)matches}
	do
		[[ ${path:t} == (#b)v(*).(*).(*) ]] || continue
		v=${(j::)${(@l:6::0:)match}}
		[[ $v > $max ]] || continue
		max=$v
		_p9k__ret=${path:t}
		[[ ${path:h:t} != io.js ]] || _p9k__ret=iojs-$_p9k__ret
	done
	[[ -n $max ]]
}
_p9k_on_expand () {
	(( _p9k__expanded && ! ${+__p9k_instant_prompt_active} )) && [[ "${langinfo[CODESET]}" == (utf|UTF)(-|)8 ]] && return
	eval "$__p9k_intro_no_locale"
	if [[ $langinfo[CODESET] != (utf|UTF)(-|)8 ]]
	then
		_p9k_restore_special_params
		if [[ $langinfo[CODESET] != (utf|UTF)(-|)8 ]] && _p9k_init_locale
		then
			if [[ -n $LC_ALL ]]
			then
				_p9k__real_lc_all=$LC_ALL
				LC_ALL=$__p9k_locale
			else
				_p9k__real_lc_ctype=$LC_CTYPE
				LC_CTYPE=$__p9k_locale
			fi
		fi
	fi
	(( _p9k__expanded && ! $+__p9k_instant_prompt_active )) && return
	eval "$__p9k_intro_locale"
	if (( ! _p9k__expanded ))
	then
		if _p9k_should_dump
		then
			sysopen -o cloexec -ru _p9k__state_dump_fd /dev/null
			zle -F $_p9k__state_dump_fd _p9k_do_dump
		fi
		if [[ -z $P9K_TTY || ( $P9K_TTY == old && -n ${_P9K_TTY:#$TTY} ) ]]
		then
			typeset -gx P9K_TTY=old
			if (( _POWERLEVEL9K_NEW_TTY_MAX_AGE_SECONDS < 0 ))
			then
				P9K_TTY=new
			else
				local -a stat
				if zstat -A stat +ctime -- $TTY 2> /dev/null && (( EPOCHREALTIME - stat[1] < _POWERLEVEL9K_NEW_TTY_MAX_AGE_SECONDS ))
				then
					P9K_TTY=new
				fi
			fi
		fi
		typeset -gx _P9K_TTY=$TTY
		__p9k_reset_state=1
		if (( _POWERLEVEL9K_PROMPT_ADD_NEWLINE ))
		then
			if [[ $P9K_TTY == new ]]
			then
				_p9k__empty_line_i=3
				_p9k__display_v[2]=hide
			elif [[ -z $_p9k_transient_prompt && $+functions[p10k-on-post-prompt] == 0 ]]
			then
				_p9k__empty_line_i=3
				_p9k__display_v[2]=print
			else
				unset _p9k__empty_line_i
				_p9k__display_v[2]=show
			fi
		fi
		if (( _POWERLEVEL9K_SHOW_RULER ))
		then
			if [[ $P9K_TTY == new ]]
			then
				_p9k__ruler_i=3
				_p9k__display_v[4]=hide
			elif [[ -z $_p9k_transient_prompt && $+functions[p10k-on-post-prompt] == 0 ]]
			then
				_p9k__ruler_i=3
				_p9k__display_v[4]=print
			else
				unset _p9k__ruler_i
				_p9k__display_v[4]=show
			fi
		fi
		(( _p9k__fully_initialized )) || _p9k_wrap_widgets
	fi
	if (( $+__p9k_instant_prompt_active ))
	then
		_p9k_clear_instant_prompt
		unset __p9k_instant_prompt_active
	fi
	if (( ! _p9k__expanded ))
	then
		_p9k__expanded=1
		(( _p9k__fully_initialized || ! $+functions[p10k-on-init] )) || p10k-on-init
		local pat idx var
		for pat idx var in $_p9k_show_on_command
		do
			_p9k_display_segment $idx $var hide
		done
		(( $+functions[p10k-on-pre-prompt] )) && p10k-on-pre-prompt
		if zle
		then
			local -a P9K_COMMANDS=($_p9k__last_commands)
			local pat idx var
			for pat idx var in $_p9k_show_on_command
			do
				if (( $P9K_COMMANDS[(I)$pat] ))
				then
					_p9k_display_segment $idx $var show
				else
					_p9k_display_segment $idx $var hide
				fi
			done
			if (( $+functions[p10k-on-post-widget] ))
			then
				local -h WIDGET
				unset WIDGET
				p10k-on-post-widget
			fi
		else
			if [[ $_p9k__display_v[2] == print && -n $_p9k_t[_p9k_empty_line_idx] ]]
			then
				print -rnP -- '%b%k%f%E'$_p9k_t[_p9k_empty_line_idx]
			fi
			if [[ $_p9k__display_v[4] == print ]]
			then
				() {
					local ruler=$_p9k_t[_p9k_ruler_idx]
					local -i _p9k__clm=COLUMNS _p9k__ind=${ZLE_RPROMPT_INDENT:-1}
					(( __p9k_ksh_arrays )) && setopt ksh_arrays
					(( __p9k_sh_glob )) && setopt sh_glob
					setopt prompt_subst
					print -rnP -- '%b%k%f%E'$ruler
				}
			fi
		fi
		__p9k_reset_state=0
		_p9k__fully_initialized=1
	fi
}
_p9k_on_widget_deactivate-region () {
	_p9k_check_visual_mode
}
_p9k_on_widget_overwrite-mode () {
	_p9k_check_visual_mode
	__p9k_reset_state=2
}
_p9k_on_widget_send-break () {
	_p9k_on_widget_zle-line-finish int
}
_p9k_on_widget_vi-replace () {
	_p9k_check_visual_mode
	__p9k_reset_state=2
}
_p9k_on_widget_visual-line-mode () {
	_p9k_check_visual_mode
}
_p9k_on_widget_visual-mode () {
	_p9k_check_visual_mode
}
_p9k_on_widget_zle-keymap-select () {
	_p9k_check_visual_mode
	__p9k_reset_state=2
}
_p9k_on_widget_zle-line-finish () {
	(( $+_p9k__line_finished )) && return
	local P9K_PROMPT=transient
	_p9k__line_finished=
	(( _p9k_reset_on_line_finish )) && __p9k_reset_state=2
	(( $+functions[p10k-on-post-prompt] )) && p10k-on-post-prompt
	local -i optimized
	if [[ -n $_p9k_transient_prompt ]]
	then
		if [[ $_POWERLEVEL9K_TRANSIENT_PROMPT == always || $_p9k__cwd == $_p9k__last_prompt_pwd ]]
		then
			optimized=1
			__p9k_reset_state=2
		else
			_p9k__last_prompt_pwd=$_p9k__cwd
		fi
	fi
	if [[ $1 == int ]]
	then
		_p9k__must_restore_prompt=1
		if (( !_p9k__restore_prompt_fd ))
		then
			sysopen -o cloexec -ru _p9k__restore_prompt_fd /dev/null
			zle -F $_p9k__restore_prompt_fd _p9k_restore_prompt
		fi
	fi
	if (( __p9k_reset_state == 2 ))
	then
		if (( optimized ))
		then
			RPROMPT= PROMPT=$_p9k_transient_prompt _p9k_reset_prompt
		else
			_p9k_reset_prompt
		fi
	fi
	_p9k__line_finished='%{%}'
}
_p9k_on_widget_zle-line-init () {
	(( _p9k__cursor_hidden )) || return 0
	_p9k__cursor_hidden=0
	echoti cnorm
}
_p9k_param () {
	local key="_p9k_param ${(pj:\0:)*}"
	_p9k__ret=$_p9k_cache[$key]
	if [[ -n $_p9k__ret ]]
	then
		_p9k__ret[-1,-1]=''
	else
		if [[ ${1//-/_} == (#b)prompt_([a-z0-9_]#)(*) ]]
		then
			local var=_POWERLEVEL9K_${${(U)match[1]}//İ/I}$match[2]_$2
			if (( $+parameters[$var] ))
			then
				_p9k__ret=${(P)var}
			else
				var=_POWERLEVEL9K_${${(U)match[1]%_}//İ/I}_$2
				if (( $+parameters[$var] ))
				then
					_p9k__ret=${(P)var}
				else
					var=_POWERLEVEL9K_$2
					if (( $+parameters[$var] ))
					then
						_p9k__ret=${(P)var}
					else
						_p9k__ret=$3
					fi
				fi
			fi
		else
			local var=_POWERLEVEL9K_$2
			if (( $+parameters[$var] ))
			then
				_p9k__ret=${(P)var}
			else
				_p9k__ret=$3
			fi
		fi
		_p9k_cache[$key]=${_p9k__ret}.
	fi
}
_p9k_parse_aws_config () {
	local cfg=$1
	typeset -ga reply=()
	[[ -f $cfg && -r $cfg ]] || return
	local -a lines
	lines=(${(f)"$(<$cfg)"})  || return
	local line profile
	local -a match mbegin mend
	for line in $lines
	do
		if [[ $line == [[:space:]]#'[default]'[[:space:]]#(|'#'*) ]]
		then
			profile=default
		elif [[ $line == (#b)'[profile'[[:space:]]##([^[:space:]]|[^[:space:]]*[^[:space:]])[[:space:]]#']'[[:space:]]#(|'#'*) ]]
		then
			profile=${(Q)match[1]}
		elif [[ $line == (#b)[[:space:]]#region[[:space:]]#=[[:space:]]#([^[:space:]]|[^[:space:]]*[^[:space:]])[[:space:]]# ]]
		then
			if [[ -n $profile ]]
			then
				reply+=$#profile:$profile:$match[1]
				profile=
			fi
		fi
	done
}
_p9k_parse_buffer () {
	[[ ${2:-0} == <-> ]] || return 2
	local rcquotes
	[[ -o rcquotes ]] && rcquotes=rcquotes
	eval "$__p9k_intro"
	setopt no_nomatch $rcquotes
	typeset -ga P9K_COMMANDS=()
	local -r id='(<->|[[:alpha:]_][[:IDENT:]]#)'
	local -r var="\$$id|\${$id}|\"\$$id\"|\"\${$id}\""
	local -i e ic c=${2:-'1 << 62'}
	local skip n s r state token cmd prev
	local -a aln alp alf v
	if [[ -o interactive_comments ]]
	then
		ic=1
		local tokens=(${(Z+C+)1})
	else
		local tokens=(${(z)1})
	fi
	{
		while (( $#tokens ))
		do
			(( e = $#state ))
			while (( $#tokens == alp[-1] ))
			do
				aln[-1]=()
				alp[-1]=()
				if (( $#tokens == alf[-1] ))
				then
					alf[-1]=()
					(( e = 0 ))
				fi
			done
			while (( c-- > 0 )) || return
			do
				token=$tokens[1]
				tokens[1]=()
				if (( $+galiases[$token] ))
				then
					(( $aln[(eI)p$token] )) && break
					s=$galiases[$token]
					n=p$token
				elif (( e ))
				then
					break
				elif (( $+aliases[$token] ))
				then
					(( $aln[(eI)p$token] )) && break
					s=$aliases[$token]
					n=p$token
				elif [[ $token == ?*.?* ]] && (( $+saliases[${token##*.}] ))
				then
					r=${token##*.}
					(( $aln[(eI)s$r] )) && break
					s=${saliases[$r]%% #}
					n=s$r
				else
					break
				fi
				aln+=$n
				alp+=$#tokens
				[[ $s == *' ' ]] && alf+=$#tokens
				(( ic )) && tokens[1,0]=(${(Z+C+)s})  || tokens[1,0]=(${(z)s})
			done
			case $token in
				('<<'(|-)) state=h
					continue ;;
				(*('`'|['<>=$']'(')*) if [[ $token == ('`'[^'`']##'`'|'"`'[^'`']##'`"'|'$('[^')']##')'|'"$('[^')']##')"'|['<>=']'('[^')']##')') ]]
					then
						s=${${token##('"'|)(['$<>']|)?}%%?('"'|)}
						(( ic )) && tokens+=(';' ${(Z+C+)s})  || tokens+=(';' ${(z)s})
					fi ;;
			esac
			case $state in
				(*r) state[-1]=
					continue ;;
				(a) if [[ $token == $skip ]]
					then
						if [[ $token == '{' ]]
						then
							P9K_COMMANDS+=$cmd
							cmd=
							state=
						else
							skip='{'
						fi
						continue
					else
						state=t
					fi ;&
				(t | p*) if (( $+__p9k_pb_term[$token] ))
					then
						if [[ $token == '()' ]]
						then
							state=
						else
							P9K_COMMANDS+=$cmd
							if [[ $token == '}' ]]
							then
								state=a
								skip=always
							else
								skip=$__p9k_pb_term_skip[$token]
								state=${skip:+s}
							fi
						fi
						cmd=
						continue
					elif [[ $state == t ]]
					then
						continue
					elif [[ $state == *x ]]
					then
						if (( $+__p9k_pb_redirect[$token] ))
						then
							prev=
							state[-1]=r
							continue
						else
							state[-1]=
						fi
					fi ;;
				(s) if [[ $token == $~skip ]]
					then
						state=
					fi
					continue ;;
				(h) while (( $#tokens ))
					do
						(( e = ${tokens[(i)${(Q)token}]} ))
						if [[ $tokens[e-1] == ';' && $tokens[e+1] == ';' ]]
						then
							tokens[1,e]=()
							break
						else
							tokens[1,e]=()
						fi
					done
					while (( $#alp && alp[-1] >= $#tokens ))
					do
						aln[-1]=()
						alp[-1]=()
					done
					state=t
					continue ;;
			esac
			if (( $+__p9k_pb_redirect[${token#<0-255>}] ))
			then
				state+=r
				continue
			fi
			if [[ $token == *'$'* ]]
			then
				if [[ $token == $~var ]]
				then
					n=${${token##[^[:IDENT:]]}%%[^[:IDENT:]]}
					[[ $token == *'"' ]] && v=("${(P)n}")  || v=(${(P)n})
					tokens[1,0]=(${(@qq)v})
					continue
				fi
			fi
			case $state in
				('') if (( $+__p9k_pb_cmd_skip[$token] ))
					then
						skip=$__p9k_pb_cmd_skip[$token]
						[[ $token == '}' ]] && state=a  || state=${skip:+s}
						continue
					fi
					if [[ $token == *=* ]]
					then
						v=${(S)token/#(<->|([[:alpha:]_][[:IDENT:]]#(|'['*[^\\](\\\\)#']')))(|'+')=}
						if (( $#v < $#token ))
						then
							if [[ $v == '(' ]]
							then
								state=s
								skip='\)'
							fi
							continue
						fi
					fi
					: ${token::=${(Q)${~token}}} ;;
				(p2) if [[ -n $prev ]]
					then
						prev=
					else
						: ${token::=${(Q)${~token}}}
						if [[ $token == '{'$~id'}' ]]
						then
							state=p2x
							prev=$token
						else
							state=p
						fi
						continue
					fi ;&
				(p) if [[ -n $prev ]]
					then
						token=$prev
						prev=
					else
						: ${token::=${(Q)${~token}}}
						case $token in
							('{'$~id'}') prev=$token
								state=px
								continue ;;
							([^-]*)  ;;
							(--) state=p1
								continue ;;
							($~skip) state=p2
								continue ;;
							(*) continue ;;
						esac
					fi ;;
				(p1) if [[ -n $prev ]]
					then
						token=$prev
						prev=
					else
						: ${token::=${(Q)${~token}}}
						if [[ $token == '{'$~id'}' ]]
						then
							state=p1x
							prev=$token
							continue
						fi
					fi ;;
			esac
			if (( $+__p9k_pb_precommand[$token] ))
			then
				prev=
				state=p
				skip=$__p9k_pb_precommand[$token]
				cmd+=$token$'\0'
			else
				state=t
				[[ $token == ('(('*'))'|'`'*'`'|'$'*|['<>=']'('*')'|*$'\0'*) ]] || cmd+=$token$'\0'
			fi
		done
	} always {
		[[ $state == (px|p1x) ]] && cmd+=$prev
		P9K_COMMANDS+=$cmd
		P9K_COMMANDS=(${(u)P9K_COMMANDS%$'\0'})
	}
}
_p9k_phpenv_global_version () {
	_p9k_read_word ${PHPENV_ROOT:-$HOME/.phpenv}/version || _p9k__ret=system
}
_p9k_plenv_global_version () {
	_p9k_read_word ${PLENV_ROOT:-$HOME/.plenv}/version || _p9k__ret=system
}
_p9k_precmd () {
	__p9k_new_status=$?
	__p9k_new_pipestatus=($pipestatus)
	trap ":" INT
	[[ -o ksh_arrays ]] && __p9k_ksh_arrays=1  || __p9k_ksh_arrays=0
	[[ -o sh_glob ]] && __p9k_sh_glob=1  || __p9k_sh_glob=0
	_p9k_restore_special_params
	_p9k_precmd_impl
	[[ ${+__p9k_instant_prompt_active} == 0 || -o no_prompt_cr ]] || __p9k_instant_prompt_active=2
	setopt no_local_options no_prompt_bang prompt_percent prompt_subst prompt_cr prompt_sp
	typeset -g __p9k_trapint='_p9k_trapint; return 130'
	trap "$__p9k_trapint" INT
	: ${(%):-%b%k%s%u}
}
_p9k_precmd_first () {
	eval "$__p9k_intro"
	if [[ -n $KITTY_SHELL_INTEGRATION && KITTY_SHELL_INTEGRATION[(wIe)no-prompt-mark] -eq 0 ]]
	then
		KITTY_SHELL_INTEGRATION+=' no-prompt-mark'
		(( $+__p9k_force_term_shell_integration )) || typeset -gri __p9k_force_term_shell_integration=1
	fi
	typeset -ga precmd_functions=(${precmd_functions:#_p9k_precmd_first})
}
_p9k_precmd_impl () {
	eval "$__p9k_intro"
	(( __p9k_enabled )) || return
	if ! zle || [[ -z $_p9k__param_sig ]]
	then
		if zle
		then
			__p9k_new_status=0
			__p9k_new_pipestatus=(0)
		else
			_p9k__must_restore_prompt=0
		fi
		if _p9k_must_init
		then
			local -i instant_prompt_disabled
			if (( !__p9k_configured ))
			then
				__p9k_configured=1
				if [[ -z "${parameters[(I)POWERLEVEL9K_*~POWERLEVEL9K_(MODE|CONFIG_FILE|GITSTATUS_DIR)]}" ]]
				then
					_p9k_can_configure -q
					local -i ret=$?
					if (( ret == 2 && $+__p9k_instant_prompt_active ))
					then
						_p9k_clear_instant_prompt
						unset __p9k_instant_prompt_active
						_p9k_delete_instant_prompt
						zf_rm -f -- $__p9k_dump_file{,.zwc} 2> /dev/null
						() {
							local key
							while true
							do
								[[ -t 2 ]]
								read -t0 -k key || break
							done 2> /dev/null
						}
						_p9k_can_configure -q
						ret=$?
					fi
					if (( ret == 0 ))
					then
						if (( $+commands[git] ))
						then
							(
								local -i pid
								{
									{
										/bin/sh "$__p9k_root_dir"/gitstatus/install < /dev/null &> /dev/null &
									} && pid=$!
									(
										builtin source "$__p9k_root_dir"/internal/wizard.zsh
									)
								} always {
									if (( pid ))
									then
										kill -- $pid 2> /dev/null
										wait -- $pid 2> /dev/null
									fi
								}
							)
						else
							(
								builtin source "$__p9k_root_dir"/internal/wizard.zsh
							)
						fi
						if (( $? ))
						then
							instant_prompt_disabled=1
						else
							builtin source "$__p9k_cfg_path"
							_p9k__force_must_init=1
							_p9k_must_init
						fi
					fi
				fi
			fi
			typeset -gi _p9k__instant_prompt_disabled=instant_prompt_disabled
			_p9k_init
		fi
		if (( _p9k__timer_start ))
		then
			typeset -gF P9K_COMMAND_DURATION_SECONDS=$((EPOCHREALTIME - _p9k__timer_start))
		else
			unset P9K_COMMAND_DURATION_SECONDS
		fi
		_p9k_save_status
		if [[ $_p9k__preexec_cmd == [[:space:]]#(clear([[:space:]]##-(|x)(|T[a-zA-Z0-9-_\'\"]#))#|reset)[[:space:]]# && $_p9k__status == 0 ]]
		then
			P9K_TTY=new
		elif [[ $P9K_TTY == new && $_p9k__fully_initialized == 1 ]] && ! zle
		then
			P9K_TTY=old
		fi
		_p9k__timer_start=0
		_p9k__region_active=0
		unset _p9k__line_finished _p9k__preexec_cmd
		_p9k__keymap=main
		_p9k__zle_state=insert
		(( ++_p9k__prompt_idx ))
		if (( $+_p9k__iterm_cmd ))
		then
			_p9k_iterm2_precmd $__p9k_new_status
		fi
	fi
	_p9k_fetch_cwd
	_p9k__refresh_reason=precmd
	__p9k_reset_state=1
	local -i fast_vcs
	if (( _p9k_vcs_index && $+GITSTATUS_DAEMON_PID_POWERLEVEL9K ))
	then
		if [[ $_p9k__cwd != $~_POWERLEVEL9K_VCS_DISABLED_DIR_PATTERN ]]
		then
			local -F start_time=EPOCHREALTIME
			unset _p9k__vcs
			unset _p9k__vcs_timeout
			local -i _p9k__vcs_called
			_p9k_vcs_gitstatus
			local -i fast_vcs=1
		fi
	fi
	(( $+functions[_p9k_async_segments_compute] )) && _p9k_async_segments_compute
	_p9k__expanded=0
	_p9k_set_prompt
	_p9k__refresh_reason=''
	if [[ $precmd_functions[1] != _p9k_do_nothing && $precmd_functions[(I)_p9k_do_nothing] != 0 ]]
	then
		precmd_functions=(_p9k_do_nothing ${(@)precmd_functions:#_p9k_do_nothing})
	fi
	if [[ $precmd_functions[-1] != _p9k_precmd && $precmd_functions[(I)_p9k_precmd] != 0 ]]
	then
		precmd_functions=(${(@)precmd_functions:#_p9k_precmd} _p9k_precmd)
	fi
	if [[ $preexec_functions[1] != _p9k_preexec1 && $preexec_functions[(I)_p9k_preexec1] != 0 ]]
	then
		preexec_functions=(_p9k_preexec1 ${(@)preexec_functions:#_p9k_preexec1})
	fi
	if [[ $preexec_functions[-1] != _p9k_preexec2 && $preexec_functions[(I)_p9k_preexec2] != 0 ]]
	then
		preexec_functions=(${(@)preexec_functions:#_p9k_preexec2} _p9k_preexec2)
	fi
	if (( fast_vcs && _p9k_vcs_index && $+GITSTATUS_DAEMON_PID_POWERLEVEL9K ))
	then
		if (( $+_p9k__vcs_timeout ))
		then
			(( _p9k__vcs_timeout = _POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS + start_time - EPOCHREALTIME ))
			(( _p9k__vcs_timeout >= 0 )) || (( _p9k__vcs_timeout = 0 ))
			gitstatus_process_results_p9k_ -t $_p9k__vcs_timeout POWERLEVEL9K
		fi
		if (( ! $+_p9k__vcs ))
		then
			local _p9k__prompt _p9k__prompt_side=$_p9k_vcs_side _p9k__segment_name=vcs
			local -i _p9k__has_upglob _p9k__segment_index=_p9k_vcs_index _p9k__line_index=_p9k_vcs_line_index
			_p9k_vcs_render
			typeset -g _p9k__vcs=$_p9k__prompt
		fi
	fi
	_p9k_worker_receive
	__p9k_reset_state=0
}
_p9k_preexec1 () {
	_p9k_restore_special_params
	unset __p9k_trapint
	trap - INT
}
_p9k_preexec2 () {
	typeset -g _p9k__preexec_cmd=$2
	_p9k__timer_start=EPOCHREALTIME
	P9K_TTY=old
	(( ! $+_p9k__iterm_cmd )) || _p9k_iterm2_preexec
}
_p9k_preinit () {
	(( 1 )) || {
		unfunction _p9k_preinit
		return 1
	}
	[[ $ZSH_VERSION == 5.7.1 ]] || return
	[[ -r /Users/sedatkilinc/powerlevel10k/gitstatus/gitstatus.plugin.zsh ]] || return
	builtin source /Users/sedatkilinc/powerlevel10k/gitstatus/gitstatus.plugin.zsh _p9k_ || return
	GITSTATUS_AUTO_INSTALL='' GITSTATUS_DAEMON='' GITSTATUS_CACHE_DIR='' GITSTATUS_NUM_THREADS='' GITSTATUS_LOG_LEVEL='' GITSTATUS_ENABLE_LOGGING='' gitstatus_start_p9k_ -s -1 -u -1 -d -1 -c -1 -m -1 -a POWERLEVEL9K
}
_p9k_print_params () {
	typeset -p -- "$@"
}
_p9k_prompt_anaconda_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${CONDA_PREFIX:-$CONDA_ENV_PATH}'
}
_p9k_prompt_asdf_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${commands[asdf]:-${${+functions[asdf]}:#0}}'
}
_p9k_prompt_aws_eb_env_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[eb]'
}
_p9k_prompt_aws_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${AWS_VAULT:-${AWSUME_PROFILE:-${AWS_PROFILE:-$AWS_DEFAULT_PROFILE}}}'
}
_p9k_prompt_azure_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[az]'
}
_p9k_prompt_battery_async () {
	local prev="${(pj:\0:)_p9k__battery_args}"
	_p9k_prompt_battery_set_args
	[[ "${(pj:\0:)_p9k__battery_args}" == $prev ]] && return 1
	_p9k_print_params _p9k__battery_args
	echo -E - 'reset=2'
}
_p9k_prompt_battery_compute () {
	_p9k_worker_async _p9k_prompt_battery_async _p9k_prompt_battery_sync
}
_p9k_prompt_battery_init () {
	typeset -ga _p9k__battery_args=()
	if [[ $_p9k_os == OSX && $+commands[pmset] == 1 ]]
	then
		_p9k__async_segments_compute+='_p9k_worker_invoke battery _p9k_prompt_battery_compute'
		return
	fi
	if [[ $_p9k_os != (Linux|Android) || -z /sys/class/power_supply/(CMB*|BAT*|battery)/(energy_full|charge_full|charge_counter)(#qN) ]]
	then
		typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${:-}'
	fi
}
_p9k_prompt_battery_set_args () {
	_p9k__battery_args=()
	local state remain
	local -i bat_percent
	case $_p9k_os in
		(OSX) (( $+commands[pmset] )) || return
			local raw_data=${${(Af)"$(pmset -g batt 2>/dev/null)"}[2]}
			[[ $raw_data == *InternalBattery* ]] || return
			remain=${${(s: :)${${(s:; :)raw_data}[3]}}[1]}
			[[ $remain == *no* ]] && remain="..."
			[[ $raw_data =~ '([0-9]+)%' ]] && bat_percent=$match[1]
			case "${${(s:; :)raw_data}[2]}" in
				('charging' | 'finishing charge' | 'AC attached') if (( bat_percent == 100 ))
					then
						state=CHARGED
						remain=''
					else
						state=CHARGING
					fi ;;
				('discharging') (( bat_percent < _POWERLEVEL9K_BATTERY_LOW_THRESHOLD )) && state=LOW  || state=DISCONNECTED  ;;
				(*) state=CHARGED
					remain=''  ;;
			esac ;;
		(Linux | Android) local -a bats=(/sys/class/power_supply/(CMB*|BAT*|battery)/(FN))
			(( $#bats )) || return
			local -i energy_now energy_full power_now
			local -i is_full=1 is_calculating is_charching
			local dir
			for dir in $bats
			do
				local -i pow=0 full=0
				if _p9k_read_file $dir/(energy_full|charge_full|charge_counter)(N)
				then
					(( energy_full += ${full::=_p9k__ret} ))
				fi
				if _p9k_read_file $dir/(power|current)_now(N) && (( $#_p9k__ret < 9 ))
				then
					(( power_now += ${pow::=$_p9k__ret} ))
				fi
				if _p9k_read_file $dir/capacity(N)
				then
					(( energy_now += _p9k__ret * full / 100. + 0.5 ))
				elif _p9k_read_file $dir/(energy|charge)_now(N)
				then
					(( energy_now += _p9k__ret ))
				fi
				_p9k_read_file $dir/status(N) && local bat_status=$_p9k__ret  || continue
				[[ $bat_status != Full ]] && is_full=0
				[[ $bat_status == Charging ]] && is_charching=1
				[[ $bat_status == (Charging|Discharging) && $pow == 0 ]] && is_calculating=1
			done
			(( energy_full )) || return
			bat_percent=$(( 100. * energy_now / energy_full + 0.5 ))
			(( bat_percent > 100 )) && bat_percent=100
			if (( is_full || (bat_percent == 100 && is_charching) ))
			then
				state=CHARGED
			else
				if (( is_charching ))
				then
					state=CHARGING
				elif (( bat_percent < _POWERLEVEL9K_BATTERY_LOW_THRESHOLD ))
				then
					state=LOW
				else
					state=DISCONNECTED
				fi
				if (( power_now > 0 ))
				then
					(( is_charching )) && local -i e=$((energy_full - energy_now))  || local -i e=energy_now
					local -i minutes=$(( 60 * e / power_now ))
					(( minutes > 0 )) && remain=$((minutes/60)):${(l#2##0#)$((minutes%60))}
				elif (( is_calculating ))
				then
					remain="..."
				fi
			fi ;;
		(*) return 0 ;;
	esac
	(( bat_percent >= _POWERLEVEL9K_BATTERY_${state}_HIDE_ABOVE_THRESHOLD )) && return
	local msg="$bat_percent%%"
	[[ $_POWERLEVEL9K_BATTERY_VERBOSE == 1 && -n $remain ]] && msg+=" ($remain)"
	local icon=BATTERY_ICON
	local var=_POWERLEVEL9K_BATTERY_${state}_STAGES
	local -i idx="${#${(@P)var}}"
	if (( idx ))
	then
		(( bat_percent < 100 )) && idx=$((bat_percent * idx / 100 + 1))
		icon=$'\1'"${${(@P)var}[idx]}"
	fi
	local bg=$_p9k_color1
	local var=_POWERLEVEL9K_BATTERY_${state}_LEVEL_BACKGROUND
	local -i idx="${#${(@P)var}}"
	if (( idx ))
	then
		(( bat_percent < 100 )) && idx=$((bat_percent * idx / 100 + 1))
		bg="${${(@P)var}[idx]}"
	fi
	local fg=$_p9k_battery_states[$state]
	local var=_POWERLEVEL9K_BATTERY_${state}_LEVEL_FOREGROUND
	local -i idx="${#${(@P)var}}"
	if (( idx ))
	then
		(( bat_percent < 100 )) && idx=$((bat_percent * idx / 100 + 1))
		fg="${${(@P)var}[idx]}"
	fi
	_p9k__battery_args=(prompt_battery_$state "$bg" "$fg" $icon 0 '' $msg)
}
_p9k_prompt_battery_sync () {
	eval $REPLY
	_p9k_worker_reply $REPLY
}
_p9k_prompt_chruby_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$RUBY_ENGINE'
}
_p9k_prompt_context_init () {
	if [[ $_POWERLEVEL9K_ALWAYS_SHOW_CONTEXT == 0 && -n $DEFAULT_USER && $P9K_SSH == 0 ]]
	then
		if [[ ${(%):-%n} == $DEFAULT_USER ]]
		then
			if (( ! _POWERLEVEL9K_ALWAYS_SHOW_USER ))
			then
				typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${:-}'
			fi
		fi
	fi
}
_p9k_prompt_detect_virt_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[systemd-detect-virt]'
}
_p9k_prompt_direnv_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${DIRENV_DIR:-${precmd_functions[-1]:#_p9k_precmd}}'
}
_p9k_prompt_disk_usage_async () {
	local pct=${${=${(f)"$(df -P $1 2>/dev/null)"}[2]}[5]%%%}
	[[ $pct == <0-100> && $pct != $_p9k__disk_usage_pct ]] || return
	_p9k__disk_usage_pct=$pct
	_p9k__disk_usage_normal=
	_p9k__disk_usage_warning=
	_p9k__disk_usage_critical=
	if (( _p9k__disk_usage_pct >= _POWERLEVEL9K_DISK_USAGE_CRITICAL_LEVEL ))
	then
		_p9k__disk_usage_critical=1
	elif (( _p9k__disk_usage_pct >= _POWERLEVEL9K_DISK_USAGE_WARNING_LEVEL ))
	then
		_p9k__disk_usage_warning=1
	elif (( ! _POWERLEVEL9K_DISK_USAGE_ONLY_WARNING ))
	then
		_p9k__disk_usage_normal=1
	fi
	_p9k_print_params _p9k__disk_usage_pct _p9k__disk_usage_normal _p9k__disk_usage_warning _p9k__disk_usage_critical
	echo -E - 'reset=1'
}
_p9k_prompt_disk_usage_compute () {
	(( $+commands[df] )) || return
	_p9k_worker_async "_p9k_prompt_disk_usage_async ${(q)1}" _p9k_prompt_disk_usage_sync
}
_p9k_prompt_disk_usage_init () {
	typeset -g _p9k__disk_usage_pct=
	typeset -g _p9k__disk_usage_normal=
	typeset -g _p9k__disk_usage_warning=
	typeset -g _p9k__disk_usage_critical=
	_p9k__async_segments_compute+='_p9k_worker_invoke disk_usage "_p9k_prompt_disk_usage_compute ${(q)_p9k__cwd_a}"'
}
_p9k_prompt_disk_usage_sync () {
	eval $REPLY
	_p9k_worker_reply $REPLY
}
_p9k_prompt_docker_machine_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$DOCKER_MACHINE_NAME'
}
_p9k_prompt_dotnet_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[dotnet]'
}
_p9k_prompt_dropbox_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[dropbox-cli]'
}
_p9k_prompt_fvm_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[fvm]'
}
_p9k_prompt_gcloud_async () {
	local gcloud=$1
	$gcloud projects describe $P9K_GCLOUD_PROJECT_ID --configuration=$P9K_GCLOUD_CONFIGURATION --account=$P9K_GCLOUD_ACCOUNT --format='value(name)'
}
_p9k_prompt_gcloud_compute () {
	local gcloud=$1
	P9K_GCLOUD_CONFIGURATION=$2
	P9K_GCLOUD_ACCOUNT=$3
	P9K_GCLOUD_PROJECT_ID=$4
	_p9k_worker_async "_p9k_prompt_gcloud_async ${(q)gcloud}" _p9k_prompt_gcloud_sync
}
_p9k_prompt_gcloud_init () {
	_p9k__async_segments_compute+=_p9k_gcloud_prefetch
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[gcloud]'
}
_p9k_prompt_gcloud_sync () {
	_p9k_worker_reply "_p9k_prompt_gcloud_update ${(q)P9K_GCLOUD_CONFIGURATION} ${(q)P9K_GCLOUD_ACCOUNT} ${(q)P9K_GCLOUD_PROJECT_ID} ${(q)REPLY%$'\n'}"
}
_p9k_prompt_gcloud_update () {
	[[ $1 == $P9K_GCLOUD_CONFIGURATION && $2 == $P9K_GCLOUD_ACCOUNT && $3 == $P9K_GCLOUD_PROJECT_ID && $4 != $P9K_GCLOUD_PROJECT_NAME ]] || return
	[[ -n $4 ]] && P9K_GCLOUD_PROJECT_NAME=$4  || unset P9K_GCLOUD_PROJECT_NAME
	_p9k_gcloud_project_name=$P9K_GCLOUD_PROJECT_NAME
	_p9k__state_dump_scheduled=1
	reset=1
}
_p9k_prompt_go_version_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[go]'
}
_p9k_prompt_goenv_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${commands[goenv]:-${${+functions[goenv]}:#0}}'
}
_p9k_prompt_google_app_cred_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${GOOGLE_APPLICATION_CREDENTIALS:+$commands[jq]}'
}
_p9k_prompt_haskell_stack_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[stack]'
}
_p9k_prompt_java_version_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[java]'
}
_p9k_prompt_jenv_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${commands[jenv]:-${${+functions[jenv]}:#0}}'
}
_p9k_prompt_kubecontext_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[kubectl]'
}
_p9k_prompt_laravel_version_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[php]'
}
_p9k_prompt_length () {
	local -i COLUMNS=1024
	local -i x y=${#1} m
	if (( y ))
	then
		while (( ${${(%):-$1%$y(l.1.0)}[-1]} ))
		do
			x=y
			(( y *= 2 ))
		done
		while (( y > x + 1 ))
		do
			(( m = x + (y - x) / 2 ))
			(( ${${(%):-$1%$m(l.x.y)}[-1]} = m ))
		done
	fi
	typeset -g _p9k__ret=$x
}
_p9k_prompt_load_async () {
	local load="$(sysctl -n vm.loadavg 2>/dev/null)"  || return
	load=${${(A)=load}[_POWERLEVEL9K_LOAD_WHICH+1]//,/.}
	[[ $load == <->(|.<->) && $load != $_p9k__load_value ]] || return
	_p9k__load_value=$load
	_p9k__load_normal=
	_p9k__load_warning=
	_p9k__load_critical=
	local -F pct='100. * _p9k__load_value / _p9k_num_cpus'
	if (( pct > _POWERLEVEL9K_LOAD_CRITICAL_PCT ))
	then
		_p9k__load_critical=1
	elif (( pct > _POWERLEVEL9K_LOAD_WARNING_PCT ))
	then
		_p9k__load_warning=1
	else
		_p9k__load_normal=1
	fi
	_p9k_print_params _p9k__load_value _p9k__load_normal _p9k__load_warning _p9k__load_critical
	echo -E - 'reset=1'
}
_p9k_prompt_load_compute () {
	(( $+commands[sysctl] )) || return
	_p9k_worker_async _p9k_prompt_load_async _p9k_prompt_load_sync
}
_p9k_prompt_load_init () {
	if [[ $_p9k_os == (OSX|BSD) ]]
	then
		typeset -g _p9k__load_value=
		typeset -g _p9k__load_normal=
		typeset -g _p9k__load_warning=
		typeset -g _p9k__load_critical=
		_p9k__async_segments_compute+='_p9k_worker_invoke load _p9k_prompt_load_compute'
	elif [[ ! -r /proc/loadavg ]]
	then
		typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${:-}'
	fi
}
_p9k_prompt_load_sync () {
	eval $REPLY
	_p9k_worker_reply $REPLY
}
_p9k_prompt_luaenv_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${commands[luaenv]:-${${+functions[luaenv]}:#0}}'
}
_p9k_prompt_midnight_commander_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$MC_TMPDIR'
}
_p9k_prompt_net_iface_async () {
	local iface ip line var
	typeset -a iface2ip ips ifaces
	if (( $+commands[ifconfig] ))
	then
		for line in ${(f)"$(command ifconfig 2>/dev/null)"}
		do
			if [[ $line == (#b)([^[:space:]]##):[[:space:]]##flags=([[:xdigit:]]##)'<'* ]]
			then
				[[ $match[2] == *[13579bdfBDF] ]] && iface=$match[1]  || iface=
			elif [[ -n $iface && $line == (#b)[[:space:]]##inet[[:space:]]##([0-9.]##)* ]]
			then
				iface2ip+=($iface $match[1])
				iface=
			fi
		done
	elif (( $+commands[ip] ))
	then
		for line in ${(f)"$(command ip -4 a show 2>/dev/null)"}
		do
			if [[ $line == (#b)<->:[[:space:]]##([^:]##):[[:space:]]##\<([^\>]#)\>* ]]
			then
				[[ ,$match[2], == *,UP,* ]] && iface=$match[1]  || iface=
			elif [[ -n $iface && $line == (#b)[[:space:]]##inet[[:space:]]##([0-9.]##)* ]]
			then
				iface2ip+=($iface $match[1])
				iface=
			fi
		done
	fi
	if _p9k_prompt_net_iface_match $_POWERLEVEL9K_PUBLIC_IP_VPN_INTERFACE
	then
		local public_ip_vpn=1
		local public_ip_not_vpn=
	else
		local public_ip_vpn=
		local public_ip_not_vpn=1
	fi
	if _p9k_prompt_net_iface_match $_POWERLEVEL9K_IP_INTERFACE
	then
		local ip_ip=$ips[1] ip_interface=$ifaces[1] ip_timestamp=$EPOCHREALTIME
		local ip_tx_bytes ip_rx_bytes ip_tx_rate ip_rx_rate
		if [[ $_p9k_os == (Linux|Android) ]]
		then
			if [[ -r /sys/class/net/$ifaces[1]/statistics/tx_bytes && -r /sys/class/net/$ifaces[1]/statistics/rx_bytes ]]
			then
				_p9k_read_file /sys/class/net/$ifaces[1]/statistics/tx_bytes && [[ $_p9k__ret == <-> ]] && ip_tx_bytes=$_p9k__ret  && _p9k_read_file /sys/class/net/$ifaces[1]/statistics/rx_bytes && [[ $_p9k__ret == <-> ]] && ip_rx_bytes=$_p9k__ret  || {
					ip_tx_bytes=
					ip_rx_bytes=
				}
			fi
		elif [[ $_p9k_os == (BSD|OSX) && $+commands[netstat] == 1 ]]
		then
			local -a lines
			if lines=(${(f)"$(netstat -inbI $ifaces[1])"})
			then
				local header=($=lines[1])
				local -i rx_idx=$header[(Ie)Ibytes]
				local -i tx_idx=$header[(Ie)Obytes]
				if (( rx_idx && tx_idx ))
				then
					ip_tx_bytes=0
					ip_rx_bytes=0
					for line in ${lines:1}
					do
						(( ip_rx_bytes += ${line[(w)rx_idx]} ))
						(( ip_tx_bytes += ${line[(w)tx_idx]} ))
					done
				fi
			fi
		fi
		if [[ -n $ip_rx_bytes ]]
		then
			if [[ $ip_ip == $P9K_IP_IP && $ifaces[1] == $P9K_IP_INTERFACE ]]
			then
				local -F t='ip_timestamp - _p9__ip_timestamp'
				if (( t <= 0 ))
				then
					ip_tx_rate=${P9K_IP_TX_RATE:-0 B/s}
					ip_rx_rate=${P9K_IP_RX_RATE:-0 B/s}
				else
					_p9k_human_readable_bytes $(((ip_tx_bytes - P9K_IP_TX_BYTES) / t))
					[[ $_p9k__ret == *B ]] && ip_tx_rate="$_p9k__ret[1,-2] B/s"  || ip_tx_rate="$_p9k__ret[1,-2] $_p9k__ret[-1]iB/s"
					_p9k_human_readable_bytes $(((ip_rx_bytes - P9K_IP_RX_BYTES) / t))
					[[ $_p9k__ret == *B ]] && ip_rx_rate="$_p9k__ret[1,-2] B/s"  || ip_rx_rate="$_p9k__ret[1,-2] $_p9k__ret[-1]iB/s"
				fi
			else
				ip_tx_rate='0 B/s'
				ip_rx_rate='0 B/s'
			fi
		fi
	else
		local ip_ip= ip_interface= ip_tx_bytes= ip_rx_bytes= ip_tx_rate= ip_rx_rate= ip_timestamp=
	fi
	if _p9k_prompt_net_iface_match $_POWERLEVEL9K_VPN_IP_INTERFACE
	then
		if (( _POWERLEVEL9K_VPN_IP_SHOW_ALL ))
		then
			local vpn_ip_ips=($ips)
		else
			local vpn_ip_ips=($ips[1])
		fi
	else
		local vpn_ip_ips=()
	fi
	[[ $_p9k__public_ip_vpn == $public_ip_vpn && $_p9k__public_ip_not_vpn == $public_ip_not_vpn && $P9K_IP_IP == $ip_ip && $P9K_IP_INTERFACE == $ip_interface && $P9K_IP_TX_BYTES == $ip_tx_bytes && $P9K_IP_RX_BYTES == $ip_rx_bytes && $P9K_IP_TX_RATE == $ip_tx_rate && $P9K_IP_RX_RATE == $ip_rx_rate && "$_p9k__vpn_ip_ips" == "$vpn_ip_ips" ]] && return 1
	if [[ "$_p9k__vpn_ip_ips" == "$vpn_ip_ips" ]]
	then
		echo -n 0
	else
		echo -n 1
	fi
	_p9k__public_ip_vpn=$public_ip_vpn
	_p9k__public_ip_not_vpn=$public_ip_not_vpn
	P9K_IP_IP=$ip_ip
	P9K_IP_INTERFACE=$ip_interface
	if [[ -n $ip_tx_bytes && -n $P9K_IP_TX_BYTES ]]
	then
		P9K_IP_TX_BYTES_DELTA=$((ip_tx_bytes - P9K_IP_TX_BYTES))
	else
		P9K_IP_TX_BYTES_DELTA=
	fi
	if [[ -n $ip_rx_bytes && -n $P9K_IP_RX_BYTES ]]
	then
		P9K_IP_RX_BYTES_DELTA=$((ip_rx_bytes - P9K_IP_RX_BYTES))
	else
		P9K_IP_RX_BYTES_DELTA=
	fi
	P9K_IP_TX_BYTES=$ip_tx_bytes
	P9K_IP_RX_BYTES=$ip_rx_bytes
	P9K_IP_TX_RATE=$ip_tx_rate
	P9K_IP_RX_RATE=$ip_rx_rate
	_p9__ip_timestamp=$ip_timestamp
	_p9k__vpn_ip_ips=($vpn_ip_ips)
	_p9k_print_params _p9k__public_ip_vpn _p9k__public_ip_not_vpn P9K_IP_IP P9K_IP_INTERFACE P9K_IP_TX_BYTES P9K_IP_RX_BYTES P9K_IP_TX_BYTES_DELTA P9K_IP_RX_BYTES_DELTA P9K_IP_TX_RATE P9K_IP_RX_RATE _p9__ip_timestamp _p9k__vpn_ip_ips
	echo -E - 'reset=1'
}
_p9k_prompt_net_iface_compute () {
	_p9k_worker_async _p9k_prompt_net_iface_async _p9k_prompt_net_iface_sync
}
_p9k_prompt_net_iface_init () {
	typeset -g _p9k__public_ip_vpn=
	typeset -g _p9k__public_ip_not_vpn=
	typeset -g P9K_IP_IP=
	typeset -g P9K_IP_INTERFACE=
	typeset -g P9K_IP_TX_BYTES=
	typeset -g P9K_IP_RX_BYTES=
	typeset -g P9K_IP_TX_BYTES_DELTA=
	typeset -g P9K_IP_RX_BYTES_DELTA=
	typeset -g P9K_IP_TX_RATE=
	typeset -g P9K_IP_RX_RATE=
	typeset -g _p9__ip_timestamp=
	typeset -g _p9k__vpn_ip_ips=()
	[[ -z $_POWERLEVEL9K_PUBLIC_IP_VPN_INTERFACE ]] && _p9k__public_ip_not_vpn=1
	_p9k__async_segments_compute+='_p9k_worker_invoke net_iface _p9k_prompt_net_iface_compute'
}
_p9k_prompt_net_iface_match () {
	local iface_regex="^($1)\$" iface ip
	ips=()
	ifaces=()
	for iface ip in "${(@)iface2ip}"
	do
		[[ $iface =~ $iface_regex ]] || continue
		ifaces+=$iface
		ips+=$ip
	done
	return $(($#ips == 0))
}
_p9k_prompt_net_iface_sync () {
	local -i vpn_ip_changed=$REPLY[1]
	REPLY[1]=""
	eval $REPLY
	(( vpn_ip_changed )) && REPLY+='; _p9k_vpn_ip_render'
	_p9k_worker_reply $REPLY
}
_p9k_prompt_nix_shell_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${IN_NIX_SHELL:#0}'
}
_p9k_prompt_nnn_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${NNNLVL:#0}'
}
_p9k_prompt_node_version_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[node]'
}
_p9k_prompt_nodeenv_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$NODE_VIRTUAL_ENV'
}
_p9k_prompt_nodenv_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${commands[nodenv]:-${${+functions[nodenv]}:#0}}'
}
_p9k_prompt_nordvpn_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[nordvpn]'
}
_p9k_prompt_nvm_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${commands[nvm]:-${${+functions[nvm]}:#0}}'
}
_p9k_prompt_openfoam_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$WM_PROJECT_VERSION'
}
_p9k_prompt_overflow_bug () {
	[[ $ZSH_PATCHLEVEL =~ '^zsh-5\.4\.2-([0-9]+)-' ]] && return $(( match[1] < 159 ))
	[[ $ZSH_PATCHLEVEL =~ '^zsh-5\.7\.1-([0-9]+)-' ]] && return $(( match[1] >= 50 ))
	is-at-least 5.5 && ! is-at-least 5.7.2
}
_p9k_prompt_php_version_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[php]'
}
_p9k_prompt_phpenv_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${commands[phpenv]:-${${+functions[phpenv]}:#0}}'
}
_p9k_prompt_plenv_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${commands[plenv]:-${${+functions[plenv]}:#0}}'
}
_p9k_prompt_proxy_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$all_proxy$http_proxy$https_proxy$ftp_proxy$ALL_PROXY$HTTP_PROXY$HTTPS_PROXY$FTP_PROXY'
}
_p9k_prompt_public_ip_async () {
	local ip method
	local -F start=EPOCHREALTIME
	local -F next='start + 5'
	for method in $_POWERLEVEL9K_PUBLIC_IP_METHODS $_POWERLEVEL9K_PUBLIC_IP_METHODS
	do
		case $method in
			(dig) if (( $+commands[dig] ))
				then
					ip="$(dig +tries=1 +short -4 A myip.opendns.com @resolver1.opendns.com 2>/dev/null)"
					[[ $ip == ';'* ]] && ip=
					if [[ -z $ip ]]
					then
						ip="$(dig +tries=1 +short -6 AAAA myip.opendns.com @resolver1.opendns.com 2>/dev/null)"
						[[ $ip == ';'* ]] && ip=
					fi
				fi ;;
			(curl) if (( $+commands[curl] ))
				then
					ip="$(curl --max-time 5 -w '\n' "$_POWERLEVEL9K_PUBLIC_IP_HOST" 2>/dev/null)"
				fi ;;
			(wget) if (( $+commands[wget] ))
				then
					ip="$(wget -T 5 -qO- "$_POWERLEVEL9K_PUBLIC_IP_HOST" 2>/dev/null)"
				fi ;;
		esac
		[[ $ip =~ '^[0-9a-f.:]+$' ]] || ip=''
		if [[ -n $ip ]]
		then
			next=$((start + _POWERLEVEL9K_PUBLIC_IP_TIMEOUT))
			break
		fi
	done
	_p9k__public_ip_next_time=$next
	_p9k_print_params _p9k__public_ip_next_time
	[[ $_p9k__public_ip == $ip ]] && return
	_p9k__public_ip=$ip
	_p9k_print_params _p9k__public_ip
	echo -E - 'reset=1'
}
_p9k_prompt_public_ip_compute () {
	(( EPOCHREALTIME >= _p9k__public_ip_next_time )) || return
	_p9k_worker_async _p9k_prompt_public_ip_async _p9k_prompt_public_ip_sync
}
_p9k_prompt_public_ip_init () {
	typeset -g _p9k__public_ip=
	typeset -gF _p9k__public_ip_next_time=0
	_p9k__async_segments_compute+='_p9k_worker_invoke public_ip _p9k_prompt_public_ip_compute'
}
_p9k_prompt_public_ip_sync () {
	eval $REPLY
	_p9k_worker_reply $REPLY
}
_p9k_prompt_pyenv_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${commands[pyenv]:-${${+functions[pyenv]}:#0}}'
}
_p9k_prompt_ram_async () {
	local -F free_bytes
	case $_p9k_os in
		(OSX) (( $+commands[vm_stat] )) || return
			local stat && stat="$(vm_stat 2>/dev/null)"  || return
			[[ $stat =~ 'Pages free:[[:space:]]+([0-9]+)' ]] || return
			(( free_bytes += match[1] ))
			[[ $stat =~ 'Pages inactive:[[:space:]]+([0-9]+)' ]] || return
			(( free_bytes += match[1] ))
			if (( ! $+_p9k__ram_pagesize ))
			then
				local p
				(( $+commands[pagesize] )) && p=$(pagesize 2>/dev/null)  && [[ $p == <1-> ]] || p=4096
				typeset -gi _p9k__ram_pagesize=p
				_p9k_print_params _p9k__ram_pagesize
			fi
			(( free_bytes *= _p9k__ram_pagesize )) ;;
		(BSD) local stat && stat="$(grep -F 'avail memory' /var/run/dmesg.boot 2>/dev/null)"  || return
			free_bytes=${${(A)=stat}[4]}  ;;
		(*) [[ -r /proc/meminfo ]] || return
			local stat && stat="$(</proc/meminfo)"  || return
			[[ $stat == (#b)*(MemAvailable:|MemFree:)[[:space:]]#(<->)* ]] || return
			free_bytes=$(( $match[2] * 1024 ))  ;;
	esac
	_p9k_human_readable_bytes $free_bytes
	[[ $_p9k__ret != $_p9k__ram_free ]] || return
	_p9k__ram_free=$_p9k__ret
	_p9k_print_params _p9k__ram_free
	echo -E - 'reset=1'
}
_p9k_prompt_ram_compute () {
	_p9k_worker_async _p9k_prompt_ram_async _p9k_prompt_ram_sync
}
_p9k_prompt_ram_init () {
	if [[ ( $_p9k_os == OSX && $+commands[vm_stat] == 0 ) || ( $_p9k_os == BSD && ! -r /var/run/dmesg.boot ) || ( $_p9k_os != (OSX|BSD) && ! -r /proc/meminfo ) ]]
	then
		typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${:-}'
		return
	fi
	typeset -g _p9k__ram_free=
	_p9k__async_segments_compute+='_p9k_worker_invoke ram _p9k_prompt_ram_compute'
}
_p9k_prompt_ram_sync () {
	eval $REPLY
	_p9k_worker_reply $REPLY
}
_p9k_prompt_ranger_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$RANGER_LEVEL'
}
_p9k_prompt_rbenv_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${commands[rbenv]:-${${+functions[rbenv]}:#0}}'
}
_p9k_prompt_rust_version_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[rustc]'
}
_p9k_prompt_rvm_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${commands[rvm-prompt]:-${${+functions[rvm-prompt]}:#0}}'
}
_p9k_prompt_scalaenv_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${commands[scalaenv]:-${${+functions[scalaenv]}:#0}}'
}
_p9k_prompt_segment () {
	"_p9k_${_p9k__prompt_side}_prompt_segment" "$@"
}
_p9k_prompt_ssh_init () {
	if (( ! P9K_SSH ))
	then
		typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${:-}'
	fi
}
_p9k_prompt_swap_async () {
	local -F used_bytes
	if [[ "$_p9k_os" == "OSX" ]]
	then
		(( $+commands[sysctl] )) || return
		[[ "$(sysctl vm.swapusage 2>/dev/null)" =~ "used = ([0-9,.]+)([A-Z]+)" ]] || return
		used_bytes=${match[1]//,/.}
		case ${match[2]} in
			('K') (( used_bytes *= 1024 )) ;;
			('M') (( used_bytes *= 1048576 )) ;;
			('G') (( used_bytes *= 1073741824 )) ;;
			('T') (( used_bytes *= 1099511627776 )) ;;
			(*) return 0 ;;
		esac
	else
		local meminfo && meminfo="$(grep -F 'Swap' /proc/meminfo 2>/dev/null)"  || return
		[[ $meminfo =~ 'SwapTotal:[[:space:]]+([0-9]+)' ]] || return
		(( used_bytes+=match[1] ))
		[[ $meminfo =~ 'SwapFree:[[:space:]]+([0-9]+)' ]] || return
		(( used_bytes-=match[1] ))
		(( used_bytes *= 1024 ))
	fi
	(( used_bytes >= 0 || (used_bytes = 0) ))
	_p9k_human_readable_bytes $used_bytes
	[[ $_p9k__ret != $_p9k__swap_used ]] || return
	_p9k__swap_used=$_p9k__ret
	_p9k_print_params _p9k__swap_used
	echo -E - 'reset=1'
}
_p9k_prompt_swap_compute () {
	_p9k_worker_async _p9k_prompt_swap_async _p9k_prompt_swap_sync
}
_p9k_prompt_swap_init () {
	if [[ ( $_p9k_os == OSX && $+commands[sysctl] == 0 ) || ( $_p9k_os != OSX && ! -r /proc/meminfo ) ]]
	then
		typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${:-}'
		return
	fi
	typeset -g _p9k__swap_used=
	_p9k__async_segments_compute+='_p9k_worker_invoke swap _p9k_prompt_swap_compute'
}
_p9k_prompt_swap_sync () {
	eval $REPLY
	_p9k_worker_reply $REPLY
}
_p9k_prompt_swift_version_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[swift]'
}
_p9k_prompt_taskwarrior_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${commands[task]:+$_p9k__taskwarrior_functional}'
}
_p9k_prompt_terraform_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[terraform]'
}
_p9k_prompt_terraform_version_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[terraform]'
}
_p9k_prompt_time_async () {
	sleep 1 || true
}
_p9k_prompt_time_compute () {
	_p9k_worker_async _p9k_prompt_time_async _p9k_prompt_time_sync
}
_p9k_prompt_time_init () {
	(( _POWERLEVEL9K_EXPERIMENTAL_TIME_REALTIME )) || return
	_p9k__async_segments_compute+='_p9k_worker_invoke time _p9k_prompt_time_compute'
}
_p9k_prompt_time_sync () {
	_p9k_worker_reply '_p9k_worker_invoke _p9k_prompt_time_compute _p9k_prompt_time_compute; reset=1'
}
_p9k_prompt_timewarrior_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$commands[timew]'
}
_p9k_prompt_todo_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$_p9k__todo_file'
}
_p9k_prompt_toolbox_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$P9K_TOOLBOX_NAME'
}
_p9k_prompt_user_init () {
	if [[ $_POWERLEVEL9K_ALWAYS_SHOW_USER == 0 && "${(%):-%n}" == $DEFAULT_USER ]]
	then
		typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${:-}'
	fi
}
_p9k_prompt_vim_shell_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$VIMRUNTIME'
}
_p9k_prompt_virtualenv_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$VIRTUAL_ENV'
}
_p9k_prompt_wifi_async () {
	local airport=/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport
	local last_tx_rate ssid link_auth rssi noise bars on out line v state iface
	{
		if [[ -x $airport ]]
		then
			out="$($airport -I)"  || return 0
			for line in ${${${(f)out}##[[:space:]]#}%%[[:space:]]#}
			do
				v=${line#*: }
				case $line[1,-$#v-3] in
					(agrCtlRSSI) rssi=$v  ;;
					(agrCtlNoise) noise=$v  ;;
					(state) state=$v  ;;
					(lastTxRate) last_tx_rate=$v  ;;
					(link\ auth) link_auth=$v  ;;
					(SSID) ssid=$v  ;;
				esac
			done
			[[ $state == running && $rssi == (0|-<->) && $noise == (0|-<->) ]] || return 0
		elif [[ -r /proc/net/wireless && -n $commands[iw] ]]
		then
			local -a lines
			lines=(${${(f)"$(</proc/net/wireless)"}:#*\|*})  || return 0
			(( $#lines == 1 )) || return 0
			local parts=(${=lines[1]})
			iface=${parts[1]%:}
			state=${parts[2]}
			rssi=${parts[4]%.*}
			noise=${parts[5]%.*}
			[[ -n $iface && $state == 0## && $rssi == (0|-<->) && $noise == (0|-<->) ]] || return 0
			lines=(${(f)"$(command iw dev $iface link)"})  || return 0
			local -a match mbegin mend
			for line in $lines
			do
				if [[ $line == (#b)[[:space:]]#SSID:[[:space:]]##(*) ]]
				then
					ssid=$match[1]
				elif [[ $line == (#b)[[:space:]]#'tx bitrate:'[[:space:]]##([^[:space:]]##)' MBit/s'* ]]
				then
					last_tx_rate=$match[1]
					[[ $last_tx_rate == <->.<-> ]] && last_tx_rate=${${last_tx_rate%%0#}%.}
				fi
			done
			[[ -n $ssid && -n $last_tx_rate ]] || return 0
		else
			return 0
		fi
		local -i snr_margin='rssi - noise'
		if (( snr_margin >= 40 ))
		then
			bars=4
		elif (( snr_margin >= 25 ))
		then
			bars=3
		elif (( snr_margin >= 15 ))
		then
			bars=2
		elif (( snr_margin >= 10 ))
		then
			bars=1
		else
			bars=0
		fi
		on=1
	} always {
		if (( ! on ))
		then
			rssi=
			noise=
			ssid=
			last_tx_rate=
			bars=
			link_auth=
		fi
		if [[ $_p9k__wifi_on != $on || $P9K_WIFI_LAST_TX_RATE != $last_tx_rate || $P9K_WIFI_SSID != $ssid || $P9K_WIFI_LINK_AUTH != $link_auth || $P9K_WIFI_RSSI != $rssi || $P9K_WIFI_NOISE != $noise || $P9K_WIFI_BARS != $bars ]]
		then
			_p9k__wifi_on=$on
			P9K_WIFI_LAST_TX_RATE=$last_tx_rate
			P9K_WIFI_SSID=$ssid
			P9K_WIFI_LINK_AUTH=$link_auth
			P9K_WIFI_RSSI=$rssi
			P9K_WIFI_NOISE=$noise
			P9K_WIFI_BARS=$bars
			_p9k_print_params _p9k__wifi_on P9K_WIFI_LAST_TX_RATE P9K_WIFI_SSID P9K_WIFI_LINK_AUTH P9K_WIFI_RSSI P9K_WIFI_NOISE P9K_WIFI_BARS
			echo -E - 'reset=1'
		fi
	}
}
_p9k_prompt_wifi_compute () {
	_p9k_worker_async _p9k_prompt_wifi_async _p9k_prompt_wifi_sync
}
_p9k_prompt_wifi_init () {
	if [[ -x /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport || ( -r /proc/net/wireless && -n $commands[iw] ) ]]
	then
		typeset -g _p9k__wifi_on=
		typeset -g P9K_WIFI_LAST_TX_RATE=
		typeset -g P9K_WIFI_SSID=
		typeset -g P9K_WIFI_LINK_AUTH=
		typeset -g P9K_WIFI_RSSI=
		typeset -g P9K_WIFI_NOISE=
		typeset -g P9K_WIFI_BARS=
		_p9k__async_segments_compute+='_p9k_worker_invoke wifi _p9k_prompt_wifi_compute'
	else
		typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='${:-}'
	fi
}
_p9k_prompt_wifi_sync () {
	if [[ -n $REPLY ]]
	then
		eval $REPLY
		_p9k_worker_reply $REPLY
	fi
}
_p9k_prompt_xplr_init () {
	typeset -g "_p9k__segment_cond_${_p9k__prompt_side}[_p9k__segment_index]"='$XPLR_PID'
}
_p9k_pyenv_compute () {
	unset P9K_PYENV_PYTHON_VERSION _p9k__pyenv_version
	local v=${(j.:.)${(@)${(s.:.)PYENV_VERSION}#python-}}
	if [[ -n $v ]]
	then
		(( ${_POWERLEVEL9K_PYENV_SOURCES[(I)shell]} )) || return
	else
		(( ${_POWERLEVEL9K_PYENV_SOURCES[(I)local|global]} )) || return
		_p9k__ret=
		if [[ $PYENV_DIR != (|.) ]]
		then
			[[ $PYENV_DIR == /* ]] && local dir=$PYENV_DIR  || local dir="$_p9k__cwd_a/$PYENV_DIR"
			dir=${dir:A}
			if [[ $dir != $_p9k__cwd_a ]]
			then
				while true
				do
					if _p9k_read_pyenv_like_version_file $dir/.python-version python-
					then
						(( ${_POWERLEVEL9K_PYENV_SOURCES[(I)local]} )) || return
						break
					fi
					[[ $dir == (/|.) ]] && break
					dir=${dir:h}
				done
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			_p9k_upglob .python-version
			local -i idx=$?
			if (( idx )) && _p9k_read_pyenv_like_version_file $_p9k__parent_dirs[idx]/.python-version python-
			then
				(( ${_POWERLEVEL9K_PYENV_SOURCES[(I)local]} )) || return
			else
				_p9k__ret=
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			(( _POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW )) || return
			(( ${_POWERLEVEL9K_PYENV_SOURCES[(I)global]} )) || return
			_p9k_pyenv_global_version
		fi
		v=$_p9k__ret
	fi
	if (( !_POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW ))
	then
		_p9k_pyenv_global_version
		[[ $v == $_p9k__ret ]] && return 1
	fi
	if (( !_POWERLEVEL9K_PYENV_SHOW_SYSTEM ))
	then
		[[ $v == system ]] && return 1
	fi
	local versions=${PYENV_ROOT:-$HOME/.pyenv}/versions
	versions=${versions:A}
	local name version
	for name in ${(s.:.)v}
	do
		version=$versions/$name
		version=${version:A}
		if [[ $version(#qN/) == (#b)$versions/([^/]##)* ]]
		then
			typeset -g P9K_PYENV_PYTHON_VERSION=$match[1]
			break
		fi
	done
	typeset -g _p9k__pyenv_version=$v
}
_p9k_pyenv_global_version () {
	_p9k_read_pyenv_like_version_file ${PYENV_ROOT:-$HOME/.pyenv}/version python- || _p9k__ret=system
}
_p9k_python_version () {
	case $commands[python] in
		("") return 1 ;;
		(${PYENV_ROOT:-~/.pyenv}/shims/python) local P9K_PYENV_PYTHON_VERSION _p9k__pyenv_version
			local -i _POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW=1 _POWERLEVEL9K_PYENV_SHOW_SYSTEM=1
			local _POWERLEVEL9K_PYENV_SOURCES=(shell local global)
			if _p9k_pyenv_compute && [[ $P9K_PYENV_PYTHON_VERSION == ([[:digit:].]##)* ]]
			then
				_p9k__ret=$P9K_PYENV_PYTHON_VERSION
				return 0
			fi ;&
		(*) _p9k_cached_cmd 1 '' python --version || return
			[[ $_p9k__ret == (#b)Python\ ([[:digit:].]##)* ]] && _p9k__ret=$match[1]  ;;
	esac
}
_p9k_rbenv_global_version () {
	_p9k_read_word ${RBENV_ROOT:-$HOME/.rbenv}/version || _p9k__ret=system
}
_p9k_read_file () {
	_p9k__ret=''
	[[ -n $1 ]] && IFS='' read -r _p9k__ret < $1
	[[ -n $_p9k__ret ]]
}
_p9k_read_pyenv_like_version_file () {
	local -a stat
	zstat -A stat +mtime -- $1 2> /dev/null || stat=(-1)
	local cached=$_p9k__read_pyenv_like_version_file_cache[$1:$2]
	if [[ $cached == $stat[1]:* ]]
	then
		_p9k__ret=${cached#*:}
	else
		local fd content
		{
			{
				sysopen -r -u fd -- $1 && sysread -i $fd -s 1024 content
			} 2> /dev/null
		} always {
			[[ -n $fd ]] && exec {fd}>&-
		}
		local MATCH
		local versions=(${${${${(f)content}/(#m)*/${MATCH[(w)1]}}##\#*}#$2})
		_p9k__ret=${(j.:.)versions}
		_p9k__read_pyenv_like_version_file_cache[$1:$2]=$stat[1]:$_p9k__ret
	fi
	[[ -n $_p9k__ret ]]
}
_p9k_read_word () {
	local -a stat
	zstat -A stat +mtime -- $1 2> /dev/null || stat=(-1)
	local cached=$_p9k__read_word_cache[$1]
	if [[ $cached == $stat[1]:* ]]
	then
		_p9k__ret=${cached#*:}
	else
		local rest
		_p9k__ret=
		{
			read _p9k__ret rest < $1
		} 2> /dev/null
		_p9k__ret=${_p9k__ret%$'\r'}
		_p9k__read_word_cache[$1]=$stat[1]:$_p9k__ret
	fi
	[[ -n $_p9k__ret ]]
}
_p9k_redraw () {
	zle -F $1
	exec {1}>&-
	_p9k__redraw_fd=0
	() {
		local -h WIDGET=zle-line-pre-redraw
		_p9k_widget_hook ''
	}
}
_p9k_reset_prompt () {
	if (( __p9k_reset_state != 1 )) && zle && [[ -z $_p9k__line_finished ]]
	then
		__p9k_reset_state=0
		setopt prompt_subst
		(( __p9k_ksh_arrays )) && setopt ksh_arrays
		(( __p9k_sh_glob )) && setopt sh_glob
		{
			(( _p9k__can_hide_cursor )) && echoti civis
			zle .reset-prompt
			(( ${+functions[z4h]} )) || zle -R
		} always {
			(( _p9k__can_hide_cursor )) && echoti cnorm
			_p9k__cursor_hidden=0
		}
	fi
}
_p9k_restore_prompt () {
	eval "$__p9k_intro"
	zle -F $1
	exec {1}>&-
	_p9k__restore_prompt_fd=0
	(( _p9k__must_restore_prompt )) || return 0
	_p9k__must_restore_prompt=0
	unset _p9k__line_finished
	_p9k__refresh_reason=restore
	_p9k_set_prompt
	_p9k__refresh_reason=
	_p9k__expanded=0
	_p9k_reset_prompt
}
_p9k_restore_special_params () {
	(( ! ${+_p9k__real_zle_rprompt_indent} )) || {
		[[ -n "$_p9k__real_zle_rprompt_indent" ]] && ZLE_RPROMPT_INDENT="$_p9k__real_zle_rprompt_indent"  || unset ZLE_RPROMPT_INDENT
		unset _p9k__real_zle_rprompt_indent
	}
	(( ! ${+_p9k__real_lc_ctype} )) || {
		LC_CTYPE="$_p9k__real_lc_ctype"
		unset _p9k__real_lc_ctype
	}
	(( ! ${+_p9k__real_lc_all} )) || {
		LC_ALL="$_p9k__real_lc_all"
		unset _p9k__real_lc_all
	}
}
_p9k_restore_state () {
	{
		[[ $__p9k_cached_param_pat == $_p9k__param_pat && $__p9k_cached_param_sig == $_p9k__param_sig ]] || return
		(( $+functions[_p9k_restore_state_impl] )) || return
		_p9k_restore_state_impl
		return 0
	} always {
		if (( $? ))
		then
			if (( $+functions[_p9k_preinit] ))
			then
				unfunction _p9k_preinit
				(( $+functions[gitstatus_stop_p9k_] )) && gitstatus_stop_p9k_ POWERLEVEL9K
			fi
			_p9k_delete_instant_prompt
			zf_rm -f -- $__p9k_dump_file{,.zwc} 2> /dev/null
		elif [[ $__p9k_instant_prompt_param_sig != $_p9k__param_sig ]]
		then
			_p9k_delete_instant_prompt
			_p9k_dumped_instant_prompt_sigs=()
		fi
		unset __p9k_cached_param_sig
	}
}
_p9k_restore_state_impl () {
	typeset -g -i _POWERLEVEL9K_DISABLE_GITSTATUS=0
	typeset -g _POWERLEVEL9K_TERRAFORM_OTHER_FOREGROUND=4
	typeset -g _POWERLEVEL9K_TIMEWARRIOR_CONTENT_EXPANSION='${P9K_CONTENT:0:24}${${P9K_CONTENT:24}:+…}'
	typeset -g -a _POWERLEVEL9K_KUBECONTEXT_CLASSES=('*' DEFAULT)
	typeset -g _POWERLEVEL9K_SHORTEN_FOLDER_MARKER='(.bzr|.citc|.git|.hg|.node-version|.python-version|.go-version|.ruby-version|.lua-version|.java-version|.perl-version|.php-version|.tool-version|.shorten_folder_marker|.svn|.terraform|CVS|Cargo.toml|composer.json|go.mod|package.json|stack.yaml)'
	typeset -g _POWERLEVEL9K_PYENV_BACKGROUND=4
	typeset -g -i _POWERLEVEL9K_JENV_PROMPT_ALWAYS_SHOW=0
	typeset -g _POWERLEVEL9K_CONTEXT_REMOTE_SUDO_FOREGROUND=3
	typeset -g _POWERLEVEL9K_DIR_FOREGROUND=254
	typeset -g -a _POWERLEVEL9K_TERRAFORM_CLASSES=('*' OTHER)
	typeset -g -i _POWERLEVEL9K_ASDF_SHOW_SYSTEM=1
	typeset -g -i _p9k_term_has_href=1
	typeset -g -a _p9k_right_join=(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43)
	typeset -g _POWERLEVEL9K_DISK_USAGE_NORMAL_FOREGROUND=3
	typeset -g _p9k_transient_prompt=''
	typeset -g -i _POWERLEVEL9K_STATUS_OK=1
	typeset -g _POWERLEVEL9K_ASDF_HASKELL_BACKGROUND=3
	typeset -g _POWERLEVEL9K_TASKWARRIOR_BACKGROUND=6
	typeset -g -A _p9k_battery_states=([CHARGED]=green [CHARGING]=yellow [DISCONNECTED]=7 [LOW]=red)
	typeset -g -i _POWERLEVEL9K_HIDE_BRANCH_ICON=0
	typeset -g -i _POWERLEVEL9K_PHPENV_PROMPT_ALWAYS_SHOW=0
	typeset -g _POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=%242F╰─
	typeset -g _POWERLEVEL9K_CONTEXT_DEFAULT_CONTENT_EXPANSION=''
	typeset -g _POWERLEVEL9K_TRANSIENT_PROMPT=off
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
	typeset -g _POWERLEVEL9K_NVM_FOREGROUND=0
	typeset -g _POWERLEVEL9K_PHP_VERSION_BACKGROUND=5
	typeset -g -i _POWERLEVEL9K_ASDF_PROMPT_ALWAYS_SHOW=0
	typeset -g _POWERLEVEL9K_ASDF_NODEJS_BACKGROUND=2
	typeset -g _POWERLEVEL9K_TOOLBOX_FOREGROUND=0
	typeset -g _p9k_preinit=$'function _p9k_preinit() {\n    (( 1 )) || { unfunction _p9k_preinit; return 1 }\n    [[ $ZSH_VERSION == 5.7.1 ]]                      || return\n    [[ -r /Users/sedatkilinc/powerlevel10k/gitstatus/gitstatus.plugin.zsh ]]             || return\n    builtin source /Users/sedatkilinc/powerlevel10k/gitstatus/gitstatus.plugin.zsh _p9k_ || return\n    GITSTATUS_AUTO_INSTALL=\'\'               GITSTATUS_DAEMON=\'\'                         GITSTATUS_CACHE_DIR=\'\'                   GITSTATUS_NUM_THREADS=\'\'               GITSTATUS_LOG_LEVEL=\'\'                   GITSTATUS_ENABLE_LOGGING=\'\'           gitstatus_start_p9k_                                              -s -1                            -u -1                          -d -1                         -c -1                        -m -1                                 -a POWERLEVEL9K\n  }'
	typeset -g _POWERLEVEL9K_PHPENV_FOREGROUND=0
	typeset -g -a _p9k_asdf_meta_non_files=()
	typeset -g -i _POWERLEVEL9K_CHRUBY_SHOW_ENGINE=1
	typeset -g -i _POWERLEVEL9K_PLENV_SHOW_SYSTEM=1
	typeset -g _POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND=2
	typeset -g _POWERLEVEL9K_STATUS_OK_BACKGROUND=0
	typeset -g _POWERLEVEL9K_JENV_FOREGROUND=1
	typeset -g -i _POWERLEVEL9K_VCS_UNTRACKED_MAX_NUM=-1
	typeset -g _POWERLEVEL9K_VCS_UNTRACKED_ICON='?'
	typeset -g _POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND='kubectl|helm|kubens|kubectx|oc|istioctl|kogito|k9s|helmfile|flux|fluxctl|stern'
	typeset -g -a _POWERLEVEL9K_BATTERY_CHARGED_LEVEL_BACKGROUND=()
	typeset -g _POWERLEVEL9K_ASDF_RUST_FOREGROUND=0
	typeset -g -a _POWERLEVEL9K_AWS_CLASSES=('*' DEFAULT)
	typeset -g -i _p9k_reset_on_line_finish=0
	typeset -g -i _POWERLEVEL9K_VCS_CONFLICTED_STATE=0
	typeset -g _POWERLEVEL9K_BATTERY_DISCONNECTED_FOREGROUND=3
	typeset -g _POWERLEVEL9K_VCS_LOADING_TEXT=loading
	typeset -g -a _POWERLEVEL9K_BATTERY_STAGES=(          )
	typeset -g _POWERLEVEL9K_RANGER_FOREGROUND=3
	typeset -g _POWERLEVEL9K_SWAP_BACKGROUND=3
	typeset -g _POWERLEVEL9K_ASDF_POSTGRES_FOREGROUND=0
	typeset -g -i _POWERLEVEL9K_RPROMPT_ON_NEWLINE=0
	typeset -g -i _POWERLEVEL9K_STATUS_OK_IN_NON_VERBOSE=0
	typeset -g -i _POWERLEVEL9K_BATTERY_DISCONNECTED_HIDE_ABOVE_THRESHOLD=999
	typeset -g _POWERLEVEL9K_DISK_USAGE_WARNING_FOREGROUND=0
	typeset -g _p9k_gcloud_configuration=''
	typeset -g _POWERLEVEL9K_COLOR_SCHEME=dark
	typeset -g _POWERLEVEL9K_ASDF_LUA_BACKGROUND=4
	typeset -g _POWERLEVEL9K_ASDF_GOLANG_FOREGROUND=0
	typeset -g _POWERLEVEL9K_WIFI_FOREGROUND=0
	typeset -g _POWERLEVEL9K_CONTEXT_REMOTE_TEMPLATE=%n@%m
	typeset -g -i _POWERLEVEL9K_EXPERIMENTAL_TIME_REALTIME=0
	typeset -g _p9k_taskwarrior_data_sig=''
	typeset -g _POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_BACKGROUND=''
	typeset -g _POWERLEVEL9K_HOME_FOLDER_ABBREVIATION='~'
	typeset -g -a _POWERLEVEL9K_BATTERY_DISCONNECTED_STAGES=(          )
	typeset -g -A _p9k_git_slow=([/Volumes/ExtMem512GB/Projects/github/WebRTC-Samples]=1 [/Volumes/ExtMem512GB/Projects/github/imgui]=1)
	typeset -g -i _POWERLEVEL9K_VCS_COMMITS_AHEAD_MAX_NUM=-1
	typeset -g _POWERLEVEL9K_ASDF_PHP_FOREGROUND=0
	typeset -g _POWERLEVEL9K_TERRAFORM_OTHER_BACKGROUND=0
	typeset -g -a _p9k_line_segments_left=($'os_icon\C-@dir\C-@vcs')
	typeset -g -i _POWERLEVEL9K_CHANGESET_HASH_LENGTH=8
	typeset -g -i _POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=0
	typeset -g _POWERLEVEL9K_ASDF_JULIA_FOREGROUND=0
	typeset -g _POWERLEVEL9K_LOAD_NORMAL_BACKGROUND=2
	typeset -g _POWERLEVEL9K_CONTEXT_REMOTE_SUDO_BACKGROUND=0
	typeset -g -i _POWERLEVEL9K_RUST_VERSION_PROJECT_ONLY=1
	typeset -g _POWERLEVEL9K_DIR_BACKGROUND=4
	typeset -g -a _POWERLEVEL9K_ASDF_SOURCES=(shell local global)
	typeset -g _POWERLEVEL9K_VCS_BRANCH_ICON='\uF126 '
	typeset -g -i _POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
	typeset -g _POWERLEVEL9K_DISK_USAGE_NORMAL_BACKGROUND=0
	typeset -g _POWERLEVEL9K_GCLOUD_PARTIAL_CONTENT_EXPANSION='${P9K_GCLOUD_PROJECT_ID//\%/%%}'
	typeset -g -i _POWERLEVEL9K_NODEENV_SHOW_NODE_VERSION=0
	typeset -g _p9k_gcloud_project_name=''
	typeset -g -i _POWERLEVEL9K_TODO_HIDE_ZERO_FILTERED=0
	typeset -g -a _POWERLEVEL9K_DIR_PACKAGE_FILES=(package.json composer.json)
	typeset -g _POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=1
	typeset -g -a _POWERLEVEL9K_BATTERY_CHARGING_STAGES=(          )
	typeset -g _POWERLEVEL9K_NORDVPN_DISCONNECTING_VISUAL_IDENTIFIER_EXPANSION=''
	typeset -g -i _POWERLEVEL9K_BATTERY_CHARGED_HIDE_ABOVE_THRESHOLD=999
	typeset -g _POWERLEVEL9K_ASDF_PERL_FOREGROUND=0
	typeset -g -i _POWERLEVEL9K_DISK_USAGE_WARNING_LEVEL=90
	typeset -g _POWERLEVEL9K_VI_INSERT_MODE_STRING=''
	typeset -g -i _POWERLEVEL9K_BATTERY_CHARGING_HIDE_ABOVE_THRESHOLD=999
	typeset -g _POWERLEVEL9K_TOOLBOX_BACKGROUND=3
	typeset -g _POWERLEVEL9K_USER_TEMPLATE=%n
	typeset -g _POWERLEVEL9K_STATUS_ERROR_FOREGROUND=3
	typeset -g -i _POWERLEVEL9K_DISK_USAGE_CRITICAL_LEVEL=95
	typeset -g -F _POWERLEVEL9K_LOAD_CRITICAL_PCT=70.0000000000
	typeset -g _POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYENV=false
	typeset -g -a _p9k_t=($'\n' $'%{%G\n%}' '' $'\n' '%b%k%f${(pl.${$((_p9k__clm-_p9k__ind))/#-*/0}..─.)}%k%f${_p9k_t[$((1+!_p9k__ind))]}' '${${:-${_p9k__x::=0}${_p9k__y::=1024}${_p9k__p::=$_p9k__lprompt$_p9k__rprompt}${_p9k__m::=$(((_p9k__x+_p9k__y)/2))}${_p9k__xy::=${${(%):-$_p9k__p%$_p9k__m(l./$_p9k__m;$_p9k__y./$_p9k__x;$_p9k__m)}##*/}}${_p9k__x::=${_p9k__xy%;*}}${_p9k__y::=${_p9k__xy#*;}}${_p9k__m::=$(((_p9k__x+_p9k__y)/2))}${_p9k__xy::=${${(%):-$_p9k__p%$_p9k__m(l./$_p9k__m;$_p9k__y./$_p9k__x;$_p9k__m)}##*/}}${_p9k__x::=${_p9k__xy%;*}}${_p9k__y::=${_p9k__xy#*;}}${_p9k__m::=$(((_p9k__x+_p9k__y)/2))}${_p9k__xy::=${${(%):-$_p9k__p%$_p9k__m(l./$_p9k__m;$_p9k__y./$_p9k__x;$_p9k__m)}##*/}}${_p9k__x::=${_p9k__xy%;*}}${_p9k__y::=${_p9k__xy#*;}}${_p9k__m::=$(((_p9k__x+_p9k__y)/2))}${_p9k__xy::=${${(%):-$_p9k__p%$_p9k__m(l./$_p9k__m;$_p9k__y./$_p9k__x;$_p9k__m)}##*/}}${_p9k__x::=${_p9k__xy%;*}}${_p9k__y::=${_p9k__xy#*;}}${_p9k__m::=$(((_p9k__x+_p9k__y)/2))}${_p9k__xy::=${${(%):-$_p9k__p%$_p9k__m(l./$_p9k__m;$_p9k__y./$_p9k__x;$_p9k__m)}##*/}}${_p9k__x::=${_p9k__xy%;*}}${_p9k__y::=${_p9k__xy#*;}}${_p9k__m::=$(((_p9k__x+_p9k__y)/2))}${_p9k__xy::=${${(%):-$_p9k__p%$_p9k__m(l./$_p9k__m;$_p9k__y./$_p9k__x;$_p9k__m)}##*/}}${_p9k__x::=${_p9k__xy%;*}}${_p9k__y::=${_p9k__xy#*;}}${_p9k__m::=$(((_p9k__x+_p9k__y)/2))}${_p9k__xy::=${${(%):-$_p9k__p%$_p9k__m(l./$_p9k__m;$_p9k__y./$_p9k__x;$_p9k__m)}##*/}}${_p9k__x::=${_p9k__xy%;*}}${_p9k__y::=${_p9k__xy#*;}}${_p9k__m::=$(((_p9k__x+_p9k__y)/2))}${_p9k__xy::=${${(%):-$_p9k__p%$_p9k__m(l./$_p9k__m;$_p9k__y./$_p9k__x;$_p9k__m)}##*/}}${_p9k__x::=${_p9k__xy%;*}}${_p9k__y::=${_p9k__xy#*;}}${_p9k__m::=$(((_p9k__x+_p9k__y)/2))}${_p9k__xy::=${${(%):-$_p9k__p%$_p9k__m(l./$_p9k__m;$_p9k__y./$_p9k__x;$_p9k__m)}##*/}}${_p9k__x::=${_p9k__xy%;*}}${_p9k__y::=${_p9k__xy#*;}}${_p9k__m::=$(((_p9k__x+_p9k__y)/2))}${_p9k__xy::=${${(%):-$_p9k__p%$_p9k__m(l./$_p9k__m;$_p9k__y./$_p9k__x;$_p9k__m)}##*/}}${_p9k__x::=${_p9k__xy%;*}}${_p9k__y::=${_p9k__xy#*;}}${_p9k__m::=$((_p9k__clm-_p9k__x-_p9k__ind-1))}}+}' $'${${_p9k__clm::=$COLUMNS}+}${${COLUMNS::=1024}+}${${_p9k__keymap::=${KEYMAP:-$_p9k__keymap}}+}${${_p9k__zle_state::=${ZLE_STATE:-$_p9k__zle_state}}+}%b%k%f${${_p9k__ind::=${${ZLE_RPROMPT_INDENT:-1}/#-*/0}}+}%{\C-[]133;A\C-G%}${_p9k_t[${_p9k__empty_line_i:-4}]}%{${_p9k__ipe-${_p9k_t[${_p9k__ruler_i:-1}]:+\n${(Q)${:-"$\'\\\\033\'\\\\[A"}}}}%}${(e)_p9k_t[${_p9k__ruler_i:-5}]}' '%b%k%F{000}%b%K{000}%F{002} ' '<_p9k__w>%b%K{000}%F{002}' '<_p9k__w>%b%K{000}%F{002}╱ ' '<_p9k__w>%F{000}%b%K{000}%F{002} ' '%b%k%F{000}%b%K{000}%F{006} ' '<_p9k__w>%b%K{000}%F{006}' '<_p9k__w>%b%K{000}%F{006}╱ ' '<_p9k__w>%F{000}%b%K{000}%F{006} ' '%b%k%F{000}%b%K{000}%F{003} ' '<_p9k__w>%b%K{000}%F{003}' '<_p9k__w>%b%K{000}%F{003}╱ ' '<_p9k__w>%F{000}%b%K{000}%F{003} ' '%b%k%F{000}%b%K{000}%F{001} ' '<_p9k__w>%b%K{000}%F{001}' '<_p9k__w>%b%K{000}%F{001}╱ ' '<_p9k__w>%F{000}%b%K{000}%F{001} ' '%b%k%F{003}%b%K{003}%F{000} ' '<_p9k__w>%b%K{003}%F{000}' '<_p9k__w>%b%K{003}%F{000}╱ ' '<_p9k__w>%F{003}%b%K{003}%F{000} ' '%b%k%F{002}%b%K{002}%F{000} ' '<_p9k__w>%b%K{002}%F{000}' '<_p9k__w>%b%K{002}%F{000}╱ ' '<_p9k__w>%F{002}%b%K{002}%F{000} ' '%b%k%F{004}%b%K{004}%F{000} ' '<_p9k__w>%b%K{004}%F{000}' '<_p9k__w>%b%K{004}%F{000}╱ ' '<_p9k__w>%F{004}%b%K{004}%F{000} ' '%b%k%F{001}%b%K{001}%F{000} ' '<_p9k__w>%b%K{001}%F{000}' '<_p9k__w>%b%K{001}%F{000}╱ ' '<_p9k__w>%F{001}%b%K{001}%F{000} ' '%b%k%F{003}%b%K{003}%F{000} ' '<_p9k__w>%b%K{003}%F{000}' '<_p9k__w>%b%K{003}%F{000}╱ ' '<_p9k__w>%F{003}%b%K{003}%F{000} ' '%b%k%F{002}%b%K{002}%F{000} ' '<_p9k__w>%b%K{002}%F{000}' '<_p9k__w>%b%K{002}%F{000}╱ ' '<_p9k__w>%F{002}%b%K{002}%F{000} ' '%b%k%F{007}%b%K{007}%F{000} ' '<_p9k__w>%b%K{007}%F{000}' '<_p9k__w>%b%K{007}%F{000}╱ ' '<_p9k__w>%F{007}%b%K{007}%F{000} ' '%b%k%F{007}%b%K{007}%F{232} ' '%b%K{007}%F{232}' '%b%K{007}<_p9k__ss>%b%K{007}%F{232} ' '%b%K{007}<_p9k__s>%b%K{007}%F{232} ' '%b%k%F{004}%b%K{004}%F{254} ' '%b%K{004}%F{254}' '%b%K{004}<_p9k__ss>%b%K{004}%F{254} ' '%b%K{004}<_p9k__s>%b%K{004}%F{254} ' '%b%k%F{003}%b%K{003}%F{000} ' '<_p9k__w>%b%K{003}%F{000}' '<_p9k__w>%b%K{003}%F{000}╱ ' '<_p9k__w>%F{003}%b%K{003}%F{000} ' '%b%k%F{000}%b%K{000}%F{003} ' '<_p9k__w>%b%K{000}%F{003}' '<_p9k__w>%b%K{000}%F{003}╱ ' '<_p9k__w>%F{000}%b%K{000}%F{003} ' '%b%k%F{006}%b%K{006}%F{000} ' '<_p9k__w>%b%K{006}%F{000}' '<_p9k__w>%b%K{006}%F{000}╱ ' '<_p9k__w>%F{006}%b%K{006}%F{000} ' '%b%k%F{006}%b%K{006}%F{000} ' '<_p9k__w>%b%K{006}%F{000}' '<_p9k__w>%b%K{006}%F{000}╱ ' '<_p9k__w>%F{006}%b%K{006}%F{000} ' '%b%k%F{002}%b%K{002}%F{000} ' '<_p9k__w>%b%K{002}%F{000}' '<_p9k__w>%b%K{002}%F{000}╱ ' '<_p9k__w>%F{002}%b%K{002}%F{000} ' '%b%k%F{000}%b%K{000}%F{003} ' '<_p9k__w>%b%K{000}%F{003}' '<_p9k__w>%b%K{000}%F{003}╱ ' '<_p9k__w>%F{000}%b%K{000}%F{003} ' '%b%k%F{004}%b%K{004}%F{000} ' '<_p9k__w>%b%K{004}%F{000}' '<_p9k__w>%b%K{004}%F{000}╱ ' '<_p9k__w>%F{004}%b%K{004}%F{000} ' '%b%k%F{004}%b%K{004}%F{254} ' '%b%K{004}%F{254}' '%b%K{004}<_p9k__ss>%b%K{004}%F{254} ' '%b%K{004}<_p9k__s>%b%K{004}%F{254} ' '%b%k%F{001}%b%K{001}%F{003} ' '<_p9k__w>%b%K{001}%F{003}' '<_p9k__w>%b%K{001}%F{003}╱ ' '<_p9k__w>%F{001}%b%K{001}%F{003} ' '%b%k%F{003}%b%K{003}%F{000} ' '<_p9k__w>%b%K{003}%F{000}' '<_p9k__w>%b%K{003}%F{000}╱ ' '<_p9k__w>%F{003}%b%K{003}%F{000} ' '%b%k%F{004}%b%K{004}%F{196} ' '%b%K{004}%F{196}' '%b%K{004}<_p9k__ss>%b%K{004}%F{196} ' '%b%K{004}<_p9k__s>%b%K{004}%F{196} ' '%b%k%F{001}%b%K{001}%F{003} ' '<_p9k__w>%b%K{001}%F{003}' '<_p9k__w>%b%K{001}%F{003}╱ ' '<_p9k__w>%F{001}%b%K{001}%F{003} ' '%b%k%F{001}%b%K{001}%F{003} ' '<_p9k__w>%b%K{001}%F{003}' '<_p9k__w>%b%K{001}%F{003}╱ ' '<_p9k__w>%F{001}%b%K{001}%F{003} ' '%b%k%F{008}%b%K{008}%F{000} ' '%b%K{008}%F{000}' '%b%K{008}<_p9k__ss>%b%K{008}%F{000} ' '%b%K{008}<_p9k__s>%b%K{008}%F{000} ' '%b%k%F{002}%b%K{002}%F{000} ' '%b%K{002}%F{000}' '%b%K{002}<_p9k__ss>%b%K{002}%F{000} ' '%b%K{002}<_p9k__s>%b%K{002}%F{000} ' '%b%k%F{008}%b%K{008}%F{000} ' '%b%K{008}%F{000}' '%b%K{008}<_p9k__ss>%b%K{008}%F{000} ' '%b%K{008}<_p9k__s>%b%K{008}%F{000} ')
	typeset -g _POWERLEVEL9K_RUST_VERSION_BACKGROUND=208
	typeset -g _POWERLEVEL9K_PROXY_FOREGROUND=4
	typeset -g _POWERLEVEL9K_KUBECONTEXT_DEFAULT_CONTENT_EXPANSION='${P9K_KUBECONTEXT_CLOUD_CLUSTER:-${P9K_KUBECONTEXT_NAME}}${${:-/$P9K_KUBECONTEXT_NAMESPACE}:#/default}'
	typeset -g _POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX=%242F├─
	typeset -g -A _p9k_asdf_file_info=()
	typeset -g _POWERLEVEL9K_ASDF_RUST_BACKGROUND=208
	typeset -g _POWERLEVEL9K_DISK_USAGE_CRITICAL_FOREGROUND=7
	typeset -g -A _p9k_asdf_file2versions=()
	typeset -g -a _p9k_taskwarrior_meta_files=()
	typeset -g _POWERLEVEL9K_RANGER_BACKGROUND=0
	typeset -g _POWERLEVEL9K_TODO_FOREGROUND=0
	typeset -g _POWERLEVEL9K_ASDF_POSTGRES_BACKGROUND=6
	typeset -g -a _POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs)
	typeset -g _POWERLEVEL9K_PUBLIC_IP_VPN_INTERFACE=''
	typeset -g -i _p9k_emulate_zero_rprompt_indent=0
	typeset -g _POWERLEVEL9K_KUBECONTEXT_DEFAULT_BACKGROUND=5
	typeset -g _POWERLEVEL9K_PUBLIC_IP_FOREGROUND=7
	typeset -g _POWERLEVEL9K_DISK_USAGE_WARNING_BACKGROUND=3
	typeset -g _POWERLEVEL9K_HOST_TEMPLATE=%m
	typeset -g _POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL='\uE0BC'
	typeset -g _POWERLEVEL9K_NODENV_FOREGROUND=2
	typeset -g _POWERLEVEL9K_CONTEXT_REMOTE_SUDO_TEMPLATE=%n@%m
	typeset -g _POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION=✘
	typeset -g _POWERLEVEL9K_IP_BACKGROUND=4
	typeset -g _POWERLEVEL9K_STATUS_ERROR_SIGNAL_BACKGROUND=1
	typeset -g _POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL='\uE0BA'
	typeset -g -i _POWERLEVEL9K_KUBECONTEXT_SHOW_DEFAULT_NAMESPACE=1
	typeset -g _POWERLEVEL9K_FVM_FOREGROUND=0
	typeset -g _POWERLEVEL9K_ASDF_GOLANG_BACKGROUND=4
	typeset -g _POWERLEVEL9K_PLENV_FOREGROUND=0
	typeset -g _POWERLEVEL9K_INSTANT_PROMPT=verbose
	typeset -g -a _POWERLEVEL9K_BATTERY_LOW_LEVEL_BACKGROUND=()
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_ERROR_VIVIS_FOREGROUND=196
	typeset -g _POWERLEVEL9K_AWS_SHOW_ON_COMMAND='aws|awless|terraform|pulumi|terragrunt'
	typeset -g _p9k_gcloud_account=''
	typeset -g -i _POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
	typeset -g -i _POWERLEVEL9K_NODENV_PROMPT_ALWAYS_SHOW=0
	typeset -g _POWERLEVEL9K_PYENV_CONTENT_EXPANSION='${P9K_CONTENT}${${P9K_CONTENT:#$P9K_PYENV_PYTHON_VERSION(|/*)}:+ $P9K_PYENV_PYTHON_VERSION}'
	typeset -g _POWERLEVEL9K_TERRAFORM_VERSION_BACKGROUND=0
	typeset -g _POWERLEVEL9K_EXAMPLE_BACKGROUND=1
	typeset -g _p9k_prompt_suffix_right='${${COLUMNS::=$_p9k__clm}+}}'
	typeset -g -i _POWERLEVEL9K_GOENV_SHOW_SYSTEM=1
	typeset -g _POWERLEVEL9K_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL='\uE0B2'
	typeset -g _POWERLEVEL9K_ASDF_PYTHON_FOREGROUND=0
	typeset -g -i _POWERLEVEL9K_LUAENV_PROMPT_ALWAYS_SHOW=0
	typeset -g _POWERLEVEL9K_ASDF_JAVA_BACKGROUND=7
	typeset -g _POWERLEVEL9K_EMPTY_LINE_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
	typeset -g _POWERLEVEL9K_ASDF_JULIA_BACKGROUND=2
	typeset -g _POWERLEVEL9K_LOAD_WARNING_BACKGROUND=3
	typeset -g _POWERLEVEL9K_TOOLBOX_CONTENT_EXPANSION='${P9K_TOOLBOX_NAME:#fedora-toolbox-*}'
	typeset -g -a _POWERLEVEL9K_JENV_SOURCES=(shell local global)
	typeset -g _POWERLEVEL9K_SCALAENV_FOREGROUND=0
	typeset -g _POWERLEVEL9K_HASKELL_STACK_BACKGROUND=3
	typeset -g -i _POWERLEVEL9K_DIR_OMIT_FIRST_CHARACTER=0
	typeset -g _POWERLEVEL9K_VI_OVERWRITE_MODE_STRING=OVERTYPE
	typeset -g -i _POWERLEVEL9K_SHOW_CHANGESET=0
	typeset -g _POWERLEVEL9K_GOOGLE_APP_CRED_DEFAULT_FOREGROUND=7
	typeset -g _POWERLEVEL9K_GOENV_FOREGROUND=0
	typeset -g _POWERLEVEL9K_BATTERY_CHARGED_FOREGROUND=2
	typeset -g -a _POWERLEVEL9K_GOOGLE_APP_CRED_CLASSES=('*' DEFAULT)
	typeset -g _POWERLEVEL9K_AWS_EB_ENV_BACKGROUND=0
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_ERROR_VIOWR_FOREGROUND=196
	typeset -g _POWERLEVEL9K_AWS_DEFAULT_FOREGROUND=7
	typeset -g _POWERLEVEL9K_CONTEXT_REMOTE_BACKGROUND=0
	typeset -g -a _p9k_line_gap_post=()
	typeset -g -A _p9k_cache=([$'_p9k_cache_stat_get\C-@prompt_kubecontext\C-@meta\C-@/Users/sedatkilinc/.kube/config']=$'\C-@md5: /Users/sedatkilinc/.kube/config: No such file or directory\C-@\C-@\C-@\C-@\C-@\C-@\C-@\C-@\C-@\C-@0' [$'_p9k_color prompt_background_jobs\C-@BACKGROUND\C-@0']=000. [$'_p9k_color prompt_background_jobs\C-@FOREGROUND\C-@cyan']=006. [$'_p9k_color prompt_background_jobs\C-@VISUAL_IDENTIFIER_COLOR\C-@006']=006. [$'_p9k_color prompt_command_execution_time\C-@BACKGROUND\C-@red']=003. [$'_p9k_color prompt_command_execution_time\C-@FOREGROUND\C-@yellow1']=000. [$'_p9k_color prompt_command_execution_time\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_color prompt_context_DEFAULT\C-@BACKGROUND\C-@0']=000. [$'_p9k_color prompt_context_DEFAULT\C-@FOREGROUND\C-@yellow']=003. [$'_p9k_color prompt_context_ROOT\C-@BACKGROUND\C-@0']=000. [$'_p9k_color prompt_context_ROOT\C-@FOREGROUND\C-@yellow']=001. [$'_p9k_color prompt_dir_DEFAULT\C-@ANCHOR_FOREGROUND\C-@']=255. [$'_p9k_color prompt_dir_DEFAULT\C-@BACKGROUND\C-@blue']=004. [$'_p9k_color prompt_dir_DEFAULT\C-@FOREGROUND\C-@0']=254. [$'_p9k_color prompt_dir_DEFAULT\C-@SHORTENED_FOREGROUND\C-@']=250. [$'_p9k_color prompt_dir_HOME\C-@ANCHOR_FOREGROUND\C-@']=255. [$'_p9k_color prompt_dir_HOME\C-@BACKGROUND\C-@blue']=004. [$'_p9k_color prompt_dir_HOME\C-@FOREGROUND\C-@0']=254. [$'_p9k_color prompt_dir_HOME\C-@SHORTENED_FOREGROUND\C-@']=250. [$'_p9k_color prompt_dir_WORK\C-@ANCHOR_FOREGROUND\C-@']=196. [$'_p9k_color prompt_dir_WORK\C-@BACKGROUND\C-@blue']=004. [$'_p9k_color prompt_dir_WORK\C-@FOREGROUND\C-@0']=196. [$'_p9k_color prompt_dir_WORK\C-@SHORTENED_FOREGROUND\C-@']=250. [$'_p9k_color prompt_dir_WORK\C-@VISUAL_IDENTIFIER_COLOR\C-@196']=196. [$'_p9k_color prompt_load_CRITICAL\C-@BACKGROUND\C-@red']=001. [$'_p9k_color prompt_load_CRITICAL\C-@FOREGROUND\C-@0']=000. [$'_p9k_color prompt_load_CRITICAL\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_color prompt_load_NORMAL\C-@BACKGROUND\C-@green']=002. [$'_p9k_color prompt_load_NORMAL\C-@FOREGROUND\C-@0']=000. [$'_p9k_color prompt_load_NORMAL\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_color prompt_load_WARNING\C-@BACKGROUND\C-@yellow']=003. [$'_p9k_color prompt_load_WARNING\C-@FOREGROUND\C-@0']=000. [$'_p9k_color prompt_load_WARNING\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_color prompt_midnight_commander\C-@BACKGROUND\C-@0']=000. [$'_p9k_color prompt_midnight_commander\C-@FOREGROUND\C-@yellow']=003. [$'_p9k_color prompt_midnight_commander\C-@VISUAL_IDENTIFIER_COLOR\C-@003']=003. [$'_p9k_color prompt_nix_shell\C-@BACKGROUND\C-@4']=004. [$'_p9k_color prompt_nix_shell\C-@FOREGROUND\C-@0']=000. [$'_p9k_color prompt_nix_shell\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_color prompt_nnn\C-@BACKGROUND\C-@6']=006. [$'_p9k_color prompt_nnn\C-@FOREGROUND\C-@0']=000. [$'_p9k_color prompt_nnn\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_color prompt_os_icon\C-@BACKGROUND\C-@black']=007. [$'_p9k_color prompt_os_icon\C-@FOREGROUND\C-@white']=232. [$'_p9k_color prompt_ranger\C-@BACKGROUND\C-@0']=000. [$'_p9k_color prompt_ranger\C-@FOREGROUND\C-@yellow']=003. [$'_p9k_color prompt_ranger\C-@VISUAL_IDENTIFIER_COLOR\C-@003']=003. [$'_p9k_color prompt_ruler\C-@BACKGROUND\C-@']=. [$'_p9k_color prompt_ruler\C-@FOREGROUND\C-@']=. [$'_p9k_color prompt_status_ERROR\C-@BACKGROUND\C-@red']=001. [$'_p9k_color prompt_status_ERROR\C-@FOREGROUND\C-@yellow1']=003. [$'_p9k_color prompt_status_ERROR\C-@VISUAL_IDENTIFIER_COLOR\C-@003']=003. [$'_p9k_color prompt_status_ERROR_PIPE\C-@BACKGROUND\C-@red']=001. [$'_p9k_color prompt_status_ERROR_PIPE\C-@FOREGROUND\C-@yellow1']=003. [$'_p9k_color prompt_status_ERROR_PIPE\C-@VISUAL_IDENTIFIER_COLOR\C-@003']=003. [$'_p9k_color prompt_status_ERROR_SIGNAL\C-@BACKGROUND\C-@red']=001. [$'_p9k_color prompt_status_ERROR_SIGNAL\C-@FOREGROUND\C-@yellow1']=003. [$'_p9k_color prompt_status_ERROR_SIGNAL\C-@VISUAL_IDENTIFIER_COLOR\C-@003']=003. [$'_p9k_color prompt_status_OK\C-@BACKGROUND\C-@0']=000. [$'_p9k_color prompt_status_OK\C-@FOREGROUND\C-@green']=002. [$'_p9k_color prompt_status_OK\C-@VISUAL_IDENTIFIER_COLOR\C-@002']=002. [$'_p9k_color prompt_time\C-@BACKGROUND\C-@7']=007. [$'_p9k_color prompt_time\C-@FOREGROUND\C-@0']=000. [$'_p9k_color prompt_time\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_color prompt_toolbox\C-@BACKGROUND\C-@0']=003. [$'_p9k_color prompt_toolbox\C-@FOREGROUND\C-@yellow']=000. [$'_p9k_color prompt_toolbox\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_color prompt_vcs_CLEAN\C-@BACKGROUND\C-@2']=002. [$'_p9k_color prompt_vcs_CLEAN\C-@FOREGROUND\C-@0']=000. [$'_p9k_color prompt_vcs_CLEAN\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_color prompt_vcs_LOADING\C-@BACKGROUND\C-@8']=008. [$'_p9k_color prompt_vcs_LOADING\C-@FOREGROUND\C-@0']=000. [$'_p9k_color prompt_vcs_LOADING\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_color prompt_vi_mode_NORMAL\C-@BACKGROUND\C-@0']=002. [$'_p9k_color prompt_vi_mode_NORMAL\C-@FOREGROUND\C-@white']=000. [$'_p9k_color prompt_vi_mode_OVERWRITE\C-@BACKGROUND\C-@0']=003. [$'_p9k_color prompt_vi_mode_OVERWRITE\C-@FOREGROUND\C-@blue']=000. [$'_p9k_color prompt_vi_mode_VISUAL\C-@BACKGROUND\C-@0']=004. [$'_p9k_color prompt_vi_mode_VISUAL\C-@FOREGROUND\C-@white']=000. [$'_p9k_color prompt_vim_shell\C-@BACKGROUND\C-@green']=002. [$'_p9k_color prompt_vim_shell\C-@FOREGROUND\C-@0']=000. [$'_p9k_color prompt_vim_shell\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_color prompt_xplr\C-@BACKGROUND\C-@6']=006. [$'_p9k_color prompt_xplr\C-@FOREGROUND\C-@0']=000. [$'_p9k_color prompt_xplr\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_get_icon \C-@LEFT_SEGMENT_END_SEPARATOR']=' .' [$'_p9k_get_icon \C-@LEFT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon \C-@RULER_CHAR']=─. [$'_p9k_get_icon \C-@VCS_BRANCH_ICON']=' .' [$'_p9k_get_icon \C-@VCS_STAGED_ICON']=. [$'_p9k_get_icon \C-@VCS_UNSTAGED_ICON']=. [$'_p9k_get_icon prompt_background_jobs\C-@BACKGROUND_JOBS_ICON']=. [$'_p9k_get_icon prompt_background_jobs\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_background_jobs\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_background_jobs\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_background_jobs\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_background_jobs\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_background_jobs\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_background_jobs\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_background_jobs\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_command_execution_time\C-@EXECUTION_TIME_ICON']=. [$'_p9k_get_icon prompt_command_execution_time\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_command_execution_time\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_command_execution_time\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_command_execution_time\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_command_execution_time\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_command_execution_time\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_command_execution_time\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_command_execution_time\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_context_DEFAULT\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_context_DEFAULT\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_context_DEFAULT\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_context_DEFAULT\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_context_DEFAULT\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_context_DEFAULT\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_context_DEFAULT\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_context_ROOT\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_context_ROOT\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_context_ROOT\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_context_ROOT\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_context_ROOT\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_context_ROOT\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_context_ROOT\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_dir_DEFAULT\C-@\C-A']=. [$'_p9k_get_icon prompt_dir_DEFAULT\C-@LEFT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_dir_DEFAULT\C-@LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL']=. [$'_p9k_get_icon prompt_dir_DEFAULT\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_dir_DEFAULT\C-@LEFT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_dir_DEFAULT\C-@LEFT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_dir_DEFAULT\C-@LEFT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_dir_DEFAULT\C-@WHITESPACE_BETWEEN_LEFT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_dir_HOME\C-@\C-A']=. [$'_p9k_get_icon prompt_dir_HOME\C-@LEFT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_dir_HOME\C-@LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL']=. [$'_p9k_get_icon prompt_dir_HOME\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_dir_HOME\C-@LEFT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_dir_HOME\C-@LEFT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_dir_HOME\C-@LEFT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_dir_HOME\C-@WHITESPACE_BETWEEN_LEFT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_dir_WORK\C-@\C-A']=. [$'_p9k_get_icon prompt_dir_WORK\C-@LEFT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_dir_WORK\C-@LEFT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_dir_WORK\C-@LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL']=. [$'_p9k_get_icon prompt_dir_WORK\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_dir_WORK\C-@LEFT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_dir_WORK\C-@LEFT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_dir_WORK\C-@LEFT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_dir_WORK\C-@WHITESPACE_BETWEEN_LEFT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_empty_line\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_load_CRITICAL\C-@LOAD_ICON']=. [$'_p9k_get_icon prompt_load_CRITICAL\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_load_CRITICAL\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_load_CRITICAL\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_load_CRITICAL\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_load_CRITICAL\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_load_CRITICAL\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_load_CRITICAL\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_load_CRITICAL\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_load_NORMAL\C-@LOAD_ICON']=. [$'_p9k_get_icon prompt_load_NORMAL\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_load_NORMAL\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_load_NORMAL\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_load_NORMAL\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_load_NORMAL\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_load_NORMAL\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_load_NORMAL\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_load_NORMAL\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_load_WARNING\C-@LOAD_ICON']=. [$'_p9k_get_icon prompt_load_WARNING\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_load_WARNING\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_load_WARNING\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_load_WARNING\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_load_WARNING\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_load_WARNING\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_load_WARNING\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_load_WARNING\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_midnight_commander\C-@MIDNIGHT_COMMANDER_ICON']=mc. [$'_p9k_get_icon prompt_midnight_commander\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_midnight_commander\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_midnight_commander\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_midnight_commander\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_midnight_commander\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_midnight_commander\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_midnight_commander\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_midnight_commander\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_nix_shell\C-@NIX_SHELL_ICON']=. [$'_p9k_get_icon prompt_nix_shell\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_nix_shell\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_nix_shell\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_nix_shell\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_nix_shell\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_nix_shell\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_nix_shell\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_nix_shell\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_nnn\C-@NNN_ICON']=nnn. [$'_p9k_get_icon prompt_nnn\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_nnn\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_nnn\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_nnn\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_nnn\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_nnn\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_nnn\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_nnn\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_os_icon\C-@APPLE_ICON']=. [$'_p9k_get_icon prompt_os_icon\C-@LEFT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_os_icon\C-@LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL']=. [$'_p9k_get_icon prompt_os_icon\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_os_icon\C-@LEFT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_os_icon\C-@LEFT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_os_icon\C-@LEFT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_os_icon\C-@WHITESPACE_BETWEEN_LEFT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_ranger\C-@RANGER_ICON']=. [$'_p9k_get_icon prompt_ranger\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_ranger\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_ranger\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_ranger\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_ranger\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_ranger\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_ranger\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_ranger\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_status_ERROR\C-@CARRIAGE_RETURN_ICON']=↵. [$'_p9k_get_icon prompt_status_ERROR\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_status_ERROR\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_status_ERROR\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_status_ERROR\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_status_ERROR\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_status_ERROR\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_status_ERROR\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_status_ERROR\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_status_ERROR_PIPE\C-@CARRIAGE_RETURN_ICON']=↵. [$'_p9k_get_icon prompt_status_ERROR_PIPE\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_status_ERROR_PIPE\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_status_ERROR_PIPE\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_status_ERROR_PIPE\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_status_ERROR_PIPE\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_status_ERROR_PIPE\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_status_ERROR_PIPE\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_status_ERROR_PIPE\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_status_ERROR_SIGNAL\C-@CARRIAGE_RETURN_ICON']=↵. [$'_p9k_get_icon prompt_status_ERROR_SIGNAL\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_status_ERROR_SIGNAL\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_status_ERROR_SIGNAL\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_status_ERROR_SIGNAL\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_status_ERROR_SIGNAL\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_status_ERROR_SIGNAL\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_status_ERROR_SIGNAL\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_status_ERROR_SIGNAL\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_status_OK\C-@OK_ICON']=. [$'_p9k_get_icon prompt_status_OK\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_status_OK\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_status_OK\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_status_OK\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_status_OK\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_status_OK\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_status_OK\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_status_OK\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_time\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_time\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_time\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_time\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_time\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_time\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_time\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_time\C-@TIME_ICON']=. [$'_p9k_get_icon prompt_time\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_toolbox\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_toolbox\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_toolbox\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_toolbox\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_toolbox\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_toolbox\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_toolbox\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_toolbox\C-@TOOLBOX_ICON']=. [$'_p9k_get_icon prompt_toolbox\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_vcs_CLEAN\C-@LEFT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vcs_CLEAN\C-@LEFT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vcs_CLEAN\C-@LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL']=. [$'_p9k_get_icon prompt_vcs_CLEAN\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_vcs_CLEAN\C-@LEFT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vcs_CLEAN\C-@LEFT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_vcs_CLEAN\C-@LEFT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_vcs_CLEAN\C-@VCS_GIT_GITHUB_ICON']=. [$'_p9k_get_icon prompt_vcs_CLEAN\C-@WHITESPACE_BETWEEN_LEFT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_vcs_LOADING\C-@LEFT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vcs_LOADING\C-@LEFT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vcs_LOADING\C-@LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL']=. [$'_p9k_get_icon prompt_vcs_LOADING\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_vcs_LOADING\C-@LEFT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vcs_LOADING\C-@LEFT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_vcs_LOADING\C-@LEFT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_vcs_LOADING\C-@VCS_GIT_GITHUB_ICON']=. [$'_p9k_get_icon prompt_vcs_LOADING\C-@VCS_LOADING_ICON']=. [$'_p9k_get_icon prompt_vcs_LOADING\C-@WHITESPACE_BETWEEN_LEFT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_vi_mode_NORMAL\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vi_mode_NORMAL\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_vi_mode_NORMAL\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_vi_mode_NORMAL\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vi_mode_NORMAL\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_vi_mode_NORMAL\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_vi_mode_NORMAL\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_vi_mode_OVERWRITE\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vi_mode_OVERWRITE\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_vi_mode_OVERWRITE\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_vi_mode_OVERWRITE\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vi_mode_OVERWRITE\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_vi_mode_OVERWRITE\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_vi_mode_OVERWRITE\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_vi_mode_VISUAL\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vi_mode_VISUAL\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_vi_mode_VISUAL\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_vi_mode_VISUAL\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vi_mode_VISUAL\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_vi_mode_VISUAL\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_vi_mode_VISUAL\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_vim_shell\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vim_shell\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vim_shell\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_vim_shell\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_vim_shell\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_vim_shell\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_vim_shell\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_vim_shell\C-@VIM_ICON']=. [$'_p9k_get_icon prompt_vim_shell\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_xplr\C-@RIGHT_LEFT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_xplr\C-@RIGHT_MIDDLE_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_xplr\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@']=. [$'_p9k_get_icon prompt_xplr\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL']=. [$'_p9k_get_icon prompt_xplr\C-@RIGHT_RIGHT_WHITESPACE\C-@ ']=' .' [$'_p9k_get_icon prompt_xplr\C-@RIGHT_SEGMENT_SEPARATOR']=. [$'_p9k_get_icon prompt_xplr\C-@RIGHT_SUBSEGMENT_SEPARATOR']=╱. [$'_p9k_get_icon prompt_xplr\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@ ']=' .' [$'_p9k_get_icon prompt_xplr\C-@XPLR_ICON']=xplr. [$'_p9k_left_prompt_segment\C-@prompt_dir_DEFAULT\C-@blue\C-@0\C-@\C-A\C-@2']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=88}}${_p9k__n:=${${(M)${:-x004}:#x($_p9k__bg|${_p9k__bg:-0})}:+90}}${_p9k__n:=91}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1ldir+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}0}}}+}${${_p9k__e:#00}:+${${_p9k_t[$_p9k__n]/<_p9k__ss>/$_p9k__ss}/<_p9k__s>/$_p9k__s}${_p9k__c}%b%K{004\\}%F{254\\} ${${:-${_p9k__s::=%F{004\\}}${_p9k__ss::=╱}${_p9k__sss::=%F{004\\}}${_p9k__i::=2}${_p9k__bg::=004}}+}}\C-@00' [$'_p9k_left_prompt_segment\C-@prompt_dir_HOME\C-@blue\C-@0\C-@\C-A\C-@2']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=56}}${_p9k__n:=${${(M)${:-x004}:#x($_p9k__bg|${_p9k__bg:-0})}:+58}}${_p9k__n:=59}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1ldir+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}0}}}+}${${_p9k__e:#00}:+${${_p9k_t[$_p9k__n]/<_p9k__ss>/$_p9k__ss}/<_p9k__s>/$_p9k__s}${_p9k__c}%b%K{004\\}%F{254\\} ${${:-${_p9k__s::=%F{004\\}}${_p9k__ss::=╱}${_p9k__sss::=%F{004\\}}${_p9k__i::=2}${_p9k__bg::=004}}+}}\C-@00' [$'_p9k_left_prompt_segment\C-@prompt_dir_WORK\C-@blue\C-@0\C-@\C-A\C-@2']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=100}}${_p9k__n:=${${(M)${:-x004}:#x($_p9k__bg|${_p9k__bg:-0})}:+102}}${_p9k__n:=103}${_p9k__v::="💻"}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1ldir+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${${_p9k_t[$_p9k__n]/<_p9k__ss>/$_p9k__ss}/<_p9k__s>/$_p9k__s}${_p9k__v}${${(M)_p9k__e:#11}:+ }${_p9k__c}%b%K{004\\}%F{196\\} ${${:-${_p9k__s::=%F{004\\}}${_p9k__ss::=╱}${_p9k__sss::=%F{004\\}}${_p9k__i::=2}${_p9k__bg::=004}}+}}\C-@00' [$'_p9k_left_prompt_segment\C-@prompt_os_icon\C-@black\C-@white\C-@\C-@1']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=52}}${_p9k__n:=${${(M)${:-x007}:#x($_p9k__bg|${_p9k__bg:-0})}:+54}}${_p9k__n:=55}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1los_icon+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}0}}}+}${${_p9k__e:#00}:+${${_p9k_t[$_p9k__n]/<_p9k__ss>/$_p9k__ss}/<_p9k__s>/$_p9k__s}${_p9k__c}%b%K{007\\}%F{232\\} ${${:-${_p9k__s::=%F{007\\}}${_p9k__ss::=╱}${_p9k__sss::=%F{007\\}}${_p9k__i::=1}${_p9k__bg::=007}}+}}\C-@00' [$'_p9k_left_prompt_segment\C-@prompt_vcs_CLEAN\C-@2\C-@0\C-@VCS_GIT_GITHUB_ICON\C-@3']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=116}}${_p9k__n:=${${(M)${:-x002}:#x($_p9k__bg|${_p9k__bg:-0})}:+118}}${_p9k__n:=119}${P9K_VISUAL_IDENTIFIER::=}${_p9k__v::=}${_p9k__c::="${$((my_git_formatter()))+${my_git_format}}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1lvcs+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${${_p9k_t[$_p9k__n]/<_p9k__ss>/$_p9k__ss}/<_p9k__s>/$_p9k__s}${_p9k__v}${${(M)_p9k__e:#11}:+ }${_p9k__c}%b%K{002\\}%F{000\\} ${${:-${_p9k__s::=%F{002\\}}${_p9k__ss::=╱}${_p9k__sss::=%F{002\\}}${_p9k__i::=3}${_p9k__bg::=002}}+}}\C-@10' [$'_p9k_left_prompt_segment\C-@prompt_vcs_LOADING\C-@8\C-@0\C-@VCS_GIT_GITHUB_ICON\C-@3']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=112}}${_p9k__n:=${${(M)${:-x008}:#x($_p9k__bg|${_p9k__bg:-0})}:+114}}${_p9k__n:=115}${P9K_VISUAL_IDENTIFIER::=}${_p9k__v::=}${_p9k__c::="${$((my_git_formatter()))+${my_git_format}}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1lvcs+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${${_p9k_t[$_p9k__n]/<_p9k__ss>/$_p9k__ss}/<_p9k__s>/$_p9k__s}${_p9k__v}${${(M)_p9k__e:#11}:+ }${_p9k__c}%b%K{008\\}%F{000\\} ${${:-${_p9k__s::=%F{008\\}}${_p9k__ss::=╱}${_p9k__sss::=%F{008\\}}${_p9k__i::=3}${_p9k__bg::=008}}+}}\C-@10' [$'_p9k_left_prompt_segment\C-@prompt_vcs_LOADING\C-@8\C-@0\C-@VCS_LOADING_ICON\C-@3']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=120}}${_p9k__n:=${${(M)${:-x008}:#x($_p9k__bg|${_p9k__bg:-0})}:+122}}${_p9k__n:=123}${P9K_VISUAL_IDENTIFIER::=}${_p9k__c::="${$((my_git_formatter()))+${my_git_format}}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1lvcs+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}0}}}+}${${_p9k__e:#00}:+${${_p9k_t[$_p9k__n]/<_p9k__ss>/$_p9k__ss}/<_p9k__s>/$_p9k__s}${_p9k__c}%b%K{008\\}%F{000\\} ${${:-${_p9k__s::=%F{008\\}}${_p9k__ss::=╱}${_p9k__sss::=%F{008\\}}${_p9k__i::=3}${_p9k__bg::=008}}+}}\C-@10' [$'_p9k_param \C-@LEFT_SEGMENT_END_SEPARATOR\C-@ ']=' .' [$'_p9k_param \C-@LEFT_SEGMENT_SEPARATOR\C-@\\uE0B0']='\uE0BC.' [$'_p9k_param \C-@RULER_CHAR\C-@\\u2500']='\u2500.' [$'_p9k_param \C-@VCS_BRANCH_ICON\C-@\\uF126 ']='\uF126 .' [$'_p9k_param \C-@VCS_STAGED_ICON\C-@\\uF055']='\uF055.' [$'_p9k_param \C-@VCS_UNSTAGED_ICON\C-@\\uF06A']='\uF06A.' [$'_p9k_param prompt_background_jobs\C-@BACKGROUND\C-@0']=0. [$'_p9k_param prompt_background_jobs\C-@BACKGROUND_JOBS_ICON\C-@\\uF013']='\uF013.' [$'_p9k_param prompt_background_jobs\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_background_jobs\C-@FOREGROUND\C-@cyan']=6. [$'_p9k_param prompt_background_jobs\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_background_jobs\C-@PREFIX\C-@']=. [$'_p9k_param prompt_background_jobs\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_background_jobs\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_background_jobs\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_background_jobs\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_background_jobs\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_background_jobs\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_background_jobs\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_background_jobs\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_background_jobs\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_background_jobs\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_background_jobs\C-@VISUAL_IDENTIFIER_COLOR\C-@006']=006. [$'_p9k_param prompt_background_jobs\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_background_jobs\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_command_execution_time\C-@BACKGROUND\C-@red']=3. [$'_p9k_param prompt_command_execution_time\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_command_execution_time\C-@EXECUTION_TIME_ICON\C-@\\uF252']='\uF252.' [$'_p9k_param prompt_command_execution_time\C-@FOREGROUND\C-@yellow1']=0. [$'_p9k_param prompt_command_execution_time\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_command_execution_time\C-@PREFIX\C-@']=. [$'_p9k_param prompt_command_execution_time\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_command_execution_time\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_command_execution_time\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_command_execution_time\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_command_execution_time\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_command_execution_time\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_command_execution_time\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_command_execution_time\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_command_execution_time\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_command_execution_time\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_command_execution_time\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_param prompt_command_execution_time\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_command_execution_time\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_context_DEFAULT\C-@BACKGROUND\C-@0']=0. [$'_p9k_param prompt_context_DEFAULT\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']=. [$'_p9k_param prompt_context_DEFAULT\C-@FOREGROUND\C-@yellow']=3. [$'_p9k_param prompt_context_DEFAULT\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_context_DEFAULT\C-@PREFIX\C-@']=. [$'_p9k_param prompt_context_DEFAULT\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_context_DEFAULT\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_context_DEFAULT\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_context_DEFAULT\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_context_DEFAULT\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_context_DEFAULT\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_context_DEFAULT\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_context_DEFAULT\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_context_DEFAULT\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_context_DEFAULT\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']=. [$'_p9k_param prompt_context_DEFAULT\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_context_ROOT\C-@BACKGROUND\C-@0']=0. [$'_p9k_param prompt_context_ROOT\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_context_ROOT\C-@FOREGROUND\C-@yellow']=1. [$'_p9k_param prompt_context_ROOT\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_context_ROOT\C-@PREFIX\C-@']=. [$'_p9k_param prompt_context_ROOT\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_context_ROOT\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_context_ROOT\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_context_ROOT\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_context_ROOT\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_context_ROOT\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_context_ROOT\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_context_ROOT\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_context_ROOT\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_context_ROOT\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_context_ROOT\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_dir_DEFAULT\C-@ANCHOR_BOLD\C-@']=true. [$'_p9k_param prompt_dir_DEFAULT\C-@ANCHOR_FOREGROUND\C-@']=255. [$'_p9k_param prompt_dir_DEFAULT\C-@BACKGROUND\C-@blue']=4. [$'_p9k_param prompt_dir_DEFAULT\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_dir_DEFAULT\C-@FOREGROUND\C-@0']=254. [$'_p9k_param prompt_dir_DEFAULT\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_dir_DEFAULT\C-@LEFT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_dir_DEFAULT\C-@LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0B2.' [$'_p9k_param prompt_dir_DEFAULT\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0BC.' [$'_p9k_param prompt_dir_DEFAULT\C-@LEFT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_dir_DEFAULT\C-@LEFT_SEGMENT_SEPARATOR\C-@\\uE0B0']='\uE0BC.' [$'_p9k_param prompt_dir_DEFAULT\C-@LEFT_SUBSEGMENT_SEPARATOR\C-@\\uE0B1']='\u2571.' [$'_p9k_param prompt_dir_DEFAULT\C-@PATH_HIGHLIGHT_BOLD\C-@']=. [$'_p9k_param prompt_dir_DEFAULT\C-@PATH_SEPARATOR\C-@/']=/. [$'_p9k_param prompt_dir_DEFAULT\C-@PREFIX\C-@']=. [$'_p9k_param prompt_dir_DEFAULT\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_dir_DEFAULT\C-@SHORTENED_FOREGROUND\C-@']=250. [$'_p9k_param prompt_dir_DEFAULT\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_dir_DEFAULT\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_dir_DEFAULT\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_dir_DEFAULT\C-@WHITESPACE_BETWEEN_LEFT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_dir_HOME\C-@ANCHOR_BOLD\C-@']=true. [$'_p9k_param prompt_dir_HOME\C-@ANCHOR_FOREGROUND\C-@']=255. [$'_p9k_param prompt_dir_HOME\C-@BACKGROUND\C-@blue']=4. [$'_p9k_param prompt_dir_HOME\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_dir_HOME\C-@FOREGROUND\C-@0']=254. [$'_p9k_param prompt_dir_HOME\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_dir_HOME\C-@LEFT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_dir_HOME\C-@LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0B2.' [$'_p9k_param prompt_dir_HOME\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0BC.' [$'_p9k_param prompt_dir_HOME\C-@LEFT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_dir_HOME\C-@LEFT_SEGMENT_SEPARATOR\C-@\\uE0B0']='\uE0BC.' [$'_p9k_param prompt_dir_HOME\C-@LEFT_SUBSEGMENT_SEPARATOR\C-@\\uE0B1']='\u2571.' [$'_p9k_param prompt_dir_HOME\C-@PATH_HIGHLIGHT_BOLD\C-@']=. [$'_p9k_param prompt_dir_HOME\C-@PATH_SEPARATOR\C-@/']=/. [$'_p9k_param prompt_dir_HOME\C-@PREFIX\C-@']=. [$'_p9k_param prompt_dir_HOME\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_dir_HOME\C-@SHORTENED_FOREGROUND\C-@']=250. [$'_p9k_param prompt_dir_HOME\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_dir_HOME\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_dir_HOME\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_dir_HOME\C-@WHITESPACE_BETWEEN_LEFT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_dir_WORK\C-@ANCHOR_BOLD\C-@']=true. [$'_p9k_param prompt_dir_WORK\C-@ANCHOR_FOREGROUND\C-@']=196. [$'_p9k_param prompt_dir_WORK\C-@BACKGROUND\C-@blue']=4. [$'_p9k_param prompt_dir_WORK\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_dir_WORK\C-@FOREGROUND\C-@0']=196. [$'_p9k_param prompt_dir_WORK\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_dir_WORK\C-@LEFT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_dir_WORK\C-@LEFT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_dir_WORK\C-@LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0B2.' [$'_p9k_param prompt_dir_WORK\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0BC.' [$'_p9k_param prompt_dir_WORK\C-@LEFT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_dir_WORK\C-@LEFT_SEGMENT_SEPARATOR\C-@\\uE0B0']='\uE0BC.' [$'_p9k_param prompt_dir_WORK\C-@LEFT_SUBSEGMENT_SEPARATOR\C-@\\uE0B1']='\u2571.' [$'_p9k_param prompt_dir_WORK\C-@PATH_HIGHLIGHT_BOLD\C-@']=. [$'_p9k_param prompt_dir_WORK\C-@PATH_SEPARATOR\C-@/']=/. [$'_p9k_param prompt_dir_WORK\C-@PREFIX\C-@']=. [$'_p9k_param prompt_dir_WORK\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_dir_WORK\C-@SHORTENED_FOREGROUND\C-@']=250. [$'_p9k_param prompt_dir_WORK\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_dir_WORK\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_dir_WORK\C-@VISUAL_IDENTIFIER_COLOR\C-@196']=196. [$'_p9k_param prompt_dir_WORK\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']=💻. [$'_p9k_param prompt_dir_WORK\C-@WHITESPACE_BETWEEN_LEFT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_empty_line\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']=. [$'_p9k_param prompt_load_CRITICAL\C-@BACKGROUND\C-@red']=1. [$'_p9k_param prompt_load_CRITICAL\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_load_CRITICAL\C-@FOREGROUND\C-@0']=0. [$'_p9k_param prompt_load_CRITICAL\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_load_CRITICAL\C-@LOAD_ICON\C-@\\uF080']='\uF080.' [$'_p9k_param prompt_load_CRITICAL\C-@PREFIX\C-@']=. [$'_p9k_param prompt_load_CRITICAL\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_load_CRITICAL\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_load_CRITICAL\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_load_CRITICAL\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_load_CRITICAL\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_load_CRITICAL\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_load_CRITICAL\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_load_CRITICAL\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_load_CRITICAL\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_load_CRITICAL\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_load_CRITICAL\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_param prompt_load_CRITICAL\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_load_CRITICAL\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_load_NORMAL\C-@BACKGROUND\C-@green']=2. [$'_p9k_param prompt_load_NORMAL\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_load_NORMAL\C-@FOREGROUND\C-@0']=0. [$'_p9k_param prompt_load_NORMAL\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_load_NORMAL\C-@LOAD_ICON\C-@\\uF080']='\uF080.' [$'_p9k_param prompt_load_NORMAL\C-@PREFIX\C-@']=. [$'_p9k_param prompt_load_NORMAL\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_load_NORMAL\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_load_NORMAL\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_load_NORMAL\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_load_NORMAL\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_load_NORMAL\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_load_NORMAL\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_load_NORMAL\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_load_NORMAL\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_load_NORMAL\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_load_NORMAL\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_param prompt_load_NORMAL\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_load_NORMAL\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_load_WARNING\C-@BACKGROUND\C-@yellow']=3. [$'_p9k_param prompt_load_WARNING\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_load_WARNING\C-@FOREGROUND\C-@0']=0. [$'_p9k_param prompt_load_WARNING\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_load_WARNING\C-@LOAD_ICON\C-@\\uF080']='\uF080.' [$'_p9k_param prompt_load_WARNING\C-@PREFIX\C-@']=. [$'_p9k_param prompt_load_WARNING\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_load_WARNING\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_load_WARNING\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_load_WARNING\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_load_WARNING\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_load_WARNING\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_load_WARNING\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_load_WARNING\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_load_WARNING\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_load_WARNING\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_load_WARNING\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_param prompt_load_WARNING\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_load_WARNING\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_midnight_commander\C-@BACKGROUND\C-@0']=0. [$'_p9k_param prompt_midnight_commander\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_midnight_commander\C-@FOREGROUND\C-@yellow']=3. [$'_p9k_param prompt_midnight_commander\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_midnight_commander\C-@MIDNIGHT_COMMANDER_ICON\C-@mc']=mc. [$'_p9k_param prompt_midnight_commander\C-@PREFIX\C-@']=. [$'_p9k_param prompt_midnight_commander\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_midnight_commander\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_midnight_commander\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_midnight_commander\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_midnight_commander\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_midnight_commander\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_midnight_commander\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_midnight_commander\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_midnight_commander\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_midnight_commander\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_midnight_commander\C-@VISUAL_IDENTIFIER_COLOR\C-@003']=003. [$'_p9k_param prompt_midnight_commander\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_midnight_commander\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_nix_shell\C-@BACKGROUND\C-@4']=4. [$'_p9k_param prompt_nix_shell\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_nix_shell\C-@FOREGROUND\C-@0']=0. [$'_p9k_param prompt_nix_shell\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_nix_shell\C-@NIX_SHELL_ICON\C-@\\uF313']='\uF313.' [$'_p9k_param prompt_nix_shell\C-@PREFIX\C-@']=. [$'_p9k_param prompt_nix_shell\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_nix_shell\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_nix_shell\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_nix_shell\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_nix_shell\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_nix_shell\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_nix_shell\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_nix_shell\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_nix_shell\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_nix_shell\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_nix_shell\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_param prompt_nix_shell\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_nix_shell\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_nnn\C-@BACKGROUND\C-@6']=6. [$'_p9k_param prompt_nnn\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_nnn\C-@FOREGROUND\C-@0']=0. [$'_p9k_param prompt_nnn\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_nnn\C-@NNN_ICON\C-@nnn']=nnn. [$'_p9k_param prompt_nnn\C-@PREFIX\C-@']=. [$'_p9k_param prompt_nnn\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_nnn\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_nnn\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_nnn\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_nnn\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_nnn\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_nnn\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_nnn\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_nnn\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_nnn\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_nnn\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_param prompt_nnn\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_nnn\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_os_icon\C-@APPLE_ICON\C-@\\uF179']='\uF179.' [$'_p9k_param prompt_os_icon\C-@BACKGROUND\C-@black']=7. [$'_p9k_param prompt_os_icon\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_os_icon\C-@FOREGROUND\C-@white']=232. [$'_p9k_param prompt_os_icon\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_os_icon\C-@LEFT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_os_icon\C-@LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0B2.' [$'_p9k_param prompt_os_icon\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0BC.' [$'_p9k_param prompt_os_icon\C-@LEFT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_os_icon\C-@LEFT_SEGMENT_SEPARATOR\C-@\\uE0B0']='\uE0BC.' [$'_p9k_param prompt_os_icon\C-@LEFT_SUBSEGMENT_SEPARATOR\C-@\\uE0B1']='\u2571.' [$'_p9k_param prompt_os_icon\C-@PREFIX\C-@']=. [$'_p9k_param prompt_os_icon\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_os_icon\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_os_icon\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_os_icon\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_os_icon\C-@WHITESPACE_BETWEEN_LEFT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_ranger\C-@BACKGROUND\C-@0']=0. [$'_p9k_param prompt_ranger\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_ranger\C-@FOREGROUND\C-@yellow']=3. [$'_p9k_param prompt_ranger\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_ranger\C-@PREFIX\C-@']=. [$'_p9k_param prompt_ranger\C-@RANGER_ICON\C-@\\uF00b']='\uF00b.' [$'_p9k_param prompt_ranger\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_ranger\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_ranger\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_ranger\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_ranger\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_ranger\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_ranger\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_ranger\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_ranger\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_ranger\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_ranger\C-@VISUAL_IDENTIFIER_COLOR\C-@003']=003. [$'_p9k_param prompt_ranger\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_ranger\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_ruler\C-@BACKGROUND\C-@']=. [$'_p9k_param prompt_ruler\C-@FOREGROUND\C-@']=. [$'_p9k_param prompt_status_ERROR\C-@BACKGROUND\C-@red']=1. [$'_p9k_param prompt_status_ERROR\C-@CARRIAGE_RETURN_ICON\C-@\\u21B5']='\u21B5.' [$'_p9k_param prompt_status_ERROR\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_status_ERROR\C-@FOREGROUND\C-@yellow1']=3. [$'_p9k_param prompt_status_ERROR\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_status_ERROR\C-@PREFIX\C-@']=. [$'_p9k_param prompt_status_ERROR\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_ERROR\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_ERROR\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_status_ERROR\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_status_ERROR\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_ERROR\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_status_ERROR\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_status_ERROR\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_status_ERROR\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_status_ERROR\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_status_ERROR\C-@VISUAL_IDENTIFIER_COLOR\C-@003']=003. [$'_p9k_param prompt_status_ERROR\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']=✘. [$'_p9k_param prompt_status_ERROR\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_ERROR_PIPE\C-@BACKGROUND\C-@red']=1. [$'_p9k_param prompt_status_ERROR_PIPE\C-@CARRIAGE_RETURN_ICON\C-@\\u21B5']='\u21B5.' [$'_p9k_param prompt_status_ERROR_PIPE\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_status_ERROR_PIPE\C-@FOREGROUND\C-@yellow1']=3. [$'_p9k_param prompt_status_ERROR_PIPE\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_status_ERROR_PIPE\C-@PREFIX\C-@']=. [$'_p9k_param prompt_status_ERROR_PIPE\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_ERROR_PIPE\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_ERROR_PIPE\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_status_ERROR_PIPE\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_status_ERROR_PIPE\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_ERROR_PIPE\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_status_ERROR_PIPE\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_status_ERROR_PIPE\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_status_ERROR_PIPE\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_status_ERROR_PIPE\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_status_ERROR_PIPE\C-@VISUAL_IDENTIFIER_COLOR\C-@003']=003. [$'_p9k_param prompt_status_ERROR_PIPE\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']=✘. [$'_p9k_param prompt_status_ERROR_PIPE\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@BACKGROUND\C-@red']=1. [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@CARRIAGE_RETURN_ICON\C-@\\u21B5']='\u21B5.' [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@FOREGROUND\C-@yellow1']=3. [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@PREFIX\C-@']=. [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@VISUAL_IDENTIFIER_COLOR\C-@003']=003. [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']=✘. [$'_p9k_param prompt_status_ERROR_SIGNAL\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_OK\C-@BACKGROUND\C-@0']=0. [$'_p9k_param prompt_status_OK\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_status_OK\C-@FOREGROUND\C-@green']=2. [$'_p9k_param prompt_status_OK\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_status_OK\C-@OK_ICON\C-@\\uF00C']='\uF00C.' [$'_p9k_param prompt_status_OK\C-@PREFIX\C-@']=. [$'_p9k_param prompt_status_OK\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_OK\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_OK\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_status_OK\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_status_OK\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_status_OK\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_status_OK\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_status_OK\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_status_OK\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_status_OK\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_status_OK\C-@VISUAL_IDENTIFIER_COLOR\C-@002']=002. [$'_p9k_param prompt_status_OK\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']=✔. [$'_p9k_param prompt_status_OK\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_time\C-@BACKGROUND\C-@7']=7. [$'_p9k_param prompt_time\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_time\C-@FOREGROUND\C-@0']=0. [$'_p9k_param prompt_time\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_time\C-@PREFIX\C-@']=. [$'_p9k_param prompt_time\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_time\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_time\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_time\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_time\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_time\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_time\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_time\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_time\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_time\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_time\C-@TIME_ICON\C-@\\uF017']='\uF017.' [$'_p9k_param prompt_time\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_param prompt_time\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_time\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_toolbox\C-@BACKGROUND\C-@0']=3. [$'_p9k_param prompt_toolbox\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_TOOLBOX_NAME:#fedora-toolbox-*}.' [$'_p9k_param prompt_toolbox\C-@FOREGROUND\C-@yellow']=0. [$'_p9k_param prompt_toolbox\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_toolbox\C-@PREFIX\C-@']=. [$'_p9k_param prompt_toolbox\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_toolbox\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_toolbox\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_toolbox\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_toolbox\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_toolbox\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_toolbox\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_toolbox\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_toolbox\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_toolbox\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_toolbox\C-@TOOLBOX_ICON\C-@\\uE20F']='\uE20F.' [$'_p9k_param prompt_toolbox\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_param prompt_toolbox\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_toolbox\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vcs_CLEAN\C-@BACKGROUND\C-@2']=2. [$'_p9k_param prompt_vcs_CLEAN\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${$((my_git_formatter()))+${my_git_format}}.' [$'_p9k_param prompt_vcs_CLEAN\C-@CONTENT_EXPANSION\C-@x']='${$((my_git_formatter()))+${my_git_format}}.' [$'_p9k_param prompt_vcs_CLEAN\C-@FOREGROUND\C-@0']=0. [$'_p9k_param prompt_vcs_CLEAN\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_vcs_CLEAN\C-@LEFT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vcs_CLEAN\C-@LEFT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vcs_CLEAN\C-@LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0B2.' [$'_p9k_param prompt_vcs_CLEAN\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0BC.' [$'_p9k_param prompt_vcs_CLEAN\C-@LEFT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vcs_CLEAN\C-@LEFT_SEGMENT_SEPARATOR\C-@\\uE0B0']='\uE0BC.' [$'_p9k_param prompt_vcs_CLEAN\C-@LEFT_SUBSEGMENT_SEPARATOR\C-@\\uE0B1']='\u2571.' [$'_p9k_param prompt_vcs_CLEAN\C-@PREFIX\C-@']=. [$'_p9k_param prompt_vcs_CLEAN\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_vcs_CLEAN\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_vcs_CLEAN\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_vcs_CLEAN\C-@VCS_GIT_GITHUB_ICON\C-@\\uF113']='\uF113.' [$'_p9k_param prompt_vcs_CLEAN\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_param prompt_vcs_CLEAN\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_vcs_CLEAN\C-@WHITESPACE_BETWEEN_LEFT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vcs_CONFLICTED\C-@CONTENT_EXPANSION\C-@x']='${$((my_git_formatter()))+${my_git_format}}.' [$'_p9k_param prompt_vcs_LOADING\C-@BACKGROUND\C-@8']=8. [$'_p9k_param prompt_vcs_LOADING\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${$((my_git_formatter()))+${my_git_format}}.' [$'_p9k_param prompt_vcs_LOADING\C-@CONTENT_EXPANSION\C-@x']='${$((my_git_formatter()))+${my_git_format}}.' [$'_p9k_param prompt_vcs_LOADING\C-@FOREGROUND\C-@0']=0. [$'_p9k_param prompt_vcs_LOADING\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_vcs_LOADING\C-@LEFT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vcs_LOADING\C-@LEFT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vcs_LOADING\C-@LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0B2.' [$'_p9k_param prompt_vcs_LOADING\C-@LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0BC.' [$'_p9k_param prompt_vcs_LOADING\C-@LEFT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vcs_LOADING\C-@LEFT_SEGMENT_SEPARATOR\C-@\\uE0B0']='\uE0BC.' [$'_p9k_param prompt_vcs_LOADING\C-@LEFT_SUBSEGMENT_SEPARATOR\C-@\\uE0B1']='\u2571.' [$'_p9k_param prompt_vcs_LOADING\C-@PREFIX\C-@']=. [$'_p9k_param prompt_vcs_LOADING\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_vcs_LOADING\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_vcs_LOADING\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_vcs_LOADING\C-@VCS_GIT_GITHUB_ICON\C-@\\uF113']='\uF113.' [$'_p9k_param prompt_vcs_LOADING\C-@VCS_LOADING_ICON']=. [$'_p9k_param prompt_vcs_LOADING\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_param prompt_vcs_LOADING\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_vcs_LOADING\C-@WHITESPACE_BETWEEN_LEFT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vcs_MODIFIED\C-@CONTENT_EXPANSION\C-@x']='${$((my_git_formatter()))+${my_git_format}}.' [$'_p9k_param prompt_vcs_UNTRACKED\C-@CONTENT_EXPANSION\C-@x']='${$((my_git_formatter()))+${my_git_format}}.' [$'_p9k_param prompt_vi_mode_NORMAL\C-@BACKGROUND\C-@0']=2. [$'_p9k_param prompt_vi_mode_NORMAL\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_vi_mode_NORMAL\C-@FOREGROUND\C-@white']=0. [$'_p9k_param prompt_vi_mode_NORMAL\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_vi_mode_NORMAL\C-@PREFIX\C-@']=. [$'_p9k_param prompt_vi_mode_NORMAL\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vi_mode_NORMAL\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_vi_mode_NORMAL\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_vi_mode_NORMAL\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vi_mode_NORMAL\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_vi_mode_NORMAL\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_vi_mode_NORMAL\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_vi_mode_NORMAL\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_vi_mode_NORMAL\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_vi_mode_NORMAL\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_vi_mode_NORMAL\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@BACKGROUND\C-@0']=3. [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@FOREGROUND\C-@blue']=0. [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@PREFIX\C-@']=. [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_vi_mode_OVERWRITE\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vi_mode_VISUAL\C-@BACKGROUND\C-@0']=4. [$'_p9k_param prompt_vi_mode_VISUAL\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_vi_mode_VISUAL\C-@FOREGROUND\C-@white']=0. [$'_p9k_param prompt_vi_mode_VISUAL\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_vi_mode_VISUAL\C-@PREFIX\C-@']=. [$'_p9k_param prompt_vi_mode_VISUAL\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vi_mode_VISUAL\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_vi_mode_VISUAL\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_vi_mode_VISUAL\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vi_mode_VISUAL\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_vi_mode_VISUAL\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_vi_mode_VISUAL\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_vi_mode_VISUAL\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_vi_mode_VISUAL\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_vi_mode_VISUAL\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_vi_mode_VISUAL\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vim_shell\C-@BACKGROUND\C-@green']=2. [$'_p9k_param prompt_vim_shell\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_vim_shell\C-@FOREGROUND\C-@0']=0. [$'_p9k_param prompt_vim_shell\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_vim_shell\C-@PREFIX\C-@']=. [$'_p9k_param prompt_vim_shell\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vim_shell\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vim_shell\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_vim_shell\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_vim_shell\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_vim_shell\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_vim_shell\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_vim_shell\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_vim_shell\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_vim_shell\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_vim_shell\C-@VIM_ICON\C-@\\uE62B']='\uE62B.' [$'_p9k_param prompt_vim_shell\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_param prompt_vim_shell\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_vim_shell\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_xplr\C-@BACKGROUND\C-@6']=6. [$'_p9k_param prompt_xplr\C-@CONTENT_EXPANSION\C-@${P9K_CONTENT}']='${P9K_CONTENT}.' [$'_p9k_param prompt_xplr\C-@FOREGROUND\C-@0']=0. [$'_p9k_param prompt_xplr\C-@ICON_BEFORE_CONTENT\C-@']=. [$'_p9k_param prompt_xplr\C-@PREFIX\C-@']=. [$'_p9k_param prompt_xplr\C-@RIGHT_LEFT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_xplr\C-@RIGHT_MIDDLE_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_xplr\C-@RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL\C-@\C-A']='\uE0BA.' [$'_p9k_param prompt_xplr\C-@RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL\C-@\C-A']='\uE0B0.' [$'_p9k_param prompt_xplr\C-@RIGHT_RIGHT_WHITESPACE\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_xplr\C-@RIGHT_SEGMENT_SEPARATOR\C-@\\uE0B2']='\uE0BA.' [$'_p9k_param prompt_xplr\C-@RIGHT_SUBSEGMENT_SEPARATOR\C-@\\uE0B3']='\u2571.' [$'_p9k_param prompt_xplr\C-@SELF_JOINED\C-@false']=false. [$'_p9k_param prompt_xplr\C-@SHOW_ON_UPGLOB\C-@']=. [$'_p9k_param prompt_xplr\C-@SUFFIX\C-@']=. [$'_p9k_param prompt_xplr\C-@VISUAL_IDENTIFIER_COLOR\C-@000']=000. [$'_p9k_param prompt_xplr\C-@VISUAL_IDENTIFIER_EXPANSION\C-@${P9K_VISUAL_IDENTIFIER}']='${P9K_VISUAL_IDENTIFIER}.' [$'_p9k_param prompt_xplr\C-@WHITESPACE_BETWEEN_RIGHT_SEGMENTS\C-@\C-A ']=$'\C-A .' [$'_p9k_param prompt_xplr\C-@XPLR_ICON\C-@xplr']=xplr. [$'_p9k_right_prompt_segment\C-@prompt_background_jobs\C-@0\C-@cyan\C-@BACKGROUND_JOBS_ICON\C-@3']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=12}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(000|000)}:+14}}${_p9k__n:=15}${_p9k__v::=}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rbackground_jobs+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{000\\}%F{006\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{000\\}%F{006\\} %b%K{000\\}%F{006\\}}${_p9k__sss::=%b%K{000\\}%F{006\\} %k%F{000\\}%b%K{000\\}%F{006\\}}${_p9k__i::=3}${_p9k__bg::=000}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_command_execution_time\C-@red\C-@yellow1\C-@EXECUTION_TIME_ICON\C-@2']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=96}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(003|003)}:+98}}${_p9k__n:=99}${_p9k__v::=}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rcommand_execution_time+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{003\\}%F{000\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{003\\}%F{000\\} %b%K{003\\}%F{000\\}}${_p9k__sss::=%b%K{003\\}%F{000\\} %k%F{003\\}%b%K{003\\}%F{000\\}}${_p9k__i::=2}${_p9k__bg::=003}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_context_DEFAULT\C-@0\C-@yellow\C-@\C-@30']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=16}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(000|000)}:+18}}${_p9k__n:=19}${_p9k__c::=}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rcontext+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}0}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{000\\}%F{003\\}${${:-${_p9k__w::=%b%K{000\\}%F{003\\} %b%K{000\\}%F{003\\}}${_p9k__sss::=%b%K{000\\}%F{003\\} %k%F{000\\}%b%K{000\\}%F{003\\}}${_p9k__i::=30}${_p9k__bg::=000}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_context_ROOT\C-@0\C-@yellow\C-@\C-@30']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=20}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(000|000)}:+22}}${_p9k__n:=23}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rcontext+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}0}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{000\\}%F{001\\}${${:-${_p9k__w::=%b%K{000\\}%F{001\\} %b%K{000\\}%F{001\\}}${_p9k__sss::=%b%K{000\\}%F{001\\} %k%F{000\\}%b%K{000\\}%F{001\\}}${_p9k__i::=30}${_p9k__bg::=000}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_load_CRITICAL\C-@red\C-@0\C-@LOAD_ICON\C-@39']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=36}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(001|001)}:+38}}${_p9k__n:=39}${_p9k__v::=}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rload+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{001\\}%F{000\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{001\\}%F{000\\} %b%K{001\\}%F{000\\}}${_p9k__sss::=%b%K{001\\}%F{000\\} %k%F{001\\}%b%K{001\\}%F{000\\}}${_p9k__i::=39}${_p9k__bg::=001}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_load_NORMAL\C-@green\C-@0\C-@LOAD_ICON\C-@39']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=44}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(002|002)}:+46}}${_p9k__n:=47}${_p9k__v::=}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rload+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{002\\}%F{000\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{002\\}%F{000\\} %b%K{002\\}%F{000\\}}${_p9k__sss::=%b%K{002\\}%F{000\\} %k%F{002\\}%b%K{002\\}%F{000\\}}${_p9k__i::=39}${_p9k__bg::=002}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_load_WARNING\C-@yellow\C-@0\C-@LOAD_ICON\C-@39']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=40}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(003|003)}:+42}}${_p9k__n:=43}${_p9k__v::=}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rload+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{003\\}%F{000\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{003\\}%F{000\\} %b%K{003\\}%F{000\\}}${_p9k__sss::=%b%K{003\\}%F{000\\} %k%F{003\\}%b%K{003\\}%F{000\\}}${_p9k__i::=39}${_p9k__bg::=003}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_midnight_commander\C-@0\C-@yellow\C-@MIDNIGHT_COMMANDER_ICON\C-@36']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=80}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(000|000)}:+82}}${_p9k__n:=83}${_p9k__v::=mc}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rmidnight_commander+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{000\\}%F{003\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{000\\}%F{003\\} %b%K{000\\}%F{003\\}}${_p9k__sss::=%b%K{000\\}%F{003\\} %k%F{000\\}%b%K{000\\}%F{003\\}}${_p9k__i::=36}${_p9k__bg::=000}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_nix_shell\C-@4\C-@0\C-@NIX_SHELL_ICON\C-@37']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=84}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(004|004)}:+86}}${_p9k__n:=87}${_p9k__v::=}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rnix_shell+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{004\\}%F{000\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{004\\}%F{000\\} %b%K{004\\}%F{000\\}}${_p9k__sss::=%b%K{004\\}%F{000\\} %k%F{004\\}%b%K{004\\}%F{000\\}}${_p9k__i::=37}${_p9k__bg::=004}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_nnn\C-@6\C-@0\C-@NNN_ICON\C-@33']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=68}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(006|006)}:+70}}${_p9k__n:=71}${_p9k__v::=nnn}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rnnn+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{006\\}%F{000\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{006\\}%F{000\\} %b%K{006\\}%F{000\\}}${_p9k__sss::=%b%K{006\\}%F{000\\} %k%F{006\\}%b%K{006\\}%F{000\\}}${_p9k__i::=33}${_p9k__bg::=006}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_ranger\C-@0\C-@yellow\C-@RANGER_ICON\C-@32']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=64}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(000|000)}:+66}}${_p9k__n:=67}${_p9k__v::=}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rranger+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{000\\}%F{003\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{000\\}%F{003\\} %b%K{000\\}%F{003\\}}${_p9k__sss::=%b%K{000\\}%F{003\\} %k%F{000\\}%b%K{000\\}%F{003\\}}${_p9k__i::=32}${_p9k__bg::=000}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_status_ERROR\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@1']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=108}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(001|001)}:+110}}${_p9k__n:=111}${_p9k__v::="✘"}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rstatus+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{001\\}%F{003\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{001\\}%F{003\\} %b%K{001\\}%F{003\\}}${_p9k__sss::=%b%K{001\\}%F{003\\} %k%F{001\\}%b%K{001\\}%F{003\\}}${_p9k__i::=1}${_p9k__bg::=001}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_status_ERROR_PIPE\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@1']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=104}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(001|001)}:+106}}${_p9k__n:=107}${_p9k__v::="✘"}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rstatus+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{001\\}%F{003\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{001\\}%F{003\\} %b%K{001\\}%F{003\\}}${_p9k__sss::=%b%K{001\\}%F{003\\} %k%F{001\\}%b%K{001\\}%F{003\\}}${_p9k__i::=1}${_p9k__bg::=001}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_status_ERROR_SIGNAL\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@1']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=92}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(001|001)}:+94}}${_p9k__n:=95}${_p9k__v::="✘"}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rstatus+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{001\\}%F{003\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{001\\}%F{003\\} %b%K{001\\}%F{003\\}}${_p9k__sss::=%b%K{001\\}%F{003\\} %k%F{001\\}%b%K{001\\}%F{003\\}}${_p9k__i::=1}${_p9k__bg::=001}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_status_OK\C-@0\C-@green\C-@OK_ICON\C-@1']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=8}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(000|000)}:+10}}${_p9k__n:=11}${_p9k__v::="✔"}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rstatus+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{000\\}%F{002\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{000\\}%F{002\\} %b%K{000\\}%F{002\\}}${_p9k__sss::=%b%K{000\\}%F{002\\} %k%F{000\\}%b%K{000\\}%F{002\\}}${_p9k__i::=1}${_p9k__bg::=000}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_time\C-@7\C-@0\C-@TIME_ICON\C-@43']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=48}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(007|007)}:+50}}${_p9k__n:=51}${_p9k__v::=}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rtime+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{007\\}%F{000\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{007\\}%F{000\\} %b%K{007\\}%F{000\\}}${_p9k__sss::=%b%K{007\\}%F{000\\} %k%F{007\\}%b%K{007\\}%F{000\\}}${_p9k__i::=43}${_p9k__bg::=007}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_toolbox\C-@0\C-@yellow\C-@TOOLBOX_ICON\C-@29']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=60}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(003|003)}:+62}}${_p9k__n:=63}${P9K_VISUAL_IDENTIFIER::=}${_p9k__v::=}${_p9k__c::="${P9K_TOOLBOX_NAME:#fedora-toolbox-*}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rtoolbox+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{003\\}%F{000\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{003\\}%F{000\\} %b%K{003\\}%F{000\\}}${_p9k__sss::=%b%K{003\\}%F{000\\} %k%F{003\\}%b%K{003\\}%F{000\\}}${_p9k__i::=29}${_p9k__bg::=003}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_vi_mode_NORMAL\C-@0\C-@white\C-@\C-@38']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=28}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(002|002)}:+30}}${_p9k__n:=31}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rvi_mode+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}0}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{002\\}%F{000\\}${${:-${_p9k__w::=%b%K{002\\}%F{000\\} %b%K{002\\}%F{000\\}}${_p9k__sss::=%b%K{002\\}%F{000\\} %k%F{002\\}%b%K{002\\}%F{000\\}}${_p9k__i::=38}${_p9k__bg::=002}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_vi_mode_OVERWRITE\C-@0\C-@blue\C-@\C-@38']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=24}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(003|003)}:+26}}${_p9k__n:=27}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rvi_mode+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}0}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{003\\}%F{000\\}${${:-${_p9k__w::=%b%K{003\\}%F{000\\} %b%K{003\\}%F{000\\}}${_p9k__sss::=%b%K{003\\}%F{000\\} %k%F{003\\}%b%K{003\\}%F{000\\}}${_p9k__i::=38}${_p9k__bg::=003}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_vi_mode_VISUAL\C-@0\C-@white\C-@\C-@38']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=32}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(004|004)}:+34}}${_p9k__n:=35}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rvi_mode+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}0}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{004\\}%F{000\\}${${:-${_p9k__w::=%b%K{004\\}%F{000\\} %b%K{004\\}%F{000\\}}${_p9k__sss::=%b%K{004\\}%F{000\\} %k%F{004\\}%b%K{004\\}%F{000\\}}${_p9k__i::=38}${_p9k__bg::=004}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_vim_shell\C-@green\C-@0\C-@VIM_ICON\C-@35']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=76}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(002|002)}:+78}}${_p9k__n:=79}${_p9k__v::=}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rvim_shell+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{002\\}%F{000\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{002\\}%F{000\\} %b%K{002\\}%F{000\\}}${_p9k__sss::=%b%K{002\\}%F{000\\} %k%F{002\\}%b%K{002\\}%F{000\\}}${_p9k__i::=35}${_p9k__bg::=002}}+}}\C-@00' [$'_p9k_right_prompt_segment\C-@prompt_xplr\C-@6\C-@0\C-@XPLR_ICON\C-@34']=$'${_p9k__n::=}${${${_p9k__bg:-0}:#NONE}:-${_p9k__n::=72}}${_p9k__n:=${${(M)${:-x$_p9k__bg}:#x(006|006)}:+74}}${_p9k__n:=75}${_p9k__v::=xplr}${_p9k__c::="${P9K_CONTENT}"}${_p9k__c::=${_p9k__c//\C-M}}${_p9k__e::=${${_p9k__1rxplr+00}:-${${(%):-$_p9k__c%1(l.1.0)}[-1]}1}}}+}${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/<_p9k__w>/$_p9k__w}${_p9k__c}%b%K{006\\}%F{000\\}${${(M)_p9k__e:#11}:+ }$_p9k__v${${:-${_p9k__w::=%b%K{006\\}%F{000\\} %b%K{006\\}%F{000\\}}${_p9k__sss::=%b%K{006\\}%F{000\\} %k%F{006\\}%b%K{006\\}%F{000\\}}${_p9k__i::=34}${_p9k__bg::=006}}+}}\C-@00' [$'prompt_status\C-@0\C-@0\C-@0']=$'prompt_status_OK\C-@0\C-@green\C-@OK_ICON\C-@0\C-@\C-@0' [$'prompt_status\C-@0\C-@0']=$'prompt_status_OK\C-@0\C-@green\C-@OK_ICON\C-@0\C-@\C-@0' [$'prompt_status\C-@1\C-@0\C-@1']=$'prompt_status_ERROR_PIPE\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@0\C-@\C-@0|10' [$'prompt_status\C-@1\C-@1']=$'prompt_status_ERROR\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@0\C-@\C-@10' [$'prompt_status\C-@1\C-@127\C-@1']=$'prompt_status_ERROR_PIPE\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@0\C-@\C-@127|10' [$'prompt_status\C-@126\C-@126']=$'prompt_status_ERROR\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@0\C-@\C-@1260' [$'prompt_status\C-@127\C-@0\C-@127']=$'prompt_status_ERROR_PIPE\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@0\C-@\C-@0|1270' [$'prompt_status\C-@127\C-@127']=$'prompt_status_ERROR\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@0\C-@\C-@1270' [$'prompt_status\C-@130\C-@130']=$'prompt_status_ERROR_SIGNAL\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@0\C-@\C-@INT0' [$'prompt_status\C-@2\C-@0\C-@2']=$'prompt_status_ERROR_PIPE\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@0\C-@\C-@0|20' [$'prompt_status\C-@2\C-@141\C-@2']=$'prompt_status_ERROR_PIPE\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@0\C-@\C-@PIPE|20' [$'prompt_status\C-@2\C-@2']=$'prompt_status_ERROR\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@0\C-@\C-@20' [$'prompt_status\C-@9\C-@9']=$'prompt_status_ERROR\C-@red\C-@yellow1\C-@CARRIAGE_RETURN_ICON\C-@0\C-@\C-@90')
	typeset -g -F _p9k_taskwarrior_next_due=0.0000000000
	typeset -g _POWERLEVEL9K_CONTEXT_ROOT_BACKGROUND=0
	typeset -g _POWERLEVEL9K_ASDF_PERL_BACKGROUND=4
	typeset -g _p9k_os=OSX
	typeset -g _POWERLEVEL9K_STATUS_OK_PIPE_VISUAL_IDENTIFIER_EXPANSION=✔
	typeset -g _POWERLEVEL9K_VIRTUALENV_LEFT_DELIMITER=''
	typeset -g _POWERLEVEL9K_HASKELL_STACK_ALWAYS_SHOW=true
	typeset -g _POWERLEVEL9K_STATUS_ERROR_BACKGROUND=1
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_CONTENT_EXPANSION=❯
	typeset -g _POWERLEVEL9K_AZURE_FOREGROUND=7
	typeset -g _POWERLEVEL9K_ASDF_DOTNET_CORE_BACKGROUND=5
	typeset -g -i _POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_CONTENT_EXPANSION=❯
	typeset -g _POWERLEVEL9K_PROXY_BACKGROUND=0
	typeset -g -a _POWERLEVEL9K_BATTERY_LOW_STAGES=(          )
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_ERROR_VICMD_FOREGROUND=196
	typeset -g _POWERLEVEL9K_ASDF_FOREGROUND=0
	typeset -g _p9k_gap_pre='${(e)_p9k_t[6]}'
	typeset -g _p9k_taskwarrior_meta_sig=''
	typeset -g _p9k_uname=Darwin
	typeset -g _POWERLEVEL9K_STATUS_ERROR_PIPE_VISUAL_IDENTIFIER_EXPANSION=✘
	typeset -g _POWERLEVEL9K_CONFIG_FILE=/Users/sedatkilinc/.p10k.zsh
	typeset -g _POWERLEVEL9K_MULTILINE_FIRST_PROMPT_SUFFIX=%242F─╮
	typeset -g _POWERLEVEL9K_XPLR_FOREGROUND=0
	typeset -g _POWERLEVEL9K_NORDVPN_DISCONNECTED_VISUAL_IDENTIFIER_EXPANSION=''
	typeset -g _POWERLEVEL9K_DISK_USAGE_CRITICAL_BACKGROUND=1
	typeset -g -i _POWERLEVEL9K_JAVA_VERSION_FULL=0
	typeset -g _POWERLEVEL9K_ASDF_RUBY_FOREGROUND=0
	typeset -g -i _POWERLEVEL9K_STATUS_OK_PIPE=1
	typeset -g _POWERLEVEL9K_MODE=nerdfont-complete
	typeset -g _p9k_taskwarrior_data_dir=''
	typeset -g -a _POWERLEVEL9K_BATTERY_DISCONNECTED_LEVEL_FOREGROUND=()
	typeset -g _POWERLEVEL9K_CONTEXT_SUDO_CONTENT_EXPANSION=''
	typeset -g -i _POWERLEVEL9K_DIR_HYPERLINK=0
	typeset -g _POWERLEVEL9K_NODENV_BACKGROUND=0
	typeset -g _POWERLEVEL9K_ASDF_FLUTTER_FOREGROUND=0
	typeset -g -a _p9k_line_never_empty_right=(0)
	typeset -g -a _POWERLEVEL9K_PLENV_SOURCES=(shell local global)
	typeset -g -i _POWERLEVEL9K_RVM_SHOW_GEMSET=0
	typeset -g -i _p9k_ruler_idx=5
	typeset -g _POWERLEVEL9K_TIME_FOREGROUND=0
	typeset -g _POWERLEVEL9K_BATTERY_LOW_FOREGROUND=1
	typeset -g _POWERLEVEL9K_RBENV_FOREGROUND=0
	typeset -g _p9k_vcs_side=left
	typeset -g _POWERLEVEL9K_ASDF_PYTHON_BACKGROUND=4
	typeset -g -i _p9k_vcs_index=3
	typeset -g _POWERLEVEL9K_VPN_IP_FOREGROUND=0
	typeset -g -i _POWERLEVEL9K_VCS_CONFLICTED_MAX_NUM=-1
	typeset -g -i _POWERLEVEL9K_PROMPT_ADD_NEWLINE=0
	typeset -g _p9k_color1=0
	typeset -g _p9k_color2=7
	typeset -g _POWERLEVEL9K_ICON_PADDING=none
	typeset -g _POWERLEVEL9K_NIX_SHELL_FOREGROUND=0
	typeset -g _POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
	typeset -g _POWERLEVEL9K_SCALAENV_BACKGROUND=1
	typeset -g _POWERLEVEL9K_GOOGLE_APP_CRED_DEFAULT_BACKGROUND=4
	typeset -g _POWERLEVEL9K_GOENV_BACKGROUND=4
	typeset -g _POWERLEVEL9K_VI_MODE_INSERT_FOREGROUND=8
	typeset -g -i _POWERLEVEL9K_PHPENV_SHOW_SYSTEM=1
	typeset -g -A _p9k_taskwarrior_counters=()
	typeset -g _POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR=' '
	typeset -g _POWERLEVEL9K_NVM_BACKGROUND=5
	typeset -g -i _POWERLEVEL9K_MAX_CACHE_SIZE=10000
	typeset -g _p9k_os_icon=
	typeset -g -i _p9k_vcs_line_index=1
	typeset -g _POWERLEVEL9K_ANACONDA_LEFT_DELIMITER='('
	typeset -g _POWERLEVEL9K_DATE_FORMAT='%D{%d.%m.%y}'
	typeset -g -a _POWERLEVEL9K_HOOK_WIDGETS=()
	typeset -g _POWERLEVEL9K_NORDVPN_CONNECTING_VISUAL_IDENTIFIER_EXPANSION=''
	typeset -g _POWERLEVEL9K_VI_VISUAL_MODE_STRING=VISUAL
	typeset -g _POWERLEVEL9K_RVM_FOREGROUND=0
	typeset -g _POWERLEVEL9K_CONTEXT_TEMPLATE=%n@%m
	typeset -g _POWERLEVEL9K_PHPENV_BACKGROUND=5
	typeset -g _POWERLEVEL9K_VI_MODE_VISUAL_BACKGROUND=4
	typeset -g -i _POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY=1
	typeset -g _POWERLEVEL9K_JENV_BACKGROUND=7
	typeset -g -a _p9k_line_suffix_right=('$_p9k__sss%b%k%f}')
	typeset -g _p9k_prompt_prefix_right='${_p9k__1-${${_p9k__clm::=$COLUMNS}+}${${COLUMNS::=1024}+}'
	typeset -g _POWERLEVEL9K_RAM_FOREGROUND=0
	typeset -g _POWERLEVEL9K_TIMEWARRIOR_FOREGROUND=255
	typeset -g _POWERLEVEL9K_CONTEXT_FOREGROUND=3
	typeset -g -i _POWERLEVEL9K_VCS_COMMITS_BEHIND_MAX_NUM=-1
	typeset -g _POWERLEVEL9K_VCS_LOADING_BACKGROUND=8
	typeset -g _POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=0
	typeset -g -i _POWERLEVEL9K_STATUS_SHOW_PIPESTATUS=1
	typeset -g _POWERLEVEL9K_IP_INTERFACE=''
	typeset -g -F _POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0.0100000000
	typeset -g _POWERLEVEL9K_NORDVPN_FOREGROUND=7
	typeset -g _POWERLEVEL9K_DIR_WORK_FOREGROUND=196
	typeset -g -a _POWERLEVEL9K_BATTERY_LEVEL_FOREGROUND=()
	typeset -g -a _POWERLEVEL9K_BATTERY_CHARGING_LEVEL_FOREGROUND=()
	typeset -g _POWERLEVEL9K_OS_ICON_FOREGROUND=232
	typeset -g _POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=2
	typeset -g -F _POWERLEVEL9K_NEW_TTY_MAX_AGE_SECONDS=5.0000000000
	typeset -g -a _POWERLEVEL9K_LUAENV_SOURCES=(shell local global)
	typeset -g -a _POWERLEVEL9K_GOENV_SOURCES=(shell local global)
	typeset -g -a _POWERLEVEL9K_BATTERY_DISCONNECTED_LEVEL_BACKGROUND=()
	typeset -g -i _POWERLEVEL9K_HASKELL_STACK_PROMPT_ALWAYS_SHOW=1
	typeset -g _POWERLEVEL9K_WIFI_BACKGROUND=4
	typeset -g -i _POWERLEVEL9K_LUAENV_SHOW_SYSTEM=1
	typeset -g _POWERLEVEL9K_MIDNIGHT_COMMANDER_FOREGROUND=3
	typeset -g _POWERLEVEL9K_BATTERY_CHARGING_FOREGROUND=2
	typeset -g _POWERLEVEL9K_GCLOUD_FOREGROUND=7
	typeset -g _POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=3
	typeset -g _POWERLEVEL9K_GCLOUD_SHOW_ON_COMMAND='gcloud|gcs|gsutil'
	typeset -g -i _POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=0
	typeset -g _POWERLEVEL9K_ANACONDA_RIGHT_DELIMITER=')'
	typeset -g _POWERLEVEL9K_ASDF_FLUTTER_BACKGROUND=4
	typeset -g _POWERLEVEL9K_ASDF_PHP_BACKGROUND=5
	typeset -g _POWERLEVEL9K_NORDVPN_DISCONNECTED_CONTENT_EXPANSION=''
	typeset -g _p9k_asdf_meta_sig=''
	typeset -g -i _POWERLEVEL9K_STATUS_ERROR_PIPE=1
	typeset -g _POWERLEVEL9K_TIME_BACKGROUND=7
	typeset -g -i _POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
	typeset -g _POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER=''
	typeset -g _POWERLEVEL9K_RBENV_BACKGROUND=1
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''
	typeset -g _POWERLEVEL9K_PACKAGE_FOREGROUND=0
	typeset -g _POWERLEVEL9K_NODEENV_LEFT_DELIMITER=''
	typeset -g -a _p9k_line_prefix_left=('${_p9k__1l-${${:-${_p9k__bg::=NONE}${_p9k__i::=0}${_p9k__sss::=%f}}+}')
	typeset -g _POWERLEVEL9K_VPN_IP_BACKGROUND=6
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_OK_VIOWR_CONTENT_EXPANSION=▶
	typeset -g _POWERLEVEL9K_NIX_SHELL_BACKGROUND=4
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_ERROR_VIOWR_CONTENT_EXPANSION=▶
	typeset -g -a _p9k_line_suffix_left=('%b%k$_p9k__sss%b%k%f${:-" %b%k%f"}}')
	typeset -g -i _POWERLEVEL9K_DISK_USAGE_ONLY_WARNING=0
	typeset -g _POWERLEVEL9K_DIR_WORK_VISUAL_IDENTIFIER_EXPANSION=💻
	typeset -g -i _p9k_empty_line_idx=4
	typeset -g _POWERLEVEL9K_VPN_IP_CONTENT_EXPANSION=''
	typeset -g _POWERLEVEL9K_ANACONDA_FOREGROUND=0
	typeset -g _POWERLEVEL9K_JAVA_VERSION_FOREGROUND=1
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_LEFT_RIGHT_WHITESPACE=''
	typeset -g -a _POWERLEVEL9K_VCS_SVN_HOOKS=(vcs-detect-changes svn-detect-changes)
	typeset -g -F _POWERLEVEL9K_GCLOUD_REFRESH_PROJECT_NAME_SECONDS=60.0000000000
	typeset -g -i _POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE_ALWAYS=0
	typeset -g -A _p9k_display_k=([-1]=5 [-1/gap]=15 [-1/left]=11 [-1/left/dir]=19 [-1/left/os_icon]=17 [-1/left/vcs]=21 [-1/left_frame]=7 [-1/right]=13 [-1/right/anaconda]=35 [-1/right/asdf]=31 [-1/right/aws]=69 [-1/right/aws_eb_env]=71 [-1/right/azure]=73 [-1/right/background_jobs]=27 [-1/right/command_execution_time]=25 [-1/right/context]=81 [-1/right/direnv]=29 [-1/right/fvm]=51 [-1/right/gcloud]=75 [-1/right/goenv]=39 [-1/right/google_app_cred]=77 [-1/right/haskell_stack]=63 [-1/right/jenv]=55 [-1/right/kubecontext]=65 [-1/right/load]=99 [-1/right/luaenv]=53 [-1/right/midnight_commander]=93 [-1/right/nix_shell]=95 [-1/right/nnn]=87 [-1/right/nodeenv]=45 [-1/right/nodenv]=41 [-1/right/nordvpn]=83 [-1/right/nvm]=43 [-1/right/phpenv]=59 [-1/right/plenv]=57 [-1/right/pyenv]=37 [-1/right/ranger]=85 [-1/right/rbenv]=47 [-1/right/rvm]=49 [-1/right/scalaenv]=61 [-1/right/status]=23 [-1/right/taskwarrior]=105 [-1/right/terraform]=67 [-1/right/time]=107 [-1/right/timewarrior]=103 [-1/right/todo]=101 [-1/right/toolbox]=79 [-1/right/vi_mode]=97 [-1/right/vim_shell]=91 [-1/right/virtualenv]=33 [-1/right/xplr]=89 [-1/right_frame]=9 [1]=5 [1/gap]=15 [1/left]=11 [1/left/dir]=19 [1/left/os_icon]=17 [1/left/vcs]=21 [1/left_frame]=7 [1/right]=13 [1/right/anaconda]=35 [1/right/asdf]=31 [1/right/aws]=69 [1/right/aws_eb_env]=71 [1/right/azure]=73 [1/right/background_jobs]=27 [1/right/command_execution_time]=25 [1/right/context]=81 [1/right/direnv]=29 [1/right/fvm]=51 [1/right/gcloud]=75 [1/right/goenv]=39 [1/right/google_app_cred]=77 [1/right/haskell_stack]=63 [1/right/jenv]=55 [1/right/kubecontext]=65 [1/right/load]=99 [1/right/luaenv]=53 [1/right/midnight_commander]=93 [1/right/nix_shell]=95 [1/right/nnn]=87 [1/right/nodeenv]=45 [1/right/nodenv]=41 [1/right/nordvpn]=83 [1/right/nvm]=43 [1/right/phpenv]=59 [1/right/plenv]=57 [1/right/pyenv]=37 [1/right/ranger]=85 [1/right/rbenv]=47 [1/right/rvm]=49 [1/right/scalaenv]=61 [1/right/status]=23 [1/right/taskwarrior]=105 [1/right/terraform]=67 [1/right/time]=107 [1/right/timewarrior]=103 [1/right/todo]=101 [1/right/toolbox]=79 [1/right/vi_mode]=97 [1/right/vim_shell]=91 [1/right/virtualenv]=33 [1/right/xplr]=89 [1/right_frame]=9 [empty_line]=1 [ruler]=3)
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_BACKGROUND=''
	typeset -g _POWERLEVEL9K_RAM_BACKGROUND=3
	typeset -g _POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND=3
	typeset -g -F _POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT=50.0000000000
	typeset -g -i _POWERLEVEL9K_DISABLE_RPROMPT=0
	typeset -g -a _POWERLEVEL9K_HASKELL_STACK_SOURCES=(shell local)
	typeset -g -i _POWERLEVEL9K_RVM_SHOW_PREFIX=0
	typeset -g -A icons=([ANDROID_ICON]='\uF17B' [APPLE_ICON]='\uF179' [AWS_EB_ICON]='\UF1BD' [AWS_ICON]='\uF270' [AZURE_ICON]='\uFD03' [BACKGROUND_JOBS_ICON]='\uF013' [BATTERY_ICON]='\UF240' [CARRIAGE_RETURN_ICON]='\u21B5' [DATE_ICON]='\uF073' [DIRENV_ICON]='\u25BC' [DISK_ICON]='\uF0A0' [DOTNET_CORE_ICON]='\uE77F' [DOTNET_ICON]='\uE77F' [DROPBOX_ICON]='\UF16B' [ELIXIR_ICON]='\uE62D' [ERLANG_ICON]='\uE7B1' [ETC_ICON]='\uF013' [EXECUTION_TIME_ICON]='\uF252' [FAIL_ICON]='\uF00D' [FLUTTER_ICON]=F [FOLDER_ICON]='\uF115' [FREEBSD_ICON]='\UF30C' [GCLOUD_ICON]='\uF7B7' [GOLANG_ICON]='\uE626' [GO_ICON]='\uE626' [HASKELL_ICON]='\uE61F' [HOME_ICON]='\uF015' [HOME_SUB_ICON]='\uF07C' [JAVA_ICON]='\uE738' [JULIA_ICON]='\uE624' [KUBERNETES_ICON]='\U2388' [LARAVEL_ICON]='\ue73f' [LEFT_SEGMENT_END_SEPARATOR]=' ' [LEFT_SEGMENT_SEPARATOR]='\uE0B0' [LEFT_SUBSEGMENT_SEPARATOR]='\uE0B1' [LINUX_ALPINE_ICON]='\uF300' [LINUX_AMZN_ICON]='\uF270' [LINUX_AOSC_ICON]='\uF301' [LINUX_ARCH_ICON]='\uF303' [LINUX_ARTIX_ICON]='\uF17C' [LINUX_CENTOS_ICON]='\uF304' [LINUX_COREOS_ICON]='\uF305' [LINUX_DEBIAN_ICON]='\uF306' [LINUX_DEVUAN_ICON]='\uF307' [LINUX_ELEMENTARY_ICON]='\uF309' [LINUX_FEDORA_ICON]='\uF30a' [LINUX_GENTOO_ICON]='\uF30d' [LINUX_ICON]='\uF17C' [LINUX_MAGEIA_ICON]='\uF310' [LINUX_MANJARO_ICON]='\uF312' [LINUX_MINT_ICON]='\uF30e' [LINUX_NIXOS_ICON]='\uF313' [LINUX_OPENSUSE_ICON]='\uF314' [LINUX_RASPBIAN_ICON]='\uF315' [LINUX_RHEL_ICON]='\uF316' [LINUX_SABAYON_ICON]='\uF317' [LINUX_SLACKWARE_ICON]='\uF319' [LINUX_UBUNTU_ICON]='\uF31b' [LINUX_VOID_ICON]='\uF17C' [LOAD_ICON]='\uF080' [LOCK_ICON]='\UF023' [LUA_ICON]='\uE620' [MIDNIGHT_COMMANDER_ICON]=mc [MULTILINE_FIRST_PROMPT_PREFIX]='\u256D\U2500' [MULTILINE_LAST_PROMPT_PREFIX]='\u2570\U2500 ' [MULTILINE_NEWLINE_PROMPT_PREFIX]='\u251C\U2500' [NETWORK_ICON]='\uF50D' [NIX_SHELL_ICON]='\uF313' [NNN_ICON]=nnn [NODEJS_ICON]='\uE617' [NODE_ICON]='\uE617' [NORDVPN_ICON]='\UF023' [OK_ICON]='\uF00C' [PACKAGE_ICON]='\uF8D6' [PERL_ICON]='\uE769' [PHP_ICON]='\uE608' [POSTGRES_ICON]='\uE76E' [PROXY_ICON]='\u2194' [PUBLIC_IP_ICON]='\UF0AC' [PYTHON_ICON]='\UE73C' [RAM_ICON]='\uF0E4' [RANGER_ICON]='\uF00b' [RIGHT_SEGMENT_SEPARATOR]='\uE0B2' [RIGHT_SUBSEGMENT_SEPARATOR]='\uE0B3' [ROOT_ICON]='\uE614' [RUBY_ICON]='\uF219' [RULER_CHAR]='\u2500' [RUST_ICON]='\uE7A8' [SCALA_ICON]='\uE737' [SERVER_ICON]='\uF0AE' [SSH_ICON]='\uF489' [SUDO_ICON]='\uF09C' [SUNOS_ICON]='\uF185' [SWAP_ICON]='\uF464' [SWIFT_ICON]='\uE755' [SYMFONY_ICON]='\uE757' [TASKWARRIOR_ICON]='\uF4A0' [TERRAFORM_ICON]='\uF1BB' [TEST_ICON]='\uF188' [TIMEWARRIOR_ICON]='\uF49B' [TIME_ICON]='\uF017' [TODO_ICON]='\u2611' [TOOLBOX_ICON]='\uE20F' [VCS_BOOKMARK_ICON]='\uF461 ' [VCS_BRANCH_ICON]='\uF126 ' [VCS_COMMIT_ICON]='\uE729 ' [VCS_GIT_BITBUCKET_ICON]='\uE703' [VCS_GIT_GITHUB_ICON]='\uF113' [VCS_GIT_GITLAB_ICON]='\uF296' [VCS_GIT_ICON]='\uF1D3' [VCS_HG_ICON]='\uF0C3' [VCS_INCOMING_CHANGES_ICON]='\uF01A' [VCS_LOADING_ICON]='' [VCS_OUTGOING_CHANGES_ICON]='\uF01B' [VCS_REMOTE_BRANCH_ICON]='\uE728 ' [VCS_STAGED_ICON]='\uF055' [VCS_STASH_ICON]='\uF01C' [VCS_SVN_ICON]='\uE72D' [VCS_TAG_ICON]='\uF02B ' [VCS_UNSTAGED_ICON]='\uF06A' [VCS_UNTRACKED_ICON]='\uF059' [VIM_ICON]='\uE62B' [VPN_ICON]='\UF023' [WIFI_ICON]='\uF1EB' [WINDOWS_ICON]='\uF17A' [XPLR_ICON]=xplr)
	typeset -g -i _POWERLEVEL9K_VCS_UNSTAGED_MAX_NUM=-1
	typeset -g -i _POWERLEVEL9K_STATUS_CROSS=0
	typeset -g _POWERLEVEL9K_SHORTEN_DELIMITER=•
	typeset -g _POWERLEVEL9K_ANACONDA_CONTENT_EXPANSION='${${${${CONDA_PROMPT_MODIFIER#\(}% }%\)}:-${CONDA_PREFIX:t}}'
	typeset -g _POWERLEVEL9K_TODO_BACKGROUND=8
	typeset -g -i _POWERLEVEL9K_STATUS_VERBOSE=1
	typeset -g _POWERLEVEL9K_VI_MODE_NORMAL_BACKGROUND=2
	typeset -g -a _POWERLEVEL9K_RBENV_SOURCES=(shell local global)
	typeset -g _POWERLEVEL9K_NORDVPN_BACKGROUND=4
	typeset -g _POWERLEVEL9K_PUBLIC_IP_BACKGROUND=0
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_OK_VIOWR_FOREGROUND=76
	typeset -g _POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=%242F╭─
	typeset -g _POWERLEVEL9K_PYENV_FOREGROUND=0
	typeset -g -a _POWERLEVEL9K_SCALAENV_SOURCES=(shell local global)
	typeset -g -a _POWERLEVEL9K_BATTERY_LEVEL_BACKGROUND=()
	typeset -g -i _POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=1
	typeset -g _POWERLEVEL9K_STATUS_OK_PIPE_BACKGROUND=0
	typeset -g -i _POWERLEVEL9K_STATUS_ERROR=1
	typeset -g _POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR='\uE0BC'
	typeset -g -i _POWERLEVEL9K_DISABLE_HOT_RELOAD=1
	typeset -g _POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=250
	typeset -g _POWERLEVEL9K_FVM_BACKGROUND=4
	typeset -g _POWERLEVEL9K_PLENV_BACKGROUND=4
	typeset -g -a _p9k_exitcode2str=(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125 126 127 128 HUP INT QUIT ILL TRAP ABRT EMT FPE KILL BUS SEGV SYS PIPE ALRM TERM URG STOP TSTP CONT CHLD TTIN TTOU IO XCPU XFSZ VTALRM PROF WINCH INFO USR1 USR2 ZERR DEBUG 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192 193 194 195 196 197 198 199 200 201 202 203 204 205 206 207 208 209 210 211 212 213 214 215 216 217 218 219 220 221 222 223 224 225 226 227 228 229 230 231 232 233 234 235 236 237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 254 255)
	typeset -g _POWERLEVEL9K_DOTNET_VERSION_FOREGROUND=7
	typeset -g -a _p9k_line_prefix_right=('${_p9k__1r-${${:-${_p9k__bg::=NONE}${_p9k__i::=0}${_p9k__sss::=}}+}')
	typeset -g -i _POWERLEVEL9K_CHRUBY_SHOW_VERSION=1
	typeset -g -a _POWERLEVEL9K_AZURE_CLASSES=()
	typeset -g _POWERLEVEL9K_LUAENV_FOREGROUND=0
	typeset -g _POWERLEVEL9K_STATUS_ERROR_PIPE_BACKGROUND=1
	typeset -g -i _POWERLEVEL9K_GOENV_PROMPT_ALWAYS_SHOW=0
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND=196
	typeset -g -a _POWERLEVEL9K_BATTERY_CHARGED_STAGES=(          )
	typeset -g _POWERLEVEL9K_ASDF_ERLANG_FOREGROUND=0
	typeset -g _POWERLEVEL9K_NODEENV_FOREGROUND=2
	typeset -g -i _POWERLEVEL9K_VPN_IP_SHOW_ALL=0
	typeset -g -i _POWERLEVEL9K_STATUS_ERROR_SIGNAL=1
	typeset -g -i _POWERLEVEL9K_SCALAENV_PROMPT_ALWAYS_SHOW=0
	typeset -g -i _POWERLEVEL9K_JENV_SHOW_SYSTEM=1
	typeset -g _POWERLEVEL9K_STATUS_OK_FOREGROUND=2
	typeset -g _POWERLEVEL9K_NODEENV_RIGHT_DELIMITER=''
	typeset -g -a _p9k_taskwarrior_meta_non_files=()
	typeset -g _POWERLEVEL9K_DIR_ANCHOR_BOLD=true
	typeset -g -a _POWERLEVEL9K_KUBECONTEXT_SHORTEN=()
	typeset -g _POWERLEVEL9K_AWS_DEFAULT_BACKGROUND=1
	typeset -g -i _POWERLEVEL9K_ALWAYS_SHOW_CONTEXT=0
	typeset -g _POWERLEVEL9K_DIRENV_FOREGROUND=3
	typeset -g _POWERLEVEL9K_DIR_WORK_ANCHOR_FOREGROUND=196
	typeset -g -F _POWERLEVEL9K_PUBLIC_IP_TIMEOUT=300.0000000000
	typeset -g _POWERLEVEL9K_STATUS_ERROR_SIGNAL_VISUAL_IDENTIFIER_EXPANSION=✘
	typeset -g _POWERLEVEL9K_ICON_BEFORE_CONTENT=''
	typeset -g -i _p9k_timewarrior_file_mtime=0
	typeset -g -F _POWERLEVEL9K_LOAD_WARNING_PCT=50.0000000000
	typeset -g -i _POWERLEVEL9K_VCS_SHOW_SUBMODULE_DIRTY=0
	typeset -g _POWERLEVEL9K_AZURE_BACKGROUND=4
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_LEFT_LEFT_WHITESPACE=''
	typeset -g -i _POWERLEVEL9K_PROMPT_ADD_NEWLINE_COUNT=1
	typeset -g _p9k_gcloud_project_id=''
	typeset -g -i _POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=0
	typeset -g _POWERLEVEL9K_GOOGLE_APP_CRED_SHOW_ON_COMMAND='terraform|pulumi|terragrunt'
	typeset -g _POWERLEVEL9K_ASDF_BACKGROUND=7
	typeset -g _POWERLEVEL9K_TERRAFORM_VERSION_SHOW_ON_COMMAND='terraform|tf'
	typeset -g _POWERLEVEL9K_DIR_MAX_LENGTH=80
	typeset -g _POWERLEVEL9K_GO_VERSION_FOREGROUND=255
	typeset -g -i _POWERLEVEL9K_BATTERY_HIDE_ABOVE_THRESHOLD=999
	typeset -g -a _p9k_taskwarrior_data_files=()
	typeset -g _POWERLEVEL9K_XPLR_BACKGROUND=6
	typeset -g _POWERLEVEL9K_LARAVEL_VERSION_FOREGROUND=1
	typeset -g _POWERLEVEL9K_ASDF_RUBY_BACKGROUND=1
	typeset -g -i _POWERLEVEL9K_TODO_HIDE_ZERO_TOTAL=1
	typeset -g -i _POWERLEVEL9K_LOAD_WHICH=2
	typeset -g -i _POWERLEVEL9K_PYENV_SHOW_SYSTEM=1
	typeset -g -i _POWERLEVEL9K_PYENV_PROMPT_ALWAYS_SHOW=0
	typeset -g _POWERLEVEL9K_LOAD_CRITICAL_FOREGROUND=0
	typeset -g -a _p9k_asdf_meta_files=()
	typeset -g _POWERLEVEL9K_LOAD_NORMAL_FOREGROUND=0
	typeset -g -i _POWERLEVEL9K_SCALAENV_SHOW_SYSTEM=1
	typeset -g _POWERLEVEL9K_PUBLIC_IP_HOST=https://v4.ident.me/
	typeset -g _POWERLEVEL9K_NODE_VERSION_FOREGROUND=7
	typeset -g _POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
	typeset -g _POWERLEVEL9K_MULTILINE_LAST_PROMPT_SUFFIX=%242F─╯
	typeset -g _POWERLEVEL9K_GITSTATUS_DIR=''
	typeset -g _POWERLEVEL9K_NORDVPN_CONNECTING_CONTENT_EXPANSION=''
	typeset -g _POWERLEVEL9K_DOTNET_VERSION_BACKGROUND=5
	typeset -g _POWERLEVEL9K_ASDF_SHOW_ON_UPGLOB=''
	typeset -g _POWERLEVEL9K_ASDF_ELIXIR_FOREGROUND=0
	typeset -g _POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
	typeset -g -i _p9k_num_cpus=8
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_OK_VICMD_CONTENT_EXPANSION=❮
	typeset -g -i _POWERLEVEL9K_DOTNET_VERSION_PROJECT_ONLY=1
	typeset -g _POWERLEVEL9K_VIRTUALENV_FOREGROUND=0
	typeset -g _POWERLEVEL9K_LUAENV_BACKGROUND=4
	typeset -g _POWERLEVEL9K_VIRTUALENV_GENERIC_NAMES='virtualenv|venv|.venv|env'
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_ERROR_VICMD_CONTENT_EXPANSION=❮
	typeset -g -a _POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs direnv asdf virtualenv anaconda pyenv goenv nodenv nvm nodeenv rbenv rvm fvm luaenv jenv plenv phpenv scalaenv haskell_stack kubecontext terraform aws aws_eb_env azure gcloud google_app_cred toolbox context nordvpn ranger nnn xplr vim_shell midnight_commander nix_shell vi_mode load todo timewarrior taskwarrior time)
	typeset -g -a _POWERLEVEL9K_NODENV_SOURCES=(shell local global)
	typeset -g _POWERLEVEL9K_ASDF_ERLANG_BACKGROUND=1
	typeset -g -i _p9k_timewarrior_dir_mtime=0
	typeset -g -a _POWERLEVEL9K_DIR_CLASSES=('~/Projects(|/*)' WORK '' '*/Projects(|/*)' WORK '' '~(|/*)' HOME '' '*' DEFAULT '')
	typeset -g _POWERLEVEL9K_NODEENV_BACKGROUND=0
	typeset -g _POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR='\uE0BA'
	typeset -g _POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE=%n@%m
	typeset -g _POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=6
	typeset -g -A _p9k_asdf_plugins=()
	typeset -g -i _POWERLEVEL9K_RBENV_PROMPT_ALWAYS_SHOW=0
	typeset -g _POWERLEVEL9K_NORDVPN_DISCONNECTING_CONTENT_EXPANSION=''
	typeset -g _POWERLEVEL9K_VIM_SHELL_FOREGROUND=0
	typeset -g _POWERLEVEL9K_GOOGLE_APP_CRED_DEFAULT_CONTENT_EXPANSION='${P9K_GOOGLE_APP_CRED_PROJECT_ID//\%/%%}'
	typeset -g _POWERLEVEL9K_RUST_VERSION_FOREGROUND=0
	typeset -g -i _POWERLEVEL9K_JAVA_VERSION_PROJECT_ONLY=1
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_OK_VIVIS_FOREGROUND=76
	typeset -g _POWERLEVEL9K_NNN_FOREGROUND=0
	typeset -g _p9k_prompt_prefix_left='${(e)_p9k_t[7]}'
	typeset -g -i _POWERLEVEL9K_TERRAFORM_SHOW_DEFAULT=0
	typeset -g _POWERLEVEL9K_VCS_DISABLED_WORKDIR_PATTERN='~'
	typeset -g _POWERLEVEL9K_RVM_BACKGROUND=240
	typeset -g _POWERLEVEL9K_DIRENV_BACKGROUND=0
	typeset -g _p9k_prompt_suffix_left=$'${${COLUMNS::=$_p9k__clm}+}%{\C-[]133;B\C-G%}'
	typeset -g _POWERLEVEL9K_VPN_IP_INTERFACE=''
	typeset -g _p9k_timewarrior_dir=''
	typeset -g -i _POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING=1
	typeset -g _POWERLEVEL9K_CONTEXT_BACKGROUND=0
	typeset -g _POWERLEVEL9K_TIMEWARRIOR_BACKGROUND=8
	typeset -g _POWERLEVEL9K_STATUS_OK_VISUAL_IDENTIFIER_EXPANSION=✔
	typeset -g _POWERLEVEL9K_KUBECONTEXT_DEFAULT_FOREGROUND=7
	typeset -g -a _POWERLEVEL9K_VCS_BACKENDS=(git)
	typeset -g _POWERLEVEL9K_IP_FOREGROUND=0
	typeset -g _POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=3
	typeset -g _POWERLEVEL9K_RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL='\uE0B0'
	typeset -g _POWERLEVEL9K_GO_VERSION_BACKGROUND=2
	typeset -g -a _POWERLEVEL9K_BATTERY_LOW_LEVEL_FOREGROUND=()
	typeset -g _POWERLEVEL9K_VCS_CLEAN_BACKGROUND=2
	typeset -g _POWERLEVEL9K_CONTEXT_DEFAULT_VISUAL_IDENTIFIER_EXPANSION=''
	typeset -g -a _p9k_left_join=(1 2 3)
	typeset -g _POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_GAP_BACKGROUND=''
	typeset -g _POWERLEVEL9K_LARAVEL_VERSION_BACKGROUND=7
	typeset -g _POWERLEVEL9K_VCS_MODIFIED_BACKGROUND=3
	typeset -g _POWERLEVEL9K_VCS_ACTIONFORMAT_FOREGROUND=1
	typeset -g -i _POWERLEVEL9K_BATTERY_VERBOSE=0
	typeset -g _POWERLEVEL9K_DIR_WORK_BACKGROUND=4
	typeset -g _POWERLEVEL9K_AZURE_SHOW_ON_COMMAND='az|terraform|pulumi|terragrunt'
	typeset -g _POWERLEVEL9K_TERRAFORM_VERSION_FOREGROUND=4
	typeset -g -a _POWERLEVEL9K_BATTERY_CHARGING_LEVEL_BACKGROUND=()
	typeset -g _POWERLEVEL9K_EXAMPLE_FOREGROUND=3
	typeset -g _POWERLEVEL9K_OS_ICON_BACKGROUND=7
	typeset -g _POWERLEVEL9K_AWS_CONTENT_EXPANSION='${P9K_AWS_PROFILE//\%/%%}${P9K_AWS_REGION:+ ${P9K_AWS_REGION//\%/%%}}'
	typeset -g -i _POWERLEVEL9K_VCS_STAGED_MAX_NUM=-1
	typeset -g _POWERLEVEL9K_ASDF_JAVA_FOREGROUND=1
	typeset -g _POWERLEVEL9K_LOAD_CRITICAL_BACKGROUND=1
	typeset -g _POWERLEVEL9K_LOAD_WARNING_FOREGROUND=0
	typeset -g _POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=255
	typeset -g -i _POWERLEVEL9K_PHP_VERSION_PROJECT_ONLY=1
	typeset -g _POWERLEVEL9K_MIDNIGHT_COMMANDER_BACKGROUND=0
	typeset -g _POWERLEVEL9K_ASDF_HASKELL_FOREGROUND=0
	typeset -g _POWERLEVEL9K_VCS_SHORTEN_DELIMITER=…
	typeset -g _POWERLEVEL9K_GCLOUD_BACKGROUND=4
	typeset -g _POWERLEVEL9K_HASKELL_STACK_FOREGROUND=0
	typeset -g _POWERLEVEL9K_TASKWARRIOR_FOREGROUND=0
	typeset -g -i _POWERLEVEL9K_PLENV_PROMPT_ALWAYS_SHOW=0
	typeset -g _POWERLEVEL9K_CONTEXT_SUDO_VISUAL_IDENTIFIER_EXPANSION=''
	typeset -g _POWERLEVEL9K_NODE_VERSION_BACKGROUND=2
	typeset -g -i _POWERLEVEL9K_TERM_SHELL_INTEGRATION=1
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_OK_VIVIS_CONTENT_EXPANSION=V
	typeset -g _POWERLEVEL9K_RIGHT_SUBSEGMENT_SEPARATOR='\u2571'
	typeset -g -i _POWERLEVEL9K_VCS_HIDE_TAGS=0
	typeset -g -a _POWERLEVEL9K_PHPENV_SOURCES=(shell local global)
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_OK_VICMD_FOREGROUND=76
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_ERROR_VIVIS_CONTENT_EXPANSION=V
	typeset -g _POWERLEVEL9K_PHP_VERSION_FOREGROUND=0
	typeset -g _POWERLEVEL9K_ASDF_ELIXIR_BACKGROUND=5
	typeset -g _POWERLEVEL9K_ASDF_NODEJS_FOREGROUND=0
	typeset -g -i _POWERLEVEL9K_ANACONDA_SHOW_PYTHON_VERSION=1
	typeset -g _POWERLEVEL9K_VIRTUALENV_BACKGROUND=4
	typeset -g -A _p9k_dumped_instant_prompt_sigs=([/Users/sedatkilinc/PDFs:0:%]=1 [/Users/sedatkilinc/tmp:0:%]=1 [/Users/sedatkilinc:0:%]=1 ['/Volumes/ExtMem512GB/Cloud/Google Drive/CheatSheets:0:%']=1 [/Volumes/ExtMem512GB/Projects/github/WebRTC-Samples:0:%]=1 [/Volumes/ExtMem512GB/Projects/github/imgui:0:%]=1 [/Volumes/ExtMem512GB/Projects/github:0:%]=1)
	typeset -g -i _POWERLEVEL9K_GO_VERSION_PROJECT_ONLY=1
	typeset -g _POWERLEVEL9K_AWS_EB_ENV_FOREGROUND=2
	typeset -g -i _POWERLEVEL9K_BATTERY_LOW_THRESHOLD=20
	typeset -g -a _p9k_taskwarrior_data_non_files=()
	typeset -g _POWERLEVEL9K_CONTEXT_REMOTE_FOREGROUND=3
	typeset -g -F _POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3.0000000000
	typeset -g -i _POWERLEVEL9K_BATTERY_LOW_HIDE_ABOVE_THRESHOLD=999
	typeset -g -a _POWERLEVEL9K_VCS_HG_HOOKS=(vcs-detect-changes)
	typeset -g -i _POWERLEVEL9K_NODENV_SHOW_SYSTEM=1
	typeset -g -i _POWERLEVEL9K_SHOW_RULER=0
	typeset -g -a _POWERLEVEL9K_PUBLIC_IP_METHODS=(dig curl wget)
	typeset -g _POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((my_git_formatter()))+${my_git_format}}'
	typeset -g _POWERLEVEL9K_PACKAGE_BACKGROUND=6
	typeset -g _POWERLEVEL9K_VI_MODE_OVERWRITE_BACKGROUND=3
	typeset -g _POWERLEVEL9K_BACKGROUND_JOBS_BACKGROUND=0
	typeset -g _POWERLEVEL9K_VI_MODE_FOREGROUND=0
	typeset -g _POWERLEVEL9K_PUBLIC_IP_NONE=''
	typeset -g -a _p9k_show_on_command=($'(|*[/\C-@])(kubectl|helm|kubens|kubectx|oc|istioctl|kogito|k9s|helmfile|flux|fluxctl|stern)' 66 _p9k__1rkubecontext $'(|*[/\C-@])(aws|awless|terraform|pulumi|terragrunt)' 70 _p9k__1raws $'(|*[/\C-@])(az|terraform|pulumi|terragrunt)' 74 _p9k__1razure $'(|*[/\C-@])(gcloud|gcs|gsutil)' 76 _p9k__1rgcloud $'(|*[/\C-@])(terraform|pulumi|terragrunt)' 78 _p9k__1rgoogle_app_cred)
	typeset -g -a _POWERLEVEL9K_BATTERY_CHARGED_LEVEL_FOREGROUND=()
	typeset -g _POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_SUFFIX=%242F─┤
	typeset -g _POWERLEVEL9K_ASDF_DOTNET_CORE_FOREGROUND=0
	typeset -g -i _POWERLEVEL9K_RBENV_SHOW_SYSTEM=1
	typeset -g _POWERLEVEL9K_VIM_SHELL_BACKGROUND=2
	typeset -g _POWERLEVEL9K_BATTERY_BACKGROUND=0
	typeset -g -i _POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE=0
	typeset -g -i _POWERLEVEL9K_DIR_SHOW_WRITABLE=3
	typeset -g _POWERLEVEL9K_SWAP_FOREGROUND=0
	typeset -g _POWERLEVEL9K_NNN_BACKGROUND=6
	typeset -g -i _POWERLEVEL9K_PROMPT_ON_NEWLINE=0
	typeset -g -i _POWERLEVEL9K_STATUS_HIDE_SIGNAME=0
	typeset -g -a _POWERLEVEL9K_VCS_GIT_HOOKS=(vcs-detect-changes git-untracked git-aheadbehind git-stash git-remotebranch git-tagname)
	typeset -g _POWERLEVEL9K_ANACONDA_BACKGROUND=4
	typeset -g -a _p9k_line_segments_right=($'status\C-@command_execution_time\C-@background_jobs\C-@direnv\C-@asdf\C-@virtualenv\C-@anaconda\C-@pyenv\C-@goenv\C-@nodenv\C-@nvm\C-@nodeenv\C-@rbenv\C-@rvm\C-@fvm\C-@luaenv\C-@jenv\C-@plenv\C-@phpenv\C-@scalaenv\C-@haskell_stack\C-@kubecontext\C-@terraform\C-@aws\C-@aws_eb_env\C-@azure\C-@gcloud\C-@google_app_cred\C-@toolbox\C-@context\C-@nordvpn\C-@ranger\C-@nnn\C-@xplr\C-@vim_shell\C-@midnight_commander\C-@nix_shell\C-@vi_mode\C-@load\C-@todo\C-@timewarrior\C-@taskwarrior\C-@time')
	typeset -g _POWERLEVEL9K_JAVA_VERSION_BACKGROUND=7
	typeset -g -i _POWERLEVEL9K_DIR_PATH_ABSOLUTE=0
	typeset -g _POWERLEVEL9K_VIRTUALENV_RIGHT_DELIMITER=''
	typeset -g _p9k_uname_m=x86_64
	typeset -g -i _POWERLEVEL9K_ALWAYS_SHOW_USER=0
	typeset -g _p9k_uname_o=''
	typeset -g -i _POWERLEVEL9K_VCS_RECURSE_UNTRACKED_DIRS=0
	typeset -g _POWERLEVEL9K_VCS_CONFLICTED_BACKGROUND=3
	typeset -g _POWERLEVEL9K_ASDF_LUA_FOREGROUND=0
	typeset -g _POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND=76
	typeset -g -i _POWERLEVEL9K_COMMANDS_MAX_TOKEN_COUNT=64
	typeset -g -i _POWERLEVEL9K_STATUS_EXTENDED_STATES=1
	typeset -g _POWERLEVEL9K_VI_COMMAND_MODE_STRING=NORMAL
	typeset -g _POWERLEVEL9K_IP_CONTENT_EXPANSION='${P9K_IP_RX_RATE:+⇣$P9K_IP_RX_RATE }${P9K_IP_TX_RATE:+⇡$P9K_IP_TX_RATE }$P9K_IP_IP'
	typeset -g _POWERLEVEL9K_LEFT_SUBSEGMENT_SEPARATOR='\u2571'
	typeset -g -i _POWERLEVEL9K_DISABLE_INSTANT_PROMPT=0
	typeset -g _POWERLEVEL9K_GCLOUD_COMPLETE_CONTENT_EXPANSION='${P9K_GCLOUD_PROJECT_NAME//\%/%%}'
	typeset -g -a _POWERLEVEL9K_PYENV_SOURCES=(shell local global)
	typeset -g _p9k_timewarrior_file_name=''
	typeset -g _POWERLEVEL9K_DIR_WORK_SHORTENED_FOREGROUND=250
}
_p9k_right_prompt_segment () {
	if ! _p9k_cache_get "$0" "$1" "$2" "$3" "$4" "$_p9k__segment_index"
	then
		_p9k_color $1 BACKGROUND $2
		local bg_color=$_p9k__ret
		_p9k_background $bg_color
		local bg=$_p9k__ret
		local bg_=${_p9k__ret//\}/\\\}}
		_p9k_color $1 FOREGROUND $3
		local fg_color=$_p9k__ret
		_p9k_foreground $fg_color
		local fg=$_p9k__ret
		local style=%b$bg$fg
		local style_=${style//\}/\\\}}
		_p9k_get_icon $1 RIGHT_SEGMENT_SEPARATOR
		local sep=$_p9k__ret
		_p9k_escape $_p9k__ret
		local sep_=$_p9k__ret
		_p9k_get_icon $1 RIGHT_SUBSEGMENT_SEPARATOR
		local subsep=$_p9k__ret
		[[ $subsep == *%* ]] && subsep+=$style
		local icon_
		if [[ -n $4 ]]
		then
			_p9k_get_icon $1 $4
			_p9k_escape $_p9k__ret
			icon_=$_p9k__ret
		fi
		_p9k_get_icon $1 RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL $sep
		local start_sep=$_p9k__ret
		[[ -n $start_sep ]] && start_sep="%b%k%F{$bg_color}$start_sep"
		_p9k_get_icon $1 RIGHT_PROMPT_LAST_SEGMENT_END_SYMBOL
		_p9k_escape $_p9k__ret
		local end_sep_=$_p9k__ret
		_p9k_get_icon $1 WHITESPACE_BETWEEN_RIGHT_SEGMENTS ' '
		local space=$_p9k__ret
		_p9k_get_icon $1 RIGHT_LEFT_WHITESPACE $space
		local left_space=$_p9k__ret
		[[ $left_space == *%* ]] && left_space+=$style
		_p9k_get_icon $1 RIGHT_RIGHT_WHITESPACE $space
		_p9k_escape $_p9k__ret
		local right_space_=$_p9k__ret
		[[ $right_space_ == *%* ]] && right_space_+=$style_
		local w='<_p9k__w>' s='<_p9k__s>'
		local -i non_hermetic=0
		local t=$(($#_p9k_t - __p9k_ksh_arrays))
		_p9k_t+=$start_sep$style$left_space
		_p9k_t+=$w$style
		_p9k_t+=$w$style$subsep$left_space
		_p9k_t+=$w%F{$bg_color}$sep$style$left_space
		local join="_p9k__i>=$_p9k_right_join[$_p9k__segment_index]"
		_p9k_param $1 SELF_JOINED false
		if [[ $_p9k__ret == false ]]
		then
			if (( _p9k__segment_index > $_p9k_right_join[$_p9k__segment_index] ))
			then
				join+="&&_p9k__i<$_p9k__segment_index"
			else
				join=
			fi
		fi
		local p=
		p+="\${_p9k__n::=}"
		p+="\${\${\${_p9k__bg:-0}:#NONE}:-\${_p9k__n::=$((t+1))}}"
		if [[ -n $join ]]
		then
			p+="\${_p9k__n:=\${\${\$(($join)):#0}:+$((t+2))}}"
		fi
		if (( __p9k_sh_glob ))
		then
			p+="\${_p9k__n:=\${\${(M)\${:-x\$_p9k__bg}:#x${(b)bg_color}}:+$((t+3))}}"
			p+="\${_p9k__n:=\${\${(M)\${:-x\$_p9k__bg}:#x${(b)bg_color:-0}}:+$((t+3))}}"
		else
			p+="\${_p9k__n:=\${\${(M)\${:-x\$_p9k__bg}:#x(${(b)bg_color}|${(b)bg_color:-0})}:+$((t+3))}}"
		fi
		p+="\${_p9k__n:=$((t+4))}"
		_p9k_param $1 VISUAL_IDENTIFIER_EXPANSION '${P9K_VISUAL_IDENTIFIER}'
		[[ $_p9k__ret == (|*[^\\])'$('* ]] && non_hermetic=1
		local icon_exp_=${_p9k__ret:+\"$_p9k__ret\"}
		_p9k_param $1 CONTENT_EXPANSION '${P9K_CONTENT}'
		[[ $_p9k__ret == (|*[^\\])'$('* ]] && non_hermetic=1
		local content_exp_=${_p9k__ret:+\"$_p9k__ret\"}
		if [[ ( $icon_exp_ != '"${P9K_VISUAL_IDENTIFIER}"' && $icon_exp_ == *'$'* ) || ( $content_exp_ != '"${P9K_CONTENT}"' && $content_exp_ == *'$'* ) ]]
		then
			p+="\${P9K_VISUAL_IDENTIFIER::=$icon_}"
		fi
		local -i has_icon=-1
		if [[ $icon_exp_ != '"${P9K_VISUAL_IDENTIFIER}"' && $icon_exp_ == *'$'* ]]
		then
			p+="\${_p9k__v::=$icon_exp_$style_}"
		else
			[[ $icon_exp_ == '"${P9K_VISUAL_IDENTIFIER}"' ]] && _p9k__ret=$icon_  || _p9k__ret=$icon_exp_
			if [[ -n $_p9k__ret ]]
			then
				p+="\${_p9k__v::=$_p9k__ret"
				[[ $_p9k__ret == *%* ]] && p+=$style_
				p+="}"
				has_icon=1
			else
				has_icon=0
			fi
		fi
		p+='${_p9k__c::='$content_exp_'}${_p9k__c::=${_p9k__c//'$'\r''}}'
		p+='${_p9k__e::=${${_p9k__'${_p9k__line_index}r${${1#prompt_}%%[A-Z0-9_]#}'+00}:-'
		if (( has_icon == -1 ))
		then
			p+='${${(%):-$_p9k__c%1(l.1.0)}[-1]}${${(%):-$_p9k__v%1(l.1.0)}[-1]}}'
		else
			p+='${${(%):-$_p9k__c%1(l.1.0)}[-1]}'$has_icon'}'
		fi
		p+='}}+}'
		p+='${${_p9k__e:#00}:+${_p9k_t[$_p9k__n]/'$w'/$_p9k__w}'
		_p9k_param $1 ICON_BEFORE_CONTENT ''
		if [[ $_p9k__ret != true ]]
		then
			_p9k_param $1 PREFIX ''
			_p9k__ret=${(g::)_p9k__ret}
			_p9k_escape $_p9k__ret
			p+=$_p9k__ret
			[[ $_p9k__ret == *%* ]] && p+=$style_
			p+='${_p9k__c}'$style_
			if (( has_icon != 0 ))
			then
				local -i need_style=0
				_p9k_get_icon $1 RIGHT_MIDDLE_WHITESPACE ' '
				if [[ -n $_p9k__ret ]]
				then
					_p9k_escape $_p9k__ret
					[[ $_p9k__ret == *%* ]] && need_style=1
					p+='${${(M)_p9k__e:#11}:+'$_p9k__ret'}'
				fi
				_p9k_color $1 VISUAL_IDENTIFIER_COLOR $fg_color
				_p9k_foreground $_p9k__ret
				_p9k__ret=%b$bg$_p9k__ret
				_p9k__ret=${_p9k__ret//\}/\\\}}
				[[ $_p9k__ret != $style_ || $need_style == 1 ]] && p+=$_p9k__ret
				p+='$_p9k__v'
			fi
		else
			_p9k_param $1 PREFIX ''
			_p9k__ret=${(g::)_p9k__ret}
			_p9k_escape $_p9k__ret
			p+=$_p9k__ret
			[[ $_p9k__ret == *%* ]] && local -i need_style=1  || local -i need_style=0
			if (( has_icon != 0 ))
			then
				_p9k_color $1 VISUAL_IDENTIFIER_COLOR $fg_color
				_p9k_foreground $_p9k__ret
				_p9k__ret=%b$bg$_p9k__ret
				_p9k__ret=${_p9k__ret//\}/\\\}}
				if [[ $_p9k__ret != $style_ ]]
				then
					p+=$_p9k__ret'${_p9k__v}'$style_
				else
					(( need_style )) && p+=$style_
					p+='${_p9k__v}'
				fi
				_p9k_get_icon $1 RIGHT_MIDDLE_WHITESPACE ' '
				if [[ -n $_p9k__ret ]]
				then
					_p9k_escape $_p9k__ret
					[[ _p9k__ret == *%* ]] && _p9k__ret+=$style_
					p+='${${(M)_p9k__e:#11}:+'$_p9k__ret'}'
				fi
			elif (( need_style ))
			then
				p+=$style_
			fi
			p+='${_p9k__c}'$style_
		fi
		_p9k_param $1 SUFFIX ''
		_p9k__ret=${(g::)_p9k__ret}
		_p9k_escape $_p9k__ret
		p+=$_p9k__ret
		p+='${${:-'
		if [[ -n $fg_color && $fg_color == $bg_color ]]
		then
			if [[ $fg_color == $_p9k_color1 ]]
			then
				_p9k_foreground $_p9k_color2
			else
				_p9k_foreground $_p9k_color1
			fi
		else
			_p9k__ret=$fg
		fi
		_p9k__ret=${_p9k__ret//\}/\\\}}
		p+="\${_p9k__w::=${right_space_:+$style_}$right_space_%b$bg_$_p9k__ret}"
		p+='${_p9k__sss::='
		p+=$style_$right_space_
		[[ $right_space_ == *%* ]] && p+=$style_
		if [[ -n $end_sep_ ]]
		then
			p+="%k%F{$bg_color\}$end_sep_$style_"
		fi
		p+='}'
		p+="\${_p9k__i::=$_p9k__segment_index}\${_p9k__bg::=$bg_color}"
		p+='}+}'
		p+='}'
		_p9k_param $1 SHOW_ON_UPGLOB ''
		_p9k_cache_set "$p" $non_hermetic $_p9k__ret
	fi
	if [[ -n $_p9k__cache_val[3] ]]
	then
		_p9k__has_upglob=1
		_p9k_upglob $_p9k__cache_val[3] && return
	fi
	_p9k__non_hermetic_expansion=$_p9k__cache_val[2]
	(( $5 )) && _p9k__ret=\"$7\"  || _p9k_escape $7
	if [[ -z $6 ]]
	then
		_p9k__prompt+="\${\${:-\${P9K_CONTENT::=$_p9k__ret}$_p9k__cache_val[1]"
	else
		_p9k__prompt+="\${\${:-\"$6\"}:+\${\${:-\${P9K_CONTENT::=$_p9k__ret}$_p9k__cache_val[1]}"
	fi
}
_p9k_save_status () {
	local -i pipe
	if (( !$+_p9k__line_finished ))
	then
		:
	elif (( !$+_p9k__preexec_cmd ))
	then
		(( _p9k__status == __p9k_new_status )) && return
	elif (( $__p9k_new_pipestatus[(I)$__p9k_new_status] ))
	then
		local cmd=(${(z)_p9k__preexec_cmd})
		if [[ $#cmd != 0 && $cmd[1] != '!' && ${(Q)cmd[1]} != coproc ]]
		then
			local arg
			for arg in ${(z)_p9k__preexec_cmd}
			do
				if [[ $arg == ('()'|'&&'|'||'|'&'|'&|'|'&!'|*';') ]]
				then
					pipe=0
					break
				elif [[ $arg == *('|'|'|&')* ]]
				then
					pipe=1
				fi
			done
		fi
	fi
	_p9k__status=$__p9k_new_status
	if (( pipe ))
	then
		_p9k__pipestatus=($__p9k_new_pipestatus)
	else
		_p9k__pipestatus=($_p9k__status)
	fi
}
_p9k_scalaenv_global_version () {
	_p9k_read_word ${SCALAENV_ROOT:-$HOME/.scalaenv}/version || _p9k__ret=system
}
_p9k_segment_in_use () {
	(( $_POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[(I)$1(|_joined)] ||
     $_POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS[(I)$1(|_joined)] ))
}
_p9k_set_instant_prompt () {
	local saved_prompt=$PROMPT
	local saved_rprompt=$RPROMPT
	_p9k_set_prompt instant_
	typeset -g _p9k__instant_prompt=$PROMPT$'\x1f'$_p9k__prompt$'\x1f'$RPROMPT
	PROMPT=$saved_prompt
	RPROMPT=$saved_rprompt
	[[ -n $RPROMPT ]] || unset RPROMPT
}
_p9k_set_os () {
	_p9k_os=$1
	_p9k_get_icon prompt_os_icon $2
	_p9k_os_icon=$_p9k__ret
}
_p9k_set_prompt () {
	local -i _p9k__vcs_called
	PROMPT=
	RPROMPT=
	[[ $1 == instant_ ]] || PROMPT+='${$((_p9k_on_expand()))+}%{${_p9k__raw_msg-}${_p9k__raw_msg::=}%}'
	PROMPT+=$_p9k_prompt_prefix_left
	local -i _p9k__has_upglob
	local -i left_idx=1 right_idx=1 num_lines=$#_p9k_line_segments_left
	for _p9k__line_index in {1..$num_lines}
	do
		local right=
		if (( !_POWERLEVEL9K_DISABLE_RPROMPT ))
		then
			_p9k__dir=
			_p9k__prompt=
			_p9k__segment_index=right_idx
			_p9k__prompt_side=right
			if [[ $1 == instant_ ]]
			then
				for _p9k__segment_name in ${${(0)_p9k_line_segments_right[_p9k__line_index]}%_joined}
				do
					if (( $+functions[instant_prompt_$_p9k__segment_name] ))
					then
						local disabled=_POWERLEVEL9K_${${(U)_p9k__segment_name}//İ/I}_DISABLED_DIR_PATTERN
						if [[ $_p9k__cwd != ${(P)~disabled} ]]
						then
							local -i len=$#_p9k__prompt
							_p9k__non_hermetic_expansion=0
							instant_prompt_$_p9k__segment_name
							if (( _p9k__non_hermetic_expansion ))
							then
								_p9k__prompt[len+1,-1]=
							fi
						fi
					fi
					((++_p9k__segment_index))
				done
			else
				for _p9k__segment_name in ${${(0)_p9k_line_segments_right[_p9k__line_index]}%_joined}
				do
					local cond=$_p9k__segment_cond_right[_p9k__segment_index]
					if [[ -z $cond || -n ${(e)cond} ]]
					then
						local disabled=_POWERLEVEL9K_${${(U)_p9k__segment_name}//İ/I}_DISABLED_DIR_PATTERN
						if [[ $_p9k__cwd != ${(P)~disabled} ]]
						then
							local val=$_p9k__segment_val_right[_p9k__segment_index]
							if [[ -n $val ]]
							then
								_p9k__prompt+=$val
							else
								if [[ $_p9k__segment_name == custom_* ]]
								then
									_p9k_custom_prompt $_p9k__segment_name[8,-1]
								elif (( $+functions[prompt_$_p9k__segment_name] ))
								then
									prompt_$_p9k__segment_name
								fi
							fi
						fi
					fi
					((++_p9k__segment_index))
				done
			fi
			_p9k__prompt=${${_p9k__prompt//$' %{\b'/'%{%G'}//$' \b'}
			right_idx=_p9k__segment_index
			if [[ -n $_p9k__prompt || $_p9k_line_never_empty_right[_p9k__line_index] == 1 ]]
			then
				right=$_p9k_line_prefix_right[_p9k__line_index]$_p9k__prompt$_p9k_line_suffix_right[_p9k__line_index]
			fi
		fi
		unset _p9k__dir
		_p9k__prompt=$_p9k_line_prefix_left[_p9k__line_index]
		_p9k__segment_index=left_idx
		_p9k__prompt_side=left
		if [[ $1 == instant_ ]]
		then
			for _p9k__segment_name in ${${(0)_p9k_line_segments_left[_p9k__line_index]}%_joined}
			do
				if (( $+functions[instant_prompt_$_p9k__segment_name] ))
				then
					local disabled=_POWERLEVEL9K_${${(U)_p9k__segment_name}//İ/I}_DISABLED_DIR_PATTERN
					if [[ $_p9k__cwd != ${(P)~disabled} ]]
					then
						local -i len=$#_p9k__prompt
						_p9k__non_hermetic_expansion=0
						instant_prompt_$_p9k__segment_name
						if (( _p9k__non_hermetic_expansion ))
						then
							_p9k__prompt[len+1,-1]=
						fi
					fi
				fi
				((++_p9k__segment_index))
			done
		else
			for _p9k__segment_name in ${${(0)_p9k_line_segments_left[_p9k__line_index]}%_joined}
			do
				local cond=$_p9k__segment_cond_left[_p9k__segment_index]
				if [[ -z $cond || -n ${(e)cond} ]]
				then
					local disabled=_POWERLEVEL9K_${${(U)_p9k__segment_name}//İ/I}_DISABLED_DIR_PATTERN
					if [[ $_p9k__cwd != ${(P)~disabled} ]]
					then
						local val=$_p9k__segment_val_left[_p9k__segment_index]
						if [[ -n $val ]]
						then
							_p9k__prompt+=$val
						else
							if [[ $_p9k__segment_name == custom_* ]]
							then
								_p9k_custom_prompt $_p9k__segment_name[8,-1]
							elif (( $+functions[prompt_$_p9k__segment_name] ))
							then
								prompt_$_p9k__segment_name
							fi
						fi
					fi
				fi
				((++_p9k__segment_index))
			done
		fi
		_p9k__prompt=${${_p9k__prompt//$' %{\b'/'%{%G'}//$' \b'}
		left_idx=_p9k__segment_index
		_p9k__prompt+=$_p9k_line_suffix_left[_p9k__line_index]
		if (( $+_p9k__dir || (_p9k__line_index != num_lines && $#right) ))
		then
			_p9k__prompt='${${:-${_p9k__d::=0}${_p9k__rprompt::='$right'}${_p9k__lprompt::='$_p9k__prompt'}}+}'
			_p9k__prompt+=$_p9k_gap_pre
			if (( $+_p9k__dir ))
			then
				if (( _p9k__line_index == num_lines && (_POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS > 0 || _POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT > 0) ))
				then
					local a=$_POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS
					local f=$((0.01*_POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS_PCT))'*_p9k__clm'
					_p9k__prompt+="\${\${_p9k__h::=$((($a<$f)*$f+($a>=$f)*$a))}+}"
				else
					_p9k__prompt+='${${_p9k__h::=0}+}'
				fi
				if [[ $_POWERLEVEL9K_DIR_MAX_LENGTH == <->('%'|) ]]
				then
					local lim=
					if [[ $_POWERLEVEL9K_DIR_MAX_LENGTH[-1] == '%' ]]
					then
						lim="$_p9k__dir_len-$((0.01*$_POWERLEVEL9K_DIR_MAX_LENGTH[1,-2]))*_p9k__clm"
					else
						lim=$((_p9k__dir_len-_POWERLEVEL9K_DIR_MAX_LENGTH))
						((lim <= 0)) && lim=
					fi
					if [[ -n $lim ]]
					then
						_p9k__prompt+='${${${$((_p9k__h<_p9k__m+'$lim')):#1}:-${_p9k__h::=$((_p9k__m+'$lim'))}}+}'
					fi
				fi
				_p9k__prompt+='${${_p9k__d::=$((_p9k__m-_p9k__h))}+}'
				_p9k__prompt+='${_p9k__lprompt/\%\{d\%\}*\%\{d\%\}/${_p9k__'$_p9k__line_index'ldir-'$_p9k__dir'}}'
				_p9k__prompt+='${${_p9k__m::=$((_p9k__d+_p9k__h))}+}'
			else
				_p9k__prompt+='${_p9k__lprompt}'
			fi
			((_p9k__line_index != num_lines && $#right)) && _p9k__prompt+=$_p9k_line_gap_post[_p9k__line_index]
		fi
		if (( _p9k__line_index == num_lines ))
		then
			[[ -n $right ]] && RPROMPT=$_p9k_prompt_prefix_right$right$_p9k_prompt_suffix_right
			_p9k__prompt='${_p9k__'$_p9k__line_index'-'$_p9k__prompt'}'$_p9k_prompt_suffix_left
			[[ $1 == instant_ ]] || PROMPT+=$_p9k__prompt
		else
			[[ -n $right ]] || _p9k__prompt+=$'\n'
			PROMPT+='${_p9k__'$_p9k__line_index'-'$_p9k__prompt'}'
		fi
	done
	_p9k__prompt_side=
	(( $#_p9k_cache < _POWERLEVEL9K_MAX_CACHE_SIZE )) || _p9k_cache=()
	(( $#_p9k__cache_ephemeral < _POWERLEVEL9K_MAX_CACHE_SIZE )) || _p9k__cache_ephemeral=()
	[[ -n $RPROMPT ]] || unset RPROMPT
}
_p9k_setup () {
	(( __p9k_enabled )) && return
	prompt_opts=(percent subst)
	if (( ! $+__p9k_instant_prompt_active ))
	then
		prompt_opts+=sp
		prompt_opts+=cr
	fi
	prompt_powerlevel9k_teardown
	__p9k_enabled=1
	typeset -ga preexec_functions=(_p9k_preexec1 $preexec_functions _p9k_preexec2)
	typeset -ga precmd_functions=(_p9k_do_nothing _p9k_precmd_first $precmd_functions _p9k_precmd)
}
_p9k_shorten_delim_len () {
	local def=$1
	_p9k__ret=${_POWERLEVEL9K_SHORTEN_DELIMITER_LENGTH:--1}
	(( _p9k__ret >= 0 )) || _p9k_prompt_length $1
}
_p9k_should_dump () {
	(( __p9k_dumps_enabled && ! _p9k__state_dump_fd )) || return
	(( _p9k__state_dump_scheduled || _p9k__prompt_idx == 1 )) && return
	_p9k__instant_prompt_sig=$_p9k__cwd:$P9K_SSH:${(%):-%#}
	(( ! $+_p9k_dumped_instant_prompt_sigs[$_p9k__instant_prompt_sig] ))
}
_p9k_taskwarrior_check_data () {
	[[ -n $_p9k_taskwarrior_data_sig ]] || return
	[[ -z $^_p9k_taskwarrior_data_non_files(#qN) ]] || return
	local -a stat
	if (( $#_p9k_taskwarrior_data_files ))
	then
		zstat -A stat +mtime -- $_p9k_taskwarrior_data_files 2> /dev/null || return
	fi
	[[ $_p9k_taskwarrior_data_sig == ${(pj:\0:)stat}$'\0'$TASKRC$'\0'$TASKDATA ]] || return
	(( _p9k_taskwarrior_next_due == 0 || _p9k_taskwarrior_next_due > EPOCHSECONDS )) || return
}
_p9k_taskwarrior_check_meta () {
	[[ -n $_p9k_taskwarrior_meta_sig ]] || return
	[[ -z $^_p9k_taskwarrior_meta_non_files(#qN) ]] || return
	local -a stat
	if (( $#_p9k_taskwarrior_meta_files ))
	then
		zstat -A stat +mtime -- $_p9k_taskwarrior_meta_files 2> /dev/null || return
	fi
	[[ $_p9k_taskwarrior_meta_sig == ${(pj:\0:)stat}$'\0'$TASKRC$'\0'$TASKDATA ]] || return
}
_p9k_taskwarrior_init_data () {
	local -a stat files=($_p9k_taskwarrior_data_dir/{pending,completed}.data)
	_p9k_taskwarrior_data_files=($^files(N))
	_p9k_taskwarrior_data_non_files=(${files:|_p9k_taskwarrior_data_files})
	if (( $#_p9k_taskwarrior_data_files ))
	then
		zstat -A stat +mtime -- $_p9k_taskwarrior_data_files 2> /dev/null || stat=(-1)
		_p9k_taskwarrior_data_sig=${(pj:\0:)stat}$'\0'
	else
		_p9k_taskwarrior_data_sig=
	fi
	_p9k_taskwarrior_data_files+=($_p9k_taskwarrior_meta_files)
	_p9k_taskwarrior_data_non_files+=($_p9k_taskwarrior_meta_non_files)
	_p9k_taskwarrior_data_sig+=$_p9k_taskwarrior_meta_sig
	local name val
	for name in PENDING OVERDUE
	do
		val="$(command task +$name count rc.color=0 rc._forcecolor=0 </dev/null 2>/dev/null)"  || continue
		[[ $val == <1-> ]] || continue
		_p9k_taskwarrior_counters[$name]=$val
	done
	_p9k_taskwarrior_next_due=0
	if (( _p9k_taskwarrior_counters[PENDING] > _p9k_taskwarrior_counters[OVERDUE] ))
	then
		local -a ts
		ts=($(command task +PENDING -OVERDUE list rc.verbose=nothing rc.color=0 rc._forcecolor=0 \
      rc.report.list.labels= rc.report.list.columns=due.epoch </dev/null 2>/dev/null))  || ts=()
		if (( $#ts ))
		then
			_p9k_taskwarrior_next_due=${${(on)ts}[1]}
			(( _p9k_taskwarrior_next_due > EPOCHSECONDS )) || _p9k_taskwarrior_next_due=$((EPOCHSECONDS+60))
		fi
	fi
	_p9k__state_dump_scheduled=1
}
_p9k_taskwarrior_init_meta () {
	local last_sig=$_p9k_taskwarrior_meta_sig
	{
		local cfg
		cfg="$(command task show data.location rc.color=0 rc._forcecolor=0 </dev/null 2>/dev/null)"  || return
		local lines=(${(@M)${(f)cfg}:#data.location[[:space:]]##[^[:space:]]*})
		(( $#lines == 1 )) || return
		local dir=${lines[1]##data.location[[:space:]]#}
		: ${dir::=$~dir}
		local -a stat files=(${TASKRC:-~/.taskrc})
		_p9k_taskwarrior_meta_files=($^files(N))
		_p9k_taskwarrior_meta_non_files=(${files:|_p9k_taskwarrior_meta_files})
		if (( $#_p9k_taskwarrior_meta_files ))
		then
			zstat -A stat +mtime -- $_p9k_taskwarrior_meta_files 2> /dev/null || stat=(-1)
		fi
		_p9k_taskwarrior_meta_sig=${(pj:\0:)stat}$'\0'$TASKRC$'\0'$TASKDATA
		_p9k_taskwarrior_data_dir=$dir
	} always {
		if (( $? == 0 ))
		then
			_p9k__state_dump_scheduled=1
			return
		fi
		[[ -n $last_sig ]] && _p9k__state_dump_scheduled=1
		_p9k_taskwarrior_meta_files=()
		_p9k_taskwarrior_meta_non_files=()
		_p9k_taskwarrior_meta_sig=
		_p9k_taskwarrior_data_dir=
		_p9k__taskwarrior_functional=
	}
}
_p9k_timewarrior_clear () {
	[[ -z $_p9k_timewarrior_dir ]] && return
	_p9k_timewarrior_dir=
	_p9k_timewarrior_dir_mtime=0
	_p9k_timewarrior_file_mtime=0
	_p9k_timewarrior_file_name=
	unset _p9k_timewarrior_tags
	_p9k__state_dump_scheduled=1
}
_p9k_translate_color () {
	if [[ $1 == <-> ]]
	then
		_p9k__ret=${(l.3..0.)1}
	elif [[ $1 == '#'[[:xdigit:]]## ]]
	then
		_p9k__ret=${${(L)1}//ı/i}
	else
		_p9k__ret=$__p9k_colors[${${${1#bg-}#fg-}#br}]
	fi
}
_p9k_trapint () {
	if (( __p9k_enabled ))
	then
		eval "$__p9k_intro"
		_p9k_deschedule_redraw
		zle && _p9k_on_widget_zle-line-finish int
	fi
	return 0
}
_p9k_upglob () {
	local cached=$_p9k__upsearch_cache[$_p9k__cwd/$1]
	if [[ -n $cached ]]
	then
		if [[ $_p9k__parent_mtimes_s == ${cached% *}(| *) ]]
		then
			return ${cached##* }
		fi
		cached=(${(s: :)cached})
		local last_idx=$cached[-1]
		cached[-1]=()
		local -i i
		for i in ${(@)${cached:|_p9k__parent_mtimes_i}%:*}
		do
			_p9k_glob $i $1 && continue
			_p9k__upsearch_cache[$_p9k__cwd/$1]="${_p9k__parent_mtimes_i[1,i]} $i"
			return i
		done
		if (( i != last_idx ))
		then
			_p9k__upsearch_cache[$_p9k__cwd/$1]="${_p9k__parent_mtimes_i[1,$#cached]} $last_idx"
			return last_idx
		fi
		i=$(($#cached + 1))
	else
		local -i i=1
	fi
	for ((; i <= $#_p9k__parent_mtimes; ++i)) do
		_p9k_glob $i $1 && continue
		_p9k__upsearch_cache[$_p9k__cwd/$1]="${_p9k__parent_mtimes_i[1,i]} $i"
		return i
	done
	_p9k__upsearch_cache[$_p9k__cwd/$1]="$_p9k__parent_mtimes_s 0"
	return 0
}
_p9k_url_escape () {
	if [[ $1 == [a-zA-Z0-9"/:_.-!'()~ "]# ]]
	then
		_p9k__ret=${1// /%%20}
	else
		local c
		_p9k__ret=
		for c in ${(s::)1}
		do
			[[ $c == [a-zA-Z0-9"/:_.-!'()~"] ]] || printf -v c '%%%%%02X' $(( #c ))
			_p9k__ret+=$c
		done
	fi
}
_p9k_vcs_gitstatus () {
	if [[ $_p9k__refresh_reason == precmd ]] && (( !_p9k__vcs_called ))
	then
		typeset -gi _p9k__vcs_called=1
		if (( $+_p9k__gitstatus_next_dir ))
		then
			_p9k__gitstatus_next_dir=$_p9k__cwd_a
		else
			local -F timeout=_POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS
			if ! _p9k_vcs_status_for_dir
			then
				_p9k__git_dir=$GIT_DIR
				gitstatus_query_p9k_ -d $_p9k__cwd_a -t $timeout -p -c '_p9k_vcs_resume 0' POWERLEVEL9K || return 1
				_p9k_maybe_ignore_git_repo
				case $VCS_STATUS_RESULT in
					(tout) _p9k__gitstatus_next_dir=''
						_p9k__gitstatus_start_time=$EPOCHREALTIME
						return 0 ;;
					(norepo-sync) return 0 ;;
					(ok-sync) _p9k_vcs_status_save ;;
				esac
			else
				if [[ -n $GIT_DIR ]]
				then
					[[ $_p9k_git_slow[GIT_DIR:$GIT_DIR] == 1 ]] && timeout=0
				else
					local dir=$_p9k__cwd_a
					while true
					do
						case $_p9k_git_slow[$dir] in
							("") [[ $dir == (/|.) ]] && break
								dir=${dir:h}  ;;
							(0) break ;;
							(1) timeout=0
								break ;;
						esac
					done
				fi
			fi
			(( _p9k__prompt_idx == 1 )) && timeout=0
			_p9k__git_dir=$GIT_DIR
			if (( _p9k_vcs_index && $+GITSTATUS_DAEMON_PID_POWERLEVEL9K ))
			then
				if ! gitstatus_query_p9k_ -d $_p9k__cwd_a -t 0 -c '_p9k_vcs_resume 1' POWERLEVEL9K
				then
					unset VCS_STATUS_RESULT
					return 1
				fi
				typeset -gF _p9k__vcs_timeout=timeout
				_p9k__gitstatus_next_dir=''
				_p9k__gitstatus_start_time=$EPOCHREALTIME
				return 0
			fi
			if ! gitstatus_query_p9k_ -d $_p9k__cwd_a -t $timeout -c '_p9k_vcs_resume 1' POWERLEVEL9K
			then
				unset VCS_STATUS_RESULT
				return 1
			fi
			_p9k_maybe_ignore_git_repo
			case $VCS_STATUS_RESULT in
				(tout) _p9k__gitstatus_next_dir=''
					_p9k__gitstatus_start_time=$EPOCHREALTIME  ;;
				(norepo-sync) _p9k_vcs_status_purge $_p9k__cwd_a ;;
				(ok-sync) _p9k_vcs_status_save ;;
			esac
		fi
	fi
	return 0
}
_p9k_vcs_icon () {
	case "$VCS_STATUS_REMOTE_URL" in
		(*github*) _p9k__ret=VCS_GIT_GITHUB_ICON  ;;
		(*bitbucket*) _p9k__ret=VCS_GIT_BITBUCKET_ICON  ;;
		(*stash*) _p9k__ret=VCS_GIT_BITBUCKET_ICON  ;;
		(*gitlab*) _p9k__ret=VCS_GIT_GITLAB_ICON  ;;
		(*) _p9k__ret=VCS_GIT_ICON  ;;
	esac
}
_p9k_vcs_info_init () {
	autoload -Uz vcs_info
	local prefix=''
	if (( _POWERLEVEL9K_SHOW_CHANGESET ))
	then
		_p9k_get_icon '' VCS_COMMIT_ICON
		prefix="$_p9k__ret%0.${_POWERLEVEL9K_CHANGESET_HASH_LENGTH}i "
	fi
	zstyle ':vcs_info:*' check-for-changes true
	zstyle ':vcs_info:*' formats "$prefix%b%c%u%m"
	zstyle ':vcs_info:*' actionformats "%b %F{$_POWERLEVEL9K_VCS_ACTIONFORMAT_FOREGROUND}| %a%f"
	_p9k_get_icon '' VCS_STAGED_ICON
	zstyle ':vcs_info:*' stagedstr " $_p9k__ret"
	_p9k_get_icon '' VCS_UNSTAGED_ICON
	zstyle ':vcs_info:*' unstagedstr " $_p9k__ret"
	zstyle ':vcs_info:git*+set-message:*' hooks $_POWERLEVEL9K_VCS_GIT_HOOKS
	zstyle ':vcs_info:hg*+set-message:*' hooks $_POWERLEVEL9K_VCS_HG_HOOKS
	zstyle ':vcs_info:svn*+set-message:*' hooks $_POWERLEVEL9K_VCS_SVN_HOOKS
	if (( _POWERLEVEL9K_HIDE_BRANCH_ICON ))
	then
		zstyle ':vcs_info:hg*:*' branchformat "%b"
	else
		_p9k_get_icon '' VCS_BRANCH_ICON
		zstyle ':vcs_info:hg*:*' branchformat "$_p9k__ret%b"
	fi
	zstyle ':vcs_info:hg*:*' get-revision true
	zstyle ':vcs_info:hg*:*' get-bookmarks true
	zstyle ':vcs_info:hg*+gen-hg-bookmark-string:*' hooks hg-bookmarks
	zstyle ':vcs_info:svn*:*' formats "$prefix%c%u"
	zstyle ':vcs_info:svn*:*' actionformats "$prefix%c%u %F{$_POWERLEVEL9K_VCS_ACTIONFORMAT_FOREGROUND}| %a%f"
	if (( _POWERLEVEL9K_SHOW_CHANGESET ))
	then
		zstyle ':vcs_info:*' get-revision true
	else
		zstyle ':vcs_info:*' get-revision false
	fi
}
_p9k_vcs_render () {
	local state
	if (( $+_p9k__gitstatus_next_dir ))
	then
		if _p9k_vcs_status_for_dir
		then
			_p9k_vcs_status_restore $_p9k__ret
			state=LOADING
		else
			_p9k_prompt_segment prompt_vcs_LOADING "${__p9k_vcs_states[LOADING]}" "$_p9k_color1" VCS_LOADING_ICON 0 '' "$_POWERLEVEL9K_VCS_LOADING_TEXT"
			return 0
		fi
	elif [[ $VCS_STATUS_RESULT != ok-* ]]
	then
		return 1
	fi
	if (( _POWERLEVEL9K_VCS_DISABLE_GITSTATUS_FORMATTING ))
	then
		if [[ -z $state ]]
		then
			if [[ $VCS_STATUS_HAS_CONFLICTED == 1 && $_POWERLEVEL9K_VCS_CONFLICTED_STATE == 1 ]]
			then
				state=CONFLICTED
			elif [[ $VCS_STATUS_HAS_STAGED != 0 || $VCS_STATUS_HAS_UNSTAGED != 0 ]]
			then
				state=MODIFIED
			elif [[ $VCS_STATUS_HAS_UNTRACKED != 0 ]]
			then
				state=UNTRACKED
			else
				state=CLEAN
			fi
		fi
		_p9k_vcs_icon
		_p9k_prompt_segment prompt_vcs_$state "${__p9k_vcs_states[$state]}" "$_p9k_color1" "$_p9k__ret" 0 '' ""
		return 0
	fi
	(( ${_POWERLEVEL9K_VCS_GIT_HOOKS[(I)git-untracked]} )) || VCS_STATUS_HAS_UNTRACKED=0
	(( ${_POWERLEVEL9K_VCS_GIT_HOOKS[(I)git-aheadbehind]} )) || {
		VCS_STATUS_COMMITS_AHEAD=0  && VCS_STATUS_COMMITS_BEHIND=0
	}
	(( ${_POWERLEVEL9K_VCS_GIT_HOOKS[(I)git-stash]} )) || VCS_STATUS_STASHES=0
	(( ${_POWERLEVEL9K_VCS_GIT_HOOKS[(I)git-remotebranch]} )) || VCS_STATUS_REMOTE_BRANCH=""
	(( ${_POWERLEVEL9K_VCS_GIT_HOOKS[(I)git-tagname]} )) || VCS_STATUS_TAG=""
	(( _POWERLEVEL9K_VCS_COMMITS_AHEAD_MAX_NUM >= 0 && VCS_STATUS_COMMITS_AHEAD > _POWERLEVEL9K_VCS_COMMITS_AHEAD_MAX_NUM )) && VCS_STATUS_COMMITS_AHEAD=$_POWERLEVEL9K_VCS_COMMITS_AHEAD_MAX_NUM
	(( _POWERLEVEL9K_VCS_COMMITS_BEHIND_MAX_NUM >= 0 && VCS_STATUS_COMMITS_BEHIND > _POWERLEVEL9K_VCS_COMMITS_BEHIND_MAX_NUM )) && VCS_STATUS_COMMITS_BEHIND=$_POWERLEVEL9K_VCS_COMMITS_BEHIND_MAX_NUM
	local -a cache_key=("$VCS_STATUS_LOCAL_BRANCH" "$VCS_STATUS_REMOTE_BRANCH" "$VCS_STATUS_REMOTE_URL" "$VCS_STATUS_ACTION" "$VCS_STATUS_NUM_STAGED" "$VCS_STATUS_NUM_UNSTAGED" "$VCS_STATUS_NUM_UNTRACKED" "$VCS_STATUS_HAS_CONFLICTED" "$VCS_STATUS_HAS_STAGED" "$VCS_STATUS_HAS_UNSTAGED" "$VCS_STATUS_HAS_UNTRACKED" "$VCS_STATUS_COMMITS_AHEAD" "$VCS_STATUS_COMMITS_BEHIND" "$VCS_STATUS_STASHES" "$VCS_STATUS_TAG" "$VCS_STATUS_NUM_UNSTAGED_DELETED")
	if [[ $_POWERLEVEL9K_SHOW_CHANGESET == 1 || -z $VCS_STATUS_LOCAL_BRANCH ]]
	then
		cache_key+=$VCS_STATUS_COMMIT
	fi
	if ! _p9k_cache_ephemeral_get "$state" "${(@)cache_key}"
	then
		local icon
		local content
		if (( ${_POWERLEVEL9K_VCS_GIT_HOOKS[(I)vcs-detect-changes]} ))
		then
			if [[ $VCS_STATUS_HAS_CONFLICTED == 1 && $_POWERLEVEL9K_VCS_CONFLICTED_STATE == 1 ]]
			then
				: ${state:=CONFLICTED}
			elif [[ $VCS_STATUS_HAS_STAGED != 0 || $VCS_STATUS_HAS_UNSTAGED != 0 ]]
			then
				: ${state:=MODIFIED}
			elif [[ $VCS_STATUS_HAS_UNTRACKED != 0 ]]
			then
				: ${state:=UNTRACKED}
			fi
			_p9k_vcs_icon
			icon=$_p9k__ret
		fi
		: ${state:=CLEAN}
		_$0_fmt () {
			_p9k_vcs_style $state $1
			content+="$_p9k__ret$2"
		}
		local ws
		if [[ $_POWERLEVEL9K_SHOW_CHANGESET == 1 || -z $VCS_STATUS_LOCAL_BRANCH ]]
		then
			_p9k_get_icon prompt_vcs_$state VCS_COMMIT_ICON
			_$0_fmt COMMIT "$_p9k__ret${${VCS_STATUS_COMMIT:0:$_POWERLEVEL9K_CHANGESET_HASH_LENGTH}:-HEAD}"
			ws=' '
		fi
		if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]
		then
			local branch=$ws
			if (( !_POWERLEVEL9K_HIDE_BRANCH_ICON ))
			then
				_p9k_get_icon prompt_vcs_$state VCS_BRANCH_ICON
				branch+=$_p9k__ret
			fi
			if (( $+_POWERLEVEL9K_VCS_SHORTEN_LENGTH && $+_POWERLEVEL9K_VCS_SHORTEN_MIN_LENGTH &&
            $#VCS_STATUS_LOCAL_BRANCH > _POWERLEVEL9K_VCS_SHORTEN_MIN_LENGTH &&
            $#VCS_STATUS_LOCAL_BRANCH > _POWERLEVEL9K_VCS_SHORTEN_LENGTH )) && [[ $_POWERLEVEL9K_VCS_SHORTEN_STRATEGY == (truncate_middle|truncate_from_right) ]]
			then
				branch+=${VCS_STATUS_LOCAL_BRANCH[1,_POWERLEVEL9K_VCS_SHORTEN_LENGTH]//\%/%%}${_POWERLEVEL9K_VCS_SHORTEN_DELIMITER}
				if [[ $_POWERLEVEL9K_VCS_SHORTEN_STRATEGY == truncate_middle ]]
				then
					_p9k_vcs_style $state BRANCH
					branch+=${_p9k__ret}${VCS_STATUS_LOCAL_BRANCH[-_POWERLEVEL9K_VCS_SHORTEN_LENGTH,-1]//\%/%%}
				fi
			else
				branch+=${VCS_STATUS_LOCAL_BRANCH//\%/%%}
			fi
			_$0_fmt BRANCH $branch
		fi
		if [[ $_POWERLEVEL9K_VCS_HIDE_TAGS == 0 && -n $VCS_STATUS_TAG ]]
		then
			_p9k_get_icon prompt_vcs_$state VCS_TAG_ICON
			_$0_fmt TAG " $_p9k__ret${VCS_STATUS_TAG//\%/%%}"
		fi
		if [[ -n $VCS_STATUS_ACTION ]]
		then
			_$0_fmt ACTION " | ${VCS_STATUS_ACTION//\%/%%}"
		else
			if [[ -n $VCS_STATUS_REMOTE_BRANCH && $VCS_STATUS_LOCAL_BRANCH != $VCS_STATUS_REMOTE_BRANCH ]]
			then
				_p9k_get_icon prompt_vcs_$state VCS_REMOTE_BRANCH_ICON
				_$0_fmt REMOTE_BRANCH " $_p9k__ret${VCS_STATUS_REMOTE_BRANCH//\%/%%}"
			fi
			if [[ $VCS_STATUS_HAS_STAGED == 1 || $VCS_STATUS_HAS_UNSTAGED == 1 || $VCS_STATUS_HAS_UNTRACKED == 1 ]]
			then
				_p9k_get_icon prompt_vcs_$state VCS_DIRTY_ICON
				_$0_fmt DIRTY "$_p9k__ret"
				if [[ $VCS_STATUS_HAS_STAGED == 1 ]]
				then
					_p9k_get_icon prompt_vcs_$state VCS_STAGED_ICON
					(( _POWERLEVEL9K_VCS_STAGED_MAX_NUM != 1 )) && _p9k__ret+=$VCS_STATUS_NUM_STAGED
					_$0_fmt STAGED " $_p9k__ret"
				fi
				if [[ $VCS_STATUS_HAS_UNSTAGED == 1 ]]
				then
					_p9k_get_icon prompt_vcs_$state VCS_UNSTAGED_ICON
					(( _POWERLEVEL9K_VCS_UNSTAGED_MAX_NUM != 1 )) && _p9k__ret+=$VCS_STATUS_NUM_UNSTAGED
					_$0_fmt UNSTAGED " $_p9k__ret"
				fi
				if [[ $VCS_STATUS_HAS_UNTRACKED == 1 ]]
				then
					_p9k_get_icon prompt_vcs_$state VCS_UNTRACKED_ICON
					(( _POWERLEVEL9K_VCS_UNTRACKED_MAX_NUM != 1 )) && _p9k__ret+=$VCS_STATUS_NUM_UNTRACKED
					_$0_fmt UNTRACKED " $_p9k__ret"
				fi
			fi
			if [[ $VCS_STATUS_COMMITS_BEHIND -gt 0 ]]
			then
				_p9k_get_icon prompt_vcs_$state VCS_INCOMING_CHANGES_ICON
				(( _POWERLEVEL9K_VCS_COMMITS_BEHIND_MAX_NUM != 1 )) && _p9k__ret+=$VCS_STATUS_COMMITS_BEHIND
				_$0_fmt INCOMING_CHANGES " $_p9k__ret"
			fi
			if [[ $VCS_STATUS_COMMITS_AHEAD -gt 0 ]]
			then
				_p9k_get_icon prompt_vcs_$state VCS_OUTGOING_CHANGES_ICON
				(( _POWERLEVEL9K_VCS_COMMITS_AHEAD_MAX_NUM != 1 )) && _p9k__ret+=$VCS_STATUS_COMMITS_AHEAD
				_$0_fmt OUTGOING_CHANGES " $_p9k__ret"
			fi
			if [[ $VCS_STATUS_STASHES -gt 0 ]]
			then
				_p9k_get_icon prompt_vcs_$state VCS_STASH_ICON
				_$0_fmt STASH " $_p9k__ret$VCS_STATUS_STASHES"
			fi
		fi
		_p9k_cache_ephemeral_set "prompt_vcs_$state" "${__p9k_vcs_states[$state]}" "$_p9k_color1" "$icon" 0 '' "$content"
	fi
	_p9k_prompt_segment "$_p9k__cache_val[@]"
	return 0
}
_p9k_vcs_resume () {
	eval "$__p9k_intro"
	_p9k_maybe_ignore_git_repo
	if [[ $VCS_STATUS_RESULT == ok-async ]]
	then
		local latency=$((EPOCHREALTIME - _p9k__gitstatus_start_time))
		if (( latency > _POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS ))
		then
			_p9k_git_slow[${${_p9k__git_dir:+GIT_DIR:$_p9k__git_dir}:-$VCS_STATUS_WORKDIR}]=1
		elif (( $1 && latency < 0.8 * _POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS ))
		then
			_p9k_git_slow[${${_p9k__git_dir:+GIT_DIR:$_p9k__git_dir}:-$VCS_STATUS_WORKDIR}]=0
		fi
		_p9k_vcs_status_save
	fi
	if [[ -z $_p9k__gitstatus_next_dir ]]
	then
		unset _p9k__gitstatus_next_dir
		case $VCS_STATUS_RESULT in
			(norepo-async) (( $1 )) && _p9k_vcs_status_purge $_p9k__cwd_a ;;
			(ok-async) (( $1 )) || _p9k__gitstatus_next_dir=$_p9k__cwd_a  ;;
		esac
	fi
	if [[ -n $_p9k__gitstatus_next_dir ]]
	then
		_p9k__git_dir=$GIT_DIR
		if ! gitstatus_query_p9k_ -d $_p9k__gitstatus_next_dir -t 0 -c '_p9k_vcs_resume 1' POWERLEVEL9K
		then
			unset _p9k__gitstatus_next_dir
			unset VCS_STATUS_RESULT
		else
			_p9k_maybe_ignore_git_repo
			case $VCS_STATUS_RESULT in
				(tout) _p9k__gitstatus_next_dir=''
					_p9k__gitstatus_start_time=$EPOCHREALTIME  ;;
				(norepo-sync) _p9k_vcs_status_purge $_p9k__gitstatus_next_dir
					unset _p9k__gitstatus_next_dir ;;
				(ok-sync) _p9k_vcs_status_save
					unset _p9k__gitstatus_next_dir ;;
			esac
		fi
	fi
	if (( _p9k_vcs_index && $+GITSTATUS_DAEMON_PID_POWERLEVEL9K ))
	then
		local _p9k__prompt _p9k__prompt_side=$_p9k_vcs_side _p9k__segment_name=vcs
		local -i _p9k__has_upglob _p9k__segment_index=_p9k_vcs_index _p9k__line_index=_p9k_vcs_line_index
		_p9k_vcs_render
		typeset -g _p9k__vcs=$_p9k__prompt
	else
		_p9k__refresh_reason=gitstatus
		_p9k_set_prompt
		_p9k__refresh_reason=''
	fi
	_p9k_reset_prompt
}
_p9k_vcs_status_for_dir () {
	if [[ -n $GIT_DIR ]]
	then
		_p9k__ret=$_p9k__gitstatus_last[GIT_DIR:$GIT_DIR]
		[[ -n $_p9k__ret ]]
	else
		local dir=$_p9k__cwd_a
		while true
		do
			_p9k__ret=$_p9k__gitstatus_last[$dir]
			[[ -n $_p9k__ret ]] && return 0
			[[ $dir == (/|.) ]] && return 1
			dir=${dir:h}
		done
	fi
}
_p9k_vcs_status_purge () {
	if [[ -n $_p9k__git_dir ]]
	then
		_p9k__gitstatus_last[GIT_DIR:$_p9k__git_dir]=""
	else
		local dir=$1
		while true
		do
			_p9k__gitstatus_last[$dir]=""
			_p9k_git_slow[$dir]=""
			[[ $dir == (/|.) ]] && break
			dir=${dir:h}
		done
	fi
}
_p9k_vcs_status_restore () {
	for VCS_STATUS_COMMIT VCS_STATUS_LOCAL_BRANCH VCS_STATUS_REMOTE_BRANCH VCS_STATUS_REMOTE_NAME VCS_STATUS_REMOTE_URL VCS_STATUS_ACTION VCS_STATUS_INDEX_SIZE VCS_STATUS_NUM_STAGED VCS_STATUS_NUM_UNSTAGED VCS_STATUS_NUM_CONFLICTED VCS_STATUS_NUM_UNTRACKED VCS_STATUS_HAS_STAGED VCS_STATUS_HAS_UNSTAGED VCS_STATUS_HAS_CONFLICTED VCS_STATUS_HAS_UNTRACKED VCS_STATUS_COMMITS_AHEAD VCS_STATUS_COMMITS_BEHIND VCS_STATUS_STASHES VCS_STATUS_TAG VCS_STATUS_NUM_UNSTAGED_DELETED VCS_STATUS_NUM_STAGED_NEW VCS_STATUS_NUM_STAGED_DELETED VCS_STATUS_PUSH_REMOTE_NAME VCS_STATUS_PUSH_REMOTE_URL VCS_STATUS_PUSH_COMMITS_AHEAD VCS_STATUS_PUSH_COMMITS_BEHIND VCS_STATUS_NUM_SKIP_WORKTREE VCS_STATUS_NUM_ASSUME_UNCHANGED in "${(@0)1}"
	do

	done
}
_p9k_vcs_status_save () {
	local z=$'\0'
	_p9k__gitstatus_last[${${_p9k__git_dir:+GIT_DIR:$_p9k__git_dir}:-$VCS_STATUS_WORKDIR}]=$VCS_STATUS_COMMIT$z$VCS_STATUS_LOCAL_BRANCH$z$VCS_STATUS_REMOTE_BRANCH$z$VCS_STATUS_REMOTE_NAME$z$VCS_STATUS_REMOTE_URL$z$VCS_STATUS_ACTION$z$VCS_STATUS_INDEX_SIZE$z$VCS_STATUS_NUM_STAGED$z$VCS_STATUS_NUM_UNSTAGED$z$VCS_STATUS_NUM_CONFLICTED$z$VCS_STATUS_NUM_UNTRACKED$z$VCS_STATUS_HAS_STAGED$z$VCS_STATUS_HAS_UNSTAGED$z$VCS_STATUS_HAS_CONFLICTED$z$VCS_STATUS_HAS_UNTRACKED$z$VCS_STATUS_COMMITS_AHEAD$z$VCS_STATUS_COMMITS_BEHIND$z$VCS_STATUS_STASHES$z$VCS_STATUS_TAG$z$VCS_STATUS_NUM_UNSTAGED_DELETED$z$VCS_STATUS_NUM_STAGED_NEW$z$VCS_STATUS_NUM_STAGED_DELETED$z$VCS_STATUS_PUSH_REMOTE_NAME$z$VCS_STATUS_PUSH_REMOTE_URL$z$VCS_STATUS_PUSH_COMMITS_AHEAD$z$VCS_STATUS_PUSH_COMMITS_BEHIND$z$VCS_STATUS_NUM_SKIP_WORKTREE$z$VCS_STATUS_NUM_ASSUME_UNCHANGED
}
_p9k_vcs_style () {
	local key="$0 ${(pj:\0:)*}"
	_p9k__ret=$_p9k_cache[$key]
	if [[ -n $_p9k__ret ]]
	then
		_p9k__ret[-1,-1]=''
	else
		local style=%b
		_p9k_color prompt_vcs_$1 BACKGROUND "${__p9k_vcs_states[$1]}"
		_p9k_background $_p9k__ret
		style+=$_p9k__ret
		local var=_POWERLEVEL9K_VCS_${1}_${2}FORMAT_FOREGROUND
		if (( $+parameters[$var] ))
		then
			_p9k_translate_color "${(P)var}"
		else
			var=_POWERLEVEL9K_VCS_${2}FORMAT_FOREGROUND
			if (( $+parameters[$var] ))
			then
				_p9k_translate_color "${(P)var}"
			else
				_p9k_color prompt_vcs_$1 FOREGROUND "$_p9k_color1"
			fi
		fi
		_p9k_foreground $_p9k__ret
		_p9k__ret=$style$_p9k__ret
		_p9k_cache[$key]=${_p9k__ret}.
	fi
}
_p9k_vpn_ip_render () {
	local _p9k__segment_name=vpn_ip _p9k__prompt_side ip
	local -i _p9k__has_upglob _p9k__segment_index
	for _p9k__prompt_side _p9k__line_index _p9k__segment_index in $_p9k__vpn_ip_segments
	do
		local _p9k__prompt=
		for ip in $_p9k__vpn_ip_ips
		do
			_p9k_prompt_segment prompt_vpn_ip "cyan" "$_p9k_color1" 'VPN_ICON' 0 '' $ip
		done
		typeset -g _p9k__vpn_ip_$_p9k__prompt_side$_p9k__segment_index=$_p9k__prompt
	done
}
_p9k_widget () {
	local f=${widgets[._p9k_orig_$1]:-}
	local -i res
	[[ -z $f ]] || {
		[[ $f == user:-z4h-* ]] && {
			"${f#user:}" "${@:2}"
			res=$?
		} || {
			zle ._p9k_orig_$1 -- "${@:2}"
			res=$?
		}
	}
	(( ! __p9k_enabled )) || [[ $CONTEXT != start ]] || _p9k_widget_hook "$@"
	return res
}
_p9k_widget_clear-screen () {
	_p9k_widget clear-screen "$@"
}
_p9k_widget_deactivate-region () {
	_p9k_widget deactivate-region "$@"
}
_p9k_widget_hook () {
	_p9k_deschedule_redraw
	if (( ${+functions[p10k-on-post-widget]} || ${#_p9k_show_on_command} ))
	then
		local -a P9K_COMMANDS
		if [[ "$_p9k__last_buffer" == "$PREBUFFER$BUFFER" ]]
		then
			P9K_COMMANDS=(${_p9k__last_commands[@]})
		else
			_p9k__last_buffer="$PREBUFFER$BUFFER"
			if [[ -n "$_p9k__last_buffer" ]]
			then
				_p9k_parse_buffer "$_p9k__last_buffer" $_POWERLEVEL9K_COMMANDS_MAX_TOKEN_COUNT
			fi
			_p9k__last_commands=(${P9K_COMMANDS[@]})
		fi
	fi
	eval "$__p9k_intro"
	(( _p9k__restore_prompt_fd )) && _p9k_restore_prompt $_p9k__restore_prompt_fd
	if [[ $1 == (clear-screen|z4h-clear-screen-*-top) ]]
	then
		P9K_TTY=new
		_p9k__expanded=0
		_p9k_reset_prompt
	fi
	__p9k_reset_state=1
	_p9k_check_visual_mode
	local pat idx var
	for pat idx var in $_p9k_show_on_command
	do
		if (( $P9K_COMMANDS[(I)$pat] ))
		then
			_p9k_display_segment $idx $var show
		else
			_p9k_display_segment $idx $var hide
		fi
	done
	(( $+functions[p10k-on-post-widget] )) && p10k-on-post-widget "${@:2}"
	(( $+functions[_p9k_on_widget_$1] )) && _p9k_on_widget_$1
	(( __p9k_reset_state == 2 )) && _p9k_reset_prompt
	__p9k_reset_state=0
}
_p9k_widget_overwrite-mode () {
	_p9k_widget overwrite-mode "$@"
}
_p9k_widget_send-break () {
	(( ! __p9k_enabled )) || [[ $CONTEXT != start ]] || {
		_p9k_widget_hook send-break "$@"
	}
	local f=${widgets[._p9k_orig_send-break]:-}
	[[ -z $f ]] || zle ._p9k_orig_send-break -- "$@"
}
_p9k_widget_vi-replace () {
	_p9k_widget vi-replace "$@"
}
_p9k_widget_visual-line-mode () {
	_p9k_widget visual-line-mode "$@"
}
_p9k_widget_visual-mode () {
	_p9k_widget visual-mode "$@"
}
_p9k_widget_z4h-clear-screen-hard-top () {
	_p9k_widget z4h-clear-screen-hard-top "$@"
}
_p9k_widget_z4h-clear-screen-soft-top () {
	_p9k_widget z4h-clear-screen-soft-top "$@"
}
_p9k_widget_zle-keymap-select () {
	_p9k_widget zle-keymap-select "$@"
}
_p9k_widget_zle-line-finish () {
	_p9k_widget zle-line-finish "$@"
}
_p9k_widget_zle-line-init () {
	_p9k_widget zle-line-init "$@"
}
_p9k_widget_zle-line-pre-redraw () {
	_p9k_widget_zle-line-pre-redraw-impl
}
_p9k_widget_zle-line-pre-redraw-impl () {
	(( __p9k_enabled )) && [[ $CONTEXT == start ]] || return 0
	! (( ${+functions[p10k-on-post-widget]} || ${#_p9k_show_on_command} || _p9k__restore_prompt_fd || _p9k__redraw_fd )) && [[ ${KEYMAP:-} != vicmd ]] && return
	(( PENDING || KEYS_QUEUED_COUNT )) && {
		(( _p9k__redraw_fd )) || {
			sysopen -o cloexec -ru _p9k__redraw_fd /dev/null
			zle -F $_p9k__redraw_fd _p9k_redraw
		}
		return
	}
	_p9k_widget_hook zle-line-pre-redraw
}
_p9k_worker_cleanup () {
	emulate -L zsh
	[[ $_p9k__worker_shell_pid == $sysparams[pid] ]] && _p9k_worker_stop
	return 0
}
_p9k_worker_invoke () {
	[[ -n $_p9k__worker_resp_fd ]] || return
	local req=$1$'\x1f'$2$'\x1e'
	if [[ -n $_p9k__worker_req_fd && $+_p9k__worker_request_map[$1] == 0 ]]
	then
		_p9k__worker_request_map[$1]=
		print -rnu $_p9k__worker_req_fd -- $req
	else
		_p9k__worker_request_map[$1]=$req
	fi
}
_p9k_worker_main () {
	mkfifo -- $_p9k__worker_file_prefix.fifo || return
	echo -nE - s$_p9k_worker_pgid$'\x1e' || return
	exec < $_p9k__worker_file_prefix.fifo || return
	zf_rm -- $_p9k__worker_file_prefix.fifo || return
	local -i reset
	local req fd
	local -a ready
	local _p9k_worker_request_id
	local -A _p9k_worker_fds
	local -A _p9k_worker_inflight
	_p9k_worker_reply () {
		print -nr -- e${(pj:\n:)@}$'\x1e' || kill -- -$_p9k_worker_pgid
	}
	_p9k_worker_async () {
		local fd async=$1
		sysopen -r -o cloexec -u fd <(() { eval $async; } && print -n '\x1e') || return
		(( ++_p9k_worker_inflight[$_p9k_worker_request_id] ))
		_p9k_worker_fds[$fd]=$_p9k_worker_request_id$'\x1f'$2
	}
	trap '' PIPE
	{
		while zselect -a ready 0 ${(k)_p9k_worker_fds}
		do
			[[ $ready[1] == -r ]] || return
			for fd in ${ready:1}
			do
				if [[ $fd == 0 ]]
				then
					local buf=
					[[ -t 0 ]]
					if sysread -t 0 'buf[$#buf+1]'
					then
						while [[ $buf != *$'\x1e' ]]
						do
							sysread 'buf[$#buf+1]' || return
						done
					else
						(( $? == 4 )) || return
					fi
					for req in ${(ps:\x1e:)buf}
					do
						_p9k_worker_request_id=${req%%$'\x1f'*}
						() {
							eval $req[$#_p9k_worker_request_id+2,-1]
						}
						(( $+_p9k_worker_inflight[$_p9k_worker_request_id] )) && continue
						print -rn -- d$_p9k_worker_request_id$'\x1e' || return
					done
				else
					local REPLY=
					while true
					do
						if sysread -i $fd 'REPLY[$#REPLY+1]'
						then
							[[ $REPLY == *$'\x1e' ]] || continue
						else
							(( $? == 5 )) || return
							break
						fi
					done
					local cb=$_p9k_worker_fds[$fd]
					_p9k_worker_request_id=${cb%%$'\x1f'*}
					unset "_p9k_worker_fds[$fd]"
					exec {fd}>&-
					if [[ $REPLY == *$'\x1e' ]]
					then
						REPLY[-1]=""
						() {
							eval $cb[$#_p9k_worker_request_id+2,-1]
						}
					fi
					if (( --_p9k_worker_inflight[$_p9k_worker_request_id] == 0 ))
					then
						unset "_p9k_worker_inflight[$_p9k_worker_request_id]"
						print -rn -- d$_p9k_worker_request_id$'\x1e' || return
					fi
				fi
			done
		done
	} always {
		kill -- -$_p9k_worker_pgid
	}
}
_p9k_worker_receive () {
	eval "$__p9k_intro"
	[[ -z $_p9k__worker_resp_fd ]] && return
	{
		(( $# <= 1 )) || return
		local buf resp
		[[ -t $_p9k__worker_resp_fd ]]
		if sysread -i $_p9k__worker_resp_fd -t 0 'buf[$#buf+1]'
		then
			while [[ $buf == *[^$'\x05\x1e']$'\x05'# ]]
			do
				sysread -i $_p9k__worker_resp_fd 'buf[$#buf+1]' || return
			done
		else
			(( $? == 4 )) || return
		fi
		local -i reset max_reset
		for resp in ${(ps:\x1e:)${buf//$'\x05'}}
		do
			local arg=$resp[2,-1]
			case $resp[1] in
				(d) local req=$_p9k__worker_request_map[$arg]
					if [[ -n $req ]]
					then
						_p9k__worker_request_map[$arg]=
						print -rnu $_p9k__worker_req_fd -- $req || return
					else
						unset "_p9k__worker_request_map[$arg]"
					fi ;;
				(e) () {
						eval $arg
					}
					(( reset > max_reset )) && max_reset=reset  ;;
				(s) [[ -z $_p9k__worker_req_fd ]] || return
					[[ $arg == <1-> ]] || return
					_p9k__worker_pid=$arg
					sysopen -w -o cloexec -u _p9k__worker_req_fd $_p9k__worker_file_prefix.fifo || return
					local req=
					for req in $_p9k__worker_request_map
					do
						print -rnu $_p9k__worker_req_fd -- $req || return
					done
					_p9k__worker_request_map=({${(k)^_p9k__worker_request_map},''})  ;;
				(*) return 1 ;;
			esac
		done
		if (( max_reset == 2 ))
		then
			_p9k__refresh_reason=worker
			_p9k_set_prompt
			_p9k__refresh_reason=''
		fi
		(( max_reset )) && _p9k_reset_prompt
		return 0
	} always {
		(( $? )) && _p9k_worker_stop
	}
}
_p9k_worker_start () {
	setopt monitor || return
	{
		[[ -n $_p9k__worker_resp_fd ]] && return
		if [[ -n "$TMPDIR" && ( ( -d "$TMPDIR" && -w "$TMPDIR" ) || ! ( -d /tmp && -w /tmp ) ) ]]
		then
			local tmpdir=$TMPDIR
		else
			local tmpdir=/tmp
		fi
		_p9k__worker_file_prefix=$tmpdir/p10k.worker.$EUID.$sysparams[pid].$EPOCHSECONDS
		sysopen -r -o cloexec -u _p9k__worker_resp_fd <(
      exec 0</dev/null
      if [[ -n $_POWERLEVEL9K_WORKER_LOG_LEVEL ]]; then
        exec 2>$_p9k__worker_file_prefix.log
        setopt xtrace
      else
        exec 2>/dev/null
      fi
      builtin cd -q /                    || return
      zmodload zsh/zselect               || return
      ! { zselect -t0 || (( $? != 1 )) } || return
      local _p9k_worker_pgid=$sysparams[pid]
      _p9k_worker_main &
      {
        trap '' PIPE
        while syswrite $'\x05'; do zselect -t 1000; done
        zf_rm -f $_p9k__worker_file_prefix.fifo
        kill -- -$_p9k_worker_pgid
      } &
      exec =true) || return
		_p9k__worker_pid=$sysparams[procsubstpid]
		zle -F $_p9k__worker_resp_fd _p9k_worker_receive
		_p9k__worker_shell_pid=$sysparams[pid]
		add-zsh-hook zshexit _p9k_worker_cleanup
	} always {
		(( $? )) && _p9k_worker_stop
	}
}
_p9k_worker_stop () {
	emulate -L zsh
	add-zsh-hook -D zshexit _p9k_worker_cleanup
	[[ -n $_p9k__worker_resp_fd ]] && zle -F $_p9k__worker_resp_fd
	[[ -n $_p9k__worker_resp_fd ]] && exec {_p9k__worker_resp_fd}>&-
	[[ -n $_p9k__worker_req_fd ]] && exec {_p9k__worker_req_fd}>&-
	[[ -n $_p9k__worker_pid ]] && kill -- -$_p9k__worker_pid 2> /dev/null
	[[ -n $_p9k__worker_file_prefix ]] && zf_rm -f -- $_p9k__worker_file_prefix.fifo
	_p9k__worker_pid=
	_p9k__worker_req_fd=
	_p9k__worker_resp_fd=
	_p9k__worker_shell_pid=
	_p9k__worker_request_map=()
	return 0
}
_p9k_wrap_widgets () {
	(( __p9k_widgets_wrapped )) && return
	typeset -gir __p9k_widgets_wrapped=1
	local -a widget_list
	if is-at-least 5.3
	then
		local -aU widget_list=(zle-line-pre-redraw zle-line-init zle-line-finish zle-keymap-select overwrite-mode vi-replace visual-mode visual-line-mode deactivate-region clear-screen z4h-clear-screen-soft-top z4h-clear-screen-hard-top send-break $_POWERLEVEL9K_HOOK_WIDGETS)
	else
		if [[ -n "$TMPDIR" && ( ( -d "$TMPDIR" && -w "$TMPDIR" ) || ! ( -d /tmp && -w /tmp ) ) ]]
		then
			local tmpdir=$TMPDIR
		else
			local tmpdir=/tmp
		fi
		local keymap tmp=$tmpdir/p10k.bindings.$sysparams[pid]
		{
			for keymap in $keymaps
			do
				bindkey -M $keymap
			done > $tmp
			local -aU widget_list=(zle-isearch-exit zle-isearch-update zle-line-init zle-line-finish zle-history-line-set zle-keymap-select send-break $_POWERLEVEL9K_HOOK_WIDGETS ${${${(f)"$(<$tmp)"}##* }:#(*\"|.*)})
		} always {
			zf_rm -f -- $tmp
		}
	fi
	local widget
	for widget in $widget_list
	do
		if (( ! $+functions[_p9k_widget_$widget] ))
		then
			functions[_p9k_widget_$widget]='_p9k_widget '${(q)widget}' "$@"'
		fi
		if [[ $widget == zle-* && $widgets[$widget] == user:azhw:* && -n $functions[add-zle-hook-widget] ]]
		then
			add-zle-hook-widget $widget _p9k_widget_$widget
		else
			zle -A $widget ._p9k_orig_$widget
			zle -N $widget _p9k_widget_$widget
		fi
	done 2> /dev/null
	case ${widgets[._p9k_orig_zle-line-pre-redraw]:-} in
		(user:-z4h-zle-line-pre-redraw) _p9k_widget_zle-line-pre-redraw () {
				-z4h-zle-line-pre-redraw "$@"
				_p9k_widget_zle-line-pre-redraw-impl
			} ;;
		(?*) _p9k_widget_zle-line-pre-redraw () {
				zle ._p9k_orig_zle-line-pre-redraw -- "$@"
				local -i res=$?
				_p9k_widget_zle-line-pre-redraw-impl
				return res
			} ;;
		('') _p9k_widget_zle-line-pre-redraw () {
				_p9k_widget_zle-line-pre-redraw-impl
			} ;;
	esac
}
_pack () {
	# undefined
	builtin autoload -XUz
}
_pandoc () {
	local cur prev opts lastc informats outformats datafiles
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	opts="-f -r --from --read -t -w --to --write -o --output --data-dir -M --metadata --metadata-file -d --defaults --file-scope --sandbox -s --standalone --template -V --variable --wrap --ascii --toc --table-of-contents --toc-depth -N --number-sections --number-offset --top-level-division --extract-media --resource-path -H --include-in-header -B --include-before-body -A --include-after-body --no-highlight --highlight-style --syntax-definition --dpi --eol --columns -p --preserve-tabs --tab-stop --pdf-engine --pdf-engine-opt --reference-doc --self-contained --request-header --no-check-certificate --abbreviations --indented-code-classes --default-image-extension -F --filter -L --lua-filter --shift-heading-level-by --base-header-level --strip-empty-paragraphs --track-changes --strip-comments --reference-links --reference-location --atx-headers --markdown-headings --listings -i --incremental --slide-level --section-divs --html-q-tags --email-obfuscation --id-prefix -T --title-prefix -c --css --epub-subdirectory --epub-cover-image --epub-metadata --epub-embed-font --epub-chapter-level --ipynb-output -C --citeproc --bibliography --csl --citation-abbreviations --natbib --biblatex --mathml --webtex --mathjax --katex --gladtex --trace --dump-args --ignore-args --verbose --quiet --fail-if-warnings --log --bash-completion --list-input-formats --list-output-formats --list-extensions --list-highlight-languages --list-highlight-styles -D --print-default-template --print-default-data-file --print-highlight-style -v --version -h --help"
	informats="biblatex bibtex commonmark commonmark_x creole csljson csv docbook docx dokuwiki epub fb2 gfm haddock html ipynb jats jira json latex man markdown markdown_github markdown_mmd markdown_phpextra markdown_strict mediawiki muse native odt opml org rst rtf t2t textile tikiwiki twiki vimwiki"
	outformats="asciidoc asciidoctor beamer biblatex bibtex commonmark commonmark_x context csljson docbook docbook4 docbook5 docx dokuwiki dzslides epub epub2 epub3 fb2 gfm haddock html html4 html5 icml ipynb jats jats_archiving jats_articleauthoring jats_publishing jira json latex man markdown markdown_github markdown_mmd markdown_phpextra markdown_strict mediawiki ms muse native odt opendocument opml org pdf plain pptx revealjs rst rtf s5 slideous slidy tei texinfo textile xwiki zimwiki"
	highlight_styles="pygments tango espresso zenburn kate monochrome breezedark haddock"
	datafiles="reference.docx reference.odt reference.pptx MANUAL.txt docx/_rels/.rels pptx/_rels/.rels abbreviations bash_completion.tpl default.csl docx/[Content_Types].xml docx/docProps/app.xml docx/docProps/core.xml docx/docProps/custom.xml docx/word/_rels/document.xml.rels docx/word/_rels/footnotes.xml.rels docx/word/comments.xml docx/word/document.xml docx/word/fontTable.xml docx/word/footnotes.xml docx/word/numbering.xml docx/word/settings.xml docx/word/styles.xml docx/word/theme/theme1.xml docx/word/webSettings.xml dzslides/template.html epub.css init.lua odt/Configurations2/accelerator/current.xml odt/META-INF/manifest.xml odt/Thumbnails/thumbnail.png odt/content.xml odt/manifest.rdf odt/meta.xml odt/mimetype odt/settings.xml odt/styles.xml pandoc.List.lua pandoc.lua pptx/[Content_Types].xml pptx/docProps/app.xml pptx/docProps/core.xml pptx/ppt/_rels/presentation.xml.rels pptx/ppt/notesMasters/_rels/notesMaster1.xml.rels pptx/ppt/notesMasters/notesMaster1.xml pptx/ppt/notesSlides/_rels/notesSlide1.xml.rels pptx/ppt/notesSlides/_rels/notesSlide2.xml.rels pptx/ppt/notesSlides/notesSlide1.xml pptx/ppt/notesSlides/notesSlide2.xml pptx/ppt/presProps.xml pptx/ppt/presentation.xml pptx/ppt/slideLayouts/_rels/slideLayout1.xml.rels pptx/ppt/slideLayouts/_rels/slideLayout10.xml.rels pptx/ppt/slideLayouts/_rels/slideLayout11.xml.rels pptx/ppt/slideLayouts/_rels/slideLayout2.xml.rels pptx/ppt/slideLayouts/_rels/slideLayout3.xml.rels pptx/ppt/slideLayouts/_rels/slideLayout4.xml.rels pptx/ppt/slideLayouts/_rels/slideLayout5.xml.rels pptx/ppt/slideLayouts/_rels/slideLayout6.xml.rels pptx/ppt/slideLayouts/_rels/slideLayout7.xml.rels pptx/ppt/slideLayouts/_rels/slideLayout8.xml.rels pptx/ppt/slideLayouts/_rels/slideLayout9.xml.rels pptx/ppt/slideLayouts/slideLayout1.xml pptx/ppt/slideLayouts/slideLayout10.xml pptx/ppt/slideLayouts/slideLayout11.xml pptx/ppt/slideLayouts/slideLayout2.xml pptx/ppt/slideLayouts/slideLayout3.xml pptx/ppt/slideLayouts/slideLayout4.xml pptx/ppt/slideLayouts/slideLayout5.xml pptx/ppt/slideLayouts/slideLayout6.xml pptx/ppt/slideLayouts/slideLayout7.xml pptx/ppt/slideLayouts/slideLayout8.xml pptx/ppt/slideLayouts/slideLayout9.xml pptx/ppt/slideMasters/_rels/slideMaster1.xml.rels pptx/ppt/slideMasters/slideMaster1.xml pptx/ppt/slides/_rels/slide1.xml.rels pptx/ppt/slides/_rels/slide2.xml.rels pptx/ppt/slides/_rels/slide3.xml.rels pptx/ppt/slides/_rels/slide4.xml.rels pptx/ppt/slides/slide1.xml pptx/ppt/slides/slide2.xml pptx/ppt/slides/slide3.xml pptx/ppt/slides/slide4.xml pptx/ppt/tableStyles.xml pptx/ppt/theme/theme1.xml pptx/ppt/theme/theme2.xml pptx/ppt/viewProps.xml sample.lua templates/affiliations.jats templates/article.jats_publishing templates/default.asciidoc templates/default.asciidoctor templates/default.biblatex templates/default.bibtex templates/default.commonmark templates/default.context templates/default.docbook4 templates/default.docbook5 templates/default.dokuwiki templates/default.dzslides templates/default.epub2 templates/default.epub3 templates/default.haddock templates/default.html4 templates/default.html5 templates/default.icml templates/default.jats_archiving templates/default.jats_articleauthoring templates/default.jats_publishing templates/default.jira templates/default.latex templates/default.man templates/default.markdown templates/default.mediawiki templates/default.ms templates/default.muse templates/default.opendocument templates/default.opml templates/default.org templates/default.plain templates/default.revealjs templates/default.rst templates/default.rtf templates/default.s5 templates/default.slideous templates/default.slidy templates/default.tei templates/default.texinfo templates/default.textile templates/default.xwiki templates/default.zimwiki templates/styles.html translations/am.yaml translations/ar.yaml translations/bg.yaml translations/bn.yaml translations/ca.yaml translations/cs.yaml translations/da.yaml translations/de.yaml translations/el.yaml translations/en.yaml translations/eo.yaml translations/es.yaml translations/et.yaml translations/eu.yaml translations/fa.yaml translations/fi.yaml translations/fr.yaml translations/he.yaml translations/hi.yaml translations/hr.yaml translations/hu.yaml translations/is.yaml translations/it.yaml translations/km.yaml translations/ko.yaml translations/lo.yaml translations/lt.yaml translations/lv.yaml translations/nl.yaml translations/no.yaml translations/pl.yaml translations/pt.yaml translations/rm.yaml translations/ro.yaml translations/ru.yaml translations/sk.yaml translations/sl.yaml translations/sq.yaml translations/sr-cyrl.yaml translations/sr.yaml translations/sv.yaml translations/th.yaml translations/tr.yaml translations/uk.yaml translations/ur.yaml translations/vi.yaml translations/zh-Hans.yaml translations/zh-Hant.yaml"
	case "${prev}" in
		(--from | -f | --read | -r) COMPREPLY=($(compgen -W "${informats}" -- ${cur}))
			return 0 ;;
		(--to | -t | --write | -w | -D | --print-default-template) COMPREPLY=($(compgen -W "${outformats}" -- ${cur}))
			return 0 ;;
		(--email-obfuscation) COMPREPLY=($(compgen -W "references javascript none" -- ${cur}))
			return 0 ;;
		(--ipynb-output) COMPREPLY=($(compgen -W "all none best" -- ${cur}))
			return 0 ;;
		(--pdf-engine) COMPREPLY=($(compgen -W "pdflatex lualatex xelatex latexmk tectonic wkhtmltopdf weasyprint prince context pdfroff" -- ${cur}))
			return 0 ;;
		(--print-default-data-file) COMPREPLY=($(compgen -W "${datafiles}" -- ${cur}))
			return 0 ;;
		(--wrap) COMPREPLY=($(compgen -W "auto none preserve" -- ${cur}))
			return 0 ;;
		(--track-changes) COMPREPLY=($(compgen -W "accept reject all" -- ${cur}))
			return 0 ;;
		(--reference-location) COMPREPLY=($(compgen -W "block section document" -- ${cur}))
			return 0 ;;
		(--top-level-division) COMPREPLY=($(compgen -W "section chapter part" -- ${cur}))
			return 0 ;;
		(--highlight-style) COMPREPLY=($(compgen -W "${highlight_styles}" -- ${cur}))
			return 0 ;;
		(*)  ;;
	esac
	case "${cur}" in
		(-*) COMPREPLY=($(compgen -W "${opts}" -- ${cur}))
			return 0 ;;
		(*) local IFS=$'\n'
			COMPREPLY=($(compgen -X '' -f "${cur}"))
			return 0 ;;
	esac
}
_parameter () {
	_parameters -e
}
_parameters () {
	local expl pattern fakes faked tmp pfilt
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
	_wanted parameters expl parameter compadd "$@" -Q - "${(@M)${(@k)parameters[(R)${pattern[2]}~*local*]}:#${~pfilt}*}" "$fakes[@]" "${(@)${(@M)faked:#${~pattern[2]}}%%:*}"
}
_paste () {
	# undefined
	builtin autoload -XUz
}
_patch () {
	# undefined
	builtin autoload -XUz
}
_patchutils () {
	# undefined
	builtin autoload -XUz
}
_path_commands () {
	local need_desc expl ret=1
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
			for line in "${(f)$(_call_program command-descriptions _call_whatis -s 1 -r .\\\*\; _call_whatis -s 6 -r .\\\* 2>/dev/null)}"
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
	return $ret
}
_path_commands_caching_policy () {
	local file
	local -a oldp dbfiles
	oldp=("$1"(Nmw+1))
	(( $#oldp )) && return 0
	dbfiles=(/usr/share/man/index.(bt|db|dir|pag)(N) /usr/man/index.(bt|db|dir|pag)(N) /var/cache/man/index.(bt|db|dir|pag)(N) /var/catman/index.(bt|db|dir|pag)(N) /usr/share/man/*/whatis(N))
	for file in $dbfiles
	do
		[[ $file -nt $1 ]] && return 0
	done
	return 1
}
_path_files () {
	local -a match mbegin mend
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
	[[ $compstate[insert] = (*menu|[0-9]*) || -n "$_comp_correct" || ( -n "$compstate[pattern_match]" && "${orig#\~}" != (|*[^\\])[][*?#~^\|\<\>]* ) ]] && menu=yes
	if [[ -n "$_comp_correct" ]]
	then
		cfopt=-
		Uopt=-U
	else
		Mopts=(-M "r:|/=* r:|=*")
	fi
	if [[ "$pre" = [^][*?#^\|\<\>\\]#(\`[^\`]#\`|\$)*/* && "$compstate[quote]" != \' ]]
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
			tmp1=${tmp1//(#b)\\(?)/$match[1]}
			tpre=${tpre//(#b)\\([^\\\]\[\^\~\(\)\#\*\?])/$match[1]}
			tmp3=${donepath//(#b)\\(?)/$match[1]}
			while true
			do
				if [[ -z $path_completion || -d $prepath$realpath$tmp3$tmp2 ]]
				then
					tmp3=$tmp3$tmp1/
					donepath=${tmp3//(#b)([\\\]\[\^\~\(\)\#\*\?])/\\$match[1]}
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
		testpath="${donepath//(#b)\\([\\\]\[\^\~\(\)\#\*\?])/$match[1]}"
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
				if [[ -z "$_comp_correct" && "$compstate[pattern_match]" = \* && -n "$listsfx" && "$tmp2" = (|*[^\\])[][*?#~^\|\<\>]* ]]
				then
					PREFIX="$opre"
					SUFFIX="$osuf"
				fi
				if [[ -z "$compstate[insert]" ]] || {
						! zstyle -t ":completion:${curcontext}:paths" expand suffix && [[ -z "$listsfx" && ( -n "$_comp_correct" || -z "$compstate[pattern_match]" || "$SUFFIX" != */* || "${SUFFIX#*/}" = (|*[^\\])[][*?#~^\|\<\>]* ) ]]
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
				if [[ -z "$_comp_correct" && -n "$compstate[pattern_match]" && "$tmp2" = (|*[^\\])[][*?#~^\|\<\>]* ]]
				then
					cpre="${cpre}${tmp1[1]%%/*}/"
				else
					cpre="${cpre}${tpre%%/*}/"
				fi
				tpre="${tpre#*/}"
			elif [[ "$tsuf" = */* ]]
			then
				[[ "$tsuf" != /* ]] && mid="$testpath"
				if [[ -z "$_comp_correct" && -n "$compstate[pattern_match]" && "$tmp2" = (|*[^\\])[][*?#~^\|\<\>]* ]]
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
				if [[ -z "$_comp_correct" && -n "$compstate[pattern_match]" && "${PREFIX#\~}$SUFFIX" = (|*[^\\])[][*?#~^\|\<\>]* ]]
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
	[[ nm -ne compstate[nmatches] ]]
}
_pax () {
	# undefined
	builtin autoload -XUz
}
_pbcopy () {
	# undefined
	builtin autoload -XUz
}
_pbm () {
	# undefined
	builtin autoload -XUz
}
_pbuilder () {
	# undefined
	builtin autoload -XUz
}
_pdf () {
	# undefined
	builtin autoload -XUz
}
_pdftk () {
	# undefined
	builtin autoload -XUz
}
_perforce () {
	# undefined
	builtin autoload -XUz
}
_perl () {
	# undefined
	builtin autoload -XUz
}
_perl_basepods () {
	# undefined
	builtin autoload -XUz
}
_perl_modules () {
	# undefined
	builtin autoload -XUz
}
_perldoc () {
	# undefined
	builtin autoload -XUz
}
_pfctl () {
	# undefined
	builtin autoload -XUz
}
_pfexec () {
	# undefined
	builtin autoload -XUz
}
_pgrep () {
	# undefined
	builtin autoload -XUz
}
_php () {
	# undefined
	builtin autoload -XUz
}
_physical_volumes () {
	# undefined
	builtin autoload -XUz
}
_pick_variant () {
	local output cmd pat
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
	return 1
}
_picocom () {
	# undefined
	builtin autoload -XUz
}
_pidof () {
	# undefined
	builtin autoload -XUz
}
_pids () {
	# undefined
	builtin autoload -XUz
}
_pine () {
	# undefined
	builtin autoload -XUz
}
_ping () {
	# undefined
	builtin autoload -XUz
}
_pip_completion () {
	local words cword
	read -Ac words
	read -cn cword
	reply=($( COMP_WORDS="$words[*]" \
             COMP_CWORD=$(( cword-1 )) \
             PIP_AUTO_COMPLETE=1 $words[1] 2>/dev/null ))
}
_piuparts () {
	# undefined
	builtin autoload -XUz
}
_pkg-config () {
	# undefined
	builtin autoload -XUz
}
_pkg5 () {
	# undefined
	builtin autoload -XUz
}
_pkg_instance () {
	# undefined
	builtin autoload -XUz
}
_pkgadd () {
	# undefined
	builtin autoload -XUz
}
_pkginfo () {
	# undefined
	builtin autoload -XUz
}
_pkgrm () {
	# undefined
	builtin autoload -XUz
}
_pkgtool () {
	# undefined
	builtin autoload -XUz
}
_plutil () {
	# undefined
	builtin autoload -XUz
}
_poetry () {
	# undefined
	builtin autoload -XUz
}
_pon () {
	# undefined
	builtin autoload -XUz
}
_portaudit () {
	# undefined
	builtin autoload -XUz
}
_portlint () {
	# undefined
	builtin autoload -XUz
}
_portmaster () {
	# undefined
	builtin autoload -XUz
}
_ports () {
	# undefined
	builtin autoload -XUz
}
_portsnap () {
	# undefined
	builtin autoload -XUz
}
_postfix () {
	# undefined
	builtin autoload -XUz
}
_postscript () {
	# undefined
	builtin autoload -XUz
}
_powerd () {
	# undefined
	builtin autoload -XUz
}
_prcs () {
	# undefined
	builtin autoload -XUz
}
_precommand () {
	# undefined
	builtin autoload -XUz
}
_prefix () {
	# undefined
	builtin autoload -XUz
}
_print () {
	# undefined
	builtin autoload -XUz
}
_printenv () {
	# undefined
	builtin autoload -XUz
}
_printers () {
	# undefined
	builtin autoload -XUz
}
_process_names () {
	# undefined
	builtin autoload -XUz
}
_procstat () {
	# undefined
	builtin autoload -XUz
}
_progressed () {
	DOWNLOAD_FILE="$1"
	[[ -f $DOWNLOAD_FILE ]] || {
		echo "usage $0 <path 2 file getting downloaded>"
		return 1
	}
	TMP_FILE=$TMP/.byte_counter.txt
	CURRENT=$(ls -s $DOWNLOAD_FILE | cut -d ' ' -f1)
	[[ -f $TMP_FILE ]] || echo $CURRENT > $TMP_FILE
	PREVIOUS=$(cat  $TMP_FILE)
	PROGRESS=$(($CURRENT-$PREVIOUS))
	echo "$CURRENT B - $PREVIOUS B"
	echo "$PROGRESS Bytes"
	echo "$(($PROGRESS/1024)) KiloBytes"
	echo $CURRENT > $TMP_FILE
}
_prompt () {
	# undefined
	builtin autoload -XUz
}
_prove () {
	# undefined
	builtin autoload -XUz
}
_prstat () {
	# undefined
	builtin autoload -XUz
}
_ps () {
	# undefined
	builtin autoload -XUz
}
_ps1234 () {
	# undefined
	builtin autoload -XUz
}
_pscp () {
	# undefined
	builtin autoload -XUz
}
_pspdf () {
	# undefined
	builtin autoload -XUz
}
_psutils () {
	# undefined
	builtin autoload -XUz
}
_ptree () {
	# undefined
	builtin autoload -XUz
}
_pump () {
	# undefined
	builtin autoload -XUz
}
_putclip () {
	# undefined
	builtin autoload -XUz
}
_pwgen () {
	# undefined
	builtin autoload -XUz
}
_pydoc () {
	# undefined
	builtin autoload -XUz
}
_python () {
	# undefined
	builtin autoload -XUz
}
_python_modules () {
	# undefined
	builtin autoload -XUz
}
_qdbus () {
	# undefined
	builtin autoload -XUz
}
_qemu () {
	# undefined
	builtin autoload -XUz
}
_qiv () {
	# undefined
	builtin autoload -XUz
}
_qtplay () {
	# undefined
	builtin autoload -XUz
}
_quilt () {
	# undefined
	builtin autoload -XUz
}
_raggle () {
	# undefined
	builtin autoload -XUz
}
_rake () {
	# undefined
	builtin autoload -XUz
}
_ranlib () {
	# undefined
	builtin autoload -XUz
}
_rar () {
	# undefined
	builtin autoload -XUz
}
_rcctl () {
	# undefined
	builtin autoload -XUz
}
_rcs () {
	# undefined
	builtin autoload -XUz
}
_rdesktop () {
	# undefined
	builtin autoload -XUz
}
_read () {
	# undefined
	builtin autoload -XUz
}
_read_comp () {
	# undefined
	builtin autoload -XUz
}
_readelf () {
	# undefined
	builtin autoload -XUz
}
_readlink () {
	# undefined
	builtin autoload -XUz
}
_readshortcut () {
	# undefined
	builtin autoload -XUz
}
_rebootin () {
	# undefined
	builtin autoload -XUz
}
_redirect () {
	local strs _comp_command1 _comp_command2 _comp_command
	_set_command
	strs=(-default-)
	if [[ "$CURRENT" != "1" ]]
	then
		strs=("${_comp_command}" "$strs[@]")
		if [[ -n "$_comp_command1" ]]
		then
			strs=("${_comp_command1}" "$strs[@]")
			[[ -n "$_comp_command2" ]] && strs=("${_comp_command2}" "$strs[@]")
		fi
	fi
	_dispatch -redirect-,{${compstate[redirect]},-default-},${^strs}
}
_regex_arguments () {
	# undefined
	builtin autoload -XUz
}
_regex_words () {
	# undefined
	builtin autoload -XUz
}
_remote_files () {
	# undefined
	builtin autoload -XUz
}
_renice () {
	# undefined
	builtin autoload -XUz
}
_reprepro () {
	# undefined
	builtin autoload -XUz
}
_requested () {
	local __gopt
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
	fi
}
_retrieve_cache () {
	# undefined
	builtin autoload -XUz
}
_retrieve_mac_apps () {
	# undefined
	builtin autoload -XUz
}
_ri () {
	# undefined
	builtin autoload -XUz
}
_rlogin () {
	# undefined
	builtin autoload -XUz
}
_rm () {
	# undefined
	builtin autoload -XUz
}
_rmdir () {
	# undefined
	builtin autoload -XUz
}
_route () {
	# undefined
	builtin autoload -XUz
}
_rpm () {
	# undefined
	builtin autoload -XUz
}
_rpmbuild () {
	# undefined
	builtin autoload -XUz
}
_rrdtool () {
	# undefined
	builtin autoload -XUz
}
_rsync () {
	# undefined
	builtin autoload -XUz
}
_rubber () {
	# undefined
	builtin autoload -XUz
}
_ruby () {
	# undefined
	builtin autoload -XUz
}
_run-help () {
	# undefined
	builtin autoload -XUz
}
_runit () {
	# undefined
	builtin autoload -XUz
}
_sablotron () {
	# undefined
	builtin autoload -XUz
}
_samba () {
	# undefined
	builtin autoload -XUz
}
_savecore () {
	# undefined
	builtin autoload -XUz
}
_say () {
	# undefined
	builtin autoload -XUz
}
_sc_usage () {
	# undefined
	builtin autoload -XUz
}
_sccs () {
	# undefined
	builtin autoload -XUz
}
_sched () {
	# undefined
	builtin autoload -XUz
}
_schedtool () {
	# undefined
	builtin autoload -XUz
}
_schroot () {
	# undefined
	builtin autoload -XUz
}
_scl () {
	# undefined
	builtin autoload -XUz
}
_scons () {
	# undefined
	builtin autoload -XUz
}
_screen () {
	# undefined
	builtin autoload -XUz
}
_script () {
	# undefined
	builtin autoload -XUz
}
_scselect () {
	# undefined
	builtin autoload -XUz
}
_scutil () {
	# undefined
	builtin autoload -XUz
}
_sed () {
	# undefined
	builtin autoload -XUz
}
_sep_parts () {
	# undefined
	builtin autoload -XUz
}
_seq () {
	# undefined
	builtin autoload -XUz
}
_sequence () {
	# undefined
	builtin autoload -XUz
}
_service () {
	# undefined
	builtin autoload -XUz
}
_services () {
	# undefined
	builtin autoload -XUz
}
_set () {
	# undefined
	builtin autoload -XUz
}
_set_command () {
	local command
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
	fi
}
_setfacl () {
	# undefined
	builtin autoload -XUz
}
_setopt () {
	# undefined
	builtin autoload -XUz
}
_setsid () {
	# undefined
	builtin autoload -XUz
}
_setup () {
	local val nm="$compstate[nmatches]"
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
	[[ "$_comp_force_list" != always ]] && zstyle -s ":completion:${curcontext}:$1" force-list val && [[ "$val" = always || ( "$val" = [0-9]## && ( -z "$_comp_force_list" || _comp_force_list -gt val ) ) ]] && _comp_force_list="$val"
}
_setxkbmap () {
	# undefined
	builtin autoload -XUz
}
_sh () {
	# undefined
	builtin autoload -XUz
}
_shasum () {
	# undefined
	builtin autoload -XUz
}
_showmount () {
	# undefined
	builtin autoload -XUz
}
_shred () {
	# undefined
	builtin autoload -XUz
}
_shuf () {
	# undefined
	builtin autoload -XUz
}
_shutdown () {
	# undefined
	builtin autoload -XUz
}
_signals () {
	# undefined
	builtin autoload -XUz
}
_signify () {
	# undefined
	builtin autoload -XUz
}
_sisu () {
	# undefined
	builtin autoload -XUz
}
_slrn () {
	# undefined
	builtin autoload -XUz
}
_smartmontools () {
	# undefined
	builtin autoload -XUz
}
_smit () {
	# undefined
	builtin autoload -XUz
}
_snoop () {
	# undefined
	builtin autoload -XUz
}
_socket () {
	# undefined
	builtin autoload -XUz
}
_sockstat () {
	# undefined
	builtin autoload -XUz
}
_softwareupdate () {
	# undefined
	builtin autoload -XUz
}
_sort () {
	# undefined
	builtin autoload -XUz
}
_source () {
	# undefined
	builtin autoload -XUz
}
_spamassassin () {
	# undefined
	builtin autoload -XUz
}
_split () {
	# undefined
	builtin autoload -XUz
}
_sqlite () {
	# undefined
	builtin autoload -XUz
}
_sqsh () {
	# undefined
	builtin autoload -XUz
}
_ss () {
	# undefined
	builtin autoload -XUz
}
_ssh () {
	# undefined
	builtin autoload -XUz
}
_ssh_hosts () {
	# undefined
	builtin autoload -XUz
}
_sshfs () {
	# undefined
	builtin autoload -XUz
}
_stat () {
	# undefined
	builtin autoload -XUz
}
_stdbuf () {
	# undefined
	builtin autoload -XUz
}
_stgit () {
	# undefined
	builtin autoload -XUz
}
_store_cache () {
	# undefined
	builtin autoload -XUz
}
_strace () {
	# undefined
	builtin autoload -XUz
}
_strftime () {
	# undefined
	builtin autoload -XUz
}
_strings () {
	# undefined
	builtin autoload -XUz
}
_strip () {
	# undefined
	builtin autoload -XUz
}
_stty () {
	# undefined
	builtin autoload -XUz
}
_su () {
	# undefined
	builtin autoload -XUz
}
_sub_commands () {
	# undefined
	builtin autoload -XUz
}
_sublimetext () {
	# undefined
	builtin autoload -XUz
}
_subscript () {
	# undefined
	builtin autoload -XUz
}
_subversion () {
	# undefined
	builtin autoload -XUz
}
_sudo () {
	# undefined
	builtin autoload -XUz
}
_suffix_alias_files () {
	local expl pat
	(( ${#saliases} )) || return 1
	if (( ${#saliases} == 1 ))
	then
		pat="*.${(kq)saliases}"
	else
		local -a tmpa
		tmpa=(${(kq)saliases})
		pat="*.(${(kj.|.)tmpa})"
	fi
	_path_files "$@" -g $pat
}
_surfraw () {
	# undefined
	builtin autoload -XUz
}
_svcadm () {
	# undefined
	builtin autoload -XUz
}
_svccfg () {
	# undefined
	builtin autoload -XUz
}
_svcprop () {
	# undefined
	builtin autoload -XUz
}
_svcs () {
	# undefined
	builtin autoload -XUz
}
_svcs_fmri () {
	# undefined
	builtin autoload -XUz
}
_svn-buildpackage () {
	# undefined
	builtin autoload -XUz
}
_sw_vers () {
	# undefined
	builtin autoload -XUz
}
_swaks () {
	# undefined
	builtin autoload -XUz
}
_swanctl () {
	# undefined
	builtin autoload -XUz
}
_swift () {
	# undefined
	builtin autoload -XUz
}
_sys_calls () {
	# undefined
	builtin autoload -XUz
}
_sysctl () {
	# undefined
	builtin autoload -XUz
}
_sysrc () {
	# undefined
	builtin autoload -XUz
}
_sysstat () {
	# undefined
	builtin autoload -XUz
}
_systat () {
	# undefined
	builtin autoload -XUz
}
_system_profiler () {
	# undefined
	builtin autoload -XUz
}
_tac () {
	# undefined
	builtin autoload -XUz
}
_tags () {
	local prev
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
	comptags "-N$prev"
}
_tail () {
	# undefined
	builtin autoload -XUz
}
_tar () {
	# undefined
	builtin autoload -XUz
}
_tar_archive () {
	# undefined
	builtin autoload -XUz
}
_tardy () {
	# undefined
	builtin autoload -XUz
}
_tcpdump () {
	# undefined
	builtin autoload -XUz
}
_tcpsys () {
	# undefined
	builtin autoload -XUz
}
_tcptraceroute () {
	# undefined
	builtin autoload -XUz
}
_tee () {
	# undefined
	builtin autoload -XUz
}
_telnet () {
	# undefined
	builtin autoload -XUz
}
_terminals () {
	# undefined
	builtin autoload -XUz
}
_tex () {
	# undefined
	builtin autoload -XUz
}
_texi () {
	# undefined
	builtin autoload -XUz
}
_texinfo () {
	# undefined
	builtin autoload -XUz
}
_tidy () {
	# undefined
	builtin autoload -XUz
}
_tiff () {
	# undefined
	builtin autoload -XUz
}
_tilde () {
	# undefined
	builtin autoload -XUz
}
_tilde_files () {
	# undefined
	builtin autoload -XUz
}
_time_zone () {
	# undefined
	builtin autoload -XUz
}
_timeout () {
	# undefined
	builtin autoload -XUz
}
_tin () {
	# undefined
	builtin autoload -XUz
}
_tla () {
	# undefined
	builtin autoload -XUz
}
_tmux () {
	# undefined
	builtin autoload -XUz
}
_todo.sh () {
	# undefined
	builtin autoload -XUz
}
_toilet () {
	# undefined
	builtin autoload -XUz
}
_toolchain-source () {
	# undefined
	builtin autoload -XUz
}
_top () {
	# undefined
	builtin autoload -XUz
}
_topgit () {
	# undefined
	builtin autoload -XUz
}
_totd () {
	# undefined
	builtin autoload -XUz
}
_touch () {
	# undefined
	builtin autoload -XUz
}
_tpb () {
	# undefined
	builtin autoload -XUz
}
_tpconfig () {
	# undefined
	builtin autoload -XUz
}
_tput () {
	# undefined
	builtin autoload -XUz
}
_tr () {
	# undefined
	builtin autoload -XUz
}
_tracepath () {
	# undefined
	builtin autoload -XUz
}
_trap () {
	# undefined
	builtin autoload -XUz
}
_tree () {
	# undefined
	builtin autoload -XUz
}
_truss () {
	# undefined
	builtin autoload -XUz
}
_tty () {
	# undefined
	builtin autoload -XUz
}
_ttyctl () {
	# undefined
	builtin autoload -XUz
}
_ttys () {
	# undefined
	builtin autoload -XUz
}
_tune2fs () {
	# undefined
	builtin autoload -XUz
}
_twidge () {
	# undefined
	builtin autoload -XUz
}
_twisted () {
	# undefined
	builtin autoload -XUz
}
_typeset () {
	# undefined
	builtin autoload -XUz
}
_ulimit () {
	# undefined
	builtin autoload -XUz
}
_uml () {
	# undefined
	builtin autoload -XUz
}
_umountable () {
	# undefined
	builtin autoload -XUz
}
_unace () {
	# undefined
	builtin autoload -XUz
}
_uname () {
	# undefined
	builtin autoload -XUz
}
_unexpand () {
	# undefined
	builtin autoload -XUz
}
_unhash () {
	# undefined
	builtin autoload -XUz
}
_uniq () {
	# undefined
	builtin autoload -XUz
}
_unison () {
	# undefined
	builtin autoload -XUz
}
_units () {
	# undefined
	builtin autoload -XUz
}
_update-alternatives () {
	# undefined
	builtin autoload -XUz
}
_update-rc.d () {
	# undefined
	builtin autoload -XUz
}
_uptime () {
	# undefined
	builtin autoload -XUz
}
_urls () {
	# undefined
	builtin autoload -XUz
}
_urpmi () {
	# undefined
	builtin autoload -XUz
}
_urxvt () {
	# undefined
	builtin autoload -XUz
}
_usage () {
	if isFunction3 "$1"
	then
		CMD="$1"
	else
		CMD=$(basename "$1")
	fi
	ARG_CNT=$2
	ARG_CNT_MIN=$3
	PARAM="$4"
	USAGE="$5"
	if isDebug
	then
		echo "0:function $0\n1:CMD $1\n2:ARG_CNT $2\n3:ARG_CNT_MIN $3\n4:PARAM $4\n5:USAGE $5"
		echo "0:function $0\n1:CMD $CMD\n2:ARG_CNT $ARG_CNT\n3:ARG_CNT_MIN $ARG_CNT_MIN\n4:PARAM $PARAM\n5:USAGE $USAGE"
	fi
	if [[ $ARG_CNT -lt $ARG_CNT_MIN ]]
	then
		echo "Usage: $CMD $PARAM"
		echo
		echo "$USAGE"
		return 1
	fi
}
_uscan () {
	# undefined
	builtin autoload -XUz
}
_user_admin () {
	# undefined
	builtin autoload -XUz
}
_user_at_host () {
	# undefined
	builtin autoload -XUz
}
_user_expand () {
	# undefined
	builtin autoload -XUz
}
_user_math_func () {
	# undefined
	builtin autoload -XUz
}
_users () {
	# undefined
	builtin autoload -XUz
}
_users_on () {
	# undefined
	builtin autoload -XUz
}
_uzbl () {
	# undefined
	builtin autoload -XUz
}
_valgrind () {
	# undefined
	builtin autoload -XUz
}
_value () {
	# undefined
	builtin autoload -XUz
}
_values () {
	# undefined
	builtin autoload -XUz
}
_vared () {
	# undefined
	builtin autoload -XUz
}
_vars () {
	# undefined
	builtin autoload -XUz
}
_vcsh () {
	# undefined
	builtin autoload -XUz
}
_vim () {
	# undefined
	builtin autoload -XUz
}
_vim-addons () {
	# undefined
	builtin autoload -XUz
}
_visudo () {
	# undefined
	builtin autoload -XUz
}
_vmctl () {
	# undefined
	builtin autoload -XUz
}
_vmstat () {
	# undefined
	builtin autoload -XUz
}
_vnc () {
	# undefined
	builtin autoload -XUz
}
_volume_groups () {
	# undefined
	builtin autoload -XUz
}
_vorbis () {
	# undefined
	builtin autoload -XUz
}
_vpnc () {
	# undefined
	builtin autoload -XUz
}
_vserver () {
	# undefined
	builtin autoload -XUz
}
_vux () {
	# undefined
	builtin autoload -XUz
}
_w () {
	# undefined
	builtin autoload -XUz
}
_w3m () {
	# undefined
	builtin autoload -XUz
}
_wait () {
	# undefined
	builtin autoload -XUz
}
_wajig () {
	# undefined
	builtin autoload -XUz
}
_wakeup_capable_devices () {
	# undefined
	builtin autoload -XUz
}
_wanna-build () {
	# undefined
	builtin autoload -XUz
}
_wanted () {
	local -a __targs __gopt
	zparseopts -D -a __gopt 1 2 V J x C:=__targs
	_tags "$__targs[@]" "$1"
	while _tags
	do
		_all_labels "$__gopt[@]" "$@" && return 0
	done
	return 1
}
_watch () {
	# undefined
	builtin autoload -XUz
}
_watch-snoop () {
	# undefined
	builtin autoload -XUz
}
_wc () {
	# undefined
	builtin autoload -XUz
}
_webbrowser () {
	# undefined
	builtin autoload -XUz
}
_wget () {
	# undefined
	builtin autoload -XUz
}
_whereis () {
	# undefined
	builtin autoload -XUz
}
_which () {
	# undefined
	builtin autoload -XUz
}
_who () {
	# undefined
	builtin autoload -XUz
}
_whois () {
	# undefined
	builtin autoload -XUz
}
_widgets () {
	# undefined
	builtin autoload -XUz
}
_wiggle () {
	# undefined
	builtin autoload -XUz
}
_wipefs () {
	# undefined
	builtin autoload -XUz
}
_wpa_cli () {
	# undefined
	builtin autoload -XUz
}
_x_arguments () {
	# undefined
	builtin autoload -XUz
}
_x_borderwidth () {
	# undefined
	builtin autoload -XUz
}
_x_color () {
	# undefined
	builtin autoload -XUz
}
_x_colormapid () {
	# undefined
	builtin autoload -XUz
}
_x_cursor () {
	# undefined
	builtin autoload -XUz
}
_x_display () {
	# undefined
	builtin autoload -XUz
}
_x_extension () {
	# undefined
	builtin autoload -XUz
}
_x_font () {
	# undefined
	builtin autoload -XUz
}
_x_geometry () {
	# undefined
	builtin autoload -XUz
}
_x_keysym () {
	# undefined
	builtin autoload -XUz
}
_x_locale () {
	# undefined
	builtin autoload -XUz
}
_x_modifier () {
	# undefined
	builtin autoload -XUz
}
_x_name () {
	# undefined
	builtin autoload -XUz
}
_x_resource () {
	# undefined
	builtin autoload -XUz
}
_x_selection_timeout () {
	# undefined
	builtin autoload -XUz
}
_x_title () {
	# undefined
	builtin autoload -XUz
}
_x_utils () {
	# undefined
	builtin autoload -XUz
}
_x_visual () {
	# undefined
	builtin autoload -XUz
}
_x_window () {
	# undefined
	builtin autoload -XUz
}
_xargs () {
	# undefined
	builtin autoload -XUz
}
_xauth () {
	# undefined
	builtin autoload -XUz
}
_xautolock () {
	# undefined
	builtin autoload -XUz
}
_xclip () {
	# undefined
	builtin autoload -XUz
}
_xcode-select () {
	# undefined
	builtin autoload -XUz
}
_xdvi () {
	# undefined
	builtin autoload -XUz
}
_xfig () {
	# undefined
	builtin autoload -XUz
}
_xft_fonts () {
	# undefined
	builtin autoload -XUz
}
_xloadimage () {
	# undefined
	builtin autoload -XUz
}
_xmlsoft () {
	# undefined
	builtin autoload -XUz
}
_xmlstarlet () {
	# undefined
	builtin autoload -XUz
}
_xmms2 () {
	# undefined
	builtin autoload -XUz
}
_xmodmap () {
	# undefined
	builtin autoload -XUz
}
_xournal () {
	# undefined
	builtin autoload -XUz
}
_xpdf () {
	# undefined
	builtin autoload -XUz
}
_xrandr () {
	# undefined
	builtin autoload -XUz
}
_xscreensaver () {
	# undefined
	builtin autoload -XUz
}
_xset () {
	# undefined
	builtin autoload -XUz
}
_xt_arguments () {
	# undefined
	builtin autoload -XUz
}
_xt_session_id () {
	# undefined
	builtin autoload -XUz
}
_xterm () {
	# undefined
	builtin autoload -XUz
}
_xv () {
	# undefined
	builtin autoload -XUz
}
_xwit () {
	# undefined
	builtin autoload -XUz
}
_xxd () {
	# undefined
	builtin autoload -XUz
}
_xz () {
	# undefined
	builtin autoload -XUz
}
_yafc () {
	# undefined
	builtin autoload -XUz
}
_yast () {
	# undefined
	builtin autoload -XUz
}
_yodl () {
	# undefined
	builtin autoload -XUz
}
_yp () {
	# undefined
	builtin autoload -XUz
}
_yum () {
	# undefined
	builtin autoload -XUz
}
_zargs () {
	# undefined
	builtin autoload -XUz
}
_zathura () {
	# undefined
	builtin autoload -XUz
}
_zattr () {
	# undefined
	builtin autoload -XUz
}
_zcalc () {
	# undefined
	builtin autoload -XUz
}
_zcalc_line () {
	# undefined
	builtin autoload -XUz
}
_zcat () {
	# undefined
	builtin autoload -XUz
}
_zcompile () {
	# undefined
	builtin autoload -XUz
}
_zdump () {
	# undefined
	builtin autoload -XUz
}
_zeal () {
	# undefined
	builtin autoload -XUz
}
_zed () {
	# undefined
	builtin autoload -XUz
}
_zfs () {
	# undefined
	builtin autoload -XUz
}
_zfs_dataset () {
	# undefined
	builtin autoload -XUz
}
_zfs_keysource_props () {
	# undefined
	builtin autoload -XUz
}
_zfs_pool () {
	# undefined
	builtin autoload -XUz
}
_zftp () {
	# undefined
	builtin autoload -XUz
}
_zip () {
	# undefined
	builtin autoload -XUz
}
_zle () {
	# undefined
	builtin autoload -XUz
}
_zlogin () {
	# undefined
	builtin autoload -XUz
}
_zmodload () {
	# undefined
	builtin autoload -XUz
}
_zmv () {
	# undefined
	builtin autoload -XUz
}
_zoneadm () {
	# undefined
	builtin autoload -XUz
}
_zones () {
	# undefined
	builtin autoload -XUz
}
_zpool () {
	# undefined
	builtin autoload -XUz
}
_zpty () {
	# undefined
	builtin autoload -XUz
}
_zsh () {
	# undefined
	builtin autoload -XUz
}
_zsh-mime-handler () {
	# undefined
	builtin autoload -XUz
}
_zsh_tmux_plugin_run () {
	if [[ -n "$@" ]]
	then
		command tmux "$@"
		return $?
	fi
	local -a tmux_cmd
	tmux_cmd=(command tmux)
	[[ "$ZSH_TMUX_ITERM2" == "true" ]] && tmux_cmd+=(-CC)
	[[ "$ZSH_TMUX_UNICODE" == "true" ]] && tmux_cmd+=(-u)
	[[ "$ZSH_TMUX_AUTOCONNECT" == "true" ]] && $tmux_cmd attach
	if [[ $? -ne 0 ]]
	then
		if [[ "$ZSH_TMUX_FIXTERM" == "true" ]]
		then
			tmux_cmd+=(-f "$_ZSH_TMUX_FIXED_CONFIG")
		elif [[ -e "$ZSH_TMUX_CONFIG" ]]
		then
			tmux_cmd+=(-f "$ZSH_TMUX_CONFIG")
		fi
		$tmux_cmd new-session
	fi
	if [[ "$ZSH_TMUX_AUTOQUIT" == "true" ]]
	then
		exit
	fi
}
_zsocket () {
	# undefined
	builtin autoload -XUz
}
_zstyle () {
	# undefined
	builtin autoload -XUz
}
_ztodo () {
	# undefined
	builtin autoload -XUz
}
_zypper () {
	# undefined
	builtin autoload -XUz
}
abbr_it () {
	IFS=$DELIMITER_ENDL
	for i in $(cat $SHELL_VARS | grep -E '^export abbr_')
	do
		TMP_KEY=$(e "${i}" | cut -d'=' -f1)
		TMP_KEY=${TMP_KEY//export /}
		CMD=$(e "addvar $(echo \"${i}\" | grep -oE '\s.*\=')")
		CMD="${CMD//abbr_/}'\$${TMP_KEY}'"
		EXISTS=$(cat $SHELL_VARS | grep -e "\$${TMP_KEY}")
		CMD=${CMD//=/ }
		echo "\$CMD = ${CMD}"
		[[ -z ${EXISTS} ]] && eval ${CMD}
	done
}
abs () {
	echo "$1" | tr -d -
}
activate_xcode_commands () {
	PATH=/Applications/Xcode.app/Contents/Developer/usr/bin:$PATH
}
add-function () {
	[[ $# -eq 1 ]] && function_exists "$1" && {
		echo "$1 already exists."
		type $1
		builtin which $1
		return 1
	}
	FUNCTIONS=$BIN/.functions
	[[ -n "${2}" ]] && FUNCTIONS="${2}"
	echo >> $FUNCTIONS
	FUNCTION_NAME=$1
	builtin which $FUNCTION_NAME >> $FUNCTIONS
}
add-function-ext () {
	[[ $# -eq 1 ]] && function_exists "$1" && {
		echo "$1 already exists."
		type $1
		builtin which $1
		return 1
	}
	FUNCTIONS_EXT=$BIN/.functions_ext
	[[ -n "${2}" ]] && FUNCTIONS_EXT="${2}"
	echo >> $FUNCTIONS_EXT
	FUNCTION_NAME=$1
	builtin which $FUNCTION_NAME >> $FUNCTIONS_EXT
}
add-moron () {
	NAME="${1}"
	SURNAME="${2}"
	[[ -n "${3}" ]] && RESIDENCE="${3}"
	echo "${NAME};${SURNAME};${NAME} ${SURNAME};${RESIDENCE}" >> $JANUARY_6th_INSURRECTION
}
add-zsh-hook () {
	emulate -L zsh
	local -a hooktypes
	hooktypes=(chpwd precmd preexec periodic zshaddhistory zshexit zsh_directory_name)
	local usage="Usage: add-zsh-hook hook function\nValid hooks are:\n  $hooktypes"
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
	fi
}
addLinkCat () {
	add-link-category ${1} ${2}
	source /Users/sedatkilinc/.shell_vars
	source $HOME/.shell_aliases
}
addPath2Places () {
	echo "$1" >> /Users/sedatkilinc/__Places/paths.txt
}
add_ls () {
	echo $0
	[ -z "$ARR_ALIAS" ] && export ARR_ALIAS=("start")
	ARR_ALIAS+="$1"
}
addalias () {
	if [[ $# -eq 0 ]]
	then
		echo "Usage: $(basename "$0") alias command"
		return 1
	fi
	ALIASESFILE=$HOME/.bash_aliases
	WC_ORIG=$(cat $ALIASESFILE | wc -l)
	TMPFOLDER=$HOME/tmp/.bashstuff
	mkdir -p $TMPFOLDER
	TMPFILE=$TMPFOLDER/bash_aliases.prev
	\cp -f $ALIASESFILE $TMPFILE
	echo "alias $1='$2'" >> $ALIASESFILE
	WC_NEW=$(cat $ALIASESFILE | wc -l)
	if [[ $WC_NEW -lt $WC_ORIG ]]
	then
		echo "Error: New aliases-file didn't get extended"
		echo "Number of lines of previous aliases-file $WC_ORIG"
		echo "BUT number of lines of newly extended aliases-file $([[ $WC_NEW -eq $WC_ORIG  ]] && echo "STILL" || echo "ONLY") $WC_NEW"
		echo "Backing up new aliases-file $ALIASESFILE to ${TMPFILE}.backup\! for further analysis."
		\cp -f $ALIASESFILE "${TMPFILE}.backup\!"
		[[ $? -eq 0 ]] && echo "Backup Successful" || echo "BackUp failed! Check path, destination directory for permissions or even existence"
		echo "Restoring previous aliases-file..."
		\cp -f $TMPFILE $ALIASESFILE
		[[ $? -eq 0 ]] && echo "...previous aliases-file $TMPFILE got restored to $ALIASESFILE" || echo "This is some bullshit\nfailed! Check path, destination directory for permissions or even existence"
	fi
}
addspace () {
	local CNTNT="${1}"
	echo $CNTNT
}
alias-value () {
	local ALIAS_VAL=$(alias ${1} | cut -d '=' -f2)
	ALIAS_VAL=$(e $ALIAS_VAL | sed -e "s/[\'\"]//g")
	echo $ALIAS_VAL
}
alias_value () {
	(( $+aliases[$1] )) && echo $aliases[$1]
}
aliasesStartingWith () {
	LETTER="$1"
	alias | grep --color=auto -e "^$LETTER"
}
all-commands () {
	local COUNT=0
	for i in $(list_path)
	do
		farbex COLOR_LightRed "🤡➯➱⋙⫸PATH-Folder:"
		farbex Yellow" $i"
		farbex Green "࿕ ࿗ ࿖ ࿘"
		farbex NC n
		for cmd in $(ls -1 $i)
		do
			if [[ -x "${i}/${cmd}" ]] && [[ -f "${i}/${cmd}" ]]
			then
				COUNT=$(($COUNT+1))
				farbex Yellow "☪️- ☪︎ ------- 🤜 ${COUNT} 🤛🏼 ⭐︎☽ -------------------" n
				farbex Red "$cmd" n
				WHICHRES=$(which -a "$cmd")
				farbex LightPurple $WHICHRES n
				echo '-------------------------------------'
			fi
		done
	done
}
all_commands () {
	for i in $(list_path)
	do
		echo "==> $i <=="
		ls -G -1l $i
	done
}
allcommands () {
	for i in $(list_path)
	do
		echo "==> $i <=="
		for cmd in $(ls -1 $i)
		do
			echo "$cmd"
			isDebug && echo "$i/$cmd"
		done
	done
}
allcommands-pager () {
	local COUNT=0
	for i in $(list_path)
	do
		echo "PATH-Folder: $i"
		for cmd in $(ls -1 $i)
		do
			if [[ -x "${i}/${cmd}" ]]
			then
				COUNT=$(($COUNT+1))
				echo "----------${COUNT}-----------------------"
				echo "$cmd"
				which -a "$cmd"
				echo '-------------------------------------'
			fi
		done
	done | /usr/share/vim/vim81/macros/less.sh
}
alldoc () {
	fmp_helperx () {
		echo "$@"
	}
	for fname in "$@"
	do
		fmp_helperx "$fname"
	done
	fmp_helper () {
		echo "$@"
	}
}
androiddoc () {
	open "http://android-docs.local/$1"
}
arr4output () {
	ARRNAME="${1}"
	ARRVALUE="${2}"
	CMD="${ARRNAME}=( \$(${ARRVALUE}) )"
	IFS=$DELIMITER_ENDL
	eval "${CMD}"
}
arrrgh () {
	echo "what"
}
backward-extend-paste () {
	emulate -L zsh
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
	REGION_ACTIVE=$bep_region
}
bashcompinit () {
	# undefined
	builtin autoload -XUz
}
blue () {
	echo "${COLOR_Blue}${1}${W}"
}
br () {
	local cmd cmd_file code
	cmd_file=$(mktemp)
	if broot --outcmd "$cmd_file" "$@"
	then
		cmd=$(<"$cmd_file")
		rm -i -f "$cmd_file"
		eval "$cmd"
	else
		code=$?
		rm -i -f "$cmd_file"
		return "$code"
	fi
}
bracketed-paste-magic () {
	if [[ "$LASTWIDGET" = *vi-set-buffer ]]
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
	zle -U - $PASTED$'\e[201~'
	zle .bracketed-paste -- "$@"
	zle .split-undo
	if [[ -z $zle_highlight || -n ${(M)zle_highlight:#paste:*} ]]
	then
		zle -R
		zle .read-command && zle -U - $KEYS
	fi
}
build_prompt () {
	RETVAL=$?
	prompt_status
	prompt_virtualenv
	prompt_aws
	prompt_context
	prompt_dir
	prompt_git
	prompt_bzr
	prompt_hg
	prompt_end
}
bzr_prompt_info () {
	BZR_CB=`bzr nick 2> /dev/null | grep -v "ERROR" | cut -d ":" -f2 | awk -F / '{print "bzr::"$1}'`
	if [ -n "$BZR_CB" ]
	then
		BZR_DIRTY=""
		[[ -n `bzr status` ]] && BZR_DIRTY=" %{$fg[red]%} * %{$fg[green]%}"
		echo "$ZSH_THEME_SCM_PROMPT_PREFIX$BZR_CB$BZR_DIRTY$ZSH_THEME_GIT_PROMPT_SUFFIX"
	fi
}
callfunction () {
	$1 $2
}
capitalcase () {
	echo -n $(uppercase ${1[1]})
	lowercase "${1[2,$#1]}"
}
catch () {
	export ex_code=$?
	(( $SAVED_OPT_E )) && set +e
	return $ex_code
}
cheat () {
	open http://borkware.com/quickies/one?topic=$1
}
checkfile () {
	if [ $# -eq 2 ]
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
	done
}
chhE () {
	CMD='history | grep -i -E "[^a-zA-Z0-9_]{1}'$1'[^a-zA-Z0-9_]{1}"'
	echo $CMD
	eval $CMD
}
chhEE () {
	local OPT
	local SEARCHTERM
	[[ $# -gt 1 ]] && startsWithDash ${1} && {
		OPT=${1}  && SEARCHTERM=${2}
	} || SEARCHTERM=${1}
	CMD='history | grep '${OPT}' -E "[^a-zA-Z0-9_]{1}'${SEARCHTERM}'[^a-zA-Z0-9_]{1}"'
	echo $CMD
	eval $CMD
}
chhEEtest () {
	local OPT
	local SEARCHTERM
	[[ $# -gt 1 ]] && startsWithDash ${1} && {
		OPT=${1}  && SEARCHTERM=${2}
	} || SEARCHTERM=${1}
	CMD='history | grep '${OPT}' -E "[^a-zA-Z0-9_]{1}'${SEARCHTERM}'[^a-zA-Z0-9_]{1}"'
	echo $CMD
	eval $CMD
}
chh_sed_e () {
	omz_history -E | grep --color=auto --color=auto -i "${1}" | sed -E "s/${REGEX_NO_HIST_DATETIME}//g"
}
chparam () {
	chparam2 () {
		echo "$@"
	}
	for fname in "$@"
	do
		chparam2 "$fname"
	done
}
chparam_a () {
	echo "$@"
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
	done
}
chpwd_update_git_vars () {
	update_current_git_vars
}
chruby_prompt_info () {
	return 1
}
clipcopy () {
	emulate -L zsh
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
	fi
}
clippaste () {
	emulate -L zsh
	if [[ $OSTYPE == darwin* ]]
	then
		pbpaste | tee -a ${FILE_PBPASTE_CONTENT} && echo "" >> ${FILE_PBPASTE_CONTENT}
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
	fi
}
colormap () {
	for i in {0..255}
	do
		print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}
	done
}
colors () {
	emulate -L zsh
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
	local lc=$'\e[' rc=m
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
	done
}
compaudit () {
	# undefined
	builtin autoload -XUz
}
compdef () {
	local opt autol type func delete eval new i ret=0 cmd svc
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
						bindkey "$3" | IFS=$' \t' read -A opt
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
						bindkey "$i" | IFS=$' \t' read -A opt
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
	fi
}
compdump () {
	# undefined
	builtin autoload -XUz
}
compgen () {
	local opts prefix suffix job OPTARG OPTIND ret=1
	local -a name res results jids
	local -A shortopts
	emulate -L sh
	setopt kshglob noshglob braceexpand nokshautoload
	shortopts=(a alias b builtin c command d directory e export f file g group j job k keyword u user v variable)
	while getopts "o:A:G:C:F:P:S:W:X:abcdefgjkuv" name
	do
		case $name in
			([abcdefgjkuv]) OPTARG="${shortopts[$name]}"  ;&
			(A) case $OPTARG in
					(alias) results+=("${(k)aliases[@]}")  ;;
					(arrayvar) results+=("${(k@)parameters[(R)array*]}")  ;;
					(binding) results+=("${(k)widgets[@]}")  ;;
					(builtin) results+=("${(k)builtins[@]}" "${(k)dis_builtins[@]}")  ;;
					(command) results+=("${(k)commands[@]}" "${(k)aliases[@]}" "${(k)builtins[@]}" "${(k)functions[@]}" "${(k)reswords[@]}")  ;;
					(directory) setopt bareglobqual
						results+=(${IPREFIX}${PREFIX}*${SUFFIX}${ISUFFIX}(N-/))
						setopt nobareglobqual ;;
					(disabled) results+=("${(k)dis_builtins[@]}")  ;;
					(enabled) results+=("${(k)builtins[@]}")  ;;
					(export) results+=("${(k)parameters[(R)*export*]}")  ;;
					(file) setopt bareglobqual
						results+=(${IPREFIX}${PREFIX}*${SUFFIX}${ISUFFIX}(N))
						setopt nobareglobqual ;;
					(function) results+=("${(k)functions[@]}")  ;;
					(group) emulate zsh
						_groups -U -O res
						emulate sh
						setopt kshglob noshglob braceexpand
						results+=("${res[@]}")  ;;
					(hostname) emulate zsh
						_hosts -U -O res
						emulate sh
						setopt kshglob noshglob braceexpand
						results+=("${res[@]}")  ;;
					(job) results+=("${savejobtexts[@]%% *}")  ;;
					(keyword) results+=("${(k)reswords[@]}")  ;;
					(running) jids=("${(@k)savejobstates[(R)running*]}")
						for job in "${jids[@]}"
						do
							results+=(${savejobtexts[$job]%% *})
						done ;;
					(stopped) jids=("${(@k)savejobstates[(R)suspended*]}")
						for job in "${jids[@]}"
						do
							results+=(${savejobtexts[$job]%% *})
						done ;;
					(setopt | shopt) results+=("${(k)options[@]}")  ;;
					(signal) results+=("SIG${^signals[@]}")  ;;
					(user) results+=("${(k)userdirs[@]}")  ;;
					(variable) results+=("${(k)parameters[@]}")  ;;
					(helptopic)  ;;
				esac ;;
			(F) COMPREPLY=()
				local -a args
				args=("${words[0]}" "${@[-1]}" "${words[CURRENT-2]}")
				() {
					typeset -h words
					$OPTARG "${args[@]}"
				}
				results+=("${COMPREPLY[@]}")  ;;
			(G) setopt nullglob
				results+=(${~OPTARG})
				unsetopt nullglob ;;
			(W) results+=(${(Q)~=OPTARG})  ;;
			(C) results+=($(eval $OPTARG))  ;;
			(P) prefix="$OPTARG"  ;;
			(S) suffix="$OPTARG"  ;;
			(X) if [[ ${OPTARG[0]} = '!' ]]
				then
					results=("${(M)results[@]:#${OPTARG#?}}")
				else
					results=("${results[@]:#$OPTARG}")
				fi ;;
		esac
	done
	print -l -r -- "$prefix${^results[@]}$suffix"
}
compinit () {
	# undefined
	builtin autoload -XUz
}
compinstall () {
	# undefined
	builtin autoload -XUz
}
complete () {
	emulate -L zsh
	local args void cmd print remove
	args=("$@")
	zparseopts -D -a void o: A: G: W: C: F: P: S: X: a b c d e f g j k u v p=print r=remove
	if [[ -n $print ]]
	then
		printf 'complete %2$s %1$s\n' "${(@kv)_comps[(R)_bash*]#* }"
	elif [[ -n $remove ]]
	then
		for cmd
		do
			unset "_comps[$cmd]"
		done
	else
		compdef _bash_complete\ ${(j. .)${(q)args[1,-1-$#]}} "$@"
	fi
}
conda () {
	\local cmd="${1-__missing__}"
	case "$cmd" in
		(activate | deactivate) __conda_activate "$@" ;;
		(install | update | upgrade | remove | uninstall) __conda_exe "$@" || \return
			__conda_reactivate ;;
		(*) __conda_exe "$@" ;;
	esac
}
countchar () {
	echo "$1" | wc -c
}
createTOC-Video () {
	IFS=$DELIMITER_ENDL
	for i in $(ls -G -1 ./**/*.(mp4|mkv|webm|mov))
	do
		TMP_ROW="EXT-Movies,$(dirname $i),$(basename $i)"
		echo $TMP_ROW | tee -a TOC-Tabelle2.csv
	done
}
current_branch () {
	git_current_branch
}
cyan () {
	echo "${COLOR_Cyan}${1}${W}"
}
d () {
	if [[ -n $1 ]]
	then
		dirs "$@"
	else
		dirs -v | head -10
	fi
}
dckrh () {
	COMMAND="$1"
	docker $COMMAND --help
}
dealias () {
	local BACKUP_ALIAS_VAL=$(alias-value ${1})
	builtin unalias ${1}
	alias pre-${1}=$BACKUP_ALIAS_VAL
}
debug () {
	echo -n "DEBUGGING is "
	if isDebug
	then
		echo "on"
	else
		echo "off"
	fi
}
default () {
	(( $+parameters[$1] )) && return 0
	typeset -g "$1"="$2" && return 3
}
die () {
	yell "$*"
	exit 111
}
display_n-lines-from-m () {
	M=0
	N=10
	[[ -n $1 ]] && isNumber $1 && M=$1  || FILEPATH="${1}"
	echo "\tM=$M\tN=$N\tFILEPATH=$FILEPATH"
	[[ -n $2 ]] && isNaN $1 && M=$2  || N=$2
	echo "\tM=$M\tN=$N\tFILEPATH=$FILEPATH"
	[[ -n $3 ]] && N=$3
	echo "\tM=$M\tN=$N\tFILEPATH=$FILEPATH"
	return 100
	if [[ -z $FILEPATH ]]
	then
		while read -r line
		do
			echo ">> ${line}" | tail -n $(($CNTLNS-$M)) | head -n $N
		done
	else
		tail -n $(($CNTLNS-$M)) "${FILEPATH}" | head -n $N
	fi
}
do-chess () {
	doline1 () {
		for i in {1..4}
		do
			echo -n "$(ekko '   ' 015 010)$(ekko '   ' 000 010)"
		done
	}
	doline2 () {
		for i in {1..4}
		do
			echo -n "$(ekko '   ' 000 010)$(ekko '   ' 015 010)"
		done
	}
	FLOP=1
	for i in {1..8}
	do
		[[ $FLOP -eq 1 ]] && doline1 || doline2
		echo
		FLOP=$(($FLOP*-1))
	done
}
do-chess2 () {
	doline1 () {
		for i in {1..4}
		do
			echo -n "$(ekko '   ' 015 010)$(ekko '   ' 000 010)"
		done
	}
	doline2 () {
		for i in {1..4}
		do
			echo -n "$(ekko '   ' 000 010)$(ekko '   ' 015 010)"
		done
	}
	FLOP=1
	COUNT=1
	for i in {1..8}
	do
		echo -n " $i "
		[[ $FLOP -eq 1 ]] && doline1 || doline2
		echo
		FLOP=$(($FLOP*-1))
	done
	echo -n "   "
	for b in {H..A}
	do
		echo -n " $b "
	done
	echo
}
do-chess3 () {
	doline1 () {
		for i in {1..4}
		do
			echo -n "$(ekko '   ' 015 010)$(ekko '   ' 000 010)"
		done
	}
	doline2 () {
		for i in {1..4}
		do
			echo -n "$(ekko '   ' 000 010)$(ekko '   ' 015 010)"
		done
	}
	FLOP=1
	for i in {8..1}
	do
		echo -n " $i "
		[[ $FLOP -eq 1 ]] && doline1 || doline2
		echo
		FLOP=$(($FLOP*-1))
	done
	echo -n "   "
	for b in {A..H}
	do
		echo -n " $b "
	done
	echo
}
down-line-or-beginning-search () {
	emulate -L zsh
	typeset -g __searching __savecursor
	if [[ ${+NUMERIC} -eq 0 && ( $LASTWIDGET = $__searching || $RBUFFER != *$'\n'* ) ]]
	then
		[[ $LASTWIDGET = $__searching ]] && CURSOR=$__savecursor
		__searching=$WIDGET
		__savecursor=$CURSOR
		if zle .history-beginning-search-forward
		then
			[[ $RBUFFER = *$'\n'* ]] || zstyle -T ':zle:down-line-or-beginning-search' leave-cursor && zle .end-of-line
			return
		fi
		[[ $RBUFFER = *$'\n'* ]] || return
	fi
	__searching=''
	zle .down-line-or-history
}
download-all-img-from-url () {
	for line in $(get-tag-attr-value-of-url "${1}" img src true)
	do
		curl https://$(gethostname ${1})/${line[1,$#line-1]//src=\"/} -O
	done
}
dying () {
	echo "cannot $*"
	sleep 1
	die "$*"
}
edit-command-line () {
	# undefined
	builtin autoload -XU
}
ekko () {
	PTEXT="${1}"
	COLORBG=${2}
	COLORFG=${3}
	XX="$BG[$COLORBG]$FG[$COLORFG]${PTEXT}%{$reset_color%}"
	print -P $XX
}
endsWith () {
	usage "$0" "$#" 2 '<HAYSSTACK> <NEEDLE>' "checks if haystack ends with needle" || return $?
	HAYSSTACK="$1"
	NEEDLE="$2"
	isDebug && echo "HAYSSTACK = $HAYSSTACK"
	isDebug && echo "NEEDLE = $NEEDLE"
	[[ "$HAYSSTACK" = *"$NEEDLE" ]] && return 0 || return 1
}
env_default () {
	(( ${${(@f):-$(typeset +xg)}[(I)$1]} )) && return 0
	export "$1=$2" && return 3
}
exists () {
	[[ -n "$1" ]] && return 0 || return 1
}
extractImages () {
	cp -i *.imageset/*.$1 $2
}
exx () {
	eval "export $1=$2"
}
f () {
	touch "/var/log/find/$1.log"
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
	done
}
f-Black () {
	CNTNT="${1}"
	farbe Black $CNTNT
}
f-Blue () {
	CNTNT="${1}"
	farbe Blue $CNTNT
}
f-BrownOrange () {
	CNTNT="${1}"
	farbe BrownOrange $CNTNT
}
f-Cyan () {
	CNTNT="${1}"
	farbe Cyan $CNTNT
}
f-DarkGray () {
	CNTNT="${1}"
	farbe DarkGray $CNTNT
}
f-Green () {
	CNTNT="${1}"
	farbe Green $CNTNT
}
f-LightBlue () {
	CNTNT="${1}"
	farbe LightBlue $CNTNT
}
f-LightCyan () {
	CNTNT="${1}"
	farbe LightCyan $CNTNT
}
f-LightGray () {
	CNTNT="${1}"
	farbe LightGray $CNTNT
}
f-LightGreen () {
	CNTNT="${1}"
	farbe LightGreen $CNTNT
}
f-LightPurple () {
	CNTNT="${1}"
	farbe LightPurple $CNTNT
}
f-LightRed () {
	CNTNT="${1}"
	farbe LightRed $CNTNT
}
f-NC () {
	CNTNT="${1}"
	farbe NC $CNTNT
}
f-Purple () {
	CNTNT="${1}"
	farbe Purple $CNTNT
}
f-Red () {
	CNTNT="${1}"
	farbe Red $CNTNT
}
f-White () {
	CNTNT="${1}"
	farbe White $CNTNT
}
f-Yellow () {
	CNTNT="${1}"
	farbe Yellow $CNTNT
}
farbe () {
	OPT="n"
	echo -${OPT} "$(eval echo\ \$COLOR_${1})${2}"
}
farbex () {
	OPT='-n'
	[[ $3 == "n" ]] && OPT=''
	echo ${OPT} "$(eval echo\ \$COLOR_${1})${2}"
}
fatal () {
	echo -e "\\033[1;31m[FATAL]\\033[0m  $*"
	echo "shell is about to get closed."
	echo "Exiting in 3 seconds"
	echo "CTRL-C to interrupt exiting"
	sleep 3
	exit 1
}
ffirst () {
	[ -n "$2" ] && H="h"  || H=''
	OPTIONS="-l${H}FAiGctd"
	ls -G $OPTIONS * | head -n "$1"
}
find_aliasi_by_whole_word () {
	CMD="alias | grep -i \\\'\\\b$1\\\b\\\'"
	echo $CMD
	CMD="alias | grep -i '\b$1\b'"
	echo "$CMD"
	$(echo $CMD)
}
first () {
	LINECOUNT=5
	WHERE=$PWD
	H=''
	if [ -n "$1" ]
	then
		PARAM1="$1"
		startsWithDash $PARAM1 && H=$PARAM1[2]  || LINECOUNT=$PARAM1
	fi
	if [ -n "$2" ]
	then
		PARAM2="$2"
		startsWithDash $PARAM2 && H=$PARAM2[2]  || WHERE=$PARAM2
	fi
	if [ -n "$2" ]
	then
		PARAM3="$3"
		startsWithDash $PARAM3 && H=$PARAM3[2]  || H="h"
	fi
	if isDebug
	then
		echo $LINECOUNT
		echo $WHERE
	fi
	[[ -L $WHERE ]] && ! endsWith $WHERE '/' && WHERE="${WHERE}/"
	isDebug && {
		echo "\$WHERE=${WHERE}"
		echo "\$LINECOUNT=${LINECOUNT}"
	}
	CMD="ls -l${H}FAGct \"$WHERE\" | head -n $(($LINECOUNT+1))"
	isDebug && echo ${CMD}
	eval ${CMD}
}
first2arr () {
	LINECOUNT=5
	WHERE=$PWD
	CORRECTION4LISTOUTPUT=0
	H=''
	if [ -n "$1" ]
	then
		PARAM1="$1"
		startsWithDash $PARAM1 && H=$PARAM1[2]  || LINECOUNT=$PARAM1
	fi
	if [ -n "$2" ]
	then
		PARAM2="$2"
		startsWithDash $PARAM2 && H=$PARAM2[2]  || WHERE=$PARAM2
	fi
	if [ -n "$2" ]
	then
		PARAM3="$3"
		startsWithDash $PARAM3 && H=$PARAM3[2,-1]  || H="h"
	fi
	if isDebugLocal
	then
		echo $LINECOUNT
		echo $WHERE
		echo "${PARAM3} : $PARAM3[2,-1]"
	fi
	[[ -L $WHERE ]] && ! endsWith $WHERE '/' && WHERE="${WHERE}/"
	isDebugLocal && {
		echo "\$WHERE=${WHERE}"
		echo "\$LINECOUNT=${LINECOUNT}"
	}
	string_contains ${H} "l" && CORRECTION4LISTOUTPUT=1
	CMD="ls -${H}FAGct \"$WHERE\" | head -n $(($LINECOUNT+${CORRECTION4LISTOUTPUT}))"
	isDebugLocal && echo ${CMD}
	IFS=$DELIMITER_ENDL
	export ARR_FILES=($(eval ${CMD}))
	for f in ${ARR_FILES}
	do
		echo "${f}"
	done
	IFS=$IFS_ORIG
}
fmp () {
	fmp2 () {
		nautilus "$@"
	}
	for fname in "$@"
	do
		fmp2 "$fname"
	done
}
foocyan () {
	echo "${COLOR_Cyan}${1}${W}"
}
fp () {
	SP='./'
	if isDebug
	then
		echo "Parameters: ${#} arguments"
	fi
	PARAMCOUNT=$#
	if [ -n $2 ]
	then
		SP=$(abspath $2)
		PARAMCOUNT=3
	fi
	if [[ $# -gt 2 ]]
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
	RESULT=$(find $SP $_OPTION "*$1*"  | tee -a "/var/log/find/$1.log")
	printf "${COLOR_Cyan}$RESULT"
}
fpx () {
	SP='./'
	echo "$1"
	echo "$2"
	if [[ -z $1 ]]
	then
		echo "-z $1 true"
	else
		echo "-z $1 false"
	fi
	if [[ -z $2 ]]
	then
		echo "-z $2 true"
	else
		echo "-z $2 false"
	fi
	if [[ -n $1 ]]
	then
		echo "-n $1 true"
	else
		echo "-n $1 false"
	fi
	if [[ -n $2 ]]
	then
		echo "-n $2 true"
	else
		echo "-n $2 false"
	fi
}
func_tmpdirr () {
	echo "run"
	: ${TMPDIR=/Users/sedatkilinc/tmp}
	{
		tmp=$TMPDIR
	}
}
function_exists () {
	FUNC="$1"
	FUNC_HEAD1="${FUNC}()"
	FUNC_HEAD2="${FUNC} ()"
	[[ $(cat $BIN/.functions | grep -E "^[ ]?$FUNC_HEAD2" | wc -l) -eq 1 ]] || [[ $(cat $BIN/.functions | grep -E "^[ ]?$FUNC_HEAD1" | wc -l) -eq 1 ]] && return 0 || return 1
}
gdv () {
	git diff -w "$@" | view -
}
get-all-function-names () {
	{
		[[ -d $1 ]] && cat "${1}/"* 2> /dev/null || cat "${1}"
	} | grep --color=auto --color=auto -oE '^\S*\s{0,1}\(\)'
}
get-content-of-script-starting-and-ending-with () {
	n=$(cat  "${1}" | wc -l)
	i="."
	TMPFILE=~/tmp/.get-content-of-script-starting-and-ending-with/$(filename "${1}")
	mkdir -p $(dirname $TMPFILE)
	[[ -n $3 ]] && i="${3}"
	tail -n $(($n -$(get-line-starts-with  "$i" "${1}" ${2}) + 1)) "${1}" > $TMPFILE
	cat "$TMPFILE" | head -n $(get-line-starts-with '}' "$TMPFILE" ${2})
}
get-content-url () {
	_usage "$0" "$#" 1 "<url>" "obtains the content of the html-documents and caches the result." || return 1
	FILE_FROM_URL=$(get-temp-file-url "$1")
	isDebug && echo $FILE_FROM_URL
	[[ -f $FILE_FROM_URL ]] && cat "$FILE_FROM_URL" || curl "${1}" | tee $FILE_FROM_URL
	isDebug && echo "$FILE_FROM_URL"
}
get-functions () {
	cat "${1}" | grep --color=auto --color=auto -E "^\S*\s?\(\)"
}
get-functions-containing_name () {
	SCRIPTFILE="$BIN/.functions"
	[[ -n ${2} ]] && SCRIPTFILE="${2}"
	cat $SCRIPTFILE | grep --color=auto --color=auto --color=auto -oE "^\S*${1}\S*\s?\(\)"
}
get-launchagents () {
	SK="."
	[[ -n "${1}" ]] && SK="${1}"
	for i in ${launch[@]}
	do
		echo "$(red "==>   $i")"
		for tmp_file in $(ls -1 $i)
		do
			isDebug && echo "$i/$tmp_file" || echo "$tmp_file"
		done
	done | grep --color=auto -E "(${SK})|(==>\s{3}/(Users/sedatkilinc/)?Library/Launch.*[s]{1}.*$)"
}
get-line-starts-with () {
	CNT=1
	[[ -n $3 ]] && CNT=$3
	grep --color=auto -En '^'${1} "${2}" | head -n $CNT | tail -n 1 | cut -d ':' -f1
}
get-n-functions-of-script () {
	n=$(cat  "${1}" | wc -l)
	i=0
	tail -n $(($n - $i + 1)) "${1}" | head -n $( get-line-starts-with '}' "${1}" ${2})
}
get-number-of-functions () {
	get-functions "${1}" | wc -l
}
get-tag-attr-value-of-url () {
	_usage "$0" "$#" 3 "<url> <tag-name> <attribute-name>" "obtains the attribute value of the html-documents's concerned tags" || return 1
	IFS=$DELIMITER_ENDL
	TAG=$2
	TAG_ATTRIBUTE=$3
	[[ $# -eq 3 ]] && SZ_REGEX="<${TAG}.*>.*</${TAG}>"  || SZ_REGEX="<${TAG}.*>"
	get-content-url "${1}" | grep --color=auto --color=auto -oE "$SZ_REGEX" | sed -e "s/<${TAG}/\\${IFS}<${TAG}/g" | sed -e "s/<\/${TAG}>/<\/${TAG}>\\${IFS}/g" | grep --color=auto --color=auto -oE "${TAG_ATTRIBUTE}=\"[^ ]*\""
}
get-temp-file-url () {
	_usage "$0" "${#}" 1 "<url>" "obtains the path of an HTML-Document's tempfile by its URL" || return 1
	echo "$TARGTFOLDER/$(url2filename ${1})"
}
get-title-of-url () {
	echo $CURRENT_HTML_CONTENT curl "${1}" | grep --color=auto --color=auto -oE "<title.*>.*</title>" | sed -e 's/<[\/]*title>//g'
}
get-youtube-dl-options () {
	export YOUTUBE_DL_OPTIONS=()
	for opt in $(env | grep 'YOUTUBE_')
	do
		echo "$opt"
		YOUTUBE_DL_OPTIONS+=$opt
	done
}
getColorCode () {
	eval "$__p9k_intro"
	if (( ARGC == 1 ))
	then
		case $1 in
			(foreground) local k
				for k in "${(k@)__p9k_colors}"
				do
					local v=${__p9k_colors[$k]}
					print -rP -- "%F{$v}$v - $k%f"
				done
				return 0 ;;
			(background) local k
				for k in "${(k@)__p9k_colors}"
				do
					local v=${__p9k_colors[$k]}
					print -rP -- "%K{$v}$v - $k%k"
				done
				return 0 ;;
		esac
	fi
	echo "Usage: getColorCode background|foreground" >&2
	return 1
}
getFirstDirectory () {
	_usage "$0" "${#}" 1 "<path2folder>" "Argument missing. Path to folder. \nGet 1st directory" || return 1
	ls -G -G -l "${1}/" | grep --color=auto --color=auto -E '^d' | head -n 1 | rev | cut -d ' ' -f1 | rev
}
getInode () {
	CURRENT_INODE=$( ls -di "${1}" | cut -d ' ' -f1)
	echo $CURRENT_INODE
}
getNthDirectory () {
	_usage "$0" "${#}" 2 "<path2folder>" "Argument missing.\n 1st parameter Path to folder.\n 2nd parameter number \nGet n-th directory" || return 1
	ALLDIRS=$(ls -G -l "${1}/" | grep --color=auto --color=auto -E '^d')
	COUNTDIRS=$(echo $ALLDIRS | wc -l)
	echo $ALLDIRS | head -n $2 | tail -n 1 | rev | cut -d ' ' -f1 | rev
}
getSymlinks () {
	FOLDER='.'
	[[ -d "$1" ]] && FOLDER="$1"
	ls -G -G -lAct $FOLDER/ | grep --color=auto --color=auto -E ^l
}
get_icon_names () {
	eval "$__p9k_intro"
	_p9k_init_icons
	local key
	for key in ${(@kon)icons}
	do
		echo -n - "POWERLEVEL9K_$key: "
		print -nP "%K{red} %k"
		if [[ $1 == original ]]
		then
			echo -n - $icons[$key]
		else
			print_icon $key
		fi
		print -P "%K{red} %k"
	done
}
get_subtitle_all () {
	pVIDEO="$1"
	pFORMATS="$3"
	[[ -z $pFORMATS ]] && sub_formats=('vtt' 'srv1' 'srv2' 'srv3' 'ttml')  || sub_formats=("${pFORMATS[@]}")
	[[ -n $2 ]] && LANG=$2  || LANG="de"
	string_contains $pVIDEO "youtube" && URL="$pVIDEO"  || URL="https://www.youtube.com/watch\?v\=$pVIDEO"
	for f in $sub_formats
	do
		CMD="youtube-dl --skip-download --write-auto-sub --no-check-certificate --sub-lang $LANG --sub-format $f https://www.youtube.com/watch\?v\=$1"
		if isDebug
		then
			echo ""$f
			echo $CMD
		fi
		eval $CMD
	done
}
getent () {
	if [[ $1 = hosts ]]
	then
		sed 's/#.*//' /etc/$1 | grep -w $2
	elif [[ $2 = <-> ]]
	then
		grep ":$2:[^:]*$" /etc/$1
	else
		grep "^$2:" /etc/$1
	fi
}
getlinks () {
	for i in $LINKS/**/*.webloc
	do
		farbe Green "$i"
		farbe NC "\n"
		TMPLINK=$(getlink $i)
		string_contains $TMPLINK 'xmlversion' && farbe Yellow $(getlink-wl $i) || farbe Purple $TMPLINK
		farbe NC "\n"
	done
}
ggf () {
	[[ "$#" != 1 ]] && local b="$(git_current_branch)"
	git push --force origin "${b:=$1}"
}
ggfl () {
	[[ "$#" != 1 ]] && local b="$(git_current_branch)"
	git push --force-with-lease origin "${b:=$1}"
}
ggl () {
	if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]
	then
		git pull origin "${*}"
	else
		[[ "$#" == 0 ]] && local b="$(git_current_branch)"
		git pull origin "${b:=$1}"
	fi
}
ggp () {
	if [[ "$#" != 0 ]] && [[ "$#" != 1 ]]
	then
		git push origin "${*}"
	else
		[[ "$#" == 0 ]] && local b="$(git_current_branch)"
		git push origin "${b:=$1}"
	fi
}
ggpnp () {
	if [[ "$#" == 0 ]]
	then
		ggl && ggp
	else
		ggl "${*}" && ggp "${*}"
	fi
}
ggu () {
	[[ "$#" != 1 ]] && local b="$(git_current_branch)"
	git pull --rebase origin "${b:=$1}"
}
git_commits_ahead () {
	if command git rev-parse --git-dir &> /dev/null
	then
		local commits="$(git rev-list --count @{upstream}..HEAD 2>/dev/null)"
		if [[ -n "$commits" && "$commits" != 0 ]]
		then
			echo "$ZSH_THEME_GIT_COMMITS_AHEAD_PREFIX$commits$ZSH_THEME_GIT_COMMITS_AHEAD_SUFFIX"
		fi
	fi
}
git_commits_behind () {
	if command git rev-parse --git-dir &> /dev/null
	then
		local commits="$(git rev-list --count HEAD..@{upstream} 2>/dev/null)"
		if [[ -n "$commits" && "$commits" != 0 ]]
		then
			echo "$ZSH_THEME_GIT_COMMITS_BEHIND_PREFIX$commits$ZSH_THEME_GIT_COMMITS_BEHIND_SUFFIX"
		fi
	fi
}
git_current_branch () {
	local ref
	ref=$(command git symbolic-ref --quiet HEAD 2> /dev/null)
	local ret=$?
	if [[ $ret != 0 ]]
	then
		[[ $ret == 128 ]] && return
		ref=$(command git rev-parse --short HEAD 2> /dev/null)  || return
	fi
	echo ${ref#refs/heads/}
}
git_current_user_email () {
	command git config user.email 2> /dev/null
}
git_current_user_name () {
	command git config user.name 2> /dev/null
}
git_prompt_ahead () {
	if [[ -n "$(command git rev-list origin/$(git_current_branch)..HEAD 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_AHEAD"
	fi
}
git_prompt_behind () {
	if [[ -n "$(command git rev-list HEAD..origin/$(git_current_branch) 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_BEHIND"
	fi
}
git_prompt_info () {
	local ref
	if [[ "$(command git config --get oh-my-zsh.hide-status 2>/dev/null)" != "1" ]]
	then
		ref=$(command git symbolic-ref HEAD 2> /dev/null)  || ref=$(command git rev-parse --short HEAD 2> /dev/null)  || return 0
		echo "$ZSH_THEME_GIT_PROMPT_PREFIX${ref#refs/heads/}$(parse_git_dirty)$ZSH_THEME_GIT_PROMPT_SUFFIX"
	fi
}
git_prompt_long_sha () {
	local SHA
	SHA=$(command git rev-parse HEAD 2> /dev/null)  && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER"
}
git_prompt_remote () {
	if [[ -n "$(command git show-ref origin/$(git_current_branch) 2> /dev/null)" ]]
	then
		echo "$ZSH_THEME_GIT_PROMPT_REMOTE_EXISTS"
	else
		echo "$ZSH_THEME_GIT_PROMPT_REMOTE_MISSING"
	fi
}
git_prompt_short_sha () {
	local SHA
	SHA=$(command git rev-parse --short HEAD 2> /dev/null)  && echo "$ZSH_THEME_GIT_PROMPT_SHA_BEFORE$SHA$ZSH_THEME_GIT_PROMPT_SHA_AFTER"
}
git_prompt_status () {
	local INDEX STATUS
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
	echo $STATUS
}
git_remote_status () {
	local remote ahead behind git_remote_status git_remote_status_detailed
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
	fi
}
git_sparse_clone () {
	rurl="$1"
	localdir="$2"  && shift 2
	mkdir -p "$localdir"
	cd "$localdir"
	git init
	git remote add -f origin "$rurl"
	git config core.sparseCheckout true
	for i
	do
		echo "$i" >> .git/info/sparse-checkout
	done
	git pull origin master
}
git_super_status () {
	precmd_update_git_vars
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
	fi
}
gitstatus_check_p9k_ () {
	emulate -L zsh -o no_aliases -o extended_glob -o typeset_silent
	local fsuf=${${(%):-%N}#gitstatus_check}
	if (( ARGC != 1 ))
	then
		print -ru2 -- "gitstatus_check: exactly one positional argument is required"
		return 1
	fi
	local name=$1
	if [[ $name != [[:IDENT:]]## ]]
	then
		print -ru2 -- "gitstatus_check: invalid positional argument: $name"
		return 1
	fi
	(( _GITSTATUS_STATE_$name == 2 ))
}
gitstatus_process_results_p9k_ () {
	emulate -L zsh -o no_aliases -o extended_glob -o typeset_silent
	local fsuf=${${(%):-%N}#gitstatus_process_results}
	local opt OPTARG
	local -i OPTIND
	local -F timeout=-1
	while getopts ":t:" opt
	do
		case $opt in
			(t) if [[ $OPTARG != (|+|-)<->(|.<->)(|[eE](|-|+)<->) ]]
				then
					print -ru2 -- "gitstatus_process_results: invalid -t argument: $OPTARG"
					return 1
				fi
				timeout=OPTARG  ;;
			(\?) print -ru2 -- "gitstatus_process_results: invalid option: $OPTARG"
				return 1 ;;
			(:) print -ru2 -- "gitstatus_process_results: missing required argument: $OPTARG"
				return 1 ;;
			(*) print -ru2 -- "gitstatus_process_results: invalid option: $opt"
				return 1 ;;
		esac
	done
	if (( OPTIND != ARGC ))
	then
		print -ru2 -- "gitstatus_process_results: exactly one positional argument is required"
		return 1
	fi
	local name=$*[OPTIND]
	if [[ $name != [[:IDENT:]]## ]]
	then
		print -ru2 -- "gitstatus_process_results: invalid positional argument: $name"
		return 1
	fi
	(( _GITSTATUS_STATE_$name == 2 )) || return
	while (( _GITSTATUS_NUM_INFLIGHT_$name ))
	do
		_gitstatus_process_response$fsuf $name $timeout '' || return
		[[ $VCS_STATUS_RESULT == *-async ]] || break
	done
	return 0
}
gitstatus_query_p9k_ () {
	emulate -L zsh -o no_aliases -o extended_glob -o typeset_silent
	local fsuf=${${(%):-%N}#gitstatus_query}
	unset VCS_STATUS_RESULT
	local opt dir callback OPTARG
	local -i no_diff OPTIND
	local -F timeout=-1
	while getopts ":d:c:t:p" opt
	do
		case $opt in
			(+p) no_diff=0  ;;
			(p) no_diff=1  ;;
			(d) dir=$OPTARG  ;;
			(c) callback=$OPTARG  ;;
			(t) if [[ $OPTARG != (|+|-)<->(|.<->)(|[eE](|-|+)<->) ]]
				then
					print -ru2 -- "gitstatus_query: invalid -t argument: $OPTARG"
					return 1
				fi
				timeout=OPTARG  ;;
			(\?) print -ru2 -- "gitstatus_query: invalid option: $OPTARG"
				return 1 ;;
			(:) print -ru2 -- "gitstatus_query: missing required argument: $OPTARG"
				return 1 ;;
			(*) print -ru2 -- "gitstatus_query: invalid option: $opt"
				return 1 ;;
		esac
	done
	if (( OPTIND != ARGC ))
	then
		print -ru2 -- "gitstatus_query: exactly one positional argument is required"
		return 1
	fi
	local name=$*[OPTIND]
	if [[ $name != [[:IDENT:]]## ]]
	then
		print -ru2 -- "gitstatus_query: invalid positional argument: $name"
		return 1
	fi
	(( _GITSTATUS_STATE_$name == 2 )) || return
	if [[ -z $GIT_DIR ]]
	then
		if [[ $dir != /* ]]
		then
			if [[ $PWD == /* && $PWD -ef . ]]
			then
				dir=$PWD/$dir
			else
				dir=${dir:a}
			fi
		fi
	else
		if [[ $GIT_DIR == /* ]]
		then
			dir=:$GIT_DIR
		elif [[ $PWD == /* && $PWD -ef . ]]
		then
			dir=:$PWD/$GIT_DIR
		else
			dir=:${GIT_DIR:a}
		fi
	fi
	if [[ $dir != (|:)/* ]]
	then
		typeset -g VCS_STATUS_RESULT=norepo-sync
		_gitstatus_clear$fsuf
		return 0
	fi
	local -i req_fd=${(P)${:-_GITSTATUS_REQ_FD_$name}}
	local req_id=$EPOCHREALTIME
	print -rnu $req_fd -- $req_id' '$callback$'\x1f'$dir$'\x1f'$no_diff$'\x1e' || return
	(( ++_GITSTATUS_NUM_INFLIGHT_$name ))
	if (( timeout == 0 ))
	then
		typeset -g VCS_STATUS_RESULT=tout
		_gitstatus_clear$fsuf
	else
		while true
		do
			_gitstatus_process_response$fsuf $name $timeout $req_id || return
			[[ $VCS_STATUS_RESULT == *-async ]] || break
		done
	fi
	[[ $VCS_STATUS_RESULT != tout || -n $callback ]]
}
gitstatus_start_p9k_ () {
	emulate -L zsh -o no_aliases -o no_bg_nice -o extended_glob -o typeset_silent || return
	print -rnu2 || return
	local fsuf=${${(%):-%N}#gitstatus_start}
	local opt OPTARG
	local -i OPTIND
	local -F timeout=5
	local -i async=0
	local -a args=()
	local -i dirty_max_index_size=-1
	while getopts ":t:s:u:c:d:m:eaUWD" opt
	do
		case $opt in
			(a) async=1  ;;
			(+a) async=0  ;;
			(t) if [[ $OPTARG != (|+)<->(|.<->)(|[eE](|-|+)<->) ]] || (( ${timeout::=OPTARG} <= 0 ))
				then
					print -ru2 -- "gitstatus_start: invalid -t argument: $OPTARG"
					return 1
				fi ;;
			(s | u | c | d | m) if [[ $OPTARG != (|-|+)<-> ]]
				then
					print -ru2 -- "gitstatus_start: invalid -$opt argument: $OPTARG"
					return 1
				fi
				args+=(-$opt $OPTARG)
				[[ $opt == m ]] && dirty_max_index_size=OPTARG  ;;
			(e | U | W | D) args+=-$opt  ;;
			(+(e|U|W|D)) args=(${(@)args:#-$opt})  ;;
			(\?) print -ru2 -- "gitstatus_start: invalid option: $OPTARG"
				return 1 ;;
			(:) print -ru2 -- "gitstatus_start: missing required argument: $OPTARG"
				return 1 ;;
			(*) print -ru2 -- "gitstatus_start: invalid option: $opt"
				return 1 ;;
		esac
	done
	if (( OPTIND != ARGC ))
	then
		print -ru2 -- "gitstatus_start: exactly one positional argument is required"
		return 1
	fi
	local name=$*[OPTIND]
	if [[ $name != [[:IDENT:]]## ]]
	then
		print -ru2 -- "gitstatus_start: invalid positional argument: $name"
		return 1
	fi
	local -i lock_fd resp_fd stderr_fd
	local file_prefix xtrace=/dev/null daemon_log=/dev/null culprit
	{
		if (( _GITSTATUS_STATE_$name ))
		then
			(( async )) && return
			(( _GITSTATUS_STATE_$name == 2 )) && return
			lock_fd=_GITSTATUS_LOCK_FD_$name
			resp_fd=_GITSTATUS_RESP_FD_$name
			xtrace=${(P)${:-GITSTATUS_XTRACE_$name}}
			daemon_log=${(P)${:-GITSTATUS_DAEMON_LOG_$name}}
			file_prefix=${(P)${:-_GITSTATUS_FILE_PREFIX_$name}}
		else
			typeset -gi _GITSTATUS_START_COUNTER
			local log_level=$GITSTATUS_LOG_LEVEL
			if [[ -n "$TMPDIR" && ( ( -d "$TMPDIR" && -w "$TMPDIR" ) || ! ( -d /tmp && -w /tmp ) ) ]]
			then
				local tmpdir=$TMPDIR
			else
				local tmpdir=/tmp
			fi
			local file_prefix=${tmpdir:A}/gitstatus.$name.$EUID
			file_prefix+=.$sysparams[pid].$EPOCHSECONDS.$((++_GITSTATUS_START_COUNTER))
			(( GITSTATUS_ENABLE_LOGGING )) && : ${log_level:=INFO}
			if [[ -n $log_level ]]
			then
				xtrace=$file_prefix.xtrace.log
				daemon_log=$file_prefix.daemon.log
			fi
			args+=(-v ${log_level:-FATAL})
			typeset -g GITSTATUS_XTRACE_$name=$xtrace
			typeset -g GITSTATUS_DAEMON_LOG_$name=$daemon_log
			typeset -g _GITSTATUS_FILE_PREFIX_$name=$file_prefix
			typeset -gi _GITSTATUS_CLIENT_PID_$name="sysparams[pid]"
			typeset -gi _GITSTATUS_DIRTY_MAX_INDEX_SIZE_$name=dirty_max_index_size
		fi
		() {
			if [[ $xtrace != /dev/null && -o no_xtrace ]]
			then
				exec {stderr_fd}>&2 || return
				exec 2>> $xtrace || return
				setopt xtrace
			fi
			setopt monitor || return
			if (( ! _GITSTATUS_STATE_$name ))
			then
				if [[ -r /proc/version && "$(</proc/version)" == *Microsoft* ]]
				then
					lock_fd=-1
				else
					print -rn > $file_prefix.lock || return
					zsystem flock -f lock_fd $file_prefix.lock || return
					[[ $lock_fd == <1-> ]] || return
				fi
				typeset -gi _GITSTATUS_LOCK_FD_$name=lock_fd
				if [[ $OSTYPE == cygwin* && -d /proc/self/fd ]]
				then
					local -i fd
					exec {fd}< <(_gitstatus_daemon$fsuf) || return
					{
						[[ -r /proc/self/fd/$fd ]] || return
						sysopen -r -o cloexec -u resp_fd /proc/self/fd/$fd || return
					} always {
						exec {fd}>&- || return
					}
				else
					sysopen -r -o cloexec -u resp_fd <(_gitstatus_daemon$fsuf) || return
				fi
				typeset -gi GITSTATUS_DAEMON_PID_$name="${sysparams[procsubstpid]:--1}"
				[[ $resp_fd == <1-> ]] || return
				typeset -gi _GITSTATUS_RESP_FD_$name=resp_fd
				typeset -gi _GITSTATUS_STATE_$name=1
			fi
			if (( ! async ))
			then
				(( _GITSTATUS_CLIENT_PID_$name == sysparams[pid] )) || return
				local pgid
				while (( $#pgid < 20 ))
				do
					[[ -t $resp_fd ]]
					sysread -s $((20 - $#pgid)) -t $timeout -i $resp_fd 'pgid[$#pgid+1]' || return
				done
				[[ $pgid == ' '#<1-> ]] || return
				typeset -gi GITSTATUS_DAEMON_PID_$name=pgid
				sysopen -w -o cloexec -u req_fd -- $file_prefix.fifo || return
				[[ $req_fd == <1-> ]] || return
				typeset -gi _GITSTATUS_REQ_FD_$name=req_fd
				print -nru $req_fd -- $'}hello\x1f\x1e' || return
				local expected=$'}hello\x1f0\x1e' actual
				if (( $+functions[p10k] )) && [[ ! -t 1 && ! -t 0 ]]
				then
					local -F deadline='EPOCHREALTIME + 4'
				else
					local -F deadline='1'
				fi
				while true
				do
					[[ -t $resp_fd ]]
					sysread -s 1 -t $timeout -i $resp_fd actual || return
					[[ $expected == $actual* ]] && break
					if [[ $actual != $'\1' ]]
					then
						[[ -t $resp_fd ]]
						while sysread -t $timeout -i $resp_fd 'actual[$#actual+1]'
						do
							[[ -t $resp_fd ]]
						done
						culprit=$actual
						return 1
					fi
					(( EPOCHREALTIME < deadline )) && continue
					if (( deadline > 0 ))
					then
						deadline=0
						if (( stderr_fd ))
						then
							unsetopt xtrace
							exec 2>&$stderr_fd {stderr_fd}>&-
							stderr_fd=0
						fi
						if (( $+functions[p10k] ))
						then
							p10k clear-instant-prompt || return
						fi
						if [[ $name == POWERLEVEL9K ]]
						then
							local label=powerlevel10k
						else
							local label=gitstatus
						fi
						if [[ -t 2 ]]
						then
							local spinner=($'\b%3F-%f' $'\b%3F\\%f' $'\b%3F|%f' $'\b%3F/%f')
							print -Prnu2 -- "[%3F$label%f] fetching %2Fgitstatusd%f ..  "
						else
							local spinner=('.')
							print -rnu2 -- "[$label] fetching gitstatusd .."
						fi
					fi
					print -Prnu2 -- $spinner[1]
					spinner=($spinner[2,-1] $spinner[1])
				done
				if (( deadline == 0 ))
				then
					if [[ -t 2 ]]
					then
						print -Pru2 -- $'\b[%2Fok%f]'
					else
						print -ru2 -- ' [ok]'
					fi
					if [[ $xtrace != /dev/null && -o no_xtrace ]]
					then
						exec {stderr_fd}>&2 || return
						exec 2>> $xtrace || return
						setopt xtrace
					fi
				fi
				while (( $#actual < $#expected ))
				do
					[[ -t $resp_fd ]]
					sysread -s $(($#expected - $#actual)) -t $timeout -i $resp_fd 'actual[$#actual+1]' || return
				done
				[[ $actual == $expected ]] || return
				_gitstatus_process_response_$name-$fsuf () {
					emulate -L zsh -o no_aliases -o extended_glob -o typeset_silent
					local pair=${${(%):-%N}#_gitstatus_process_response_}
					local name=${pair%%-*}
					local fsuf=${pair#*-}
					[[ $name == POWERLEVEL9K && $fsuf == _p9k_ ]] && eval $__p9k_intro_base
					if (( ARGC == 1 ))
					then
						_gitstatus_process_response$fsuf $name 0 ''
					else
						gitstatus_stop$fsuf $name
					fi
				}
				if ! zle -F $resp_fd _gitstatus_process_response_$name-$fsuf
				then
					unfunction _gitstatus_process_response_$name-$fsuf
					return 1
				fi
				_gitstatus_cleanup_$name-$fsuf () {
					emulate -L zsh -o no_aliases -o extended_glob -o typeset_silent
					local pair=${${(%):-%N}#_gitstatus_cleanup_}
					local name=${pair%%-*}
					local fsuf=${pair#*-}
					(( _GITSTATUS_CLIENT_PID_$name == sysparams[pid] )) || return
					gitstatus_stop$fsuf $name
				}
				if ! add-zsh-hook zshexit _gitstatus_cleanup_$name-$fsuf
				then
					unfunction _gitstatus_cleanup_$name-$fsuf
					return 1
				fi
				if (( lock_fd != -1 ))
				then
					zf_rm -- $file_prefix.lock || return
					zsystem flock -u $lock_fd || return
				fi
				unset _GITSTATUS_LOCK_FD_$name
				typeset -gi _GITSTATUS_STATE_$name=2
			fi
		}
	} always {
		local -i err=$?
		(( stderr_fd )) && exec 2>&$stderr_fd {stderr_fd}>&-
		(( err == 0  )) && return
		gitstatus_stop$fsuf $name
		setopt prompt_percent no_prompt_subst no_prompt_bang
		(( $+functions[p10k] )) && p10k clear-instant-prompt
		print -ru2 -- ''
		print -Pru2 -- '[%F{red}ERROR%f]: gitstatus failed to initialize.'
		print -ru2 -- ''
		if [[ -n $culprit ]]
		then
			print -ru2 -- $culprit
			return err
		fi
		if [[ -s $xtrace ]]
		then
			print -ru2 -- ''
			print -Pru2 -- "  Zsh log (%U${xtrace//\%/%%}%u):"
			print -Pru2 -- '%F{yellow}'
			print -lru2 -- "${(@)${(@f)$(<$xtrace)}/#/    }"
			print -Pnru2 -- '%f'
		fi
		if [[ -s $daemon_log ]]
		then
			print -ru2 -- ''
			print -Pru2 -- "  Daemon log (%U${daemon_log//\%/%%}%u):"
			print -Pru2 -- '%F{yellow}'
			print -lru2 -- "${(@)${(@f)$(<$daemon_log)}/#/    }"
			print -Pnru2 -- '%f'
		fi
		if [[ $GITSTATUS_LOG_LEVEL == DEBUG ]]
		then
			print -ru2 -- ''
			print -ru2 -- '  System information:'
			print -Pru2 -- '%F{yellow}'
			print -ru2 -- "    zsh:      $ZSH_VERSION"
			print -ru2 -- "    uname -a: $(command uname -a)"
			print -Pru2 -- '%f'
			print -ru2 -- '  If you need help, open an issue and attach this whole error message to it:'
			print -ru2 -- ''
			print -Pru2 -- '    %Uhttps://github.com/romkatv/gitstatus/issues/new%u'
		else
			print -ru2 -- ''
			local home=~
			local zshrc=${${${(q)${ZDOTDIR:-~}}/#${(q)home}/'~'}//\%/%%}/.zshrc
			print -Pru2 -- "  Add the following parameter to %U$zshrc%u for extra diagnostics on error:"
			print -ru2 -- ''
			print -Pru2 -- '    %BGITSTATUS_LOG_LEVEL=DEBUG%b'
			print -ru2 -- ''
			print -ru2 -- '  Restart Zsh to retry gitstatus initialization:'
			print -ru2 -- ''
			print -Pru2 -- '    %F{green}%Uexec%u zsh%f'
		fi
	}
}
gitstatus_stop_p9k_ () {
	emulate -L zsh -o no_aliases -o extended_glob -o typeset_silent
	local fsuf=${${(%):-%N}#gitstatus_stop}
	if (( ARGC != 1 ))
	then
		print -ru2 -- "gitstatus_stop: exactly one positional argument is required"
		return 1
	fi
	local name=$1
	if [[ $name != [[:IDENT:]]## ]]
	then
		print -ru2 -- "gitstatus_stop: invalid positional argument: $name"
		return 1
	fi
	local state_var=_GITSTATUS_STATE_$name
	local req_fd_var=_GITSTATUS_REQ_FD_$name
	local resp_fd_var=_GITSTATUS_RESP_FD_$name
	local lock_fd_var=_GITSTATUS_LOCK_FD_$name
	local client_pid_var=_GITSTATUS_CLIENT_PID_$name
	local daemon_pid_var=GITSTATUS_DAEMON_PID_$name
	local inflight_var=_GITSTATUS_NUM_INFLIGHT_$name
	local file_prefix_var=_GITSTATUS_FILE_PREFIX_$name
	local dirty_max_index_size_var=_GITSTATUS_DIRTY_MAX_INDEX_SIZE_$name
	local req_fd=${(P)req_fd_var}
	local resp_fd=${(P)resp_fd_var}
	local lock_fd=${(P)lock_fd_var}
	local daemon_pid=${(P)daemon_pid_var}
	local file_prefix=${(P)file_prefix_var}
	local cleanup=_gitstatus_cleanup_$name-$fsuf
	local process=_gitstatus_process_response_$name-$fsuf
	if (( $+functions[$cleanup] ))
	then
		add-zsh-hook -d zshexit $cleanup
		unfunction -- $cleanup
	fi
	if (( $+functions[$process] ))
	then
		[[ -n $resp_fd ]] && zle -F $resp_fd
		unfunction -- $process
	fi
	[[ $daemon_pid == <1-> ]] && kill -- -$daemon_pid 2> /dev/null
	[[ $file_prefix == /* ]] && zf_rm -f -- $file_prefix.lock $file_prefix.fifo
	[[ $lock_fd == <1-> ]] && zsystem flock -u $lock_fd
	[[ $req_fd == <1-> ]] && exec {req_fd}>&-
	[[ $resp_fd == <1-> ]] && exec {resp_fd}>&-
	unset $state_var $req_fd_var $lock_fd_var $resp_fd_var $client_pid_var $daemon_pid_var
	unset $inflight_var $file_prefix_var $dirty_max_index_size_var
	unset VCS_STATUS_RESULT
	_gitstatus_clear$fsuf
}
gittut () {
	isNumeric ${1} && [[ ${1} -ge 1 ]] && [[ ${1} -le 8 ]] && man $GITTUTZ[${1}] || echo "Usage: $0 <Parameter between 1 and $#GITTUTZ>"
}
gittutz () {
	for i in {1..$#GITTUTZ}
	do
		[[ $# -gt 0 ]] && echo -n "${i}. "
		echo $GITTUTZ[$i]
	done
}
giturlp () {
	PATH2REPO='.'
	if [ $# -eq 1 ]
	then
		PATH2REPO="$@"
	fi
	cat $PATH2REPO/.git/config | grep --color=auto -i url | cut -d'=' -f 2
}
gituser () {
	PATH2REPO='.'
	if [ $# -eq 1 ]
	then
		PATH2REPO="$@"
	fi
	cat $PATH2REPO/.git/config | grep --color=auto -i email | cut -d'=' -f 2
}
gr2 () {
	PARAM=$1
	r2_it () {
		grep --color=auto -irl $PARAM "$@"
	}
	shift
	callfunction r2_it "$@"
}
green () {
	echo "${COLOR_Green}${1}${W}"
}
handle_completion_insecurities () {
	local -aU insecure_dirs
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

EOD
}
hexcount () {
	for i in {0..15}
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
	done
}
hg_prompt_info () {
	return 1
}
ignoreErrors () {
	set +e
}
inform () {
	echo -e "\\033[1;36m[INFO]\\033[0m  $*"
}
instant_prompt__p9k_internal_nothing () {
	prompt__p9k_internal_nothing
}
instant_prompt_context () {
	if [[ $_POWERLEVEL9K_ALWAYS_SHOW_CONTEXT == 0 && -n $DEFAULT_USER && $P9K_SSH == 0 ]]
	then
		if [[ ${(%):-%n} == $DEFAULT_USER ]]
		then
			if (( ! _POWERLEVEL9K_ALWAYS_SHOW_USER ))
			then
				return
			fi
		fi
	fi
	prompt_context
}
instant_prompt_date () {
	_p9k_escape $_POWERLEVEL9K_DATE_FORMAT
	local stash='${${__p9k_instant_prompt_date::=${(%)${__p9k_instant_prompt_date_format::='$_p9k__ret'}}}+}'
	_p9k_escape $_POWERLEVEL9K_DATE_FORMAT
	_p9k_prompt_segment prompt_date "$_p9k_color2" "$_p9k_color1" "DATE_ICON" 1 '' $stash$_p9k__ret
}
instant_prompt_dir () {
	prompt_dir
}
instant_prompt_dir_writable () {
	prompt_dir_writable
}
instant_prompt_direnv () {
	if [[ -n $DIRENV_DIR && $precmd_functions[-1] == _p9k_precmd ]]
	then
		_p9k_prompt_segment prompt_direnv $_p9k_color1 yellow DIRENV_ICON 0 '' ''
	fi
}
instant_prompt_example () {
	prompt_example
}
instant_prompt_host () {
	prompt_host
}
instant_prompt_midnight_commander () {
	_p9k_prompt_segment prompt_midnight_commander $_p9k_color1 yellow MIDNIGHT_COMMANDER_ICON 0 '$MC_TMPDIR' ''
}
instant_prompt_nix_shell () {
	_p9k_prompt_segment prompt_nix_shell 4 $_p9k_color1 NIX_SHELL_ICON 1 '${IN_NIX_SHELL:#0}' '${(M)IN_NIX_SHELL:#(pure|impure)}'
}
instant_prompt_nnn () {
	_p9k_prompt_segment prompt_nnn 6 $_p9k_color1 NNN_ICON 1 '${NNNLVL:#0}' '$NNNLVL'
}
instant_prompt_os_icon () {
	prompt_os_icon
}
instant_prompt_prompt_char () {
	_p9k_prompt_segment prompt_prompt_char_OK_VIINS "$_p9k_color1" 76 '' 0 '' '❯'
}
instant_prompt_ranger () {
	_p9k_prompt_segment prompt_ranger $_p9k_color1 yellow RANGER_ICON 1 '$RANGER_LEVEL' '$RANGER_LEVEL'
}
instant_prompt_root_indicator () {
	prompt_root_indicator
}
instant_prompt_ssh () {
	if (( ! P9K_SSH ))
	then
		return
	fi
	prompt_ssh
}
instant_prompt_status () {
	if (( _POWERLEVEL9K_STATUS_OK ))
	then
		_p9k_prompt_segment prompt_status_OK "$_p9k_color1" green OK_ICON 0 '' ''
	fi
}
instant_prompt_time () {
	_p9k_escape $_POWERLEVEL9K_TIME_FORMAT
	local stash='${${__p9k_instant_prompt_time::=${(%)${__p9k_instant_prompt_time_format::='$_p9k__ret'}}}+}'
	_p9k_escape $_POWERLEVEL9K_TIME_FORMAT
	_p9k_prompt_segment prompt_time "$_p9k_color2" "$_p9k_color1" "TIME_ICON" 1 '' $stash$_p9k__ret
}
instant_prompt_toolbox () {
	_p9k_prompt_segment prompt_toolbox $_p9k_color1 yellow TOOLBOX_ICON 1 '$P9K_TOOLBOX_NAME' '$P9K_TOOLBOX_NAME'
}
instant_prompt_user () {
	if [[ $_POWERLEVEL9K_ALWAYS_SHOW_USER == 0 && "${(%):-%n}" == $DEFAULT_USER ]]
	then
		return
	fi
	prompt_user
}
instant_prompt_vi_mode () {
	if [[ -n $_POWERLEVEL9K_VI_INSERT_MODE_STRING ]]
	then
		_p9k_prompt_segment prompt_vi_mode_INSERT "$_p9k_color1" blue '' 0 '' "$_POWERLEVEL9K_VI_INSERT_MODE_STRING"
	fi
}
instant_prompt_vim_shell () {
	_p9k_prompt_segment prompt_vim_shell green $_p9k_color1 VIM_ICON 0 '$VIMRUNTIME' ''
}
instant_prompt_xplr () {
	_p9k_prompt_segment prompt_xplr 6 $_p9k_color1 XPLR_ICON 0 '$XPLR_PID' ''
}
is-at-least () {
	emulate -L zsh
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
	done
}
isDebug () {
	DEBUG=$(cat $DEBUG_STATE_FILE)
	if [ "$DEBUG" -eq $TRUE ] 2> /dev/null || [ "$DEBUG" = $TRUE ]
	then
		return 0
	else
		return 1
	fi
}
isDebugLocal () {
	if [[ "$DEBUG" -eq $TRUE ]] 2> /dev/null || [[ "$DEBUG" = $TRUE ]]
	then
		return 0
	else
		return 1
	fi
}
isDir () {
	[[ -d "$1" ]]
	return $?
}
isDirectory () {
	if [ -d "$1" ]
	then
		return 0
	else
		return 1
	fi
}
isFunction1 () {
	WHICHRESULT=$(builtin which "$1")
	if isDebug
	then
		echo "1: $1"
		echo "WHICHRESULT: \n$WHICHRESULT"
		echo "wc -l = $(echo $WHICHRESULT | wc -l)"
		echo -n "greater than 1 " && [[ $(echo $WHICHRESULT | wc -l) -gt 1 ]] && echo "return 0/true" || echo "return 1/false"
		echo -n "not containing 'not found' (exists) AND greater than 1 " && ! string_contains $WHICHRESULT 'not found' && [[ $(echo $WHICHRESULT | wc -l) -gt 1 ]] && echo "return 0/true" || echo "return 1/false"
	fi
	! string_contains $WHICHRESULT 'not found' && [[ $(echo $WHICHRESULT | wc -l) -gt 1 ]] && return 0 || return 1
}
isFunction2 () {
	local result=$(builtin which "${1}" | grep -oE "^${1} \(\)")
	[[ -n $result ]] && return 0 || return 1
}
isFunction3 () {
	local result=$(functions | grep -oE "^${1} \(\)")
	[[ -n $result ]] && return 0 || return 1
}
isFunctionDefined () {
	[[ $(builtin which ${1} | wc -l) -gt 1 ]] && return 0 || return 1
}
isNaN () {
	if [ "$1" -le 0 ] 2> /dev/null || [ "$1" -gt 0 ] 2> /dev/null
	then
		return 1
	else
		return 0
	fi
}
isNumber () {
	re='^[0-9]+$'
	if ! [[ $1 =~ $re ]]
	then
		return 1
	else
		return 0
	fi
}
isNumeric () {
	if [ "$1" -eq "$1" ] 2> /dev/null
	then
		return 0
	else
		return 1
	fi
}
isText () {
	string_contains "$(file $1)" ASCII && return 0 || return 1
}
is_plugin () {
	local base_dir=$1
	local name=$2
	test -f $base_dir/plugins/$name/$name.plugin.zsh || test -f $base_dir/plugins/$name/_$name
}
iterm2_after_cmd_executes () {
	printf "\033]133;D;%s\007" "$STATUS"
	iterm2_print_state_data
}
iterm2_before_cmd_executes () {
	printf "\033]133;C;\007"
}
iterm2_decorate_prompt () {
	typeset -g ITERM2_PRECMD_PS1=$PROMPT
	typeset -g ITERM2_SHOULD_DECORATE_PROMPT=
}
iterm2_precmd () {
	local _p9k_status=$?
	zle && return
	() {
		return $_p9k_status
	}
	local STATUS="$?"
	if [ -z "${ITERM2_SHOULD_DECORATE_PROMPT-}" ]
	then
		iterm2_before_cmd_executes
	fi
	iterm2_after_cmd_executes "$STATUS"
	if [ -n "$ITERM2_SHOULD_DECORATE_PROMPT" ]
	then
		iterm2_decorate_prompt
	fi
}
iterm2_preexec () {
	PS1="$ITERM2_PRECMD_PS1"
	ITERM2_SHOULD_DECORATE_PROMPT="1"
	iterm2_before_cmd_executes
}
iterm2_print_state_data () {
	printf "\033]1337;RemoteHost=%s@%s\007" "$USER" "${iterm2_hostname-}"
	printf "\033]1337;CurrentDir=%s\007" "$PWD"
	iterm2_print_user_vars
}
iterm2_print_user_vars () {
	iterm2_set_user_var gitBranch $((git branch 2> /dev/null) | grep \* | cut -c3-)
	iterm2_set_user_var home $(echo -n "$HOME")
}
iterm2_prompt_end () {
	printf "\033]133;B\007"
}
iterm2_prompt_mark () {
	printf "\033]133;A\007"
}
iterm2_set_user_var () {
	printf "\033]1337;SetUserVar=%s=%s\007" "$1" $(printf "%s" "$2" | base64 | tr -d '\n')
}
jenv_prompt_info () {
	return 1
}
jsonKV () {
	mkdir -p $HOME/tmp/
	local json="$1"
	local ARR=(${(@s:.:)json})
	KEYS=""
	for i in {2..$#ARR}
	do
		if [[ $i -gt 1 ]] && [[ -n $ARR[$i] ]]
		then
			if isNaN $ARR[$i]
			then
				KEYS+="[\"$ARR[$i]\"]"
			else
				KEYS+="[$ARR[$i]]"
			fi
		fi
	done
	CODE_PY='import json,sys;obj=json.load(sys.stdin);print (obj'$KEYS')'
	echo $ARR[1] | python3 -c $CODE_PY 2> $HOME/tmp/.error_jsonKV
	if [[ $? -ne 0 ]]
	then
		tail -n 1 $HOME/tmp/.error_jsonKV
		rm -i -f $HOME/tmp/.error_jsonKV
	fi
}
last• () {
	COUNT=5
	TARGET_DIR="${PWD}"
	[[ -n "${1}" ]] && COUNT="${1}"
	[[ -n "${2}" ]] && TARGET_DIR="${2}"
	cd ${TARGET_DIR}
	ls -G -lhFAGct1 ${TARGET_DIR} | tail -n ${COUNT}
	cd "${OLDPWD}"
}
last () {
	LINECOUNT=5
	WHERE=$PWD
	if [ -n "$1" ]
	then
		LINECOUNT=$1
	fi
	if [ -n "$2" ]
	then
		WHERE="$2"
	fi
	if isDebug
	then
		echo $LINECOUNT
		echo $WHERE
	fi
	[ -n "$3" ] && H="h"  || H=''
	ls -G -l${H}FAGct "$WHERE" | tail -n "$LINECOUNT"
}
last-command () {
	[[ $# -gt 0 ]] && LINENR=${1}  || LINENR=2
	LASTCMD=$(tail -n ${LINENR} $HISTFILE | head -n 1)
	TO_REPLACE=$(echo $LASTCMD |  cut -d ';' -f1)
	echo ${LASTCMD/${TO_REPLACE};/}
}
lightcyan () {
	echo "${COLOR_LightCyan}${1}${W}"
}
links-grep () {
	{
		case ${#} in
			(1) isDebugLocal && echo "\$# = 1: \$1=$1"
				SZ_REGEX="${1}"  ;;
			(2) isDebugLocal && echo "\$# = 2: \$1=$1, \$2 = $2"
				SZ_REGEX="${2}${1}${2}"  ;;
			(3) isDebugLocal && echo "\$# = 3: \$1=$1, \$2=$2,  \$3=$3"
				SZ_REGEX="${2}${1}${3}"  ;;
		esac
		isDebugLocal && echo "${SZ_REGEX}" && which -a grep
		grep --color=auto -ril . $LINKS | grep --color=auto -E "${SZ_REGEX}"
	} 2> /dev/null
}
list-links () {
	for i in ${1}/**/*.webloc
	do
		dirname "${i/${1}/}"
		TMPL=$(getlink $i)
		TMPN=$(filename $i)
		ekko ${TMPN} 200 007
		ekko ${TMPL} 107 197
	done
}
list2arr () {
	IFS=$DELIMITER_ENDL
	export ARR_LIST=($(eval ${1}))
}
listGBElements () {
	DEPTH=1
	if [ $# -gt 1 ]
	then
		DEPTH=$2
	fi
	du -h -d $DEPTH "$1" | grep --color=auto '[0-9]G\>'
}
listGBElements2 () {
	isDebug && echo \$#\ \=\ $#
	echo "\$0 = $0, \$1 = $1, \$2 = $2, \$3 = $3, \$4 = $4, \$5 = $5, \$6 = $6"
	while [[ $# -gt 0 ]]
	do
		OPT=$1
		shift
		echo $OPT
	done
}
listarray () {
	pARRAY="$1"
	IFS=$'\n'
	echo "${pARRAY[@]}"
}
listarray2 () {
	pARRAY="$1"
	IFS=$'\n'
	echo "${pARRAY[*]}"
}
lns () {
	OPT=''
	if [ -n $3 ]
	then
		OPT=$3
	fi
	ln -s$OPT "$PWD/$1" $2
}
lnsa () {
	CWD="${1}"
	TRGTDIR="."
	[[ -n $2 ]] && TRGTDIR="${2}"
	for i in $CWD/*
	do
		CMD="ln -s $i $TRGTDIR/"
		echo $CMD
		$(echo $CMD)
	done
}
lnsa2 () {
	CWD="${1}"
	[[ $# -eq 1 ]] && [[ $(getInode $PWD) -eq $(getInode $CWD) ]] && {
		CWD="${PWD}"
		TRGTDIR="${1}"
	} || TRGTDIR="${PWD}"
	[[ -n $2 ]] && TRGTDIR="${2}"
	for i in $CWD/*
	do
		CMD="ln -s $i $TRGTDIR/"
		echo $CMD
		$(echo $CMD)
	done
}
lowercase () {
	echo "$1" | tr '[:upper:]' '[:lower:]'
}
lowercase-all-file-ext () {
	for i in *
	do
		EXT=$(fileext $i)
		EXT=$(lowercase $EXT)
		ROOT=$(fileroot $i)
		echo "$i -> ${ROOT}.${EXT}"
		mv -i -i -f "${i}" "${ROOT}.${EXT}"
	done
}
lsd () {
	IFS=$DELIMITER_ENDL
	isDebug && echo "Number of Parameters $#"
	POPT='-F'
	[[ $# -gt 1 ]] && {
		POPT+=${1/-/}
		PPATH=$2
	} || PPATH=$1
	isDebug && echo "PPATH=$PPATH"
	isDebug && echo "POPT=$POPT"
	for i in $(ls -l $POPT $PPATH | grep -oE "^d{1}.*")
	do
		[[ $# -gt 1 ]] && echo $i || {
			echo $i | rev | cut -d " " -f1 | rev
		}
	done
	IFS=$IFS_ORIG
}
lsd2 () {
	IFS=$DELIMITER_ENDL
	isDebug && echo "Number of Parameters $#"
	POPT='-F'
	[[ $# -gt 1 ]] && {
		POPT+=${1/-/}
		PPATH=$2
	} || PPATH=$1
	isDebug && echo "PPATH=$PPATH"
	isDebug && echo "POPT=$POPT"
	for i in $(ls -lt $POPT $PPATH  | grep -oE "^d{1}.*")
	do
		[[ $# -gt 1 ]] && echo $i || {
			[[ $i =~ (.+)" [0-9]{2}:[0-9]{2} "(.+) ]] && {
				isDebug && echo "# of matches $#match\n $match"
				echo $match[2]
			}
		}
	done
	IFS=$IFS_ORIG
}
lsd3 () {
	IFS=$DELIMITER_ENDL
	isDebug && echo "Number of Parameters \$#=$# or \$#@=$#@"
	POPT=()
	PPATH=()
	for i in $@
	do
		isDebug && echo ">> $i"
		[[ -d "$i" ]] && PPATH+="$i"  || POPT+="$i"
	done
	isDebug && echo "PPATH=$PPATH #PPATH=${#PPATH}"
	isDebug && echo "POPT=$POPT #POPT=${#POPT}"
	for i in $(ls -lt $POPT $PPATH)
	do
		isDebug && echo "## $i ##"
		echo $i | grep --color=auto -E "^\s*.*[/]{0,1}:$"
		CURRENT_FOLDER=$(echo $i | grep -E "^d{1}.*")
		isDebug && echo "CURRENT_FOLDER=$CURRENT_FOLDER"
		if [[ -z $CURRENT_FOLDER ]]
		then
			isDebug && echo "CURRENT_FOLDER empty"
			continue
		fi
		if [[ $#POPT -gt 0 ]]
		then
			echo $i | grep --color=auto -E "^d{1}.*"
		else
			if [[ $CURRENT_FOLDER =~ (.+)" [0-9]{2}:[0-9]{2} "(.+) ]]
			then
				isDebug && echo "# of matches $#match\n $match"
				echo $match[2]
			fi
		fi
	done
	IFS=$IFS_ORIG
}
lsd4 () {
	isDebug && echo "Number of Parameters $# PARAMS $@"
	POPT='-F'
	PPATH='.'
	[[ -d "$1" ]] && STARTIDX=1  || {
		STARTIDX=2
		POPT+=${1/-/}
	}
	for x in $@[$STARTIDX,$#@]
	do
		echo "$x:"
		ls -G $POPT $x | grep --color=auto -E ".*/$"
	done
}
lsdir2 () {
	ls -G -G -l ${1} | grep --color=auto --color=auto -oE "^d.*" | rev | cut -d ' ' -f1 | rev
}
lsgit () {
	if [ ! $1 ]
	then
		echo "Usage: lsgit branchname"
		return 1
	else
		git ls-tree -r $1 --name-only
	fi
}
lsgitall () {
	git log --pretty=format: --name-status | cut -f2- | sort -u
}
lsns () {
	[ -n "$1" ] && SP="$1"  || SP="."
	[ -n "$2" ] && EXT="$2"  || EXT=".*"
	find "$SP" -maxdepth 1 ! -type l | grep --color=auto -e "$EXT$"
}
man-header () {
	IFS=$DELIMITER_ENDL
	for i in $(cat /usr/share/man/man*/${1}.* | grep -E '\.S[Hh]+ [A-Z]*')
	do
		echo $i | sed "s/.S[Hh] //" | sed "s/[\"]*//g"
	done
}
man-path () {
	ls -G /usr/share/man/man*/${1}.*
}
mancat () {
	MAN_OUTPUT_FOLDER="$TMP/manoutput"
	[ -d $MAN_OUTPUT_FOLDER ] || mkdir -p "$MAN_OUTPUT_FOLDER"
	TARGET_MAN_FILE="$MAN_OUTPUT_FOLDER/man_${1}.txt"
	[ -f $TARGET_MAN_FILE ] || man "$1" > "$TARGET_MAN_FILE"
	cat "$MAN_OUTPUT_FOLDER/man_${1}.txt"
}
mans2add () {
	echo "man $1" >> $mans2read
}
manx () {
	echo $*
	/usr/bin/man $* > ~/temp.txt
	if [ -s ~/temp.txt ]
	then
		subl ~/temp.txt
	fi
}
members () {
	dscl . -list /Users | while read user
	do
		printf "$user "
		dsmemberutil checkmembership -U "$user" -G "$*"
	done | grep --color=auto "is a member" | cut -d " " -f 1
}
mkcd () {
	cd $(mkdirp "$@")
}
mkdirlinks () {
	mkdir "$LINKS/$1"
}
my_git_formatter () {
	emulate -L zsh
	if [[ -n $P9K_CONTENT ]]
	then
		typeset -g my_git_format=$P9K_CONTENT
		return
	fi
	local meta='%7F'
	local clean='%0F'
	local modified='%0F'
	local untracked='%0F'
	local conflicted='%1F'
	local res
	if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]
	then
		local branch=${(V)VCS_STATUS_LOCAL_BRANCH}
		(( $#branch > 32 )) && branch[13,-13]="…"
		res+="${clean}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
	fi
	if [[ -n $VCS_STATUS_TAG && -z $VCS_STATUS_LOCAL_BRANCH ]]
	then
		local tag=${(V)VCS_STATUS_TAG}
		(( $#tag > 32 )) && tag[13,-13]="…"
		res+="${meta}#${clean}${tag//\%/%%}"
	fi
	[[ -z $VCS_STATUS_LOCAL_BRANCH && -z $VCS_STATUS_TAG ]] && res+="${meta}@${clean}${VCS_STATUS_COMMIT[1,8]}"
	if [[ -n ${VCS_STATUS_REMOTE_BRANCH:#$VCS_STATUS_LOCAL_BRANCH} ]]
	then
		res+="${meta}:${clean}${(V)VCS_STATUS_REMOTE_BRANCH//\%/%%}"
	fi
	if [[ $VCS_STATUS_COMMIT_SUMMARY == (|*[^[:alnum:]])(wip|WIP)(|[^[:alnum:]]*) ]]
	then
		res+=" ${modified}wip"
	fi
	(( VCS_STATUS_COMMITS_BEHIND )) && res+=" ${clean}⇣${VCS_STATUS_COMMITS_BEHIND}"
	(( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && res+=" "
	(( VCS_STATUS_COMMITS_AHEAD  )) && res+="${clean}⇡${VCS_STATUS_COMMITS_AHEAD}"
	(( VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" ${clean}⇠${VCS_STATUS_PUSH_COMMITS_BEHIND}"
	(( VCS_STATUS_PUSH_COMMITS_AHEAD && !VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" "
	(( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && res+="${clean}⇢${VCS_STATUS_PUSH_COMMITS_AHEAD}"
	(( VCS_STATUS_STASHES        )) && res+=" ${clean}*${VCS_STATUS_STASHES}"
	[[ -n $VCS_STATUS_ACTION ]] && res+=" ${conflicted}${VCS_STATUS_ACTION}"
	(( VCS_STATUS_NUM_CONFLICTED )) && res+=" ${conflicted}~${VCS_STATUS_NUM_CONFLICTED}"
	(( VCS_STATUS_NUM_STAGED     )) && res+=" ${modified}+${VCS_STATUS_NUM_STAGED}"
	(( VCS_STATUS_NUM_UNSTAGED   )) && res+=" ${modified}!${VCS_STATUS_NUM_UNSTAGED}"
	(( VCS_STATUS_NUM_UNTRACKED  )) && res+=" ${untracked}${(g::)POWERLEVEL9K_VCS_UNTRACKED_ICON}${VCS_STATUS_NUM_UNTRACKED}"
	(( VCS_STATUS_HAS_UNSTAGED == -1 )) && res+=" ${modified}─"
	typeset -g my_git_format=$res
}
n-lines-from-m () {
	usage $0 $# 1 "<path to file: string> [<line to start from=0: number> [<count of lines to show: number>]]" "displays n lines from m-th line of an ASCII file (cat-like)\n (shell not miaow)\n1st param is the path to a file (mandatory)\n2nd argument is m, defaults to 0 and indicates the starting line \n3rd argument is n, defaults to 10 and indicates to count of lines to be displayed\na command like \"head\" or \"tail\" starting anywhere but the start (head) or the end (tail) of a file" || return 1
	M=0
	N=10
	[[ -n $2 ]] && M=$2
	[[ -n $3 ]] && N=$3
	CNTLNS=$(cat "${1}" | wc -l)
	tail -n $(($CNTLNS-$M)) "${1}" | head -n $N
}
negate () {
	echo $(( $1 * -1  ))
}
new-shell-log-file () {
	export SHELL_LOG_FILE=$SHELL_LOG_FOLDER/sourced_files_$(date +%s).txt
}
nvm_prompt_info () {
	[[ -f "$NVM_DIR/nvm.sh" ]] || return
	local nvm_prompt
	nvm_prompt=$(node -v 2>/dev/null)
	[[ "${nvm_prompt}x" == "x" ]] && return
	nvm_prompt=${nvm_prompt:1}
	echo "${ZSH_THEME_NVM_PROMPT_PREFIX}${nvm_prompt}${ZSH_THEME_NVM_PROMPT_SUFFIX}"
}
omz_diagnostic_dump () {
	emulate -L zsh
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
	builtin echo
}
omz_history () {
	local clear list
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
	fi
}
omz_termsupport_precmd () {
	emulate -L zsh
	if [[ "$DISABLE_AUTO_TITLE" == true ]]
	then
		return
	fi
	title $ZSH_THEME_TERM_TAB_TITLE_IDLE $ZSH_THEME_TERM_TITLE_IDLE
}
omz_termsupport_preexec () {
	emulate -L zsh
	setopt extended_glob
	if [[ "$DISABLE_AUTO_TITLE" == true ]]
	then
		return
	fi
	local CMD=${1[(wr)^(*=*|sudo|ssh|mosh|rake|-*)]:gs/%/%%}
	local LINE="${2:gs/%/%%}"
	title '$CMD' '%100>...>$LINE%<<'
}
omz_urldecode () {
	emulate -L zsh
	local encoded_url=$1
	local caller_encoding=$langinfo[CODESET]
	local LC_ALL=C
	export LC_ALL
	local tmp=${encoded_url:gs/+/ /}
	tmp=${tmp:gs/\\/\\\\/}
	tmp=${tmp:gs/%/\\x/}
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
	echo -E "$decoded"
}
omz_urlencode () {
	emulate -L zsh
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
	echo -E "$url_str"
}
open_command () {
	local open_cmd
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
	${=open_cmd} "$@" &> /dev/null
}
opentimedoc () {
	export STANDARD_FOLDER=~/Documents/Tätigkeitsnachweis
	if [ ${#1} -ne 0 ] && [ -r $1 ]
	then
		CURRENT_PATH=$1
	elif [ "$1" == "-h" ]
	then
		echo "usage: $0 [<path to folder containing excel sheets>]"
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
		echo "usage: $0 [<path to folder containing excel sheet>]"
		echo
		return 1
	fi
	PATH2DOC=$CURRENT_DOC
	open /Applications/Microsoft\ Excel.app $PATH2DOC
}
opex () {
	xdg-open $1 &
}
p10k () {
	[[ $# != 1 || $1 != finalize ]] || {
		p10k-instant-prompt-finalize
		return 0
	}
	eval "$__p9k_intro_no_reply"
	if (( !ARGC ))
	then
		print -rP -- $__p9k_p10k_usage >&2
		return 1
	fi
	case $1 in
		(segment) local REPLY
			local -a reply
			shift
			local -i OPTIND
			local OPTARG opt state bg=0 fg icon cond text ref=0 expand=0
			while getopts ':s:b:f:i:c:t:reh' opt
			do
				case $opt in
					(s) state=$OPTARG  ;;
					(b) bg=$OPTARG  ;;
					(f) fg=$OPTARG  ;;
					(i) icon=$OPTARG  ;;
					(c) cond=${OPTARG:-'${:-}'}  ;;
					(t) text=$OPTARG  ;;
					(r) ref=1  ;;
					(e) expand=1  ;;
					(+r) ref=0  ;;
					(+e) expand=0  ;;
					(h) print -rP -- $__p9k_p10k_segment_usage
						return 0 ;;
					(?) print -rP -- $__p9k_p10k_segment_usage >&2
						return 1 ;;
				esac
			done
			if (( OPTIND <= ARGC ))
			then
				print -rP -- $__p9k_p10k_segment_usage >&2
				return 1
			fi
			if [[ -z $_p9k__prompt_side ]]
			then
				print -rP -- "%1F[ERROR]%f %Bp10k segment%b: can be called only during prompt rendering." >&2
				if (( !ARGC ))
				then
					print -rP -- ""
					print -rP -- "For help, type:" >&2
					print -rP -- ""
					print -rP -- "  %2Fp10k%f %Bhelp%b %Bsegment%b" >&2
				fi
				return 1
			fi
			(( ref )) || icon=$'\1'$icon
			typeset -i _p9k__has_upglob
			"_p9k_${_p9k__prompt_side}_prompt_segment" "prompt_${_p9k__segment_name}${state:+_${${(U)state}//İ/I}}" "$bg" "${fg:-$_p9k_color1}" "$icon" "$expand" "$cond" "$text"
			return 0 ;;
		(display) if (( ARGC == 1 ))
			then
				print -rP -- $__p9k_p10k_display_usage >&2
				return 1
			fi
			shift
			local -i k dump
			local opt prev new pair list name var
			while getopts ':har' opt
			do
				case $opt in
					(r) if (( __p9k_reset_state > 0 ))
						then
							__p9k_reset_state=2
						else
							__p9k_reset_state=-1
						fi ;;
					(a) dump=1  ;;
					(h) print -rP -- $__p9k_p10k_display_usage
						return 0 ;;
					(?) print -rP -- $__p9k_p10k_display_usage >&2
						return 1 ;;
				esac
			done
			if (( dump ))
			then
				reply=()
				shift $((OPTIND-1))
				(( ARGC )) || set -- '*'
				for opt
				do
					for k in ${(u@)_p9k_display_k[(I)$opt]:/(#m)*/$_p9k_display_k[$MATCH]}
					do
						reply+=($_p9k__display_v[k,k+1])
					done
				done
				if (( __p9k_reset_state == -1 ))
				then
					_p9k_reset_prompt
				fi
				return 0
			fi
			local REPLY
			local -a reply
			for opt in "${@:$OPTIND}"
			do
				pair=(${(s:=:)opt})
				list=(${(s:,:)${pair[2]}})
				if [[ ${(b)pair[1]} == $pair[1] ]]
				then
					local ks=($_p9k_display_k[$pair[1]])
				else
					local ks=(${(u@)_p9k_display_k[(I)$pair[1]]:/(#m)*/$_p9k_display_k[$MATCH]})
				fi
				for k in $ks
				do
					if (( $#list == 1 ))
					then
						[[ $_p9k__display_v[k+1] == $list[1] ]] && continue
						new=$list[1]
					else
						new=${list[list[(I)$_p9k__display_v[k+1]]+1]:-$list[1]}
						[[ $_p9k__display_v[k+1] == $new ]] && continue
					fi
					_p9k__display_v[k+1]=$new
					name=$_p9k__display_v[k]
					if [[ $name == (empty_line|ruler) ]]
					then
						var=_p9k__${name}_i
						[[ $new == show ]] && unset $var || typeset -gi $var=3
					elif [[ $name == (#b)(<->)(*) ]]
					then
						var=_p9k__${match[1]}${${${${match[2]//\/}/#left/l}/#right/r}/#gap/g}
						[[ $new == hide ]] && typeset -g $var= || unset $var
					fi
					if (( __p9k_reset_state > 0 ))
					then
						__p9k_reset_state=2
					else
						__p9k_reset_state=-1
					fi
				done
			done
			if (( __p9k_reset_state == -1 ))
			then
				_p9k_reset_prompt
			fi ;;
		(configure) if (( ARGC > 1 ))
			then
				print -rP -- $__p9k_p10k_configure_usage >&2
				return 1
			fi
			local REPLY
			local -a reply
			p9k_configure "$@" || return ;;
		(reload) if (( ARGC > 1 ))
			then
				print -rP -- $__p9k_p10k_reload_usage >&2
				return 1
			fi
			(( $+_p9k__force_must_init )) || return 0
			_p9k__force_must_init=1  ;;
		(help) local var=__p9k_p10k_$2_usage
			if (( $+parameters[$var] ))
			then
				print -rP -- ${(P)var}
				return 0
			elif (( ARGC == 1 ))
			then
				print -rP -- $__p9k_p10k_usage
				return 0
			else
				print -rP -- $__p9k_p10k_usage >&2
				return 1
			fi ;;
		(finalize) print -rP -- $__p9k_p10k_finalize_usage >&2
			return 1 ;;
		(clear-instant-prompt) if (( $+__p9k_instant_prompt_active ))
			then
				_p9k_clear_instant_prompt
				unset __p9k_instant_prompt_active
			fi
			return 0 ;;
		(*) print -rP -- $__p9k_p10k_usage >&2
			return 1 ;;
	esac
}
p10k-instant-prompt-finalize () {
	unsetopt local_options
	(( ${+__p9k_instant_prompt_active} )) && unsetopt prompt_cr prompt_sp || setopt prompt_cr prompt_sp
}
p9k_configure () {
	eval "$__p9k_intro"
	_p9k_can_configure || return
	(
		set -- -f
		builtin source $__p9k_root_dir/internal/wizard.zsh
	)
	local ret=$?
	case $ret in
		(0) builtin source $__p9k_cfg_path
			_p9k__force_must_init=1  ;;
		(69) return 0 ;;
		(*) return $ret ;;
	esac
}
p9k_prompt_segment () {
	p10k segment "$@"
}
param () {
	PC=2
	echo "count $#"
	echo "\$0 $0"
	echo "0 ${@:0}"
	echo "1 ${@:1}"
	echo "2 ${@:2}"
	echo "3 ${@:3}"
	echo "$PC ${@:PC}"
	echo "$1" ${@:2} -R .
}
parrram () {
	isDebug && echo "Number of Parameters \$#=$# or \$#@=$#@"
	POPT=()
	PPATH=()
	for i in $@
	do
		echo ">> $i"
		[[ -d "$i" ]] && PPATH+="$i"  || POPT+="$i"
	done
	echo $POPT $PPATH
	ls -G $POPT $PPATH
}
parse_git_dirty () {
	local STATUS
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
	fi
}
path2string () {
	ARG_PATH="${1}"
	[[ $ARG_PATH[1] = '/' ]] && echo ${ARG_PATH[2,$#ARG_PATH]//\//-} || echo ${ARG_PATH//\//-}
}
phpserve () {
	URL=$([ -n "$1" ] && echo "$1" || echo "localhost")
	PORT=$([ -n "$2" ] && echo "2" || echo "8080")
	DOCROOT=$([ -n "$3" ] && echo "3" || echo ".")
	php -S "$URL:$PORT" -t $DOCROOT
}
pink () {
	echo "${COLOR_Purple}${1}${W}"
}
pink2 () {
	echo "\033[1;35m$1\033[00m"
}
powerlevel10k_plugin_unload () {
	prompt_powerlevel9k_teardown
}
precmd_update_git_vars () {
	if [ -n "$__EXECUTED_GIT_COMMAND" ] || [ ! -n "$ZSH_THEME_GIT_PROMPT_CACHE" ]
	then
		update_current_git_vars
		unset __EXECUTED_GIT_COMMAND
	fi
}
preexec_update_git_vars () {
	case "$2" in
		(git* | hub* | gh* | stg*) __EXECUTED_GIT_COMMAND=1  ;;
	esac
}
print_icon () {
	eval "$__p9k_intro"
	_p9k_init_icons
	local var=POWERLEVEL9K_$1
	if (( $+parameters[$var] ))
	then
		echo -n - ${(P)var}
	else
		echo -n - $icons[$1]
	fi
}
print_usage () {
	IFS=''
	read -r -d '' USAGE <<EOT
What does it do?
The option "-D" opens a SOCKS port and tunnels it to the machine you are connected to.
How can i use it?
Go to the settings in your browser and look for proxy settings.
Set as proxy server (Socks 5): 127.0.0.1 and port the port you defined with option "-D", 7070 in above example.

That's all, all your traffic from your browser is now tunneled though your SSH connection!
EOT
	echo $USAGE
}
prompt__p9k_internal_nothing () {
	_p9k__prompt+='${_p9k__sss::=}'
}
prompt_anaconda () {
	local msg
	if _p9k_python_version
	then
		P9K_ANACONDA_PYTHON_VERSION=$_p9k__ret
		if (( _POWERLEVEL9K_ANACONDA_SHOW_PYTHON_VERSION ))
		then
			msg="${P9K_ANACONDA_PYTHON_VERSION//\%/%%} "
		fi
	else
		unset P9K_ANACONDA_PYTHON_VERSION
	fi
	local p=${CONDA_PREFIX:-$CONDA_ENV_PATH}
	msg+="$_POWERLEVEL9K_ANACONDA_LEFT_DELIMITER${${p:t}//\%/%%}$_POWERLEVEL9K_ANACONDA_RIGHT_DELIMITER"
	_p9k_prompt_segment "$0" "blue" "$_p9k_color1" 'PYTHON_ICON' 0 '' "$msg"
}
prompt_asdf () {
	_p9k_asdf_check_meta || _p9k_asdf_init_meta || return
	local -A versions
	local -a stat
	local -i has_global
	local dirs=($_p9k__parent_dirs)
	local mtimes=($_p9k__parent_mtimes)
	if [[ $dirs[-1] != ~ ]]
	then
		zstat -A stat +mtime ~ 2> /dev/null || return
		dirs+=(~)
		mtimes+=($stat[1])
	fi
	local elem
	for elem in ${(@)${:-{1..$#dirs}}/(#m)*/${${:-$MATCH:$_p9k__asdf_dir2files[$dirs[MATCH]]}#$MATCH:$mtimes[MATCH]:}}
	do
		if [[ $elem == *:* ]]
		then
			local dir=$dirs[${elem%%:*}]
			zstat -A stat +mtime $dir 2> /dev/null || return
			local files=($dir/.tool-versions(N) $dir/${(k)^_p9k_asdf_file_info}(N))
			_p9k__asdf_dir2files[$dir]=$stat[1]:${(pj:\0:)files}
		else
			local files=(${(0)elem})
		fi
		if [[ ${files[1]:h} == ~ ]]
		then
			has_global=1
			local -A local_versions=(${(kv)versions})
			versions=()
		fi
		local file
		for file in $files
		do
			[[ $file == */.tool-versions ]]
			_p9k_asdf_parse_version_file $file $? || return
		done
	done
	if (( ! has_global ))
	then
		has_global=1
		local -A local_versions=(${(kv)versions})
		versions=()
	fi
	if [[ -r $ASDF_DEFAULT_TOOL_VERSIONS_FILENAME ]]
	then
		_p9k_asdf_parse_version_file $ASDF_DEFAULT_TOOL_VERSIONS_FILENAME 0 || return
	fi
	local plugin
	for plugin in ${(k)_p9k_asdf_plugins}
	do
		local upper=${${(U)plugin//-/_}//İ/I}
		if (( $+parameters[_POWERLEVEL9K_ASDF_${upper}_SOURCES] ))
		then
			local sources=(${(P)${:-_POWERLEVEL9K_ASDF_${upper}_SOURCES}})
		else
			local sources=($_POWERLEVEL9K_ASDF_SOURCES)
		fi
		local version="${(P)${:-ASDF_${upper}_VERSION}}"
		if [[ -n $version ]]
		then
			(( $sources[(I)shell] )) || continue
		else
			version=$local_versions[$plugin]
			if [[ -n $version ]]
			then
				(( $sources[(I)local] )) || continue
			else
				version=$versions[$plugin]
				[[ -n $version ]] || continue
				(( $sources[(I)global] )) || continue
			fi
		fi
		if [[ $version == $versions[$plugin] ]]
		then
			if (( $+parameters[_POWERLEVEL9K_ASDF_${upper}_PROMPT_ALWAYS_SHOW] ))
			then
				(( _POWERLEVEL9K_ASDF_${upper}_PROMPT_ALWAYS_SHOW )) || continue
			else
				(( _POWERLEVEL9K_ASDF_PROMPT_ALWAYS_SHOW )) || continue
			fi
		fi
		if [[ $version == system ]]
		then
			if (( $+parameters[_POWERLEVEL9K_ASDF_${upper}_SHOW_SYSTEM] ))
			then
				(( _POWERLEVEL9K_ASDF_${upper}_SHOW_SYSTEM )) || continue
			else
				(( _POWERLEVEL9K_ASDF_SHOW_SYSTEM )) || continue
			fi
		fi
		_p9k_get_icon $0_$upper ${upper}_ICON $plugin
		_p9k_prompt_segment $0_$upper green $_p9k_color1 $'\1'$_p9k__ret 0 '' ${version//\%/%%}
	done
}
prompt_aws () {
	typeset -g P9K_AWS_PROFILE="${AWS_VAULT:-${AWSUME_PROFILE:-${AWS_PROFILE:-$AWS_DEFAULT_PROFILE}}}"
	local pat class state
	for pat class in "${_POWERLEVEL9K_AWS_CLASSES[@]}"
	do
		if [[ $P9K_AWS_PROFILE == ${~pat} ]]
		then
			[[ -n $class ]] && state=_${${(U)class}//İ/I}
			break
		fi
	done
	if [[ -n ${AWS_REGION:-$AWS_DEFAULT_REGION} ]]
	then
		typeset -g P9K_AWS_REGION=${AWS_REGION:-$AWS_DEFAULT_REGION}
	else
		local cfg=${AWS_CONFIG_FILE:-~/.aws/config}
		if ! _p9k_cache_stat_get $0 $cfg
		then
			local -a reply
			_p9k_parse_aws_config $cfg
			_p9k_cache_stat_set $reply
		fi
		local prefix=$#P9K_AWS_PROFILE:$P9K_AWS_PROFILE:
		local kv=$_p9k__cache_val[(r)${(b)prefix}*]
		typeset -g P9K_AWS_REGION=${kv#$prefix}
	fi
	_p9k_prompt_segment "$0$state" red white 'AWS_ICON' 0 '' "${P9K_AWS_PROFILE//\%/%%}"
}
prompt_aws_eb_env () {
	_p9k_upglob .elasticbeanstalk && return
	local dir=$_p9k__parent_dirs[$?]
	if ! _p9k_cache_stat_get $0 $dir/.elasticbeanstalk/config.yml
	then
		local env
		env="$(command eb list 2>/dev/null)"  || env=
		env="${${(@M)${(@f)env}:#\* *}#\* }"
		_p9k_cache_stat_set "$env"
	fi
	[[ -n $_p9k__cache_val[1] ]] || return
	_p9k_prompt_segment "$0" black green 'AWS_EB_ICON' 0 '' "${_p9k__cache_val[1]//\%/%%}"
}
prompt_azure () {
	local cfg=${AZURE_CONFIG_DIR:-$HOME/.azure}/azureProfile.json
	if ! _p9k_cache_stat_get $0 $cfg
	then
		local name
		if (( $+commands[jq] )) && name="$(jq -r '[.subscriptions[]|select(.isDefault==true)|.name][]|strings' $cfg 2>/dev/null)"
		then
			name=${name%%$'\n'*}
		elif ! name="$(az account show --query name --output tsv 2>/dev/null)"
		then
			name=
		fi
		_p9k_cache_stat_set "$name"
	fi
	local pat class state
	for pat class in "${_POWERLEVEL9K_AZURE_CLASSES[@]}"
	do
		if [[ $name == ${~pat} ]]
		then
			[[ -n $class ]] && state=_${${(U)class}//İ/I}
			break
		fi
	done
	[[ -n $_p9k__cache_val[1] ]] || return
	_p9k_prompt_segment "$0$state" "blue" "white" "AZURE_ICON" 0 '' "${_p9k__cache_val[1]//\%/%%}"
}
prompt_background_jobs () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	local msg
	if (( _POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE ))
	then
		if (( _POWERLEVEL9K_BACKGROUND_JOBS_VERBOSE_ALWAYS ))
		then
			msg='${(%):-%j}'
		else
			msg='${${(%):-%j}:#1}'
		fi
	fi
	_p9k_prompt_segment $0 "$_p9k_color1" cyan BACKGROUND_JOBS_ICON 1 '${${(%):-%j}:#0}' "$msg"
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_battery () {
	[[ $_p9k_os == (Linux|Android) ]] && _p9k_prompt_battery_set_args
	(( $#_p9k__battery_args )) && _p9k_prompt_segment "${_p9k__battery_args[@]}"
}
prompt_bzr () {
	(( $+commands[bzr] )) || return
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
	fi
}
prompt_chruby () {
	local v
	(( _POWERLEVEL9K_CHRUBY_SHOW_ENGINE )) && v=$RUBY_ENGINE
	if [[ $_POWERLEVEL9K_CHRUBY_SHOW_VERSION == 1 && -n $RUBY_VERSION ]] && v+=${v:+ }$RUBY_VERSION
		_p9k_prompt_segment "$0" "red" "$_p9k_color1" 'RUBY_ICON' 0 '' "${v//\%/%%}"
	then

	fi
}
prompt_command_execution_time () {
	(( $+P9K_COMMAND_DURATION_SECONDS )) || return
	(( P9K_COMMAND_DURATION_SECONDS >= _POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD )) || return
	if (( P9K_COMMAND_DURATION_SECONDS < 60 ))
	then
		if (( !_POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION ))
		then
			local -i sec=$((P9K_COMMAND_DURATION_SECONDS + 0.5))
		else
			local -F $_POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION sec=P9K_COMMAND_DURATION_SECONDS
		fi
		local text=${sec}s
	else
		local -i d=$((P9K_COMMAND_DURATION_SECONDS + 0.5))
		if [[ $_POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT == "H:M:S" ]]
		then
			local text=${(l.2..0.)$((d % 60))}
			if (( d >= 60 ))
			then
				text=${(l.2..0.)$((d / 60 % 60))}:$text
				if (( d >= 36000 ))
				then
					text=$((d / 3600)):$text
				elif (( d >= 3600 ))
				then
					text=0$((d / 3600)):$text
				fi
			fi
		else
			local text="$((d % 60))s"
			if (( d >= 60 ))
			then
				text="$((d / 60 % 60))m $text"
				if (( d >= 3600 ))
				then
					text="$((d / 3600 % 24))h $text"
					if (( d >= 86400 ))
					then
						text="$((d / 86400))d $text"
					fi
				fi
			fi
		fi
	fi
	_p9k_prompt_segment "$0" "red" "yellow1" 'EXECUTION_TIME_ICON' 0 '' $text
}
prompt_context () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	local content
	if [[ $_POWERLEVEL9K_ALWAYS_SHOW_CONTEXT == 0 && -n $DEFAULT_USER && $P9K_SSH == 0 ]]
	then
		local user="${(%):-%n}"
		if [[ $user == $DEFAULT_USER ]]
		then
			content="${user//\%/%%}"
		fi
	fi
	local state
	if (( P9K_SSH ))
	then
		if [[ -n "$SUDO_COMMAND" ]]
		then
			state="REMOTE_SUDO"
		else
			state="REMOTE"
		fi
	elif [[ -n "$SUDO_COMMAND" ]]
	then
		state="SUDO"
	else
		state="DEFAULT"
	fi
	local cond
	for state cond in $state '${${(%):-%#}:#\#}' ROOT '${${(%):-%#}:#\%}'
	do
		local text=$content
		if [[ -z $text ]]
		then
			local var=_POWERLEVEL9K_CONTEXT_${state}_TEMPLATE
			if (( $+parameters[$var] ))
			then
				text=${(P)var}
				text=${(g::)text}
			else
				text=$_POWERLEVEL9K_CONTEXT_TEMPLATE
			fi
		fi
		_p9k_prompt_segment "$0_$state" "$_p9k_color1" yellow '' 0 "$cond" "$text"
	done
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_date () {
	if [[ $_p9k__refresh_reason == precmd ]]
	then
		if [[ $+__p9k_instant_prompt_active == 1 && $__p9k_instant_prompt_date_format == $_POWERLEVEL9K_DATE_FORMAT ]]
		then
			_p9k__date=${__p9k_instant_prompt_date//\%/%%}
		else
			_p9k__date=${${(%)_POWERLEVEL9K_DATE_FORMAT}//\%/%%}
		fi
	fi
	_p9k_prompt_segment "$0" "$_p9k_color2" "$_p9k_color1" "DATE_ICON" 0 '' "$_p9k__date"
}
prompt_detect_virt () {
	local virt="$(systemd-detect-virt 2>/dev/null)"
	if [[ "$virt" == "none" ]]
	then
		local -a inode
		if zstat -A inode +inode / 2> /dev/null && [[ $inode[1] != 2 ]]
		then
			virt="chroot"
		fi
	fi
	if [[ -n "${virt}" ]]
	then
		_p9k_prompt_segment "$0" "$_p9k_color1" "yellow" '' 0 '' "${virt//\%/%%}"
	fi
}
prompt_dir () {
	if (( _POWERLEVEL9K_DIR_PATH_ABSOLUTE ))
	then
		local p=${(V)_p9k__cwd}
		local -a parts=("${(s:/:)p}")
	elif [[ -o auto_name_dirs ]]
	then
		local p=${(V)${_p9k__cwd/#(#b)$HOME(|\/*)/'~'$match[1]}}
		local -a parts=("${(s:/:)p}")
	else
		local p=${(%):-%~}
		if [[ $p == '~['* ]]
		then
			local func=''
			local -a parts=()
			for func in zsh_directory_name $zsh_directory_name_functions
			do
				local reply=()
				if (( $+functions[$func] )) && $func d $_p9k__cwd && [[ $p == '~['${(V)reply[1]}']'* ]]
				then
					parts+='~['${(V)reply[1]}']'
					break
				fi
			done
			if (( $#parts ))
			then
				parts+=(${(s:/:)${p#$parts[1]}})
			else
				p=${(V)_p9k__cwd}
				parts=("${(s:/:)p}")
			fi
		else
			local -a parts=("${(s:/:)p}")
		fi
	fi
	local -i fake_first=0 expand=0 shortenlen=${_POWERLEVEL9K_SHORTEN_DIR_LENGTH:--1}
	if (( $+_POWERLEVEL9K_SHORTEN_DELIMITER ))
	then
		local delim=$_POWERLEVEL9K_SHORTEN_DELIMITER
	else
		if [[ $langinfo[CODESET] == (utf|UTF)(-|)8 ]]
		then
			local delim=$'\u2026'
		else
			local delim='..'
		fi
	fi
	case $_POWERLEVEL9K_SHORTEN_STRATEGY in
		(truncate_absolute | truncate_absolute_chars) if (( shortenlen > 0 && $#p > shortenlen ))
			then
				_p9k_shorten_delim_len $delim
				if (( $#p > shortenlen + $_p9k__ret ))
				then
					local -i n=shortenlen
					local -i i=$#parts
					while true
					do
						local dir=$parts[i]
						local -i len=$(( $#dir + (i > 1) ))
						if (( len <= n ))
						then
							(( n -= len ))
							(( --i ))
						else
							parts[i]=$'\1'$dir[-n,-1]
							parts[1,i-1]=()
							break
						fi
					done
				fi
			fi ;;
		(truncate_with_package_name | truncate_middle | truncate_from_right) () {
				[[ $_POWERLEVEL9K_SHORTEN_STRATEGY == truncate_with_package_name && $+commands[jq] == 1 && $#_POWERLEVEL9K_DIR_PACKAGE_FILES > 0 ]] || return
				local pats="(${(j:|:)_POWERLEVEL9K_DIR_PACKAGE_FILES})"
				local -i i=$#parts
				local dir=$_p9k__cwd
				for ((; i > 0; --i )) do
					local markers=($dir/${~pats}(N))
					if (( $#markers ))
					then
						local pat= pkg_file=
						for pat in $_POWERLEVEL9K_DIR_PACKAGE_FILES
						do
							for pkg_file in $markers
							do
								[[ $pkg_file == $dir/${~pat} ]] || continue
								if ! _p9k_cache_stat_get $0_pkg $pkg_file
								then
									local pkg_name=''
									pkg_name="$(jq -j '.name | select(. != null)' <$pkg_file 2>/dev/null)"  || pkg_name=''
									_p9k_cache_stat_set "$pkg_name"
								fi
								[[ -n $_p9k__cache_val[1] ]] || continue
								parts[1,i]=($_p9k__cache_val[1])
								fake_first=1
								return 0
							done
						done
					fi
					dir=${dir:h}
				done
			}
			if (( shortenlen > 0 ))
			then
				_p9k_shorten_delim_len $delim
				local -i d=_p9k__ret pref=shortenlen suf=0 i=2
				[[ $_POWERLEVEL9K_SHORTEN_STRATEGY == truncate_middle ]] && suf=pref
				for ((; i < $#parts; ++i )) do
					local dir=$parts[i]
					if (( $#dir > pref + suf + d ))
					then
						dir[pref+1,-suf-1]=$'\1'
						parts[i]=$dir
					fi
				done
			fi ;;
		(truncate_to_last) shortenlen=${_POWERLEVEL9K_SHORTEN_DIR_LENGTH:-1}
			(( shortenlen > 0 )) || shortenlen=1
			local -i i='shortenlen+1'
			if [[ $#parts -gt i || ( $p[1] != / && $#parts -gt shortenlen ) ]]
			then
				fake_first=1
				parts[1,-i]=()
			fi ;;
		(truncate_to_first_and_last) if (( shortenlen > 0 ))
			then
				local -i i=$(( shortenlen + 1 ))
				[[ $p == /* ]] && (( ++i ))
				for ((; i <= $#parts - shortenlen; ++i )) do
					parts[i]=$'\1'
				done
			fi ;;
		(truncate_to_unique) expand=1
			delim=${_POWERLEVEL9K_SHORTEN_DELIMITER-'*'}
			shortenlen=${_POWERLEVEL9K_SHORTEN_DIR_LENGTH:-1}
			(( shortenlen >= 0 )) || shortenlen=1
			local rp=${(g:oce:)p}
			local rparts=("${(@s:/:)rp}")
			local -i i=2 e=$(($#parts - shortenlen))
			if [[ -n $_POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER ]]
			then
				(( e += shortenlen ))
				local orig=("$parts[2]" "${(@)parts[$((shortenlen > $#parts ? -$#parts : -shortenlen)),-1]}")
			elif [[ $p[1] == / ]]
			then
				(( ++i ))
			fi
			if (( i <= e ))
			then
				local mtimes=(${(Oa)_p9k__parent_mtimes:$(($#parts-e)):$((e-i+1))})
				local key="${(pj.:.)mtimes}"
			else
				local key=
			fi
			if ! _p9k_cache_ephemeral_get $0 $e $i $_p9k__cwd || [[ $key != $_p9k__cache_val[1] ]]
			then
				local rtail=${(j./.)rparts[i,-1]}
				local parent=$_p9k__cwd[1,-2-$#rtail]
				_p9k_prompt_length $delim
				local -i real_delim_len=_p9k__ret
				[[ -n $parts[i-1] ]] && parts[i-1]="\${(Q)\${:-${(qqq)${(q)parts[i-1]}}}}"$'\2'
				local -i d=${_POWERLEVEL9K_SHORTEN_DELIMITER_LENGTH:--1}
				(( d >= 0 )) || d=real_delim_len
				local -i m=1
				for ((; i <= e; ++i, ++m )) do
					local sub=$parts[i]
					local rsub=$rparts[i]
					local dir=$parent/$rsub mtime=$mtimes[m]
					local pair=$_p9k__dir_stat_cache[$dir]
					if [[ $pair == ${mtime:-x}:* ]]
					then
						parts[i]=${pair#*:}
					else
						[[ $sub != *["~!#\`\$^&*()\\\"'<>?{}[]"]* ]]
						local -i q=$?
						if [[ -n $_POWERLEVEL9K_SHORTEN_FOLDER_MARKER && -n $dir/${~_POWERLEVEL9K_SHORTEN_FOLDER_MARKER}(#qN) ]]
						then
							(( q )) && parts[i]="\${(Q)\${:-${(qqq)${(q)sub}}}}"
							parts[i]+=$'\2'
						else
							local -i j=$rsub[(i)[^.]]
							for ((; j + d < $#rsub; ++j )) do
								local -a matching=($parent/$rsub[1,j]*/(N))
								(( $#matching == 1 )) && break
							done
							local -i saved=$((${(m)#${(V)${rsub:$j}}} - d))
							if (( saved > 0 ))
							then
								if (( q ))
								then
									parts[i]='${${${_p9k__d:#-*}:+${(Q)${:-'${(qqq)${(q)sub}}'}}}:-${(Q)${:-'
									parts[i]+=$'\3'${(qqq)${(q)${(V)${rsub[1,j]}}}}$'}}\1\3''${$((_p9k__d+='$saved'))+}}'
								else
									parts[i]='${${${_p9k__d:#-*}:+'$sub$'}:-\3'${(V)${rsub[1,j]}}$'\1\3''${$((_p9k__d+='$saved'))+}}'
								fi
							else
								(( q )) && parts[i]="\${(Q)\${:-${(qqq)${(q)sub}}}}"
							fi
						fi
						[[ -n $mtime ]] && _p9k__dir_stat_cache[$dir]="$mtime:$parts[i]"
					fi
					parent+=/$rsub
				done
				if [[ -n $_POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER ]]
				then
					local _2=$'\2'
					if [[ $_POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER == last* ]]
					then
						(( e = ${parts[(I)*$_2]} + ${_POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER#*:} ))
					else
						(( e = ${parts[(ib:2:)*$_2]} + ${_POWERLEVEL9K_DIR_TRUNCATE_BEFORE_MARKER#*:} ))
					fi
					if (( e > 1 && e <= $#parts ))
					then
						parts[1,e-1]=()
						fake_first=1
					elif [[ $p == /?* ]]
					then
						parts[2]="\${(Q)\${:-${(qqq)${(q)orig[1]}}}}"$'\2'
					fi
					for ((i = $#parts < shortenlen ? $#parts : shortenlen; i > 0; --i)) do
						[[ $#parts[-i] == *$'\2' ]] && continue
						if [[ $orig[-i] == *["~!#\`\$^&*()\\\"'<>?{}[]"]* ]]
						then
							parts[-i]='${(Q)${:-'${(qqq)${(q)orig[-i]}}'}}'$'\2'
						else
							parts[-i]=${orig[-i]}$'\2'
						fi
					done
				else
					for ((; i <= $#parts; ++i)) do
						[[ $parts[i] == *["~!#\`\$^&*()\\\"'<>?{}[]"]* ]] && parts[i]='${(Q)${:-'${(qqq)${(q)parts[i]}}'}}'
						parts[i]+=$'\2'
					done
				fi
				_p9k_cache_ephemeral_set "$key" "${parts[@]}"
			fi
			parts=("${(@)_p9k__cache_val[2,-1]}")  ;;
		(truncate_with_folder_marker) if [[ -n $_POWERLEVEL9K_SHORTEN_FOLDER_MARKER ]]
			then
				local dir=$_p9k__cwd
				local -a m=()
				local -i i=$(($#parts - 1))
				for ((; i > 1; --i )) do
					dir=${dir:h}
					[[ -n $dir/${~_POWERLEVEL9K_SHORTEN_FOLDER_MARKER}(#qN) ]] && m+=$i
				done
				m+=1
				for ((i=1; i < $#m; ++i )) do
					(( m[i] - m[i+1] > 2 )) && parts[m[i+1]+1,m[i]-1]=($'\1')
				done
			fi ;;
		(*) if (( shortenlen > 0 ))
			then
				local -i len=$#parts
				[[ -z $parts[1] ]] && (( --len ))
				if (( len > shortenlen ))
				then
					parts[1,-shortenlen-1]=($'\1')
				fi
			fi ;;
	esac
	(( !_POWERLEVEL9K_DIR_SHOW_WRITABLE )) || [[ -w $_p9k__cwd ]]
	local -i w=$?
	(( w && _POWERLEVEL9K_DIR_SHOW_WRITABLE > 2 )) && [[ ! -e $_p9k__cwd ]] && w=2
	if ! _p9k_cache_ephemeral_get $0 $_p9k__cwd $p $w $fake_first "${parts[@]}"
	then
		local state=$0
		local icon=''
		local a='' b='' c=''
		for a b c in "${_POWERLEVEL9K_DIR_CLASSES[@]}"
		do
			if [[ $_p9k__cwd == ${~a} ]]
			then
				[[ -n $b ]] && state+=_${${(U)b}//İ/I}
				icon=$'\1'$c
				break
			fi
		done
		if (( w ))
		then
			if (( _POWERLEVEL9K_DIR_SHOW_WRITABLE == 1 ))
			then
				state=${0}_NOT_WRITABLE
			elif (( w == 2 ))
			then
				state+=_NON_EXISTENT
			else
				state+=_NOT_WRITABLE
			fi
			icon=LOCK_ICON
		fi
		local state_u=${${(U)state}//İ/I}
		local style=%b
		_p9k_color $state BACKGROUND blue
		_p9k_background $_p9k__ret
		style+=$_p9k__ret
		_p9k_color $state FOREGROUND "$_p9k_color1"
		_p9k_foreground $_p9k__ret
		style+=$_p9k__ret
		if (( expand ))
		then
			_p9k_escape_style $style
			style=$_p9k__ret
		fi
		parts=("${(@)parts//\%/%%}")
		if [[ $_POWERLEVEL9K_HOME_FOLDER_ABBREVIATION != '~' && $fake_first == 0 && $p == ('~'|'~/'*) ]]
		then
			(( expand )) && _p9k_escape $_POWERLEVEL9K_HOME_FOLDER_ABBREVIATION || _p9k__ret=$_POWERLEVEL9K_HOME_FOLDER_ABBREVIATION
			parts[1]=$_p9k__ret
			[[ $_p9k__ret == *%* ]] && parts[1]+=$style
		elif [[ $_POWERLEVEL9K_DIR_OMIT_FIRST_CHARACTER == 1 && $fake_first == 0 && $#parts > 1 && -z $parts[1] && -n $parts[2] ]]
		then
			parts[1]=()
		fi
		local last_style=
		_p9k_param $state PATH_HIGHLIGHT_BOLD ''
		[[ $_p9k__ret == true ]] && last_style+=%B
		if (( $+parameters[_POWERLEVEL9K_DIR_PATH_HIGHLIGHT_FOREGROUND] ||
          $+parameters[_POWERLEVEL9K_${state_u}_PATH_HIGHLIGHT_FOREGROUND] ))
		then
			_p9k_color $state PATH_HIGHLIGHT_FOREGROUND ''
			_p9k_foreground $_p9k__ret
			last_style+=$_p9k__ret
		fi
		if [[ -n $last_style ]]
		then
			(( expand )) && _p9k_escape_style $last_style || _p9k__ret=$last_style
			parts[-1]=$_p9k__ret${parts[-1]//$'\1'/$'\1'$_p9k__ret}$style
		fi
		local anchor_style=
		_p9k_param $state ANCHOR_BOLD ''
		[[ $_p9k__ret == true ]] && anchor_style+=%B
		if (( $+parameters[_POWERLEVEL9K_DIR_ANCHOR_FOREGROUND] ||
          $+parameters[_POWERLEVEL9K_${state_u}_ANCHOR_FOREGROUND] ))
		then
			_p9k_color $state ANCHOR_FOREGROUND ''
			_p9k_foreground $_p9k__ret
			anchor_style+=$_p9k__ret
		fi
		if [[ -n $anchor_style ]]
		then
			(( expand )) && _p9k_escape_style $anchor_style || _p9k__ret=$anchor_style
			if [[ -z $last_style ]]
			then
				parts=("${(@)parts/%(#b)(*)$'\2'/$_p9k__ret$match[1]$style}")
			else
				(( $#parts > 1 )) && parts[1,-2]=("${(@)parts[1,-2]/%(#b)(*)$'\2'/$_p9k__ret$match[1]$style}")
				parts[-1]=${parts[-1]/$'\2'}
			fi
		else
			parts=("${(@)parts/$'\2'}")
		fi
		if (( $+parameters[_POWERLEVEL9K_DIR_SHORTENED_FOREGROUND] ||
          $+parameters[_POWERLEVEL9K_${state_u}_SHORTENED_FOREGROUND] ))
		then
			_p9k_color $state SHORTENED_FOREGROUND ''
			_p9k_foreground $_p9k__ret
			(( expand )) && _p9k_escape_style $_p9k__ret
			local shortened_fg=$_p9k__ret
			(( expand )) && _p9k_escape $delim || _p9k__ret=$delim
			[[ $_p9k__ret == *%* ]] && _p9k__ret+=$style$shortened_fg
			parts=("${(@)parts/(#b)$'\3'(*)$'\1'(*)$'\3'/$shortened_fg$match[1]$_p9k__ret$match[2]$style}")
			parts=("${(@)parts/(#b)(*)$'\1'(*)/$shortened_fg$match[1]$_p9k__ret$match[2]$style}")
		else
			(( expand )) && _p9k_escape $delim || _p9k__ret=$delim
			[[ $_p9k__ret == *%* ]] && _p9k__ret+=$style
			parts=("${(@)parts/$'\1'/$_p9k__ret}")
			parts=("${(@)parts//$'\3'}")
		fi
		if [[ $_p9k__cwd == / && $_POWERLEVEL9K_DIR_OMIT_FIRST_CHARACTER == 1 ]]
		then
			local sep='/'
		else
			local sep=''
			if (( $+parameters[_POWERLEVEL9K_DIR_PATH_SEPARATOR_FOREGROUND] ||
            $+parameters[_POWERLEVEL9K_${state_u}_PATH_SEPARATOR_FOREGROUND] ))
			then
				_p9k_color $state PATH_SEPARATOR_FOREGROUND ''
				_p9k_foreground $_p9k__ret
				(( expand )) && _p9k_escape_style $_p9k__ret
				sep=$_p9k__ret
			fi
			_p9k_param $state PATH_SEPARATOR /
			_p9k__ret=${(g::)_p9k__ret}
			(( expand )) && _p9k_escape $_p9k__ret
			sep+=$_p9k__ret
			[[ $sep == *%* ]] && sep+=$style
		fi
		local content="${(pj.$sep.)parts}"
		if (( _POWERLEVEL9K_DIR_HYPERLINK && _p9k_term_has_href )) && [[ $_p9k__cwd == /* ]]
		then
			_p9k_url_escape $_p9k__cwd
			local header=$'%{\e]8;;file://'$_p9k__ret$'\a%}'
			local footer=$'%{\e]8;;\a%}'
			if (( expand ))
			then
				_p9k_escape $header
				header=$_p9k__ret
				_p9k_escape $footer
				footer=$_p9k__ret
			fi
			content=$header$content$footer
		fi
		(( expand )) && _p9k_prompt_length "${(e):-"\${\${_p9k__d::=0}+}$content"}" || _p9k__ret=
		_p9k_cache_ephemeral_set "$state" "$icon" "$expand" "$content" $_p9k__ret
	fi
	if (( _p9k__cache_val[3] ))
	then
		if (( $+_p9k__dir ))
		then
			_p9k__cache_val[4]='${${_p9k__d::=-1024}+}'$_p9k__cache_val[4]
		else
			_p9k__dir=$_p9k__cache_val[4]
			_p9k__dir_len=$_p9k__cache_val[5]
			_p9k__cache_val[4]='%{d%}'$_p9k__cache_val[4]'%{d%}'
		fi
	fi
	_p9k_prompt_segment "$_p9k__cache_val[1]" "blue" "$_p9k_color1" "$_p9k__cache_val[2]" "$_p9k__cache_val[3]" "" "$_p9k__cache_val[4]"
}
prompt_dir_writable () {
	if [[ ! -w "$_p9k__cwd_a" ]]
	then
		_p9k_prompt_segment "$0_FORBIDDEN" "red" "yellow1" 'LOCK_ICON' 0 '' ''
	fi
}
prompt_direnv () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment $0 $_p9k_color1 yellow DIRENV_ICON 0 '$DIRENV_DIR' ''
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_disk_usage () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment $0_CRITICAL red white DISK_ICON 1 '$_p9k__disk_usage_critical' '$_p9k__disk_usage_pct%%'
	_p9k_prompt_segment $0_WARNING yellow $_p9k_color1 DISK_ICON 1 '$_p9k__disk_usage_warning' '$_p9k__disk_usage_pct%%'
	if (( ! _POWERLEVEL9K_DISK_USAGE_ONLY_WARNING ))
	then
		_p9k_prompt_segment $0_NORMAL $_p9k_color1 yellow DISK_ICON 1 '$_p9k__disk_usage_normal' '$_p9k__disk_usage_pct%%'
	fi
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_docker_machine () {
	_p9k_prompt_segment "$0" "magenta" "$_p9k_color1" 'SERVER_ICON' 0 '' "${DOCKER_MACHINE_NAME//\%/%%}"
}
prompt_dotnet_version () {
	if (( _POWERLEVEL9K_DOTNET_VERSION_PROJECT_ONLY ))
	then
		_p9k_upglob 'project.json|global.json|packet.dependencies|*.csproj|*.fsproj|*.xproj|*.sln' && return
	fi
	_p9k_cached_cmd 0 '' dotnet --version || return
	_p9k_prompt_segment "$0" "magenta" "white" 'DOTNET_ICON' 0 '' "$_p9k__ret"
}
prompt_dropbox () {
	local dropbox_status="$(dropbox-cli filestatus . | cut -d\  -f2-)"
	if [[ "$dropbox_status" != 'unwatched' && "$dropbox_status" != "isn't running!" ]]
	then
		if [[ "$dropbox_status" =~ 'up to date' ]]
		then
			dropbox_status=""
		fi
		_p9k_prompt_segment "$0" "white" "blue" "DROPBOX_ICON" 0 '' "${dropbox_status//\%/%%}"
	fi
}
prompt_end () {
	if [[ -n $CURRENT_BG ]]
	then
		echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
	else
		echo -n "%{%k%}"
	fi
	echo -n "%{%f%}"
	CURRENT_BG=''
}
prompt_example () {
	p10k segment -b 1 -f 3 -i '⭐' -t 'hello, %n'
}
prompt_fvm () {
	_p9k_fvm_new || _p9k_fvm_old
}
prompt_gcloud () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment $0_PARTIAL blue white GCLOUD_ICON 1 '${${(M)${#P9K_GCLOUD_PROJECT_NAME}:#0}:+$P9K_GCLOUD_ACCOUNT$P9K_GCLOUD_PROJECT_ID}' '${P9K_GCLOUD_ACCOUNT//\%/%%}:${P9K_GCLOUD_PROJECT_ID//\%/%%}'
	_p9k_prompt_segment $0_COMPLETE blue white GCLOUD_ICON 1 '$P9K_GCLOUD_PROJECT_NAME' '${P9K_GCLOUD_ACCOUNT//\%/%%}:${P9K_GCLOUD_PROJECT_ID//\%/%%}'
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_git () {
	(( $+commands[git] )) || return
	if [[ "$(git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]
	then
		return
	fi
	local PL_BRANCH_CHAR
	() {
		local LC_ALL="" LC_CTYPE="en_US.UTF-8"
		PL_BRANCH_CHAR=$'\ue0a0'
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
	fi
}
prompt_go_version () {
	_p9k_cached_cmd 0 '' go version || return
	[[ $_p9k__ret == (#b)*go([[:digit:].]##)* ]] || return
	local v=$match[1]
	if (( _POWERLEVEL9K_GO_VERSION_PROJECT_ONLY ))
	then
		local p=$GOPATH
		if [[ -z $p ]]
		then
			if [[ -d $HOME/go ]]
			then
				p=$HOME/go
			else
				p="$(go env GOPATH 2>/dev/null)"  && [[ -n $p ]] || return
			fi
		fi
		if [[ $_p9k__cwd/ != $p/* && $_p9k__cwd_a/ != $p/* ]]
		then
			_p9k_upglob go.mod && return
		fi
	fi
	_p9k_prompt_segment "$0" "green" "grey93" "GO_ICON" 0 '' "${v//\%/%%}"
}
prompt_goenv () {
	local v=${(j.:.)${(@)${(s.:.)GOENV_VERSION}#go-}}
	if [[ -n $v ]]
	then
		(( ${_POWERLEVEL9K_GOENV_SOURCES[(I)shell]} )) || return
	else
		(( ${_POWERLEVEL9K_GOENV_SOURCES[(I)local|global]} )) || return
		_p9k__ret=
		if [[ $GOENV_DIR != (|.) ]]
		then
			[[ $GOENV_DIR == /* ]] && local dir=$GOENV_DIR  || local dir="$_p9k__cwd_a/$GOENV_DIR"
			dir=${dir:A}
			if [[ $dir != $_p9k__cwd_a ]]
			then
				while true
				do
					if _p9k_read_pyenv_like_version_file $dir/.go-version go-
					then
						(( ${_POWERLEVEL9K_GOENV_SOURCES[(I)local]} )) || return
						break
					fi
					[[ $dir == (/|.) ]] && break
					dir=${dir:h}
				done
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			_p9k_upglob .go-version
			local -i idx=$?
			if (( idx )) && _p9k_read_pyenv_like_version_file $_p9k__parent_dirs[idx]/.go-version go-
			then
				(( ${_POWERLEVEL9K_GOENV_SOURCES[(I)local]} )) || return
			else
				_p9k__ret=
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			(( _POWERLEVEL9K_GOENV_PROMPT_ALWAYS_SHOW )) || return
			(( ${_POWERLEVEL9K_GOENV_SOURCES[(I)global]} )) || return
			_p9k_goenv_global_version
		fi
		v=$_p9k__ret
	fi
	if (( !_POWERLEVEL9K_GOENV_PROMPT_ALWAYS_SHOW ))
	then
		_p9k_goenv_global_version
		[[ $v == $_p9k__ret ]] && return
	fi
	if (( !_POWERLEVEL9K_GOENV_SHOW_SYSTEM ))
	then
		[[ $v == system ]] && return
	fi
	_p9k_prompt_segment "$0" "blue" "$_p9k_color1" 'GO_ICON' 0 '' "${v//\%/%%}"
}
prompt_google_app_cred () {
	unset P9K_GOOGLE_APP_CRED_{TYPE,PROJECT_ID,CLIENT_EMAIL}
	if ! _p9k_cache_stat_get $0 $GOOGLE_APPLICATION_CREDENTIALS
	then
		local -a lines
		local q='[.type//"", .project_id//"", .client_email//"", 0][]'
		if lines=("${(@f)$(jq -r $q <$GOOGLE_APPLICATION_CREDENTIALS 2>/dev/null)}")  && (( $#lines == 4 ))
		then
			local text="${(j.:.)lines[1,-2]}"
			local pat class state
			for pat class in "${_POWERLEVEL9K_GOOGLE_APP_CRED_CLASSES[@]}"
			do
				if [[ $text == ${~pat} ]]
				then
					[[ -n $class ]] && state=_${${(U)class}//İ/I}
					break
				fi
			done
			_p9k_cache_stat_set 1 "${(@)lines[1,-2]}" "$text" "$state"
		else
			_p9k_cache_stat_set 0
		fi
	fi
	(( _p9k__cache_val[1] )) || return
	P9K_GOOGLE_APP_CRED_TYPE=$_p9k__cache_val[2]
	P9K_GOOGLE_APP_CRED_PROJECT_ID=$_p9k__cache_val[3]
	P9K_GOOGLE_APP_CRED_CLIENT_EMAIL=$_p9k__cache_val[4]
	_p9k_prompt_segment "$0$_p9k__cache_val[6]" "blue" "white" "GCLOUD_ICON" 0 '' "$_p9k__cache_val[5]"
}
prompt_haskell_stack () {
	if [[ -n $STACK_YAML ]]
	then
		(( ${_POWERLEVEL9K_HASKELL_STACK_SOURCES[(I)shell]} )) || return
		_p9k_haskell_stack_version $STACK_YAML
	else
		(( ${_POWERLEVEL9K_HASKELL_STACK_SOURCES[(I)local|global]} )) || return
		if _p9k_upglob stack.yaml
		then
			(( _POWERLEVEL9K_HASKELL_STACK_PROMPT_ALWAYS_SHOW )) || return
			(( ${_POWERLEVEL9K_HASKELL_STACK_SOURCES[(I)global]} )) || return
			_p9k_haskell_stack_version ${STACK_ROOT:-~/.stack}/global-project/stack.yaml
		else
			local -i idx=$?
			(( ${_POWERLEVEL9K_HASKELL_STACK_SOURCES[(I)local]} )) || return
			_p9k_haskell_stack_version $_p9k__parent_dirs[idx]/stack.yaml
		fi
	fi
	[[ -n $_p9k__ret ]] || return
	local v=$_p9k__ret
	if (( !_POWERLEVEL9K_HASKELL_STACK_PROMPT_ALWAYS_SHOW ))
	then
		_p9k_haskell_stack_version ${STACK_ROOT:-~/.stack}/global-project/stack.yaml
		[[ $v == $_p9k__ret ]] && return
	fi
	_p9k_prompt_segment "$0" "yellow" "$_p9k_color1" 'HASKELL_ICON' 0 '' "${v//\%/%%}"
}
prompt_hg () {
	(( $+commands[hg] )) || return
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
	fi
}
prompt_history () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment "$0" "grey50" "$_p9k_color1" '' 0 '' '%h'
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_host () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	if (( P9K_SSH ))
	then
		_p9k_prompt_segment "$0_REMOTE" "${_p9k_color1}" yellow SSH_ICON 0 '' "$_POWERLEVEL9K_HOST_TEMPLATE"
	else
		_p9k_prompt_segment "$0_LOCAL" "${_p9k_color1}" yellow HOST_ICON 0 '' "$_POWERLEVEL9K_HOST_TEMPLATE"
	fi
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_ip () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment "$0" "cyan" "$_p9k_color1" 'NETWORK_ICON' 1 '$P9K_IP_IP' '$P9K_IP_IP'
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_java_version () {
	if (( _POWERLEVEL9K_JAVA_VERSION_PROJECT_ONLY ))
	then
		_p9k_upglob 'pom.xml|build.gradle.kts|build.sbt|deps.edn|project.clj|build.boot|*.(java|class|jar|gradle|clj|cljc)' && return
	fi
	local java=$commands[java]
	if ! _p9k_cache_stat_get $0 $java ${JAVA_HOME:+$JAVA_HOME/release}
	then
		local v
		v="$(java -fullversion 2>&1)"  || v=
		v=${${v#*\"}%\"*}
		(( _POWERLEVEL9K_JAVA_VERSION_FULL )) || v=${v%%-*}
		_p9k_cache_stat_set "${v//\%/%%}"
	fi
	[[ -n $_p9k__cache_val[1] ]] || return
	_p9k_prompt_segment "$0" "red" "white" "JAVA_ICON" 0 '' $_p9k__cache_val[1]
}
prompt_jenv () {
	if [[ -n $JENV_VERSION ]]
	then
		(( ${_POWERLEVEL9K_JENV_SOURCES[(I)shell]} )) || return
		local v=$JENV_VERSION
	else
		(( ${_POWERLEVEL9K_JENV_SOURCES[(I)local|global]} )) || return
		_p9k__ret=
		if [[ $JENV_DIR != (|.) ]]
		then
			[[ $JENV_DIR == /* ]] && local dir=$JENV_DIR  || local dir="$_p9k__cwd_a/$JENV_DIR"
			dir=${dir:A}
			if [[ $dir != $_p9k__cwd_a ]]
			then
				while true
				do
					if _p9k_read_word $dir/.java-version
					then
						(( ${_POWERLEVEL9K_JENV_SOURCES[(I)local]} )) || return
						break
					fi
					[[ $dir == (/|.) ]] && break
					dir=${dir:h}
				done
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			_p9k_upglob .java-version
			local -i idx=$?
			if (( idx )) && _p9k_read_word $_p9k__parent_dirs[idx]/.java-version
			then
				(( ${_POWERLEVEL9K_JENV_SOURCES[(I)local]} )) || return
			else
				_p9k__ret=
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			(( _POWERLEVEL9K_JENV_PROMPT_ALWAYS_SHOW )) || return
			(( ${_POWERLEVEL9K_JENV_SOURCES[(I)global]} )) || return
			_p9k_jenv_global_version
		fi
		local v=$_p9k__ret
	fi
	if (( !_POWERLEVEL9K_JENV_PROMPT_ALWAYS_SHOW ))
	then
		_p9k_jenv_global_version
		[[ $v == $_p9k__ret ]] && return
	fi
	if (( !_POWERLEVEL9K_JENV_SHOW_SYSTEM ))
	then
		[[ $v == system ]] && return
	fi
	_p9k_prompt_segment "$0" white red 'JAVA_ICON' 0 '' "${v//\%/%%}"
}
prompt_kubecontext () {
	if ! _p9k_cache_stat_get $0 ${(s.:.)${KUBECONFIG:-$HOME/.kube/config}}
	then
		local name namespace cluster user cloud_name cloud_account cloud_zone cloud_cluster text state
		() {
			local cfg && cfg=(${(f)"$(kubectl config view -o=yaml 2>/dev/null)"})  || return
			local qstr='"*"'
			local str='([^"'\''|>]*|'$qstr')'
			local ctx=(${(@M)cfg:#current-context: $~str})
			(( $#ctx == 1 )) || return
			name=${ctx[1]#current-context: }
			local -i pos=${cfg[(i)contexts:]}
			{
				(( pos <= $#cfg )) || return
				shift $pos cfg
				pos=${cfg[(i)  name: $name]}
				(( pos <= $#cfg )) || return
				(( --pos ))
				for ((; pos > 0; --pos)) do
					local line=$cfg[pos]
					if [[ $line == '- context:' ]]
					then
						return 0
					elif [[ $line == (#b)'    cluster: '($~str) ]]
					then
						cluster=$match[1]
						[[ $cluster == $~qstr ]] && cluster=$cluster[2,-2]
					elif [[ $line == (#b)'    namespace: '($~str) ]]
					then
						namespace=$match[1]
						[[ $namespace == $~qstr ]] && namespace=$namespace[2,-2]
					elif [[ $line == (#b)'    user: '($~str) ]]
					then
						user=$match[1]
						[[ $user == $~qstr ]] && user=$user[2,-2]
					fi
				done
			} always {
				[[ $name == $~qstr ]] && name=$name[2,-2]
			}
		}
		if [[ -n $name ]]
		then
			: ${namespace:=default}
			if [[ $cluster == (#b)gke_(?*)_(asia|australia|europe|northamerica|southamerica|us)-([a-z]##<->)(-[a-z]|)_(?*) ]]
			then
				cloud_name=gke
				cloud_account=$match[1]
				cloud_zone=$match[2]-$match[3]$match[4]
				cloud_cluster=$match[5]
				if (( ${_POWERLEVEL9K_KUBECONTEXT_SHORTEN[(I)gke]} ))
				then
					text=$cloud_cluster
				fi
			elif [[ $cluster == (#b)arn:aws:eks:([[:alnum:]-]##):([[:digit:]]##):cluster/(?*) ]]
			then
				cloud_name=eks
				cloud_zone=$match[1]
				cloud_account=$match[2]
				cloud_cluster=$match[3]
				if (( ${_POWERLEVEL9K_KUBECONTEXT_SHORTEN[(I)eks]} ))
				then
					text=$cloud_cluster
				fi
			fi
			if [[ -z $text ]]
			then
				text=$name
				if [[ $_POWERLEVEL9K_KUBECONTEXT_SHOW_DEFAULT_NAMESPACE == 1 || $namespace != (default|$name) ]]
				then
					text+="/$namespace"
				fi
			fi
			local pat class
			for pat class in "${_POWERLEVEL9K_KUBECONTEXT_CLASSES[@]}"
			do
				if [[ $text == ${~pat} ]]
				then
					[[ -n $class ]] && state=_${${(U)class}//İ/I}
					break
				fi
			done
		fi
		_p9k_cache_stat_set "${(g::)name}" "${(g::)namespace}" "${(g::)cluster}" "${(g::)user}" "${(g::)cloud_name}" "${(g::)cloud_account}" "${(g::)cloud_zone}" "${(g::)cloud_cluster}" "${(g::)text}" "$state"
	fi
	typeset -g P9K_KUBECONTEXT_NAME=$_p9k__cache_val[1]
	typeset -g P9K_KUBECONTEXT_NAMESPACE=$_p9k__cache_val[2]
	typeset -g P9K_KUBECONTEXT_CLUSTER=$_p9k__cache_val[3]
	typeset -g P9K_KUBECONTEXT_USER=$_p9k__cache_val[4]
	typeset -g P9K_KUBECONTEXT_CLOUD_NAME=$_p9k__cache_val[5]
	typeset -g P9K_KUBECONTEXT_CLOUD_ACCOUNT=$_p9k__cache_val[6]
	typeset -g P9K_KUBECONTEXT_CLOUD_ZONE=$_p9k__cache_val[7]
	typeset -g P9K_KUBECONTEXT_CLOUD_CLUSTER=$_p9k__cache_val[8]
	[[ -n $_p9k__cache_val[9] ]] || return
	_p9k_prompt_segment $0$_p9k__cache_val[10] magenta white KUBERNETES_ICON 0 '' "${_p9k__cache_val[9]//\%/%%}"
}
prompt_laravel_version () {
	_p9k_upglob artisan && return
	local dir=$_p9k__parent_dirs[$?]
	local app=$dir/vendor/laravel/framework/src/Illuminate/Foundation/Application.php
	[[ -r $app ]] || return
	if ! _p9k_cache_stat_get $0 $dir/artisan $app
	then
		local v="$(php $dir/artisan --version 2> /dev/null)"
		_p9k_cache_stat_set "${${(M)v:#Laravel Framework *}#Laravel Framework }"
	fi
	[[ -n $_p9k__cache_val[1] ]] || return
	_p9k_prompt_segment "$0" "maroon" "white" 'LARAVEL_ICON' 0 '' "${_p9k__cache_val[1]//\%/%%}"
}
prompt_load () {
	if [[ $_p9k_os == (OSX|BSD) ]]
	then
		local -i len=$#_p9k__prompt _p9k__has_upglob
		_p9k_prompt_segment $0_CRITICAL red "$_p9k_color1" LOAD_ICON 1 '$_p9k__load_critical' '$_p9k__load_value'
		_p9k_prompt_segment $0_WARNING yellow "$_p9k_color1" LOAD_ICON 1 '$_p9k__load_warning' '$_p9k__load_value'
		_p9k_prompt_segment $0_NORMAL green "$_p9k_color1" LOAD_ICON 1 '$_p9k__load_normal' '$_p9k__load_value'
		(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
		return
	fi
	[[ -r /proc/loadavg ]] || return
	_p9k_read_file /proc/loadavg || return
	local load=${${(A)=_p9k__ret}[_POWERLEVEL9K_LOAD_WHICH]//,/.}
	local -F pct='100. * load / _p9k_num_cpus'
	if (( pct > _POWERLEVEL9K_LOAD_CRITICAL_PCT ))
	then
		_p9k_prompt_segment $0_CRITICAL red "$_p9k_color1" LOAD_ICON 0 '' $load
	elif (( pct > _POWERLEVEL9K_LOAD_WARNING_PCT ))
	then
		_p9k_prompt_segment $0_WARNING yellow "$_p9k_color1" LOAD_ICON 0 '' $load
	else
		_p9k_prompt_segment $0_NORMAL green "$_p9k_color1" LOAD_ICON 0 '' $load
	fi
}
prompt_luaenv () {
	if [[ -n $LUAENV_VERSION ]]
	then
		(( ${_POWERLEVEL9K_LUAENV_SOURCES[(I)shell]} )) || return
		local v=$LUAENV_VERSION
	else
		(( ${_POWERLEVEL9K_LUAENV_SOURCES[(I)local|global]} )) || return
		_p9k__ret=
		if [[ $LUAENV_DIR != (|.) ]]
		then
			[[ $LUAENV_DIR == /* ]] && local dir=$LUAENV_DIR  || local dir="$_p9k__cwd_a/$LUAENV_DIR"
			dir=${dir:A}
			if [[ $dir != $_p9k__cwd_a ]]
			then
				while true
				do
					if _p9k_read_word $dir/.lua-version
					then
						(( ${_POWERLEVEL9K_LUAENV_SOURCES[(I)local]} )) || return
						break
					fi
					[[ $dir == (/|.) ]] && break
					dir=${dir:h}
				done
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			_p9k_upglob .lua-version
			local -i idx=$?
			if (( idx )) && _p9k_read_word $_p9k__parent_dirs[idx]/.lua-version
			then
				(( ${_POWERLEVEL9K_LUAENV_SOURCES[(I)local]} )) || return
			else
				_p9k__ret=
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			(( _POWERLEVEL9K_LUAENV_PROMPT_ALWAYS_SHOW )) || return
			(( ${_POWERLEVEL9K_LUAENV_SOURCES[(I)global]} )) || return
			_p9k_luaenv_global_version
		fi
		local v=$_p9k__ret
	fi
	if (( !_POWERLEVEL9K_LUAENV_PROMPT_ALWAYS_SHOW ))
	then
		_p9k_luaenv_global_version
		[[ $v == $_p9k__ret ]] && return
	fi
	if (( !_POWERLEVEL9K_LUAENV_SHOW_SYSTEM ))
	then
		[[ $v == system ]] && return
	fi
	_p9k_prompt_segment "$0" blue "$_p9k_color1" 'LUA_ICON' 0 '' "${v//\%/%%}"
}
prompt_midnight_commander () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment $0 $_p9k_color1 yellow MIDNIGHT_COMMANDER_ICON 0 '' ''
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_nix_shell () {
	_p9k_prompt_segment $0 4 $_p9k_color1 NIX_SHELL_ICON 0 '' "${(M)IN_NIX_SHELL:#(pure|impure)}"
}
prompt_nnn () {
	_p9k_prompt_segment $0 6 $_p9k_color1 NNN_ICON 0 '' $NNNLVL
}
prompt_node_version () {
	_p9k_upglob package.json
	local -i idx=$?
	if (( idx ))
	then
		_p9k_cached_cmd 0 $_p9k__parent_dirs[idx]/package.json node --version || return
	else
		(( _POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY )) && return
		_p9k_cached_cmd 0 '' node --version || return
	fi
	[[ $_p9k__ret == v?* ]] || return
	_p9k_prompt_segment "$0" "green" "white" 'NODE_ICON' 0 '' "${_p9k__ret#v}"
}
prompt_nodeenv () {
	local msg
	if (( _POWERLEVEL9K_NODEENV_SHOW_NODE_VERSION )) && _p9k_cached_cmd 0 '' node --version
	then
		msg="${_p9k__ret//\%/%%} "
	fi
	msg+="$_POWERLEVEL9K_NODEENV_LEFT_DELIMITER${${NODE_VIRTUAL_ENV:t}//\%/%%}$_POWERLEVEL9K_NODEENV_RIGHT_DELIMITER"
	_p9k_prompt_segment "$0" "black" "green" 'NODE_ICON' 0 '' "$msg"
}
prompt_nodenv () {
	if [[ -n $NODENV_VERSION ]]
	then
		(( ${_POWERLEVEL9K_NODENV_SOURCES[(I)shell]} )) || return
		local v=$NODENV_VERSION
	else
		(( ${_POWERLEVEL9K_NODENV_SOURCES[(I)local|global]} )) || return
		_p9k__ret=
		if [[ $NODENV_DIR != (|.) ]]
		then
			[[ $NODENV_DIR == /* ]] && local dir=$NODENV_DIR  || local dir="$_p9k__cwd_a/$NODENV_DIR"
			dir=${dir:A}
			if [[ $dir != $_p9k__cwd_a ]]
			then
				while true
				do
					if _p9k_read_word $dir/.node-version
					then
						(( ${_POWERLEVEL9K_NODENV_SOURCES[(I)local]} )) || return
						break
					fi
					[[ $dir == (/|.) ]] && break
					dir=${dir:h}
				done
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			_p9k_upglob .node-version
			local -i idx=$?
			if (( idx )) && _p9k_read_word $_p9k__parent_dirs[idx]/.node-version
			then
				(( ${_POWERLEVEL9K_NODENV_SOURCES[(I)local]} )) || return
			else
				_p9k__ret=
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			(( _POWERLEVEL9K_NODENV_PROMPT_ALWAYS_SHOW )) || return
			(( ${_POWERLEVEL9K_NODENV_SOURCES[(I)global]} )) || return
			_p9k_nodenv_global_version
		fi
		_p9k_nodeenv_version_transform $_p9k__ret || return
		local v=$_p9k__ret
	fi
	if (( !_POWERLEVEL9K_NODENV_PROMPT_ALWAYS_SHOW ))
	then
		_p9k_nodenv_global_version
		_p9k_nodeenv_version_transform $_p9k__ret && [[ $v == $_p9k__ret ]] && return
	fi
	if (( !_POWERLEVEL9K_NODENV_SHOW_SYSTEM ))
	then
		[[ $v == system ]] && return
	fi
	_p9k_prompt_segment "$0" "black" "green" 'NODE_ICON' 0 '' "${v//\%/%%}"
}
prompt_nordvpn () {
	unset $__p9k_nordvpn_tag P9K_NORDVPN_COUNTRY_CODE
	[[ -e /run/nordvpn/nordvpnd.sock ]] || return
	_p9k_fetch_nordvpn_status 2> /dev/null || return
	if [[ $P9K_NORDVPN_SERVER == (#b)([[:alpha:]]##)[[:digit:]]##.nordvpn.com ]]
	then
		typeset -g P9K_NORDVPN_COUNTRY_CODE=${${(U)match[1]}//İ/I}
	fi
	case $P9K_NORDVPN_STATUS in
		(Connected) _p9k_prompt_segment $0_CONNECTED blue white NORDVPN_ICON 0 '' "$P9K_NORDVPN_COUNTRY_CODE" ;;
		(Disconnected | Connecting | Disconnecting) local state=${${(U)P9K_NORDVPN_STATUS}//İ/I}
			_p9k_get_icon $0_$state FAIL_ICON
			_p9k_prompt_segment $0_$state yellow white NORDVPN_ICON 0 '' "$_p9k__ret" ;;
		(*) return ;;
	esac
}
prompt_nvm () {
	[[ -n $NVM_DIR ]] && _p9k_nvm_ls_current || return
	local current=$_p9k__ret
	! _p9k_nvm_ls_default || [[ $_p9k__ret != $current ]] || return
	_p9k_prompt_segment "$0" "magenta" "black" 'NODE_ICON' 0 '' "${${current#v}//\%/%%}"
}
prompt_openfoam () {
	if [[ -z "$WM_FORK" ]]
	then
		_p9k_prompt_segment "$0" "yellow" "$_p9k_color1" '' 0 '' "OF: ${${WM_PROJECT_VERSION:t}//\%/%%}"
	else
		_p9k_prompt_segment "$0" "yellow" "$_p9k_color1" '' 0 '' "F-X: ${${WM_PROJECT_VERSION:t}//\%/%%}"
	fi
}
prompt_os_icon () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment "$0" "black" "white" '' 0 '' "$_p9k_os_icon"
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_package () {
	unset P9K_PACKAGE_NAME P9K_PACKAGE_VERSION
	_p9k_upglob package.json && return
	local file=$_p9k__parent_dirs[$?]/package.json
	if ! _p9k_cache_stat_get $0 $file
	then
		() {
			local data field
			local -A found
			{
				data="$(<$file)"  || return
			} 2> /dev/null
			data=${${data//$'\r'}##[[:space:]]#}
			[[ $data == '{'* ]] || return
			data[1]=
			local -i depth=1
			while true
			do
				data=${data##[[:space:]]#}
				[[ -n $data ]] || return
				case $data[1] in
					('{' | '[') data[1]=
						(( ++depth )) ;;
					('}' | ']') data[1]=
						(( --depth > 0 )) || return ;;
					(':') data[1]=  ;;
					(',') data[1]=
						field=  ;;
					([[:alnum:].]) data=${data##[[:alnum:].]#}  ;;
					('"') local tail=${data##\"([^\"\\]|\\?)#}
						[[ $tail == '"'* ]] || return
						local s=${data:1:-$#tail}
						data=${tail:1}
						(( depth == 1 )) || continue
						if [[ -z $field ]]
						then
							field=${s:-x}
						elif [[ $field == (name|version) ]]
						then
							(( ! $+found[$field] )) || return
							[[ -n $s ]] || return
							[[ $s != *($'\n'|'\')* ]] || return
							found[$field]=$s
							(( $#found == 2 )) && break
						fi ;;
					(*) return 1 ;;
				esac
			done
			_p9k_cache_stat_set 1 $found[name] $found[version]
			return 0
		} || _p9k_cache_stat_set 0
	fi
	(( _p9k__cache_val[1] )) || return
	P9K_PACKAGE_NAME=$_p9k__cache_val[2]
	P9K_PACKAGE_VERSION=$_p9k__cache_val[3]
	_p9k_prompt_segment "$0" "cyan" "$_p9k_color1" PACKAGE_ICON 0 '' ${P9K_PACKAGE_VERSION//\%/%%}
}
prompt_php_version () {
	if (( _POWERLEVEL9K_PHP_VERSION_PROJECT_ONLY ))
	then
		_p9k_upglob 'composer.json|*.php' && return
	fi
	_p9k_cached_cmd 0 '' php --version || return
	[[ $_p9k__ret == (#b)(*$'\n')#'PHP '([[:digit:].]##)* ]] || return
	local v=$match[2]
	_p9k_prompt_segment "$0" "fuchsia" "grey93" 'PHP_ICON' 0 '' "${v//\%/%%}"
}
prompt_phpenv () {
	if [[ -n $PHPENV_VERSION ]]
	then
		(( ${_POWERLEVEL9K_PHPENV_SOURCES[(I)shell]} )) || return
		local v=$PHPENV_VERSION
	else
		(( ${_POWERLEVEL9K_PHPENV_SOURCES[(I)local|global]} )) || return
		_p9k__ret=
		if [[ $PHPENV_DIR != (|.) ]]
		then
			[[ $PHPENV_DIR == /* ]] && local dir=$PHPENV_DIR  || local dir="$_p9k__cwd_a/$PHPENV_DIR"
			dir=${dir:A}
			if [[ $dir != $_p9k__cwd_a ]]
			then
				while true
				do
					if _p9k_read_word $dir/.php-version
					then
						(( ${_POWERLEVEL9K_PHPENV_SOURCES[(I)local]} )) || return
						break
					fi
					[[ $dir == (/|.) ]] && break
					dir=${dir:h}
				done
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			_p9k_upglob .php-version
			local -i idx=$?
			if (( idx )) && _p9k_read_word $_p9k__parent_dirs[idx]/.php-version
			then
				(( ${_POWERLEVEL9K_PHPENV_SOURCES[(I)local]} )) || return
			else
				_p9k__ret=
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			(( _POWERLEVEL9K_PHPENV_PROMPT_ALWAYS_SHOW )) || return
			(( ${_POWERLEVEL9K_PHPENV_SOURCES[(I)global]} )) || return
			_p9k_phpenv_global_version
		fi
		local v=$_p9k__ret
	fi
	if (( !_POWERLEVEL9K_PHPENV_PROMPT_ALWAYS_SHOW ))
	then
		_p9k_phpenv_global_version
		[[ $v == $_p9k__ret ]] && return
	fi
	if (( !_POWERLEVEL9K_PHPENV_SHOW_SYSTEM ))
	then
		[[ $v == system ]] && return
	fi
	_p9k_prompt_segment "$0" "magenta" "$_p9k_color1" 'PHP_ICON' 0 '' "${v//\%/%%}"
}
prompt_plenv () {
	if [[ -n $PLENV_VERSION ]]
	then
		(( ${_POWERLEVEL9K_PLENV_SOURCES[(I)shell]} )) || return
		local v=$PLENV_VERSION
	else
		(( ${_POWERLEVEL9K_PLENV_SOURCES[(I)local|global]} )) || return
		_p9k__ret=
		if [[ $PLENV_DIR != (|.) ]]
		then
			[[ $PLENV_DIR == /* ]] && local dir=$PLENV_DIR  || local dir="$_p9k__cwd_a/$PLENV_DIR"
			dir=${dir:A}
			if [[ $dir != $_p9k__cwd_a ]]
			then
				while true
				do
					if _p9k_read_word $dir/.perl-version
					then
						(( ${_POWERLEVEL9K_PLENV_SOURCES[(I)local]} )) || return
						break
					fi
					[[ $dir == (/|.) ]] && break
					dir=${dir:h}
				done
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			_p9k_upglob .perl-version
			local -i idx=$?
			if (( idx )) && _p9k_read_word $_p9k__parent_dirs[idx]/.perl-version
			then
				(( ${_POWERLEVEL9K_PLENV_SOURCES[(I)local]} )) || return
			else
				_p9k__ret=
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			(( _POWERLEVEL9K_PLENV_PROMPT_ALWAYS_SHOW )) || return
			(( ${_POWERLEVEL9K_PLENV_SOURCES[(I)global]} )) || return
			_p9k_plenv_global_version
		fi
		local v=$_p9k__ret
	fi
	if (( !_POWERLEVEL9K_PLENV_PROMPT_ALWAYS_SHOW ))
	then
		_p9k_plenv_global_version
		[[ $v == $_p9k__ret ]] && return
	fi
	if (( !_POWERLEVEL9K_PLENV_SHOW_SYSTEM ))
	then
		[[ $v == system ]] && return
	fi
	_p9k_prompt_segment "$0" "blue" "$_p9k_color1" 'PERL_ICON' 0 '' "${v//\%/%%}"
}
prompt_powerlevel9k_setup () {
	_p9k_restore_special_params
	eval "$__p9k_intro"
	_p9k_setup
}
prompt_powerlevel9k_teardown () {
	_p9k_restore_special_params
	eval "$__p9k_intro"
	add-zsh-hook -D precmd '(_p9k_|powerlevel9k_)*'
	add-zsh-hook -D preexec '(_p9k_|powerlevel9k_)*'
	PROMPT='%m%# '
	RPROMPT=
	if (( __p9k_enabled ))
	then
		_p9k_deinit
		__p9k_enabled=0
	fi
}
prompt_prompt_char () {
	local saved=$_p9k__prompt_char_saved[$_p9k__prompt_side$_p9k__segment_index$((!_p9k__status))]
	if [[ -n $saved ]]
	then
		_p9k__prompt+=$saved
		return
	fi
	local -i len=$#_p9k__prompt _p9k__has_upglob
	if (( __p9k_sh_glob ))
	then
		if (( _p9k__status ))
		then
			if (( _POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE ))
			then
				_p9k_prompt_segment $0_ERROR_VIINS "$_p9k_color1" 196 '' 0 '${${${${${${:-$_p9k__keymap.$_p9k__zle_state}:#vicmd.*}:#vivis.*}:#vivli.*}:#*.*overwrite*}}' '❯'
				_p9k_prompt_segment $0_ERROR_VIOWR "$_p9k_color1" 196 '' 0 '${${${${${${:-$_p9k__keymap.$_p9k__zle_state}:#vicmd.*}:#vivis.*}:#vivli.*}:#*.*insert*}}' '▶'
			else
				_p9k_prompt_segment $0_ERROR_VIINS "$_p9k_color1" 196 '' 0 '${${${${_p9k__keymap:#vicmd}:#vivis}:#vivli}}' '❯'
			fi
			_p9k_prompt_segment $0_ERROR_VICMD "$_p9k_color1" 196 '' 0 '${(M)${:-$_p9k__keymap$_p9k__region_active}:#vicmd0}' '❮'
			_p9k_prompt_segment $0_ERROR_VIVIS "$_p9k_color1" 196 '' 0 '${$((! ${#${${${${:-$_p9k__keymap$_p9k__region_active}:#vicmd1}:#vivis?}:#vivli?}})):#0}' 'Ⅴ'
		else
			if (( _POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE ))
			then
				_p9k_prompt_segment $0_OK_VIINS "$_p9k_color1" 76 '' 0 '${${${${${${:-$_p9k__keymap.$_p9k__zle_state}:#vicmd.*}:#vivis.*}:#vivli.*}:#*.*overwrite*}}' '❯'
				_p9k_prompt_segment $0_OK_VIOWR "$_p9k_color1" 76 '' 0 '${${${${${${:-$_p9k__keymap.$_p9k__zle_state}:#vicmd.*}:#vivis.*}:#vivli.*}:#*.*insert*}}' '▶'
			else
				_p9k_prompt_segment $0_OK_VIINS "$_p9k_color1" 76 '' 0 '${${${${_p9k__keymap:#vicmd}:#vivis}:#vivli}}' '❯'
			fi
			_p9k_prompt_segment $0_OK_VICMD "$_p9k_color1" 76 '' 0 '${(M)${:-$_p9k__keymap$_p9k__region_active}:#vicmd0}' '❮'
			_p9k_prompt_segment $0_OK_VIVIS "$_p9k_color1" 76 '' 0 '${$((! ${#${${${${:-$_p9k__keymap$_p9k__region_active}:#vicmd1}:#vivis?}:#vivli?}})):#0}' 'Ⅴ'
		fi
	else
		if (( _p9k__status ))
		then
			if (( _POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE ))
			then
				_p9k_prompt_segment $0_ERROR_VIINS "$_p9k_color1" 196 '' 0 '${${:-$_p9k__keymap.$_p9k__zle_state}:#(vicmd.*|vivis.*|vivli.*|*.*overwrite*)}' '❯'
				_p9k_prompt_segment $0_ERROR_VIOWR "$_p9k_color1" 196 '' 0 '${${:-$_p9k__keymap.$_p9k__zle_state}:#(vicmd.*|vivis.*|vivli.*|*.*insert*)}' '▶'
			else
				_p9k_prompt_segment $0_ERROR_VIINS "$_p9k_color1" 196 '' 0 '${_p9k__keymap:#(vicmd|vivis|vivli)}' '❯'
			fi
			_p9k_prompt_segment $0_ERROR_VICMD "$_p9k_color1" 196 '' 0 '${(M)${:-$_p9k__keymap$_p9k__region_active}:#vicmd0}' '❮'
			_p9k_prompt_segment $0_ERROR_VIVIS "$_p9k_color1" 196 '' 0 '${(M)${:-$_p9k__keymap$_p9k__region_active}:#(vicmd1|vivis?|vivli?)}' 'Ⅴ'
		else
			if (( _POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE ))
			then
				_p9k_prompt_segment $0_OK_VIINS "$_p9k_color1" 76 '' 0 '${${:-$_p9k__keymap.$_p9k__zle_state}:#(vicmd.*|vivis.*|vivli.*|*.*overwrite*)}' '❯'
				_p9k_prompt_segment $0_OK_VIOWR "$_p9k_color1" 76 '' 0 '${${:-$_p9k__keymap.$_p9k__zle_state}:#(vicmd.*|vivis.*|vivli.*|*.*insert*)}' '▶'
			else
				_p9k_prompt_segment $0_OK_VIINS "$_p9k_color1" 76 '' 0 '${_p9k__keymap:#(vicmd|vivis|vivli)}' '❯'
			fi
			_p9k_prompt_segment $0_OK_VICMD "$_p9k_color1" 76 '' 0 '${(M)${:-$_p9k__keymap$_p9k__region_active}:#vicmd0}' '❮'
			_p9k_prompt_segment $0_OK_VIVIS "$_p9k_color1" 76 '' 0 '${(M)${:-$_p9k__keymap$_p9k__region_active}:#(vicmd1|vivis?|vivli?)}' 'Ⅴ'
		fi
	fi
	(( _p9k__has_upglob )) || _p9k__prompt_char_saved[$_p9k__prompt_side$_p9k__segment_index$((!_p9k__status))]=$_p9k__prompt[len+1,-1]
}
prompt_proxy () {
	local -U p=($all_proxy $http_proxy $https_proxy $ftp_proxy $ALL_PROXY $HTTP_PROXY $HTTPS_PROXY $FTP_PROXY)
	p=(${(@)${(@)${(@)p#*://}##*@}%%/*})
	(( $#p == 1 )) || p=("")
	_p9k_prompt_segment $0 $_p9k_color1 blue PROXY_ICON 0 '' "$p[1]"
}
prompt_public_ip () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	local ip='${_p9k__public_ip:-$_POWERLEVEL9K_PUBLIC_IP_NONE}'
	if [[ -n $_POWERLEVEL9K_PUBLIC_IP_VPN_INTERFACE ]]
	then
		_p9k_prompt_segment "$0" "$_p9k_color1" "$_p9k_color2" PUBLIC_IP_ICON 1 '${_p9k__public_ip_not_vpn:+'$ip'}' $ip
		_p9k_prompt_segment "$0" "$_p9k_color1" "$_p9k_color2" VPN_ICON 1 '${_p9k__public_ip_vpn:+'$ip'}' $ip
	else
		_p9k_prompt_segment "$0" "$_p9k_color1" "$_p9k_color2" PUBLIC_IP_ICON 1 $ip $ip
	fi
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_pyenv () {
	_p9k_pyenv_compute || return
	_p9k_prompt_segment "$0" "blue" "$_p9k_color1" 'PYTHON_ICON' 0 '' "${_p9k__pyenv_version//\%/%%}"
}
prompt_ram () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment $0 yellow "$_p9k_color1" RAM_ICON 1 '$_p9k__ram_free' '$_p9k__ram_free'
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_ranger () {
	_p9k_prompt_segment $0 $_p9k_color1 yellow RANGER_ICON 0 '' $RANGER_LEVEL
}
prompt_rbenv () {
	if [[ -n $RBENV_VERSION ]]
	then
		(( ${_POWERLEVEL9K_RBENV_SOURCES[(I)shell]} )) || return
		local v=$RBENV_VERSION
	else
		(( ${_POWERLEVEL9K_RBENV_SOURCES[(I)local|global]} )) || return
		_p9k__ret=
		if [[ $RBENV_DIR != (|.) ]]
		then
			[[ $RBENV_DIR == /* ]] && local dir=$RBENV_DIR  || local dir="$_p9k__cwd_a/$RBENV_DIR"
			dir=${dir:A}
			if [[ $dir != $_p9k__cwd_a ]]
			then
				while true
				do
					if _p9k_read_word $dir/.ruby-version
					then
						(( ${_POWERLEVEL9K_RBENV_SOURCES[(I)local]} )) || return
						break
					fi
					[[ $dir == (/|.) ]] && break
					dir=${dir:h}
				done
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			_p9k_upglob .ruby-version
			local -i idx=$?
			if (( idx )) && _p9k_read_word $_p9k__parent_dirs[idx]/.ruby-version
			then
				(( ${_POWERLEVEL9K_RBENV_SOURCES[(I)local]} )) || return
			else
				_p9k__ret=
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			(( _POWERLEVEL9K_RBENV_PROMPT_ALWAYS_SHOW )) || return
			(( ${_POWERLEVEL9K_RBENV_SOURCES[(I)global]} )) || return
			_p9k_rbenv_global_version
		fi
		local v=$_p9k__ret
	fi
	if (( !_POWERLEVEL9K_RBENV_PROMPT_ALWAYS_SHOW ))
	then
		_p9k_rbenv_global_version
		[[ $v == $_p9k__ret ]] && return
	fi
	if (( !_POWERLEVEL9K_RBENV_SHOW_SYSTEM ))
	then
		[[ $v == system ]] && return
	fi
	_p9k_prompt_segment "$0" "red" "$_p9k_color1" 'RUBY_ICON' 0 '' "${v//\%/%%}"
}
prompt_root_indicator () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment "$0" "$_p9k_color1" "yellow" 'ROOT_ICON' 0 '${${(%):-%#}:#\%}' ''
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_rspec_stats () {
	if [[ -d app && -d spec ]]
	then
		local -a code=(app/**/*.rb(N))
		(( $#code )) || return
		local tests=(spec/**/*.rb(N))
		_p9k_build_test_stats "$0" "$#code" "$#tests" "RSpec" 'TEST_ICON'
	fi
}
prompt_rust_version () {
	unset P9K_RUST_VERSION
	if (( _POWERLEVEL9K_RUST_VERSION_PROJECT_ONLY ))
	then
		_p9k_upglob Cargo.toml && return
	fi
	local rustc=$commands[rustc] toolchain deps=()
	if (( $+commands[ldd] ))
	then
		if ! _p9k_cache_stat_get $0_so $rustc
		then
			local line so
			for line in "${(@f)$(ldd $rustc 2>/dev/null)}"
			do
				[[ $line == (#b)[[:space:]]#librustc_driver[^[:space:]]#.so' => '(*)' (0x'[[:xdigit:]]#')' ]] || continue
				so=$match[1]
				break
			done
			_p9k_cache_stat_set "$so"
		fi
		deps+=$_p9k__cache_val[1]
	fi
	if (( $+commands[rustup] ))
	then
		local rustup=$commands[rustup]
		local rustup_home=${RUSTUP_HOME:-~/.rustup}
		local cfg=($rustup_home/settings.toml(.N))
		deps+=($cfg $rustup_home/update-hashes/*(.N))
		if [[ -z ${toolchain::=$RUSTUP_TOOLCHAIN} ]]
		then
			if ! _p9k_cache_stat_get $0_overrides $rustup $cfg
			then
				local lines=(${(f)"$(rustup override list 2>/dev/null)"})
				if [[ $lines[1] == "no overrides" ]]
				then
					_p9k_cache_stat_set
				else
					local MATCH
					local keys=(${(@)${lines%%[[:space:]]#[^[:space:]]#}/(#m)*/${(b)MATCH}/})
					local vals=(${(@)lines/(#m)*/$MATCH[(I)/] ${MATCH##*[[:space:]]}})
					_p9k_cache_stat_set ${keys:^vals}
				fi
			fi
			local -A overrides=($_p9k__cache_val)
			_p9k_upglob rust-toolchain
			local dir=$_p9k__parent_dirs[$?]
			local -i n m=${dir[(I)/]}
			local pair
			for pair in ${overrides[(K)$_p9k__cwd/]}
			do
				n=${pair%% *}
				(( n <= m )) && continue
				m=n
				toolchain=${pair#* }
			done
			if [[ -z $toolchain && -n $dir ]]
			then
				_p9k_read_word $dir/rust-toolchain
				toolchain=$_p9k__ret
			fi
		fi
	fi
	if ! _p9k_cache_stat_get $0_v$toolchain $rustc $deps
	then
		_p9k_cache_stat_set "$($rustc --version 2>/dev/null)"
	fi
	local v=${${_p9k__cache_val[1]#rustc }%% *}
	[[ -n $v ]] || return
	typeset -g P9K_RUST_VERSION=$_p9k__cache_val[1]
	_p9k_prompt_segment "$0" "darkorange" "$_p9k_color1" 'RUST_ICON' 0 '' "${v//\%/%%}"
}
prompt_rvm () {
	[[ $GEM_HOME == *rvm* && $ruby_string != $rvm_path/bin/ruby ]] || return
	local v=${GEM_HOME:t}
	(( _POWERLEVEL9K_RVM_SHOW_GEMSET )) || v=${v%%${rvm_gemset_separator:-@}*}
	(( _POWERLEVEL9K_RVM_SHOW_PREFIX )) || v=${v#*-}
	[[ -n $v ]] || return
	_p9k_prompt_segment "$0" "240" "$_p9k_color1" 'RUBY_ICON' 0 '' "${v//\%/%%}"
}
prompt_scalaenv () {
	if [[ -n $SCALAENV_VERSION ]]
	then
		(( ${_POWERLEVEL9K_SCALAENV_SOURCES[(I)shell]} )) || return
		local v=$SCALAENV_VERSION
	else
		(( ${_POWERLEVEL9K_SCALAENV_SOURCES[(I)local|global]} )) || return
		_p9k__ret=
		if [[ $SCALAENV_DIR != (|.) ]]
		then
			[[ $SCALAENV_DIR == /* ]] && local dir=$SCALAENV_DIR  || local dir="$_p9k__cwd_a/$SCALAENV_DIR"
			dir=${dir:A}
			if [[ $dir != $_p9k__cwd_a ]]
			then
				while true
				do
					if _p9k_read_word $dir/.scala-version
					then
						(( ${_POWERLEVEL9K_SCALAENV_SOURCES[(I)local]} )) || return
						break
					fi
					[[ $dir == (/|.) ]] && break
					dir=${dir:h}
				done
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			_p9k_upglob .scala-version
			local -i idx=$?
			if (( idx )) && _p9k_read_word $_p9k__parent_dirs[idx]/.scala-version
			then
				(( ${_POWERLEVEL9K_SCALAENV_SOURCES[(I)local]} )) || return
			else
				_p9k__ret=
			fi
		fi
		if [[ -z $_p9k__ret ]]
		then
			(( _POWERLEVEL9K_SCALAENV_PROMPT_ALWAYS_SHOW )) || return
			(( ${_POWERLEVEL9K_SCALAENV_SOURCES[(I)global]} )) || return
			_p9k_scalaenv_global_version
		fi
		local v=$_p9k__ret
	fi
	if (( !_POWERLEVEL9K_SCALAENV_PROMPT_ALWAYS_SHOW ))
	then
		_p9k_scalaenv_global_version
		[[ $v == $_p9k__ret ]] && return
	fi
	if (( !_POWERLEVEL9K_SCALAENV_SHOW_SYSTEM ))
	then
		[[ $v == system ]] && return
	fi
	_p9k_prompt_segment "$0" "red" "$_p9k_color1" 'SCALA_ICON' 0 '' "${v//\%/%%}"
}
prompt_segment () {
	local bg fg
	[[ -n $1 ]] && bg="%K{$1}"  || bg="%k"
	[[ -n $2 ]] && fg="%F{$2}"  || fg="%f"
	if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]
	then
		echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
	else
		echo -n "%{$bg%}%{$fg%} "
	fi
	CURRENT_BG=$1
	[[ -n $3 ]] && echo -n $3
}
prompt_ssh () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment "$0" "$_p9k_color1" "yellow" 'SSH_ICON' 0 '' ''
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_status () {
	if ! _p9k_cache_get $0 $_p9k__status $_p9k__pipestatus
	then
		(( _p9k__status )) && local state=ERROR  || local state=OK
		if (( _POWERLEVEL9K_STATUS_EXTENDED_STATES ))
		then
			if (( _p9k__status ))
			then
				if (( $#_p9k__pipestatus > 1 ))
				then
					state+=_PIPE
				elif (( _p9k__status > 128 ))
				then
					state+=_SIGNAL
				fi
			elif [[ "$_p9k__pipestatus" == *[1-9]* ]]
			then
				state+=_PIPE
			fi
		fi
		_p9k__cache_val=(:)
		if (( _POWERLEVEL9K_STATUS_$state ))
		then
			if (( _POWERLEVEL9K_STATUS_SHOW_PIPESTATUS ))
			then
				local text=${(j:|:)${(@)_p9k__pipestatus:/(#b)(*)/$_p9k_exitcode2str[$match[1]+1]}}
			else
				local text=$_p9k_exitcode2str[_p9k__status+1]
			fi
			if (( _p9k__status ))
			then
				if (( !_POWERLEVEL9K_STATUS_CROSS && _POWERLEVEL9K_STATUS_VERBOSE ))
				then
					_p9k__cache_val=($0_$state red yellow1 CARRIAGE_RETURN_ICON 0 '' "$text")
				else
					_p9k__cache_val=($0_$state $_p9k_color1 red FAIL_ICON 0 '' '')
				fi
			elif (( _POWERLEVEL9K_STATUS_VERBOSE || _POWERLEVEL9K_STATUS_OK_IN_NON_VERBOSE ))
			then
				[[ $state == OK ]] && text=''
				_p9k__cache_val=($0_$state "$_p9k_color1" green OK_ICON 0 '' "$text")
			fi
		fi
		if (( $#_p9k__pipestatus < 3 ))
		then
			_p9k_cache_set "${(@)_p9k__cache_val}"
		fi
	fi
	_p9k_prompt_segment "${(@)_p9k__cache_val}"
}
prompt_swap () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment $0 yellow "$_p9k_color1" SWAP_ICON 1 '$_p9k__swap_used' '$_p9k__swap_used'
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_swift_version () {
	_p9k_cached_cmd 0 '' swift --version || return
	[[ $_p9k__ret == (#b)[^[:digit:]]#([[:digit:].]##)* ]] || return
	_p9k_prompt_segment "$0" "magenta" "white" 'SWIFT_ICON' 0 '' "${match[1]//\%/%%}"
}
prompt_symfony2_tests () {
	if [[ -d src && -d app && -f app/AppKernel.php ]]
	then
		local -a all=(src/**/*.php(N))
		local -a code=(${(@)all##*Tests*})
		(( $#code )) || return
		_p9k_build_test_stats "$0" "$#code" "$(($#all - $#code))" "SF2" 'TEST_ICON'
	fi
}
prompt_symfony2_version () {
	if [[ -r app/bootstrap.php.cache ]]
	then
		local v="${$(grep -F " VERSION " app/bootstrap.php.cache 2>/dev/null)//[![:digit:].]}"
		_p9k_prompt_segment "$0" "grey35" "$_p9k_color1" 'SYMFONY_ICON' 0 '' "${v//\%/%%}"
	fi
}
prompt_taskwarrior () {
	unset P9K_TASKWARRIOR_PENDING_COUNT P9K_TASKWARRIOR_OVERDUE_COUNT
	if ! _p9k_taskwarrior_check_data
	then
		_p9k_taskwarrior_data_files=()
		_p9k_taskwarrior_data_non_files=()
		_p9k_taskwarrior_data_sig=
		_p9k_taskwarrior_counters=()
		_p9k_taskwarrior_next_due=0
		_p9k_taskwarrior_check_meta || _p9k_taskwarrior_init_meta || return
		_p9k_taskwarrior_init_data
	fi
	(( $#_p9k_taskwarrior_counters )) || return
	local text c=$_p9k_taskwarrior_counters[OVERDUE]
	if [[ -n $c ]]
	then
		typeset -g P9K_TASKWARRIOR_OVERDUE_COUNT=$c
		text+="!$c"
	fi
	c=$_p9k_taskwarrior_counters[PENDING]
	if [[ -n $c ]]
	then
		typeset -g P9K_TASKWARRIOR_PENDING_COUNT=$c
		[[ -n $text ]] && text+='/'
		text+=$c
	fi
	[[ -n $text ]] || return
	_p9k_prompt_segment $0 6 $_p9k_color1 TASKWARRIOR_ICON 0 '' $text
}
prompt_terraform () {
	local ws=$TF_WORKSPACE
	if [[ -z $TF_WORKSPACE ]]
	then
		_p9k_read_word ${${TF_DATA_DIR:-.terraform}:A}/environment && ws=$_p9k__ret
	fi
	[[ -z $ws || ( $ws == default && $_POWERLEVEL9K_TERRAFORM_SHOW_DEFAULT == 0 ) ]] && return
	local pat class state
	for pat class in "${_POWERLEVEL9K_TERRAFORM_CLASSES[@]}"
	do
		if [[ $ws == ${~pat} ]]
		then
			[[ -n $class ]] && state=_${${(U)class}//İ/I}
			break
		fi
	done
	_p9k_prompt_segment "$0$state" $_p9k_color1 blue TERRAFORM_ICON 0 '' $ws
}
prompt_terraform_version () {
	_p9k_cached_cmd 0 '' terraform --version || return
	local v=${_p9k__ret#Terraform v}
	(( $#v < $#_p9k__ret )) || return
	v=${v%%$'\n'*}
	[[ -n $v ]] || return
	_p9k_prompt_segment $0 $_p9k_color1 blue TERRAFORM_ICON 0 '' $v
}
prompt_time () {
	if (( _POWERLEVEL9K_EXPERIMENTAL_TIME_REALTIME ))
	then
		_p9k_prompt_segment "$0" "$_p9k_color2" "$_p9k_color1" "TIME_ICON" 0 '' "$_POWERLEVEL9K_TIME_FORMAT"
	else
		if [[ $_p9k__refresh_reason == precmd ]]
		then
			if [[ $+__p9k_instant_prompt_active == 1 && $__p9k_instant_prompt_time_format == $_POWERLEVEL9K_TIME_FORMAT ]]
			then
				_p9k__time=${__p9k_instant_prompt_time//\%/%%}
			else
				_p9k__time=${${(%)_POWERLEVEL9K_TIME_FORMAT}//\%/%%}
			fi
		fi
		if (( _POWERLEVEL9K_TIME_UPDATE_ON_COMMAND ))
		then
			_p9k_escape $_p9k__time
			local t=$_p9k__ret
			_p9k_escape $_POWERLEVEL9K_TIME_FORMAT
			_p9k_prompt_segment "$0" "$_p9k_color2" "$_p9k_color1" "TIME_ICON" 1 '' "\${_p9k__line_finished-$t}\${_p9k__line_finished+$_p9k__ret}"
		else
			_p9k_prompt_segment "$0" "$_p9k_color2" "$_p9k_color1" "TIME_ICON" 0 '' $_p9k__time
		fi
	fi
}
prompt_timewarrior () {
	local -a stat
	local dir=${TIMEWARRIORDB:-~/.timewarrior}/data
	[[ $dir == $_p9k_timewarrior_dir ]] || _p9k_timewarrior_clear
	if [[ -n $_p9k_timewarrior_file_name ]]
	then
		zstat -A stat +mtime -- $dir $_p9k_timewarrior_file_name 2> /dev/null || stat=()
		if [[ $stat[1] == $_p9k_timewarrior_dir_mtime && $stat[2] == $_p9k_timewarrior_file_mtime ]]
		then
			if (( $+_p9k_timewarrior_tags ))
			then
				_p9k_prompt_segment $0 grey 255 TIMEWARRIOR_ICON 0 '' "${_p9k_timewarrior_tags//\%/%%}"
			fi
			return
		fi
	fi
	if [[ ! -d $dir ]]
	then
		_p9k_timewarrior_clear
		return
	fi
	_p9k_timewarrior_dir=$dir
	if [[ $stat[1] != $_p9k_timewarrior_dir_mtime ]]
	then
		local -a files=($dir/<->-<->.data(.N))
		if (( ! $#files ))
		then
			if (( $#stat )) || zstat -A stat +mtime -- $dir 2> /dev/null
			then
				_p9k_timewarrior_dir_mtime=$stat[1]
				_p9k_timewarrior_file_mtime=$stat[1]
				_p9k_timewarrior_file_name=$dir
				unset _p9k_timewarrior_tags
				_p9k__state_dump_scheduled=1
			else
				_p9k_timewarrior_clear
			fi
			return
		fi
		_p9k_timewarrior_file_name=${${(AO)files}[1]}
	fi
	if ! zstat -A stat +mtime -- $dir $_p9k_timewarrior_file_name 2> /dev/null
	then
		_p9k_timewarrior_clear
		return
	fi
	_p9k_timewarrior_dir_mtime=$stat[1]
	_p9k_timewarrior_file_mtime=$stat[2]
	{
		local tail=${${(Af)"$(<$_p9k_timewarrior_file_name)"}[-1]}
	} 2> /dev/null
	if [[ $tail == (#b)'inc '[^\ ]##(|\ #\#(*)) ]]
	then
		_p9k_timewarrior_tags=${${match[2]## #}%% #}
		_p9k_prompt_segment $0 grey 255 TIMEWARRIOR_ICON 0 '' "${_p9k_timewarrior_tags//\%/%%}"
	else
		unset _p9k_timewarrior_tags
	fi
	_p9k__state_dump_scheduled=1
}
prompt_todo () {
	unset P9K_TODO_TOTAL_TASK_COUNT P9K_TODO_FILTERED_TASK_COUNT
	[[ -r $_p9k__todo_file && -x $_p9k__todo_command ]] || return
	if ! _p9k_cache_stat_get $0 $_p9k__todo_file
	then
		local count="$($_p9k__todo_command -p ls | command tail -1)"
		if [[ $count == (#b)'TODO: '([[:digit:]]##)' of '([[:digit:]]##)' '* ]]
		then
			_p9k_cache_stat_set 1 $match[1] $match[2]
		else
			_p9k_cache_stat_set 0
		fi
	fi
	(( $_p9k__cache_val[1] )) || return
	typeset -gi P9K_TODO_FILTERED_TASK_COUNT=$_p9k__cache_val[2]
	typeset -gi P9K_TODO_TOTAL_TASK_COUNT=$_p9k__cache_val[3]
	if (( (P9K_TODO_TOTAL_TASK_COUNT    || !_POWERLEVEL9K_TODO_HIDE_ZERO_TOTAL) &&
        (P9K_TODO_FILTERED_TASK_COUNT || !_POWERLEVEL9K_TODO_HIDE_ZERO_FILTERED) ))
	then
		if (( P9K_TODO_TOTAL_TASK_COUNT == P9K_TODO_FILTERED_TASK_COUNT ))
		then
			local text=$P9K_TODO_TOTAL_TASK_COUNT
		else
			local text="$P9K_TODO_FILTERED_TASK_COUNT/$P9K_TODO_TOTAL_TASK_COUNT"
		fi
		_p9k_prompt_segment "$0" "grey50" "$_p9k_color1" 'TODO_ICON' 0 '' "$text"
	fi
}
prompt_toolbox () {
	_p9k_prompt_segment $0 $_p9k_color1 yellow TOOLBOX_ICON 0 '' $P9K_TOOLBOX_NAME
}
prompt_user () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment "${0}_ROOT" "${_p9k_color1}" yellow ROOT_ICON 0 '${${(%):-%#}:#\%}' "$_POWERLEVEL9K_USER_TEMPLATE"
	if [[ -n "$SUDO_COMMAND" ]]
	then
		_p9k_prompt_segment "${0}_SUDO" "${_p9k_color1}" yellow SUDO_ICON 0 '${${(%):-%#}:#\#}' "$_POWERLEVEL9K_USER_TEMPLATE"
	else
		_p9k_prompt_segment "${0}_DEFAULT" "${_p9k_color1}" yellow USER_ICON 0 '${${(%):-%#}:#\#}' "%n"
	fi
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_vcs () {
	if (( _p9k_vcs_index && $+GITSTATUS_DAEMON_PID_POWERLEVEL9K ))
	then
		_p9k__prompt+='${(e)_p9k__vcs}'
		return
	fi
	local -a backends=($_POWERLEVEL9K_VCS_BACKENDS)
	if (( ${backends[(I)git]} && $+GITSTATUS_DAEMON_PID_POWERLEVEL9K )) && _p9k_vcs_gitstatus
	then
		_p9k_vcs_render && return
		backends=(${backends:#git})
	fi
	if (( $#backends ))
	then
		VCS_WORKDIR_DIRTY=false
		VCS_WORKDIR_HALF_DIRTY=false
		local current_state=""
		zstyle ':vcs_info:*' enable ${backends}
		vcs_info
		local vcs_prompt="${vcs_info_msg_0_}"
		if [[ -n "$vcs_prompt" ]]
		then
			if [[ "$VCS_WORKDIR_DIRTY" == true ]]
			then
				current_state='MODIFIED'
			else
				if [[ "$VCS_WORKDIR_HALF_DIRTY" == true ]]
				then
					current_state='UNTRACKED'
				else
					current_state='CLEAN'
				fi
			fi
			_p9k_prompt_segment "${0}_${${(U)current_state}//İ/I}" "${__p9k_vcs_states[$current_state]}" "$_p9k_color1" "$vcs_visual_identifier" 0 '' "$vcs_prompt"
		fi
	fi
}
prompt_vi_mode () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	if (( __p9k_sh_glob ))
	then
		if (( $+_POWERLEVEL9K_VI_OVERWRITE_MODE_STRING ))
		then
			if [[ -n $_POWERLEVEL9K_VI_INSERT_MODE_STRING ]]
			then
				_p9k_prompt_segment $0_INSERT "$_p9k_color1" blue '' 0 '${${${${${${:-$_p9k__keymap.$_p9k__zle_state}:#vicmd.*}:#vivis.*}:#vivli.*}:#*.*overwrite*}}' "$_POWERLEVEL9K_VI_INSERT_MODE_STRING"
			fi
			_p9k_prompt_segment $0_OVERWRITE "$_p9k_color1" blue '' 0 '${${${${${${:-$_p9k__keymap.$_p9k__zle_state}:#vicmd.*}:#vivis.*}:#vivli.*}:#*.*insert*}}' "$_POWERLEVEL9K_VI_OVERWRITE_MODE_STRING"
		else
			if [[ -n $_POWERLEVEL9K_VI_INSERT_MODE_STRING ]]
			then
				_p9k_prompt_segment $0_INSERT "$_p9k_color1" blue '' 0 '${${${${_p9k__keymap:#vicmd}:#vivis}:#vivli}}' "$_POWERLEVEL9K_VI_INSERT_MODE_STRING"
			fi
		fi
		if (( $+_POWERLEVEL9K_VI_VISUAL_MODE_STRING ))
		then
			_p9k_prompt_segment $0_NORMAL "$_p9k_color1" white '' 0 '${(M)${:-$_p9k__keymap$_p9k__region_active}:#vicmd0}' "$_POWERLEVEL9K_VI_COMMAND_MODE_STRING"
			_p9k_prompt_segment $0_VISUAL "$_p9k_color1" white '' 0 '${$((! ${#${${${${:-$_p9k__keymap$_p9k__region_active}:#vicmd1}:#vivis?}:#vivli?}})):#0}' "$_POWERLEVEL9K_VI_VISUAL_MODE_STRING"
		else
			_p9k_prompt_segment $0_NORMAL "$_p9k_color1" white '' 0 '${$((! ${#${${${_p9k__keymap:#vicmd}:#vivis}:#vivli}})):#0}' "$_POWERLEVEL9K_VI_COMMAND_MODE_STRING"
		fi
	else
		if (( $+_POWERLEVEL9K_VI_OVERWRITE_MODE_STRING ))
		then
			if [[ -n $_POWERLEVEL9K_VI_INSERT_MODE_STRING ]]
			then
				_p9k_prompt_segment $0_INSERT "$_p9k_color1" blue '' 0 '${${:-$_p9k__keymap.$_p9k__zle_state}:#(vicmd.*|vivis.*|vivli.*|*.*overwrite*)}' "$_POWERLEVEL9K_VI_INSERT_MODE_STRING"
			fi
			_p9k_prompt_segment $0_OVERWRITE "$_p9k_color1" blue '' 0 '${${:-$_p9k__keymap.$_p9k__zle_state}:#(vicmd.*|vivis.*|vivli.*|*.*insert*)}' "$_POWERLEVEL9K_VI_OVERWRITE_MODE_STRING"
		else
			if [[ -n $_POWERLEVEL9K_VI_INSERT_MODE_STRING ]]
			then
				_p9k_prompt_segment $0_INSERT "$_p9k_color1" blue '' 0 '${_p9k__keymap:#(vicmd|vivis|vivli)}' "$_POWERLEVEL9K_VI_INSERT_MODE_STRING"
			fi
		fi
		if (( $+_POWERLEVEL9K_VI_VISUAL_MODE_STRING ))
		then
			_p9k_prompt_segment $0_NORMAL "$_p9k_color1" white '' 0 '${(M)${:-$_p9k__keymap$_p9k__region_active}:#vicmd0}' "$_POWERLEVEL9K_VI_COMMAND_MODE_STRING"
			_p9k_prompt_segment $0_VISUAL "$_p9k_color1" white '' 0 '${(M)${:-$_p9k__keymap$_p9k__region_active}:#(vicmd1|vivis?|vivli?)}' "$_POWERLEVEL9K_VI_VISUAL_MODE_STRING"
		else
			_p9k_prompt_segment $0_NORMAL "$_p9k_color1" white '' 0 '${(M)_p9k__keymap:#(vicmd|vivis|vivli)}' "$_POWERLEVEL9K_VI_COMMAND_MODE_STRING"
		fi
	fi
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_vim_shell () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment $0 green $_p9k_color1 VIM_ICON 0 '' ''
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_virtualenv () {
	local msg=''
	if (( _POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION )) && _p9k_python_version
	then
		msg="${_p9k__ret//\%/%%} "
	fi
	local v=${VIRTUAL_ENV:t}
	if [[ $VIRTUAL_ENV_PROMPT == '('?*') ' && $VIRTUAL_ENV_PROMPT != "($v) " ]]
	then
		v=$VIRTUAL_ENV_PROMPT[2,-3]
	elif [[ $v == $~_POWERLEVEL9K_VIRTUALENV_GENERIC_NAMES ]]
	then
		v=${VIRTUAL_ENV:h:t}
	fi
	msg+="$_POWERLEVEL9K_VIRTUALENV_LEFT_DELIMITER${v//\%/%%}$_POWERLEVEL9K_VIRTUALENV_RIGHT_DELIMITER"
	case $_POWERLEVEL9K_VIRTUALENV_SHOW_WITH_PYENV in
		(false) _p9k_prompt_segment "$0" "blue" "$_p9k_color1" 'PYTHON_ICON' 0 '${(M)${#P9K_PYENV_PYTHON_VERSION}:#0}' "$msg" ;;
		(if-different) _p9k_escape $v
			_p9k_prompt_segment "$0" "blue" "$_p9k_color1" 'PYTHON_ICON' 0 '${${:-'$_p9k__ret'}:#$_p9k__pyenv_version}' "$msg" ;;
		(*) _p9k_prompt_segment "$0" "blue" "$_p9k_color1" 'PYTHON_ICON' 0 '' "$msg" ;;
	esac
}
prompt_vpn_ip () {
	typeset -ga _p9k__vpn_ip_segments
	_p9k__vpn_ip_segments+=($_p9k__prompt_side $_p9k__line_index $_p9k__segment_index)
	local p='${(e)_p9k__vpn_ip_'$_p9k__prompt_side$_p9k__segment_index'}'
	_p9k__prompt+=$p
	typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$p
}
prompt_wifi () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment $0 green $_p9k_color1 WIFI_ICON 1 '$_p9k__wifi_on' '$P9K_WIFI_LAST_TX_RATE Mbps'
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
prompt_xplr () {
	local -i len=$#_p9k__prompt _p9k__has_upglob
	_p9k_prompt_segment $0 6 $_p9k_color1 XPLR_ICON 0 '' ''
	(( _p9k__has_upglob )) || typeset -g "_p9k__segment_val_${_p9k__prompt_side}[_p9k__segment_index]"=$_p9k__prompt[len+1,-1]
}
pyenv_prompt_info () {
	return 1
}
quote-paste () {
	emulate -L zsh
	local qstyle
	zstyle -s :bracketed-paste-magic:finish quote-style qstyle && NUMERIC=1
	case $qstyle in
		(b) PASTED=${(b)PASTED}  ;;
		(q-) PASTED=${(q-)PASTED}  ;;
		(\\|q) PASTED=${(q)PASTED}  ;;
		(\'|qq) PASTED=${(qq)PASTED}  ;;
		(\"|qqq) PASTED=${(qqq)PASTED}  ;;
		(\$|qqqq) PASTED=${(qqqq)PASTED}  ;;
		(Q) PASTED=${(Q)PASTED}  ;;
	esac
}
r_ () {
	PARAM=$1
	r_it () {
		grep --color=auto -irl $PARAM "$@"
	}
	shift
	for fname in "$@"
	do
		r_it "$fname"
	done
}
rbenv_prompt_info () {
	return 1
}
realias () {
	local BACKUP_ALIAS_VAL=$(alias-value pre-${1})
	builtin unalias pre-${1}
	alias ${1}=$BACKUP_ALIAS_VAL
}
realpathf () {
	/usr/bin/python -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$0"
}
red () {
	echo "${COLOR_Red}${1}${W}"
}
rename-dir-content () {
	COUNT=0
	for i in *
	do
		COUNT=$((COUNT+1))
		echo "mv ${i} $(printf %02u $COUNT;e ${1}.png)"
	done
}
reverse () {
	tail -r -n $(cat "$1" | wc -l) "$1"
}
ruby_prompt_info () {
	echo $(rvm_prompt_info || rbenv_prompt_info || chruby_prompt_info)
}
rvm_prompt_info () {
	[ -f $HOME/.rvm/bin/rvm-prompt ] || return 1
	local rvm_prompt
	rvm_prompt=$($HOME/.rvm/bin/rvm-prompt ${=ZSH_THEME_RVM_PROMPT_OPTIONS} 2>/dev/null)
	[[ -z "${rvm_prompt}" ]] && return 1
	echo "${ZSH_THEME_RUBY_PROMPT_PREFIX}${rvm_prompt}${ZSH_THEME_RUBY_PROMPT_SUFFIX}"
}
savelink () {
	TARGET=''
	if [ -n $2 ]
	then
		TARGET="$2"
		mkdirlinks $(dirname $TARGET)
	fi
	createlink "$1" ~/Desktop/LINKS/$TARGET
}
savelink2 () {
	TARGET="$HOME/Desktop/LINKS/"
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
	createlink "$1" "$TARGET"
}
scpup2 () {
	if [ ! $1 ]
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
	scp -r $1 root@vwebsk.kmundp.de:~/$DEST
}
scriptStartsWith () {
	TILL=$#@
	isNumber "$@[$#@]" && {
		A="$@[$#@]"
		TILL=$((${TILL}-1))
	} || A=1
	isNumber "$@[$((${#@}-1))]" && {
		B="$@[$((${#@}-1))]"
		TILL=$((${TILL}-1))
	} || B=1
	echo '$# '${#}
	szstart=$(echo $@[2,${TILL}])
	rgx_start=${szstart//\ /\|}
	echo $szstart
	echo $rgx_start
	ccat "$1" | grep --color=auto --color=auto -E "^($rgx_start)" -A $A -B $B
	isDebug && echo "ccat \"$1\" | grep --color=auto -E \"^($rgx_start)\" -A $A -B $B"
}
search-youtubedl-option () {
	for opt in $YOUTUBE_DL_OPTIONS
	do
		string_contains_ $opt "${1}" && {
			farbex Red $opt n
			farbex NC
		} || echo $opt
	done
}
searchFolderForGitRepo () {
	for i in $(ls -1 "$1")
	do
		[ -e "$i/.git" ] && echo "$i is a repo" && giturlp "$i" || echo "$i is a NOT repo"
	done
}
searchFolderForGitRepoX () {
	for i in $(ls -1 "$1")
	do
		[ -e "$i/.git" ] && echo "$i is a repo" && giturlp $i || echo "$i is a NOT repo"
	done
}
searchreplace () {
	SOURCETEXT="$1"
	DELIMITER="$2"
	REPLACER=$([ -n "$3" ] && $(echo "$3") || echo ";")
	echo "$1" | perl -pe "s/$2{1,}/$REPLACER/g"
}
secho () {
	echo "Number of args ${#}"
}
setDebug () {
	export DEBUG=$TRUE
}
setDebugPersistent () {
	DEBUGSTATE="$1"
	if [[ "$DEBUGSTATE" = "$TRUE" ]] || [[ "$DEBUGSTATE" = "$FALSE" ]]
	then
		echo $DEBUGSTATE > $DEBUG_STATE_FILE
	fi
}
setProd () {
	DEBUG=$FALSE
}
setPromptTime () {
	PROMPT="${PROMPT/\%\#/%T \%\#}"
}
setup_virtualenv () {
	source $(which virtualenvwrapper.sh)
	workon
}
show () {
	echo foo > "$HOME/unutmalist/foo$1.tmp"
	tail -n +1 ~/unutmalist/**/*$1* | sed '/foo/d'
	rm -i -f "$HOME/unutmalist/foo$1.tmp"
}
show-DTTK-example () {
	cat /usr/share/examples/DTTk/* | grep --color=auto --color=auto -E "^\s*\#\s{0,2}\S"
}
show-aliases-in-functions () {
	alias
}
show-dirstack () {
	for dir in $dirstack
	do
		echo ${dir}
	done
}
show2 () {
	tail -n 1 ~/unutmalist/*$1*
}
showE () {
	echo foo > "$HOME/unutmalist/foo$1.tmp"
	tail -n +1 ~/unutmalist/**/*$1* | sed '/foo/d'
	rm -i -i -i -i -f "$HOME/unutmalist/foo$1.tmp"
	[[ $# -gt 1 ]] && startsWithDash ${1} && {
		OPT=${1}  && SEARCHTERM=${2}
	} || SEARCHTERM=${1}
	grep --color=auto --color=auto -rRIsE ${OPT} "${SEARCHTERM}" "${unutmalist}" -A2
}
show_ () {
	tail -n +1 ~/unutmalist/**/*$1*
}
show__ () {
	echo foo > "$HOME/unutmalist/foo$1.tmp"
	tail -n +1 ~/unutmalist/**/*$1* | sed '/foo/d'
	rm -i -i -i -i -f "$HOME/unutmalist/foo$1.tmp"
	grep --color=auto --color=auto --color=auto -irRIs "${1}" $unutmalist -A2 --exclude "$unutmalist/*${1}*"
}
showshit () {
	for i in $ARR_ALIAS
	do
		echo $i
	done
}
sln () {
	ln -s `pwd`/$1 $2
}
source-all () {
	[[ -z $BASHDEBUGSTATE ]] && sourcee ~/.debug_state || echo "$BASHDEBUGSTATE already sourced"
	[[ -z $BASHFUNCTIONS ]] && sourcee ~/bin/.functions || echo "$BASHFUNCTIONS already sourced"
	[[ -z $BASHVARS ]] && sourcee ~/.bash_vars || echo "$BASHVARS already sourced"
	[[ -z $BASHALIASES ]] && sourcee ~/.bash_aliases || echo "$BASHALIASES already sourced"
	[[ -z $DEBUG ]] && echo "\$DEBUG zero" || echo "\$DEBUG is set"
	isFunction3 isDebug && echo "isDebug()" && [[ "$?" -eq 0 ]] && echo "TRUE" || echo "FALSE"
}
sourcee () {
	new-shell-log-file
	echo "${0}" | tee -a $SHELL_LOG_FILE
	echo "${1}" | tee -a $SHELL_LOG_FILE
	builtin source "$1" | tee -a $SHELL_LOG_FILE
}
spectrum_bls () {
	for code in {000..255}
	do
		print -P -- "$code: %{$BG[$code]%}$ZSH_SPECTRUM_TEXT%{$reset_color%}"
	done
}
spectrum_ls () {
	for code in {000..255}
	do
		print -P -- "$code: %{$FG[$code]%}$ZSH_SPECTRUM_TEXT%{$reset_color%}"
	done
}
sploit-tools () {
	cd $GITHUB/InfoSec-Exploit-PWN/DOOOOONNNNNNEEEEE/sploit-tools
	PATH=$PWD:$PATH
	cd $OLDPWD
}
ssh-proxy () {
	usage "$0" "$#" 1 'user@your-server.com' "$(print_usage)" || return $?
	ssh -D 7070 -p22 $1
}
startsWith () {
	usage "$0" "$#" 2 '<HAYSSTACK> <NEEDLE>' "checks if haystack starts with needle" || return $?
	HAYSSTACK="$1"
	NEEDLE="$2"
	isDebug && echo "HAYSSTACK = $HAYSSTACK"
	isDebug && echo "NEEDLE = $NEEDLE"
	[[ "$HAYSSTACK" = "$NEEDLE"* ]] && return 0 || return 1
}
startsWithDash () {
	PARAM="$1"
	isDebug && echo $PARAM
	[[ $PARAM[1] = "-" ]] && return 0 || return 1
}
startsWith_ () {
	usage "$0" "$#" 2 '<HAYSSTACK> <NEEDLE>' "checks if haystack starts with needle" || return $?
	[[ $#1 -gt $#2 ]] && {
		HAYSSTACK="$1"
		NEEDLE="$2"
	} || {
		HAYSSTACK="$2"
		NEEDLE="$1"
	}
	isDebug && echo "HAYSSTACK = $HAYSSTACK"
	isDebug && echo "NEEDLE = $NEEDLE"
	[[ "$HAYSSTACK" = "$NEEDLE"* ]] && return 0 || return 1
}
string_contains () {
	usage "$0" "$#" 2 '<HAYSSTACK> <NEEDLE>' "checks if haystack contains needle" || return $?
	if [[ $1 == *"$2"* ]] || [[ $2 == *"$1"* ]]
	then
		return 0
	else
		return 1
	fi
}
string_contains_ () {
	if [[ $1 == *"$2"* ]] || [[ $2 == *"$1"* ]]
	then
		return 0
	else
		return 1
	fi
}
strip_protocol () {
	echo ${$(echo $1 | cut -d ":" -f2)/\/\//}
}
svn_prompt_info () {
	return 1
}
take () {
	mkdir -p $@ && cd ${@:$#}
}
testfunc2 () {
	echo "$# parameters"
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
	done
}
throw () {
	exit $1
}
throwErrors () {
	set -e
}
timestamp () {
	date +"%s"
}
title () {
	emulate -L zsh
	setopt prompt_subst
	[[ "$EMACS" == *term* ]] && return
	: ${2=$1}
	case "$TERM" in
		(cygwin | xterm* | putty* | rxvt* | ansi) print -Pn "\e]2;$2:q\a"
			print -Pn "\e]1;$1:q\a" ;;
		(screen* | tmux*) print -Pn "\ek$1:q\e\\" ;;
		(*) if [[ "$TERM_PROGRAM" == "iTerm.app" ]]
			then
				print -Pn "\e]2;$2:q\a"
				print -Pn "\e]1;$1:q\a"
			else
				if [[ -n "$terminfo[fsl]" ]] && [[ -n "$terminfo[tsl]" ]]
				then
					echoti tsl
					print -Pn "$1"
					echoti fsl
				fi
			fi ;;
	esac
}
tmpfunc () {
	_usage "$0" "${#}" 1 "<any>" "nur um params zu checkn" || return 1
	echo "$0 $@"
}
toc_it () {
	ls -G -G -1ActF "${1}"/**/*.pdf > ~/PDFs/TOC_$(filename "${1}").txt
	IFS=$DELIMITER_ENDL
	for i in $(cat  ~/PDFs/TOC_$(filename "${1}").txt)
	do
		echo "$(dirname $i); $(filename $i);;" >> ~/PDFs/TOC_$(filename "${1}").csv
	done
}
try () {
	[[ $- = *e* ]]
	SAVED_OPT_E=$?
	set +e
}
try_alias_value () {
	alias_value "$1" || echo "$1"
}
trying () {
	"$@" || (
		[ $0 == "-bash" ] || dying "cannot $*"
	)
}
uninstall_oh_my_zsh () {
	env ZSH=$ZSH sh $ZSH/tools/uninstall.sh
}
unsetDebug () {
	export DEBUG=$FALSE
}
unsetProd () {
	DEBUG=$TRUE
}
up-line-or-beginning-search () {
	emulate -L zsh
	typeset -g __searching __savecursor
	if [[ $LBUFFER == *$'\n'* ]]
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
	fi
}
update-debug-state () {
	sourcee $HOME/.debug_state
}
update_current_git_vars () {
	unset __CURRENT_GIT_STATUS
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
	GIT_UNTRACKED=$__CURRENT_GIT_STATUS[7]
}
update_video_content () {
	cd $MOVIESe
	cd $OLDPWD
}
upgrade_oh_my_zsh () {
	env ZSH=$ZSH sh $ZSH/tools/upgrade.sh
}
uppercase () {
	echo "$1" | tr '[:lower:]' '[:upper:]'
}
url-quote-magic () {
	setopt localoptions noksharrays extendedglob
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
				((${~localschema}):/(|/localhost)/*) [[ "$urlseps" == *"$KEYS"* ]] && LBUFFER="$LBUFFER\\"  ;;
				((${~otherschema}):*) [[ "$urlseps$urlmetas" == *"$KEYS"* ]] && LBUFFER="$LBUFFER\\"  ;;
			esac
		fi
	fi
	zle .self-insert
}
url2filename () {
	echo "$1" | sed -e "s/http[s]*:\/\///g" | sed -e "s/[=&?\/]/./g"
}
urlglobber () {
	local -a args globbed localschema otherschema reply
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
	"$command" "${(@)args}"
}
useOfTripple_Chevrons_LeftArrows () {
	CMD='ccat < $(echo $PWD)'
	echo "Executing $CMD"
	eval "$CMD"
	CMD='ccat << $(echo $PWD)'
	echo "Executing $CMD"
	eval "$CMD"
	CMD='ccat <<< $(echo $PWD)'
	echo "Executing $CMD"
	ccat <<< $(echo $PWD);
}

vcs_info () {
	# undefined
	builtin autoload -XUz
}

vi_mode_prompt_info () {
	return 1
}

video_audio_merge () {
	usage "$0" "$#" 2 '<videofile> <audiofile> [<filetype>]' "merges videofile with audiofile to avi or other videofile" || return $?
	MP4="$1"
	M4A="$2"
	EXT=avi
	FILEEXT1=$(fileext $MP4)
	FILEEXT2=$(fileext $M4A)
	OUTPUT=${MP4//$FILEEXT/$EXT}
	[[ -n $3 ]] && EXT="$3"
	ffmpeg -i $MP4 -i $M4A -acodec copy -vcodec copy $(timestamp).$OUTPUT
}
virtualenv_prompt_info () {
	return 1
}
warn () {
	echo -e "\\033[1;33m[WARNING]\\033[0m  $*"
}
webextrun () {
	BROWSER=/Applications/Firefox.app
	if [ -n "$1" ]
	then
		BROWSER="$1"
	fi
	web-ext run --firefox="$BROWSER/Contents/MacOS/firefox-bin"
}
work_in_progress () {
	if $(git log -n 1 2>/dev/null | grep -q -c "\-\-wip\-\-")
	then
		echo "WIP!!"
	fi
}
write-attribute-value-of-tag-to-file () {
	URL="${1}"
	TAG="${2}"
	ATTR="${3}"
	TFILE="${4}"
	for i in $(get-tag-attr-value-of-url "${URL}" "${TAG}" "${ATTR}")
	do
		TMPPATH=${i//${ATTR}=\"/}
		echo $TMPPATH[0,$#TMPPATH-1] >> "${TFILE}"
	done
}
write2tmp () {
	local TARGETFILE="$TARGTFOLDER/$(url2filename ${1})"
	mkdir -p $TARGTFOLDER
	curl "${1}" > $TARGETFILE
	echo $TARGETFILE
}
write_img_2_storage () {
	IMG="$1"
	DISKNR="$2"
	FUNCNAME=$0
	isDebug && echo $@
	if [ $# -eq 2 ] && string_contains "$(file $IMG)" "MBR boot sector" && [[ $(hdiutil imageinfo -format $IMG) == "RAW*" ]] && isNumeric "$DISKNR"
	then
		CMD="sudo dd if=${IMG} of=/dev/rdisk${DISKNR} bs=1m"
		isDebug && echo $CMD
		$(echo $CMD)
	elif [ "$1" = "-h" ] || [ "$1" = "--help" ]
	then
		_print_usage
		return 0
	else
		echo "Errors: look up usage with $FUNCNAME --help"
		[ $# -lt 2 ] && echo "arguments missing"
		[ $# -gt 0 ] && ! string_contains "$(file $IMG)" "MBR boot sector" && echo "MBR boot sector is missing in $IMG"
		[ $# -gt 0 ] && ! [[ $(hdiutil imageinfo -format $IMG) == "RAW*" ]] && echo "do the conversion with echo \"hdiutil convert -format UDRW -o $IMG source.iso\""
		! isNumeric "$DISKNR" && echo "$DISKNR should be a number: execute \"diskutil list\" again and look for the right number"
		return 1
	fi
	_print_usage () {
		echo "usage: $FUNCNAME <path to bootable disk image> <disk-nr of removable storage device (e.g. USB-Stick)"
		echo "To find out the disk number execute diskutil list w/ and w/o the storage device plugged in"
		echo "Look for an entry like \"/dev/disk4 (external, physical)\""
		echo "the example above would lead to the disk-nr »4«"
		echo "Create the diskimage-file with"
		echo "hdiutil convert -format UDRW -o target.img source.iso"
		echo ""
	}
}
wwhich () {
	CURRCMD=${1}
	[[ -f $(builtin which "$CURRCMD") ]] && {
		which -S "$CURRCMD" || ls -G -G -lahF `builtin which "$CURRCMD"` 2> /dev/null || builtin which -a $CURRCMD
	}
}
wwwhich () {
	CURRCMD=${1}
	[[ -f $(builtin which "$CURRCMD") ]] && {
		which -S "$CURRCMD" || ls -G -G -lahF `builtin which "$CURRCMD"` 2> /dev/null || builtin which -a $CURRCMD
	}
}
yell () {
	echo "$0: $*" >&2
}
ymd () {
	date "+%Y%m%d"
}
ytd-set-no-cert () {
	alias ytd='youtube-dl $YOUTUBE_DL_OPTIONS_NO_CHECK_CERT'
}
ytd-unset-no-cert () {
	alias ytd='youtube-dl'
}
zle-line-finish () {
	echoti rmkx
}
zle-line-init () {
	echoti smkx
}
zsh_stats () {
	fc -l 1 | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep --color=auto -v "./" | column -c3 -s " " -t | sort -nr | nl | head -n20
}
