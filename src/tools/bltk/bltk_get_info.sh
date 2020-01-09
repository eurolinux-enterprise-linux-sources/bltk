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

[[ -z $BLTK_ROOT ]] && export BLTK_ROOT=`dirname `dirname $PROG``
[[ -z $BLTK_BIN ]] && export BLTK_BIN=$BLTK_ROOT/bin

error()
{
	echo "$PROG: ERROR: $*" >&2
	exit 1
}

warning()
{
	echo "Warning: $*" >&2
}

if [[ $BLTK_SIMUL_LAPTOP = TRUE ]]
then
	ROOT_DIR="$BLTK_SIMUL_LAPTOP_DIR"
else
	ROOT_DIR=
fi

export ROOT_DIR=$ROOT_DIR

CPUINFO="$ROOT_DIR/proc/cpuinfo"
INTERRUPTS="$ROOT_DIR/proc/interrupts"
MEMINFO="$ROOT_DIR/proc/meminfo"
DISKSTATS="$ROOT_DIR/proc/diskstats"
PARTITIONS="$ROOT_DIR/proc/partitions"
CPUSTAT="$ROOT_DIR/proc/stat"

[[ ! -r $CPUINFO ]] && error "Cannot access $CPUINFO file"
[[ ! -r $INTERRUPTS ]] && error "Cannot access $INTERRUPTS file"
[[ ! -r $MEMINFO ]] && error "Cannot access $MEMINFO file"
[[ ! -r $DISKSTATS ]] && warning "Cannot access $DISKSTATS file"
[[ ! -r $CPUSTAT ]] && error "Cannot access $CPUSTAT file"

AC_ADAPTER="$ROOT_DIR/proc/acpi/ac_adapter"
BAT="$ROOT_DIR/proc/acpi/battery"

CPUFREQ="$ROOT_DIR/sys/devices/system/cpu"
CPUSTATE="$ROOT_DIR/proc/acpi/processor"

DMIDECODE=
XDPYINFO=
LSPCI=
LSMOD=

CONFIG=/proc/config.gz

{
echo
echo CPUINFO_PATH = $CPUINFO
echo
echo INTERRUPTS_PATH = $INTERRUPTS
echo
echo MEMINFO_PATH = $MEMINFO
echo
echo DISKSTATS_PATH = $DISKSTATS
echo
$BLTK_BIN/bltk_get_ac_adapter	$AC_ADAPTER
echo
$BLTK_BIN/bltk_get_bat		$BAT
echo
$BLTK_BIN/bltk_get_cpufreq		$CPUFREQ
echo
$BLTK_BIN/bltk_get_cpuinfo		$CPUINFO
echo
$BLTK_BIN/bltk_get_cpustate	$CPUSTATE
echo
$BLTK_BIN/bltk_get_cpustat		$CPUSTAT
echo
$BLTK_BIN/bltk_get_dmidecode	$DMIDECODE
echo
$BLTK_BIN/bltk_get_hdparm		$PARTITIONS
echo
$BLTK_BIN/bltk_get_kernel_release
echo
$BLTK_BIN/bltk_get_meminfo		$MEMINFO
echo
$BLTK_BIN/bltk_get_system_release
echo
$BLTK_BIN/bltk_get_xdpyinfo	$XDPYINFO
echo
$BLTK_BIN/bltk_get_lspci		$LSPCI
echo
$BLTK_BIN/bltk_get_timer		$CONFIG
echo
} >$BLTK_RESULTS/info$1.log
