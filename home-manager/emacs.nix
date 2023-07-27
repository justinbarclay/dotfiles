{ config, lib, pkgs, ... }:

with lib; {
  options.modules.emacs = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    with-gtk = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf config.modules.emacs.enable
    {
      home.sessionVariables = {
        EDITOR = "emacs";
      };

      home.packages = with pkgs;
        [
          # Needed for network commnunication
          gnutls

          # This needs to be around or GTK gets mad about the themes displayed
          #
          # Used by magit
          sqlite
          # used by gcc
          # binutils
          # Needed for things like custom treesitter builds or vterm
          gcc

          (emacsGit.override {
            treeSitterPlugins = with tree-sitter-grammars; [
              tree-sitter-bash
              tree-sitter-c
              tree-sitter-c-sharp
              tree-sitter-cmake
              tree-sitter-cpp
              tree-sitter-css
              tree-sitter-dockerfile
              tree-sitter-go
              tree-sitter-gomod
              tree-sitter-java
              tree-sitter-javascript
              tree-sitter-json
              tree-sitter-python
              tree-sitter-ruby
              tree-sitter-rust
              tree-sitter-toml
              tree-sitter-tsx
              tree-sitter-typescript
              tree-sitter-yaml
            ];
            withGTK3 = config.modules.emacs.with-gtk;
            withXwidgets = config.modules.emacs.with-gtk;
          })

          # Let's spell good
          hunspell
          hunspellDicts.en_CA

          # Dirvish
          ffmpeg
          ffmpegthumbnailer
          poppler
          rnix-lsp
        ];
    };
}
