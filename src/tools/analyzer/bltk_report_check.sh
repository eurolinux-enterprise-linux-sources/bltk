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
}

set_bltk_root

Failed="Failed !!!"

ERR_IGN=

REPORT_NAME=Report.check

error_msg()
{
	if [[ -z $ERR_IGN ]]
	then
		echo "ERROR: $*" >&2
	else
		echo "ERROR ignored: $*" >&2
	fi
}

error()
{
	if [[ ! -z $results ]]
	then
		error_msg "Result directory is $results"
	fi
	if [[ -z $ERR_IGN ]]
	then
		echo "ERROR: $*" >&2
		exit 1
	else
		echo "ERROR ignored: $*" >&2
	fi
	debug "${FUNCNAME[*]}"
	debug "${BASH_LINENO[*]}"
}

warning_msg()
{
	echo "Warning: $*" >&2
}

warning()
{
	if [[ ! -z $results ]]
	then
		warning_msg "Result directory is $results" >&2
	fi
	echo "Warning: $*" >&2
}

debug()
{
	[[ $debug_flg != TRUE ]] && return
	echo "debug: $results: $*" >&2
}

debug2()
{
	echo "debug2: $results: $*" >&2
}

OPTIONS="h"

usage()
{
	echo "Usage: $PROG [-$OPTIONS] directory" ... >&2
}

sort_flg=FALSE
uniq_flg=FALSE
table_flg=TRUE

common_usage()
{
	cat >&2 << EOF

Usage:	$PROG [-$OPTIONS] directory ...

	-h		usage
	directory ...	results directories list

Example:
	bltk_report_check <results1> ... <resultsn>
EOF
}

make()
{
	while getopts $OPTIONS OPT
	do
		case $OPT in
			h ) common_usage; exit 0;;
			s ) sort_flg=TRUE;;
			t ) table_flg=FALSE;;
			u ) uniq_flg=TRUE;;
			E ) ERR_IGN="-E";;
			e ) ERR_SKIP=TRUE; ERR_IGN="-E";;
			F ) FILTER="$OPTARG";;
			n ) check_fname=TRUE;;
			* ) usage; exit 2;;
		esac
	done

	shift $((OPTIND-1))

	RESULTS_NUM="$#"
	RESULTS="$*"

	if [[ $RESULTS_NUM = 0 ]]
	then
		RESULTS_NUM=1
		RESULTS=.
	fi

	RESULTS=`find $RESULTS -type d`
	XRESULTS=

	RESULTS_NUM=0
	for results in $RESULTS
	do
		if [[ ! -a $results/info.log ]]
		then
			continue
		fi
		XRESULTS="$XRESULTS $results"
		(( RESULTS_NUM++ ))
	done

	results=

	RESULTS=$XRESULTS

	if [[ -z $RESULTS ]]
	then
		warning "Results list is empty"
		exit
	fi
	set $RESULTS
	BASE=$1

	i=0
	for results1 in $RESULTS
	do
		MRESULTS[i]=$results1
		(( i++ ))
	done
	i=0
	if [[ $check_fname = TRUE ]]
	then
		while :
		do
			results1=${MRESULTS[i]}
			[[ -z $results1 ]] && break
			bn1=`basename $results1`
			(( j = i + 1 ))
			while :
			do
				results2=${MRESULTS[j]}
				[[ -z $results2 ]] && break
				bn2=`basename $results2`
				if [[ $bn1 == $bn2 ]]
				then
   					warning "Name duplicated: $results1 and $results2"
				fi
				(( j++ ))
			done
			(( i++ ))
		done
	fi
	i=0
	while :
	do
		results1=${MRESULTS[i]}
		[[ -z $results1 ]] && break
		(( j = i + 1 ))
		while :
		do
			results2=${MRESULTS[j]}
			[[ -z $results2 ]] && break
			diff $results1/info.log $results2/info.log >/dev/null 2>&1
			status1=$?
			if [[ $status1 = 0 ]]
			then
				diff $results1/stat.log $results2/stat.log >/dev/null 2>&1
				status2=$?
				if [[ $status2 = 0 ]]
				then
   					warning "Possible results duplicated: $results1 and $results2"
				fi
			fi
			(( j++ ))
		done
		(( i++ ))
	done

	for results in $RESULTS
	do
		res=Passed
		if [[ -a $results/fail ]]
		then
			res=$Failed
		fi
		if [[ -a $results/err.log ]]
		then
			res=$Failed
		fi
		if [[ ! -r $results/info.log ]]
		then
			res=$Failed
		fi
		if [[ ! -r $results/info1.log ]]
		then
			res=$Failed
		fi
		if [[ ! -r $results/info2.log ]]
		then
			res=$Failed
		fi
		if [[ ! -r $results/stat.log ]]
		then
			res=$Failed
		fi
		{
			echo "       Source : $results"
			echo "  Test Result : $res"
		} >"$results/$REPORT_NAME"
	done
	results=
}

