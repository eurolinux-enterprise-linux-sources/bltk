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

PROG=$0

CPUFREQ=$1

ITEM_NO=0

error()
{
	echo "$PROG: ERROR: $*" >&2
	exit 1
}

warning()
{
	echo "$PROG: Warning: $*" >&2
}

setvar()
{
	typeset	file=$1
	typeset	name=$2
	typeset	str

	if [[ ! -r $file ]]
	then
##		warning "Cannot access $file"
		return
	fi
	str=`cat $file`
	echo "CPUFREQ_${ITEM_NO}_${name} = $str"
}

[[ ! -d $CPUFREQ ]] && exit

dlist=`ls $CPUFREQ`

CWD=$PWD

for d in $dlist
do
	cd $CWD
	D="$CPUFREQ/$d/cpufreq"
	[[ ! -d $D ]] && continue
	[[ $d != cpu* ]] && continue
	(( ITEM_NO++ ))
	NO=${d#cpu}
	[[ -z "$NO" ]] && NO=0
	cd $D
	[[ $? != 0 ]] && warning "Cannot change dir to $D"
	echo "CPUFREQ_${ITEM_NO}_PATH = $D"
	echo "CPUFREQ_${ITEM_NO}_NO = $NO"
	setvar affected_cpus AFFECTED_CPUS
###	setvar cpuinfo_cur_freq	CPUINFO_CUR_FREQ
	setvar cpuinfo_max_freq	CPUINFO_MAX_FREQ
	setvar cpuinfo_min_freq	CPUINFO_MIN_FREQ
	setvar scaling_available_frequencies SLALLING_AVAILABLE_FREQUENCIES
	setvar scaling_available_governors SLALLING_AVAILABLE_GOVERNORS
	setvar scaling_cur_freq SLALLING_CUR_FREQ
	setvar scaling_driver SLALLING_DRIVER
	setvar scaling_governor SLALLING_GOVERNOR
	setvar scaling_max_freq SLALLING_MAX_FREQ
	setvar scaling_min_freq SCALING_MIN_FREQ
	setvar scaling_setspeed SCALING_SETSPEED
	if [[ -r ./stats/time_in_state ]]
	then
		pnum=`cat ./stats/time_in_state | wc -l`
	else
		pnum=
	fi
	echo "CPUFREQ_${ITEM_NO}_P_NUM = $pnum"
done

echo "CPUFREQ_NUM = $ITEM_NO"

exit 0
