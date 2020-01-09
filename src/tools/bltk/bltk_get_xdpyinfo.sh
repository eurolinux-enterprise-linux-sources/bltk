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

XDPYINFO=$1
TMP_FILE=$BLTK_ROOT/tmp/xdpyinfo

if [[ -z $XDPYINFO ]]
then
	rm -f $TMP_FILE
	xdpyinfo >$TMP_FILE 2>&1
	XDPYINFO=$TMP_FILE
fi

str=`cat $XDPYINFO | grep "dimensions:" | head -1`
str=${str#*dimensions:}
str=`echo $str`
echo "DISPLAY_DIMENSIONS = $str"
str1=${str%% *}
DISPLAY_X_SIZE=${str1%x*}
DISPLAY_Y_SIZE=${str1#*x}
echo "DISPLAY_X_SIZE = $DISPLAY_X_SIZE"
echo "DISPLAY_Y_SIZE = $DISPLAY_Y_SIZE"

str=`cat $XDPYINFO | grep "resolution:" | head -1`
str=${str#*resolution:}
str=`echo $str`
echo "DISPLAY_RESOLUTION = $str"

str=`cat $XDPYINFO | grep "depths" | head -1`
str=${str#*depths*:}
str=`echo $str`
echo "DISPLAY_DEPTHS = $str"
DISPLAY_DEPTH=${str%%,*}
echo "DISPLAY_DEPTH = $DISPLAY_DEPTH"

rm -f $TMP_FILE

exit 0
