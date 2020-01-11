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
RES=check.results

OPTIONS="hIRDOPGXr:df:"

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
			I ) WL="$WL idle";;
			R ) WL="$WL reader";;
			D ) WL="$WL developer";;
			O ) WL="$WL office";;
			P ) WL="$WL player";;
			G ) WL="$WL game";;
			X ) WL="$WL reader developer office";;
			r ) RES="$OPTARG";;
			d ) DEBUG=TRUE;;
			f ) FLAGS="$FLAGS $OPTARG";;
			* ) usage; exit 2;;
		esac
	done

	shift $((OPTIND-1))

	ARGS="$*"

	[[ -z $WL ]] && WL="idle reader developer office player game"
}

cmd_startup
[[ $? != 0 ]] && exit 1

$BLTK_SUDO_CMD
if [[ $? != 0 ]]
then
	echo "Cannot run $BLTK_SUDO_CMD"
	echo "Please perform 'make su' command"
	exit 2
fi

command_line "$@"

#rm -rf $RES
mkdir -p $RES

echo "=== Results will be available in $RES directory"

###	PARAMS="--ac-ignore --bat-stat-ignore --show --show --yes $FLAGS $ARGS"
PARAMS="--ac-ignore --show --show --yes $FLAGS $ARGS"

WL_TM=$SECONDS
WL_CNT=0
for wl in $WL
do
	WLA[WL_CNT]=$wl
	WLR[WL_CNT]="unresolved (internal error)"
	WLT[WL_CNT]=0
	(( WL_CNT++ ))
done

ALL_WL_RES=
wl_cnt=0
while (( wl_cnt < WL_CNT ))
do
	wl_set_time
	wl=${WLA[wl_cnt]}
	WL_RES=$RES/$wl.results
	echo "=== Workload '$wl'"
	if [[ ! -f $BLTK_ROOT/wl_$wl/.installed && $wl != idle && $wl != reader ]]
	then
		echo "not installed";
		WLR[wl_cnt]="not installed"
		touch "$WL_RES.not_installed"
		(( wl_cnt++ ))
		continue
	fi
	ALL_WL_RES="$ALL_WL_RES $WL_RES"
	CMD="$BLTK_BIN/bltk --comment check --$wl --results $WL_RES $PARAMS"
	echo $CMD
	$CMD
	if [[ $? != 0 ]]
	then
		FAIL=TRUE
		WLR[wl_cnt]=failed
		touch "$WL_RES.fail"
	else
		WLR[wl_cnt]=passed
		touch "$WL_RES.pass"
	fi
	$BLTK_BIN/bltk_report -E $WL_RES
	echo "=== Report is available in $WL_RES/Report"
	WLT[wl_cnt]=`wl_get_time`
	(( wl_cnt++ ))
done

(( WL_TM2 = SECONDS - WL_TM ))

if [[ ! -z $ALL_WL_RES ]]
then
	$BLTK_BIN/bltk_report_table -E $ALL_WL_RES >$RES/Summary
	$BLTK_BIN/bltk_report_table -ES $ALL_WL_RES >$RES/Summary.S
	echo "=== Summary is available in $RES/Summary"
fi

echo "=== Summary:"
wl_cnt=0
while (( wl_cnt < WL_CNT ))
do
	wl=${WLA[wl_cnt]}
	res=${WLR[wl_cnt]}
	tm=${WLT[wl_cnt]}
	WL_RES=$RES/$wl.results
	echo "=== Workload '$wl' $res, time `wl_prt_time $tm`"
	(( wl_cnt++ ))
done
echo "=== Time `wl_prt_time $WL_TM2`"

if [[ $FAIL = TRUE ]]
then
	exit 2
else
	exit 0
fi


