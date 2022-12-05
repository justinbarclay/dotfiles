;; This "home-environment" file can be passed to 'guix home reconfigure'
;; to reproduce the content of your profile.  This is "symbolic": it only
;; specifies package names.  To reproduce the exact same profile, you also
;; need to capture the channels being used, as returned by "guix describe".
;; See the "Replicating Guix" section in the manual.
(add-to-load-path (string-append (dirname (current-filename)) "/packages"))
(use-modules (gnu home)
             (gnu packages)
             (gnu services)
             (gnu home services shells)
             (my-fonts)
             )

(home-environment
 ;; Below is the list of packages that will show up in your
 ;; Home profile, under ~/.guix-home/profile.
 (packages
  (append
   (map (compose list specification->package+output)
        (list
;;;
         ;; Emacs
;;;
         "emacs-next"
         "guile"
         "emacs-geiser"
         "emacs-guix"
         "emacs-use-package"
         "emacs-geiser-guile"

         ;; Dirvish
         "ffmpeg"
         "ffmpegthumbnailer"
         "poppler"
         "gnutls"
         "sqlite"

         "binutils"
         "hunspell"

;;;
         ;; /Emacs
;;;

;;;
         ;; Shell
;;;
         "zsh"
         "htop"
         "exa"
         "ripgrep"

;;;
         ;; /Shell
;;;

         "nss-certs"
         "glibc-utf8-locales-2.29"
         "git"
         "man-db"
         "openssh"
         "gnupg"
         "gnuplot"
         "graphviz"
         "pandoc"
         "zip"
         "fontconfig"
         ;;;
         ;; Fonts
         ;;;
         "font-inconsolata"
         ))
   (list font-nerd-fonts)))

 ;; Below is the list of Home services.  To search for available
 ;; services, run 'guix home search KEYWORD' in a terminal.
 (services
  (list)))