make_report_line()
{
	typeset	results=$1
	typeset	calcsize=$2
	typeset	first_report=$3
	typeset	names=
	typeset	values=

	if [[ ! -r $results/$REPORT_NAME ]]
	then
		error "Cannot access $results/$REPORT_NAME"
	fi
	first=TRUE
	(( cnt = -1 ))
	while read line
	do
		[[ "$line" != *" :"* ]] && continue
		[[ "$line" == "#"* ]] && continue
		(( cnt += 1 ))
		name=${line%% :*}
		if [[ -z "$name" ]]
		then
			name="?"
		fi
		value=${line#* : }
		if [[ "$value" = "$line" ]]
		then
			value=${line#* :}
		fi
		if [[ -z "$value" ]]
		then
			value="-"
		fi
		if [[ $calcsize = TRUE ]]
		then
			namesize=${#name}
			valuesize=${#value}
			max $valuesize $namesize ${SIZE[cnt]}
			SIZE[cnt]=$MAX
			[[ $uniq_flg != TRUE ]] && continue
			[[ ${UNIQ_PRINT_FLG[cnt]} = TRUE ]] && continue
			if [[ $first_report = TRUE ]]
			then
				PREV_VALUE[cnt]="$value"
				UNIQ_PRINT_FLG[cnt]=FALSE
			elif [[ "$value" != "${PREV_VALUE[cnt]}" ]]
			then
				UNIQ_PRINT_FLG[cnt]=TRUE
			fi
			continue
		fi
		[[ $uniq_flg = TRUE && ${UNIQ_PRINT_FLG[cnt]} != TRUE ]] && continue
		if [[ $table_flg = TRUE ]]
		then
			name=`printf "%-${SIZE[cnt]}s" "$name"`
			value=`printf "%-${SIZE[cnt]}s" "$value"`
		else
			name=`printf "%-${SIZE[cnt]}s" "$name"`
			value=`printf "%-${SIZE[cnt]}s" "$value"`
		fi
		if [[ $table_flg = TRUE ]]
		then
			if [[ $first = TRUE ]]
			then
				names="$name"
				values="$value"
			else
				names="$names    $name"
				values="$values    $value"
			fi
		else
			if [[ $first = TRUE ]]
			then
				names=" $name "
				values=" $value "
			else
				names="$names	 $name "
				values="$values	 $value "
			fi
		fi
		first=FALSE
	done <$results/$REPORT_NAME

	NAMES="$names"
	VALUES="$values"
}

INFO_LOG=

INFO_VALUE=

get_info_value()
{
	typeset	name=$1
	typeset	line

	INFO_VALUE=0
	line=`grep "^$name = " $INFO_LOG | tail -1`
	if [[ -z "$line" ]]
	then
##		warning "$name is not set in $INFO_LOG"
		return
	fi
	INFO_VALUE=${line#$name = }
	if [[ -z $INFO_VALUE ]]
	then
##		warning "$name is set to empty value in $INFO_LOG"
##		warning "$name is not set in $INFO_LOG"
		INFO_VALUE=0
	fi
	debug $name = "$INFO_VALUE"
}

MAX=

max()
{
	typeset v

	MAX=0

	for v in $*
	do
		(( v > MAX )) && (( MAX = v ))
	done
}

make_table()
{
	FIRST=TRUE

	(( RESULTS_NUM <= 1 )) && uniq_flg=FALSE
	for results in $RESULTS
	do
		make_report_line $results TRUE $FIRST
		FIRST=FALSE
	done
	results=

	FIRST=TRUE

	for results in $RESULTS
	do
		make_report_line $results
		if [[ $FIRST = TRUE ]]
		then
			FIRST=FALSE
		elif [[ "$PREV_NAMES" != "$NAMES" ]]
		then
			error "Results structures are not identical," \
				"$PREV_RESULTS and $results"
			NOT_IDENT=TRUE
			break
		fi
		PREV_RESULTS="$results"
		PREV_NAMES="$NAMES"
	done
	results=

	FIRST=TRUE
	PREV_NAMES=

	if [[ $NOT_IDENT = TRUE ]]
	then
		for results in $RESULTS
		do
			make_report_line $results
			if [[ $FIRST = TRUE ]]
			then
				echo "$NAMES"
				FIRST=FALSE
			elif [[ "$NAMES" != "$PREV_NAMES" ]]
			then
				echo ""
				echo "$NAMES"
			fi
			PREV_NAMES="$NAMES"
			echo "$VALUES"
		done
		results=
	else
		make_report_line $BASE
		echo "$NAMES"

		if [[ $sort_flg = TRUE ]]
		then
			for results in $RESULTS
			do
				make_report_line $results
				echo "$VALUES"
			done | sort
		else
			for results in $RESULTS
			do
				make_report_line $results
				echo "$VALUES"
			done
		fi
	fi
}

make "$@"
make_table
