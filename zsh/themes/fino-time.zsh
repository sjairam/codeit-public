# fino-time.zsh-theme

# Use with a dark background and 256-color terminal!
# Meant for people with RVM and git. Tested only on OS X 10.7.

# You can set your computer name in the ~/.box-name file if you want.

# Borrowing shamelessly from these oh-my-zsh themes:
#   bira
#   robbyrussell
#
# Also borrowing from http://stevelosh.com/blog/2010/02/my-extravagant-zsh-prompt/

function virtualenv_info {
    [ $CONDA_DEFAULT_ENV ] && echo "($CONDA_DEFAULT_ENV) "
    [ $VIRTUAL_ENV ] && echo '('`basename $VIRTUAL_ENV`') '
}

function prompt_char {
    git branch >/dev/null 2>/dev/null && echo '⠠⠵' && return
    echo '○'
}

function box_name {
  local box="${SHORT_HOST:-$HOST}"
  [[ -f ~/.box-name ]] && box="$(< ~/.box-name)"
  echo "${box:gs/%/%%}"
}

function k8s_namespace() {
  if ! command -v kubectl &> /dev/null; then
    echo ""
    return
  fi
  local ns
  ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
  if [[ -z "$ns" ]]; then
    ns="default"
  fi
  echo "$ns"
}

PROMPT='
╭─[%{$FG[239]%} %* %{$reset_color%}] [ %{$FG[033]%}$K8S_CLUSTER%{$reset_color%} %{$FG[239]%}::%{$reset_color%} %{$FG[040]%}$K8S_NAMESPACE%{$reset_color%} ] [ %{$terminfo[bold]$FG[226]%}%~%{$reset_color%}$(git_prompt_info)$(ruby_prompt_info) ]
╰─$(virtualenv_info)$(prompt_char) '


ZSH_THEME_GIT_PROMPT_PREFIX=" %{$FG[239]%}::%{$reset_color%} %{$fg[255]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$FG[202]%} ✘"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$FG[040]%} ✔"
ZSH_THEME_RUBY_PROMPT_PREFIX=" %{$FG[239]%}using%{$FG[243]%} ‹"
ZSH_THEME_RUBY_PROMPT_SUFFIX="›%{$reset_color%}"
