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


VERSION="1.0"

unalias -a

set_bltk_root()
{
	PROG=`basename $0`

	export BLTK_ROOT=`dirname $0`
	[[ -a $BLTK_ROOT/.bltk ]] && return

	export BLTK_ROOT=`dirname $BLTK_ROOT`
	[[ -a $BLTK_ROOT/.bltk ]] && return

	export BLTK_ROOT=../../
	[[ -a $BLTK_ROOT/.bltk ]] && return
	export BLTK_ROOT=
}

set_bltk_root

export BLTK_BIN=$BLTK_ROOT/bin
export BLTK_SUDO=$BLTK_BIN/bltk_sudo
export BLTK_GET_DMIDECODE=$BLTK_BIN/bltk_get_dmidecode
export BLTK_GET_SYSTEM_RELEASE=$BLTK_BIN/bltk_get_system_release

if [[ -x $BLTK_SUDO ]]
then
	MANUFACTURER=`$BLTK_SUDO $BLTK_GET_DMIDECODE -m`
	PRODUCT_NAME=`$BLTK_SUDO $BLTK_GET_DMIDECODE -p`
	SYSTEM_RELEASE=`$BLTK_GET_SYSTEM_RELEASE -v`
fi

# percents
BAT_CRITICAL=5
# seconds
BAT_CRITICAL_INTERVAL=60
BAT_CHECK_UPDATE_INTERVAL=60

# seconds
DEF_WORK_TIME=30
#cpu
CPU_LOAD_FLG=TRUE

PROG=`basename $0`

STDERR=/tmp/$PROG.stderr

CWD=$PWD

ACAD_DIR=
BAT_DIR=
CPU_PSTATE_DIR=
CPU_CSTATE_DIR=

ACAD_STATE_FILE=
ACAD_PRESENT=FALSE

BAT_DIR_NAME=
BAT_NAME=
BAT_CNT=0

CPU_TIMER_NAME=
CPU_TIMER_CNT=

CPU_CSTATE_DIR_NAME=
CPU_CSTATE_CNT=0

CPU_PSTATE_DIR_NAME=
CPU_PSTATE_CNT=0

RES_DIR=
RES_SYSTEM1=
RES_SYSTEM2=
RES_LOG=

log()
{
	echo "$@" >>$RES_LOG
}

f_log()
{
	printf "$@" >>$RES_LOG
}

echo_log()
{
	echo "$@"
	log "$@"
}

f_echo_log()
{
	printf "$@"
	f_log "$@"
}

error()
{
	echo_log "ERROR: $*"
	exit 1
}

warning()
{
	echo_log "Warning: $*"
}

debug()
{
	[[ $debug_flg != TRUE ]] && return
	echo_log "Debug: $*"
}

usage()
{
	if [[ -z $1 ]]
	then
		echo "Usage: $0 [-$OPTIONS]"
		echo "	-h		this info"
		echo "	-t <time>	execition time in seconds, default is 30"
		echo "	-r <dir>	results directory, default is ./results"
		echo "	-s <cmd>	screen brigthness setting, see examples"
		echo "			on/min/max/off-fn - manual actions,"
		echo "			off/standby/suspend - automatic actions"
		echo "	-K		comment"
		echo "	-L		print cpu loading"
		echo "	-a		ignore ac adapter state"
		echo "	-b		ignore screen state"
		echo "	-u		ignore battery capacity update"
		echo "	-cCkpifDnB  	internal debug options"
		echo "Results"
		echo "	log		log file"
		echo "	Report		report file"
		echo "	system1		system files snapshot (start)"
		echo "	system2		system files snapshot (finish)"
		echo "Examples:"
		echo "	$PROG"
		echo "		default values, time is 30 sec, results directory is 'results'"
		echo "	$PROG -t 600 -r res.1000hz"
		echo "		time is 600 sec, results directory is 'res.1000hz'"
		echo "	$PROG -t 600 -r results.min -s min"
		echo "		time is 600 sec, results directory is 'results.min',"
		echo "		a request to set screen to minimal brigthness"
		echo "	$PROG -t 600 -r results.max -s max"
		echo "		time is 600 sec, results directory is 'results.max',"
		echo "		a request to set screen to maximal brigthness"
		echo "	$PROG -t 600 -r results.off -s off"
		echo "		time is 600 sec, results directory is 'results.off',"
		echo "		automatically turn of screen"
	else
		echo_log "Usage: $0 [-$OPTIONS]"
	fi
}

COMMENT=
COMMENT_CNT=0

work_time=$DEF_WORK_TIME

OPTIONS="hdt:abur:LcC:k:s:pi:f:D:n:B:K:"

screen_state=on

