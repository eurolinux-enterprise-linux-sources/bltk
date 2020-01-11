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

BLTK_GET_STAT_CMD=$BLTK_BIN/bltk_get_stat
BLTK_CALC_CMD=$BLTK_BIN/bltk_calc

BLTK_PLOT_HISTORY=$BLTK_ROOT/.plot_history
BLTK_PLOT_TMP=$BLTK_TMP/bltk_plot.$$
ARGS_FILE=$BLTK_PLOT_TMP/bltk_plot.cmd
ARGS_FILE_SAVED=$BLTK_PLOT_TMP/bltk_plot.cmd.saved

OPTIONS="hDd:f:swx:yX:Y:t:o:12:vp:nR"

command_line()
{
	while getopts $OPTIONS OPT
	do
		case $OPT in
			h ) common_usage; exit 0;;
			D ) DEBUG=1;;
			d ) DIRS="$DISR $OPTARG";;
			f ) FILES="$FILES $OPTARG";;
			s ) FILES="$FILES stat.log";;
			w ) FILES="$FILES work.log";;
			x ) XFIELD="$OPTARG";;
			y ) YFIELDS="$YFIELDS $OPTARG";;
			X ) XRANGE="[$OPTARG]";;
			Y ) YRANGE="[$OPTARG]";;
			t ) TITLE="$OPTARG";;
			o ) PLOTOPTS="$PLOTOPTS $OPTARG";;
			1 ) IGN_ARGS="-1";;
			2 ) IGN_ARGS="-2 $OPTARG";;
			v ) print_vars_flg=TRUE;;
			p ) exit_flg=TRUE; print_flg=TRUE; PRINT_FILE=$OPTARG;;
			n ) print_names_flg=TRUE;;
			R ) find_mode=TRUE;;
			* ) usage; exit 1;;
		esac
	done
	shift $((OPTIND-1))

	if [[ $# != 0 ]]
	then
		DIRS="$DIRS $*"
	fi

	if [[ $find_mode = TRUE ]]
	then
		DIRS=`find $DIRS -type d`
		XDIRS=
		for results in $DIRS
		do
			if [[ ! -a $results/info.log ]]
			then
				continue
			fi
			XDIRS="$XDIRS $results"
		done
		results=
		DIRS=$XDIRS
		if [[ -z $DIRS ]]
		then
			warning "Results list is empty"
			exit
		fi
	fi

	return 0
}

error()
{
	echo "ERROR: $*" >&2
	cleanup
	exit 1
}

warning()
{
	echo "Warning: $*" >&2
}

debug()
{
	if [[ $DEBUG = 1 ]]
	then
		echo "Debug: $*" >&2
	fi
}

debug2()
{
		echo "Debug2: $*" >&2
}

usage()
{
	cat >&2 << EOF

Usage:	$PROG [-$OPTIONS] results_dir ...
	Type $PROG -h to get more information

EOF
}

common_usage(){
	cat >&2 << EOF

Usage:	$PROG [-$OPTIONS] results_dir ...

	-h			this help
	-D			debugging mode
	-d results_dir		results directory name
				this option could be passed several times
				default is current directory
	-f file			statistic file name
				this option could be passed several times
				default is stat.log
	-s			use stat.log file
	-w			use work.log file
	-x name			argument is used to be an X parameter
				default is 'time' field
	-y name ...		argument is used to be an Y parameter
				this option could be passed several times
				default is 'cap' field
	-X x1:x2		x range from x1 to x2
	-Y y1:y2		y range from y1 to y2
	-t title		graph title
	-o options		options passed to 'plot' command
	-1			first statistic item is ignored
	-2 item:num		statistic from item 'item', 'num' number
	-v			print current variables
	-p file			save graph to specified file
	-n			print available field's names
	-R			analyze all results dirs under passed directories

	results_dir ...		results directories list, the same as -d option

Example:
---------
	bltk_plot -y bat -x N <results_dir1> ... <results_dirn>
		Common graph will be generated for <results_dir1> ... <results_dirn>

EOF
dialog_usage
}

dialog_usage()
{
	cat >&2 << EOF

Dialog:
--------
	h			this help
	q/quit/e/exit/cntr-d	exit
	D			debugging mode
	d results_dir ...	results directory name
	f file			statistic file name
	x name			X parameter
	[y] name ...		Y parameter
	X x1:x2			x range from x1 to x2
	Y y1:y2			y range from y1 to y2
	t title			graph title
	o options		options passed to 'plot' command
	1			first statistic item is ignored
	2 item:num		statistic from item 'item', 'num' number
	v			print current variables
	p file			save current graph to specified file
	r			show current graph
	n			print available field's names

Example:
---------
	=> x time; y load

EOF
}

get_stat()
{
	$BLTK_GET_STAT_CMD $IGN_ARGS $*
	return $?
}

print_vars()
{
	{
	echo "D	$DEBUG"
	echo "f	$FILES"
	echo "d	$DIRS"
	echo "x	$XFIELD"
	echo "y	$YFIELDS"
	echo "X	$XRANGE"
	echo "Y	$YRANGE"
	echo "t	$TITLE"
	echo "o	$PLOTOPTS"
	echo ":	$IGN_ARGS"
	echo "p	$PRINT_FILE"
	} >&2
}

set_xrange()
{
	if [[ $# = 0 ]]
	then
		XRANGE=
	else
		XRANGE=[$*]
	fi
}

set_yrange()
{
	if [[ $# = 0 ]]
	then
		YRANGE=
	else
		YRANGE=[$*]
	fi
}

show_history()
{
	cat $BLTK_PLOT_HISTORY
}

dialog_line()
{
	typeset	ret=0
	typeset	newy=

	print_flg=FALSE

	while :
	do
		if [[ "$ARGS" == *';'* ]]
		then
			args=${ARGS%%;*}
			ARGS=${ARGS#$args;}
		else
			args=$ARGS
			ARGS=
		fi
		[[ -z "$args" ]] && break
		c=1
		opt=
		arg=
		args2=$args
		args=
		for a in $args2
		do
			if (( c == 1 ))
			then
				opt=$a
			elif (( c == 2 ))
			then
				arg=$a
				args=$a
			else
				args="$args $a"
			fi
			(( c++ ))
		done
		opt=${opt##-}
		opt=${opt##-}
		if [[ "$opt" == !* ]]
		then
			opt=${opt#!}
			$opt $args
			break
		fi
		case $opt in
			h ) dialog_usage;;
			D ) DEBUG=1;;
			v ) print_vars_flg=TRUE;;
			x ) XFIELD=$args; ((ret++));;
			y ) newy="$newy $args"; ((ret++));;
			t ) TITLE=$args; ((ret++));;
			f ) FILES=$args; ((ret++));;
			d ) DIRS=$args; ((ret++));;
			o ) PLOTOPTS=$args; ((ret++));;
			1 ) IGN_ARGS="-1"; ((ret++));;
			2 ) IGN_ARGS="-2 $args"; ((ret++));
				[[ -z "$args" ]] && IGN_ARGS=;;
			p ) print_flg=TRUE; ((ret++));
				[[ ! -z "$args" ]] && PRINT_FILE=$args;;
			r ) ((ret++));;
			n ) print_names_flg=TRUE;;
			X ) set_xrange $args; ((ret++));;
			Y ) set_yrange $args; ((ret++));;
			H ) show_history;;
			* ) newy="$newy $opt $args"; ((ret++));;
		esac
	done
	if [[ ! -z $newy ]]
	then
		YFIELDS=$newy
	fi
	return $ret
}

