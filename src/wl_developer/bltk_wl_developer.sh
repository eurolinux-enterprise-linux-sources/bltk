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

startup()
{
	trap 'cleanup 1; exit 1' 1 2 3 15

	TTY=`tty`

	wl_startup
	wl_check_error $?

	wl_check_install developer
	wl_check_error $?

	source $BLTK_WL_ROOT/extern.cfg

	if [[ -z $BLTK_LINUX_PATH ]]
	then
		BLTK_LINUX_PATH=$BLTK_EXTERN_TGT_WL_DEVELOPER/linux-$LINUX_VER
	fi

	if [[ ! -d $BLTK_LINUX_PATH ]]
	then
		echo "Cannot access $BLTK_LINUX_PATH directory"
		cleanup 1
	fi

	if [[ -z $BLTK_WL_JOBS ]]
	then
		BLTK_WL_JOBS=`grep -c ^processor /proc/cpuinfo`
		(( BLTK_WL_JOBS = BLTK_WL_JOBS * 3 ))
	fi

	makejobs=
	if [[ $BLTK_WL_JOBS != 0 ]]
	then
		makejobs="-j $BLTK_WL_JOBS"
	fi

	if [[ -z $BLTK_WL_TIME ]]
	then
		BLTK_WL_TIME=720.00
	fi

	wl_check_prog make
	wl_check_error $?

	wl_check_prog cscope
	wl_check_error $?

	wl_check_prog vi
	wl_check_error $?

	wl_check_run_prog cscope
	wl_check_error $?

	wl_check_run_prog vi
	wl_check_error $?

	CMD_MAKE_CLEAN="make clean"

	CMD_MAKE="make $makejobs"

	CMD_CD="cd $BLTK_LINUX_PATH"
	$CMD_CD
	wl_check_error $? "$CMD_CD failed"

	if [[ -z $BLTK_SHOW_DEMO_NUM ]]
	then
		export BLTK_SHOW_DEMO_NUM=1
	fi

	SCORE_CALIBR=207	# 100 on D600 with freq 1000 MHz
	SCORE_BASE=response
}

run_cscope_vi()
{
	if [[ -z $WINDOWID ]]
	then
		echo "WINDOWID not set"; cleanup 1
	fi

	rm -rf cscope*
	rm -rf drivers/acpi/.battery.c.*

	CMD_CP="cp $BLTK_WL_ROOT/battery.c.orig drivers/acpi/battery.c"
	$CMD_CP
	wl_check_error $? "$CMD_CP failed"

	CMD_FIND="find . -name acpi -type d"
	acpi_dirs=`$CMD_FIND`
	wl_check_error $? "$CMD_FIND failed"

	CMD_FIND="find $acpi_dirs -name '*.c' -type f"
	find $acpi_dirs -name '*.c' -type f >cscope.files
	wl_check_error $? "find $acpi_dirs -name '*.c' -type f >cscope.files failed"

	$BLTK_TYPE_COMMAND_CMD 0 pwd >$TTY 2>&1
	pwd >$TTY 2>&1

	XSE="$BLTK_WL_BIN/bltk_wl_developer_xse"
	$XSE &
	wl_check_error $? "$XSE failed"
	BLTK_WL_PID=$!

	CMD_CSCOPE="cscope -i cscope.files"
	$BLTK_TYPE_COMMAND_CMD 0 "$CMD_CSCOPE" >$TTY 2>&1

#	CMD_SPY="$BLTK_WL_BIN/bltk_wl_developer_spy cscope"
#	$CMD_SPY &
#	RET=$?
#	CMD_SPY_PID=$!
#	if [[ $RET != 0 ]]
#	then
#		echo "$CMD_SPY failed"
#		cleanup 1
#	fi

	$CMD_CSCOPE >$TTY 2>&1	# output is tty
	wl_check_error $? "$CMD_CSCOPE >$TTY 2>&1 failed"

	CMD_CP="cp $BLTK_WL_ROOT/battery.c.orig drivers/acpi/battery.c"
	$CMD_CP
	wl_check_error $? "$CMD_CP failed"

	wait
	wl_check_error $? "wait failed"
	BLTK_WL_PID=
}

run1()
{
	ST_TIME=`$BLTK_TIME_CMD`

	rm -f ./user_delay.tmp
	if [[ $BLTK_WL_FILE != DEBUG && $BLTK_WL_FILE != DEBUG1 ]]
	then
		run_cscope_vi
		wl_check_error $?
	else
		sleep 1
		echo 1.11 >./user_delay.tmp
		wl_check_error $? "echo 0.11 >./user_delay.tmp failed"
	fi

	CMD="cat ./user_delay.tmp"
	DELAY_TIME=`$CMD`
	wl_check_error $? "$CMD failed"

	wl_send_work_msg

	$BLTK_TYPE_COMMAND_CMD 0 "$CMD_MAKE_CLEAN" >$TTY 2>&1
	if [[ $BLTK_WL_FILE != DEBUG  && $BLTK_WL_FILE != DEBUG2 ]]
	then
		$CMD_MAKE_CLEAN  >$TTY 2>&1
	else
		sleep 1
	fi
	wl_check_error $? "$CMD_MAKE_CLEAN >$TTY 2>&1 failed"

	wl_send_work_msg

	$BLTK_TYPE_COMMAND_CMD 0 "$CMD_MAKE" >$TTY 2>&1
	if [[ $BLTK_WL_FILE != DEBUG  && $BLTK_WL_FILE != DEBUG2 ]]
	then
		$CMD_MAKE  >$TTY 2>&1
	else
		sleep 1
	fi
	wl_check_error $? "$CMD_MAKE >$TTY 2>&1 failed"

	WORK_TIME=`$BLTK_TIME_CMD`

	wl_send_work_msg

	WORK_TIME=`$BLTK_CALC_CMD -f2 $WORK_TIME $ST_TIME`
	RESPONSE_TIME=`$BLTK_CALC_CMD -f2 $WORK_TIME $DELAY_TIME`
	SLEEP_TIME=`$BLTK_CALC_CMD -f2 $BLTK_WL_TIME $WORK_TIME`

	if [[ `$BLTK_CALC_CMD 'Ll' $SLEEP_TIME 0` = TRUE ]]
	then
		echo "Warning: Work time ($WORK_TIME seconds)" \
			 "is greater than max time ($BLTK_WL_TIME seconds)"
		echo "Warning: system is very slow"
		SLEEP_TIME=1
	fi

	if [[ $BLTK_SHOW_DEMO = TRUE && $BLTK_SHOW_DEMO_SLEEP != TRUE ]]
	then
		SLEEP_TIME=1.00
	fi

	if [[ $BLTK_WL_FILE == DEBUG* ]]
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
	wait
	exit $1
}

startup
run
cleanup 0

