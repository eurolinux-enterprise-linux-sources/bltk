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

export BLTK_WL_START_PROG=$0

wl_check_error()
{
	typeset ret=$1

	if [[ $ret != 0 ]]
	then
		shift 1
		for m in "$@"
		do
			wl_error_msg $m
		done
		cleanup $ret
		exit $ret
	fi
	return 0
}

wl_check_warning()
{
	typeset ret=$1

	if [[ $ret != 0 ]]
	then
		shift 1
		for m in "$@"
		do
			wl_warning_msg $m
		done
		return $ret
	fi
	return 0
}

wl_send_work_msg()
{
	[[ ! -z $BLTK_WORK_LOG_PROC ]] && kill -USR1 $BLTK_WORK_LOG_PROC
	return 0
}

wl_send_idle_msg()
{
	[[ ! -z $BLTK_WORK_LOG_PROC ]] && kill -USR2 $BLTK_WORK_LOG_PROC
	return 0
}

wl_get_dirpath()
{
	typeset	dir=$1
	typeset	cwd=$PWD
	typeset	res=

	cd $dir
	if [[ $? != 0 ]]
	then
		wl_error_msg "cd $dir failed"
		return 1
	fi
	res=$PWD
	cd $cwd
	if [[ $? != 0 ]]
	then
		wl_error_msg "cd $cwd failed"
		retirn 1
	fi
	echo $res
	return 0
}

cmd_startup()
{
	typeset d

	if [[ -z $BLTK_ROOT ]]
	then
		d=`dirname $BLTK_WL_START_PROG`/..
		BLTK_ROOT=`wl_get_dirpath $d`
		if [[ $? != 0 ]]
		then
			wl_error_msg "Cannot get pathname of $BLTK_WL_ROOT/.."
			return 1
		fi
	fi

	export BLTK_ROOT

	export BLTK_BIN=$BLTK_ROOT/bin
	export BLTK_LIB=$BLTK_ROOT/lib
	export BLTK_TMP=$BLTK_ROOT/tmp

	[[ -z $BLTK_SUDO_CMD ]] && export BLTK_SUDO_CMD=$BLTK_BIN/bltk_sudo
	[[ -z $BLTK_CALC_CMD ]] && export BLTK_CALC_CMD=$BLTK_BIN/bltk_calc
	[[ -z $BLTK_TIME_CMD ]] && export BLTK_TIME_CMD=$BLTK_BIN/bltk_time
	[[ -z $BLTK_TYPE_COMMAND_CMD ]] && export BLTK_TYPE_COMMAND_CMD=$BLTK_BIN/bltk_type_command
	[[ -z $BLTK_GET_REALPATH_CMD ]] && export BLTK_GET_REALPATH_CMD=$BLTK_BIN/bltk_get_realpath

	return 0
}

