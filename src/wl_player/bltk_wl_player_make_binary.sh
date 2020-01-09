#!/bin/bash

source `dirname $0`/../../bin/bltk_wl_common
[[ $? != 0 ]] && { echo "bltk tree corrupted"; exit 2; }

PLAYER=MPlayer-1.0pre7try2

PLAYER_INSTALL_FLAGS=" \
	--disable-fbdev --disable-directfb \
	--disable-lirc --disable-libdv --disable-termcap \
	--disable-mad --disable-liblzo --disable-libavcodec --disable-aa \
	"

PLAYER_INSTALL_FLAGS=" \
	--disable-fbdev --disable-directfb \
	--disable-lirc --disable-libdv --disable-termcap \
	--disable-mad --disable-liblzo --disable-aa \
	"

startup()
{
	trap 'cleanup 1; exit 1' 1 2 3 15

	wl_startup
	wl_check_error $?

	export PLAYER_SRC_FILE=$BLTK_EXTERN_SRC_WL_PLAYER/$PLAYER.tar.bz2
	export PLAYER_SRC_TMP_PARENT_DIR=$BLTK_TMP_WL_PLAYER
	export PLAYER_SRC_TMP_DIR=$PLAYER_SRC_TMP_PARENT_DIR/$PLAYER
	export PLAYER_INSTALL_DIR=$BLTK_EXTERN_TGT_WL_PLAYER/mplayer

	export PLAYER_SRC_BIN_FILE=$BLTK_WL_ROOT/mplayer.tar.bz2
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

	wl_remove_file $PLAYER_SRC_BIN_FILE
	wl_check_error $?
}

make_mplayer_bin()
{
	all_remove

	wl_check_file $PLAYER_SRC_FILE
	wl_check_error $?

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
	wl_check_error $? "$CMD failed"

	CMD="make"
	$CMD
	wl_check_error $? "$CMD failed"

	CMD="make install"
	$CMD
	wl_check_error $? "$CMD failed"

	wl_change_dir $BLTK_EXTERN_TGT_WL_PLAYER
	wl_check_error $?

	CMD="tar -jpcf $PLAYER_SRC_BIN_FILE mplayer"
	$CMD
	wl_check_error $? "$CMD failed"
	return 0
}

{
startup
make_mplayer_bin
cleanup 0
}

