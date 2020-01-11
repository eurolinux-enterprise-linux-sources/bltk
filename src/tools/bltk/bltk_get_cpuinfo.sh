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

CPUINFO=$1

error()
{
	echo "$PROG: ERROR: $*" >&2
	exit 1
}

warning()
{
	echo "$PROG: Warning: $*" >&2
}

split()
{
	CNT=0
	while read line
	do
		[[ "$line" != *:* ]] && continue
		name=${line%%:*}
		value=${line#*:}
		name=`echo $name`
		value=`echo $value`
#		echo name=+"$name"+
#		echo value=+"$value"+
		NAME[$CNT]="$name"
		VALUE[$CNT]="$value"
		(( CNT++ ))
	done < $CPUINFO
}

split

cnt=0

cpu_no=0

CPU_TOTAL=0

while (( cnt < CNT ))
do
	if [[ ${NAME[$cnt]} = "processor" ]]
	then
		(( cpu_no++ ))
		(( CPU_TOTAL++ ))
		no=${VALUE[$cnt]}
		echo "CPUINFO_${cpu_no}_NO = $no"
	elif [[ ${NAME[$cnt]} = "model name" ]]
	then
		echo "CPUINFO_${cpu_no}_MODEL_NAME = ${VALUE[$cnt]}"
	elif [[ ${NAME[$cnt]} = "cache size" ]]
	then
		echo "CPUINFO_${cpu_no}_CACHE_SIZE = ${VALUE[$cnt]}"
	elif [[ ${NAME[$cnt]} = "stepping" ]]
	then
		echo "CPUINFO_${cpu_no}_STEPPING = ${VALUE[$cnt]}"
	elif [[ ${NAME[$cnt]} = "flags" ]]
	then
		echo "CPUINFO_${cpu_no}_FLAGS = ${VALUE[$cnt]}"
	elif [[ ${NAME[$cnt]} = "physical id" ]]
	then
		echo "CPUINFO_${cpu_no}_PHYSICAL_ID = ${VALUE[$cnt]}"
	elif [[ ${NAME[$cnt]} = "siblings" ]]
	then
		echo "CPUINFO_${cpu_no}_SIBLINGS = ${VALUE[$cnt]}"
		(( CPU_TOTAL += ${VALUE[$cnt]} - 1 ))
	fi
	(( cnt++ ))
done

echo "CPUINFO_NUM = $cpu_no"
###	echo "CPU_TOTAL = $CPU_TOTAL"
echo "CPU_TOTAL = $cpu_no"

exit 0

