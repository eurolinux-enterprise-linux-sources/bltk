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

SAVEDIR=$1

user=`id -un`
group=`id -gn`

trap 'trap_action 1; exit 1' 1 2 3 6 15
#trap 'echo trap 11 >&2' 11
trap_action()
{
	[[ ! -a "$SAVEDIR" ]] && return
	$BLTK_SUDO_CMD chown -h -R $user:$group $SAVEDIR
	$BLTK_SUDO_CMD chmod -R a+rw $SAVEDIR
	$BLTK_SUDO_CMD rm -rf $SAVEDIR
}

PROG=$0

error()
{
	echo "$PROG: ERROR: $*" >&2
	exit 1
}

warning()
{
	echo "$PROG: Warning: $*" >&2
}

SAVELIST="
/sys/devices/system/cpu
/proc/acpi/alarm
/proc/acpi/ac_adapter
/proc/acpi/battery
/proc/acpi/processor
/proc/cmdline
/proc/config.gz
/proc/cpuinfo
/proc/diskstats
/proc/interrupts
/proc/meminfo
/proc/modules
/proc/partitions
/proc/stat
/proc/swaps
/proc/version
/proc/vmstat
/etc/redflag-release
/etc/fedora-release
/etc/redhat-release
/etc/SuSE-release
"
#for f in /proc/acpi/*
#do
#	if [[ $f != /proc/acpi/event ]]
#	then
#		SAVELIST="$SAVELIST $f"
#	fi
#done

if [[ -a $SAVEDIR ]]
then
	CMD="$BLTK_SUDO_CMD chmod -R a+rw $SAVEDIR"
	$CMD
	[[ $? != 0 ]] && error "$CMD failed"
	CMD="$BLTK_SUDO_CMD rm -rf $SAVEDIR"
	$CMD
	[[ $? != 0 ]] && error "$CMD failed"
fi

CMD="mkdir -p -m 0777 $SAVEDIR"
$CMD
[[ $? != 0 ]] && error "$CMD failed"

for src in $SAVELIST
do
	[[ ! -a $src ]] && continue
	dst="$SAVEDIR$src"
	dstdir=`dirname $dst`
	CMD="mkdir -p -m 0777 $dstdir"
	$CMD
	[[ $? != 0 ]] && error "$CMD failed"
	CMD="$BLTK_SUDO_CMD cp -d -r $src $dst"
	$CMD
	[[ $? != 0 ]] && warning "$CMD failed"
	CMD="$BLTK_SUDO_CMD chown -h -R $user:$group $dst"
	$CMD
	[[ $? != 0 ]] && warning "$CMD failed"
	CMD="$BLTK_SUDO_CMD chmod -R a+rw $dst"
	$CMD
	[[ $? != 0 ]] && warning "$CMD failed"
done >>$SAVEDIR/err.log 2>&1

date >$SAVEDIR/date 2>&1
id >$SAVEDIR/id 2>&1
uname -a >$SAVEDIR/uname 2>&1
lspci >$SAVEDIR/lspci 2>&1
lsmod >$SAVEDIR/lsmod 2>&1
env | sort >$SAVEDIR/env 2>&1
dmesg  >$SAVEDIR/dmesg 2>&1
free >$SAVEDIR/free 2>&1
df -lk >$SAVEDIR/df 2>&1
ps -lef >$SAVEDIR/ps 2>&1
###	glxinfo >$SAVEDIR/glxinfo 2>&1
$BLTK_SUDO_CMD dmidecode >$SAVEDIR/dmidecode 2>&1
xset q >$SAVEDIR/xset 2>&1

HDPARM=hdparm

for h in hda hdb hdc hdd sda sdb sdc sdd
do
	grep " $h " /proc/diskstats >/dev/null 2>&1
	if [[ $? = 0 ]]
	then
		$BLTK_SUDO_CMD $HDPARM /dev/$h >$SAVEDIR/hdparm.$h 2>&1
		$BLTK_SUDO_CMD $HDPARM -iI /dev/$h >>$SAVEDIR/hdparm.$h 2>&1
		$BLTK_SUDO_CMD $HDPARM -C /dev/$h >>$SAVEDIR/hdparm.$h 2>&1
	fi
done

exit 0