wl_startup()
{
	BLTK_WL_BIN=`dirname $BLTK_WL_START_PROG`
	if [[ $? != 0 ]]
	then
		wl_error_msg "Cannot get dirname of $BLTK_WL_START_PROG"
		return 1
	fi
	BLTK_WL_BIN=`wl_get_dirpath $BLTK_WL_BIN`
	if [[ $? != 0 ]]
	then
		wl_error_msg "Cannot get pathname of $BLTK_WL_BIN"
		return 1
	fi
	BLTK_WL_ROOT=`wl_get_dirpath $BLTK_WL_BIN/..`
	if [[ $? != 0 ]]
	then
		wl_error_msg "Cannot get pathname of $BLTK_WL_BIN/.."
		return 1
	fi
	if [[ -z $BLTK_ROOT ]]
	then
		BLTK_ROOT=`wl_get_dirpath $BLTK_WL_ROOT/..`
		if [[ $? != 0 ]]
		then
			wl_error_msg "Cannot get pathname of $BLTK_WL_ROOT/.."
			return 1
		fi
	fi

	export BLTK_WL_BIN
	export BLTK_WL_ROOT
	export BLTK_ROOT

	export BLTK_ROOT_FILE=$BLTK_ROOT/.bltk
	export BLTK_INSTALL_FILE=$BLTK_ROOT/.installed

	export BLTK_BIN=$BLTK_ROOT/bin
	export BLTK_LIB=$BLTK_ROOT/lib
	export BLTK_TMP=$BLTK_ROOT/tmp

	export BLTK_EXTERN_SRC=$BLTK_ROOT/extern
#	export BLTK_EXTERN_TGT=$BLTK_ROOT/extern
	export BLTK_EXTERN_TGT=$BLTK_TMP

	# wl_developer wl_game wl_office wl_player wl_reader

	export BLTK_EXTERN_SRC_WL_DEVELOPER=$BLTK_EXTERN_SRC	#/wl_developer
	export BLTK_EXTERN_TGT_WL_DEVELOPER=$BLTK_EXTERN_TGT	#/wl_developer
	export BLTK_TMP_WL_DEVELOPER=$BLTK_TMP			#/wl_developer

	export BLTK_EXTERN_SRC_WL_GAME=$BLTK_EXTERN_SRC		#/wl_game
	export BLTK_EXTERN_TGT_WL_GAME=$BLTK_EXTERN_TGT		#/wl_game
	export BLTK_TMP_WL_GAME=$BLTK_TMP			#/wl_game

	export BLTK_EXTERN_SRC_WL_OFFICE=$BLTK_EXTERN_SRC	#/wl_office
	export BLTK_EXTERN_TGT_WL_OFFICE=$BLTK_EXTERN_TGT	#/wl_office
	export BLTK_TMP_WL_OFFICE=$BLTK_TMP			#/wl_office

	export BLTK_EXTERN_SRC_WL_PLAYER=$BLTK_EXTERN_SRC	#/wl_player
	export BLTK_EXTERN_TGT_WL_PLAYER=$BLTK_EXTERN_TGT	#/wl_player
	export BLTK_TMP_WL_PLAYER=$BLTK_TMP			#/wl_player

	export BLTK_EXTERN_SRC_WL_READER=$BLTK_EXTERN_SRC	#/wl_reader
	export BLTK_EXTERN_TGT_WL_READER=$BLTK_EXTERN_TGT	#/wl_reader
	export BLTK_TMP_WL_READER=$BLTK_TMP			#/wl_reader

	export BLTK_WL_INSTALL_FILE=$BLTK_WL_ROOT/.installed

	[[ -z $BLTK_SUDO_CMD ]] && export BLTK_SUDO_CMD=$BLTK_BIN/bltk_sudo
	[[ -z $BLTK_CALC_CMD ]] && export BLTK_CALC_CMD=$BLTK_BIN/bltk_calc
	[[ -z $BLTK_TIME_CMD ]] && export BLTK_TIME_CMD=$BLTK_BIN/bltk_time
	[[ -z $BLTK_TYPE_COMMAND_CMD ]] && export BLTK_TYPE_COMMAND_CMD=$BLTK_BIN/bltk_type_command
	[[ -z $BLTK_GET_REALPATH_CMD ]] && export BLTK_GET_REALPATH_CMD=$BLTK_BIN/bltk_get_realpath

	[[ -z $BLTK_RESULTS ]] && export BLTK_RESULTS=$BLTK_WL_ROOT
	[[ -z $BLTK_FAIL_FNAME ]] && export BLTK_FAIL_FNAME=$BLTK_RESULTS/fail

	export LD_LIBRARY_PATH=$BLTK_LIB:$LD_LIBRARY_PATH
	export PATH=$BLTK_WL_BIN:$BLTK_BIN:$PATH

	cd $BLTK_WL_ROOT
	if [[ $? != 0 ]]
	then
		wl_error_msg "cd $BLTK_WL_ROOT failed"
		return 1
	fi
	rm -f fail

	RES_SCORE=$BLTK_RESULTS/score
	[[ -a $RES_SCORE ]] && rm $RES_SCORE
	return 0
}

