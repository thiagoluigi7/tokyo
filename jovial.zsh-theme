# tokyo.zsh-theme based on
# jovial.zsh-theme
# https://github.com/zthxxx/jovial
# Inspired by
# https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/tokyo.omp.json


export TOKYO_VERSION='1.0.0'


# Development code style:
#
# use "@tok."" prefix for tokyo internal functions
# use "kebab-case" style for function names and mapping key
# use "snake_case" for function's internal variables, and also declare it with "local" mark
# use "CAPITAL_SNAKE_CASE" for global variables that design for user customization
# use "snake_case" for global but only used for tokyo theme
# use indent spaces 4

# https://zsh.sourceforge.io/Doc/Release/Functions.html#Hook-Functions
autoload -Uz add-zsh-hook

# https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fdatetime-Module
zmodload zsh/datetime
zmodload zsh/zpty
zmodload zsh/zle

# expand and execute the PROMPT variable
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
setopt prompt_subst

# setup this flag for hidden python `venv` default prompt
# https://github.com/python/cpython/blob/3.10/Lib/venv/scripts/common/activate#L56
export VIRTUAL_ENV_DISABLE_PROMPT=true

# the default `TERM`` in `screen` command is 'linux' which will cause colorless in terminal,
# so set it with a compatible colorful value,
# otherwise shouldn't override TERM because it maybe a specific user setting.
if [[ ${TERM} == 'linux' ]]; then
  export TERM=xterm-256color
fi

# `\e[00m` is SGR (Select Graphic Rendition) parameters
# which to disable all visual effects.
# this literal as same as `reset_color` defined in [zsh/colors](https://github.com/zsh-users/zsh/blob/zsh-5.8/Functions/Misc/colors#L98)
#
# SGR link: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
# "%{ %}" is escape values in Prompt-Expansion (vcs_info style) (for used in `print -P`)
typeset -g sgr_reset="%{\e[00m%}"


# tokyo theme element symbol mapping
#
# (the syntax `typeset -A xxx` is means to declare a `associative-array` in zsh, it's like `dictionary`)
# more `typeset` syntax see https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html
typeset -gA TOKYO_SYMBOL=(
    corner.top    '╭─'
    corner.bottom '╰─'

    git.dirty '✘✘✘'
    git.clean '✔'

    ## preset arrows
    # arrow '─>'
    arrow '─▶'
    arrow '▶'
    # arrow '─➤'
    # arrow.git-dirty '(ﾉ˚Д˚)ﾉ'
    # arrow.git-clean '(๑˃̵ᴗ˂̵)و'
    arrow.git-dirty '▶'
    arrow.git-clean '▶'
)


# tokyo theme colors mapping
# use `sheet:color` plugin function to see color table
# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html#Visual-effects
# format quickref:
#
#   %F{xxx}         => foreground color (text color)
#   %K{xxx}         => background color (color-block)
#   %B              => bold
#   %U              => underline
#   ${sgr_reset}    => reset all effect (provide by tokyo)
#
typeset -gA TOKYO_PALETTE=(
    # hostname
    host '%F{157}'

    # common user name
    user '%F{253}'

    # only root user
    root '%B%F{203}'

    # current work dir path
    path '%B%F{228}%}'

    # git status info (dirty or clean / rebase / merge / cherry-pick)
    git '%F{159}'

    # virtual env activate prompt for python
    venv '%F{159}'

    # current time when prompt render, pin at end-of-line
    time '%F{254}'

    # elapsed time of last command executed
    elapsed '%F{222}'

    # exit code of last command
    exit.mark '%F{246}'
    exit.code '%B%F{203}'

    # 'conj.': short for 'conjunction', like as, at, in, on, using
    conj. '%F{102}'

    # shell typing area pointer
    typing '%F{252}'

    # for other common case text color
    normal '%F{252}'

    success '%F{040}'
    error '%F{203}'
)

# parts dispaly order from left to right of tokyo theme at the first line
typeset -ga TOKYO_PROMPT_ORDER=( host user path dev-env git-info )

# prompt parts priority from high to low, for `responsive design`.
# decide whether to still keep dispaly while terminal width is no enough;
#
# the highest priority element will always keep dispaly;
# `current-time` will always auto detect rest spaces, it's lowest priority
typeset -ga TOKYO_PROMPT_PRIORITY=(
    path
    git-info
    user
    host
    dev-env
)

# pin last command execute elapsed, if the threshold is reached
typeset -gi TOKYO_EXEC_THRESHOLD_SECONDS=4