init_srgs()
{
	ARGS="$@"

	while getopts $OPTIONS OPT
	do
		case $OPT in
			h ) usage; exit 0;;
			d ) debug_flg=TRUE;;
			t ) work_time_flg=TRUE; work_time="$OPTARG";;
			a ) ac_ign_flg=TRUE;;
			b ) br_ign_flg=TRUE; screen_state=on;;
			u ) up_ign_flg=TRUE;;
			r ) RES_DIR="$OPTARG";;
			L ) CPU_LOAD_FLG=TRUE;;
			c ) check_bat_update_flg=TRUE;;
			n ) num_flg=TRUE; num_value="$OPTARG";;
			C ) check_bat_update_flg=TRUE;
				BAT_CHECK_UPDATE_INTERVAL="$OPTARG";;
			k ) COMMENT[COMMENT_CNT]="$OPTARG";
				(( COMMENT_CNT++ ));;
			s ) screen_state=$OPTARG;;
			p ) left_work_flg=TRUE;
				bat_percentage_flg=TRUE;;
			i ) init_user_cmd="$OPTARG";;
			f ) fini_user_cmd="$OPTARG";;
			B ) BAT_CRITICAL_ARG="$OPTARG";;
			D ) DEBUG_ROOT="$OPTARG";;
			K ) COMMENT="$OPTARG";;
			* ) usage; exit 2;;
		esac
	done

	shift $((OPTIND-1))

	check_screen_state $screen_state

	[[ $# != 0 ]] && { usage; exit 2; }

	if [[ ! -z $DEBUG_ROOT ]]
	then
		if [[ $DEBUG_ROOT != /* ]]
		then
			DEBUG_ROOT=$PWD/$DEBUG_ROOT
		fi
	fi

	ACAD_DIR=$DEBUG_ROOT/proc/acpi/ac_adapter
	BAT_DIR=$DEBUG_ROOT/proc/acpi/battery
	CPU_PSTATE_DIR=$DEBUG_ROOT/sys/devices/system/cpu
	CPU_CSTATE_DIR=$DEBUG_ROOT/proc/acpi/processor
	CPU_TIMER_NAME=$DEBUG_ROOT/proc/interrupts
	CPU_STAT_NAME=$DEBUG_ROOT/proc/stat

	get_results_dir
	check_results_dir
	rm_dir $RES_DIR
	mk_dir $RES_DIR
	rm_file last_results
	ln -s $RES_DIR last_results

	RES_LOG=$RES_DIR/log
	RES_REPORT=$RES_DIR/Report
	RES_SYSTEM1=$RES_DIR/system1
	RES_SYSTEM2=$RES_DIR/system2
	mk_dir $RES_SYSTEM1
	mk_dir $RES_SYSTEM2

	echo "Results will be available in $RES_DIR directory"
	echo_log "`date`"
	log "$PROG $ARGS"
	echo "$PROG $ARGS" >last_cmd
	echo "$PROG $ARGS" >$RES_DIR/cmd

	log "`uname -a`"
	log $MANUFACTURER
	log $PRODUCT_NAME

	if [[ ! -z $DEBUG_ROOT ]]
	then
		echo $DEBUG_ROOT >$RES_SYSTEM1/root
		echo $DEBUG_ROOT >$RES_SYSTEM2/root
	fi

	if [[ ! -z $BAT_CRITICAL_ARG ]]
	then
		BAT_CRITICAL=${BAT_CRITICAL_ARG%:*}
		BAT_CRITICAL_INTERVAL=${BAT_CRITICAL_ARG#*:}
		echo_log "BAT_CRITICAL=$BAT_CRITICAL"
		echo_log "BAT_CRITICAL_INTERVAL=$BAT_CRITICAL_INTERVAL"
	fi
}

get_results_dir()
{
	typeset i
	typeset n

	[[ ! -z $RES_DIR ]] && return
	if [[ ! -a results ]]
	then
		RES_DIR=results
		return
	fi
	i=0
	while :
	do
		(( i++ ))
		n=`printf "results.%03d" $i`
		if [[ ! -a $n ]]
		then
			RES_DIR=$n
			return
		fi
	done
}

check_results_dir()
{
	typeset r

	[[ ! -a $RES_DIR ]] && return
	beep_start
	echo -n "Warning: $RES_DIR exists, overwrite it? (y/n[n])"
	read r
	beep_finish
	if [[ $r != y ]]
	then
		echo "Test aborted by user"
		exit 1
	fi
}

check_screen_state()
{
	[[ $1 = min ]] && return
	[[ $1 = max ]] && return
	[[ $1 = on ]] && return
	[[ $1 = off ]] && return
	[[ $1 = off-fn ]] && return
	[[ $1 = standby ]] && return
	[[ $1 = suspend ]] && return
	echo "Invalid screen state = $1"
	exit 2
}

do_sleep()
{
###	echo_log "SLEEP: $1"
	[[ $1 != 0 ]] && sleep $1
}

BEEP_PID=

beep_run()
{
	trap 'trap_beep_action 0; exit 0' 1 2 3 6 15

	while :
	do
		printf "\a"
		sleep 3
	done
}

trap_beep_action()
{
	exit 0
}

beep_start()
{
	beep_run &
	BEEP_PID=$!
}

beep_finish()
{
	if [[ ! -z $BEEP_PID ]]
	then
		kill -6 $BEEP_PID >/dev/null 2>&1
		BEEP_PID=
	fi
}

rm_dir()
{
	typeset	d=$1

	rm -rf $d
	[[ $? != 0 ]] && error "Cannot remove $d"
}

mk_dir()
{
	typeset	d=$1

	mkdir -pm0777 $d
	[[ $? != 0 ]] && error "Cannot create $d"
}

rm_file()
{
	typeset	f=$1

	rm -f $f
	[[ $? != 0 ]] && error "Cannot remove $f"
}

mk_file()
{
	typeset	f=$1

	echo foo > $f
	[[ $? != 0 ]] && error "Cannot create $f"
}

cp_file()
{
	typeset	f1=$1
	typeset	f2=$2

	cp $f1 $f2
	[[ $? != 0 ]] && error "Cannot copy $f1 to $f2"
	chmod a+rw $f2
}

init_ac()
{
	[[ $ac_ign_flg = TRUE ]] && return

	ACAD_STATE_FILE=`echo $ACAD_DIR/*/state`

	if [[ ! -r "$ACAD_STATE_FILE" ]]
	then
		warning "Cannot find AC adapter state file ($ACAD_STATE_FILE)"
		ACAD_PRESENT=FALSE
		ac_ign_flg=TRUE
	else
		ACAD_PRESENT=TRUE
	fi
	debug "ACAD_STATE_FILE=$ACAD_STATE_FILE"
	debug "ACAD_PRESENT=$ACAD_PRESENT"
}

get_capacity()
{
	typeset	no=$1
	typeset	file=$2
	typeset	name=$3

	[[ $# != 3 ]] && error "INTERNAL ERROR 1"

	typeset	bat_name=${BAT_NAME[no]}
	typeset	is_mah=${BAT_IS_MAH[no]}
	typeset	voltage=${BAT_DESIGN_VOLTAGE[no]}
	typeset	capacity res_capacity

	get_value $file "$name"
	capacity=$VALUE
	if [[ $is_mah = TRUE ]]
	then
		(( res_capacity = capacity * voltage / 1000 ))
	else
		res_capacity=$capacity
	fi
	[[ -z "$res_capacity" ]] && error "$bat_name: cannot get $name"
	VALUE=$res_capacity
}

init_bat()
{
	typeset	dlist
	typeset	dir bat_info bat_state

	if [[ ! -d $BAT_DIR ]]
	then
		error "Cannot access $BAT_DIR directory"
	fi

	dlist=`ls $BAT_DIR`

	BAT_CNT=0

	for d in $dlist
	do
		bat_name=$d
		dir=$BAT_DIR/$d
		bat_info=$dir/info
		bat_state=$dir/state

		if [[ ! -r $bat_info ]]
		then
			warning "Cannot access $bat_info file"
			continue
		fi

		if [[ ! -r $bat_state ]]
		then
			warning "Cannot access $bat_state file"
			continue
		fi
		get_value $bat_info "present"
		if [[ $VALUE != yes ]]
		then
			debug "$bat_name not present, present = $VALUE"
			continue
		fi

		get_value $bat_info "design capacity"
		capacity=$VALUE
		unit=$VALUE2
		[[ -z "$capacity" ]] && error "$bat_name:" \
					"cannot get design capacity"
		[[ -z "$unit" ]] && error "$bat_name:" \
					"cannot get design capacity unit"
		BAT_OLD_UNIT[BAT_CNT]=$unit
		if [[ $unit = mAh ]]
		then
			BAT_IS_MAH[BAT_CNT]=TRUE
			BAT_UNIT[BAT_CNT]=mWh
		elif [[ $unit = mWh ]]
		then
			BAT_IS_MAH[BAT_CNT]=FALSE
			BAT_UNIT[BAT_CNT]=mWh
		else
			warning "$bat_name: unexpected unit = $unit"
			BAT_IS_MAH[BAT_CNT]=FALSE
			BAT_UNIT[BAT_CNT]=$unit
		fi
		get_value $bat_info "design voltage"
		[[ -z "$VALUE" ]] && error "$bat_name: cannot get design voltage"
		BAT_DESIGN_VOLTAGE[BAT_CNT]=$VALUE

		mk_dir $RES_SYSTEM1/$dir
		mk_file $RES_SYSTEM1/$bat_info
		mk_file $RES_SYSTEM1/$bat_state
		mk_dir $RES_SYSTEM2/$dir
		mk_file $RES_SYSTEM2/$bat_info
		mk_file $RES_SYSTEM2/$bat_state

		BAT_DIR_NAME[BAT_CNT]=$dir
		BAT_NAME[BAT_CNT]=$bat_name

		get_capacity $BAT_CNT $bat_info "design capacity"
		BAT_DESIGN_CAPACITY[BAT_CNT]=$VALUE
		get_capacity $BAT_CNT $bat_info "last full capacity"
		BAT_LAST_FULL_CAPACITY[BAT_CNT]=$VALUE
		get_capacity $BAT_CNT $bat_state "remaining capacity"
		BAT_REMAINING_CAPACITY[BAT_CNT]=$VALUE
		BAT_PREV_REMAINING_CAPACITY[BAT_CNT]=$VALUE
		(( BAT_CNT++ ))
	done
	debug "BAT_CNT=$BAT_CNT	BAT_DIR_NAME[]=${BAT_DIR_NAME[*]}"
	if [[ $BAT_CNT == 0 ]]
	then
		error "Battery not found"
	fi
}

select_bat()
{
	BAT_CHECK_NO=0
	if (( BAT_CNT > 1 ))
	then
		echo_log "Computer has $BAT_CNT batteries, specify the battery number"
		select bat in ${BAT_DIR_NAME[*]}
		do
			if [[ ! -z $bat ]]
			then
				BAT_CHECK_DIR_NAME=$bat
				break
			fi
		done
		if [[ -z $BAT_CHECK_DIR_NAME ]]
		then
			error "Completed by user"
		fi
		cnt=0
		for bat in ${BAT_DIR_NAME[*]}
		do
			if [[ $bat = $BAT_CHECK_DIR_NAME ]]
			then
				BAT_CHECK_NO=$cnt
			fi
			((  cnt++ ))
		done
		echo_log "Your choice is $BAT_CHECK_DIR_NAME"
	fi
}

init_cpu_s()
{
	CPU_STAT_FLG=FALSE
	if [[ ! -r $CPU_STAT_NAME ]]
	then
		debug "Cannot access $CPU_STAT_NAME"
		return
	fi
	CPU_STAT_FLG=TRUE
	mk_file $RES_SYSTEM1/$CPU_STAT_NAME
	mk_file $RES_SYSTEM2/$CPU_STAT_NAME
}

init_cpu_t()
{
	CPU_TIMER_FLG=FALSE
	if [[ ! -r $CPU_TIMER_NAME ]]
	then
		debug "Cannot access $CPU_TIMER_NAME"
		return
	fi
	CPU_TIMER_FLG=TRUE
	mk_file $RES_SYSTEM1/$CPU_TIMER_NAME
	mk_file $RES_SYSTEM2/$CPU_TIMER_NAME
}

init_cpu_p()
{
	typeset	dlist
	typeset	dir cpu_file

	if [[ ! -d $CPU_PSTATE_DIR ]]
	then
		warning "Cannot access $CPU_PSTATE_DIR directory"
		return
	fi

	dlist=`ls $CPU_PSTATE_DIR`

	CPU_PSTATE_CNT=0

	for d in $dlist
	do
		cpu_no=${d##*cpu}
		[[ -z $cpu_no ]] && cpu_no=0
		dir=$CPU_PSTATE_DIR/$d/cpufreq/stats
		cpu_file=$dir/time_in_state

		if [[ ! -r $cpu_file ]]
		then
			warning "Cannot access $cpu_file file"
			continue
		fi

		mk_dir $RES_SYSTEM1/$dir
		mk_file $RES_SYSTEM1/$cpu_file
		mk_dir $RES_SYSTEM2/$dir
		mk_file $RES_SYSTEM2/$cpu_file
		CPU_PSTATE_DIR_NAME[CPU_PSTATE_CNT]=$dir
		CPU_PSTATE_NO[CPU_PSTATE_CNT]=$cpu_no
		(( CPU_PSTATE_CNT++ ))
	done
	debug "CPU_PSTATE_CNT=$CPU_PSTATE_CNT	CPU_PSTATE_DIR_NAME[]=${CPU_PSTATE_DIR_NAME[*]}"
}

init_cpu_c()
{
	typeset	dlist
	typeset	dir cpu_file

	if [[ ! -d $CPU_CSTATE_DIR ]]
	then
		warning "Cannot access $CPU_CSTATE_DIR directory"
		return
	fi

	dlist=`ls $CPU_CSTATE_DIR`

	CPU_CSTATE_CNT=0

	for d in $dlist
	do
		cpu_no=${d##*CPU}
		[[ -z $cpu_no ]] && cpu_no=0
		dir=$CPU_CSTATE_DIR/$d
		cpu_file=$dir/power

		if [[ ! -r $cpu_file ]]
		then
			warning "Cannot access $cpu_file file"
			continue
		fi

		mk_dir $RES_SYSTEM1/$dir
		mk_file $RES_SYSTEM1/$cpu_file
		mk_dir $RES_SYSTEM2/$dir
		mk_file $RES_SYSTEM2/$cpu_file
		CPU_CSTATE_DIR_NAME[CPU_CSTATE_CNT]=$dir
		CPU_CSTATE_NO[CPU_CSTATE_CNT]=$cpu_no
		(( CPU_CSTATE_CNT++ ))
	done
	debug "CPU_CSTATE_CNT=$CPU_CSTATE_CNT	CPU_CSTATE_DIR_NAME[]=${CPU_CSTATE_DIR_NAME[*]}"
}

init_cpu()
{
	init_cpu_s
	init_cpu_t
	init_cpu_p
	init_cpu_c
}

init_system()
{
	init_ac
	init_bat
	init_cpu
	sync_system
}

fini_system()
{
	sync_system
}

sync_system()
{
	[[ ! -z "$1" ]] && echo_log "Synchronize ..., $*"
	sync; sync
}

VALUE=
VALUE2=

get_value()
{
	typeset	file=$1
	typeset	name=$2
	typeset	line
	typeset	tmp

	[[ $# != 2 ]] && error "INTERNAL ERROR 2"

	VALUE=
	VALUE2=

	line=`grep "$name:" $file`
	[[ -z "$line" ]] && return
	tmp=${line#*$name:}
	tmp=`echo $tmp`
	if [[ ! -z $tmp ]]
	then
		set $tmp
		VALUE=$1
		VALUE2=$2
		VALUEA=$*
	else
		VALUE=
		VALUE2=
		VALUEA=
	fi
}

waiting()
{
	typeset	tr ts

	echo_log "Wait for $work_time sec"
	[[ $work_time = 0 ]] && return

	sleep $work_time
	return

	tr=$work_time
	while :
	do
		ts=$tr
		(( ts > BAT_CRITICAL_INTERVAL )) && ts=$BAT_CRITICAL_INTERVAL
		do_sleep $ts
		(( tr -= ts ))
		(( tr <= 0 )) && return
		bat_percentage
		debug "remaining capacity: $VALUE%"
		if (( ${VALUE%.*} < BAT_CRITICAL ))
		then
			echo_log "Warning: bat capacity $VALUE% less tnan $BAT_CRITICAL%"
			return
		fi
	done
}

start()
{
	echo_log
	echo_log "********************************************"
	echo_log "* Battery drain rate measurement tool $VERSION"
	echo_log "********************************************"
}

comment()
{
	[[ $COMMENT_CNT = 0 ]] && return
	cnt=0
	while (( cnt < COMMENT_CNT ))
	do
		echo_log "# ${COMMENT[cnt]}"
		(( cnt++ ))
	done
}

report()
{
	typeset	ss=$screen_state
	[[ -z "$COMMENT" ]] && COMMENT=$RES_DIR
	[[ $ss = on ]] && ss=-
	{
	echo "           Manufacturer : $MANUFACTURER"
	echo "           Product Name : $PRODUCT_NAME"
	echo "         System Release : $SYSTEM_RELEASE"
	echo "         Kernel Release : `uname -r`"
	echo "        Work Time (sec) : $work_time_real"
	echo "         Drain Rate (W) : $DRAIN_RATE"
	echo "           Screen State : $ss"
	echo "                Comment : $COMMENT"
	} > $RES_REPORT
}


user_warning()
{
	typeset request

	if [[ $1 = 1 ]]
	then
		echo_log "Please make sure no other load is applied to the system."
		ac_state
		if [[ $AC_STATE = "on-line" ]]
		then
			UNPLUG_AC=TRUE
			beep_start
			echo_log "Unplug the AC cable"
			wait_ac_off
			beep_finish
		fi
		if [[ $screen_state = min ]]
		then
			request=minimal
		elif [[ $screen_state = max ]]
		then
			request=maximal
		elif  [[ $screen_state = on ]]
		then
			request=required
		elif  [[ $screen_state = off-fn ]]
		then
			request=required
		fi
		if [[ $br_ign_flg != TRUE && ! -z $request && $screen_state != off-fn ]]
		then
			beep_start
			echo_log -n "Set screen to $request brigthness" \
					"and press enter ..."
			log
			read foo
			beep_finish
		elif [[ $screen_state = off-fn ]]
		then
			beep_start
			echo_log -n "Press enter, turn of screen via fn key (possible fn+f6)"
			log
			read foo
			beep_finish
		fi
	else
		[[ ! -z $DRAIN_RATE ]] && echo_log "Battery drain rate $DRAIN_RATE W"
		echo_log "Measurements are done."
		if [[ $ac_ign_flg != TRUE && $UNPLUG_AC = TRUE ]]
		then
			ac_state
			if [[ $AC_STATE = "off-line" ]]
			then
				echo_log "Don't forget to plug the AC cable back."
##				wait_ac_on
			fi
		fi
		report
		beep
		echo_log "***************************************"
		echo_log
	fi
}

ac_state()
{
	AC_STATE="off-line"
	[[ $ac_ign_flg = TRUE ]] && return
	get_value $ACAD_STATE_FILE state
	AC_STATE=$VALUE
}

wait_ac_on()
{
	[[ $ac_ign_flg = TRUE ]] && return
	get_value $ACAD_STATE_FILE state
	[[ $VALUE = on-line ]] && return
	while :
	do
		echo_log "Plug in the AC cable"
		beep
		do_sleep 5
		get_value $ACAD_STATE_FILE state
		[[ $VALUE = on-line ]] && return
	done
}

wait_ac_off()
{
	[[ $ac_ign_flg = TRUE ]] && return
	get_value $ACAD_STATE_FILE state
	[[ $VALUE = off-line ]] && return
##	echo_log "Unplug the AC cable"
	while :
	do
		do_sleep 1
		get_value $ACAD_STATE_FILE state
		[[ $VALUE = off-line ]] && return
	done
}

save_bat_files()
{
	typeset	cnt
	typeset	save_dir dir bat_info bat_state
	typeset	dir_tgt bat_info_tgt bat_state_tgt

	if [[ $1 = 1 ]]
	then
		save_dir=$RES_SYSTEM1
	else
		save_dir=$RES_SYSTEM2
	fi

	cnt=0
	while (( cnt < BAT_CNT ))
	do
		dir=${BAT_DIR_NAME[cnt]}
		bat_info=$dir/info
		bat_state=$dir/state
		dir_tgt=$save_dir/$dir
		bat_info_tgt=$dir_tgt/info
		bat_state_tgt=$dir_tgt/state
		cp_file $bat_info $bat_info_tgt
		cp_file $bat_state $bat_state_tgt
		(( cnt++ ))
	done
}

save_cpu_timer_files()
{
	[[ $CPU_TIMER_FLG != TRUE ]] && return
	if [[ $1 = 1 ]]
	then
		save_dir=$RES_SYSTEM1
	else
		save_dir=$RES_SYSTEM2
	fi
	cp_file $CPU_TIMER_NAME $save_dir/$CPU_TIMER_NAME
}

save_cpu_stat_files()
{
	[[ $CPU_STAT_FLG != TRUE ]] && return
	if [[ $1 = 1 ]]
	then
		save_dir=$RES_SYSTEM1
	else
		save_dir=$RES_SYSTEM2
	fi
	cp_file $CPU_STAT_NAME $save_dir/$CPU_STAT_NAME
}

save_cpu_pstate_files()
{
	typeset	cnt
	typeset	save_dir dir cpu_file
	typeset	dir_tgt cpu_file_tgt

	if [[ $1 = 1 ]]
	then
		save_dir=$RES_SYSTEM1
	else
		save_dir=$RES_SYSTEM2
	fi

	cnt=0
	while (( cnt < CPU_PSTATE_CNT ))
	do
		dir=${CPU_PSTATE_DIR_NAME[cnt]}
		cpu_file=$dir/time_in_state
		dir_tgt=$save_dir/$dir
		cpu_file_tgt=$dir_tgt/time_in_state
		cp_file $cpu_file $cpu_file_tgt
		(( cnt++ ))
	done
}

save_cpu_cstate_files()
{
	typeset	cnt
	typeset	save_dir dir cpu_file
	typeset	dir_tgt cpu_file_tgt

	if [[ $1 = 1 ]]
	then
		save_dir=$RES_SYSTEM1
	else
		save_dir=$RES_SYSTEM2
	fi

	cnt=0
	while (( cnt < CPU_CSTATE_CNT ))
	do
		dir=${CPU_CSTATE_DIR_NAME[cnt]}
		cpu_file=$dir/power
		dir_tgt=$save_dir/$dir
		cpu_file_tgt=$dir_tgt/power
		cp_file $cpu_file $cpu_file_tgt
		(( cnt++ ))
	done
}

save_cpu_files()
{
	save_cpu_timer_files $1
	save_cpu_pstate_files $1
	save_cpu_cstate_files $1
	save_cpu_stat_files $1
}

save_files()
{
	if [[ $1 = 1 ]]
	then
		save_bat_files $1
		save_cpu_files $1
	else
		save_cpu_files $1
		save_bat_files $1
	fi
}

set_screen()
{
	xset dpms 0 0 0
	if [[ $1 = 1 ]]
	then
		echo_log "Screen state: $screen_state"
		if [[ $screen_state != min && $screen_state != max && $screen_state != on && $screen_state != off-fn ]]
		then
			sleep 1
			xset dpms force $screen_state 2>$STDERR
			if [[ $? != 0 || -s $STDERR ]]
			then
				cat $STDERR
				error "xset dpms force $screen_state failed"
			fi
		fi
	else
		xset dpms force on
	fi
}

beep()
{
	typeset	num=$1 cnt=0

	[[ -z $num ]] && (( num = 1 ))

	while (( cnt < num ))
	do
		printf "\a"
		[[ $num = 1 ]] && return
		do_sleep 1
		(( cnt++ ))
	done
}

FORMAT="%2s %8s %8s %8s %8s %8s %8s %8s %8s %s\n"

print_stat_line()
{
	typeset	iter=$1
	typeset	full_time=$2
	typeset	delta_time=$3
	typeset	capacity2=$4
	typeset	delta=$5
	typeset	full_delta=$6
	typeset	full_rate=$7
	typeset	rate=$8
	typeset	percents=$9
	typeset	unit=${10}
	typeset	disp

	disp=`xset q | grep Monitor`
	disp=${disp#*Monitor is }

	if (( iter == 0 ))
	then
		echo_log "time/d_time - seconds, bat/d_bat - mWh," \
				"rate/c_rate - W, life - %"
	fi

	if (( iter % 100 == 0 ))
	then
		f_echo_log \
			"$FORMAT" \
			"T:" "iter" "time" "d_time" \
			"bat" "d_bat" "rate" "c_rate" \
			"life" "disp"
	fi
	f_echo_log \
		"$FORMAT" \
		"S:" "$iter" "$full_time" "$delta_time" \
		"$capacity2" "$delta" "$full_rate" "$rate" \
		"$percents" "$disp"
}

check_bat_update()
{
	typeset	no=$1
	typeset	start_time=$SECONDS
	typeset	dir unit capacity1 capacity2 delta rate iter

	bat_name=${BAT_NAME[no]}
	dir=${BAT_DIR_NAME[no]}
	bat_state=$dir/state
	unit=${BAT_UNIT[no]}
	iter=0

	critical_time=$SECONDS
	while :
	do
		time2=$SECONDS
		time1=${SAVED_TIME[no]}
		get_capacity $no $bat_state "remaining capacity"
		capacity2=$VALUE
		capacity1=${SAVED_CAPACITY[no]}
		if [[ -z $capacity1 ]]
		then
			time1=$time2
			capacity1=$capacity2
			SAVED_CAPACITY[no]=$capacity2
			SAVED_TIME[no]=$time2
			START_CAPACITY[no]=$capacity2
			START_TIME[no]=$time2
		fi
		(( delta_time = time2 - time1 ))
		(( delta = capacity1 - capacity2 ))
		bat_percentage $no
		percents=$VALUE
		if (( ${percents%.*} < BAT_CRITICAL ))
		then
			critical_time=$SECONDS
			TIME2=$SECONDS
			echo_log "Warning: remaining" \
					"capacity $percents%" \
					"less tnan $BAT_CRITICAL%"
			save_time 2
			save_files 2
			analyser
			sync_system "critical capacity $percents%"
			CRITICAL_FLG=TRUE
			(( BAT_CRITICAL = BAT_CRITICAL - 1 ))
			prt_line_flg=TRUE
		fi
		prt_line_flg=FALSE
		if (( SECONDS - critical_time >= BAT_CRITICAL_INTERVAL ))
		then
			if [[ $CRITICAL_FLG = TRUE ]]
			then
				sync_system "critical time $BAT_CRITICAL_INTERVAL sec"
			fi
			prt_line_flg=TRUE
		fi
		if [[ $delta != 0 || $iter = 0 || $prt_line_flg = TRUE ]]
		then
			(( full_delta = START_CAPACITY[no] - capacity2 ))
			(( full_time = time2 - START_TIME[no] ))
			if (( delta_time != 0 ))
			then
				rate=`\
					echo "scale=2; ( $delta * 3600 ) / ( $delta_time * 1000 )" | bc`
			else
				rate=0
			fi
			if (( full_time != 0 ))
			then
				full_rate=`\
					echo "scale=2; ( $full_delta * 3600 ) / ( $full_time * 1000 )" | bc`
			else
				full_rate=0
			fi
			print_stat_line \
				"$iter" \
				"$full_time" "$delta_time" \
				"$capacity2" "$delta" "$full_delta" \
				"$full_rate" "$rate" \
				"$percents" "$unit"
			SAVED_CAPACITY[no]=$capacity2
			SAVED_TIME[no]=$time2
			critical_time=$SECONDS
			(( iter++ ))
		fi
		if [[ $num_flg = TRUE ]]
		then
			(( iter >= num_value )) && break
		elif [[ $work_time_flg = TRUE ]]
		then
			(( SECONDS - start_time >= work_time )) && break
		fi
		do_sleep $BAT_CHECK_UPDATE_INTERVAL
	done
}

wait_bat_update()
{
	typeset	first=$1
	typeset	no=$2
	typeset	start_time wait_time dir bat_state
	typeset	capacity1 capacity2 delta speep_cnt=0

	[[ $# != 2 ]] && error "INTERNAL ERROR 3"

	start_time=$SECONDS

	if [[ $up_ign_flg = TRUE ]]
	then
		return
	fi

	if [[ $first = 1 ]]
	then
		echo_log -n "Wait for battery capacity update" \
				"to start the test ... "
	else
		echo_log -n "Wait for battery capacity update" \
				"to finish the test ... "
	fi

	dir=${BAT_DIR_NAME[no]}
	bat_state=$dir/state

	while :
	do
		get_capacity $no $bat_state "remaining capacity"
		capacity2=$VALUE
		[[ -z $capacity1 ]] && capacity1=$capacity2
		(( delta = capacity1 - capacity2 ))
		(( delta != 0 )) && break
		do_sleep 1
		(( do_sleep_cnt++ ))
	done

	(( wait_time = SECONDS - start_time ))
	echo_log "$wait_time sec"
}

bat_charging_state()
{
	typeset	no=$1
	typeset	dir bat_info

	dir=${BAT_DIR_NAME[no]}
	bat_info=$dir/info
	get_value $bat_info "charging state"
	VALUE=$VALUEA
}

bat_model()
{
	typeset	no=$1
	typeset	dir bat_info

	dir=${BAT_DIR_NAME[no]}
	bat_info=$dir/info
	get_value $bat_info "model number"
	VALUE=$VALUEA
}

bat_percentage()
{
	typeset	no=$1
	typeset	cnt
	typeset	dir des_capacity capacity percents=0

	if [[ ! -z $no ]]
	then
		(( cnt = no ))
		(( bat_cnt = no + 1 ))
	else
		(( cnt = 0 ))
		(( bat_cnt = BAT_CNT ))
	fi

	while (( cnt < bat_cnt ))
	do
		dir=${BAT_DIR_NAME[cnt]}
		bat_state=$dir/state
		bat_info=$dir/info
		get_capacity $cnt $bat_state "remaining capacity"
		capacity=$VALUE
		get_capacity $cnt $bat_info "design capacity"
		des_capacity=$VALUE
		percentage $des_capacity $capacity
		percents=`echo "scale=2; $percents + $VALUE" | bc`
		(( cnt++ ))
	done
	VALUE=$percents
	[[ "$VALUE" == .* ]] && VALUE="0$VALUE"
}

percentage()
{
	typeset	v100=$1
	typeset	v=$2

	if [[ $v100 != 0 ]]
	then
		VALUE=`echo "scale=2; ( $v * 100 ) / ( $v100 )" | bc`
		[[ "$VALUE" == .* ]] && VALUE="0$VALUE"
	else
		VALUE=0
	fi
}

print_bat_info()
{
	cnt=0
	while (( cnt < BAT_CNT ))
	do
		bat_name=${BAT_NAME[cnt]}
		bat_model $cnt
		model=$VALUE
		bat_percentage $cnt
		echo_log "$bat_name: $model, $VALUE% charged"
		(( cnt++ ))
	done
}
work_idle_action()
{
	START_FLG=TRUE
	if [[ $check_bat_update_flg = TRUE ]]
	then
		check_bat_update $BAT_CHECK_NO
	else
		waiting
	fi
}

trap 'trap_action 1; exit 1' 1 2 3 6 15

trap_action()
{
	beep_finish
	[[ $START_FLG != TRUE ]] && exit 1
	save_time 2
	save_files 2
	analyser
	set_screen 2
	fini_system
	user_warning 2
}

bat_analyser()
{
	typeset	cnt
	typeset	dir unit capacity1 capacity2
	typeset	delta drain des_capacity life voltage

	w=$work_time_real

	cnt=0
	while (( cnt < BAT_CNT ))
	do
		bat_name=${BAT_NAME[cnt]}
		dir=${BAT_DIR_NAME[cnt]}
		dir1=$RES_SYSTEM1$dir
		dir2=$RES_SYSTEM2$dir
		bat_info1=$dir1/info
		bat_info2=$dir2/info
		bat_state1=$dir1/state
		bat_state2=$dir2/state
		unit=${BAT_UNIT[cnt]}
		get_capacity $cnt $bat_state1 "remaining capacity"
		capacity1=$VALUE
		get_capacity $cnt $bat_state2 "remaining capacity"
		capacity2=$VALUE
		get_capacity $cnt $bat_info2 "design capacity"
		des_capacity=$VALUE
		(( delta = capacity1 - capacity2 ))
		echo_log "$bat_name"
		percentage $des_capacity $des_capacity
		echo_log " design capacity: $des_capacity $unit, $VALUE%"
		percentage $des_capacity $capacity1
		echo_log " start capacity: $capacity1 $unit, $VALUE%"
		percentage $des_capacity $capacity2
		echo_log " finish capacity: $capacity2 $unit, $VALUE%"
		percentage $des_capacity $delta
		echo_log " capacity drain: $delta $unit, $VALUE%"
		drain=`echo "scale=2; $delta / $w" | bc`
		drain2=`echo "scale=2; ( $delta * 3600 ) / ( $w * 1000 )" | bc`
		echo_log " drain rate: $drain2 W"
		DRAIN_RATE="$drain2"
		if (( delta != 0 ))
		then
			life=`echo "scale=2; $des_capacity / $drain" | bc`
			life=`echo "scale=0; $life / 60" | bc`
			life1=`echo "scale=2; $capacity2 / $drain" | bc`
			life1=`echo "scale=0; $life1 / 60" | bc`
#			time_min $life
			echo_log " design battery life: $life min"
#			time_min $life1
			echo_log " remaining battery life: $life1 min"
		fi
		(( cnt++ ))
	done
}

cpu_stat_analyser()
{
	w=$work_time_real
	[[ $CPU_STAT_FLG != TRUE ]] && return

	cnt=-1
	while (( cnt <= 16 ))
	do
		if (( cnt == -1 ))
		then
			no=
		else
			no=$cnt
		fi
		str1=`grep "cpu$no " $RES_SYSTEM1/$CPU_STAT_NAME`
		[[ $? != 0 ]] && break
		str2=`grep "cpu$no " $RES_SYSTEM2/$CPU_STAT_NAME`
		[[ $? != 0 ]] && break
		(( cnt++ ))
		set $str1
		(( load1 = $2 + $4 ))
		(( comm1 = $2 + $3 + $4 + $5 + $6 ))
		set $str2
		(( load2 = $2 + $4 ))
		(( comm2 = $2 + $3 + $4 + $5 + $6 ))
		(( load = load2 - load1 ))
		(( comm = comm2 - comm1 ))
		percentage $comm $load
		(( load = load / w ))
		(( comm = comm / w ))
		echo_log "CPU$no"
		echo_log " load: $VALUE%"
#		echo_log " load: $VALUE%, load $load, sum $comm"
	done
}

cpu_timer_analyser()
{
	w=$work_time_real
	[[ $CPU_TIMER_FLG != TRUE ]] && return
	cpu_cnt=0
	timer_cnt=0
	while read line
	do
		if [[ "$line" == *"CPU"* ]]
		then
			list=
			first=TRUE
			for n in $line
			do
				if [[ $first = TRUE ]]
				then
					list="$n"
					first=FALSE
				else
					list="$list, $n"
				fi
			done
			CPU_TIMER_NAME1[cpu_cnt]="$list"
			(( cpu_cnt++ ))
		elif [[ "$line" == *" timer" ]]
		then
			t=`echo "$line" | awk '{ print $2 }'`
			CPU_TIMER1[timer_cnt]="$t"
			(( timer_cnt++ ))
		fi
	done < $RES_SYSTEM1/$CPU_TIMER_NAME
	debug CPU_TIMER_NAME1 ${CPU_TIMER_NAME1[*]}
	debug CPU_TIMER1 ${CPU_TIMER1[*]}
	TT_CNT1=$timer_cnt
	if (( cpu_cnt != timer_cnt ))
	then
		warning "Cannot determine CPU timer"
		debug "ERROR CPU TIMER 1: cpu_cnt=$cpu_cnt, timer_cnt=$timer_cnt"
		return
	fi
	cpu_cnt=0
	timer_cnt=0
	while read line
	do
		if [[ "$line" == *"CPU"* ]]
		then
			CPU_TIMER_NAME2[cpu_cnt]="$line"
			(( cpu_cnt++ ))
		elif [[ "$line" == *" timer" ]]
		then
			t=`echo "$line" | awk '{ print $2 }'`
			CPU_TIMER2[timer_cnt]="$t"
			(( timer_cnt++ ))
		fi
	done < $RES_SYSTEM2/$CPU_TIMER_NAME
	debug CPU_TIMER_NAME2 ${CPU_TIMER_NAME2[*]}
	debug CPU_TIMER2 ${CPU_TIMER2[*]}
	TT_CNT2=$timer_cnt
	if (( cpu_cnt != timer_cnt ))
	then
		warning "Cannot determine CPU timer"
		debug "ERROR CPU TIMER 2: cpu_cnt=$cpu_cnt, timer_cnt=$timer_cnt"
		return
	fi
	if (( TT_CNT1 != TT_CNT2 ))
	then
		warning "Cannot determine CPU timer"
		debug "ERROR CPU TIMER 3: TT_CNT1=$TT_CNT1, TT_CNT2=$TT_CNT2"
		return
	fi

	c=0
	while (( c < TT_CNT1 ))
	do
		(( t = (CPU_TIMER2[c] - CPU_TIMER1[c]) / w ))
		T_N_STR[c]="${CPU_TIMER_NAME1[c]}"
		T_V_STR[c]="$t"
		echo_log "${T_N_STR[c]}"
		echo_log " timer: ${T_V_STR[c]}"
		(( c++ ))
	done
}

cpu_pstate_analyser()
{
	typeset	cnt

	cnt=0
	while (( cnt < CPU_PSTATE_CNT ))
	do
		cpu_no=${CPU_PSTATE_NO[cnt]}
		cpu_pstate_analyser_1 $cnt
		s1="${P_N_STR[cnt]}"
		if [[ ! -z "$s1" ]]
		then
			echo_log "CPU$cpu_no"
			echo_log " ${P_N_STR[cnt]}"
			echo_log " ${P_F_STR[cnt]}"
			echo_log " ${P_V_STR[cnt]}"
		fi
		(( cnt++ ))
	done

}

cpu_pstate_analyser_1()
{
	typeset	cnt=$1
	typeset	dir val1 val2

	w=$work_time_real

	P_N_STR[cnt]=
	P_F_STR[cnt]=
	P_V_STR[cnt]=
	cpu_no=${CPU_PSTATE_NO[cnt]}
	dir=${CPU_PSTATE_DIR_NAME[cnt]}
	dir1=$RES_SYSTEM1$dir
	dir2=$RES_SYSTEM2$dir
	cpu_file1=$dir1/time_in_state
	cpu_file2=$dir2/time_in_state
	c=0
	while read p t
	do
		P1[c]=$p
		T1[c]=$t
		(( c++ ))
	done < $cpu_file1
	debug "P1[]=${P1[*]}"
	debug "T1[]=${T1[*]}"
	c=0
	while read p t
	do
		P2[c]=$p
		T2[c]=$t
		(( c++ ))
	done < $cpu_file2
	c_cnt=$c
	debug "P2[]=${P2[*]}"
	debug "T2[]=${T2[*]}"
	spt=0
	st=0
	st1=0
	c=0
	while (( c < c_cnt ))
	do
		p=${P1[c]}
		t1=${T1[c]}
		t2=${T2[c]}
		(( t = (t2 - t1) ))
		(( spt += p * t ))
		(( st += t ))
		(( t = t / w ))
		(( st1 += t ))
		if (( c == 0 ))
		then
			P_N_STR[cnt]="`printf '%8s' P$c`"
			P_F_STR[cnt]="`printf '%8i' $p`"
			P_V_STR[cnt]="`printf '%8i' $t`"
		else
			P_N_STR[cnt]="${P_N_STR[cnt]} `printf '%8s' P$c`"
			P_F_STR[cnt]="${P_F_STR[cnt]} `printf '%8i' $p`"
			P_V_STR[cnt]="${P_V_STR[cnt]} `printf '%8i' $t`"
		fi
		(( c++ ))
	done
	if (( st == 0 ))
	then
		f="-"
	else
		(( f = spt / st ))
	fi
	P_N_STR[cnt]="${P_N_STR[cnt]} `printf '%8s' Sum`"
	P_F_STR[cnt]="${P_F_STR[cnt]} `printf '%8i' $f`"
	P_V_STR[cnt]="${P_V_STR[cnt]} `printf '%8i' $st1`"
}

rm_lead_0()
{
	typeset	v=$1

	while :
	do
		if [[ "$v" == 0* ]]
		then
			v=${v#0}
		else
			break
		fi
	done
	[[ -z $v ]] && v=0
	ZVALUE=$v
}

cpu_cstate_analyser()
{
	typeset	cnt

	cnt=0
	while (( cnt < CPU_CSTATE_CNT ))
	do
		cpu_no=${CPU_CSTATE_NO[cnt]}
		cpu_cstate_analyser_1 $cnt
		s1="${C_N_STR[cnt]}"
		if [[ ! -z "$s1" ]]
		then
			echo_log "CPU$cpu_no"
			echo_log " ${C_N_STR[cnt]}"
			echo_log " ${C_V_STR[cnt]}"
		fi
		(( cnt++ ))
	done
}

cpu_cstate_analyser_1()
{
	typeset	cnt=$1
	typeset	dir val1 val2

	w=$work_time_real

	C_N_STR[cnt]=
	C_V_STR[cnt]=
	cpu_no=${CPU_CSTATE_NO[cnt]}
	dir=${CPU_CSTATE_DIR_NAME[cnt]}
	dir1=$RES_SYSTEM1$dir
	dir2=$RES_SYSTEM2$dir
	cpu_file1=$dir1/power
	cpu_file2=$dir2/power
	(( c = 1 ))
	while read ln
	do
		[[ "$ln" != *usage* ]] && continue
		u=${ln##*usage[}
		u=${u%%]*}
		C1[c]=$u
		(( c++ ))
	done < $cpu_file1
	(( c = 1 ))
	while read ln
	do
		[[ "$ln" != *usage* ]] && continue
		u=${ln##*usage[}
		u=${u%%]*}
		C2[c]=$u
		(( c++ ))
	done < $cpu_file2
	c_cnt=$c
	debug "C1[]=${C1[*]}"
	debug "C2[]=${C2[*]}"
	us=0
	(( c = 1 ))
	while (( c < c_cnt ))
	do
		u1=${C1[c]}
		rm_lead_0 $u1; u1=$ZVALUE
		u2=${C2[c]}
		rm_lead_0 $u2; u2=$ZVALUE
		(( ux = u2 - u1 ))
#		(( us = us + ux ))
		(( u = ux  / w ))
		(( us = us + u ))
		if (( c == 1 ))
		then
			C_N_STR[cnt]="`printf '%8s' C$c`"
			C_V_STR[cnt]="`printf '%8i' $u`"
		else
			C_N_STR[cnt]="${C_N_STR[cnt]} `printf '%8s' C$c`"
			C_V_STR[cnt]="${C_V_STR[cnt]} `printf '%8i' $u`"
		fi
		(( c++ ))
	done
#	(( us = us  / w ))
	C_N_STR[cnt]="${C_N_STR[cnt]} `printf '%8s' Sum`"
	C_V_STR[cnt]="${C_V_STR[cnt]} `printf '%8i' $us`"
}

time_sec()
{
	typeset	tm=$1 hh mm ss

	(( hh = tm / 3600 ))
	(( mm = (tm - hh * 3600) / 60 ))
	(( ss = tm % 60 ))
	VALUE=`printf "%i:%02i:%02i" $hh $mm $ss`
}

time_min()
{
	typeset	tm=$1 hh mm

	(( hh = tm / 60 ))
	(( mm = tm % 60 ))
	VALUE=`printf "%i:%02i" $hh $mm`
}

analyser()
{
	(( work_time_real = TIME2 - TIME1 ))
	(( work_time_real == 0 )) && (( work_time_real = 1 ))
	(( hh = work_time_real / 3600 ))
	(( mm = (work_time_real - hh * 3600) / 60 ))
	(( ss = work_time_real % 60 ))
	echo_log "TIME"
#	time_sec $work_time_real
	echo_log " measurement time: $work_time_real sec"
	bat_analyser
	[[ $CPU_LOAD_FLG = TRUE ]] && cpu_stat_analyser
	cpu_timer_analyser
	cpu_pstate_analyser
	cpu_cstate_analyser
}

save_time()
{
	if [[ $1 = 1 ]]
	then
		TIME1=$SECONDS
		echo $TIME1  > $RES_SYSTEM1/TIME1
	else
		TIME2=$SECONDS
		echo $TIME2  > $RES_SYSTEM2/TIME2
	fi
}

left_work()
{
	if [[ $bat_percentage_flg = TRUE ]]
	then
		init_system
		print_bat_info
		exit $?
	fi
}

right_work()
{
	start
	comment
	init_system
	print_bat_info
	select_bat
	user_warning 1
	wait_ac_off
	set_screen 1
	wait_bat_update 1 $BAT_CHECK_NO
	echo_log "Start"
	init_user
	save_files 1
	save_time 1
	work_idle_action
	wait_bat_update 2 $BAT_CHECK_NO
	save_time 2
	save_files 2
	fini_user
	set_screen 2
	echo_log "Finish"
	analyser
	fini_system
	user_warning 2
}

init_user()
{
	[[ -z "$init_user_cmd" ]] && return
	echo_log "$init_user_cmd"
	$init_user_cmd
}

fini_user()
{
	[[ -z "$fini_user_cmd" ]] && return
	echo_log "$fini_user_cmd"
	$fini_user_cmd
}

bat_startup()
{
	if [[ -x $BLTK_SUDO ]]
	then
		$BLTK_SUDO modprobe cpufreq_stats >/dev/null 2>&1
	fi
}

bat_startup

init_srgs "$@"

if [[ $left_work_flg = TRUE ]]
then
	left_work
else
	right_work
fi

exit 0
