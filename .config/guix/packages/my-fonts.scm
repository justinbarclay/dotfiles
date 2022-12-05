(define-module (my-fonts)
  #:use-module (guix licenses)
  #:use-module (guix packages)
  #:use-module (guix build-system font)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix download)
  #:use-module (guix gexp))

(define-public font-nerd-fonts
  (package
   (name "font-nerd-fonts")
   (version "v2.2.1")
   (source
    (origin
     (method git-fetch)
     (uri (git-reference
           (url "https://github.com/ryanoasis/nerd-fonts")
           (commit version)))
     (file-name (git-file-name name version))
     (sha256
      (base32
       "064khkp7q11hv8gfygddw54079hfmz0mypghjyfr1x3hmannmp1i"))))
   (build-system font-build-system)
   (arguments
    `(#:phases
      (modify-phases %standard-phases
                     (add-before 'install 'make-files-writable
                                 (lambda _
                                   (for-each
                                    make-file-writable
                                    (find-files "." ".*\\.(otf|otc|ttf|ttc)$"))
                                   #t)))))
   (home-page "https://www.nerdfonts.com/")
   (synopsis "Iconic font aggregator, collection, and patcher")
   (description
    "Nerd Fonts patches developer targeted fonts with a high number
of glyphs (icons).  Specifically to add a high number of extra glyphs
from popular ‘iconic fonts’ such as Font Awesome, Devicons, Octicons,
and others.")
   (license expat)))

(define-public font-nerd-fonts-fira-code
  (package
   (name "font-nerd-fonts-fira-code")
   (version "2.2.1")
   (source
    (origin
     (method url-fetch)
     (uri
      (string-append
       "https://github.com/ryanoasis/nerd-fonts/releases/download/v"
       version
       "/FiraCode.zip"))
     (sha256
      (base32
       "064khkp7q11hv8gfygddw54079hfmz0mypghjyfr1x3hmannmp1i"))))
   (build-system font-build-system)
   (arguments
    `(#:phases
      (modify-phases %standard-phases
        (add-before 'install 'make-files-writable
          (lambda _
            (for-each
             make-file-writable
             (find-files "." ".*\\.(otf|otc|ttf|ttc)$"))
            #t)))))
   (home-page "https://www.nerdfonts.com/")
   (synopsis "Nerd fonts variant of FiraCode font")
   (description
    "Nerd fonts variant of FiraCode font.  Nerd Fonts is a project that patches
developer targeted fonts with a high number of glyphs (icons).  Specifically to
add a high number of extra glyphs from popular 'iconic fonts' such as Font
Awesome, Devicons, Octicons, and others.")
   (license expat)))

(define-public font-nerd-fonts-cascadia-code
  (package
   (name "font-nerd-fonts-cascadia-code")
   (version "2.2.1")
   (source
    (origin
     (method url-fetch)
     (uri
      (string-append
       "https://github.com/ryanoasis/nerd-fonts/releases/download/v"
       version
       "/CascadiaCode.zip"))
     (sha256
      (base32
       "0r8c93f6ysqwl6bsb3avjnhx20fcxz6ng0mwddhcaz14dhl9y0q6"))))
   (build-system font-build-system)
   (arguments
    `(#:phases
      (modify-phases %standard-phases
        (add-before 'install 'make-files-writable
          (lambda _
            (for-each
             make-file-writable
             (find-files "." ".*\\.(otf|otc|ttf|ttc)$"))
            #t)))))
   (home-page "https://www.nerdfonts.com/")
   (synopsis "Nerd fonts variant of FiraCode font")
   (description
    "Nerd fonts variant of FiraCode font.  Nerd Fonts is a project that patches
developer targeted fonts with a high number of glyphs (icons).  Specifically to
add a high number of extra glyphs from popular 'iconic fonts' such as Font
Awesome, Devicons, Octicons, and others.")
   (license expat)))

font-nerd-fonts-cascadia-code
