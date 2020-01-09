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

	wl_startup
	wl_check_error $?

	source $BLTK_WL_ROOT/extern.cfg

	wl_check_install player
	wl_check_error $?

	if [[ $BLTK_WL_FILE = DEBUG ]]
	then
		BLTK_WL_FILE=
	fi
	if [ $PLAY_MD != "dvd://" -a $PLAY_MD != "vcd://" ]
	then
		BLTK_WL_FILE=$BLTK_EXTERN_SRC_WL_PLAYER/$PLAY_MD
	else 
		set_dvd_config
		BLTK_WL_FILE=$PLAY_MD
	fi

echo ALEX DEBUG BLTK_WL_FILE is $BLTK_WL_FILE 

	if [[ -z $BLTK_WL_PROG ]]
	then
		BLTK_WL_PROG=$BLTK_EXTERN_TGT_WL_PLAYER/mplayer/bin/mplayer
	fi
	if [[ -z $BLTK_WL_PROG_FLG ]]
	then
		BLTK_WL_PROG_FLG="-fs -quiet"
	fi

	if [[ -z $BLTK_SHOW_DEMO_NUM ]]
	then
		export BLTK_SHOW_DEMO_NUM=1
	fi
	if [[ -z $BLTK_SHOW_DEMO_TIME ]]
	then
		export BLTK_SHOW_DEMO_TIME=60
	fi

	wl_check_prog $BLTK_WL_PROG
	wl_check_error $?

	wl_check_run_prog $BLTK_WL_PROG
	wl_check_error $?

	wl_check_all_run_prog $BLTK_WL_PROG
	wl_check_error $?
###	env | sort >env.log
}

set_dvd_config()
{
	typeset dvd

	for d in /dev/cdrom /dev/hdc /dev/hdd /dev/sr0
	do
		if [[ -a $d ]]
		then
			dvd=$d
			break
		fi
	done

	if [[ ! -a /dev/dvd && ! -z $dvd ]]
	then
		$BLTK_SUDO_CMD ln -s $dvd /dev/dvd
		$BLTK_SUDO_CMD chmod a+r /dev/dvd
		$BLTK_SUDO_CMD hdparm -d1 /dev/dvd
	fi
}

run1()
{
	ST_TIME=`$BLTK_TIME_CMD`

	CMD="$BLTK_WL_PROG $BLTK_WL_PROG_FLG $BLTK_WL_FILE"
	if [[ $BLTK_SHOW_DEMO = TRUE && $BLTK_SHOW_DEMO_TIME != 0 ]]
	then
		$CMD &
		wl_check_error $? "CMD failed"
		pid=$!
		sleep $BLTK_SHOW_DEMO_TIME
		prog=`basename $BLTK_WL_PROG`
		pgrep $prog
		wl_check_error $? "$prog is not running"
		/bin/kill -QUIT $pid >/dev/null 2>&1
		wait
	else
		$CMD
		wl_check_error $?
	fi
	wl_send_work_msg
	WORK_TIME=`$BLTK_TIME_CMD`
	WORK_TIME=`$BLTK_CALC_CMD -f2 $WORK_TIME $ST_TIME`

	if [[ `$BLTK_CALC_CMD Ll $WORK_TIME 60` = TRUE && $BLTK_SHOW_DEMO != TRUE ]]
	then
		echo "ERROR: $CMD unexpectedly finished, "\
				"check if DVD is inserted"
		cleanup 1
	fi

	score=`wl_prt_time $WORK_TIME`

	# cycle base calibr N time work delay response idle score

	wl_gen_score \
		"" no "" $CNT $WORK_TIME $WORK_TIME 0 $WORK_TIME 0 -
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

