;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.
(add-to-load-path (string-append (dirname (current-filename)) "/packages"))

(use-modules (gnu home)
             (gnu packages)
             (gnu packages databases)
             (gnu services)
             (guix gexp)
             (justins-channel)
             (my-base-system)
             (emacs-packages)
             (zsh-config))

(home-environment
 ;; Below is the list of packages that will show up in your
 ;; Home profile, under ~/.guix-home/profile.
 (packages
  (append
   emacs-packages
   zsh-packages
   os-packages
   (map (compose list specification->package+output)
        (list
         "guile-gcrypt"
         "pandoc"
         "gnuplot"
         "graphviz"
         "git"
         "postgresql@13.9"
         "fontconfig"))
   (list font-nerd-fonts imagemagick-7)))

 ;; Below is the list of Home services.  To search for available
 ;; services, run 'guix home search KEYWORD' in a terminal.
 (services
  (list zsh-service-config
        system-services)))
