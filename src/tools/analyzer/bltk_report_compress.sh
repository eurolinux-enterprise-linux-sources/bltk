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
	export BLTK_GET_REALPATH=$BLTK_BIN/bltk_get_realpath
}

set_bltk_root

CWD=$PWD

error()
{
	echo cwd=$PWD >&2
	echo "ERROR: $*" >&2
	exit 1
}

warning()
{
	echo cwd=$PWD >&2
	echo "Warning: $*" >&2
}

debug()
{
	echo cwd=$PWD >&2
	[[ $debug_flg != TRUE ]] && return
	echo "debug: $results: $*" >&2
}

debug2()
{
	echo cwd=$PWD >&2
	echo "debug2: $results: $*" >&2
}

OPTIONS="h"

usage()
{
	echo "Usage: $PROG [-$OPTIONS] src_dir tgt_dir" >&2
}

common_usage()
{
	cat >&2 << EOF

Usage:	$PROG [-$OPTIONS] src_dir tgt_dir

	-h		usage
	src_dir		source directory
	tgt_dir		target directory

Example:
	$PROG src_dir tgt_dir
EOF
}

compress()
{
	while getopts $OPTIONS OPT
	do
		case $OPT in
			h ) common_usage; exit 0;;
			* ) usage; exit 2;;
		esac
	done

	shift $((OPTIND-1))

	if [[ $# != 2 ]]
	then
		usage; exit 2
	fi

	SRC_DIR=$1
	TGT_DIR=$2

	[[ ! -a $SRC_DIR ]] && error "Cannot access $SRC_DIR"

	if [[ -d $SRC_DIR ]]
	then
		CMD="cd $SRC_DIR"
		$CMD
		[[ $? != 0 ]] && error "$CMD failed"
		RESULTS=`find -name info.log -type f | sort`
		[[ $? != 0 ]] && error "find -name info.log -type f | sort failed"
		cd $CWD
		SRC_DIR_PATH=`$BLTK_GET_REALPATH $SRC_DIR`
	else
		error "Cannot access $SRC_DIR"
	fi
	XRESULTS=
	for r in $RESULTS
	do
		xr=`dirname $r`
		xr=`dirname $xr`
		xr=${xr#./}
		XRESULTS="$XRESULTS $xr"
	done
	RESULTS="$XRESULTS"
	RESULTS=`
	for r in $RESULTS
	do
		echo $r
	done | sort | uniq`

	if [[ -a $TGT_DIR ]]
	then
		[[ ! -d $TGT_DIR ]] && error "$TGT_DIR is not a directory"
		CMD="rmdir $TGT_DIR"
		$CMD
		[[ $? != 0 ]] && error "$CMD failed"
	fi

	CMD="mkdir -p -m 0777 $TGT_DIR"
	$CMD
	[[ $? != 0 ]] && error "$CMD failed"
	TGT_DIR_PATH=`$BLTK_GET_REALPATH $TGT_DIR`

	for results in $RESULTS
	do
		CMD="cd $SRC_DIR_PATH/$results"
		$CMD
		[[ $? != 0 ]] && error "$CMD failed"
		dir=`dirname $results`
		file=`basename $results`
		if [[ $dir != . ]]
		then
			CMD="mkdir -p -m 0777 $TGT_DIR_PATH/$dir"
			$CMD
			[[ $? != 0 ]] && error "$CMD failed"
		fi
		CMD="tar -jpcf $TGT_DIR_PATH/$results.tar.bz2 ."
		echo "Create $TGT_DIR_PATH/$results.tar.bz2"
		$CMD
		[[ $? != 0 ]] && error "$CMD failed"
	done
}

compress "$@"
