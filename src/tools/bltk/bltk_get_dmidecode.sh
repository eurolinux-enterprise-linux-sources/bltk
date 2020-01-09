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

error()
{
	echo "$PROG: ERROR: $*" >&2
	exit 1
}

warning()
{
	echo "$PROG: Warning: $*" >&2
}

OPTIONS="hmp"

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
			m ) manufacturer_flg=TRUE;;
			p ) product_name_flg=TRUE;;
			* ) usage; exit 2;;
		esac
	done

	shift $((OPTIND-1))

	DMIDECODE=$*
	TMP_FILE=$BLTK_ROOT/tmp/dmidecode

	if [[ -z $DMIDECODE ]]
	then
		type -p dmidecode >/dev/null 2>&1
		if [[ $? = 0 ]]
		then
			rm -f $TMP_FILE
			$BLTK_SUDO_CMD dmidecode >$TMP_FILE
			DMIDECODE=$TMP_FILE
		else
			if [[ $manufacturer_flg = TRUE ]]
			then
				:
			elif [[ $product_name_flg = TRUE ]]
			then
				:
			else
				echo "MANUFACTURER ="
				echo "PRODUCT_NAME ="
			fi
			exit 1
		fi
	fi

	MANUFACTURER=
	PRODUCT_NAME=
}

command_line "$@"

while read line
do
	if [[ "$line" == *"System Information"* ]]
	then
		read line_m
		read line_p
		break
	fi
done < $DMIDECODE


if [[ ! -z "$line_m" ]]
then
	if [[ "$line_m" == *"Manufacturer: "* ]]
	then
		MANUFACTURER=${line_m#Manufacturer: }
	fi
fi

if [[ ! -z "$line_p" ]]
then
	if [[ "$line_p" == *"Product Name: "* ]]
	then
		PRODUCT_NAME=${line_p#Product Name: }
	fi
fi

if [[ $manufacturer_flg = TRUE ]]
then
	echo "$MANUFACTURER"
elif [[ $product_name_flg = TRUE ]]
then
	echo "$PRODUCT_NAME"
else
	echo "MANUFACTURER = $MANUFACTURER"
	echo "PRODUCT_NAME = $PRODUCT_NAME"
fi

rm -f $TMP_FILE

exit 0
