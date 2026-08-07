;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((nil . ((eval . (setq-local lsp-nix-nixd-nixos-options-expr
                            (getenv "NIXD_NIXOS_OPTIONS_EXPR")))
         (eval . (setq-local lsp-nix-nixd-home-manager-options-expr
                            (getenv "NIXD_HOME_MANAGER_OPTIONS_EXPR"))))))
