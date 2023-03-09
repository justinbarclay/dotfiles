(define-module (zsh-config)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (gnu home)
  #:use-module (gnu home services shells)
  #:use-module (guix gexp))

(define-public zsh-packages
  (map (compose list specification->package+output)
       (list
        "zsh"
        "htop"
        "exa"
        "jq"
        "direnv")))

(define-public zsh-service-config
  ;; "Links the users personal zsh config and adds the needed configuration to be compatible with Guix"
  (service home-zsh-service-type
           (home-zsh-configuration
            (zprofile (list (local-file
                             "/home/justin/dotfiles/.config/guix/packages/zprofile"))))))
