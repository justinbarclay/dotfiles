# `use-package` Configuration Guide

Use `use-package` to declare Emacs package configurations cleanly, reproducibly, and performantly.

## 1. Standard Keyword Hierarchy

Always order keywords consistently within `use-package` blocks:

```elisp
(use-package package-name
  :ensure t
  :init
  ;; Code to run BEFORE package is loaded (e.g. settings needed for autoloads)
  (setq package-name-pre-load-var t)
  :custom
  ;; User options set via customize interface
  (package-name-option 'value)
  :bind
  ;; Keybindings
  ("C-c p f" . package-name-find-file)
  :hook
  ;; Mode hooks
  (prog-mode . package-name-mode)
  :config
  ;; Code to run AFTER package is loaded
  (package-name-setup))
```

## 2. Keybinding Syntax (`:bind` and `:bind-keymap`)

Use pair syntax for `:bind` clauses:

```elisp
(use-package magit
  :ensure t
  :bind
  (("C-x g" . magit-status)
   ("C-x M-g" . magit-dispatch)))
```

## 3. Lazy Loading & Deferred Package Loading

Use `:defer t` or implicit autoload keywords (`:bind`, `:mode`, `:hook`, `:commands`) to keep Emacs startup fast.

```elisp
(use-package rust-mode
  :ensure t
  :mode "\\.rs\\'"
  :defer t)
```

## 4. Avoiding Anti-Patterns

- **Avoid**: Loose `(require 'foo)` followed by unnested `(setq foo-var bar)`.
- **Preferred**: `(use-package foo :config (setq foo-var bar))`.
