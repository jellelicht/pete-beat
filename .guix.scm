; SPDX-FileCopyrightText: 2021 Jelle Licht <jlicht@fsfe.org>
;
; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (.guix)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix profiles)
  #:use-module (guix utils)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages embedded)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages base))

(define-public gbdk-2020
  (let ((commit "02bba6f762ea8f9a6678722f3324b71c21a725c6")
	(revision "1"))
    (package
      (name "gbdk-2020")
      (version "4.0.3")
      (source (origin
		(method git-fetch)
		(uri (git-reference
                      (url "https://github.com/Zal0/gbdk-2020")
                      (commit version)))
		(file-name (git-file-name name version))
		(sha256
		 (base32
		  "1ymy4xvs21wzk6ga1ab450i7jjg3jpzfli8a9lcknxja4p4rsi6k"))))
      (build-system gnu-build-system)
      (outputs '("out" "doc"))
      (arguments
       '(#:make-flags (list (string-append "SDCCDIR=" (assoc-ref %build-inputs "sdcc")))
	 #:phases
	 (modify-phases %standard-phases
	   (replace 'configure
	     (lambda* (#:key outputs inputs #:allow-other-keys)
	       (let* ((out (assoc-ref outputs "out"))
		      (ucsim (assoc-ref inputs "ucsim"))
		      (sz80 (string-append ucsim "/bin/sz80")))
		 (substitute* "Makefile"
		   (("TARGETDIR = .*")
		    (string-append "TARGETDIR = " out))
		   ;; We symlink sdcc and ucsim binaries, instead of making a copy
		   (("sz80") "")
		   (("Installing SDCC" all)
		    (string-append all "\n\t"
				   "@ln -s " 
				   sz80
				   " $(BUILDDIR)/bin/ && echo \"-> sz80\""))
		   (("cp \\$\\(SDCCDIR\\)")
		    "ln -s $(SDCCDIR)")))
	       #t))
	   (replace 'build
	     (lambda* (#:key make-flags #:allow-other-keys)
	       (apply invoke "make" "gbdk-build" make-flags)))
	   (add-after 'build 'build-docs
	     (lambda* (#:key make-flags #:allow-other-keys)
	       (apply invoke "make" "docs" make-flags)))
	   ;; stripping makes lcc complain about missing symbols
	   (delete 'strip) 		
	   (add-before 'install 'install-docs
	     (lambda* (#:key outputs #:allow-other-keys)
	       (let ((doc (assoc-ref outputs "doc")))
		 (copy-recursively "docs/api"
				   (string-append doc "/share/doc/gbdk/html")))))
	   (add-after 'install 'clean-install
	     (lambda* (#:key outputs #:allow-other-keys)
	       (let ((out (assoc-ref outputs "out")))
		 (for-each (lambda (p)
			     (delete-file-recursively (string-append out "/" p)))
			   (list "ChangeLog"
				 "README"
				 "examples"))))))
         #:tests? #f))
      (native-inputs
       `(("perl" ,perl)
	 ("doxygen" ,doxygen)))
      (inputs
       `(("sdcc" ,sdcc)
	 ("ucsim" ,ucsim)))
      (home-page "https://github.com/Zal0/gbdk-2020")
      (synopsis "C compiler, assembler, linker and set of libraries
for the Z80 like Nintendo Gameboy")
      (description "An updated version of GBDK, A C compiler,
assembler, linker and set of libraries for the Z80 like Nintendo
Gameboy.")
      (license license:expat))))

(define-public png2gbtiles
  (package
    (name "png2gbtiles")
    (version "1.12")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/bbbbbr/gimp-tilemap-gb")
             (commit (string-append "v" version))))
       (sha256
        (base32
         "1lqj0km1s2ibvvb5v8gfiw2h7pnqbr29i4f2y0x0j8h061dng47q"))
       (file-name (git-file-name name version))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'build 
           (lambda _
             (with-directory-excursion "console"
               (invoke "make" "png2gbtiles"))))
         (replace 'install 
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (bin (string-append out "/bin")))
               (install-file "console/bin/png2gbtiles" bin)))))))
    (home-page "https://github.com/bbbbbr/gimp-tilemap-gb")
    (synopsis "Command line tool for GB Tilemaps")
    (description "png2gbtiles is a standalone, command line version of the
Tilemap GB GIMP plugin. It allows you to generate GBTD GBR files and GBMB GBM
files from png images.")
    (license license:gpl3+)))

(define-public zgb-tools
  (package
    (name "zgb-tools")
    (version "2021.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/Zal0/ZGB")
             (commit (string-append "v" version))))
       (sha256
        (base32
         "038aln0qqmzg9smihn3i22n071y3ifj5p2dwpw39hvfl2d4z6kis"))
       (file-name (git-file-name name version))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'build 
           (lambda _
             (with-directory-excursion "tools/gbm2c"
               (invoke "g++" "gbm2c.cpp" "-o" "gbm2c"))
             (with-directory-excursion "tools/gbr2c"
               (invoke "g++" "gbr2c.cpp" "-o" "gbr2c"))))
         (replace 'install 
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (bin (string-append out "/bin")))
               (install-file "tools/gbm2c/gbm2c" bin)
               (install-file "tools/gbr2c/gbr2c" bin)))))))
    (home-page "https://github.com/Zal0/ZGB")
    (synopsis "Game Boy / Color tilemap and tileset compilers")
    (description "ZGB is a complete engine for creating Game Boy / Color
games. This package contains only the command line tools for working with GBM
and GBR files.")
    (license license:expat)))


(use-modules (ice-9 popen)
	     (ice-9 match)
	     (ice-9 rdelim)
	     (srfi srfi-1)
             (guix gexp)
	     (srfi srfi-26)
	     ((guix build utils) #:select (with-directory-excursion)))

(define %source-dir (dirname (current-filename)))
(define git-file?
  (let* ((pipe (with-directory-excursion %source-dir
                 (open-pipe* OPEN_READ "git" "ls-files")))
         (files (let loop ((lines '()))
                  (match (read-line pipe)
                    ((? eof-object?)
                     (reverse lines))
                    (line
                     (loop (cons line lines))))))
         (status (close-pipe pipe)))
    (lambda (file stat)
      (match (stat:type stat)
        ('directory
         #t)
        ((or 'regular 'symlink)
         (any (cut string-suffix? <> file) files))
        (_
         #f)))))

(define-public pete-beat-gb
  (package
    (name "pete-beat-gb")
    (version "0")
    (source (local-file %source-dir
			#:recursive? #t
			#:select? git-file?))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f
       #:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (replace 'install 
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (share (string-append out "/share")))
               (install-file "obj/PeteBeat.gb" share)))))))
    (native-inputs
     `(("gbdk-2020" ,gbdk-2020)
       ("png2gbtiles" ,png2gbtiles)
       ("zgb-tools" ,zgb-tools)))
    (home-page "")
    (synopsis "")
    (description "")
    (license license:gpl3+)))

pete-beat-gb
