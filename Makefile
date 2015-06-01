#$Id: Makefile 1116 2011-08-25 03:53:15Z rohare $
#$HeadURL: https://restless/svn/scripts/trunk/Makefile $
#

SCRIPT_DIR= /usr/local/bin

SCRIPT_FILES= catxml.pl \
	ckinstperlmods.pl \
	hms2sec \
	howto \
	journal \
	pwAgeChk.sh \
	sedit \
	sshx \
	w2sec

FILES= ${SCRIPT_FILES}

INST= /usr/bin/install

all: $(FILES)

install: uid_chk all
	@for file in ${SCRIPT_FILES}; do \
		${INST} -p $$file ${SCRIPT_DIR} -o root -g root -m 755; \
	done

uid_chk:
	@if [ `id -u` != 0 ]; then echo You must become root first; exit 1; fi

