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
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBGMORS
#  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BGM NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#  OWNER OR CONTRIBGMORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BGM NOT LIMITED
#  TO, PROCUREMENT OF SUBSTITGME GOODS OR SERVICES;
#  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
#  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OGM OF
#  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
#  DAMAGE.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#

set -x 

source `dirname $0`/../../bin/bltk_wl_common
[[ $? != 0 ]] && { echo "bltk tree corrupted"; exit 2; }
startup()
{
	trap 'cleanup 1; exit 1' 1 2 3 15

	TTY=`tty`

	wl_startup
	wl_check_error $?

	wl_check_install game
	wl_check_error $?

	if [[ -z $BLTK_SHOW_DEMO_NUM ]]
	then
		BLTK_SHOW_DEMO_NUM=1
	fi
	if [[ -z $BLTK_SHOW_DEMO_TIME ]]
	then
		BLTK_SHOW_DEMO_TIME=
	fi

	wl_check_prog $BLTK_WL_PROG
	wl_check_error $?

	wl_check_run_prog $BLTK_WL_PROG
	wl_check_error $?

	wl_check_all_run_prog $BLTK_WL_PROG
	wl_check_error $?
###	env | sort >env.log
}

clean_gmhome()
{
	if [[ -d $GMHOME ]]
	then
		CMD="$BLTK_SUDO_CMD rm -rf $GMHOME"
		$CMD
		wl_check_error $? "$CMD failed"
	fi
}

game_preparation()
{
	GMHOME=$HOME/.openarena
	if [[ ! -d $GMHOME ]]
	then 
		CMD="mkdir $GMHOME"
		$CMD
		wl_check_error $? "$CMD failed"
	fi

	FIRST_SCORE=1

	RES=$GMHOME/anholt.results
	if [[ `uname -m` == x86_64 ]]
	then 
		export GM_PROG=$BLTK_TMP_WL_GAME/openarena-0.7.0/ioquake3-smp.x86_64
	else 
	        export GM_PROG=$BLTK_TMP_WL_GAME/openarena-0.7.0/ioquake3-smp.i386
	fi


	if [[ ! -x $GM_PROG ]]
	then
		echo "Cannot access $GM_PROG"
		cleanup 1
	fi

	if [[ $BLTK_SHOW_DEMO = TRUE ]]
	then
		GAME_TIME=30.00
	else
		GAME_TIME=300.00
	fi
	[[ ! -z $BLTK_WL_TIME ]] && GAME_TIME=$BLTK_WL_TIME

	EXEC1="+exec anholt"

	#EXEC2="exec=$GAHOME/baseoa/demo002.cfg"

	FLAGS=" +set ttycon 0 "

	WORK_DEMO="$EXEC1 $FLAGS"
}

game()
{
	ST_TIME=`$BLTK_TIME_CMD`
	#clean_gmhome
	CMD="$GM_PROG $WORK_DEMO"
	echo "$CMD"
	if [[ $BLTK_SHOW_DEMO = TRUE && $BLTK_SHOW_DEMO_KILL = TRUE ]]
	then
		$CMD  &>$RES &
		ret=$?
		pid=$!
		wl_check_error $? "$CMD failed"
		sleep $GAME_TIME
		/bin/kill -QUIT $pid >/dev/null 2>&1
	else
		$CMD &>$RES
		cat $RES | egrep -e '[0-9]+ frames' -q
		wl_check_error $? "$CMD failed"
	fi
	wait
	wl_send_work_msg
	WORK_TIME=`$BLTK_TIME_CMD`
	WORK_TIME=`$BLTK_CALC_CMD -f2 $WORK_TIME $ST_TIME`
	echo "TIME: Expected $GAME_TIME, Actually $WORK_TIME"
	cat $RES
	score=`cat $RES | egrep -e '[0-9]+ frames' | awk '{print $5}'`
	if [[ -z $score ]]
	then
		echo "Cannot get score from $RES files, setting score to zero"
		score=0
	fi
	wl_gen_score \
		"" score "" $CNT $WORK_TIME $WORK_TIME 0 $WORK_TIME 0 "$score"
	wl_check_error $?
	echo "$CNT: Score $score"
	echo "$CNT: Score $score" >$TTY 2>&1
}

run1()
{
	game
}

run()
{
	game_preparation
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

