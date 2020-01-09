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

BLTK_GET_STAT_CMD="$BLTK_BIN/bltk_get_stat $stat_ign_lines_arg"
BLTK_CALC_CMD=$BLTK_BIN/bltk_calc

ERR_IGN=

ERROR_CNT=0
ERROR_ARR=
WARNING_CNT=0
WARNING_ARR=

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
	ERROR_ARR[ERROR_CNT]="$*"
	(( ERROR_CNT++ ))
	if [[ -z $ERR_IGN ]]
	then
		echo "ERROR: $*" >&2
		exit 1
	else
		echo "ERROR ignored: $*" >&2
	fi
	echo "	" >&2
}

warning_msg()
{
	echo "Warning: $*" >&2
}

warning()
{
	WARNING_ARR[WARNING_CNT]="$*"
	(( WARNING_CNT++ ))
	if [[ ! -z $results ]]
	then
		warning_msg "Result directory is $results" >&2
	fi
	echo "Warning: $*" >&2
	echo "	" >&2
}

REPORT=

OPTIONS="hdr:s:b:c:oU:B:D:C:P:K:fI0R:12:34:EiS"

usage()
{
	cat >&2 << EOF

Usage:	$PROG [-$OPTIONS] directory...
	Type $PROG -h to get more information

EOF
}

common_usage()
{
	cat >&2 << EOF

Usage:	$PROG [-$OPTIONS] directory...

	-h		usage
	-o		print report to output
	-K string	comment string
	-f		results directory name will be used as a comment
	-R filename	argument will be used as report file name
	-1		first statistic item of score file is ignored
	-2 item:num	statistic from item 'item', 'num' number of score file
	-3		first statistic item of stat.log file is ignored
	-4 item:num	statistic from item 'item', 'num' number of stat.log file
	-E		errors being ignored (allows to create report file anyway)
	-i		idle mode

	directory ...	result directories list

	Other options are reserved for internal purposes

Example:
---------
	bltk_report result
		'Report' file will be generated in results directory

EOF
}

full_bat_life_flg=TRUE

CPU_C_STATES_NUM_AUTO=TRUE
CPU_P_STATES_NUM_AUTO=TRUE

MAX_CPU_C_STATES_NUM=16
MAX_CPU_P_STATES_NUM=16

ign_lines_flg=FALSE
ign_lines_arg=

rating_flg=TRUE
sum_flg=TRUE

bat_ignore=FALSE

while getopts $OPTIONS OPT
do
	case $OPT in
		h ) common_usage; exit 0;;
		d ) DEBUG=TRUE;;
		o ) OUTPUT=TRUE;;
		r ) rating_flg=$OPTARG;;
		s ) sum_flg=$OPTARG;;
		b ) rating_flg=TRUE; base_arg=$OPTARG;;
		c ) rating_flg=TRUE; calibr_arg=$OPTARG;;
		U ) CPU_COMMON_NUM="$OPTARG";;
		B ) BAT_COMMON_NUM="$OPTARG";;
		D ) HD_COMMON_NUM="$OPTARG";;
		C ) CPU_C_STATES_NUM="$OPTARG"; CPU_C_STATES_NUM_AUTO=FALSE;;
		P ) CPU_P_STATES_NUM="$OPTARG"; CPU_P_STATES_NUM_AUTO=FALSE;;
		K ) comment_flg=TRUE; COMMENT="$OPTARG";;
		f ) fname_comment_flg=TRUE;;
		I ) full_bat_life_flg=FALSE;;
		0 ) null_finish_bat_life_flg=TRUE;;
		R ) REPORT="$OPTARG";;
		1 ) ign_lines_flg=TRUE; ign_lines_arg="-1";;
		2 ) ign_lines_flg=TRUE; ign_lines_arg="-2 $OPTARG";;
		3 ) stat_ign_lines_flg=TRUE; stat_ign_lines_arg="-1";;
		4 ) stat_ign_lines_flg=TRUE; stat_ign_lines_arg="-2 $OPTARG";;
		E ) ERR_IGN="-E";;
		i ) idle_test_mode=TRUE;;
		S ) split_mode=TRUE;;
		* ) usage; exit 2;;
	esac
done

shift $((OPTIND-1))

if [[ $CPU_C_STATES_NUM_AUTO = TRUE ]]
then
	CPU_C_STATES_NUM=$MAX_CPU_C_STATES_NUM
fi

if [[ $CPU_P_STATES_NUM_AUTO = TRUE ]]
then
	CPU_P_STATES_NUM=$MAX_CPU_P_STATES_NUM
fi

DEBUG_TIME=$SECONDS

debug()
{
	typeset t t1

	if [[ $DEBUG = 1 || $DEBUG = TRUE ]]
	then
		(( t1 = SECONDS ))
		(( t = t1 - DEBUG_TIME ))
		(( DEBUG_TIME = t1 ))
		echo "DEBUG: $t: $*" >&2
	fi
}

