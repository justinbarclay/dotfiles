{ config, lib, pkgs, ... }:

with lib; {
  options.modules.email = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.email.enable {

    programs = {
      mu.enable = true;
      msmtp.enable = true;
      mbsync.enable = true;
    };

    accounts.email = {
      accounts.fastmail = {
        flavor = "fastmail.com";
        address = "me@justinbarclay.ca";
        imap =
          {
            host = "imap.fastmail.com";
            port = 993;
          };
        mbsync = {
          enable = true;
          create = "maildir";
        };
        #        msmtp.enable = true;
        mu.enable = true;
        primary = true;
        realName = "Justin Barclay";
        passwordCommand = if pkgs.stdenv.isDarwin then "op item get fastmail-smtp --field password" else "op.exe item get fastmail-smtp --field password";
        userName = "me@justinbarclay.ca";
      };
    };
  };
}