# prefixes and suffixes of tokyo prompt part
# all values wrapped in `${...}` will be subject to `Prompt-Expansion` during initialization
typeset -gA TOKYO_AFFIXES=(
    host.prefix            '${TOKYO_PALETTE[normal]}['
    # hostname/username use `Prompt-Expansion` syntax in default
    #   https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
    # but you can override it with simple constant string
    hostname               '${(%):-%m}'
    host.suffix            '${TOKYO_PALETTE[normal]}] ${TOKYO_PALETTE[conj.]}as'

    user.prefix            ' '
    username               '${(%):-%n}'
    user.suffix            ' ${TOKYO_PALETTE[conj.]}in'

    path.prefix            ' '
    current-dir            '%~'
    path.suffix            ''

    dev-env.prefix         ' '
    dev-env.suffix         ''

    git-info.prefix        ' ${TOKYO_PALETTE[conj.]}on ${TOKYO_PALETTE[normal]}('
    git-info.suffix        '${TOKYO_PALETTE[normal]})'

    venv.prefix            ' ${TOKYO_PALETTE[normal]}('
    venv.suffix            '${TOKYO_PALETTE[normal]})'

    exec-elapsed.prefix    ' ${TOKYO_PALETTE[elapsed]}~'
    exec-elapsed.suffix    ' '

    exit-code.prefix       ' ${TOKYO_PALETTE[exit.mark]}exit:'
    exit-code.suffix       ' '

    current-time.prefix    ' '
    current-time.suffix    ' '
)



@tok.iscommand() { [[ -e ${commands[$1]} ]] }

