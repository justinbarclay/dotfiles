---
name: emacs-org-workflow
description: Use when editing Emacs configuration, writing Elisp, configuring packages with use-package, or writing developer documentation, system specs, or Org-mode (.org) documents.
---

# Emacs & Org-Mode Workflow Guidelines

Enforce idiomatic Emacs Lisp configuration patterns using `use-package` and mandate Org-mode syntax (`.org`) and Graphviz diagrams for developer documentation.

## Core Rules

1. **Org-mode for Developer Documentation**: When writing developer documentation for moderately complex and larger systems, use Org-mode syntax (`.org`). Include standard Org metadata headers (`#+TITLE:`, `#+AUTHOR:`, `#+DATE:`), proper headline hierarchies (`*`, `**`), and source blocks (`#+begin_src`).
2. **`use-package` Configuration Standard**: All Emacs package configuration code MUST be wrapped inside `use-package` declarations. Do not write unorganized top-level `setq` or `require` calls without a `use-package` block wrapper.
3. **Structured Keywords**: Separate configuration options cleanly using standard `use-package` keywords:
   - `:init` for code run before the package is loaded.
   - `:config` for code run after the package is loaded.
   - `:bind` for keybindings.
   - `:custom` for customizable user options.
   - `:hook` for mode hooks.
   - `:mode` for auto-mode-alist association.
4. **Graphviz for Diagrams**: When creating architecture diagrams, flowcharts, or system models within Org documentation, use Graphviz `dot` source blocks (`#+begin_src dot :file diagram.png`).

## Language & Syntax References

- **`use-package` Standards**: See [`references/use-package-guide.md`](references/use-package-guide.md) for detailed keyword structure, keybinding syntax, and lazy-loading rules.
- **Org-Mode & Graphviz Guide**: See [`references/org-syntax-guide.md`](references/org-syntax-guide.md) for Org document structure, metadata headers, tables, links, source blocks, and Graphviz diagram blocks.

## Completion Criteria

The Emacs/Org task is complete when:
- Developer documentation uses valid Org-mode syntax (`.org`) with proper metadata headers.
- Diagrams inside Org documents use `#+begin_src dot` Graphviz source blocks.
- Emacs configuration snippets use structured `use-package` declarations without loose top-level `setq` calls.
