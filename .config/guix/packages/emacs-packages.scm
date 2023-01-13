(define-module (emacs-packages)
  #:use-module (gnu packages)
  #:use-module (justins-channel))

(define-public emacs-packages
  (append
   (list emacs-master)
   (map (compose list specification->package+output)
        (list
         ;; Base packages
         ;;"emacs-next"

         ;; Guix based dev packages
         "guile"
         "emacs-geiser"
         "emacs-geiser-guile"

         ;; Dirvish
         "ffmpeg"
         "ffmpegthumbnailer"
         "poppler"
         "gnutls"

         ;; Spell checking
         "hunspell"

         ;; General
         "ripgrep"
         "sqlite"
         "binutils"))))