wl_cleanup()
{
	typeset	pid n p ret

	ret=$1

	for n in $BLTK_WL_PROC_NAME
	do
		pid=`pgrep -x $n`
		if [[ ! -z "$pid" ]]
		then
			kill -9 $pid
		fi
	done
	for n in $BLTK_WL_ALL_PROC_NAME
	do
		pid=`pgrep $n`
		if [[ ! -z "$pid" ]]
		then
			kill -9 $pid
		fi
	done
	for p in $BLTK_WL_PID
	do
		kill -9 $p >/dev/null 2>&1
	done

	if [[ $1 != 0 ]]
	then
		[[ ! -z $BLTK_FAIL_FNAME ]] && touch $BLTK_FAIL_FNAME
	fi
	wait
	return $ret
}

wl_gen_score()
{
	typeset	cycle=$1
	typeset	base=$2
	typeset	calibr=$3
	typeset N=$4
	typeset time=$5
	typeset work=$6
	typeset delay=$7
	typeset response=$8
	typeset idle=$9
	typeset score=${10}

	if [[ $# != 10 ]]
	then
		wl_error_msg "Internal error: wl_gen_score - inavlid args number:"
		wl_error_msg "num: expected 10, actually $#"
		wl_error_msg "args: $*"
		return 1
	fi

	{
	if [[ $SCORE_TITLE != TRUE ]]
	then
		SCORE_TITLE=TRUE
		echo "cycle	$cycle"
		echo "base	$base"
		echo "calibr	$calibr"
		printf "T: %5s %10s %10s %10s %10s %10s %10s\n" \
			N time work delay response idle score
	fi
	printf "S: %5s %10s %10s %10s %10s %10s %10s\n" \
		"$N" "$time" "$work" "$delay" "$response" "$idle" "$score"
	} >>$RES_SCORE
	return 0
}

export BLTK_WL_START_TIME=$SECONDS
#export BLTK_WL_TIME=

wl_set_time()
{
	typeset tm=$1

	[[ -z $tm ]] && tm=$SECONDS
	BLTK_WL_START_TIME=$tm
}

wl_get_time()
{
	typeset tm

	(( tm = SECONDS - BLTK_WL_START_TIME ))
	echo $tm
}

wl_prt_time()
{
	typeset tm=$1
	typeset hh
	typeset mm
	typeset ss

	[[ -z $tm ]] && (( tm = SECONDS - BLTK_WL_START_TIME ))

	ss=`$BLTK_CALC_CMD "%i" $tm 60`
	mm=`$BLTK_CALC_CMD "/i" $tm 60`
	mm=`$BLTK_CALC_CMD "%i" $mm 60`
	hh=`$BLTK_CALC_CMD "/i" $tm 3600`
	printf "%02i:%02i:%02i" $hh $mm $ss
	return 0
}

wl_create_install()
{
	wl_remove_install
	[[ $? != 0 ]] && return 1
	touch $BLTK_WL_INSTALL_FILE
	if [[ $? != 0 ]]
	then
		wl_error_msg "Cannot create $BLTK_WL_ROOT/.installed file"
		return 1
	fi
	return 0
}

wl_remove_install()
{
	if [[ -a $BLTK_WL_INSTALL_FILE ]]
	then
		rm $BLTK_WL_INSTALL_FILE
		if [[ $? != 0 ]]
		then
			wl_error_msg "Cannot remove $BLTK_WL_ROOT/.installed file"
			return 1
		fi
	fi
	return 0
}

wl_check_install()
{
	typeset wl=$1

	if [[ ! -a $BLTK_WL_INSTALL_FILE ]]
	then
		wl_error_msg "Installation is not completed, perform 'make install-$wl'"
		return 1
	fi
	return 0
}

wl_error_msg()
{
	echo "ERROR: $*"
	return 0
}

wl_warning_msg()
{
	echo "Warning: $*"
	return 0
}

wl_display_on()
{
	if [[ $BLTK_DPMS = TRUE ]]
	then
		xset dpms 0 0 0 >/dev/null 2>&1
	fi
	return 0
}

wl_display_off()
{
	if [[ $BLTK_DPMS = TRUE ]]
	then
		xset dpms 0 0 10 >/dev/null 2>&1
	fi
	return 0
}

wl_check_prog()
{
	typeset	prog=$1
	typeset	cmd

	[[ -z $prog ]] && return 0

	cmd="type -p $prog"
	$cmd >/dev/null 2>&1
	if [[ $? != 0 ]]
	then
		wl_error_msg "$cmd failed"
		wl_error_msg "Cannot access $prog program"
		return 1
	fi
	return 0
}

wl_check_run_prog()
{
	typeset	prog=$1
	typeset	cmd

	[[ -z $prog ]] && return 0
	cmd="pgrep -x $prog"
	$cmd >/dev/null 2>&1
	if [[ $? = 0 ]]
	then
		wl_error_msg "$cmd passed"
		wl_error_msg "Program $prog is running already, close and repeat"
		return 1
	fi
	return 0
}

wl_check_all_run_prog()
{
	typeset	prog=$1
	typeset	cmd

	[[ -z $prog ]] && return 0
	cmd="pgrep $prog"
	$cmd >/dev/null 2>&1
	if [[ $? = 0 ]]
	then
		wl_error_msg "$cmd passed"
		wl_error_msg "Program $prog is running already, close and repeat"
		return 1
	fi
	return 0
}

wl_check_file()
{
	typeset	file=$1

	if [[ ! -f $file ]]
	then
		wl_error_msg "Cannot access $file"
		return 1
	fi
	return 0
}

wl_check_dir()
{
	typeset	dir=$1

	if [[ ! -d $dir ]]
	then
		wl_error_msg "Cannot access $dir"
		return 1
	fi
	return 0
}

wl_make_dir()
{
	typeset	dir=$1

	if [[ ! -d $dir ]]
	then
		CMD="mkdir -p $dir"
		$CMD
		if [[ $? != 0 ]]
		then
			wl_error_msg "$CMD failed"
			wl_error_msg "Cannot create $dir directory"
			return 1
		fi
	fi
	return 0
}

wl_change_dir()
{
	typeset	dir=$1

	CMD="cd $dir"
	$CMD
	if [[ $? != 0 ]]
	then
		wl_error_msg "$CMD failed"
		wl_error_msg "Cannot change current directory to $dir"
		return 1
	fi
	return 0
}

wl_remove_dir()
{
	typeset	dir=$1

	if [[ -a $dir ]]
	then
		CMD="rm -rf $dir"
		$CMD
		if [[ $? != 0 ]]
		then
			wl_error_msg "$CMD failed"
			wl_error_msg "Cannot remove $dir"
			return 1
		fi
	fi
	return 0
}

wl_remove_dir_su()
{
	typeset	dir=$1

	if [[ -a $dir ]]
	then
		CMD="$BLTK_SUDO_CMD rm -rf $dir"
		$CMD
		if [[ $? != 0 ]]
		then
			wl_error_msg "$CMD failed"
			wl_error_msg "Cannot remove $dir"
			return 1
		fi
	fi
#	CMD="rmdir -p `dirname $dir`"
#	$CMD >/dev/null 2>&1
#	return 0
	return 0
}

wl_move_dir()
{
	typeset	dir1=$1
	typeset	dir2=$2

	CMD="mv $dir1 $dir2"
	$CMD
	if [[ $? != 0 ]]
	then
		wl_error_msg "$CMD failed"
		wl_error_msg "Cannot move $dir1 into $dir2"
		return 1
	fi
	return 0
}

wl_remove_file()
{
	typeset	file=$1

	if [[ -a $file ]]
	then
		CMD="rm $file"
		$CMD
		if [[ $? != 0 ]]
		then
			wl_error_msg "$CMD failed"
			wl_error_msg "Cannot remove $file"
			return 1
		fi
	fi
	return 0
}

wl_copy_dir()
{
	typeset	dir1=$1
	typeset	dir2=$2

	CMD="cp -r $dir1 $dir2"
	$CMD
	if [[ $? != 0 ]]
	then
		wl_error_msg "$CMD failed"
		wl_error_msg "Cannot copy $dir1 to $dir2"
		return 1
	fi
	return 0
}

wl_copy_file()
{
	typeset	file1=$1
	typeset	file2=$2

	CMD="cp $file1 $file2"
	$CMD
	if [[ $? != 0 ]]
	then
		wl_error_msg "$CMD failed"
		wl_error_msg "Cannot copy $file1 to $file2"
		return 1
	fi
	return 0
}

