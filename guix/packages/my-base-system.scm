(define-module (my-base-system)
  #:use-module (gnu packages)
  #:use-module (gnu services)
  #:use-module (gnu home)
  #:use-module (gnu home services shepherd)
  #:use-module (guix gexp))

(define-public os-packages
  (map (compose list specification->package+output)
       (list
        "nss-certs"
        "glibc-locales"
        "mandoc"
        "man-db"
        "man-pages-posix"
        "man-pages"
        "gnupg"
        "openssh"
        "git"
        "zip")))

(define-public system-services
  (service home-shepherd-service-type
           (home-shepherd-configuration
            (services '()))))
