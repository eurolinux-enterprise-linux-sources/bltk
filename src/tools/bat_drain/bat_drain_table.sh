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

REPORT_NAME=Report

ERR_IGN=

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
	echo "Debug: $results: $*" >&2
}

debug2()
{
	echo "Debug2: $results: $*" >&2
}


OPTIONS="hdstuEe"

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
	-d		debugging mode
	-s		sort result lines
	-t		Excel-compatible file format
	-u		only columns which contain different
			values will be included into table
	-E		errors being ignored (allows to create
			result table anyway)
	-e		skip error results
	directory ...	results directories list

Example:
	bat_drain_table <results1> ... <resultsn> >sum
		Common results table will be generated in 'sum' file for
		<results1> ... <resultsn> directories
EOF
}

command_line()
{
	while getopts $OPTIONS OPT
	do
		case $OPT in
			h ) common_usage; exit 0;;
			d ) debug_flg=TRUE;;
			s ) sort_flg=TRUE;;
			t ) table_flg=FALSE;;
			u ) uniq_flg=TRUE;;
			E ) ERR_IGN="-E";;
			e ) ERR_SKIP=TRUE; ERR_IGN="-E";;
			S ) split_mode=-S;;
			* ) usage; exit 2;;
		esac
	done

	shift $((OPTIND-1))

	RESULTS_NUM="$#"
	BASE="$1"
	RESULTS="$*"

	XRESULTS=

	for results in $RESULTS
	do
		if [[ ! -d $results ]]
		then
			error "$results is not a directory"
			continue
		fi
		if [[ ! -r $results/$REPORT_NAME ]]
		then
			error "Cannot access Report file"
			continue
		fi
		if [[ $ERR_SKIP = TRUE ]]
		then
			XRESULTS="$XRESULTS $results"
		fi
	done
	if [[ $ERR_SKIP = TRUE ]]
	then
		RESULTS="$XRESULTS"
	fi
	results=
}

make_report_line()
{
	results=$1
	calcsize=$2
	first_report=$3

	names=
	values=
	if [[ ! -r $results/$REPORT_NAME ]]
	then
		error "Cannot access $results/$REPORT_NAME" >&2
	fi
	first=TRUE
	(( cnt = -1 ))
	while read line
	do
		(( cnt += 1 ))
		[[ "$line" != *" :"* ]] && continue
		[[ "$line" == "#"* ]] && continue
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

command_line "$@"
make_table
