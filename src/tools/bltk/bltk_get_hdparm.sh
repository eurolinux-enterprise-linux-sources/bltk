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

PARTITIONS=$1

TMP_FILE=$BLTK_ROOT/tmp/hdparm

#str=`df -lk / | grep -v ^Filesystem`
str=`df -lk / | grep ^/dev/`
DF_DEV_NAME=${str%% *}
if [  -L $DF_DEV_NAME ];then 
	realname="`readlink $DF_DEV_NAME`"
	DF_NAME="`basename ${realname}`"
	HD_NAME=${DF_NAME}
	DISK_CK_TOOL="lvdisplay -a"
	HD_DEV_NAME=$DF_DEV_NAME
else 
	DF_NAME=${DF_DEV_NAME#/dev/}
	HD_NAME=${DF_NAME%%[0-9]*}
	DISK_CK_TOOL="hdparm -iI"
	HD_DEV_NAME=/dev/$HD_NAME
fi

grep -w "$HD_NAME" "$PARTITIONS" >/dev/null 2>&1
if [[ $? != 0 ]]
then
	warning "Cannot determine hard disk $HD_NAME statistics"
fi

echo "DF_NAME = $DF_NAME"
echo "DF_DEV_NAME = $DF_DEV_NAME"
echo "HD_NAME = $HD_NAME"
echo "HD_DEV_NAME = $HD_DEV_NAME"

rm -f $TMP_FILE
BLTK_SUDO_CMD=sudo
$BLTK_SUDO_CMD $DISK_CK_TOOL "$HD_DEV_NAME" >$TMP_FILE 2>&1
if [  -L $DF_DEV_NAME ];then 
	echo "HD_MODEL = Logical volume"

	str=`grep 'LV Size' $TMP_FILE`
	str=${str#*LV Size*}
	str=`echo $str`
	echo "HD_SIZE = $str"
else 
	
	str=`grep '^ Model=' $TMP_FILE`
	str=${str# Model=}
	str=${str%%, *}
	if [[ -z "$str" ]]
	then
		str=`grep '^	Model Number:' $TMP_FILE`
		str=${str#*Model Number:}
		str=`echo $str`
	fi
	echo "HD_MODEL = $str"
	
	str=`grep 'device size with M = 1000' $TMP_FILE`
	str=${str#*device size with M = 1000*:}
	str=`echo $str`
	echo "HD_SIZE = $str"
fi

rm -f $TMP_FILE

exit 0
