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

MEMINFO=$1

error()
{
	echo "ERROR $*" >&2
	exit 1
}

warning()
{
	echo "Warning: $*" >&2
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
	done < $MEMINFO
}

split

cnt=0

while (( cnt < CNT ))
do
	if [[ ${NAME[$cnt]} = "MemTotal" ]]
	then
		echo "MEMORY_SIZE = ${VALUE[$cnt]}"
	elif [[ ${NAME[$cnt]} = "SwapTotal" ]]
	then
		echo "SWAP_SIZE = ${VALUE[$cnt]}"
	fi
	(( cnt++ ))
done

exit 0
