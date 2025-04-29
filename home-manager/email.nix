{ config, lib, pkgs, ... }:

with lib;
{
  options.modules.email = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    username = mkOption {
      type = types.str;
    };
  };
  config = mkIf config.modules.email.enable
    {

      programs = {
        mu = {
          enable = false;
        };
        msmtp.enable = true;
        mbsync.enable = true;
      };

      accounts.email = {
        accounts.fastmail = {
          flavor = "fastmail.com";
          address = config.modules.email.username;
          imap =
            {
              host = "imap.fastmail.com";
              port = 993;
            };
          mbsync = {
            enable = true;
            create = "maildir";
          };
          msmtp.enable = true;
          mu.enable = true;
          primary = true;
          realName = "Justin Barclay";
          passwordCommand = if pkgs.stdenv.isDarwin then "op item get fastmail-smtp --field password --reveal" else "op.exe item get fastmail-smtp --field password --reveal";
          userName = config.modules.email.username;
        };

        # accounts.gmail = {
        #   flavor = "gmail.com";
        #   address = "{{ op://Private/gmail-smtp/username }}";
        #   imap =
        #     {
        #       host = "imap.gmail.com";
        #       port = 993;
        #     };
        #   mbsync = {
        #     enable = true;
        #     create = "maildir";
        #   };
        #   msmtp.enable = true;
        #   mu.enable = true;
        #   primary = false;
        #   realName = "Justin Barclay";
        #   passwordCommand = if pkgs.stdenv.isDarwin then "/usr/local/bin/op item get gmail-smtp --field password" else "op.exe item get gmail-smtp --field password";
        #   userName = "{{ op://Private/gmail-smtp/username }}";
        # };
      };
    };
}
