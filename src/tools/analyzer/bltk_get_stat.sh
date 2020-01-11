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

PROG=$0

error()
{
	echo "ERROR: $PROG: $*" >&2
	echo BLTK_GET_STAT_BAD_ARGS
	exit 1
}

warning()
{
	echo "Warning $PROG: $*" >&2
}

debug()
{
	if [[ $DEBUG = TRUE || DEBUG = 1 ]]
	then
		echo "DEBUG: $PROG: $*" >&2
	fi
}

TMP_FILE=/tmp/tmp.$$

STAT=./stat.log

NAMES=

DEBUG=0

OPTIONS="hdtcflan:Ns:SWI12:"

usage()
{
	echo Usage: $0 [-$OPTIONS] >&2
}

while getopts $OPTIONS OPT
do
	case $OPT in
		h ) usage; exit 0;;
		d ) DEBUG=$OPTARG;;
		t ) title_flg=TRUE;;
		c ) check_flg=TRUE;;
		f ) first_flg=TRUE;;
		l ) last_flg=TRUE;;
		a ) all_flg=TRUE;;
		n ) no_flg=TRUE; no_val=$OPTARG;;
		N ) num_flg=TRUE;;
		s ) STAT=$OPTARG;;
###		S ) S_flg=TRUE;;
###		W ) W_flg=TRUE;;
###		I ) I_flg=TRUE;;
		1 ) ign_lines_flg=TRUE; ign_head_cnt=1;;
		2 ) ign_lines_flg=TRUE; ign_head_cnt=$OPTARG;;
		* ) usage; exit 2;;
	esac
done

if [[ $ign_lines_flg = TRUE ]]
then
	if [[ $ign_head_cnt == *:* ]]
	then
		ign_num_cnt=${ign_head_cnt#*:}
		ign_head_cnt=${ign_head_cnt%:*}
		ign_head_cnt=`echo $ign_head_cnt`
		ign_num_cnt=`echo $ign_num_cnt`
		if [[ -z $ign_head_cnt ]]
		then
			ign_head_cnt=0
		elif (( ign_head_cnt < 0 ))
		then
			ign_head_cnt=0
		fi
		if [[ -z $ign_num_cnt ]]
		then
			ign_num_cnt=
		elif (( ign_num_cnt < 0 ))
		then
			ign_num_cnt=
		fi
	fi
fi

shift $((OPTIND-1))

NAMES=$*

get_title()
{
	typeset	stat=$1
	typeset	line

	TITLE=
	line=`cat $stat | grep '^T:' | head -2 | tail -1` # second title line
	if [[ -z $line ]]
	then
		error "Cannot get title info from $stat file, (corrupted?)"
	fi
	TITLE=$line
	debug "TITLE: $TITLE"
}

get_name_no()
{
	typeset	name=$1
	typeset	no_val=$2
	typeset name_no=0
	typeset no=0
	typeset	nm

	NAME_NO=

	[[ -z $no_val ]] && no_val=1

	for nm in $TITLE
	do
		(( no = no + 1 ))
		if [[ $nm = $name ]]
		then
			(( name_no++ ))
			if (( name_no == no_val ))
			then
				(( NAME_NO = no ))
				break
			fi
		fi
	done
	debug "NAME_NO: $name $NAME_NO"
}

get_first()
{
	typeset	stat=$1
	typeset	name_no=$2
	typeset	value

	if [[ $ign_lines_flg != TRUE ]]
	then
		grep '^.:' $stat | grep -v "^T:" | head -1 |
			awk "{ print \$$name_no }"
	else
		grep '^.:' $stat | grep -v "^T:" |
			awk "{ print \$$name_no }" >$TMP_FILE
		cnt=`cat $TMP_FILE | wc -l`
		[[ -z $ign_head_cnt ]] && ign_head_cnt=0
		(( cnt = cnt - ign_head_cnt ))
		(( cnt < 0 )) && (( cnt = 0 ))
		[[ -z $ign_num_cnt ]] && ign_num_cnt=$cnt
		tail -$cnt $TMP_FILE | head -$ign_num_cnt | head -1
	fi
}

get_last()
{
	typeset	stat=$1
	typeset	name_no=$2
	typeset	value

	if [[ $ign_lines_flg != TRUE ]]
	then
		grep '^.:' $stat | grep -v "^T:" | tail -1 |
			awk "{ print \$$name_no }"
	else
		grep '^.:' $stat | grep -v "^T:" |
			awk "{ print \$$name_no }" >$TMP_FILE
		cnt=`cat $TMP_FILE | wc -l`
		[[ -z $ign_head_cnt ]] && ign_head_cnt=0
		(( cnt = cnt - ign_head_cnt ))
		(( cnt < 0 )) && (( cnt = 0 ))
		[[ -z $ign_num_cnt ]] && ign_num_cnt=$cnt
		tail -$cnt $TMP_FILE | head -$ign_num_cnt | tail -1
	fi
}

get_all()
{
	typeset	stat=$1
	typeset	name_no=$2
	typeset	values
	typeset	first
	typeset	cnt

	if [[ $ign_lines_flg != TRUE ]]
	then
		grep '^.:' $stat | grep -v "^T:" |
			awk "{ print \$$name_no }"
	else
		grep '^.:' $stat | grep -v "^T:" |
			awk "{ print \$$name_no }" >$TMP_FILE
		cnt=`cat $TMP_FILE | wc -l`
		[[ -z $ign_head_cnt ]] && ign_head_cnt=0
		(( cnt = cnt - ign_head_cnt ))
		(( cnt < 0 )) && (( cnt = 0 ))
		[[ -z $ign_num_cnt ]] && ign_num_cnt=$cnt
		tail -$cnt $TMP_FILE | head -$ign_num_cnt
	fi
}

get_num()
{
	typeset	stat=$1
	typeset	cnt

	if [[ $ign_lines_flg != TRUE ]]
	then
		cnt=`grep '^.:' $stat | grep -v "^T:" | wc -l`
	else
		cnt=`grep '^.:' $stat | grep -v "^T:" | wc -l`
		[[ -z $ign_head_cnt ]] && ign_head_cnt=0
		(( cnt = cnt - ign_head_cnt ))
		if (( cnt < 0 ))
		then
			(( cnt = 0 ))
		elif [[ ! -z $ign_num_cnt ]]
		then
			(( ign_num_cnt < cnt )) && cnt=$ign_num_cnt
		fi
	fi
	echo "$cnt"
}

check_value()
{
	typeset	stat=$1
	typeset	name=$2
	typeset	value=$3
	typeset	error=$4

	if [[ -z $value && $error = 1 ]]
	then
		error "Cannot get '$name' info from $STAT, (corrupted?)"
	elif [[ -z $value ]]
	then
		warning "Cannot get '$name' info from $STAT, (corrupted?)"
	fi
}

get_title $STAT

if [[ $title_flg = TRUE ]]
then
	echo "$TITLE"
fi

if [[ $num_flg = TRUE ]]
then
	get_num $STAT
fi

for name in $NAMES
do
	get_name_no $name $no_val
	if [[ $check_flg = TRUE ]]
	then
		if [[ -z $NAME_NO ]]
		then
			exit 2;
		fi
	else
		check_value "$STAT" "$name" "$NAME_NO" 1
	fi
	if [[ $first_flg = TRUE ]]
	then
		get_first $STAT $NAME_NO
	elif [[ $last_flg = TRUE ]]
	then
		get_last $STAT $NAME_NO
	elif [[ $all_flg = TRUE ]]
	then
		get_all $STAT $NAME_NO
	fi
done

rm -f $TMP_FILE

exit 0

