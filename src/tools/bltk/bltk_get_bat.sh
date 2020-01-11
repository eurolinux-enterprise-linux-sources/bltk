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

ITEM_NO=0

BAT=$1

error()
{
	echo "$PROG: ERROR: $*" >&2
	exit 1
}

warning()
{
	echo "$PROG: Warning: $*" >&2
}

prt_var()
{
	typeset	name=$1
	typeset	varname=$2

	find_name "$name"
	if [[ ! -z "$VALUE2" && "$name" != "model number" ]]
	then
		echo "BAT_${ITEM_NO}_${varname} = $VALUE1"
		echo "BAT_${ITEM_NO}_${varname}_UNIT = $VALUE2"
	else
		echo "BAT_${ITEM_NO}_${varname} = $VALUE"
	fi
}

split()
{
	typeset	file=$1
	typeset	name
	typeset	value
	typeset	value1
	typeset	value2

	cat $file > /tmp/$file

	CNT=0
	while read line
	do
		[[ "$line" != *:* ]] && continue
		name=${line%%:*}
		value=${line#*:}
		name=`echo $name`
		value=`echo $value`
		NAMES[$CNT]="$name"
		VALUES[$CNT]="$value"
		if [[ "$value" == *" "* ]]
		then
			value1=${value%% *}
			value2=${value#* }
		else
			value1="$value"
			value2=
		fi
		VALUES1[$CNT]="$value1"
		VALUES2[$CNT]="$value2"
		(( CNT++ ))
	done </tmp/$file
}

find_name()
{
	typeset	name=$1
	typeset	cnt

	VALUE=
	VALUE1=
	VALUE2=
	cnt=0
	while (( cnt < CNT ))
	do
		if [[ ${NAMES[$cnt]} = "$name" ]]
		then
			VALUE=${VALUES[$cnt]}
			VALUE1=${VALUES1[$cnt]}
			VALUE2=${VALUES2[$cnt]}
			break
		fi
		(( cnt++ ))
	done
}

[[ ! -d $BAT ]] && exit

dlist=`ls $BAT`

CWD=$PWD

XNO=0

for d in $dlist
do
	cd $CWD
	D="$BAT/$d"
	[[ ! -d $D ]] && continue
	if [[ $d != BAT* ]]
	then
		NO=$XNO
		(( XNO++ ))
	else
		NO=${d#BAT}
		if [[ -z "$NO" ]]
		then
			NO=$XNO
			(( XNO++ ))
		fi
	fi
	cd $D
	[[ $? != 0 ]] && warning "Cannot change dir to $D"
	[[ ! -r state ]] && continue
	split state
	find_name present
	[[ "$VALUE" != yes ]] && continue
	(( ITEM_NO++ ))
	echo "BAT_${ITEM_NO}_PATH = $D"
	echo "BAT_${ITEM_NO}_NO = $NO"
	prt_var present PRESENT
	prt_var "capacity state" CAPACITY_STATE
	prt_var "charging state" CHARGING_STATE
	prt_var "present rate" PRESENT_RATE
	prt_var "remaining capacity" REMAINING_CAPACITY
	prt_var "present voltage" PRESENT_VOLTAGE

	split alarm
	prt_var alarm ALARM

	split info
	prt_var "design capacity" DESIGN_CAPACITY
	prt_var "last full capacity" LAST_FULL_CAPACITY
	prt_var "battery technology" BAT_TECHNOLOGY
	prt_var "design voltage" DESIGN_VOLTAGE
	prt_var "design capacity warning" DESIGN_CAPACITY_WARNING
	prt_var "design capacity low" DESIGN_CAPACITY_LOW
	prt_var "capacity granularity 1" CAPACITY_GRANULARITY_1
	prt_var "capacity granularity 2" CAPACITY_GRANULARITY_2
	prt_var "model number" MODEL_NUMBER
	prt_var "serial number" SERIAL_NUMBER
	prt_var "battery type" BAT_TYPE
	prt_var "OEM info" OEM_INFO

done

echo "BAT_NUM = $ITEM_NO"

exit 0
