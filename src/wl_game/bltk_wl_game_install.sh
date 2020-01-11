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
set -x 
startup()
{
	trap 'cleanup 1; exit 1' 1 2 3 15

	wl_startup
	wl_check_error $?

        export GAME_SRC_FILE=$BLTK_EXTERN_SRC_WL_GAME/openarena.tar.bz2
        export GAME_SRC_TMP_PARENT_DIR=$BLTK_TMP_WL_GAME
        export GAME_SRC_TMP_DIR=$GAME_SRC_TMP_PARENT_DIR/openarena

        export GAME_BIN_PACKAGE=$BLTK_EXTERN_SRC_WL_GAME/oa070.zip
        export GAME_TGT_BIN_PARENT_DIR=$BLTK_EXTERN_TGT_WL_GAME/openarena-0.7.0
	if [[ `uname -m` == x86_64 ]]
	then 
	        export GAME_TGT_BIN_FILE=$GAME_TGT_BIN_PARENT_DIR/ioquake3-smp.x86_64
	else 
	        export GAME_TGT_BIN_FILE=$GAME_TGT_BIN_PARENT_DIR/ioquake3-smp.i386
	fi
        export GAME_TGT_CONFIG_DIR=$GAME_TGT_BIN_PARENT_DIR/baseoa


#	export GAME_TGT_INSTALL_XSE_PROG=$BLTK_WL_BIN/bltk_wl_game_xse
}

cleanup()
{
	typeset	status=$1

	wl_cleanup $status

	if [[ $? != 0 ]]
	then
		wl_error_msg "=== Workload 'game' failed, time `wl_prt_time`"
		exit 1
	else
		echo "=== Workload 'game' passed, time `wl_prt_time`"
		exit 0
	fi
}
make_game_src()
{
        

        wl_check_file $GAME_SRC_FILE
        wl_check_warning $?
        [[ $? != 0 ]] && return 1

        wl_make_dir $GAME_SRC_TMP_PARENT_DIR
        wl_check_error $?

        wl_change_dir $GAME_SRC_TMP_PARENT_DIR
        wl_check_error $?

        CMD="tar -jxf $GAME_SRC_FILE "
        $CMD
        wl_check_error $? "$CMD failed" "Cannot extract $GAME_SRC_FILE"

        wl_check_dir $GAME_SRC_TMP_DIR
        wl_check_error $?

        wl_change_dir $GAME_SRC_TMP_DIR
        wl_check_error $?


        CMD="make -j3"
        $CMD
        wl_check_warning $? "$CMD failed"
        [[ $? != 0 ]] && return 1

        return 0
}
make_game_zip(){

        wl_check_file $GAME_BIN_PACKAGE
        wl_check_warning $?
        [[ $? != 0 ]] && return 1

        wl_make_dir $BLTK_EXTERN_TGT_WL_GAME
        wl_check_error $?

        wl_change_dir $BLTK_EXTERN_TGT_WL_GAME
        wl_check_error $?

	CMD="unzip $GAME_BIN_PACKAGE"
        $CMD
        wl_check_error $? "$CMD failed" "Cannot extract $GAME_BIN_PACKAGE"
	
        return 0

}

install()
{
	uninstall	
	wl_check_error $?

#        make_game_src
        make_game_zip
        wl_check_error $?

	wl_create_install
	wl_check_error $?

#	wl_remove_file $GAME_INSTALL_PROG
#	wl_check_error $?
}

uninstall()
{
	wl_remove_install
	wl_check_error $?

	wl_remove_dir $GAME_TGT_BIN_PARENT_DIR
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