debug2()
{
	echo "DEBUG2:  $*" >&2
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

VALUE=

get_value()
{
	typeset name=$1
	typeset add=$2
	typeset file=$info
	typeset line

	VALUE=
	line=`grep "^$name = " $file | tail -1`
	### echo line=$line >&2
	[[ -z "$line" ]] && return
	VALUE=${line#$name = }
	[[ ! -z "$add" ]] && VALUE="$VALUE $add"
	### echo VALUE=+"$VALUE"+ >&2
}

HEAD_WIDTH=32

print_head()
{
	typeset head="$1"
	typeset size

	size=${#head}
	(( size = (size + 1) / 2 ))
	(( size = HEAD_WIDTH + size + 1 ))
	printf "%${size}s\n" "$head"
}

print_item()
{
	if [[ ! -z "$2" ]]
	then
		if [[ ! -z "$3" ]]
		then
			if [[ "$3" = "%" ]]
			then
				printf "%${HEAD_WIDTH}s : %0s %s\n" "$1" "$2$3"
			else
				printf "%${HEAD_WIDTH}s : %0s %s\n" "$1" "$2" "$3"
			fi
		else
			printf "%${HEAD_WIDTH}s : %0s\n" "$1" "$2"
		fi
	else
		printf "%${HEAD_WIDTH}s : %0s\n" "$1" "-"
	fi
}

print_line()
{
	printf "%${HEAD_WIDTH}s\n" "$*"
}

print_workload()
{
	typeset workload

	workload=`cat $results/workload`
	print_head "Workload"
	print_item "Workload"	"$workload"
}

print_rating()
{
	typeset base
	typeset calibr
	typeset iter_num=
	typeset base_list
	typeset work_list
	typeset response_list
	typeset score_list
	typeset work_sum
	typeset response_sum
	typeset score_sum
	typeset work_val
	typeset response_val
	typeset score_val
	typeset tm
	typeset var
	typeset var2
	typeset ret
	typeset time_list
	typeset time_val
	typeset iter_real
	typeset xtime_val
	typeset xwork_val
	typeset xresponse_val

	tm="$TIME_MIN"

	print_head "Rating"
	if [[ $bat_ignore != TRUE ]]
	then
		if [[ "$tm" == "-"* ]]
		then
			warning "Battery Rating is negative"
		fi
		if [[ $split_mode != TRUE ]]
		then
			print_item "Battery Rating"	"$tm min ($TIME_HH_MM_SS)"
		else
			print_item "Battery Rating (min)"	"$tm"
			print_item "Battery Rating (h:m:s)"	"$TIME_HH_MM_SS"
		fi
	fi

	if [[ $idle_test_mode = TRUE ]]
	then
		return
	fi
	if [[ -r $score ]]
	then
		iter_num=`$BLTK_GET_STAT_CMD $ign_lines_arg -s $score -N`
		if [[ $? != 0 ]]
		then
			warning "Cannot get num iterations: file score corrupted"
			iter_num=
		fi
	fi
	if [[ -r $score && -z $iter_num ]]
	then
		warning "Cannot get num iterations: file score corrupted"
	fi

	if [[ -r $score && ! -z $iter_num ]]
	then
		if [[ ! -z $base_arg ]]
		then
			base=$base_arg
		else
			base=`grep ^base $score`
			base=${base#base}
			base=`echo $base`
		fi
		if [[ ! -z $calibr_arg ]]
		then
			calibr=$calibr_arg
		else
			calibr=`grep ^calibr $score`
			calibr=${calibr#calibr}
			calibr=`echo $calibr`
		fi

#		[[ -z $calibr ]] && calibr=1
		[[ -z $base ]] && base=score

		iter_num=`$BLTK_GET_STAT_CMD $ign_lines_arg -s $score -N`
		if [[ $? != 0 ]]
		then
			error "Cannot get num iterations: file score corrupted"
		fi
		time_list=`$BLTK_GET_STAT_CMD $ign_lines_arg -s $score -a time`
		full_time_list=`$BLTK_GET_STAT_CMD -s $score -a time`
		work_list=`$BLTK_GET_STAT_CMD $ign_lines_arg -s $score -a work`
		ret=`$BLTK_GET_STAT_CMD $ign_lines_arg -s $score -c response`
		if [[ $? = 0 ]]
		then
			response_list=`$BLTK_GET_STAT_CMD $ign_lines_arg -s $score -a response`
		else
			ret=`$BLTK_GET_STAT_CMD $ign_lines_arg -s $score -c reply`
			if [[ $? = 0 ]]
			then
				response_list=`$BLTK_GET_STAT_CMD $ign_lines_arg -s $score -a reply`
			else
				error "Cannot get scores, file $score corrupted"
				return
			fi
		fi
		if [[ $rating_flg = TRUE && $base != no ]]
		then
			base_list=`$BLTK_GET_STAT_CMD $ign_lines_arg -s $score -a $base`
			if [[ $sum_flg = TRUE ]]
			then
				if [[ ! -z $calibr ]]
				then
					calc "*f" $calibr 100 $iter_num
					var=$CALC_RES
					calc "+f" $base_list
					var2=$CALC_RES
					calc "/f" $var $var2
					var=$CALC_RES
					calc "*f" $var $iter_num
					score_list=$CALC_RES
				else
					calc "+f" $base_list
					score_list=$CALC_RES
				fi
			else
				for var in $base_list
				do
					if [[ ! -z $calibr ]]
					then
						calc "*f" $calibr 100
						var2=$CALC_RES
						calc "/f" $var2 $var
						var=$CALC_RES
						score_list="$score_list $var"
					else
						score_list="$score_list $var"
					fi
				done
			fi
		elif [[ $base != no ]]
		then
			score_list=`$BLTK_GET_STAT_CMD $ign_lines_arg -s $score -a score`
		fi
		calc "+f" $time_list
		time_sum=$CALC_RES
		calc "+f" $full_time_list
		full_time_sum=$CALC_RES
		calc "/f2" $time_sum $iter_num
		time_val=$CALC_RES
		calc "+f" $work_list
		work_sum=$CALC_RES
		calc "+f" $response_list
		response_sum=$CALC_RES
		if [[ base != no ]]
		then
			calc "+f" $score_list
			score_sum=$CALC_RES
		fi
		calc "/f2" $work_sum $iter_num
		work_val=$CALC_RES
		calc "/f2" $response_sum $iter_num
		response_val=$CALC_RES
		if [[ $base != no ]]
		then
			calc "/f2" $score_sum $iter_num
			score_val=$CALC_RES
		else
			score_val=-
		fi
		calc "-f" $TIME_SEC $full_time_sum
		time_rem=$CALC_RES
		calc "Ll" $time_rem 0
		if [[ $CALC_RES != TRUE && $ign_lines_arg != *:* ]]
		then
			calc "/f2" $time_rem $time_val
			iter_rem=$CALC_RES
			calc "Ll" 1.5 $iter_rem
			if [[ $CALC_RES = TRUE ]]
			then
				warning "Incorrect iterations number (check times in log files)"
			fi
			calc "+f2" $iter_num $iter_rem
			iter_num=$CALC_RES
		else
			calc "+f2" $iter_num
			iter_num=$CALC_RES
		fi
		xtime_val="$time_val"
		time_val="$time_val sec"
		xwork_val="$work_val"
		work_val="$work_val sec"
		xresponse_val="$response_val"
		response_val="$response_val sec"
	fi

	print_item "Iterations"			"$iter_num"
###	print_item "Iterations"			"$iter_real"
	if [[ $split_mode = TRUE ]]
	then
		print_item "Cycle Time (sec)"		"$xtime_val"
		print_item "Work Time (sec)"		"$xwork_val"
		print_item "Response Time (sec)"	"$xresponse_val"
		print_item "Score"			"$score_val"
	else
		print_item "Cycle Time"			"$time_val"
		print_item "Work Time"			"$work_val"
		print_item "Response Time"		"$response_val"
		print_item "Score"			"$score_val"
	fi
}

print_system()
{
	typeset manufacturer
	typeset product_name
	typeset system_release
	typeset kernel_release

	get_value MANUFACTURER; manufacturer=$VALUE
	get_value PRODUCT_NAME; product_name=$VALUE
	get_value SYSTEM_RELEASE; system_release=$VALUE
	get_value KERNEL_RELEASE; kernel_release=$VALUE

	print_head "System"
	print_item "Manufacturer"	"$manufacturer"
	print_item "Product Name"	"$product_name"
	print_item "System Release"	"$system_release"
	print_item "Kernel Release"	"$kernel_release"
}

print_bat()
{
	typeset no=$1
	typeset bat_no=
	typeset model_number
	typeset design_capacity
	typeset last_full
	typeset last_full_1
	typeset remaining
	typeset remaining1
	typeset unit=mWh
	typeset voltage
	typeset voltage_unit=mV
	typeset state
	typeset start
	typeset finish
	typeset drain_rate_list_X
	typeset drain_rate_list
	typeset drain_rate
	typeset drain_rate1
	typeset drain_rate_sum
	typeset start_value
	typeset finish_value
	typeset full_bat_life
	typeset res
	typeset ret
	typeset xdesign_capacity
	typeset xdesign_capacity_percent
	typeset xlast_full
	typeset xlast_full_percent
	typeset xremaining
	typeset xremaining_percent
	typeset xstart_value
	typeset xstart_value_percent
	typeset xfinish_value
	typeset xfinish_value_percent
	typeset xdrain_rate1
	typeset xdrain_rate2
	typeset xvoltage
	typeset iter_num
	typeset num
	typeset list
	typeset var
	typeset vol
	typeset xvol
	typeset rate
	typeset xrate

	iter_num=`$BLTK_GET_STAT_CMD -s $stat -N`

	$BLTK_GET_STAT_CMD -s $stat -n $no -c bat
	if [[ $? = 0 ]]
	then
		get_value BAT_${no}_NO; bat_no=$VALUE
		get_value BAT_${no}_MODEL_NUMBER; model_number=$VALUE
		get_value BAT_${no}_DESIGN_CAPACITY; design_capacity=$VALUE
		get_value BAT_${no}_LAST_FULL_CAPACITY; last_full=$VALUE
		get_value BAT_${no}_REMAINING_CAPACITY; remaining=$VALUE
		get_value BAT_${no}_REMAINING_CAPACITY_UNIT; unit=$VALUE
		get_value BAT_${no}_DESIGN_VOLTAGE; voltage=$VALUE
		get_value BAT_${no}_DESIGN_VOLTAGE_UNIT; voltage_unit=$VALUE
		get_value BAT_${no}_CHARGING_STATE; state=$VALUE
		start=`$BLTK_GET_STAT_CMD -s $stat -n $no -f bat`
		if [[ $null_finish_bat_life_flg = TRUE ]]
		then
			finish=0
		else
			finish=`$BLTK_GET_STAT_CMD -s $stat -n $no -l bat`
		fi
		if [[ $unit == mAh && ! -z $voltage ]]
		then
			unit=mWh
			(( design_capacity = design_capacity * voltage / 1000 ))
			(( last_full = last_full * voltage / 1000 ))
			(( remaining = remaining * voltage / 1000 ))
		fi

		start_value=`$BLTK_GET_STAT_CMD -s $stat -n $no -f cap`
		finish_value=`$BLTK_GET_STAT_CMD -s $stat -n $no -l cap`

		if (( start_value < finish_value ))
		then
			warning "Start battery capacity is less than finish capacity," \
				"the results data can be invalid"
		fi

		calc "-f2" $start_value $finish_value
		drain_rate=$CALC_RES
		calc "*f2" $drain_rate 3600
		drain_rate1=$CALC_RES
		calc "/f2" $drain_rate1 1000
		drain_rate1=$CALC_RES
		calc "/f2" $drain_rate1 $TIME_SEC
		drain_rate1=$CALC_RES

		calc "/f2" $drain_rate $TIME_SEC
		drain_rate2=$CALC_RES

		calc "=l" $drain_rate 0
		res=$CALC_RES
		if [[ $full_bat_life_flg = TRUE && $res != TRUE ]]
		then
			calc "*f" $design_capacity $TIME_SEC
			full_bat_life=$CALC_RES
			calc "/i" $full_bat_life $drain_rate
			full_bat_life=$CALC_RES
		fi

		calc "*f2" $last_full 100
		last_full_1=$CALC_RES
		calc "Ll" $design_capacity 0
		if [[ $CALC_RES != TRUE ]]
		then
			calc "/f2" $last_full_1 $design_capacity
			last_full_1=$CALC_RES
		else
			last_full_1=0.00
		fi
		calc "*f2" $remaining 100
		remaining1=$CALC_RES
		calc "Ll" $design_capacity 0
		if [[ $CALC_RES != TRUE ]]
		then
			calc "/f2" $remaining1 $design_capacity
			remaining1=$CALC_RES
		else
			remaining1=0.00
		fi

		xdesign_capacity="$design_capacity"
		xdesign_capacity_percent="100"
		design_capacity="$design_capacity $unit (100.00%)"

		xlast_full="$last_full"
		xlast_full_percent="$last_full_1"
		last_full="$last_full $unit ($last_full_1%)"

		xremaining="$remaining"
		xremaining_percent="$remaining1"
		remaining="$remaining $unit ($remaining1%)"

		xstart_value="$start_value"
		xstart_value_percent="$start"
		start_value="$start_value $unit ($start%)"

		xfinish_value="$finish_value"
		xfinish_value_percent="$finish"
		finish_value="$finish_value $unit ($finish%)"

		xdrain_rate1="$drain_rate1"
		xdrain_rate2="$drain_rate2"
		drain_rate1="$drain_rate1 W ($drain_rate2 $unit per sec)"
		xvoltage="$voltage"
		voltage="$voltage $voltage_unit"
		[[ -z $unit ]] && unit=mWh
		[[ -z $voltage_unit ]] && voltage_unit=mV
		if [[ $state != charged ]]
		then
			warning "Battery start charging state ($state) is not charged"
		fi

		(( num = iter_num ))

		CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -c vol"
		$CMD
		ret=$?
		if [[ $ret = 0 ]]
		then
			CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -a vol"
			list=`$CMD`
			ret=$?
			[[ $ret != 0 ]] && error "$CMD failed"
			calc +f $list
			var=$CALC_RES
			calc /f2 $var $num
			var=$CALC_RES
			vol=$var
			xvol="$var mV"
		else
			vol=
			xvol=
		fi

		CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -c rate"
		$CMD
		ret=$?
		if [[ $ret = 0 ]]
		then
			CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -a rate"
			list=`$CMD`
			ret=$?
			[[ $ret != 0 ]] && error "$CMD failed"
			calc +f $list
			var=$CALC_RES
			calc /f2 $var $num
			var=$CALC_RES
			rate=$var
			xrate="$var mW"
		else
			rate=
			xrate=
		fi
	fi

	if (( BAT_NUM > 1 ))
	then
		print_head "BAT"
#		print_head "BAT$bat_no"
		print_item "BAT"	"$bat_no"
	else
		print_head "BAT"
	fi
	print_item "Battery Model"	"$model_number"
	print_item "Charging State"	"$state"

	if [[ $split_mode = TRUE ]]
	then
		print_item "Design Voltage ($voltage_unit)"	"$xvoltage"
		print_item "Design Capacity ($unit)"	"$xdesign_capacity"
		print_item "Design Capacity (%)"	"$xdesign_capacity_percent"
		print_item "Last Full Capacity ($unit)"	"$xlast_full"
		print_item "Last Full Capacity (%)"	"$xlast_full_percent"
		print_item "Remaining Capacity ($unit)"	"$xremaining"
		print_item "Remaining Capacity (%)"	"$xremaining_percent"
		print_item "Start Capacity ($unit)"	"$xstart_value"
		print_item "Start Capacity (%)"		"$xstart_value_percent"
		print_item "Finish Capacity ($unit)"	"$xfinish_value"
		print_item "Finish Capacity (%)"	"$xfinish_value_percent"
		print_item "Average Present Rate (mW)"	"$rate"
		print_item "Average Present Voltage (mV)"	"$vol"
		print_item "Drain Rate (W)"		"$xdrain_rate1"
		print_item "Drain Rate ($unit per sec)"	"$xdrain_rate2"
	else
		print_item "Design Voltage"	"$voltage"
		print_item "Design Capacity"	"$design_capacity"
		print_item "Last Full Capacity"	"$last_full"
		print_item "Remaining Capacity"	"$remaining"
		print_item "Start Capacity"	"$start_value"
		print_item "Finish Capacity"	"$finish_value"
		print_item "Average Present Rate"	"$xrate"
		print_item "Average Present Voltage"	"$xvol"
		print_item "Drain Rate"		"$drain_rate1"
	fi

	if [[ $full_bat_life_flg = TRUE ]]
	then
		if [[ ! -z $full_bat_life ]]
		then
			time_conv $full_bat_life
			calc "/i" $full_bat_life 60
			full_bat_life=$CALC_RES
#			full_bat_life="$full_bat_life min ($TIME_CONV)"
			if [[ $split_mode != TRUE ]]
			then
				print_item "Design Battery Rating" \
					"$full_bat_life min ($TIME_CONV)"
			else
				print_item "Design Battery Rating (min)" \
					"$full_bat_life"
				print_item "Design Battery Rating (h:m:s)" \
					"$TIME_HH_MM_SS"
			fi
		else
			if [[ $split_mode != TRUE ]]
			then
				print_item "Design Battery Rating" ""
			else
				print_item "Design Battery Rating (min)" ""
				print_item "Design Battery Rating (h:m:s)" ""
			fi
		fi
	fi
}

print_cpu()
{
	typeset no=$1
	typeset cpu_no
	typeset cpu_model
	typeset cpu_governor
	typeset cpu_max_freq
	typeset cpu_min_freq
	typeset cpu_freq
	typeset cpu_cache_size
	typeset cpu_num_logical
	typeset cpu_timer
	typeset cpu_intr
	typeset bus_mas
	typeset var
	typeset num
	typeset list
	typeset load
	typeset ret
	typeset CMD
	typeset c_no
	typeset C Cd
	typeset p_no
	typeset P
	typeset xsize
	typeset xunit
	typeset throttling

	iter_num=`$BLTK_GET_STAT_CMD -s $stat -N`
	if [[ $? != 0 ]]
	then
		error "Cannot get info from $stat file"
	fi
	(( iter_num-- ))
	if (( no <= CPUINFO_NUM ))
	then
		get_value CPUINFO_${no}_NO; cpu_no=$VALUE
		get_value CPUINFO_${no}_MODEL_NAME; cpu_model=$VALUE
		get_value CPUINFO_${no}_CACHE_SIZE; cpu_cache_size=$VALUE
		get_value CPUINFO_${no}_SIBLINGS; cpu_num_logical=$VALUE

		get_value CPUFREQ_${no}_SLALLING_GOVERNOR; cpu_governor=$VALUE
		get_value CPUFREQ_${no}_CPUINFO_MAX_FREQ; cpu_max_freq=$VALUE
		get_value CPUFREQ_${no}_CPUINFO_MIN_FREQ; cpu_min_freq=$VALUE

		CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -c load"
		$CMD
		ret=$?
		if [[ $ret = 0 ]]
		then
			load=`$BLTK_GET_STAT_CMD -s $stat -n $no -l load`
		fi

		(( num = iter_num ))

		CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -c timer"
		$CMD
		ret=$?
		if [[ $ret = 0 ]]
		then
			CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -a timer"
			list=`$CMD`
			ret=$?
			[[ $ret != 0 ]] && error "$CMD failed"
			calc +f $list
			var=$CALC_RES
			calc /f2 $var $TIME_SEC
			var=$CALC_RES
			cpu_timer=$var
		else
			cpu_timer=
		fi
		CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -c intr"
		$CMD
		ret=$?
		if [[ $ret = 0 ]]
		then
			CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -a intr"
			list=`$CMD`
			ret=$?
			[[ $ret != 0 ]] && error "$CMD failed"
			calc +f $list
			var=$CALC_RES
			calc /f2 $var $TIME_SEC
			var=$CALC_RES
			cpu_intr=$var
		else
			cpu_intr=
		fi
		CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -c freq"
		$CMD
		ret=$?
		if [[ $ret = 0 ]]
		then
			CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -a freq"
			list=`$CMD`
			ret=$?
			[[ $ret != 0 ]] && error "$CMD failed"
			calc +f $list
			var=$CALC_RES
			calc /i $var $num
			var=$CALC_RES
			cpu_freq=$var
		else
			cpu_freq=
		fi
		CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -c bus-mas"
		$CMD
		ret=$?
		if [[ $ret = 0 ]]
		then
			CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -a bus-mas"
			list=`$CMD`
			ret=$?
			[[ $ret != 0 ]] && error "$CMD failed"
			calc +b $list
			var=$CALC_RES
			(( num = num + 1 ))
			calc /f2 $var $num
			var=$CALC_RES
			bus_mas=$var
		else
			bus_mas=
		fi

		(( num = iter_num + 1 ))
		CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -c T"
		$CMD
		ret=$?
		if [[ $ret = 0 ]]
		then
			CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -a T"
			list=`$CMD`
			ret=$?
			[[ $ret != 0 ]] && error "$CMD failed"
			calc +i $list
			var=$CALC_RES
			calc /f2 $var $num
			var=$CALC_RES
			throttling=$var
		else
			throttling=
		fi

		if [[ ! -z $CPU_C_STATES_NUM ]]
		then
			c_no=0
			while (( c_no < CPU_C_STATES_NUM ))
			do
				(( c_no++ ))
				CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -c C$c_no"
				$CMD
				ret=$?
				if [[ $ret = 2 ]]
				then
					C[$c_no]=
					continue
				fi
				[[ $ret != 0 ]] && error "$CMD failed"
				CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -a C$c_no"
				list=`$CMD`
				ret=$?
				[[ $ret != 0 ]] && error "$CMD failed"
				calc +f $list
				var=$CALC_RES
				calc /f2 $var $TIME_SEC
				var=$CALC_RES
				C[$c_no]=$var
			done
		fi

		if [[ ! -z $CPU_C_STATES_NUM ]]
		then
			c_no=0
			while (( c_no < CPU_C_STATES_NUM ))
			do
				(( c_no++ ))
				CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -c Cd${c_no}"
				$CMD
				ret=$?
				if [[ $ret = 2 ]]
				then
					Cd[$c_no]=
					continue
				fi
				[[ $ret != 0 ]] && error "$CMD failed"
				CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -a Cd${c_no}"
				list=`$CMD`
				ret=$?
				[[ $ret != 0 ]] && error "$CMD failed"
				calc +f $list
				var=$CALC_RES
				calc /f2 $var 3.579
				var=$CALC_RES
				calc /f2 $var 1000000
				var=$CALC_RES
				calc *f2 $var 100
				var=$CALC_RES
				calc /f2 $var $TIME_SEC
				var=$CALC_RES
				Cd[$c_no]=$var
			done
		fi

		if [[ ! -z $CPU_P_STATES_NUM ]]
		then
			p_no=-1
			while (( p_no < CPU_P_STATES_NUM - 1 ))
			do
				(( p_no++ ))
				CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -c P$p_no"
				$CMD
				ret=$?
				if [[ $ret = 2 ]]
				then
					P[$p_no]=
					continue
				fi
				[[ $ret != 0 ]] && error "$CMD failed"
				CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -a P$p_no"
				list=`$CMD`
				ret=$?
				[[ $ret != 0 ]] && error "$CMD failed"
				calc +f $list
				var=$CALC_RES
				calc /f2 $var $TIME_SEC # * 100% / 100 (10ms)
				var=$CALC_RES
				P[$p_no]=$var
			done
		fi
	fi

	if (( CPU_MAX > 1 ))
	then
		print_head "CPU"
		print_item "CPU"	"$cpu_no"
	else
		print_head "CPU"
	fi
	print_item "CPU Model"		"$cpu_model"
	if [[ $split_mode = TRUE ]]
	then
		if [[ -z $cpu_cache_size ]]
		then
			xsize=-
			xunit=KB
		else
			if [[ -z $cpu_cache_size ]]
			then
				xsize=-
				xunit=KB
			else
				set $cpu_cache_size
				xsize=$1
				xunit=$2
			fi
		fi
		print_item "Cache Size ($xunit)"	"$xsize"
	else
		print_item "Cache Size"		"$cpu_cache_size"
	fi
	print_item "Num Logical"	"$cpu_num_logical"
	print_item "Governor"		"$cpu_governor"
	if [[ $split_mode = TRUE ]]
	then
		print_item "Timer (per sec)"		"$cpu_timer"
		print_item "Interrupts (per sec)"	"$cpu_intr"
	else
		print_item "Timer"		"$cpu_timer" "per sec"
		print_item "Interrupts"		"$cpu_intr" "per sec"
	fi

	if [[ $split_mode = TRUE ]]
	then
		print_item "Load (%)"		"$load"
	else
		print_item "Load"		"$load" "%"
	fi
	if [[ $split_mode = TRUE ]]
	then
		print_item "Max Frequecy (kHz)"		"$cpu_max_freq"
		print_item "Min Frequency (kHz)"	"$cpu_min_freq"
		print_item "Average Frequency (kHz)"	"$cpu_freq"
	else
		print_item "Max Frequecy"		"$cpu_max_freq" "kHz"
		print_item "Min Frequency"		"$cpu_min_freq" "kHz"
		print_item "Average Frequency"		"$cpu_freq" "kHz"
	fi
	print_item "Bus Master Activity"	"$bus_mas"
	if [[ $split_mode = TRUE ]]
	then
		print_item "T (%)"	"$throttling"
	else
		print_item "T"		"$throttling" "%"
	fi

	if [[ ! -z $CPU_C_STATES_NUM ]]
	then
		c_no=0
		while (( c_no < CPU_C_STATES_NUM ))
		do
			(( c_no++ ))
			if [[ $CPU_C_STATES_NUM_AUTO = TRUE ]]
			then
				[[ -z "${C[$c_no]}" ]] && break
			fi
			if [[ $split_mode = TRUE ]]
			then
				print_item "C$c_no (per sec)"	"${C[$c_no]}"
			else
				print_item "C$c_no"	"${C[$c_no]}" "per sec"
			fi
		done
	fi

	if [[ ! -z $CPU_C_STATES_NUM ]]
	then
		c_no=0
		while (( c_no < CPU_C_STATES_NUM ))
		do
			(( c_no++ ))
			if [[ $CPU_C_STATES_NUM_AUTO = TRUE ]]
			then
				[[ -z "${Cd[$c_no]}" ]] && break
			fi
			if [[ $split_mode = TRUE ]]
			then
				print_item "Cd${c_no} (%)"	"${Cd[$c_no]}"
			else
				print_item "Cd${c_no}"	"${Cd[$c_no]}" "%"
			fi
		done
	fi

	if [[ ! -z $CPU_P_STATES_NUM ]]
	then
		p_no=-1
		while (( p_no < CPU_P_STATES_NUM - 1 ))
		do
			(( p_no++ ))
			if [[ $CPU_P_STATES_NUM_AUTO = TRUE ]]
			then
				[[ -z "${P[$p_no]}" ]] && break
			fi
			if [[ $split_mode = TRUE ]]
			then
				print_item "P$p_no (%)"	"${P[$p_no]}"
			else
				print_item "P$p_no"	"${P[$p_no]}" "%"
			fi
		done
	fi
}

print_user_field()
{
	typeset field_no
	typeset field_avg
	typeset var
	typeset num
	typeset list
	typeset ret
	typeset CMD

	num=`$BLTK_GET_STAT_CMD -s $stat -N`
	if [[ $? != 0 ]]
	then
		error "Cannot get info from $stat file"
	fi

	field_no=0
	while true
	do
		CMD="$BLTK_GET_STAT_CMD -s $stat -c field$field_no"
		$CMD
		ret=$?
		if [[ $ret = 0 ]]
		then
			CMD="$BLTK_GET_STAT_CMD -s $stat -a field$field_no"
			list=`$CMD`
			ret=$?
			[[ $ret != 0 ]] && error "$CMD failed"
			calc +f $list
			var=$CALC_RES
			calc /f $var $num
			var=$CALC_RES
			field_avg=$var
			(( field_no == 0 )) && 	print_head "User fields"
			print_item "User field $field_no" "$field_avg"
			(( field_no++ ))
		else
			break
		fi
	done
}

print_memory()
{
	typeset memory_type
	typeset memory_size
	typeset swap_size
	typeset ret
	typeset list
	typeset swap
	typeset mem
	typeset var
	typeset xmemory_size
	typeset xmemory_size_unit
	typeset xswap

	ret=`$BLTK_GET_STAT_CMD -s $stat -c mem`
	if [[ $? = 0 ]]
	then
		CMD="$BLTK_GET_STAT_CMD -s $stat -a mem"
		list=`$CMD`
		ret=$?
		[[ $ret != 0 ]] && error "$CMD failed"
		max $list
		var=$MAX
		xmem="$var"
		mem="$var kB"
	fi
	ret=`$BLTK_GET_STAT_CMD -s $stat -c swap`
	if [[ $? = 0 ]]
	then
		CMD="$BLTK_GET_STAT_CMD -s $stat -a swap"
		list=`$CMD`
		ret=$?
		[[ $ret != 0 ]] && error "$CMD failed"
		max $list
		var=$MAX
		xswap="$var"
		swap="$var kB"
	fi

	get_value MEMORY_TYPE; memory_type=$VALUE
	get_value MEMORY_SIZE; memory_size=$VALUE
	get_value SWAP_SIZE; swap_size=$VALUE

	print_head "Memory"
###	print_item "Memory Type"	"$memory_type"
	if [[ $split_mode = TRUE ]]
	then
		if [[ -z $memory_size ]]
		then
			xmemory_size=-
			xmemory_size_unit=kB
		else
			set $memory_size
			xmemory_size=$1
			xmemory_size_unit=$2
		fi
		if [[ -z $swap_size ]]
		then
			xswap_size=-
			xswap_size_unit=kB
		else
			set $swap_size
			xswap_size=$1
			xswap_size_unit=$2
		fi
		print_item "Memory Size ($xmemory_size_unit)"	"$xmemory_size"
		print_item "Swap Size ($xswap_size_unit)"	"$xswap_size"
		print_item "Max Memory (kB)"	"$xmem"
		print_item "Max Swap (kB)"	"$xswap"
	else
		print_item "Memory Size"	"$memory_size"
		print_item "Swap Size"		"$swap_size"
		print_item "Max Memory"		"$mem"
		print_item "Max Swap"		"$swap"
	fi
}

print_display()
{
	typeset model
	typeset x_size
	typeset y_size
	typeset z_size
	typeset d_on=0
	typeset d_off=0
	typeset d_st=0
	typeset d_sus=0
	typeset disk_cnt=0
	typeset disk_state

	get_value DISPLAY_MODEL; model=$VALUE
	get_value DISPLAY_X_SIZE; x_size=$VALUE
	get_value DISPLAY_Y_SIZE; y_size=$VALUE
	get_value DISPLAY_DEPTH; z_size=$VALUE

	ret=`$BLTK_GET_STAT_CMD -s $stat -c disp`
	if [[ $? = 0 ]]
	then
		CMD="$BLTK_GET_STAT_CMD -s $stat -a disp"
		list=`$CMD`
		ret=$?
		[[ $ret != 0 ]] && error "$CMD failed"
		for v in $list
		do
			if [[ "$v" = on ]]
			then
				(( d_on++ ))
			elif [[ "$v" = st ]]
			then
				(( d_st++ ))
			elif [[ "$v" = off ]]
			then
				(( d_off++ ))
			elif [[ "$v" = sus ]]
			then
				(( d_sus++ ))
			elif [[ $warn != 1 ]]
			then
				warn=1
				warning "Unexpected display state, " \
							"see $stat file"
				break
			fi
		done
		(( d_cnt = d_on + d_off + d_st + d_sus ))
		if (( d_cnt != 0 ))
		then
			calc "*f2" $d_on 100
			d_on=$CALC_RES
			calc "/f2" $d_on $d_cnt
			d_on=$CALC_RES

			calc "*f2" $d_off 100
			d_off=$CALC_RES
			calc "/f2" $d_off $d_cnt
			d_off=$CALC_RES

			calc "*f2" $d_st 100
			d_st=$CALC_RES
			calc "/f2" $d_st $d_cnt
			d_st=$CALC_RES

			calc "*f2" $d_sus 100
			d_sus=$CALC_RES
			calc "/f2" $d_sus $d_cnt
			d_sus=$CALC_RES

			d_state="on $d_on%, standby $d_st%, suspend $d_sus%, off $d_off%"
		fi
	fi

	print_head "Display"
	print_item "Grafic Model"		"$model"
	if [[ $split_mode = TRUE ]]
	then
		print_item "Display Size (x)"	"${x_size}"
		print_item "Display Size (y)"	"${y_size}"
		print_item "Display Size (z)"	"${z_size}"
	else
		if [[ -z $x_size && -z $y_size && -z $z_size ]]
		then
			print_item "Display Size"	""
		else
			print_item "Display Size"	"${x_size}x${y_size}x${z_size}"
		fi
	fi
	if [[ $split_mode = TRUE ]]
	then
		print_item "Display State (on%)"		"$d_on"
		print_item "Display State (standby%)"		"$d_st"
		print_item "Display State (suspend%)"		"$d_sus"
		print_item "Display State (off%)"		"$d_off"
	else
		print_item "Display State"	"$d_state"
	fi
}

print_hd()
{
	typeset hd_model
	typeset hd_size
	typeset hd_ai=0
	typeset hd_st=0
	typeset hd_sl=0
	typeset hd_cnt=0
	typeset hd_state
	typeset ret
	typeset num
	typeset list
	typeset rd
	typeset wr
	typeset var
	typeset hd_rpm
	typeset xmbsize
	typeset xmbsize_unit
	typeset xgbsize
	typeset xgbsize_unit

	get_value HD_MODEL; hd_model=$VALUE
	get_value HD_SIZE; hd_size=$VALUE
  	get_value HD_RPM; hd_rpm=$VALUE
	if [[ -z $hd_rpm ]]
	then
		hd_rpm=`$BLTK_BIN/bltk_get_hd_rpm "$hd_model"`
	fi

	ret=`$BLTK_GET_STAT_CMD -s $stat -c rd`
	if [[ $? = 0 ]]
	then
		CMD="$BLTK_GET_STAT_CMD -s $stat -a rd"
		list=`$CMD`
		ret=$?
		[[ $ret != 0 ]] && error "$CMD failed"
		calc +f $list
		var=$CALC_RES
		calc /f2 $var $TIME_SEC
		var=$CALC_RES
		xrd="$var"
		rd="$var per sec"
	fi
	ret=`$BLTK_GET_STAT_CMD -s $stat -c wr`
	if [[ $? = 0 ]]
	then
		CMD="$BLTK_GET_STAT_CMD -s $stat -a wr"
		list=`$CMD`
		ret=$?
		[[ $ret != 0 ]] && error "$CMD failed"
		calc +f $list
		var=$CALC_RES
		calc /f2 $var $TIME_SEC
		var=$CALC_RES
		xwr="$var"
		wr="$var per sec"
	fi
	ret=`$BLTK_GET_STAT_CMD -s $stat -c hd`
	if [[ $? = 0 ]]
	then
		CMD="$BLTK_GET_STAT_CMD -s $stat -a hd"
		list=`$CMD`
		ret=$?
		[[ $ret != 0 ]] && error "$CMD failed"
		for v in $list
		do
			if [[ "$v" = a/i ]]
			then
				(( hd_ai++ ))
			elif [[ "$v" = st ]]
			then
				(( hd_st++ ))
			elif [[ "$v" = sl ]]
			then
				(( hd_sl++ ))
			elif [[ $warn != 1 ]]
			then
				warn=1
				warning "Unexpected hd state value, see $stat file"
				break
			fi
		done
		(( hd_cnt = hd_ai + hd_st + hd_sl ))
		if (( hd_cnt != 0 ))
		then
			calc "*f2" $hd_ai 100
			hd_ai=$CALC_RES
			calc "/f2" $hd_ai $hd_cnt
			hd_ai=$CALC_RES

			calc "*f2" $hd_st 100
			hd_st=$CALC_RES
			calc "/f2" $hd_st $hd_cnt
			hd_st=$CALC_RES

			calc "/f2" $hd_sl 100
			hd_sl=$CALC_RES
			calc "/f2" $hd_sl $hd_cnt
			hd_sl=$CALC_RES

			hd_state="active/idle $hd_ai%, standby $hd_st%, sleeping $hd_sl%"
		fi
	fi

	print_head "HD"
	print_item "HD Model"		"$hd_model"
	if [[ $split_mode = TRUE ]]
	then
		hd_size=`echo "$hd_size" | sed -e "s/(//g"`
		hd_size=`echo "$hd_size" | sed -e "s/)//g"`
		if [[ -z $hd_size ]]
		then
			print_item "HD Size (Mbytes)"	""
			print_item "HD Size (GB)"	""
		else
			set $hd_size
			xmbsize=$1
			xmbsize_unit=$2
			xgbsize=$3
			xgbsize_unit=$4
			print_item "HD Size ($xmbsize_unit)"	"$xmbsize"
			print_item "HD Size ($xgbsize_unit)"	"$xgbsize"
		fi
	else
		print_item "HD Size"		"$hd_size"
	fi
	print_item "HD RPM"		"$hd_rpm"
	if [[ $split_mode = TRUE ]]
	then
		print_item "HD Reads (per sec)"		"$xrd"
		print_item "HD Writes (per sec)"	"$xwr"
		print_item "HD State (active/idle%)"	"$hd_ai"
		print_item "HD State (standby%)"	"$hd_st"
		print_item "HD State (sleeping%)"	"$hd_sl"
	else
		print_item "HD Reads"		"$rd"
		print_item "HD Writes"		"$wr"
		print_item "HD State"		"$hd_state"
	fi
}

print_comment()
{
	typeset line
	typeset comment

	print_head "Comment"
	if [[ -r $results/comment ]]
	then
		while read line
		do
			if [[ -z $comment ]]
			then
				comment="$line"
			else
				comment="$comment | $line"
			fi
		done < $results/comment
		print_item "Comment"	"$comment"
	elif [[ $comment_flg = TRUE ]]
	then
			print_item "Comment"	"$COMMENT"
	elif [[ $fname_comment_flg = TRUE ]]
	then
			print_item "Comment"	"$results"
	else
			print_item "Comment"	""
	fi
}

print_source()
{
	print_head "Source"
	print_item "Source"	"$results"
}

print_msg()
{
	if [[ ! -z $2 ]]
	then
		printf "# %s : %0s\n" "$1" "$2"
	else
		printf "# %s : %0s\n" "$1" "-"
	fi
}

print_results()
{
	print_head "Test Result"
	if [[ -z $TEST_ERROR && $WARNING_CNT = 0  && $ERROR_CNT = 0 ]]
	then
		print_item "Result"	"Passed"
	else
		if [[ ! -z $TEST_ERROR ]]
		then
			print_item "Result"	"Failed"
		elif [[ $ERROR_CNT = 0 ]]
		then
			print_item "Result"	"Warning"
		else
			print_item "Result"	"Error"
		fi
		(( i = 0 ))
		while (( i < ERROR_CNT ))
		do
			print_msg "Error"	"${ERROR_ARR[i]}"
			(( i++ ))
		done
		(( i = 0 ))
		while (( i < WARNING_CNT ))
		do
			print_msg "Warning"	"${WARNING_ARR[i]}"
			(( i++ ))
		done
	fi
}

get_time()
{
	typeset tm
	typeset ss
	typeset mm
	typeset hh

	iter_num=`$BLTK_GET_STAT_CMD -s $stat -N`
	if [[ $? != 0 ]]
	then
		error "Cannot get info from $stat file"
	fi
	(( iter_num-- ))
	if (( $iter_num < 1 ))
	then
		warning "Zero iter number, set to 1"
		iter_num=1
	fi

	tm=`$BLTK_GET_STAT_CMD -s $stat -l time`
	if [[ $? != 0 ]]
	then
		error "Cannot get info from $stat file"
	fi
	tm=${tm%.*}
	TIME_HH_MM_SS=$tm

	ss=${tm##*:}
	ss=${ss#0}
	tm=${tm%:*}
	mm=${tm##*:}
	mm=${mm#0}
	hh=${tm%:*}
	hh=${hh#0}

	(( tm = hh * 60 * 60 + mm * 60 + ss ))
	if (( tm == 0 ))
	then
		warning "Zero time, set to 1 sec"
		tm=1
		TIME_HH_MM_SS="00:00:01"
	fi
	TIME_SEC=$tm
	(( tm = tm / 60 ))
	TIME_MIN=$tm
}

TIME_CONV=

time_conv()
{
	typeset tm=$1
	typeset hh
	typeset mm
	typeset ss

	neg_flg=FALSE
	if (( tm < 0 ))
	then
		(( tm = -tm ))
		neg_flg=TRUE
	fi

	calc "%i" $tm 60
	ss=$CALC_RES
	calc "/i" $tm 60
	mm=$CALC_RES
	calc "%i" $mm 60
	mm=$CALC_RES
	calc "/i" $tm 3600
	hh=$CALC_RES
	[[ $heg_flg = TRUE ]] && (( hh = -hh ))
	TIME_CONV=`printf "%02i:%02i:%02i" $hh $mm $ss`
}

print_report()
{
	typeset no

	printf "\n"
	print_workload;	printf "\n"
	print_system;	printf "\n"
	no=1
	if [[ ! -z $CPU_COMMON_NUM ]]
	then
		CPU_MAX=$CPU_COMMON_NUM
	else
		CPU_MAX=$CPUINFO_NUM
	fi

	while (( no <= CPU_MAX ))
	do
		print_cpu $no; printf "\n"
		(( no += 1 ))
	done
	print_memory;	printf "\n"
	print_display;	printf "\n"
	print_hd;	printf "\n"

	if [[ ! -z $BAT_COMMON_NUM ]]
	then
		BAT_NUM=$BAT_COMMON_NUM
	fi
	no=1
	if [[ $bat_ignore != TRUE ]]
	then
		while (( no <= BAT_NUM ))
		do
#			do_plot $no p bat
#			do_plot $no c cap
			print_bat $no; printf "\n"
			(( no += 1 ))
		done
	fi

	print_user_field;	printf "\n"
	print_rating;		printf "\n"
	print_source;		printf "\n"
	print_comment;		printf "\n"
	print_results;		printf "\n"
}

do_plot()
{
	typeset no=$1
	typeset suff=$2
	typeset name=$3

	rm -f $results/plot.$no.$suff

	CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -c $name"
	$CMD
	ret=$?
	if [[ $ret != 0 ]]
	then
		warning "Info for $name plotting in $results not found"
		return
	fi
	CMD="$BLTK_GET_STAT_CMD -s $stat -n $no -a $name"
	list=`$CMD`
	ret=$?
	[[ $ret != 0 ]] && error "$CMD failed"
	for l in $list
	do
		echo "$cnt	$l"
	done >$results/plot.$no.$suff
}

calc()
{
	typeset ret
	typeset list
	typeset cmd

	CALC_RES=

	set -f
	cmd="$BLTK_CALC_CMD $*"
	list=`$cmd`
	ret=$?
	set +f
	if [[ $ret = 0 ]]
	then
		CALC_RES="$list"
	else
		error_msg "$BLTK_CALC_CMD $1 $2 $3 $4 $5 ... failed"
		error_msg "${FUNCNAME[*]}"
		error_msg "${BASH_LINENO[*]}"
		error "Internal ERROR: calc"
	fi
}

RESULTS=$*

if [[ -z $RESULTS ]]
then
	RESULTS="."
fi

for results in $RESULTS
do
	TEST_ERROR=
	ERROR_CNT=0
	ERROR_ARR=
	WARNING_CNT=0
	WARNING_ARR=

	if [[ ! -d $results ]]
	then
		error "$results is not a directory"
	fi
	if [[ -e $results/fail ]]
	then
		TEST_ERROR=TRUE
		error "Test completed with errors (see work_out.log and other log files for more details)"
	fi
	if [[ ! -e $results/info2.log ]]
	then
		TEST_ERROR=TRUE
		error "Test is not completed (see work_out.log and other log files for more details)"
	fi
	if [[ ! -r $results/info.log ]]
	then
		TEST_ERROR=TRUE
		error "Cannot access info.log file, invalid results directory"
	fi
	if [[ ! -r $results/stat.log ]]
	then
		TEST_ERROR=TRUE
		error "Cannot access stat.log file, invalid results directory"
	fi
	stat=$results/stat.log
	score=$results/score
	info=$results/info.log

	get_value CPUINFO_NUM; CPUINFO_NUM=$VALUE
	get_value CPUFREQ_NUM; CPUFREQ_NUM=$VALUE
	get_value CPUSTATE_NUM; CPUSTATE_NUM=$VALUE
	get_value BAT_NUM; BAT_NUM=$VALUE

	get_time

	if [[ -z $REPORT ]]
	then
		report=$results/Report
	else
		report=$results/$REPORT
	fi

	tmp_report=/tmp/bltk_report.$$

	rm -f $report $report.tar.bz2

	if [[ $OUTPUT != TRUE ]]
	then
		print_report > $report
	else
		print_report
	fi
###	tar -jpcf $tmp_report $results
###	cp $tmp_report $report.tar.bz2
###	rm -f $tmp_report
done

