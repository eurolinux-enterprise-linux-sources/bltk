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


PLAYER_INSTALL_FLAGS=" --disable-ivtv"

source `dirname $0`/../../bin/bltk_wl_common
[[ $? != 0 ]] && { echo "bltk tree corrupted"; exit 2; }

startup()
{
	trap 'cleanup 1; exit 1' 1 2 3 15

	wl_startup
	wl_check_error $?

	source $BLTK_WL_ROOT/extern.cfg

	if [[ -z $PLAYER ]]
	then
		wl_error_msg "=== PLAYER not set (see wl_player/extern.cfg)"
		exit 1
	fi

	export PLAYER_SRC_FILE=$BLTK_EXTERN_SRC_WL_PLAYER/$PLAYER.tar.bz2
	export PLAYER_SRC_TMP_PARENT_DIR=$BLTK_TMP_WL_PLAYER
	export PLAYER_SRC_TMP_DIR=$PLAYER_SRC_TMP_PARENT_DIR/$PLAYER
	export PLAYER_INSTALL_DIR=$BLTK_EXTERN_TGT_WL_PLAYER/mplayer

	export PLAYER_SRC_BIN_FILE=$BLTK_EXTERN_SRC_WL_PLAYER/mplayer.tar.bz2
	export PLAYER_TGT_BIN_PARENT_DIR=$BLTK_EXTERN_TGT_WL_PLAYER
	export PLAYER_TGT_BIN_FILE=$BLTK_EXTERN_TGT_WL_PLAYER/mplayer/bin/mplayer
	export PLAYER_TGT_BIN_DIR=$BLTK_EXTERN_TGT_WL_PLAYER/mplayer/bin
	export PLAYER_TGT_BIN_FILE=$PLAYER_TGT_BIN_DIR/mplayer
}

cleanup()
{
	typeset	status=$1

	wl_cleanup $status

	if [[ $? != 0 ]]
	then
		wl_error_msg "=== Workload 'player' failed, time `wl_prt_time`"
		exit 1
	else
		echo "=== Workload 'player' passed, time `wl_prt_time`"
		exit 0
	fi
}

all_remove()
{
	wl_remove_dir $PLAYER_SRC_TMP_DIR
	wl_check_error $?

	wl_remove_dir $PLAYER_INSTALL_DIR
	wl_check_error $?
}

make_mplayer_src()
{
	all_remove

	wl_check_file $PLAYER_SRC_FILE
	wl_check_warning $?
	[[ $? != 0 ]] && return 1

	wl_make_dir $PLAYER_SRC_TMP_PARENT_DIR
	wl_check_error $?

	wl_change_dir $PLAYER_SRC_TMP_PARENT_DIR
	wl_check_error $?

	CMD="tar -jxf $PLAYER_SRC_FILE"
	$CMD
	wl_check_error $? "$CMD failed" "Cannot extract $PLAYER_SRC_FILE"

	wl_check_dir $PLAYER_SRC_TMP_DIR
	wl_check_error $?

	wl_change_dir $PLAYER_SRC_TMP_DIR
	wl_check_error $?

	CMD="./configure --prefix=$PLAYER_INSTALL_DIR $PLAYER_INSTALL_FLAGS"
	$CMD
	wl_check_warning $? "$CMD failed"
	[[ $? != 0 ]] && return 1

	CMD="make"
	$CMD
	wl_check_warning $? "$CMD failed"
	[[ $? != 0 ]] && return 1

	CMD="make install"
	$CMD
	wl_check_warning $? "$CMD failed"
	[[ $? != 0 ]] && return 1
	return 0
}

make_mplayer_bin()
{
	all_remove

	wl_check_file $PLAYER_SRC_BIN_FILE
	wl_check_error $?

	wl_make_dir $PLAYER_TGT_BIN_PARENT_DIR
	wl_check_error $?

	wl_change_dir $PLAYER_TGT_BIN_PARENT_DIR
	wl_check_error $?

	CMD="tar -jxf $PLAYER_SRC_BIN_FILE"
	$CMD
	wl_check_error $? "$CMD failed" "Cannot extract $PLAYER_SRC_BIN_FILE"

	wl_check_file $PLAYER_TGT_BIN_FILE
	wl_check_error $?

	$PLAYER_TGT_BIN_FILE --help >/dev/null 2>&1
	if [[ $? != 0 ]]
	then
		$PLAYER_TGT_BIN_FILE --help
		wl_warning_msg "Cannot run mplayer binary on your system"
		return 1
	fi
	return 0
}

make_mplayer_loc()
{
	all_remove

	wl_check_prog mplayer
	wl_check_error $? "Cannot find mplayer on your system"

	mplayer_path=`type -p mplayer`
	if [[ $? != 0 || -z $mplayer_path ]]
	then
		wl_check_error 1 "Cannot determine mplayer path"
	fi

	wl_make_dir $PLAYER_TGT_BIN_PARENT_DIR
	wl_check_error $?

	wl_make_dir $PLAYER_TGT_BIN_DIR
	wl_check_error $?

	ln -s $mplayer_path $PLAYER_TGT_BIN_FILE
	wl_check_error $?

#	wl_remove_dir $PLAYER_TGT_BIN_PARENT_DIR
#	wl_check_error $?
}

make_mplayer()
{
	make_mplayer_src
	if [[ $? != 0 ]]
	then
		wl_warning_msg "Cannot build mplayer on your system," \
				"trying use binary"
		make_mplayer_bin
		if [[ $? != 0 ]]
		then
			wl_warning_msg "Cannot run mplayer binary on your system," \
				"trying use local mplayer"
			make_mplayer_loc
			wl_check_error $?
		fi
		echo "Passed"
	fi
}

install()
{
	wl_remove_install
	wl_check_error $?

	if [[ $work_type = src ]]
	then
		make_mplayer_src
		wl_check_error $?
	elif [[ $work_type = bin ]]
	then
		make_mplayer_bin
		wl_check_error $?
	elif [[ $work_type = loc ]]
	then
		make_mplayer_loc
		wl_check_error $?
	elif [[ -z $work_type ]]
	then
		make_mplayer
		wl_check_error $?
	else
		usage
		exit 1
	fi

	wl_remove_dir $PLAYER_SRC_TMP_DIR
	wl_check_error $?

	wl_create_install
	wl_check_error $?
}

uninstall()
{
	wl_remove_install
	wl_check_error $?

	wl_remove_dir $PLAYER_SRC_TMP_DIR
	wl_check_error $?

	wl_remove_dir $PLAYER_INSTALL_DIR
	wl_check_error $?
}

usage()
{
	echo "Usage: $0 install [src|bin|loc] | uninstall"
}

if [[ $1 = install ]]
then
	work=install
	work_type=
elif [[ $1 = install-src ]]
then
	work=install
	work_type=src
elif [[ $1 = install-bin ]]
then
	work=install
	work_type=bin
elif [[ $1 = install-loc ]]
then
	work=install
	work_type=loc
elif [[ $1 = uninstall ]]
then
	work=uninstall
else
	usage
	exit 1
fi

{

#If there is a ENV variable named CFLAGS, the CFLAGS value in wl_player/Makefile
#will be set to this ENV variable. Since the MPlayer will inherit the ENV CFLAGS
#value, the compiling will failed for "-pedantic -std=c99" in CFLAGS. So we need
#to unset the variable here.

CFLAGS=
LDFLAGS=
startup
$work
cleanup 0
}  2>&1 | tee -i $work.log

