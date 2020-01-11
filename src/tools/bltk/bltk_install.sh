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


source `dirname $0`/bltk_wl_common
[[ $? != 0 ]] && { echo "bltk tree corrupted"; exit 2; }

PROG=`basename $0`

WL=
RES=RESULTS.check

OPTIONS="hsiuRDOPGXr:df:"

usage()
{
	echo "Usage: $PROG [-$OPTIONS]"
}

command_line()
{
	while getopts $OPTIONS OPT
	do
		case $OPT in
			h ) usage; exit 0;;
			s ) SU=TRUE;;
			i ) WORK="$WORK install";;
			u ) WORK="$WORK uninstall";;
			D ) WL="$WL developer";;
			O ) WL="$WL office";;
			P ) WL="$WL player";;
			G ) WL="$WL game";;
			X ) WL="$WL developer office";;
			d ) DEBUG=TRUE;;
			f ) FLAGS="$FLAGS $OPTARG";;
			* ) usage; exit 2;;
		esac
	done

	shift $((OPTIND-1))

	ARGS="$*"
	[[ -z $WL && $SU != TRUE ]] && WL="developer office player game"
	[[ -z $WORK && $SU != TRUE ]] && WORK=install
}

cmd_startup
[[ $? != 0 ]] && exit 1

command_line "$@"

PARAMS="$FLAGS $ARGS"

WL_CNT=0
for wl in $WL
do
	WLA[WL_CNT]=$wl
	WLR[WL_CNT]="unresolved (internal error)"
	WLT[WL_CNT]=0
	(( WL_CNT++ ))
done

cd $BLTK_ROOT
[[ $? != 0 ]] && exit 1

$BLTK_SUDO_CMD >/dev/null 2>&1
if [[ $? != 0 ]]
then
	SU=TRUE
fi

if [[ $SU = TRUE ]]
then
	make su
	[[ $? != 0 ]] && exit 1
fi

CWD=$PWD

for work in $WORK
do
	{
	WL_TM=$SECONDS
	wl_cnt=0
	while (( wl_cnt < WL_CNT ))
	do
		wl=${WLA[wl_cnt]}
		wl_set_time
		echo "=== Workload '$wl'"
		CMD="./bin/bltk_wl_${wl}_install $work $PARAMS"
		cd wl_${wl}
		[[ $? != 0 ]] && exit 1
		if [[ $DEBUG = TRUE ]]
		then
			echo "$CMD"
		else
			$CMD
		fi
		ret=$?
		cd $CWD
		[[ $? != 0 ]] && exit 1
		if [[ $ret != 0 || -a wl_${wl}/fail ]]
		then
			FAIL=TRUE
			WLR[wl_cnt]=failed
		else
			WLR[wl_cnt]=passed
		fi
		WLT[wl_cnt]=`wl_get_time`
		(( wl_cnt++ ))
	done

	echo "=== Summary:"
	wl_cnt=0
	while (( wl_cnt < WL_CNT ))
	do
		wl=${WLA[wl_cnt]}
		res=${WLR[wl_cnt]}
		tm=${WLT[wl_cnt]}
		echo "=== Workload '$wl' $res, time `wl_prt_time $tm`"
		(( wl_cnt++ ))
	done
	echo "=== Time `wl_prt_time $(( SECONDS - WL_TM))`"
	} 2>&1 | tee -i ./$work.log
done
if [[ $FAIL = TRUE ]]
then
	exit 2
else
	exit 0
fi