defaults()
{
	if [[ -z $DIRS ]]
	then
		DIRS="."
	fi
	DIRS=`echo $DIRS`
	if [[ -z $FILES ]]
	then
		FILES="stat.log"
	fi
	FILES=`echo $FILES`
	if [[ -z $XFIELD ]]
	then
		XFIELD="time"
	fi
	if [[ -z $YFIELDS ]]
	then
		YFIELDS="cap"
	fi
	YFIELDS=`echo $YFIELDS`
	if [[ -z $PLOTOPTS ]]
	then
		PLOTOPTS="with lines lw 3"
	fi
	if [[ -z $PRINT_FILE ]]
	then
		PRINT_FILE="tmp.png"
	elif [[ $PRINT_FILE != *.png ]]
	then
		PRINT_FILE="$PRINT_FILE.png"
	fi
	return 0
}

check_dirs()
{
	unset FLIST
	(( FLISTCNT = 0 ))
	for d in $DIRS
	do
		if [[  ! -d $d ]]
		then
			error "Cannot access $d"
		fi
		for f in $FILES
		do
			if [[  ! -r $d/$f ]]
			then
				error "Cannot access $d/$f, pass valid results directory"
			fi
			FLIST="$FLIST $d/$f"
			(( FLISTCNT++ ))
		done
	done
	return 0
}

