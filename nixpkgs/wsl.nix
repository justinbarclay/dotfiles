{ lib, pkgs, config, ... }:

with builtins;
with lib; {
  config = {

    users.users.justin = {
      isNormalUser = true;
      shell = pkgs.zsh;
      extraGroups = [ "wheel" ];
    };
    programs.dconf.enable = true;
    fonts.fonts = with pkgs; [ nerdfonts powerline-fonts ];
    environment.systemPackages = with pkgs; [ git bat ripgrep exa emacs wsl-open man-pages man-pages-posix];
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
      # Allow Home-Manager to control starting WMs via XSession
      xserver = {
        enable = true;
        layout = "us";
        xkbVariant = "";
        libinput.enable = true;

        displayManager = {
          defaultSession = "xsession";
          autoLogin.user = "justin";

          session = [{
            manage = "desktop";
            name = "xsession";
            start = "  exec $HOME/.xsession &\n  waitPID=$!\n";
          }];
        };
      };
    };
  };
}
