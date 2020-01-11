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

BLTK_REPORT=$BLTK_BIN/bltk_report

REPORT_NAME=Report.table
REPORT_NAME_LOCAL=Report

ERR_IGN=

error()
{
	if [[ ! -z $results ]]
	then
		echo "ERROR: Result directory is $results" >&2
	fi
	if [[ -z $ERR_IGN && -z $ERR_SKIP ]]
	then
		echo "FATAL ERROR: $*" >&2
		exit 1
	fi
	if [[ $ERR_SKIP = TRUE ]]
	then
		echo "ERROR: Results directory is skipped: $*" >&2
	else
		echo "ERROR: Error is ignored: $*" >&2
	fi
	debug "${FUNCNAME[*]}"
	debug "${BASH_LINENO[*]}"
	echo "	" >&2
}

warning()
{
	if [[ ! -z $results ]]
	then
		echo "WARNING: Result directory is $results" >&2
	fi
	echo "WARNING: $*" >&2
	echo "	" >&2
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


OPTIONS="hdstfuEe12:34:F:SRr"

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
	-f		filename will be used as a comment
	-1		first statistic item of score file is ignored
	-2 item:num	statistic from item 'item', 'num' number of score file
	-3		first statistic item of stat.log file is ignored
	-4 item:num	statistic from item 'item', 'num' number of stat.log file
	-u		only columns which contain different
			values will be included into table
	-E		errors being ignored (allows to create
			result table anyway)
	-e		skip error results
	-F filter	only fields from filter file will be included into table
			(see data/filter as an example)
	-S		split mode - split multiple values to columns
	-R		analyze all results dirs under passed directories
	directory ...	results directories list

Example:
	bltk_report_table <results1> ... <resultsn> >sum
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
			f ) REPORT_FLAGS="$REPORT_FLAGS -f";;
			1 ) REPORT_FLAGS="$REPORT_FLAGS -1";;
			2 ) REPORT_FLAGS="$REPORT_FLAGS -2 $OPTARG";;
			3 ) REPORT_FLAGS="$REPORT_FLAGS -3";;
			4 ) REPORT_FLAGS="$REPORT_FLAGS -4 $OPTARG";;
			u ) uniq_flg=TRUE;;
			E ) ERR_IGN="-E";;
			e ) ERR_SKIP=TRUE; ERR_IGN="-E";;
			F ) FILTER="$OPTARG";;
			S ) split_mode=-S;;
			R ) find_mode=TRUE;;
			r ) lock_report_flg=TRUE;;
			* ) usage; exit 2;;
		esac
	done

	shift $((OPTIND-1))

	RESULTS="$*"

	if [[ $# = 0 ]]
	then
		RESULTS=.
	fi

	if [[ $find_mode = TRUE ]]
	then
		RESULTS=`find $RESULTS -type d`
		XRESULTS=
		for results in $RESULTS
		do
			if [[ ! -a $results/info.log ]]
			then
				continue
			fi
			XRESULTS="$XRESULTS $results"
		done
		results=
		RESULTS=$XRESULTS
	fi

	XRESULTS=

	for results in $RESULTS
	do
		if [[ ! -d $results ]]
		then
			error "$results is not a directory"
			[[ $ERR_SKIP = TRUE ]] && continue
		fi
		if [[ -a $results/fail ]]
		then
			error "Test completed with error (fail file)"
			[[ $ERR_SKIP = TRUE ]] && continue
		fi
		if [[ -a $results/err.log ]]
		then
			error "Test completed with error (err.log file)"
			[[ $ERR_SKIP = TRUE ]] && continue
		fi
		if [[ ! -r $results/info.log ]]
		then
			error "Cannot access info.log file"
			[[ $ERR_SKIP = TRUE ]] && continue
		fi
		if [[ ! -r $results/info1.log ]]
		then
			error "Cannot access info1.log file"
			[[ $ERR_SKIP = TRUE ]] && continue
		fi
		if [[ ! -r $results/info2.log ]]
		then
			error "Cannot access info2.log file"
			[[ $ERR_SKIP = TRUE ]] && continue
		fi
		if [[ ! -r $results/stat.log ]]
		then
			error "Cannot access stat.log file"
			[[ $ERR_SKIP = TRUE ]] && continue
		fi
		if [[ $ERR_SKIP = TRUE ]]
		then
			XRESULTS="$XRESULTS $results"
		fi
	done
	results=
	if [[ $ERR_SKIP = TRUE ]]
	then
		RESULTS="$XRESULTS"
	fi
	RESULTS_NUM=0
	for results in $RESULTS
	do
		(( RESULTS_NUM++ ))
	done
	if [[ -z $RESULTS ]]
	then
		warning "Results list is empty"
		exit
	fi
	set $RESULTS
	BASE=$1
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

BAT_MAX=0
HD_MAX=0
CPU_MAX=0
C_MAX=0
P_MAX=0

get_max_config()
{
	typeset	CPUFREQ_CUR=
	typeset	CPUINFO_CUR=
	typeset	CPUSTATE_CUR=
	typeset	CPU_CUR=
	typeset	BAT_CUR=
	typeset	HD_CUR=
	typeset	C_CUR=
	typeset	P_CUR=

	for results in $RESULTS
	do
		INFO_LOG=$results/info1.log
		get_info_value CPUFREQ_NUM; CPUFREQ_CUR=$INFO_VALUE
		get_info_value CPUINFO_NUM; CPUINFO_CUR=$INFO_VALUE
		get_info_value CPUSTATE_NUM; CPUSTATE_CUR=$INFO_VALUE
		if [[ $CPUFREQ_CUR != $CPUINFO_CUR || $CPUFREQ_CUR != $CPUSTATE_CUR ]]
		then
			:
			#warning "Invalid CPUs number in $INFO_LOG file"
			#warning "CPUFREQ_NUM = $CPUFREQ_CUR"
			#warning "CPUINFO_NUM = $CPUINFO_CUR"
			#warning "CPUSTATE_NUM = $CPUSTATE_CUR"
		fi
		i=0
		while (( i < CPUSTATE_CUR ))
		do
			(( i++ ))
			get_info_value CPUSTATE_${i}_C_NUM; C_CUR=$INFO_VALUE
			max $C_MAX $C_CUR; (( C_MAX = MAX ))
		done

		i=0
		while (( i < CPUFREQ_CUR ))
		do
			(( i++ ))
			get_info_value CPUFREQ_${i}_P_NUM; P_CUR=$INFO_VALUE
			max $P_MAX $P_CUR; (( P_MAX = MAX ))
		done
		max $CPU_MAX $CPUFREQ_CUR $CPUINFO_CUR $CPUSTATE_CUR; (( CPU_MAX = MAX ))

		get_info_value BAT_NUM; BAT_CUR=$INFO_VALUE
		max $BAT_MAX $BAT_CUR; (( BAT_MAX = MAX ))

##		get_info_value HD_NUM; HD_CUR=$INFO_VALUE
##		max $HD_MAX $HD_CUR; (( HD_MAX = MAX ))
	done
	results=

	debug CPU_MAX=$CPU_MAX
	debug C_MAX=$C_MAX
	debug P_MAX=$P_MAX
	debug BAT_MAX=$BAT_MAX
	debug HD_MAX=$HD_MAX

	CMD="$BLTK_REPORT $ERR_IGN -U $CPU_MAX -C $C_MAX -P $P_MAX -B $BAT_MAX -D $HD_MAX $REPORT_FLAGS -R $REPORT_NAME $split_mode $RESULTS"
	debug $CMD
	$CMD
	[[ $? != 0 ]] && error "$CMD failed"

	if [[ $lock_report_flg = TRUE ]]
	then
		CMD="$BLTK_REPORT $ERR_IGN $REPORT_FLAGS -R $REPORT_NAME_LOCAL $split_mode $RESULTS"
		debug $CMD
		$CMD
		[[ $? != 0 ]] && error "$CMD failed"
	fi

	if [[ ! -z $FILTER ]]
	then
		if [[ ! -r $FILTER ]]
		then
			error "Cannot access $FILTER"
		fi
		FILTER_LINE_CNT=0
		while read filter_line
		do
			[[ -z "$filter_line" ]] && continue
			[[ "$filter_line" == "#"* ]] && continue
			FILTER_LINES[FILTER_LINE_CNT]="  $filter_line :"
			(( FILTER_LINE_CNT++ ))
		done <$FILTER
		for results in $RESULTS
		do
			r=$results/$REPORT_NAME
			r2=$results/$REPORT_NAME.2
			rm -f $r2
			cnt=0
			while (( cnt < FILTER_LINE_CNT ))
			do
				CMD="grep "${FILTER_LINES[cnt]}" $r >> $r2"
				grep "${FILTER_LINES[cnt]}" $r >> $r2
				[[ $? = 2 ]] && error "$CMD failed"
				(( cnt++ ))
			done
			CMD="cp $r2 $r"
			$CMD
			[[ $? != 0 ]] && error "$CMD failed"
			rm -f $r2
		done
		results=
	fi
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
			results=
		else
			for results in $RESULTS
			do
				make_report_line $results
				echo "$VALUES"
			done
			results=
		fi
	fi
}

command_line "$@"
get_max_config
make_table
