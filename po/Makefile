# Makefile for various po files.

srcdir = .

CATALOGS = $(LINGUAS)
MO_FILES = $(addsuffix .mo, $(LINGUAS))

MSGMERGE    = msgmerge
MSGFMT      = msgfmt
XGETTEXT    = xgettext
CATOBJEXT   = .po

include $(srcdir)/PACKAGE

TEXTDOMAIN_POT = $(addsuffix .pot, $(TEXTDOMAIN))
TEXTDOMAIN_POX = $(addsuffix .pox, $(TEXTDOMAIN))
TEXTDOMAIN_MO = $(addsuffix .mo, $(TEXTDOMAIN))

default: help

all: $(TEXTDOMAIN_POT) update-po update-mo install

help:
	@echo "Available targets:"
	@echo "  pot                       - remake master catalog"
	@echo "  update-po                 - merge po files"
	@echo "  update-mo                 - regenerate mo files"
	@echo "  install                   - install mo files"
	@echo "  all                       - all of the above"

POTFILES = $(srcdir)/POTFILES.in \
	$(shell cat $(srcdir)/POTFILES.in) 

TEMPLATES = $(srcdir)/TEMPLATES.in \
        $(shell cat $(srcdir)/TEMPLATES.in)

pot: $(TEXTDOMAIN_POT) 

clean:
	rm -f *~ *.bak *.mo

# FIXME: The parameter --from-code is only needed if your sources contain
# any 8 bit data (even in comments).  UTF-8 is only a guess here, but it
# will at least accept any 8 bit data.
$(TEXTDOMAIN_POT): $(POTFILES) $(srcdir)/PACKAGE
	$(XGETTEXT) --output=$(srcdir)/$(TEXTDOMAIN_POX) --from-code=utf-8 \
		--add-comments=TRANSLATORS: --files-from=$(srcdir)/POTFILES.in \
		--copyright-holder="$(COPYRIGHT_HOLDER)" \
		--msgid-bugs-address="$(MSGID_BUGS_ADDRESS)" \
		--keyword --keyword='$$__' --keyword=__ --keyword=__x \
		--keyword=__n:1,2 --keyword=__nx:1,2 --keyword=__xn:1,2 \
		--keyword=N__ --keyword=%__ && \
	rm -f $@ && \
		mv $(srcdir)/$(TEXTDOMAIN_POX) $@

install: $(MO_FILES)
	cd $(srcdir); \
	targetdir='$(libdir)/LocaleData'; \
	languages='$(LINGUAS)'; \
	for lang in $$languages; do \
		mkdir -p "$$targetdir/$$lang/LC_MESSAGES" || exit 1; \
		dest="$$targetdir/$$lang/LC_MESSAGES/$(TEXTDOMAIN_MO)"; \
		cat="$$lang.mo"; \
		echo "installing $$cat as $$dest"; \
		cp -f $$cat $$dest && chmod 644 $$dest || exit 1; \
	done

update-mo: $(MO_FILES)

update-po:
	$(MAKE) $(TEXTDOMAIN_POT)
	cd $(srcdir); \
        catalogs='$(CATALOGS)'; \
        for cat in $$catalogs; do \
          cat=`basename $$cat`; \
          lang=`echo $$cat | sed 's/\$(CATOBJEXT)$$//'`; \
          mv $$lang.po $$lang.old.po; \
          echo "$$lang:"; \
          if $(MSGMERGE) $$lang.old.po $(TEXTDOMAIN_POT) -o $$lang.po; then \
            rm -f $$lang.old.po; \
          else \
            echo "msgmerge for $$cat failed!"; \
            rm -f $$lang.po; \
            mv $$lang.old.po $$lang.po; \
          fi; \
        done

.SUFFIXES:
.SUFFIXES: .po .mo

.po.mo:
	$(MSGFMT) --check --statistics --verbose -o $@ $<

