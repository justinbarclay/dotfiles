# Nushell Config File
#
# version = "0.115.1"
#
# Nushell ships every default in `$env.config`, `menus` and `keybindings`
# built in, so this file only records the deltas. Run `config nu --default`
# to see the fully-commented upstream reference.
#
# The external completer is not set here: carapace installs its own (which also
# expands aliases and completes nushell builtins). On nix that comes from the
# autoload dir, on Windows from the init generated in env.nu.

$env.config.show_banner = false

# Always act as if `rm -t` was given. Override per-call with -p.
$env.config.rm.always_trash = true

# osc133/osc633 prompt marking shifts the terminal around in wezterm; the rest
# of the shell-integration escapes are fine.
$env.config.shell_integration.osc133 = false
$env.config.shell_integration.osc633 = false

# 0.115 defaults these to `inherit` (leave the terminal's cursor alone).
$env.config.cursor_shape.emacs = "line"
$env.config.cursor_shape.vi_insert = "block"
$env.config.cursor_shape.vi_normal = "underscore"

# Bind the IDE completion menu to ctrl+n rather than the default ctrl+space.
# Assignment merges into the defaults by name as of 0.115, so this replaces the
# built-in entry rather than adding a second one.
$env.config.keybindings = [{
  name: ide_completion_menu
  modifier: control
  keycode: char_n
  mode: [emacs vi_normal vi_insert]
  event: {
    until: [
      { send: menu name: ide_completion_menu }
      { send: menunext }
      { edit: complete }
    ]
  }
}]

source ~/dotfiles/home-manager/config/custom.nu
source ~/.config/starship/starship.nu
source ~/.config/zoxide/init.nu
source ~/.cache/carapace/init.nu
source ~/.config/atuin/init.nu
