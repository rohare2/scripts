# sedit

SCRIPT_DIR= /usr/local/bin
ADMIN_DIR= /usr/local/sbin

SCRIPT_FILES= catxml.pl \
	ckinstperlmods.pl \
	hms2sec \
	howto \
	journal \
	pwAgeChk.sh \
	sedit \
	w2sec

ADMIN_FILES= ban_check.sh \
	block_et.py \
	extract_us_ips.py \
	suricata_alert_chk

INST= /usr/bin/install

install: uid_chk 
	@for file in ${SCRIPT_FILES}; do \
		${INST} -p $$file ${SCRIPT_DIR} -o root -g sudo -m 755; \
	done
	@for file in ${ADMIN_FILES}; do \
		${INST} -p $$file ${ADMIN_DIR} -o root -g sudo -m 754; \
	done

uid_chk:
	@if [ `id -u` != 0 ]; then echo You must become root first; exit 1; fi

