EMACS=emacs

VERSION=1.4
PACKAGE=dictionary
TYPE=comm
XEMACS-PACKAGE=$(PACKAGE)-$(VERSION)-pkg.tar.gz

SOURCES=dictionary.el connection.el link.el
COMPILED=dictionary.elc connection.elc link.elc

.SUFFIXES: .elc .el

.el.elc:
	$(EMACS) -q -no-site-file -no-init-file -batch -l lpath.el \
	-f batch-byte-compile $<

.PHONY: all
all: $(COMPILED)

.PHONY: debian
debian:
	@if [ -x /usr/bin/fakeroot ]; then \
	  dpkg-buildpackage -us -uc -rfakeroot; \
	elif [ `id -u` -ne 0 ]; then \
	  echo "You are not root and fakeroot is not installed, aborting"; \
	  exit 1; \
	else \
	  dpkg-buildpackage -us -uc; \
	fi
	@echo "You can now install the debian package, the previous output tells"
	@echo "you its location (probably stored in ..)"
	@echo
	@echo "Please note, this debian package is unofficial, report bugs"
	@echo "to me only, not to the Debian Bugtracking System."

.PHONY: package
package: $(XEMACS-PACKAGE) 

$(XEMACS-PACKAGE): $(COMPILED)
	@case $(EMACS) in emacs*) printf "\aNote, packages work with XEmacs 21 only, hope you know what you are doing\n\n";; esac
	@mkdir -p lisp/$(PACKAGE)
	@mkdir -p pkginfo
	@printf ";;;###autoload\n(package-provide '$(PACKAGE)\n:version $(VERSION)\n:type '$(TYPE))\n" > lisp/$(PACKAGE)/_pkg.el
	@rm -f lisp/$(PACKAGE)/auto-autoloads.el lisp/$(PACKAGE)/custom-load.el
	@cp $(SOURCES) $(COMPILED) lisp/$(PACKAGE)
	@cd lisp &&  \
	$(EMACS) -vanilla -batch -l autoload -f batch-update-directory $(PACKAGE) && \
	$(EMACS) -vanilla -batch -l cus-dep -f Custom-make-dependencies $(PACKAGE) && \
	$(EMACS) -vanilla -batch -f batch-byte-compile $(PACKAGE)/auto-autoloads.el $(PACKAGE)/custom-load.el
	@touch pkginfo/MANIFEST.$(PACKAGE)
	@find lisp pkginfo -type f > pkginfo/MANIFEST.$(PACKAGE)
	@tar cf - pkginfo lisp | gzip -c > $(XEMACS-PACKAGE)

.PHONY: package-install
package-install: package
	@if [ `id -u` -ne 0 ]; then printf "\aWarning, you are not root; the installation might fail\n\n"; fi
	@$(EMACS) -vanilla -batch -l install-package.el -f install-package `pwd`/$(XEMACS-PACKAGE)

.PHONY: clean
clean:
	rm -f $(XEMACS-PACKAGE) $(COMPILED) build
	rm -rf debian/tmp lisp pkginfo
