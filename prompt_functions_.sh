prompt () {
	local -a prompt_opts theme_active
	zstyle -g theme_active :prompt-theme cleanup || {
		[[ -o promptbang ]] && prompt_opts+=(bang) 
		[[ -o promptcr ]] && prompt_opts+=(cr) 
		[[ -o promptpercent ]] && prompt_opts+=(percent) 
		[[ -o promptsp ]] && prompt_opts+=(sp) 
		[[ -o promptsubst ]] && prompt_opts+=(subst) 
		zstyle -e :prompt-theme cleanup 'zstyle -d :prompt-theme cleanup;' 'prompt_default_setup;' ${PS1+PS1="${(q)PS1}"} ${PS2+PS2="${(q)PS2}"} ${PS3+PS3="${(q)PS3}"} ${PS4+PS4="${(q)PS4}"} ${RPS1+RPS1="${(q)RPS1}"} ${RPS2+RPS2="${(q)RPS2}"} ${RPROMPT+RPROMPT="${(q)RPROMPT}"} ${RPROMPT2+RPROMPT2="${(q)RPROMPT2}"} ${PSVAR+PSVAR="${(q)PSVAR}"} "precmd_functions=(${(q)precmd_functions[@]})" "preexec_functions=(${(q)preexec_functions[@]})" "prompt_opts=( ${prompt_opts[*]} )" 'reply=(yes)'
	}
	set_prompt "$@"
	(( ${#prompt_opts} )) && setopt noprompt{bang,cr,percent,sp,subst} "prompt${^prompt_opts[@]}"
	true
}

prompt () {
	local -a prompt_opts theme_active
	zstyle -g theme_active :prompt-theme cleanup || {
		[[ -o promptbang ]] && prompt_opts+=(bang) 
		[[ -o promptcr ]] && prompt_opts+=(cr) 
		[[ -o promptpercent ]] && prompt_opts+=(percent) 
		[[ -o promptsp ]] && prompt_opts+=(sp) 
		[[ -o promptsubst ]] && prompt_opts+=(subst) 
		zstyle -e :prompt-theme cleanup 'zstyle -d :prompt-theme cleanup;' 'prompt_default_setup;' ${PS1+PS1="${(q)PS1}"} ${PS2+PS2="${(q)PS2}"} ${PS3+PS3="${(q)PS3}"} ${PS4+PS4="${(q)PS4}"} ${RPS1+RPS1="${(q)RPS1}"} ${RPS2+RPS2="${(q)RPS2}"} ${RPROMPT+RPROMPT="${(q)RPROMPT}"} ${RPROMPT2+RPROMPT2="${(q)RPROMPT2}"} ${PSVAR+PSVAR="${(q)PSVAR}"} "precmd_functions=(${(q)precmd_functions[@]})" "preexec_functions=(${(q)preexec_functions[@]})" "prompt_opts=( ${prompt_opts[*]} )" 'reply=(yes)'
	}
	set_prompt "$@"
	(( ${#prompt_opts} )) && setopt noprompt{bang,cr,percent,sp,subst} "prompt${^prompt_opts[@]}"
	true
}

prompt-themecleanup not found

prompt_adam1_help () {
	cat <<'EOF'
This prompt is color-scheme-able.  You can invoke it thus:

  prompt adam1 [<color1> [<color2> [<color3>]]]

where the colors are for the user@host background, current working
directory, and current working directory if the prompt is split over
two lines respectively.  The default colors are blue, cyan and green.
This theme works best with a dark background.

Recommended fonts for this theme: nexus or vga or similar.  If you
don't have any of these, then specify the `plain' option to use 7-bit
replacements for the 8-bit characters.
EOF
}

prompt_adam1_precmd () {
	setopt localoptions noxtrace nowarncreateglobal
	local base_prompt_expanded_no_color base_prompt_etc
	local prompt_length space_left
	base_prompt_expanded_no_color=$(print -P "$base_prompt_no_color") 
	base_prompt_etc=$(print -P "$base_prompt%(4~|...|)%3~") 
	prompt_length=${#base_prompt_etc} 
	if [[ $prompt_length -lt 40 ]]
	then
		path_prompt="%B%F{$prompt_adam1_color2}%(4~|...|)%3~%F{white}" 
	else
		space_left=$(( $COLUMNS - $#base_prompt_expanded_no_color - 2 )) 
		path_prompt="%B%F{$prompt_adam1_color3}%${space_left}<...<%~$prompt_newline%F{white}" 
	fi
	PS1="$base_prompt$path_prompt %# $post_prompt" 
	PS2="$base_prompt$path_prompt %_> $post_prompt" 
	PS3="$base_prompt$path_prompt ?# $post_prompt" 
}

prompt_adam1_setup () {
	setopt localoptions nowarncreateglobal
	prompt_adam1_color1=${1:-'blue'} 
	prompt_adam1_color2=${2:-'cyan'} 
	prompt_adam1_color3=${3:-'green'} 
	base_prompt="%K{$prompt_adam1_color1}%n@%m%k " 
	post_prompt="%b%f%k" 
	setopt localoptions extendedglob
	base_prompt_no_color="${base_prompt//(%K{[^\\\}]#\}|%k)/}" 
	post_prompt_no_color="${post_prompt//(%K{[^\\\}]#\}|%k)/}" 
	add-zsh-hook precmd prompt_adam1_precmd
}

prompt_adam2_choose_prompt () {
	local prompt_line_1a_width=${#${(S%%)prompt_line_1a//(\%([KF1]|)\{*\}|\%[Bbkf])}} 
	local prompt_line_1b_width=${#${(S%%)prompt_line_1b//(\%([KF1]|)\{*\}|\%[Bbkf])}} 
	local prompt_padding_size=$(( COLUMNS
                                  - prompt_line_1a_width
                                  - prompt_line_1b_width )) 
	if (( prompt_padding_size > 0 ))
	then
		local prompt_padding
		eval "prompt_padding=\${(l:${prompt_padding_size}::${prompt_gfx_hyphen}:)_empty_zz}"
		prompt_line_1="$prompt_line_1a$prompt_padding$prompt_line_1b" 
		return
	fi
	prompt_padding_size=$(( COLUMNS - prompt_line_1a_width )) 
	if (( prompt_padding_size > 0 ))
	then
		local prompt_padding
		eval "prompt_padding=\${(l:${prompt_padding_size}::${prompt_gfx_hyphen}:)_empty_zz}"
		prompt_line_1="$prompt_line_1a$prompt_padding" 
		return
	fi
	local prompt_pwd_size=$(( COLUMNS - 5 )) 
	prompt_line_1="$prompt_gfx_tbox$prompt_l_paren%B%F{$prompt_adam2_color2}%$prompt_pwd_size<...<%~%<<$prompt_r_paren%b%F{$prompt_adam2_color1}$prompt_gfx_hyphen" 
}

prompt_adam2_help () {
	cat <<'EOF'
This prompt is color-scheme-able.  You can invoke it thus:

  prompt adam2 [ 8bit ] [<color1> [<color2> [<color3>] [<color4>]]

where the colors are for the hyphens, current directory, user@host,
and user input bits respectively.  The default colors are cyan, green,
cyan, and white.  This theme works best with a dark background.

If you have either UTF-8 or the `nexus' or `vga' console fonts or similar,
you can specify the `8bit' option to use 8-bit replacements for the
7-bit characters.

And you probably thought adam1 was overkill ...
EOF
}

prompt_adam2_precmd () {
	setopt localoptions extendedglob noxtrace nowarncreateglobal
	local prompt_line_1
	prompt_adam2_choose_prompt
	PS1="$prompt_line_1$prompt_newline$prompt_line_2%B%F{white}$prompt_char %b%f%k" 
	PS2="$prompt_line_2$prompt_gfx_bbox_to_mbox%B%F{white}%_> %b%f%k" 
	PS3="$prompt_line_2$prompt_gfx_bbox_to_mbox%B%F{white}?# %b%f%k" 
	zle_highlight[(r)default:*]="default:fg=$prompt_adam2_color4,bold" 
}

prompt_adam2_setup () {
	setopt localoptions nowarncreateglobal
	local prompt_gfx_tlc prompt_gfx_mlc prompt_gfx_blc
	if [[ $1 == '8bit' ]]
	then
		shift
		if [[ ${LC_ALL:-${LC_CTYPE:-$LANG}} = *UTF-8* ]]
		then
			prompt_gfx_tlc=$'\xe2\x94\x8c' 
			prompt_gfx_mlc=$'\xe2\x94\x9c' 
			prompt_gfx_blc=$'\xe2\x94\x94' 
			prompt_gfx_hyphen=$'\xe2\x94\x80' 
		else
			prompt_gfx_tlc=$'\xda' 
			prompt_gfx_mlc=$'\xc3' 
			prompt_gfx_blc=$'\xc0' 
			prompt_gfx_hyphen=$'\xc4' 
		fi
	else
		prompt_gfx_tlc='.' 
		prompt_gfx_mlc='|' 
		prompt_gfx_blc='\`' 
		prompt_gfx_hyphen='-' 
	fi
	prompt_adam2_color1=${1:-'cyan'} 
	prompt_adam2_color2=${2:-'green'} 
	prompt_adam2_color3=${3:-'cyan'} 
	prompt_adam2_color4=${4:-'white'} 
	local prompt_gfx_bbox
	prompt_gfx_tbox="%B%F{$prompt_adam2_color1}${prompt_gfx_tlc}%b%F{$prompt_adam2_color1}${prompt_gfx_hyphen}" 
	prompt_gfx_bbox="%B%F{$prompt_adam2_color1}${prompt_gfx_blc}${prompt_gfx_hyphen}%b%F{$prompt_adam2_color1}" 
	prompt_gfx_bbox_to_mbox=$'%{\e[A\r'"%}%B%F{$prompt_adam2_color1}${prompt_gfx_mlc}%b%F{$prompt_adam2_color1}${prompt_gfx_hyphen}%{"$'\e[B%}' 
	prompt_l_paren="%B%F{black}(" 
	prompt_r_paren="%B%F{black})" 
	prompt_user_host="%b%F{$prompt_adam2_color3}%n%B%F{$prompt_adam2_color3}@%b%F{$prompt_adam2_color3}%m" 
	prompt_line_1a="$prompt_gfx_tbox$prompt_l_paren%B%F{$prompt_adam2_color2}%~$prompt_r_paren%b%F{$prompt_adam2_color1}" 
	prompt_line_1b="$prompt_l_paren$prompt_user_host$prompt_r_paren%b%F{$prompt_adam2_color1}${prompt_gfx_hyphen}" 
	prompt_line_2="$prompt_gfx_bbox${prompt_gfx_hyphen}%B%F{white}" 
	prompt_char="%(!.#.>)" 
	prompt_opts=(cr subst percent) 
	add-zsh-hook precmd prompt_adam2_precmd
}

prompt_bart_help () {
	setopt localoptions nocshnullcmd noshnullcmd
	[[ $ZSH_VERSION < 4.2.2 ]] && print 'Requires ZSH_VERSION 4.2.2'$'\n'
	 <<\EOF
This prompt gives the effect of left and right prompts on the upper
line of a two-line prompt.  It also illustrates including history
text in the prompt.  The lower line is initialized from the last
(or only) line of whatever prompt was previously in effect.

    prompt bart [on|off] [color...]

You may provide up to five colors, though only three colors (red,
blue, and the default foreground) are used if no arguments are
given.  The defaults look best on a light background.

No background colors or hardwired cursor motion escapes are used,
and it is not necessary to setopt promptsubst.

The "off" token temporarily disables the theme; "on" restores it.
Note, this does NOT fully reset to the original prompt state, it
only hides/reveals the extra lines above the command line and
removes	the supporting hooks.
EOF
	[[ $(read -sek 1 "?${(%):-%S[press return]%s}") == [Qq] ]] && print -nP '\r%E' && return
	 <<\EOF

The "upper left prompt" looks like:
    machine [last command] /current/working/dir
The first three color arguments apply to these components.  The
last command is shown in standout mode if the exit status was
nonzero, or underlined if the job was stopped.

If the last command is too wide to fit without truncating the
current directory, it is put on a middle line by itself.  The
current	directory uses %~, so namedir abbreviation applies.

The "upper right prompt" looks like:
    date time
The fourth color is used for the date, and the first again for the
time.  As with RPS1, first the date and then the time disappear as
the upper left prompt grows too wide.  The clock is not live; it
changes only after each command, as does the rest of the prompt.
EOF
	[[ $(read -sek 1 "?${(%):-%S[press return]%s}") == [Qq] ]] && print -nP '\r%E' && return
	 <<\EOF

When RPS1 (RPROMPT) is set before this prompt is selected and a
fifth color is specified, that color is turned on before RPS1 is
displayed and reset after it.  Other color changes within RPS1, if
any, remain in effect.  This also applies to RPS2 (RPROMPT2).
If a fifth color is specified and there is no RPS2, PS2 (PROMPT2)
is colored and moved to RPS2.  Changes to RPS1/RPS2 are currently
not reverted when the theme is switched off.  These work best with
the TRANSIENT_RPROMPT option, which must be set separately.

This theme hijacks psvar[7] through [9] to avoid having to reset
the entire PS1 string on every command.  It uses TRAPWINCH to set
the position of the upper right prompt on a window resize, so the
prompt may not match the window width until the next command.

When setopt nopromptcr is in effect, an ANSI terminal protocol
exchange is attempted in order to determine the current cursor
column, and the width of the upper prompt is adjusted accordingly.
If your terminal is not ANSI compliant, this may cause unexpected
behavior, and in any case it may consume typeahead.  (Recommended
workaround is to setopt promptcr.)
EOF
	[[ $(read -sek 1 "?${(%):-%S[done]%s}") == $'\n' ]] || print -nP '\n%E'
}

prompt_bart_precmd () {
	setopt localoptions noxtrace noksharrays unset
	local zero='%([BSUbfksu]|[FB]{*})' escape colno lineno 
	: "${PSCMD:=$history[$[HISTCMD-1]]}"
	psvar[7]="$PSCMD" 
	psvar[8]='' 
	psvar[9]=() 
	((PSCOL == 1)) || {
		PSCOL=1 
		prompt_bart_ps1
	}
	if [[ -o promptcr ]]
	then
		eval '[[ -o promptsp ]] 2>/dev/null' || print -nP "${(l.COLUMNS.. .)}\e[s${(pl.COLUMNS..\b.)}%E\e[u" > $TTY
	else
		IFS='[;' read -s -d R escape\?$'\e[6n' lineno PSCOL < $TTY
	fi
	((PSCOL == 1)) || prompt_bart_ps1
	((colno = COLUMNS-PSCOL))
	((${#${(f)${(%%)${(S)PS1//$~zero/}}}[1]} > colno)) && psvar[9]='' 
	(((colno -= ${#${(f)${(%%)${(S)PS1//$~zero/}}}[1]}) > 0)) && psvar[8]=${(l:colno:: :)} 
}

prompt_bart_preexec () {
	setopt localoptions noxtrace noshwordsplit noksharrays unset
	local -a cmd
	cmd=(${(z)3}) 
	if [[ $cmd[1] = fg ]]
	then
		shift cmd
		cmd[1]=${cmd[1]:-%+} 
	fi
	if [[ $#cmd -eq 1 && $cmd[1] = %* ]]
	then
		PSCMD=$jobtexts[$cmd[1]] 
	elif [[ -o autoresume && -n $jobtexts[%?$2] ]]
	then
		PSCMD=$jobtexts[%?$2] 
	else
		PSCMD=$history[$HISTCMD] 
	fi
	return 0
}

prompt_bart_preview () {
	local +h PS1='%# ' 
	prompt_preview_theme bart "$@"
}

prompt_bart_ps1 () {
	setopt localoptions noxtrace noksharrays
	local -ah ps1
	local -h host hist1 hist2 dir space date time rs="%b%f%k" 
	local -h eon="%(?.[.%20(?.[%U.%S[))" eoff="%(?.].%20(?.%u].]%s))" 
	host="%{$fg[%m]%}%m$rs" 
	hist1="%9(v. . %{$fg[%h]%}$eon%7v$eoff$rs )" 
	hist2=$'%9(v.\n'"%{$fg[%h]%}$eon%7v$eoff$rs.)" 
	dir="%{$fg[%~]%}%8~$rs" 
	space=%8v 
	date="%{$fg[%D]%}%D$rs" 
	time="%{$fg[%@]%}%@$rs" 
	[[ $prompt_theme[1] = oliver ]] && PS1='[%h%0(?..:%?)]%# '  || PS1=${PS1//$prompt_newline/$'\n'} 
	ps1=(${(f)PS1}) 
	ps1=("%$[COLUMNS-PSCOL]>..>" "$host" "$hist1" "$dir" "%<<" "$space" "%$[COLUMNS-PSCOL-15](l. . $date)" "%$[COLUMNS-PSCOL-7](l.. $time)" "$hist2" $'\n' $ps1[-1]) 
	PS1="${(j::)ps1}" 
}

prompt_bart_setup () {
	setopt localoptions nolocaltraps noksharrays unset
	typeset -gA fg
	repeat 1
	do
		case "$1:l" in
			(off|disable) add-zsh-hook -D precmd "prompt_*_precmd"
				add-zsh-hook -D preexec "prompt_*_preexec"
				functions[TRAPWINCH]="${functions[TRAPWINCH]//prompt_bart_winch}" 
				[[ $prompt_theme[1] = bart ]] && PS1=${${(f)PS1}[-1]} 
				return 1 ;;
			(on|enable) shift
				[[ $prompt_theme[1] = bart ]] && break ;&
			(*) fg[%m]="%F{${1:-red}}" 
				fg[%h]="%F{${2:-blue}}" 
				fg[%~]="%F{${3:-default}}" 
				fg[%D]="%F{${4:-default}}" 
				fg[%@]="%F{${1:-red}}"  ;;
		esac
	done
	prompt_bart_ps1
	if (($# > 4))
	then
		if (($#RPS1))
		then
			RPS1="%F{$5}$RPS1%f" 
		fi
		if (($#RPS2))
		then
			RPS2="%F{$5}$RPS2%f" 
		else
			RPS2="%F{$5}<${${PS2//\%_/%^}%> }%f" 
			PS2='' 
		fi
	fi
	add-zsh-hook precmd prompt_bart_precmd
	add-zsh-hook preexec prompt_bart_preexec
	prompt_cleanup 'functions[TRAPWINCH]="${functions[TRAPWINCH]//prompt_bart_winch}"'
	functions[TRAPWINCH]="${functions[TRAPWINCH]//prompt_bart_winch}
	prompt_bart_winch" 
	return 0
}

prompt_bart_winch () {
	setopt localoptions nolocaltraps noksharrays unset
	[[ $precmd_functions = *prompt_bart_precmd* ]] && prompt_bart_ps1 || functions[TRAPWINCH]="${functions[TRAPWINCH]//prompt_bart_winch}" 
}

prompt_bigfade_help () {
	cat <<EOH
This prompt is color-scheme-able.  You can invoke it thus:

  prompt bigfade [<fade-bar> [<userhost> [<date> [<cwd>]]]]

where the parameters are the colors for the fade-bar, user@host text,
date text, and current working directory respectively.  The default
colors are blue, white, white, and yellow.  This theme works best with
a dark background.


Recommended fonts for this theme: either UTF-8, or nexus or vga or similar.
If you don't have any of these, the 8-bit characters will probably look
stupid.
EOH
}

prompt_bigfade_preview () {
	if (( ! $#* ))
	then
		prompt_preview_theme bigfade
		print
		prompt_preview_theme bigfade red white grey white
	else
		prompt_preview_theme bigfade "$@"
	fi
}

prompt_bigfade_setup () {
	local fadebar=${1:-'blue'} 
	local userhost=${2:-'white'} 
	local date=${3:-'white'} 
	local cwd=${4:-'yellow'} 
	local -A schars
	autoload -Uz prompt_special_chars
	prompt_special_chars
	PS1="%B%F{$fadebar}$schars[333]$schars[262]$schars[261]$schars[260]%B%F{$userhost}%K{$fadebar}%n@%m%b%k%f%F{$fadebar}%K{black}$schars[260]$schars[261]$schars[262]$schars[333]%b%f%k%F{$fadebar}%K{black}$schars[333]$schars[262]$schars[261]$schars[260]%B%F{$date}%K{black} %D{%a %b %d} %D{%I:%M:%S%P}$prompt_newline%B%F{$cwd}%K{black}%d>%b%f%k " 
	PS2="%B%F{$fadebar}$schars[333]$schars[262]$schars[261]$schars[260]%b%F{$fadebar}%K{black}$schars[260]$schars[261]$schars[262]$schars[333]%F{$fadebar}%K{black}$schars[333]$schars[262]$schars[261]$schars[260]%B%F{$fadebar}>%b%f%k " 
	prompt_opts=(cr subst percent) 
}

prompt_cleanup () {
	local -a cleanup_hooks
	if zstyle -g cleanup_hooks :prompt-theme cleanup
	then
		cleanup_hooks+=(';' "$@") 
		zstyle -e :prompt-theme cleanup "${cleanup_hooks[@]}"
	elif (( $+prompt_preview_cleanup == 0 ))
	then
		print -u2 "prompt_cleanup: no prompt theme active"
		return 1
	fi
}

prompt_clint_help () {
	cat <<'EOF'

  prompt clint [<color1> [<color2> [<color3> [<color4> [<color5>]]]]]

  defaults are red, cyan, green, yellow, and white, respectively.

EOF
}

prompt_clint_precmd () {
	setopt noxtrace noksharrays localoptions
	local exitstatus=$? 
	local git_dir git_ref
	psvar=() 
	[[ $exitstatus -ge 128 ]] && psvar[1]=" $signals[$exitstatus-127]"  || psvar[1]="" 
	[[ -o interactive ]] && jobs -l
	vcs_info
	[[ -n $vcs_info_msg_0_ ]] && psvar[2]="$vcs_info_msg_0_" 
}

prompt_clint_setup () {
	local -a pcc
	local -A pc
	local p_date p_tty p_plat p_ver p_userpwd p_apm p_shlvlhist p_rc p_end p_win
	autoload -Uz vcs_info
	pcc[1]=${1:-${${SSH_CLIENT+'yellow'}:-'red'}} 
	pcc[2]=${2:-'cyan'} 
	pcc[3]=${3:-'green'} 
	pcc[4]=${4:-'yellow'} 
	pcc[5]=${5:-'white'} 
	pc['\[']="%F{$pcc[1]}[" 
	pc['\]']="%F{$pcc[1]}]" 
	pc['<']="%F{$pcc[1]}<" 
	pc['>']="%F{$pcc[1]}>" 
	pc['\(']="%F{$pcc[1]}(" 
	pc['\)']="%F{$pcc[1]})" 
	p_date="$pc['\[']%F{$pcc[2]}%D{%a %y/%m/%d %R %Z}$pc['\]']" 
	p_tty="$pc['\[']%F{$pcc[3]}%l$pc['\]']" 
	p_plat="$pc['\[']%F{$pcc[2]}${MACHTYPE}/${OSTYPE}/$(uname -r)$pc['\]']" 
	p_ver="$pc['\[']%F{$pcc[2]}${ZSH_VERSION}$pc['\]']" 
	[[ -n "$WINDOW" ]] && p_win="$pc['\(']%F{$pcc[4]}$WINDOW$pc['\)']" 
	p_userpwd="$pc['<']%F{$pcc[3]}%n@%m$p_win%F{$pcc[5]}:%F{$pcc[4]}%~$pc['>']" 
	local p_vcs="%(2v.%U%2v%u.)" 
	p_shlvlhist="%fzsh%(2L./$SHLVL.) %B%h%b " 
	p_rc="%(?..[%?%1v] )" 
	p_end="%f%B%#%b " 
	typeset -ga zle_highlight
	zle_highlight[(r)default:*]=default:$pcc[2] 
	prompt="$p_date$p_tty$p_plat$p_ver
$p_userpwd
$p_shlvlhist$p_rc$p_vcs$p_end" 
	PS2='%(4_.\.)%3_> %E' 
	add-zsh-hook precmd prompt_clint_precmd
}

prompt_default_setup () {
	PS1='%m%# ' 
	PS2='%_> ' 
	PS3='?# ' 
	PS4='+%N:%i> ' 
	unset RPS1 RPS2 RPROMPT RPROMPT2
	prompt_opts=(cr percent sp) 
}

prompt_elite2_help () {
	cat <<EOH
This prompt is color-scheme-able.  You can invoke it thus:

  prompt elite2 [<text-color> [<parentheses-color>]]

The default colors are both cyan.  This theme works best with a dark
background.

Recommended fonts for this theme: either UTF-8, or nexus or vga or similar.
If you don't have any of these, the 8-bit characters will probably look
stupid.
EOH
}

prompt_elite2_preview () {
	local color colors
	colors=(red yellow green blue magenta) 
	if (( ! $#* ))
	then
		for ((i = 1; i <= $#colors; i++ )) do
			color=$colors[$i] 
			prompt_preview_theme elite2 $color
			(( i < $#colors )) && print
		done
	else
		prompt_preview_theme elite2 "$@"
	fi
}

prompt_elite2_setup () {
	local text_col=${1:-'cyan'} 
	local parens_col=${2:-$text_col} 
	local -A schars
	autoload -Uz prompt_special_chars
	prompt_special_chars
	local text="%b%F{$text_col}" 
	local parens="%B%F{$parens_col}" 
	local punct="%B%F{black}" 
	local reset="%b%f" 
	local lpar="$parens($text" 
	local rpar="$parens)$text" 
	PS1="$punct$schars[332]$text$schars[304]$lpar%n$punct@$text%m$rpar$schars[304]$lpar%!$punct/$text%y$rpar$schars[304]$lpar%D{%I:%M%P}$punct:$text%D{%m/%d/%y}$rpar$schars[304]$punct-$reset$prompt_newline$punct$schars[300]$text$schars[304]$lpar%#$punct:$text%~$rpar$schars[304]$punct-$reset " 
	PS2="$parens$schars[304]$text$schars[304]$punct-$reset " 
	prompt_opts=(cr subst percent) 
}

prompt_elite_help () {
	cat <<EOH
This prompt is color-scheme-able.  You can invoke it thus:

  prompt elite [<text-color> [<punctuation-color>]]

The default colors are red and blue respectively.  This theme is
intended for use with a black background.

Recommended fonts for this theme: either UTF-8, or nexus or vga or similar.
If you don't have any of these, the 8-bit characters will probably look
stupid.
EOH
}

prompt_elite_preview () {
	if (( ! $#* ))
	then
		prompt_preview_theme elite
		print
		prompt_preview_theme elite green yellow
	else
		prompt_preview_theme elite "$@"
	fi
}

prompt_elite_setup () {
	local text=${1:-'red'} 
	local punctuation=${2:-'blue'} 
	local -A schars
	autoload -Uz prompt_special_chars
	prompt_special_chars
	PS1="%F{$text}$schars[332]$schars[304]%F{$punctuation}(%F{$text}%n%F{$punctuation}@%F{$text}%m%F{$punctuation})%F{$text}-%F{$punctuation}(%F{$text}%D{%I:%M%P}%F{$punctuation}-:-%F{$text}%D{%m}%F{$punctuation}%F{$text}/%D{%d}%F{$punctuation})%F{$text}$schars[304]-%F{$punctuation}$schars[371]%F{$text}-$schars[371]$schars[371]%F{$punctuation}$schars[372]$prompt_newline%F{$text}$schars[300]$schars[304]%F{$punctuation}(%F{$text}%1~%F{$punctuation})%F{$text}$schars[304]$schars[371]%F{$punctuation}$schars[372]%f" 
	PS2="> " 
	prompt_opts=(cr subst percent) 
}

prompt_fade_help () {
	cat <<EOH
This prompt is color-scheme-able.  You can invoke it thus:

  prompt fade [<fade-bar-and-cwd> [<userhost> [<date>]]] 

where the parameters are the colors for the fade-bar and current
working directory, user@host text, and date text respectively.  The
default colors are green, white, and white.  This theme works best
with a dark background.

Recommended fonts for this theme: either UTF-8, or nexus or vga or similar.
If you don't have any of these, the 8-bit characters will probably look
stupid.
EOH
}

prompt_fade_preview () {
	local color colors
	colors=(red yellow green blue magenta) 
	if (( ! $#* ))
	then
		for ((i = 1; i <= $#colors; i++ )) do
			color=$colors[$i] 
			prompt_preview_theme fade $color
			print
		done
		prompt_preview_theme fade white grey blue
	else
		prompt_preview_theme fade "$@"
	fi
}

prompt_fade_setup () {
	local fadebar_cwd=${1:-'green'} 
	local userhost=${2:-'white'} 
	local date=${3:-'white'} 
	local -A schars
	autoload -Uz prompt_special_chars
	prompt_special_chars
	PS1="%F{$fadebar_cwd}%B%K{$fadebar_cwd}$schars[333]$schars[262]$schars[261]$schars[260]%F{$userhost}%K{$fadebar_cwd}%B%n@%m%b%F{$fadebar_cwd}%K{black}$schars[333]$schars[262]$schars[261]$schars[260]%F{$date}%K{black}%B %D{%a %b %d} %D{%I:%M:%S%P} $prompt_newline%F{$fadebar_cwd}%K{black}%B%~/%b%k%f " 
	PS2="%F{$fadebar_cwd}%K{black}$schars[333]$schars[262]$schars[261]$schars[260]%f%k>" 
	prompt_opts=(cr subst percent) 
}

prompt_fire_help () {
	cat <<EOH
This prompt is color-scheme-able.  You can invoke it thus:

  prompt fire [<fire1> [<fire2> [<fire3> [<userhost> [<date> [<cwd>]]]]]]

where the parameters are the three fire colors, and the colors for the
user@host text, date text, and current working directory respectively.
The default colors are yellow, yellow, red, white, white, and yellow.
This theme works best with a dark background.

Recommended fonts for this theme: either UTF-8, or nexus or vga or similar.
If you don't have any of these, the 8-bit characters will probably look
stupid.
EOH
}

prompt_fire_preview () {
	if (( ! $#* ))
	then
		prompt_preview_theme fire
		print
		prompt_preview_theme fire red magenta blue white white white
	else
		prompt_preview_theme fire "$@"
	fi
}

prompt_fire_setup () {
	local fire1=${1:-'yellow'} 
	local fire2=${2:-'yellow'} 
	local fire3=${3:-'red'} 
	local userhost=${4:-'white'} 
	local date=${5:-'white'} 
	local cwd=${6:-'yellow'} 
	local -a schars
	autoload -Uz prompt_special_chars
	prompt_special_chars
	local GRAD1="%{$schars[333]$schars[262]$schars[261]$schars[260]%}" 
	local GRAD2="%{$schars[260]$schars[261]$schars[262]$schars[333]%}" 
	local COLOR1="%B%F{$fire1}%K{$fire2}" 
	local COLOR2="%B%F{$userhost}%K{$fire2}" 
	local COLOR3="%b%F{$fire3}%K{$fire2}" 
	local COLOR4="%b%F{$fire3}%K{black}" 
	local COLOR5="%B%F{$cwd}%K{black}" 
	local COLOR6="%B%F{$date}%K{black}" 
	local GRAD0="%b%f%k" 
	PS1=$COLOR1$GRAD1$COLOR2'%n@%m'$COLOR3$GRAD2$COLOR4$GRAD1$COLOR6' %D{%a %b %d} %D{%I:%M:%S%P} '$prompt_newline$COLOR5'%~/'$GRAD0' ' 
	PS2=$COLOR1$GRAD1$COLOR3$GRAD2$COLOR4$GRAD1$COLOR5'>'$GRAD0' ' 
	prompt_opts=(cr subst percent) 
}

prompt_off_setup () {
	prompt_default_setup 2> /dev/null
	PS1="%# " 
	PS2="> " 
	PS3='?# ' 
	PS4='+> ' 
	prompt_opts=(cr percent sp) 
}

prompt_oliver_help () {
	cat <<'ENDHELP'
With this prompt theme, the prompt contains the current directory,
history number, number of jobs (if non-zero) and the previous
command's exit code (if non-zero) and a final character which
depends on priviledges.

The colour of the prompt depends on two associative arrays -
$pcolour and $tcolour. Each array is indexed by the name of the
local host. Alternatively, the colour can be set with parameters
to prompt. To specify colours, use English words like 'yellow',
optionally preceded by 'bold'.

The hostname and username are also included unless they are in the
$normal_hosts or $normal_users array.
ENDHELP
}

prompt_oliver_setup () {
	prompt_opts=(cr subst percent) 
	[[ "${(t)pcolour}" != assoc* ]] && typeset -Ag pcolour
	[[ "${(t)tcolour}" != assoc* ]] && typeset -Ag tcolour
	local pcol=${1:-${pcolour[${HOST:=`hostname`}]:-bold}} 
	local pcolr="%F{${${pcol#bold}:-default}}" 
	[[ $pcol = bold* ]] && pcolr=%B$pcolr 
	local tcol=${2:-${tcolour[$HOST]}} 
	local tcolr="fg=${${tcol#bold}:-default}" 
	[[ $tcol = bold* ]] && tcolr=bold,$tcolr 
	local a host="%m:" user="%n " 
	[[ $HOST == (${(j(|))~normal_hosts}) ]] && host="" 
	[[ $LOGNAME == (root|${(j(|))~normal_users}) ]] && user="" 
	PS1="$pcolr$user$host%~%"'$((COLUMNS-12))'"(l.$prompt_newline. )[%h%1(j.%%%j.)%0(?..:%?)]%# %b%f%k" RPS2='<%^' 
	PS2='' 
	typeset -ga zle_highlight
	zle_highlight[(r)default:*]=default:$tcolr 
}

prompt_preview_safely () {
	emulate -L zsh
	print -P "%b%f%k"
	if [[ -z "$prompt_themes[(r)$1]" ]]
	then
		print "Unknown theme: $1"
		return
	fi
	local +h PS1=$PS1 PS2=$PS2 PS3=$PS3 PS4=$PS4 RPS1=$RPS1 RPS2=$RPS2 
	local +h PROMPT=$PROMPT RPROMPT=$RPOMPT RPROMPT2=$RPROMPT2 PSVAR=$PSVAR 
	local -a precmd_functions preexec_functions prompt_preview_cleanup
	local -aLl +h zle_highlight
	{
		zstyle -g prompt_preview_cleanup :prompt-theme cleanup
		{
			zstyle -d :prompt-theme cleanup
			prompt_${1}_setup
			if typeset +f prompt_${1}_preview >&/dev/null
			then
				prompt_${1}_preview "$@[2,-1]"
			else
				prompt_preview_theme "$@"
			fi
		} always {
			zstyle -t :prompt-theme cleanup
		}
	} always {
		(( $#prompt_preview_cleanup )) && zstyle -e :prompt-theme cleanup "${prompt_preview_cleanup[@]}"
	}
}

prompt_preview_theme () {
	emulate -L zsh
	(( $+prompt_preview_cleanup )) || {
		prompt_preview_safely "$@"
		return
	}
	local -a prompt_opts
	print -n "$1 theme"
	(( $#* > 1 )) && print -n " with parameters \`$*[2,-1]'"
	print ":"
	prompt_${1}_setup "$@[2,-1]"
	(( ${#prompt_opts} )) && setopt noprompt{bang,cr,percent,sp,subst} "prompt${^prompt_opts[@]}"
	[[ -n ${precmd_functions[(r)prompt_${1}_precmd]} ]] && prompt_${1}_precmd
	[[ -o promptcr ]] && print -n $'\r'
	:
	print -P "${PS1}command arg1 arg2 ... argn"
	[[ -n ${preexec_functions[(r)prompt_${1}_preexec]} ]] && prompt_${1}_preexec
}

prompt_preview_cleanup not found

prompt_pws_help () {
	cat <<'EOF'
Simple prompt which tries to display only the information you need.
- highlighted parenthesised status if last command had non-zero status
- bold + if shell is not at top level (may need tweaking if there
  is another shell in the process history of your terminal)
- number of background jobs in square brackets if non-zero
- time in yellow on black, with Ding! on the hour.
I usually use this in a white on black terminal.
EOF
}

prompt_pws_setup () {
	PS1='%K{white}%F{red}%(?..(%?%))''%K{black}%F{white}%B%(2L.+.)%(1j.[%j].)''%F{yellow}%(t.Ding!.%D{%L:%M})''%f%k%b%# ' 
}

prompt_redhat_setup () {
	PS1='[%n@%m %1~]%(#.#.$) ' 
	PS2="> " 
	prompt_opts=(cr percent) 
}

prompt_restore_setup () {
	zstyle -t :prompt-theme cleanup
}

prompt_special_chars () {
	typeset -gA schars
	if [[ ${LC_ALL:-${LC_CTYPE:-$LANG}} = *(UTF-8|utf8)* ]]
	then
		schars[300]=$'\xe2\x94\x94' 
		schars[304]=$'\xe2\x94\x8c' 
		schars[332]=$'\xe2\x94\x8c' 
		schars[333]=$'\xe2\x96\x88' 
		schars[371]=$'\xc2\xa8' 
		schars[372]=$'\xcb\x99' 
		schars[262]=$'\xe2\x96\x93' 
		schars[261]=$'\xe2\x96\x92' 
		schars[260]=$'\xe2\x96\x91' 
	else
		local code
		for code in 300 304 332 333 371 372 262 261 260
		do
			eval "schars[$code]=\$'\\$code'"
		done
	fi
}

prompt_suse_setup () {
	PS1="%n@%m:%~/ > " 
	PS2="> " 
	prompt_opts=(cr percent) 
}

prompt_walters_help () {
	cat <<'EOF'
This prompt is color-scheme-able.  You can invoke it thus:

  prompt walters [<color1>]

where the color is for the right-hand prompt.

This prompt was stolen from Colin Walters <walters@debian.org>,
who gives credit to Michel Daenzer <daenzer@debian.org>.
EOF
}

prompt_walters_setup () {
	if [[ "$TERM" != "dumb" ]]
	then
		PS1='%B%(?..[%?] )%b%n@%U%m%u> ' 
		RPS1="%F{${1:-green}}%~%f" 
	else
		PS1="%(?..[%?] )%n@%m:%~> " 
	fi
	prompt_opts=(cr percent) 
}

prompt_zefram_precmd () {
	local exitstatus=$? 
	setopt localoptions noxtrace noksharrays
	psvar=(SIG) 
	[[ $exitstatus -gt 128 ]] && psvar[1]=SIG$signals[$exitstatus-127] 
	[[ $psvar[1] = SIG ]] && psvar[1]=$exitstatus 
	jobs % > /dev/null 2>&1 && psvar[2]= 
}

prompt_zefram_setup () {
	PS1='[%(2L.%L/.)'$ZSH_VERSION']%(?..%B{%v}%b)%n%(2v.%B@%b.@)%m:%B%~%b%(!.#.>) ' 
	PS2='%(4_:... :)%3_> ' 
	prompt_opts=(cr subst percent) 
	add-zsh-hook precmd prompt_zefram_precmd
}

promptinit () {
	emulate -L zsh
	setopt extendedglob
	local ppath='' name theme 
	local -a match mbegin mend
	for theme in $^fpath/prompt_*_setup(N)
	do
		if [[ $theme == */prompt_(#b)(*)_setup ]]
		then
			name="$match[1]" 
			if [[ -r "$theme" ]]
			then
				prompt_themes=($prompt_themes $name) 
				autoload -Uz prompt_${name}_setup
			else
				print "Couldn't read file $theme containing theme $name."
			fi
		else
			print "Eh?  Mismatch between glob patterns in promptinit."
		fi
	done
	autoload -Uz add-zsh-hook
	prompt_newline=$'\n%{\r%}' 
}

prompt () {
	local -a prompt_opts theme_active
	zstyle -g theme_active :prompt-theme cleanup || {
		[[ -o promptbang ]] && prompt_opts+=(bang) 
		[[ -o promptcr ]] && prompt_opts+=(cr) 
		[[ -o promptpercent ]] && prompt_opts+=(percent) 
		[[ -o promptsp ]] && prompt_opts+=(sp) 
		[[ -o promptsubst ]] && prompt_opts+=(subst) 
		zstyle -e :prompt-theme cleanup 'zstyle -d :prompt-theme cleanup;' 'prompt_default_setup;' ${PS1+PS1="${(q)PS1}"} ${PS2+PS2="${(q)PS2}"} ${PS3+PS3="${(q)PS3}"} ${PS4+PS4="${(q)PS4}"} ${RPS1+RPS1="${(q)RPS1}"} ${RPS2+RPS2="${(q)RPS2}"} ${RPROMPT+RPROMPT="${(q)RPROMPT}"} ${RPROMPT2+RPROMPT2="${(q)RPROMPT2}"} ${PSVAR+PSVAR="${(q)PSVAR}"} "precmd_functions=(${(q)precmd_functions[@]})" "preexec_functions=(${(q)preexec_functions[@]})" "prompt_opts=( ${prompt_opts[*]} )" 'reply=(yes)'
	}
	set_prompt "$@"
	(( ${#prompt_opts} )) && setopt noprompt{bang,cr,percent,sp,subst} "prompt${^prompt_opts[@]}"
	true
}

