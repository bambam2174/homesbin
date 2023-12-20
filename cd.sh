#!/bin/zsh

# $FreeBSD: src/usr.bin/alias/generic.sh,v 1.2 2005/10/24 22:32:19 cperciva Exp $
# This file is in the public domain.
# copied from `/usr/bin/cd` (Author's Remark, Anmerkung des Autors)
#
builtin `echo ${0##*/} | tr \[:upper:] \[:lower:]` ${1+"$@"}
