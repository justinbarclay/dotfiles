### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing DHARMA Initiative Plugin Manager (zdharma/zinit)…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone git@github.com:zdharma-continuum/zinit.git "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f" || \
        print -P "%F{160}▓▒░ The clone has failed.%f"
fi
source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
### End of Zinit installer's chunk

# Create a nice experience similar to fish
# an explanation of syntax can be found here
# https://zdharma.org/zinit/wiki/Example-Minimal-Setup/
zplugin ice wait"0" lucid
zplugin light zsh-users/zsh-completions

zplugin ice wait"0" atload"_zsh_autosuggest_start" lucid
zplugin light zsh-users/zsh-autosuggestions

zplugin ice wait"0" atinit"zpcompinit" lucid
zplugin light zdharma-continuum/fast-syntax-highlighting

zplugin ice wait"1" lucid
zplugin light zdharma-continuum/history-search-multi-word

zplugin ice wait"1" lucid
zplugin light zsh-users/zsh-history-substring-search

# Steal some plugins from OMZ
zinit wait lucid for \
      OMZ::plugins/colored-man-pages/colored-man-pages.plugin.zsh \
      OMZ::plugins/command-not-found/command-not-found.plugin.zsh \
      OMZ::plugins/rbenv/rbenv.plugin.zsh