# https://superuser.com/questions/380772/removing-ansi-color-codes-from-text-stream
# https://www.refining-linux.org/archives/52-ZSH-Gem-18-Regexp-search-and-replace-on-parameters.html
@tok.unstyle-len() {
    # use (%) for expand `prompt` format like color `%F{123}` or username `%n`
    # https://zsh.sourceforge.io/Doc/Release/Expansion.html#Parameter-Expansion-Flags
    # https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html#Prompt-Expansion
    local str="${(%)1}"
    local store_var="$2"

    ## regexp with POSIX mode
    ## compatible with macOS Catalina default zsh
    #
    ## !!! NOTE: note that the "empty space" in this regexp at the beginning is not a common "space",
    ## it is the ANSI escape ESC char ("\e") which is cannot wirte as literal in there
    local unstyle_regex="\[[0-9;]*[a-zA-Z]"

    # inspired by zsh builtin regexp-replace
    # https://github.com/zsh-users/zsh/blob/zsh-5.8/Functions/Misc/regexp-replace
    # it same as next line
    # regexp-replace str "${unstyle_regex}" ''

    local unstyled
    # `MBEGIN` `MEND` are zsh builtin variables
    # https://zsh.sourceforge.io/Doc/Release/Expansion.html

    while [[ -n ${str} ]]; do
        if [[ ${str} =~ ${unstyle_regex} ]]; then
            # append initial part and subsituted match
            unstyled+=${str[1,MBEGIN-1]}
            # truncate remaining string
            str=${str[MEND+1,-1]}
        else
            break
        fi
    done
    unstyled+=${str}

    eval ${store_var}=${#unstyled}
}


# @tok.rev-parse-find(filename:string, path:string, output:boolean)
# reverse from path to root wanna find the targe file
# output: whether show the file path
@tok.rev-parse-find() {
    local target="$1"
    local current_path="${2:-${PWD}}"
    local whether_output=${3:-false}

    local root_regex='^(/)[^/]*$'
    local dirname_regex='^((/[^/]+)+)/[^/]+/?$'

    # [hacking] it's same as  parent_path=`\dirname ${current_path}`,
    # but better performance due to reduce subprocess call
    # `match` is zsh builtin variable
    # https://zsh.sourceforge.io/Doc/Release/Expansion.html
    if [[ ${current_path} =~ ${root_regex} || ${current_path} =~ ${dirname_regex} ]]; then
        local parent_path="${match[1]}"
    else
        return 1
    fi

    while [[ ${parent_path} != "/" && ${current_path} != "${HOME}" ]]; do
        if [[ -e ${current_path}/${target} ]]; then
            if ${whether_output}; then
                echo "${current_path}";
            fi
            return 0
        fi
        current_path="${parent_path}"

        # [hacking] it's same as  parent_path=`\dirname ${parent_path}`,
        # but better performance due to reduce subprocess call
        if [[ ${parent_path} =~ ${root_regex} || ${parent_path} =~ ${dirname_regex} ]]; then
            parent_path="${match[1]}"
        else
            return 1
        fi
    done
    return 1
}


# map for { job-name -> file-descriptor }
typeset -gA tokyo_async_jobs=()
# map for { file-descriptor -> job-name }
typeset -gA tokyo_async_fds=()
# map for { job-name -> callback }
typeset -gA tokyo_async_callbacks=()

# tiny util for run async job with callback via zpty and zle
# inspired by https://github.com/mafredri/zsh-async
#
# @tok.async <job-name> <handler-func> <callback-func>
#
# `handler-func`  cannot handle with not any param
# `callback-func` can only receive one param: <output-data>
#
# https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html
@tok.async() {
    local job_name=$1
    local handler=$2
    local callback=$3

    # if job is running, donot run again
    # by believe all zpty job will clear itself by trigger in callback
    # it's an alternative to`zpty -t ${job_name}`
    # because zpty test job done not means the job cleared, they cannot create again
    if [[ -n ${tokyo_async_jobs[${job_name}]} ]]; then
        return
    fi

    # async run as non-blocking output subprocess in zpty
    zpty -b ${job_name} @tok.zpty-worker ${handler}
    # REPLY a file-descriptor which was opened by the lost zpty job
    local -i fd=${REPLY}

    tokyo_async_jobs[${job_name}]=${fd}
    tokyo_async_fds[${fd}]=${job_name}
    tokyo_async_callbacks[${job_name}]=${callback}

    zle -F ${fd} @tok.zle-callback-handler
}

@tok.zpty-worker() {
    local handler=$1

    ${handler}

    # always print new line to avoid handler has not any output that cannot trigger callback
    echo ''
}

# callback for zle, forward zpty output to really job callback
@tok.zle-callback-handler() {
    local -i fd=$1
    local data=''

    local job_name=${tokyo_async_fds[${fd}]}
    local callback=${tokyo_async_callbacks[${job_name}]}

    # assume the job only have one-line output
    # so if the handler called, we can read all message at this time,
    # then we can remove callback and kill subprocess safety
    zle -F ${fd}
    zpty -r ${job_name} data
    zpty -d ${job_name}

    unset "tokyo_async_jobs[${job_name}]"
    unset "tokyo_async_fds[${fd}]"
    unset "tokyo_async_callbacks[${job_name}]"

    # forward callback, and trimming any leading/trailing whitespace same as command s  ubstitution
    # `[[:graph:]]` is glob for whitespace
    # https://zsh.sourceforge.io/Doc/Release/Expansion.html#Glob-Operators
    # https://stackoverflow.com/questions/68259691/trimming-whitespace-from-the-ends-of-a-string-in-zsh/68288735#68288735
    ${callback} "${(MS)data##[[:graph:]]*[[:graph:]]}"
}


typeset -g tokyo_prompt_part_changed=false

@tok.infer-prompt-rerender() {
    local has_changed="$1"

    if [[ ${has_changed} == true ]]; then
        tokyo_prompt_part_changed=true
    fi

    # only rerender if changed and all async jobs done
    if [[ ${tokyo_prompt_part_changed} == true ]] && (( ! ${(k)#tokyo_async_jobs} )); then
        tokyo_prompt_part_changed=false

        # only call zle rerender while prompt prepared
        if (( tokyo_prompt_run_count > 1 )); then
            zle reset-prompt
        fi
    fi
}

zle -N @tok.infer-prompt-rerender



# variables for git prompt
typeset -g tokyo_rev_git_dir=""
typeset -g tokyo_is_git_dirty=false

@tok.chpwd-git-dir-hook() {
    # it's the same as  tokyo_rev_git_dir=`\git rev-parse --git-dir 2>/dev/null`
    # but better performance due to reduce subprocess call

    local project_root_dir="$(@tok.rev-parse-find .git '' true)"

    if [[ -n ${project_root_dir} ]]; then
        tokyo_rev_git_dir="${project_root_dir}/.git"
    else
        tokyo_rev_git_dir=""
    fi
}

add-zsh-hook chpwd @tok.chpwd-git-dir-hook
@tok.chpwd-git-dir-hook


typeset -gi tokyo_prompt_run_count=0

# tokyo prompt element value
typeset -gA tokyo_parts=() tokyo_part_lengths=()
typeset -gA tokyo_previous_parts=() tokyo_previous_lengths=()

@tok.reset-prompt-parts() {
    for key in ${(k)tokyo_parts}; do
        tokyo_previous_parts[${key}]="${tokyo_parts[${key}]}"
        tokyo_previous_lengths[${key}]="${tokyo_part_lengths[${key}]}"
    done

    tokyo_parts=(
        exec-elapsed    ''
        exit-code       ''
        margin-line     ''
        host            ''
        user            ''
        path            ''
        dev-env         ''
        git-info        ''
        current-time    ''
        typing          ''
        venv            ''
    )

    tokyo_part_lengths=(
        host            0
        user            0
        path            0
        dev-env         0
        git-info        0
        current-time    0
    )
}

# store calculated lengths of `TOKYO_AFFIXES` part
typeset -gA tokyo_affix_lengths=()

@tok.init-affix() {
    local key result
    for key in ${(k)TOKYO_AFFIXES}; do
        eval "TOKYO_AFFIXES[${key}]"=\""${TOKYO_AFFIXES[${key}]}"\"
        # remove `.prefix`, `.suffix`
        # `xxx.prefix`` -> `xxx`
        local part="${key/%.(prefix|suffix)/}"

        local -i affix_len
        @tok.unstyle-len "${TOKYO_AFFIXES[${key}]}" affix_len

        tokyo_affix_lengths[${part}]=$((
            ${tokyo_affix_lengths[${part}]:-0}
            + affix_len
        ))
    done
}

@tok.set-typing-pointer() {
    tokyo_parts[typing]="${TOKYO_PALETTE[typing]}"

    if [[ -n ${tokyo_rev_git_dir} ]]; then
        if [[ ${tokyo_is_git_dirty} == false ]]; then
            tokyo_parts[typing]+="${TOKYO_SYMBOL[arrow.git-clean]}"
        else
            tokyo_parts[typing]+="${TOKYO_SYMBOL[arrow.git-dirty]}"
        fi
    else
        tokyo_parts[typing]+="${TOKYO_SYMBOL[arrow]}"
    fi
}

@tok.set-venv-info() {
    if [[ -z ${VIRTUAL_ENV} ]]; then
        tokyo_parts[venv]=''
    else
        tokyo_parts[venv]="${TOKYO_AFFIXES[venv.prefix]}${TOKYO_PALETTE[venv]}$(basename ${VIRTUAL_ENV})${TOKYO_AFFIXES[venv.suffix]}"
    fi
}

# https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html
@tok.set-host-name() {
    tokyo_parts[host]="${TOKYO_AFFIXES[hostname]}"
    tokyo_part_lengths[host]=$((
        ${#tokyo_parts[host]}
        + ${tokyo_affix_lengths[host]}
    ))

    tokyo_parts[host]="${TOKYO_AFFIXES[host.prefix]}${TOKYO_PALETTE[host]}${tokyo_parts[host]}${TOKYO_AFFIXES[host.suffix]}"
}

@tok.set-user-name() {
    tokyo_parts[user]="${TOKYO_AFFIXES[username]}"

    tokyo_part_lengths[user]=$((
        ${#tokyo_parts[user]}
        + ${tokyo_affix_lengths[user]}
    ))

    local name_color="${TOKYO_PALETTE[user]}"
    if [[ ${UID} == 0 || ${USER} == 'root' ]]; then
        name_color="${TOKYO_PALETTE[root]}"
    fi

    tokyo_parts[user]="${TOKYO_AFFIXES[user.prefix]}${name_color}${tokyo_parts[user]}${TOKYO_AFFIXES[user.suffix]}"
}

@tok.set-current-dir() {
    tokyo_parts[path]="${(%):-${TOKYO_AFFIXES[current-dir]}}"

    tokyo_part_lengths[path]=$((
        ${#tokyo_parts[path]}
        + ${tokyo_affix_lengths[path]}
    ))

    tokyo_parts[path]="${TOKYO_AFFIXES[path.prefix]}${TOKYO_PALETTE[path]}${tokyo_parts[path]}${TOKYO_AFFIXES[path.suffix]}"
}


@tok.align-previous-right() {
    # References:
    #
    # CSI ref: https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_sequences
    # http://zsh.sourceforge.net/Doc/Release/Prompt-Expansion.html
    # https://en.wikipedia.org/wiki/ANSI_escape_code#Terminal_output_sequences
    # https://donsnotes.com/tech/charsets/ascii.html
    #
    # Cursor Up        <ESC>[{COUNT}A
    # Cursor Down      <ESC>[{COUNT}B
    # Cursor Right     <ESC>[{COUNT}C
    # Cursor Left      <ESC>[{COUNT}D
    # Cursor Horizontal Absolute      <ESC>[{COUNT}G

    local str="$1"
    local len=$2
    local store_var="$3"

    local align_site=$(( ${COLUMNS} - ${len} + 1 ))
    local previous_line="\e[1F"
    local next_line="\e[1E"
    local new_line="\n"
    # use `%{ %}` wrapper to aviod ANSI cause eat previous line after prompt rerender (zle reset-prompt)
    local cursor_col="%{\e[${align_site}G%}"
    local result="${previous_line}${cursor_col}${str}"

    eval ${store_var}=${(q)result}
}

@tok.align-right() {
    local str="$1"
    local len=$2
    local store_var="$3"

    local align_site=$(( ${COLUMNS} - ${len} + 1 ))
    local cursor_col="%{\e[${align_site}G%}"
    local result="${cursor_col}${str}"

    eval ${store_var}=${(q)result}
}


# pin the last command execute elapsed and exit code at previous line end
@tok.pin-execute-info() {
    local -i exec_seconds="${1:-0}"
    local -i exit_code="${2:-0}"

    local -i pin_length=0

    if (( TOKYO_EXEC_THRESHOLD_SECONDS >= 0)) && (( exec_seconds >= TOKYO_EXEC_THRESHOLD_SECONDS )); then
        local -i seconds=$(( exec_seconds % 60 ))
        local -i minutes=$(( exec_seconds / 60 % 60 ))
        local -i hours=$(( exec_seconds / 3600 ))

        local -a humanize=()

        (( hours > 0 )) && humanize+="${hours}h"
        (( minutes > 0 )) && humanize+="${minutes}m"
        (( seconds > 0 )) && humanize+="${seconds}s"

        # join array with 1 space
        local elapsed="${(j.:.)humanize}"

        tokyo_parts[exec-elapsed]="${sgr_reset}${TOKYO_AFFIXES[exec-elapsed.prefix]}${TOKYO_PALETTE[elapsed]}${elapsed}${TOKYO_AFFIXES[exec-elapsed.suffix]}"
        pin_length+=$(( ${tokyo_affix_lengths[exec-elapsed]} + ${#elapsed} ))
    fi

    if (( exit_code != 0 )); then
        tokyo_parts[exit-code]="${sgr_reset}${TOKYO_AFFIXES[exit-code.prefix]}${TOKYO_PALETTE[exit.code]}${exit_code}${TOKYO_AFFIXES[exit-code.suffix]}"
        pin_length+=$(( ${tokyo_affix_lengths[exit-code]} + ${#exit_code} ))
    fi

    if (( pin_length > 0 )); then
        local pin_message="${tokyo_parts[exec-elapsed]}${tokyo_parts[exit-code]}"
        @tok.align-previous-right "${pin_message}" ${pin_length} pin_message
        print -P "${pin_message}"
    fi
}


@tok.set-date-time() {
    # trimming suffix trailing whitespace
    # donot print trailing whitespace for better interaction while terminal width in narrowing
    local suffix="${(MS)TOKYO_AFFIXES[current-time.suffix]##*[[:graph:]]}"
    local current_time="${TOKYO_AFFIXES[current-time.prefix]}${TOKYO_PALETTE[time]}${(%):-%D{%H:%M:%S\}}${suffix}"
    # 8 is fixed lenght of datatime format `hh:mm:ss`
    tokyo_part_lengths[current-time]=$(( 8 + ${tokyo_affix_lengths[current-time]} ))
    @tok.align-right "${current_time}" ${tokyo_part_lengths[current-time]} 'tokyo_parts[current-time]'
}



@tok.prompt-node-version() {
    if @tok.rev-parse-find "package.json"; then
        if @tok.iscommand node; then
            local node_prompt_prefix="${TOKYO_PALETTE[conj.]}using "
            local node_prompt="%F{120}node `\node -v`"
        else
            local node_prompt_prefix="${TOKYO_PALETTE[normal]}[${TOKYO_PALETTE[error]}need "
            local node_prompt="Nodejs${TOKYO_PALETTE[normal]}]"
        fi
        echo "${node_prompt_prefix}${node_prompt}"
    fi
}

@tok.prompt-golang-version() {
    if @tok.rev-parse-find "go.mod"; then
        if @tok.iscommand go; then
            local go_prompt_prefix="${TOKYO_PALETTE[conj.]}using "
            # go version go1.7.4 linux/amd64
            local go_version=`go version`
            if [[ ${go_version} =~ ' go([0-9]+\.[0-9]+\.[0-9]+) ' ]]; then
                go_version="${match[1]}"
            else
                return 1
            fi
            local go_prompt="%F{086}Golang ${go_version}"
        else
            local go_prompt_prefix="${TOKYO_PALETTE[normal]}[${TOKYO_PALETTE[error]}need "
            local go_prompt="Golang${TOKYO_PALETTE[normal]}]"
        fi
        echo "${go_prompt_prefix}${go_prompt}"
    fi
}

# http://php.net/manual/en/reserved.constants.php
@tok.prompt-php-version() {
    if @tok.rev-parse-find "composer.json"; then
        if @tok.iscommand php; then
            local php_prompt_prefix="${TOKYO_PALETTE[conj.]}using "
            local php_prompt="%F{105}php `\php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . "." . PHP_RELEASE_VERSION . "\n";'`"
        else
            local php_prompt_prefix="${TOKYO_PALETTE[normal]}[${TOKYO_PALETTE[error]}need "
            local php_prompt="php${TOKYO_PALETTE[normal]}]"
        fi
        echo "${php_prompt_prefix}${php_prompt}"
    fi
}

@tok.prompt-python-version() {
    local python_prompt_prefix="${TOKYO_PALETTE[conj.]}using "

    if [[ -n ${VIRTUAL_ENV} ]] && @tok.rev-parse-find "venv"; then
        local python_prompt="%F{123}`$(@tok.rev-parse-find venv '' true)/venv/bin/python --version 2>&1`"
        echo "${python_prompt_prefix}${python_prompt}"
        return 0
    fi

    if @tok.rev-parse-find "requirements.txt"; then
        if @tok.iscommand python; then
            local python_prompt="%F{123}`\python --version 2>&1`"
        elif @tok.iscommand python3; then
            local python_prompt="%F{123}`\python3 --version 2>&1`"
        else
            python_prompt_prefix="${TOKYO_PALETTE[normal]}[${TOKYO_PALETTE[error]}need "
            local python_prompt="Python${TOKYO_PALETTE[normal]}]"
        fi
        echo "${python_prompt_prefix}${python_prompt}"
    fi
}

typeset -ga TOKYO_DEV_ENV_DETECT_FUNCS=(
    @tok.prompt-node-version
    @tok.prompt-golang-version
    @tok.prompt-python-version
    @tok.prompt-php-version
)

@tok.dev-env-detect() {
    for segment_func in ${TOKYO_DEV_ENV_DETECT_FUNCS[@]}; do
        local segment=`${segment_func}`
        if [[ -n ${segment} ]]; then
            echo "${segment}"
            break
        fi
    done
}

@tok.set-dev-env-info() {
    local result="$1"
    local has_changed=false

    if [[ -z ${result} ]]; then
        if [[ -n ${tokyo_previous_parts[dev-env]} ]]; then
            tokyo_parts[dev-env]=''
            tokyo_part_lengths[dev-env]=0
            has_changed=true
        fi

        @tok.infer-prompt-rerender ${has_changed}
        return
    fi

    tokyo_parts[dev-env]="${TOKYO_AFFIXES[dev-env.prefix]}${result}${TOKYO_AFFIXES[dev-env.suffix]}"

    local -i result_len
    @tok.unstyle-len "${result}" result_len

    tokyo_part_lengths[dev-env]=$((
        result_len
        + ${tokyo_affix_lengths[dev-env]}
    ))

    if [[ ${tokyo_parts[dev-env]} != ${tokyo_previous_parts[dev-env]} ]]; then
        has_changed=true
    fi

    @tok.infer-prompt-rerender ${has_changed}
}


@tok.sync-dev-env-detect() {
    local -i output_fd=$1

    local dev_env="$(<& ${output_fd})"
    exec {output_fd}>& -

    @tok.set-dev-env-info "${dev_env}"
}

@tok.async-dev-env-detect() {
    # use cached prompt part for render, and try to update as async

    tokyo_parts[dev-env]="${tokyo_previous_parts[dev-env]}"
    tokyo_part_lengths[dev-env]="${tokyo_previous_lengths[dev-env]}"

    @tok.async 'dev-env' @tok.dev-env-detect @tok.set-dev-env-info
}

# return `true` for dirty
# return `false` for clean
@tok.judge-git-dirty() {
    local git_status
    local -a flags
    flags=('--porcelain')
    if [[ ${DISABLE_UNTRACKED_FILES_DIRTY} == true ]]; then
        flags+='--untracked-files=no'
    fi
    git_status="$(\git status ${flags} 2> /dev/null)"
    if [[ -n ${git_status} ]]; then
        echo true
    else
        echo false
    fi
}

@tok.git-action-prompt() {
    # always depend on ${tokyo_rev_git_dir} path is existed

    local action=''
    local rebase_process=''
    local rebase_merge="${tokyo_rev_git_dir}/rebase-merge"
    local rebase_apply="${tokyo_rev_git_dir}/rebase-apply"

    if [[ -d ${rebase_merge} ]]; then
        if [[ -f ${rebase_merge}/interactive ]]; then
            action="REBASE-i"
        else
            action="REBASE-m"
        fi

        # while edit rebase interactive message,
        # `msgnum` `end` are not exist yet
        if [[ -f ${rebase_merge}/msgnum ]]; then
            local rebase_step="$(< ${rebase_merge}/msgnum)"
            local rebase_total="$(< ${rebase_merge}/end)"
            rebase_process="${rebase_step}/${rebase_total}"
        fi
    elif [[ -d ${rebase_apply} ]]; then
        if [[ -f ${rebase_apply}/rebasing ]]; then
            action="REBASE"
        elif [[ -f ${rebase_apply}/applying ]]; then
            action="AM"
        else
            action="AM/REBASE"
        fi

        local rebase_step="$(< ${rebase_merge}/next)"
        local rebase_total="$(< ${rebase_merge}/last)"
        rebase_process="${rebase_step}/${rebase_total}"
    elif [[ -f ${tokyo_rev_git_dir}/MERGE_HEAD ]]; then
        action="MERGING"
    elif [[ -f ${tokyo_rev_git_dir}/CHERRY_PICK_HEAD ]]; then
        action="CHERRY-PICKING"
    elif [[ -f ${tokyo_rev_git_dir}/REVERT_HEAD ]]; then
        action="REVERTING"
    elif [[ -f ${tokyo_rev_git_dir}/BISECT_LOG ]]; then
        action="BISECTING"
    fi

    if [[ -n ${rebase_process} ]]; then
        action="${action} ${rebase_process}"
    fi
    if [[ -n ${action} ]]; then
        action="|${action}"
    fi

    echo "${action}"
}

@tok.git-branch() {
    # always depend on ${tokyo_rev_git_dir} path is existed

    local ref
    ref="$(\git symbolic-ref HEAD 2> /dev/null)" \
      || ref="$(\git describe --tags --exact-match 2> /dev/null)" \
      || ref="$(\git rev-parse --short HEAD 2> /dev/null)" \
      || return 0
    ref="${ref#refs/heads/}"

    echo "${ref}"
}


# use `exec` to parallel run commands and capture stdout into file descriptor
#   @tok.set-git-info [true|false]
# first param is whether git is dirty or not (`true` or `false`),
# if first param is not set, will try to read by exec
@tok.set-git-info() {
    local is_dirty="$1"

    local dirty_fd branch_fd action_fd

    if [[ -z ${is_dirty} ]]; then
        exec {dirty_fd}<> <(@tok.judge-git-dirty)
    fi

    exec {branch_fd}<> <(@tok.git-branch)
    exec {action_fd}<> <(@tok.git-action-prompt)

    # read and close file descriptors
    local git_branch="$(<& ${branch_fd})"
    local git_action="$(<& ${action_fd})"
    exec {branch_fd}>& -
    exec {action_fd}>& -

    if [[ -n ${dirty_fd} ]]; then
        is_dirty="$(<& ${dirty_fd})"
        exec {dirty_fd}>& -
    fi

    local git_state='' state_color='' git_dirty_status=''

    if [[ ${is_dirty} == true ]]; then
        git_state='dirty'
        state_color='error'
    else
        git_state='clean'
        state_color='success'
    fi

    git_dirty_status="${TOKYO_PALETTE[${state_color}]} ${TOKYO_SYMBOL[git.${git_state}]}"

    tokyo_parts[git-info]="${TOKYO_AFFIXES[git-info.prefix]}${TOKYO_PALETTE[git]}${git_branch}${git_action}${TOKYO_AFFIXES[git-info.suffix]}${git_dirty_status}"

    tokyo_part_lengths[git-info]=$((
        ${#TOKYO_SYMBOL[git.${git_state}]}
        + ${tokyo_affix_lengths[git-info]}
        + ${#git_branch}
        + ${#git_action}
    ))

    local has_changed=false

    if [[ ${tokyo_parts[git-info]} != ${tokyo_previous_parts[git-info]} ]]; then
        has_changed=true
    fi

    # `tokyo_is_git_dirty` is global variable that `true` or `false`
    tokyo_is_git_dirty="${is_dirty}"

    # set typing-pointer due to git_dirty state maybe changed
    @tok.set-typing-pointer

    @tok.infer-prompt-rerender ${has_changed}
}


@tok.sync-git-check() {
    if [[ -z ${tokyo_rev_git_dir} ]]; then return; fi

    @tok.set-git-info
}

@tok.async-git-check() {
    if [[ -z ${tokyo_rev_git_dir} ]]; then return; fi

    # use cached prompt part for render, and try to update as async

    tokyo_parts[git-info]="${tokyo_previous_parts[git-info]}"
    tokyo_part_lengths[git-info]="${tokyo_previous_lengths[git-info]}"

    @tok.async 'git-info' @tok.judge-git-dirty @tok.set-git-info
}

# `EPOCHSECONDS` is setup in zsh/datetime module
# https://zsh.sourceforge.io/Doc/Release/Zsh-Modules.html#The-zsh_002fdatetime-Module
typeset -gi tokyo_exec_timestamp=0
@tok.exec-timestamp() {
    tokyo_exec_timestamp=${EPOCHSECONDS}
}
add-zsh-hook preexec @tok.exec-timestamp

@tok.set-margin-line() {
    # donot print empty line if terminal height less than 12 lines when prompt initial load
    if (( tokyo_prompt_run_count == 1 )) && (( LINES <= 12 )); then
        return
    fi

    tokyo_parts[margin-line]='\n'
}

@tok.prompt-prepare() {
    local -i exit_code=$?
    local -i exec_seconds=0

    if (( tokyo_exec_timestamp > 0 )); then
        exec_seconds=$(( EPOCHSECONDS - tokyo_exec_timestamp ))
        tokyo_exec_timestamp=0
    fi

    tokyo_prompt_run_count+=1

    @tok.reset-prompt-parts

    if (( tokyo_prompt_run_count == 1 )); then
        @tok.init-affix

        local -i dev_env_fd
        exec {dev_env_fd}<> <(@tok.dev-env-detect)
        @tok.sync-git-check
        @tok.sync-dev-env-detect ${dev_env_fd}
    else
        @tok.async-dev-env-detect
        @tok.async-git-check
    fi

    @tok.pin-execute-info ${exec_seconds} ${exit_code}
    @tok.set-margin-line
    @tok.set-host-name
    @tok.set-user-name
    @tok.set-current-dir
    @tok.set-typing-pointer
    @tok.set-venv-info
}

add-zsh-hook precmd @tok.prompt-prepare



@tokyo-prompt() {
    local -i total_length=${#TOKYO_SYMBOL[corner.top]}
    local -A prompts=(
        margin-line ''
        host ''
        user ''
        path ''
        dev-env ''
        git-info ''
        current-time ''
        typing ''
        venv ''
    )

    local prompt_is_emtpy=true
    local key

    for key in ${TOKYO_PROMPT_PRIORITY[@]}; do
        local -i part_length=${tokyo_part_lengths[${key}]}

        # keep padding right 1 space
        if (( total_length + part_length + 1 > COLUMNS )) && [[ ${prompt_is_emtpy} == false ]] ; then
            break
        fi

        prompt_is_emtpy=false

        total_length+=${part_length}
        prompts[${key}]="${sgr_reset}${tokyo_parts[${key}]}"
    done

    # always auto detect rest spaces to float current time
    @tok.set-date-time
    if (( total_length + ${tokyo_part_lengths[current-time]} <= COLUMNS )); then
        prompts[current-time]="${sgr_reset}${tokyo_parts[current-time]}"
    fi

    prompts[margin-line]="${sgr_reset}${tokyo_parts[margin-line]}"
    prompts[typing]="${sgr_reset}${tokyo_parts[typing]}"
    prompts[venv]="${sgr_reset}${tokyo_parts[venv]}"

    local -a ordered_parts=()
    for key in ${TOKYO_PROMPT_ORDER[@]}; do
        ordered_parts+="${prompts[${key}]}"
    done

    local corner_top="${prompts[margin-line]}${TOKYO_PALETTE[normal]}${TOKYO_SYMBOL[corner.top]}"
    local corner_bottom="${sgr_reset}${TOKYO_PALETTE[normal]}${TOKYO_SYMBOL[corner.bottom]}"

    echo "${corner_top}${(j..)ordered_parts}${prompts[current-time]}"
    echo "${corner_bottom}${prompts[typing]}${prompts[venv]} ${sgr_reset}"
}


PROMPT='$(@tokyo-prompt)'