print_names()
{
	for f in $FLIST
	do
		s=`get_stat -s $f -t`
		if [[ $? != 0 ]]
		then
			error "Nemes getting failed, file $f"
		fi
		echo "$s"
	done | sort| uniq >&2
}

prepare_data()
{
	(( pcnt = 0 ))
	unset FILEPLOT
	for f in $FLIST
	do
		if [[ "$XFIELD" == *:* ]]
		then
			no=${XFIELD##*:}
			no="-n $no"
			nm=${XFIELD%%:*}
		else
			nm=$XFIELD
			no=
		fi
		get_stat -s $f $no -c "$nm"
		if [[ $? != 0 ]]
		then
			warning "$XFIELD is absent in $f"
			continue
		fi
		xlist=`get_stat -s $f -a $no "$nm"`
		if [[ $? != 0 ]]
		then
			error "$XFIELD getting failed, file $f"
		fi
		xlist=`$BLTK_CALC_CMD +c $xlist`
		if [[ $? != 0 ]]
		then
			error "$BLTK_CALC_CMD +c xlist... failed, file $f"
		fi
		(( xcnt = 0 ))
		for x in $xlist
		do
			X[xcnt]=$x
			(( xcnt++ ))
		done
		(( XCNT = xcnt ))
		for yf in $YFIELDS
		do
			if [[ "$yf" == *:* ]]
			then
				no=${yf##*:}
				no="-n $no"
				nm=${yf%%:*}
			else
				nm=$yf
				no=
			fi
			get_stat -s $f $no -c "$nm"
			if [[ $? != 0 ]]
			then
				warning "$yf is absent in $f"
				continue
			fi
			ylist=`get_stat -s $f -a $no "$nm"`
			if [[ $? != 0 ]]
			then
				error "$yf getting failed, file $f"
			fi
			ylist=`$BLTK_CALC_CMD +c $ylist`
			if [[ $? != 0 ]]
			then
				error "$BLTK_CALC_CMD +c ylist... failed, file $f"
			fi
			(( ycnt = 0 ))
			for y in $ylist
			do
				Y[ycnt]=$y
				(( ycnt++ ))
			done
			(( YCNT = ycnt ))
			if (( XCNT != YCNT ))
			then
				error "f: x number ($XCNT) != y number ($YCNT), file $f"
			fi
			FILEPLOT[pcnt]="$BLTK_PLOT_TMP/$XFIELD.$yf.$pcnt.plot"
			if (( FLISTCNT > 1 ))
			then
				TITLEPLOT[pcnt]="$f $yf"
			else
				TITLEPLOT[pcnt]="$yf"
			fi
			(( cnt = 0 ))
			(( CNT = YCNT ))
			while (( cnt < CNT ))
			do
				echo "${X[cnt]} 	${Y[cnt]}"
				(( cnt++ ))
			done >${FILEPLOT[pcnt]}
			(( pcnt++ ))
		done
	done
	(( PCNT = pcnt ))
	return 0
}

prepare_plot()
{
	PLOT=
	pcnt=0
	while (( pcnt < PCNT ))
	do
		if (( pcnt == 0 ))
		then
			PLOT="plot "
		else
			PLOT="$PLOT , "
		fi
		PLOT="$PLOT '${FILEPLOT[pcnt]}' title '${TITLEPLOT[pcnt]}' $PLOTOPTS"
		(( pcnt++ ))
	done
	return 0
}

plot()
{
	if [[ $print_flg = TRUE ]]
	then
		echo "printing to $PRINT_FILE"
	fi

	{
	if [[ $print_flg = TRUE ]]
	then
		echo "set terminal png"
#		echo "set key off"
#		echo "set grid"
		echo "set output '$PRINT_FILE'"
	fi
	echo "set title '$TITLE'"
	echo "set xlabel '$XFIELD'"
	echo "set ylabel '$YFIELDS'"
	[[ ! -z $XRANGE ]] && echo "set xrange $XRANGE"
	[[ ! -z $YRANGE ]] && echo "set yrange $YRANGE"
	echo "$PLOT"
	[[ $exit_flg = TRUE ]] && return 0
	read_cmd
	} | gnuplot
	return $?
}

read_cmd()
{
	typeset	OCMD

	while :
	do
		history -c
		history -r $BLTK_PLOT_HISTORY
		read -e -u2 -p "=> " CMD
		if [[ $? != 0 ]]
		then
			CMD=q
		fi
		[[ -z $CMD ]] && continue
		echo "$CMD" >$ARGS_FILE
		[[ $CMD = e || $CMD = exit || $CMD = q || $CMD = quit ]] && return
		[[ $CMD = v || $CMD = h || $CMD = H ]] && return
		if [[ -f $ARGS_FILE_SAVED ]]
		then
			OCMD=`cat $ARGS_FILE_SAVED`
			[[ $OCMD = $CMD ]] && return
		fi
		echo "$CMD" >>$BLTK_PLOT_HISTORY
		return
	done
}

print_vars_names()
{
	if [[ $print_names_flg = TRUE ]]
	then
		print_names
		print_names_flg=FALSE
	fi

	if [[ $print_vars_flg = TRUE ]]
	then
		print_vars
		print_vars_flg=FALSE
	fi
}

startup()
{
	CMD="type -p gnuplot"
	$CMD >/dev/null 2>&1
	[[ $? != 0 ]] && error "$CMD failed, cannot accces gnuplot program"

	CMD="rm -rf $BLTK_PLOT_TMP"
	$CMD
	[[ $? != 0 ]] && error "$CMD failed"

	CMD="mkdir -pm0777 $BLTK_PLOT_TMP"
	$CMD
	[[ $? != 0 ]] && error "$CMD failed"
}

cleanup()
{
	CMD="rm -rf $BLTK_PLOT_TMP"
	$CMD
	[[ $? != 0 ]] && warning "$CMD failed"
}

main()
{
	typeset	first_iter=TRUE

	while :
	do
		if [[ $first_iter = TRUE ]]
		then
			command_line "$@"
			first_iter=FALSE
		else
			[[ $exit_flg = TRUE ]] && break
			if [[ ! -f $ARGS_FILE ]]
			then
				read_cmd
			fi
			ARGS=`cat $ARGS_FILE`
			PREV_ARGS="$ARGS"
			mv $ARGS_FILE $ARGS_FILE_SAVED
			[[ "$ARGS" = q || "$ARGS" = quit ]] && break
			[[ "$ARGS" = e || "$ARGS" = exit ]] && break
			dialog_line
			ret=$?
			print_vars_names
			[[ $ret = 0 ]] && continue
		fi
		defaults
		[[ $? != 0 ]] && continue
		check_dirs
		ret=$?
		print_vars_names
		[[ $ret != 0 ]] && continue
		prepare_data
		[[ $? != 0 ]] && continue
		prepare_plot
		[[ $? != 0 ]] && continue
		plot
	done
}

trap 'cleanup; exit 1' 1 2 3 6 15

startup
main "$@"
cleanup
