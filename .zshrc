# Set up the prompt

# autoload -Uz promptinit
# promptinit
# prompt adam1




fpath=(/usr/local/share/zsh/site-functions $fpath)
autoload -Uz compinit
ZSH_COMPDUMP=${ZSH_COMPDUMP:-${ZDOTDIR:-$HOME}/.zcompdump}

# cache .zcompdump for about a day
if [[ -n $(find "$ZSH_COMPDUMP" -mtime -1 2>/dev/null) ]]; then
  compinit -C -d "$ZSH_COMPDUMP"
else
  compinit -i -d "$ZSH_COMPDUMP"
  touch "$ZSH_COMPDUMP"
fi


# Compile .zcompdump in background if needed
if [[ -s "$ZSH_COMPDUMP" && ( ! -s "${ZSH_COMPDUMP}.zwc" || "$ZSH_COMPDUMP" -nt "${ZSH_COMPDUMP}.zwc" ) ]]; then
  zcompile "$ZSH_COMPDUMP" &
fi








setopt histignorealldups sharehistory


# Use emacs keybindings even if our EDITOR is set to vi
# bindkey -e

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history








# ########################################################################################################################
# environment variables
# ########################################################################################################################




# remove duplicate entries from $PATH
typeset -U PATH path



export ZSH_CACHE_DIR="$HOME/.cache/zshcache"


#---------------------------------------exports-----------------------------------------------#



export SCCACHE_DIRECT=true


export RUST_BACKTRACE=full
export CARGO_INCREMENTAL=0
export RUSTC_WRAPPER=sccache

export RUSTFLAGS="-C link-arg=-fuse-ld=mold ${RUSTFLAGS:-}"


export CMAKE_C_COMPILER_LAUNCHER=sccache
export CMAKE_CXX_COMPILER_LAUNCHER=sccache

#make ninja default for make
export CMAKE_GENERATOR=Ninja
export CMAKE_EXPORT_COMPILE_COMMANDS=1

export LDFLAGS="-fuse-ld=mold"

# force C colored diagnostic output
export CFLAGS="${CFLAGS} -fdiagnostics-color=always"
# force C++ colored diagnostic output
export CXXFLAGS="${CXXFLAGS} -fdiagnostics-color=always"
export CCFLAGS="${CCFLAGS} -fdiagnostics-color=always"
# force C, C++, Cpp (pre-processor) colored diagnostic output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"



#------------------------------------plugin exports-------------------------------------#




export ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd completion history)
export ZSH_AUTOSUGGEST_COMPLETION_IGNORE="\#*"


export CLICOLOR=1
export LESS="$LESS -R"
export LESSOPEN="|~/.lessfilter %s"
export LESSCOLORIZER="bat"
export MANPAGER="manpager --theme=Monokai --italic-text=always | less --pattern=^\\S+"
# export MANPAGER="manpager --theme='Monokai Extended' --italic-text=always | less --pattern='^\\S+'"

# export MANPAGER="manpager --theme=\"Monokai Extended\" --italic-text=always | less --pattern=^\\\\S+"

# export MANPAGER='gccmanpager --theme=Monokai --italic-text=always | less --pattern=^\S+'


export warhol_ignore_curl=1
export warhol_ignore_ls=1
export warhol_ignore_diff=1

export ZSH_LS_BACKEND=eza
# export warhol_ignore_ps=1





# antidote loading

zsh_plugins=${ZDOTDIR:-~}/.zsh_plugins.zsh


# Ensure you have a corresponding .zsh_plugins.txt file where you can add plugins.
[[ -f ${zsh_plugins:r}.txt ]] || touch ${zsh_plugins:r}.txt


# Lazy-load antidote.
fpath=(${ZDOTDIR:-~}/.antidote/functions $fpath)
autoload -Uz antidote



# Generate static file in a subshell when .zsh_plugins.txt is updated.
if [[ ! $zsh_plugins -nt ${zsh_plugins:r}.txt ]]; then
  (antidote bundle <${zsh_plugins:r}.txt >|$zsh_plugins)
fi

source $zsh_plugins


#export PATH="/usr/local/bin:$PATH"


# Append a command directly
# zvm_after_init_commands+=(
 # 'eval "$(atuin init zsh)"'
# )


# appearance
# autoload -Uz promptinit && promptinit && prompt powerlevel10k
# Use modern completion system



# zstyle ':completion:*' auto-description 'specify: %d'
# zstyle ':completion:*' completer _expand _complete _correct _approximate
# zstyle ':completion:*' format 'Completing %d'
# zstyle ':completion:*' group-name ''
# zstyle ':completion:*' menu select=2
# eval "$(dircolors -b)"
# zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# zstyle ':completion:*' list-colors ''
# zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
# zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
# zstyle ':completion:*' menu select=long
# zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
# zstyle ':completion:*' use-compctl false
# zstyle ':completion:*' verbose true
#
# zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
# zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'




alias cp="cp -i"

alias mv="mv -i"

alias rm="rm -i"

# alias mkdir="mkdir -p"

alias rmdir="rmdir -p"

alias sudo="sudo "





alias cat="bat"
alias curl="curlie"

alias diff="batdiff"

alias find="bfs"

alias grep="rga --color=auto"
alias egrep="rga -F"
# alias ps="procs"
alias asdf="mise"
# alias man="batman"

alias top="btm --basic"
#eval "$(mise activate zsh)"




alias clang="grc --colour=auto --config=conf.gcc clang"
alias "clang++"="grc --colour=auto --config=conf.gcc clang++"
alias cpp="grc --colour=auto --config=conf.gcc cpp"


# alias hgrep="fc -El 0 | rg"

alias listalias="als"
alias lv="lnav"
alias sl="ls"
alias szrc="exec zsh" # better then sourcezing


last_repository=""


check_directory_for_new_repository() {
  local current_repository
  current_repository=$(git rev-parse --show-toplevel 2>/dev/null) || current_repository=""

  if [[ -n $current_repository && $current_repository != $last_repository ]]; then
    if command -v onefetch >/dev/null 2>&1 && git -C "$current_repository" rev-list -n 1 --all >/dev/null 2>&1; then
      # Optional: if HEAD is unborn, pick the first commit on any branch
      if ! git -C "$current_repository" rev-parse --verify HEAD >/dev/null 2>&1; then
        # HEAD is unborn; just skip to avoid onefetch error
        :
      else
        onefetch
      fi
    fi
  fi

  last_repository=$current_repository
}

cd() {
  z "$@"
  check_directory_for_new_repository
}


# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh"}}\x9c'




# Auto-Warpify
# [[ "$-" == *i* ]] && printf 'P$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh", "uname": "Linux" }}�' 

# Auto-Warpify
# [[ "$-" == *i* ]] && printf 'P$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh", "uname": "Linux" }}�' 
