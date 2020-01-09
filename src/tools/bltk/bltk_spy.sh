#!/bin/bash
#
#  Copyright (c) 2006 Intel Corp.
#  Copyright (c) 2006 Konstantin Karasyov <konstantin.a.karasyov@intel.com>
#  Copyright (c) 2006 Vladimir Lebedev <vladimir.p.lebedev@intel.com>
#  All rights reserved.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Redistribution and use in source and binary forms, with or without
#  modification, are permitted provided that the following conditions
#  are met:
#
#    Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
#    Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
#    Neither the name of Intel Corporation nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
#  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
#  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
#  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
#  DAMAGE.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#


unalias -a

PROG=`basename $0`

BLTK_BIN=`dirname $0`
BLTK_ROOT=`dirname $BLTK_BIN`

BLTK_TMP=$BLTK_ROOT/tmp

PS_CMD="ps -e -o comm,pid,ppid,time"

SLEEP_TIME=10

file_old=$BLTK_TMP/bltk_spy_file_old
file_new=$BLTK_TMP/bltk_spy_file_new
file_diff=$BLTK_TMP/bltk_spy_file_diff
file_grep=$BLTK_TMP/bltk_spy_file_grep
file_sum=$BLTK_TMP/bltk_spy_file_sum

OPTIONS="t:f:"

usage()
{
	echo Usage: $0 [-$OPTIONS]
}

while getopts $OPTIONS OPT
do
	case $OPT in
		h ) usage; exit 0;;
		t ) SLEEP_TIME=$OPTARG;;
		f ) file_sum=$OPTARG;;
		* ) usage; exit 1;;
	esac
done

shift $((OPTIND-1))

if [[ $# != 0 ]]
then
	usage; exit 1
fi

startup()
{
	trap 'cleanup; exit 1' 1 2 3 6 15
	rm -f $file_old $file_new $file_diff $file_grep
	touch $file_old $file_new
	{
	printf '^sort \n^ps \n^grep \n^bltk \n^xset \n^sh \n^bash \n^hdparm \n^COMMAND \n'
	} >$file_grep
}

cleanup()
{
:#	rm -f $file_old $file_new $file_diff $file_grep
}

get_time()
{
	typeset tm=$1
	typeset hh
	typeset mm
	typeset ss

	(( ss = tm % 60 ))
	(( mm = tm / 60 ))
	(( hh = mm / 60 ))
	(( mm = mm % 60 ))
	TIME=`printf "%02i:%02i:%02i" $hh $mm $ss`
}

startup

while :	sleep $SLEEP_TIME

do
	$PS_CMD | sort | grep -v -f $file_grep >$file_new

	diff $file_new $file_old | grep -e '^>
^<' >$file_diff
	if [[ -s $file_diff ]]
	then
		get_time $SECONDS
		echo "$TIME ==================================="
		cat $file_diff
	fi >>$file_sum
	x=$file_new; file_new=$file_old; file_old=$x
	sleep $SLEEP_TIME
done

cleanup

