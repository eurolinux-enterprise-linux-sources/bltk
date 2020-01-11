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


source `dirname $0`/../../bin/bltk_wl_common
[[ $? != 0 ]] && { echo "bltk tree corrupted"; exit 2; }

DEF_BROWSER="firefox"
DEF_TITLE="War and Peace"
DEF_FILE="war_and_peace.html"

XSE_PROG="bltk_wl_reader_xse"

startup()
{
	trap 'cleanup 1; exit 1' 1 2 3 15

	wl_startup
	wl_check_error $?

###	wl_check_install reader
###	wl_check_error $?

	if [[ -z $BLTK_WL_PROG ]]
	then
		export BLTK_WL_PROG=$DEF_BROWSER
		export BLTK_WL_PROG_FLG=
	fi

	wl_check_prog $BLTK_WL_PROG
	wl_check_error $?

	wl_check_run_prog $BLTK_WL_PROG
	wl_check_error $?

	echo "Browser	$BLTK_WL_PROG"

	wl_check_all_run_prog $BLTK_WL_PROG
	wl_check_error $?

	tmp_reader_file=/tmp/$DEF_FILE

	if [[ $BLTK_WL_FILE = DEBUG ]]
	then
		BLTK_WL_FILE=
	fi

	if [[ ! -z $BLTK_WL_FILE ]]
	then
		reader_file=$BLTK_WL_FILE
		title="$BLTK_WL_TITLE"
		flags="$BLTK_WL_PROG_FLG"
	else
		default_flg=TRUE
		reader_file=$DEF_FILE
		title=$DEF_TITLE
		flags=""
	fi
	if [[ $default_flg = TRUE ]]
	then
		CMD="$BLTK_SUDO_CMD rm -f $tmp_reader_file"
		$CMD
		wl_check_error $? "$CMD fialed"

		wl_copy_file $reader_file $tmp_reader_file
		$CMD
		wl_check_error $? "$CMD fialed"
		reader_file=$tmp_reader_file
	fi
	export BLTK_WL_TITLE=$title

	echo "File	$reader_file"
	echo "Title	$title"

	[[ -z $title ]] && wl_check_error 1 "Title not set"

	if [[ -d $HOME/.mozilla ]]
	then
		lock=`find $HOME/.mozilla -name lock`
		if [[ ! -z "$lock" ]]
		then
			CMD="rm -f $lock"
			$CMD
			wl_check_error $? "$CMD fialed"
		fi
	fi
	if [[ -z $BLTK_SHOW_DEMO_NUM ]]
	then
		export BLTK_SHOW_DEMO_NUM=1
	fi
	if [[ -z $BLTK_SHOW_DEMO_CNT ]]
	then
		export BLTK_SHOW_DEMO_CNT=2
	fi
	if [[ -z $BLTK_SHOW_DEMO_TIME ]]
	then
		export BLTK_SHOW_DEMO_TIME=5
	fi
}

run1()
{
	ST_TIME=`$BLTK_TIME_CMD`

	rm -f ./user_delay.tmp

	CMD="$BLTK_WL_PROG $BLTK_WL_PROG_FLG $reader_file"
	$CMD &
	wl_check_error $? "$CMD failed"

	BLTK_WL_ALL_PROC_NAME="$BLTK_WL_ALL_PROC_NAME $BLTK_WL_PROG"

	windowid=`bltk_winid -S "$title"`
	wl_check_error $? "Cannot get windowid of $BLTK_WL_PRO"

	[[ -z $BLTK_WL_TIME ]] && export BLTK_WL_TIME=120
	[[ -z $BLTK_WORK_LOG_PROC ]] && export BLTK_WORK_LOG_PROC=

	export WINDOWID=$windowid

	CMD="$BLTK_WL_BIN/$XSE_PROG"
	$CMD
	wl_check_error $? "$CMD failed"

	BLTK_WL_PROC_NAME="$BLTK_WL_PROC_NAME $XSE_PROG"

	CMD="cat ./user_delay.tmp"
	DELAY_TIME=`$CMD`
	wl_check_error $? "$CMD failed"

	WORK_TIME=`$BLTK_TIME_CMD`
	WORK_TIME=`$BLTK_CALC_CMD -f2 $WORK_TIME $ST_TIME`
	RESPONSE_TIME=`$BLTK_CALC_CMD -f2 $WORK_TIME $DELAY_TIME`

	score=`wl_prt_time $WORK_TIME`

	# cycle base calibr N time work delay response idle score

	wl_gen_score \
		"" no "" $CNT $WORK_TIME $WORK_TIME $DELAY_TIME $RESPONSE_TIME 0 -
	wl_check_error $?

	echo "Battery Rating $score"
}

run()
{
	CNT=1
	while :
	do
		run1
		if [[ $BLTK_SHOW_DEMO = TRUE && $CNT = $BLTK_SHOW_DEMO_NUM ]]
		then
			break
		fi
		(( CNT++ ))
	done
}

cleanup()
{
	wl_cleanup $1
	exit $1
}

startup
run
cleanup 0

