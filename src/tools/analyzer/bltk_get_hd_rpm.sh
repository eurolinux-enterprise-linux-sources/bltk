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

model="$*"

set_bltk_root()
{
	PROG=`basename $0`

	BLTK_ROOT=`dirname $0`
	if [[ ! -a $BLTK_ROOT/.bltk ]]
	then
		BLTK_ROOT=`dirname $BLTK_ROOT`
		if [[ ! -a $BLTK_ROOT/.bltk ]]
		then
			echo "Cannot determine bltk root, bltk tree corrupted."
			exit 2
		fi
	fi
	export BLTK_ROOT
	export BLTK_BIN=$BLTK_ROOT/bin
	export BLTK_TMP=$BLTK_ROOT/tmp
}

set_bltk_root

RPM_FILE=$BLTK_ROOT/data/hd_rpm.data

MODEL=
RPM=

while read line
do
	MODEL=${line%%	*}
	RPM=${line##*	}
	if [[ "$model" = "$MODEL" ]]
	then
		echo "$RPM"
		exit
	fi
done < $RPM_FILE
exit
