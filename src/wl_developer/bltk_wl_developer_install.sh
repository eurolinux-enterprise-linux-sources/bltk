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

source `dirname $0`/../../bin/bltk_wl_common
[[ $? != 0 ]] && { echo "bltk tree corrupted"; exit 2; }


startup()
{
	trap 'cleanup 1; exit 1' 1 2 3 15

	wl_startup
	wl_check_error $?

	source $BLTK_WL_ROOT/extern.cfg

	export LINUX_SRC_FILE=$BLTK_EXTERN_SRC_WL_DEVELOPER/linux-$LINUX_VER.tar.bz2
	export LINUX_TGT_PARENT_DIR=$BLTK_EXTERN_TGT_WL_DEVELOPER
	export LINUX_TGT_DIR=$LINUX_TGT_PARENT_DIR/linux-$LINUX_VER
	export LINUX_CONFIG_TGT=$LINUX_TGT_DIR/.config
}

cleanup()
{
	typeset	status=$1

	wl_cleanup $status

	if [[ $? != 0 ]]
	then
		wl_error_msg "=== Workload 'developer' failed, time `wl_prt_time`"
		exit 1
	else
		echo "=== Workload 'developer' passed, time `wl_prt_time`"
		exit 0
	fi
}

install()
{
	wl_remove_install
	wl_check_error $?

	wl_check_file $LINUX_SRC_FILE
	wl_check_error $?

	wl_remove_dir $LINUX_TGT_DIR
	wl_check_error $?

	wl_make_dir $LINUX_TGT_PARENT_DIR
	wl_check_error $?

	wl_change_dir $LINUX_TGT_PARENT_DIR
	wl_check_error $?

	CMD="tar -jxf $LINUX_SRC_FILE"
	$CMD
	wl_check_error $? "$CMD failed" "Cannot extract $LINUX_SRC_FILE"

	wl_check_dir $LINUX_TGT_DIR
	wl_check_error $?

	wl_change_dir $LINUX_TGT_DIR
	wl_check_error $?

	sed -i "s/-ffreestanding/-ffreestanding -fno-stack-protector/g" Makefile
	wl_check_error $? "$CMD failed"

	CMD="make clean"
	$CMD
	wl_check_error $? "$CMD failed"

	CMD="make defconfig"
	$CMD
	wl_check_error $? "$CMD failed"

###	CMD="make -j 3"
###	$CMD
###	wl_check_error $? "$CMD failed"

	wl_create_install
	wl_check_error $?
}

uninstall()
{
	wl_remove_install
	wl_check_error $?

	wl_remove_dir $LINUX_TGT_DIR
	wl_check_error $?
}

if [[ $# = 0 || $1 = i || $1 = install ]]
then
	work=install
elif [[ $1 = u || $1 = uninstall ]]
then
	work=uninstall
else
	echo "Invalid parameter"
	exit 1
fi

{
startup
$work
cleanup 0
}  2>&1 | tee -i $work.log

