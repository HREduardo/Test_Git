#----------------------------------------------------------------
# project ....: Dissertation
# file .......: Makefile
# authors ....: Pablo Alvarado
# organization: LTI, RWTH Aachen
# creation ...: 24.04.2003
#----------------------------------------------------------------

MAINFILE=tut_01

LATEX=/usr/bin/latex -interaction=batchmode -file-line-error-style
PDFLATEX=pdflatex -interaction=batchmode
ECHO=/bin/echo -E

# TeX files
TEXFILES = $(wildcard ./*.tex) $(wildcard ./*.sty)
PNGFILES = $(wildcard fig/*.png)
JPGFILES = $(wildcard fig/*.jpg)
GPFILES = $(wildcard fig/*_.gp)
OCTFILES = $(wildcard fig/*_.m)
FIGFILES = $(wildcard fig/*.fig)
LFIGFILES = $(wildcard fig/*.ltxfig)
TIKZFILES = $(wildcard fig/*.tikz)
PSTFILES = $(wildcard fig/*.pstricks)
EGPFILES = $(patsubst %.gp,%.eps,$(GPFILES))
EOCTFILES = $(patsubst %.m,%.eps,$(OCTFILES))
EPNGFILES = $(patsubst %.png,%.eps,$(PNGFILES))
EJPGFILES = $(patsubst %.jpg,%.eps,$(JPGFILES))
EFIGFILES = $(patsubst %.fig,%.eps,$(FIGFILES))
ELFIGFILES = $(patsubst %.ltxfig,%.eps,$(LFIGFILES))
EPSTFILES = $(patsubst %.pstricks,%.eps,$(PSTFILES))
EPSFILES = $(wildcard fig/*.eps) $(EGPFILES) $(EOCTFILES) $(EPNGFILES) $(EJPGFILES) $(EFIGFILES) $(ELFIGFILES) $(EPSTFILES) $(ETIKZFILES)

PTIKZFILES = $(patsubst %.tikz,%.pdf,$(TIKZFILES))

PDFFILES = $(patsubst %.eps,%.pdf,$(EPSFILES)) $(PTIKZFILES)

BIBFILES = $(wildcard *.bib)

# implicit rules (pattern rules)

# for eps from octave files
fig/%_.eps : fig/%_.m
	@echo "Generating $@ from $<" ; \
	cd fig ; octave-cli -q ../$<

# for eps from gnuplot files
fig/%_.eps : fig/%_.gp
	@echo "Generating $@ from $<" ; \
	cd fig ; gnuplot ../$<

# for eps images from png
fig/%.eps : fig/%.png
	@echo "Converting $< to $@" ; \
	convert -density 100x100 $< 'eps:-' > $@

# for eps images from jpeg
fig/%.eps : fig/%.jpg
	@echo "Converting $< to $@" ; \
	jpeg2ps  $< > $@

# for eps images from fig
# WARNING: fig files may include eps files directly, so, the following trick
#          of changing to fig to go back with each file is done so that fig2dev
#          can find those files.
fig/%.eps : fig/%.fig
	@echo "Converting $< to $@" ; \
	cd fig ; fig2dev -L eps ../$< ../$@

#
# for eps images from ltxfig files (fig files with LaTeX code)
# it is assumed that there exists a file with the same basename but extension
# psfrag.  It must contain the LaTeX code to work with a preliminar eps file
# with extension epstmp.
#
# If the file with extension psfrag does not exist, it will be created with
# a default content, which is: \includegraphics{your_file.epstmp}
#
fig/%.eps : fig/%.ltxfig fig/%.psfrag
	@echo "Converting $< to $@" ; \
	file=`basename $< .ltxfig` ; \
	cd fig ; fig2dev -L eps -K $$file.ltxfig $$file.epstmp ; \
	if [ ! -f $$file.psfrag ] ; then \
	  $(ECHO) "\includegraphics{$$file.epstmp}" > $$file.psfrag ; \
	fi ; \
	($(ECHO) '\documentclass{article}' ; \
	 $(ECHO) '\usepackage[spanish]{babel}' ; \
	 $(ECHO) '\usepackage[utf8]{inputenc}' ; \
	 $(ECHO) '\usepackage{mathrsfs,amsmath,amssymb,amstext}' ; \
	 $(ECHO) '\usepackage{graphicx,color,psfrag}' ; \
	 $(ECHO) '\pagestyle{empty}' ; \
	 $(ECHO) '\begin{document} '; \
	 cat $$file.psfrag ; \
	 $(ECHO) '\end{document}')> ../$<.tex ; \
	if ( $(LATEX) ../$<.tex ) ; then \
	  dvips -Ppdf -T 60cm,60cm -o $$file.ps ../$<.dvi ; \
	  ps2eps -l -f $$file.ps ; \
		rm  -f $$file.ps ../$<.aux ../$<.tex ../$<.log ../$<.dvi ; \
	  rm  -f $$file.epstmp ; \
	else \
	  echo "Error running LaTeX on $<." ; \
	  cat ../$<.log ; \
	fi

#
# for eps images from ltxfig files (fig files with LaTeX code)
# it is assumed that there exists a file with the same basename but extension
# psfrag.  It must contain the LaTeX code to work with a preliminar eps file
# with extension epstmp.
#
# If the file with extension psfrag does not exist, it will be created with
# a default content, which is: \includegraphics{your_file.epstmp}
#
fig/%.eps : fig/%.pstricks
	@echo "Converting $< to $@" ; \
	bn=`basename $< .pstricks` ; \
	file=$$bn.pstricks ; \
	cp $< $<.tex ; \
	cd fig ; \
        echo "  Processing $$file.tex" ; \
	if ( $(LATEX) $$file.tex && \
    dvips -Ppdf -T 60cm,60cm -o $$bn.ps $$file.dvi ) ; then \
	  ps2eps -l -f $$bn.ps ; \
	  rm -f $$file.aux $$file.log $$bn.ps $$file.dvi ; \
	  rm -f $$file.tex ; \
	else \
	  echo "Error running LaTeX on $<.tex" ; \
	  rm -f $$file.aux $$bn.ps $$file.dvi ; \ # $$file.tex ; \
	fi

fig/%.psfrag:
	file=`basename $@ .psfrag` ; \
	if [ ! -f $@ ] ; then \
	  echo "\\includegraphics{$$file.epstmp}" > $@ ; \
	  cp $@ $@.TODO ; \
	fi

# TIKZ
fig/%.pdf : fig/%.tikz
	@echo "Converting $< to $@" ; \
	bn=`basename $< .tikz` ; \
	file=$$bn.tex ; \
	cp $< fig/$$file ; \
	cd fig ; \
        echo "  Processing $$file" ; \
	if ( $(PDFLATEX) $$file ) ; then \
	  rm -f $$bn.aux $$bn.log ; \
	  rm -f $$file ; \
	else \
	  echo "Error running LaTeX on $$file" ; \
	  rm -f $$bn.aux ; \
	fi


# for pdf images from eps
fig/%.pdf : fig/%.eps
	@echo "Converting $< to pdf" ; \
	epstopdf --outfile=$@ $<

# -----------------------------------------------------------------------------
# Targets
# -----------------------------------------------------------------------------
pdf:     $(MAINFILE).pdf

$(MAINFILE).pdf:	$(TEXFILES) $(PDFFILES)
	@echo "Generating PDF file..."; \
	echo "------------------------------------------" ;\
	echo "Running latex once..." ;\
	$(PDFLATEX) $(MAINFILE) > pdf.log 2>&1 ;\
# 	if ( bibtex $(MAINFILE) >> pdf.log 2>&1 ) ; then \
# 	  echo " Bibliography ok" ;\
# 	else \
# 	  echo " Bibliography failed" ;\
# 	fi ;\
	$(PDFLATEX) $(MAINFILE) > pdf.log 2>&1 ;\
	latex_count=5 ; \
	while egrep -s 'Rerun (LaTeX|to get cross-references right)' $(MAINFILE).log && [ $$latex_count -gt 0 ] ;\
	    do \
	      echo "Rerunning latex...." ;\
	      $(PDFLATEX) $(MAINFILE).tex >> pdf.log 2>&1 ;\
	      latex_count=`expr $$latex_count - 1` ;\
	    done ;\
	echo "Ready."

force-pdf: 
	touch $(MAINFILE).tex ;\
	make pdf

figs:	$(EPSFILES)

pdfigs: figs $(PDFFILES)

partial-clean:
	@echo "Cleaning..." ;\
	rm -f *.log *.lot *.toc *.lof *.aux *.dvi *.nlo *.nls ;\
	rm -f *.idx *.ilg *.ind *.bbl *.blg *.brf *.out *.todo *.flc *.xmp ;\

clean:  partial-clean
	@cd fig ;\
	for e in .fig .png .jpg .ltxfig _.eps ; do \
	  for i in `find . -name "*$$e"` ; do \
	    b=`basename $$i $$e`.eps ;\
	    if [ -f $$b ] ; then \
	      rm $$b ;\
	    fi ;\
	  done ;\
	done ;\
	for i in `find . -name "*_.gp"` ; do \
	  b=`basename $$i .gp`.eps ;\
	  if [ -f $$b ] ; then \
	    rm $$b ;\
	  fi ;\
	done ;\
	echo "Done." ;\
	cd ..

clean-all: clean
	@rm -f `find . -name "*~"` \#* fig/*.aux ;\
	rm -f fig/*.pdf ;\
	rm -fr *.ps *.pdf ;\
	rm -fr `find . -name ".xvpics"` \.#* ;\
	rm -fr fig/*fig.bak ;\
	echo "All cleaned up"

help:
	@echo "This Makefile provides following targets: " ;\
	echo " pdf:       generate $(MAINFILE).pdf" ;\
	echo " force-pdf: force generation of $(MAINFILE).pdf" ;\
	echo " figs:      create eps image files from jpg,png,fig,etc." ;\
	echo " pdfigs:    create pdf image files from jpg,png,fig,etc." ;\
	echo " clean:     remove temporary files but keep final ps and pdf" ;\
	echo " clean-all: like clean but remove also final files"
