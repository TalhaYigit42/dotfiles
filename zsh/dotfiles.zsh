# Source this from your ~/.zshrc (or ~/.config/zsh/user.zsh):  source ~/.config/zsh/dotfiles.zsh
# Needs (optional, each only used if installed): zoxide eza bat atuin fzf lazygit tldr pgcli starship fastfetch

# random Lain logo in fastfetch for every new terminal
if [[ $- == *i* ]] && command -v fastfetch >/dev/null; then
    _lainlogos=(~/.config/fastfetch/lain-*.txt(N))
    (( ${#_lainlogos} )) && fastfetch --logo-type file --logo "${_lainlogos[$((RANDOM % ${#_lainlogos} + 1))]}" --logo-color-1 magenta --logo-padding-right 4
fi
command -v starship >/dev/null && eval "$(starship init zsh)"

# --- helpers (only active if installed) ---
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"          # z <part-of-folder> jumps there
# aliases are set right before the first prompt, so later plugin aliases cannot override them
_late_aliases() {
  command -v eza >/dev/null && { alias ls='eza --icons --group-directories-first'; alias ll='eza -l --icons --group-directories-first --git'; alias lt='eza --tree --level=2 --icons'; }
  alias gs='git status -sb' ga='git add' gaa='git add -A' gc='git commit' gcm='git commit -m' gd='git diff' gds='git diff --staged' gp='git push' gpl='git pull --rebase' gco='git switch' gl='git log --oneline --graph --decorate -15' lg='lazygit' d='cd ~/Downloads' p='cd ~/GitHub'
  unalias up 2>/dev/null   # plugin alias would hide the up() function
  add-zsh-hook -d precmd _late_aliases
}
autoload -Uz add-zsh-hook && add-zsh-hook precmd _late_aliases
command -v bat >/dev/null && alias cat='bat --paging=never --style=plain'
command -v atuin >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"   # Ctrl+R: searchable history
command -v tldr >/dev/null && alias h='tldr'
# fzf in Eva colours (Ctrl+T files, Alt+C folders)
export FZF_DEFAULT_OPTS="--height=40% --layout=reverse --border=rounded --color=bg+:#2a2638,fg:#d9d4ee,fg+:#ffffff,hl:#a77bff,hl+:#c0a0ff,pointer:#8fe07a,prompt:#a77bff,info:#7d7a96,border:#3d3a52"

# --- dev helpers ---
mkcd()  { mkdir -p "$1" && cd "$1"; }                                        # mkcd newfolder
up()    { local n=${1:-1} p=""; for ((i=0;i<n;i++)); do p+="../"; done; cd "$p"; }   # up 3
serve() { python3 -m http.server "${1:-8000}"; }                              # serve [port]
ports() { ss -ltnp 2>/dev/null | awk 'NR==1 || /LISTEN/' | column -t; }      # what listens where
fcd()   { local d; d=$(find "${1:-.}" -maxdepth 4 -type d -not -path '*/.git/*' -not -path '*/node_modules/*' 2>/dev/null | fzf --preview 'ls -1 {} | head -20') && cd "$d"; }
fe()    { local f; f=$(fzf --preview 'bat --color=always --style=plain {} 2>/dev/null || cat {}') && ${EDITOR:-nvim} "$f"; }
fkill() { local p; p=$(ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | sed 1d | fzf -m --header='TAB = mehrere, ENTER = kill' | awk '{print $1}'); [ -n "$p" ] && echo "$p" | xargs kill && echo "killed: $p"; }
fbr()   { local b; b=$(git branch --all --sort=-committerdate | sed 's/^[ *]*//; s#remotes/origin/##' | awk '!s[$0]++' | fzf --preview 'git log --oneline --graph -10 {}') && git switch "$b"; }
fgl()   { git log --oneline --color=always | fzf --ansi --preview 'git show --stat --color=always {1}' ; }
pgdb()  { local d; d=$(psql -Atc "select datname from pg_database where not datistemplate" 2>/dev/null | fzf --header='database') && pgcli "$d"; }   # pick a local Postgres DB
extract() { case "$1" in *.tar.gz|*.tgz) tar xzf "$1";; *.tar.bz2) tar xjf "$1";; *.tar.xz) tar xJf "$1";; *.tar) tar xf "$1";; *.zip) unzip "$1";; *.7z) 7z x "$1";; *.gz) gunzip "$1";; *) echo "unbekanntes format: $1";; esac; }
calc()  { ~/.config/niri/scripts/calc.py "$@"; }                              # calc "2**16" / calc "hex(255)"
