{ lib, pkgs, config, ... }:

with builtins;
with lib; {
  config = {
    nix.settings.auto-optimise-store = true;
    users.users.justin = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "docker" ];
    };
    programs.zsh.enable = true;
    programs.dconf.enable = true;
    time.timeZone = "America/Vancouver";
    fonts.fonts = with pkgs; [ nerdfonts powerline-fonts ];
    environment = {
      systemPackages = with pkgs; [
        git
        bat
        ripgrep
        exa
        wsl-open
        man-pages
        man-pages-posix
      ];
      variables = rec {
        BROWSER = "wsl-open";
      };
    };
    services = {
      postgresql = {
        enable = true;
        package = pkgs.postgresql_13;
        enableTCPIP = true;
        authentication = pkgs.lib.mkOverride 13 ''
          local all all trust
          host all all 127.0.0.1/32 trust
          host all all ::1/128 trust
        '';
      };
      # Use "" to start a standard redis instance
      redis.servers."".enable = true;
      redis.servers."".openFirewall = true;
    };
  };
}
