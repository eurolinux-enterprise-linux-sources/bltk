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

XSE_PROG="bltk_wl_office_xse"

startup()
{
	trap 'cleanup 1; exit 1' 1 2 3 15

	TTY=`tty`

	wl_startup
	wl_check_error $?

	wl_check_install office
	wl_check_error $?

	export SOFFICE_PROG=$HOME/soffice

	BLTK_WL_OFFICE_SCEN=$BLTK_WL_FILE

	if [[ -z $BLTK_WL_OFFICE_SCEN ]]
	then
		BLTK_WL_OFFICE_SCEN=./scen
	else
		echo "OOo apps running by scenario $BLTK_WL_OFFICE_SCEN"
	fi
	if [[ -z $BLTK_SHOW_DEMO_NUM ]]
	then
		export BLTK_SHOW_DEMO_NUM=1
	fi
	if [[ -z $BLTK_WL_TIME ]]
	then
		BLTK_WL_TIME=720.00
	fi

	SCORE_CALIBR=24	# 100 on D600 with freq 1000 MHz
	SCORE_BASE=response
}

run1()
{
	ST_TIME=`$BLTK_TIME_CMD`

	wl_remove_file OOWRITER_FILE.odt
	wl_check_error $?
	wl_copy_file OOWRITER_FILE_SAMPLE.odt OOWRITER_FILE.odt
	wl_check_error $?

	wl_remove_file OOCALC_FILE.ods
	wl_check_error $?
	wl_copy_file OOCALC_FILE_SAMPLE.ods OOCALC_FILE.ods
	wl_check_error $?

	wl_remove_file OODRAW_FILE.odg
	wl_check_error $?
	wl_copy_file OODRAW_FILE_SAMPLE.odg OODRAW_FILE.odg
	wl_check_error $?

	wl_remove_file ./user_delay.tmp
	wl_check_error $?

	if [[ $BLTK_WL_OFFICE_SCEN = DEBUG ]]
	then
		sleep 1
		echo 0.11 > ./user_delay.tmp
		wl_check_error $? "echo 1.11 >./user_delay.tmp failed"
	elif [[ -f "$BLTK_WL_OFFICE_SCEN" ]]
	then
		CMD="$BLTK_WL_BIN/$XSE_PROG $BLTK_WL_OFFICE_SCEN"
#####		\time -p $CMD >./XSE.times 2>&1
		$CMD
	else
		wl_check_error 1 "Cannot access $BLTK_WL_OFFICE_SCEN"
	fi

	CMD="cat ./user_delay.tmp"
	DELAY_TIME=`$CMD`
	wl_check_error $? "$CMD failed"

	WORK_TIME=`$BLTK_TIME_CMD`
	WORK_TIME=`$BLTK_CALC_CMD -f2 $WORK_TIME $ST_TIME`
	RESPONSE_TIME=`$BLTK_CALC_CMD -f2 $WORK_TIME $DELAY_TIME`
	SLEEP_TIME=`$BLTK_CALC_CMD -f2 $BLTK_WL_TIME $WORK_TIME`

	if [[ `$BLTK_CALC_CMD 'Ll' $SLEEP_TIME 0` = TRUE ]]
	then
		wl_warning_msg "Work time ($WORK_TIME seconds)" \
			 "is greater than max time ($BLTK_WL_TIME seconds)"
		wl_warning_msg "System is very slow"
		SLEEP_TIME=1.00
	fi

	if [[ $BLTK_SHOW_DEMO = TRUE && $BLTK_SHOW_DEMO_SLEEP != TRUE ]]
	then
		SLEEP_TIME=1.00
	fi

	echo "Sleeping for $SLEEP_TIME seconds, wait"
	echo "Sleeping for $SLEEP_TIME seconds, wait" >$TTY 2>&1

	wl_display_off
	$BLTK_TIME_CMD $SLEEP_TIME
	wl_send_idle_msg
	wl_display_on

	score=`$BLTK_CALC_CMD '*f2' 100 $SCORE_CALIBR`
	score=`$BLTK_CALC_CMD "/f2" $score $RESPONSE_TIME`

	# cycle base calibr N time work delay response idle score

	wl_gen_score \
		$BLTK_WL_TIME response $SCORE_CALIBR \
		$CNT $BLTK_WL_TIME $WORK_TIME \
		$DELAY_TIME $RESPONSE_TIME $SLEEP_TIME $score
	wl_check_error $?

	echo "$CNT: Score $score"
	echo "$CNT: Score $score" >$TTY 2>&1
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

