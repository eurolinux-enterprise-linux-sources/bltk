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

PROGNAME=$0

[[ -z $BLTK_BIN ]] && export BLTK_BIN=$BLTK_ROOT/bin

BLTK_TIME_CMD="$BLTK_BIN/bltk_time"
BLTK_CALC_CMD="$BLTK_BIN/bltk_calc"

if [[ ! -z $BLTK_WORK_OUT_LOG_FILE ]]
then
	TIME=`$BLTK_TIME_CMD`
fi

OPTIONS="ht:ls:SFi"

usage()
{
	echo Usage: $PROGNAME [-$OPTIONS] >&2
}

waittime=120
sleeptime=
longwait=FALSE
flags=
job=START

while getopts $OPTIONS OPT
do
	case $OPT in
		h ) usage; exit 0;;
		S ) job=START;;
		F ) job=FINISH;;
		t ) waittime=$OPTARG;;
		s ) sleeptime=$OPTARG;;
		l ) longwait=TRUE;;
		i ) flags="-int";;
		* ) usage; exit 2;;
	esac
done

shift $((OPTIND-1))

if [[ $# != 1 ]]
then
	echo "$PROGNAME: Invalid args number"
	exit 1
fi

title="$*"

if [[ -z $sleeptime ]]
then
	if [[ $longwait = TRUE ]]
	then
		sleeptime=10
	else
		sleeptime=0.1
	fi
fi

if [[ -z "$title" ]]
then
	echo "$PROGNAME: Title is not set"
	exit 1
fi

ST_SECONDS=$SECONDS

if [[ $job = FINISH ]]
then
	while (( SECONDS - ST_SECONDS < waittime ))
	do
		windowid=`xwininfo $flags -root -tree 2>/dev/null | grep "$title" | tail -1 | awk '{print $1}'`
		[[ -z "$windowid" ]] && break
		if [[ ! -z $BLTK_WORK_OUT_LOG_FILE ]]
		then
			$BLTK_TIME_CMD $sleeptime
		else
			sleep $sleeptime
		fi
	done
	if [[ ! -z $windowid ]]
	then
		echo "Window $title is running"
		exit 1
	fi
else
	while (( SECONDS - ST_SECONDS < waittime ))
	do
		windowid=`xwininfo $flags -root -tree 2>/dev/null | grep "$title" | tail -1 | awk '{print $1}'`
		if [[ ! -z "$windowid" ]]
		then
			[[ $longwait = FALSE ]] && break
			[[ "$windowid" = "$windowid2" ]] && break
			windowid2=$windowid
		fi
		if [[ ! -z $BLTK_WORK_OUT_LOG_FILE ]]
		then
			$BLTK_TIME_CMD $sleeptime
		else
			sleep $sleeptime
		fi
	done
	if [[ -z $windowid ]]
	then
		echo "Window $title is not running"
		exit 1
	fi
fi

if [[ ! -z $BLTK_WORK_OUT_LOG_FILE ]]
then
	TIME2=`$BLTK_TIME_CMD`
	TIME2=`$BLTK_CALC_CMD -f2 $TIME2 $TIME`
fi

if [[ $job != FINISH ]]
then
	echo $windowid
fi
exit 0
