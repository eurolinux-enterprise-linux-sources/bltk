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

source `dirname $0`/../../bin/bltk_wl_common
[[ $? != 0 ]] && { echo "bltk tree corrupted"; exit 2; }

startup()
{
	trap 'cleanup 1; exit 1' 1 2 3 15

	wl_startup
	wl_check_error $?

	if [ "`uname -m`" = "x86_64" ];then 
		export OFFICE_SRC_FILE=$BLTK_EXTERN_SRC_WL_OFFICE/OOo_3.0.0_LinuxX86-64_install_en-US.tar.gz
	elif [ "`uname -m`" = "i386" ];then
		export OFFICE_SRC_FILE=$BLTK_EXTERN_SRC_WL_OFFICE/OOo_3.0.0_LinuxIntel_install_en-US.tar.gz
	else 
		echo "unknow OS"; exit 1 
	fi 
	export OFFICE_SRC_TMP_PARENT_DIR=$BLTK_TMP_WL_OFFICE
	export OFFICE_SRC_TMP_DIR=$OFFICE_SRC_TMP_PARENT_DIR/OOO300_m9_native_packed-1_en-US.9358
	export OFFICE_TGT_DIR=$OFFICE_SRC_TMP_PARENT_DIR/OOO
	export SOFFICE_PROG=$HOME/soffice
}

cleanup()
{
	typeset	status=$1

	wl_cleanup $status

	if [[ $? != 0 ]]
	then
		wl_error_msg "=== Workload 'office' failed, time `wl_prt_time`"
		exit 1
	else
		echo "=== Workload 'office' passed, time `wl_prt_time`"
		exit 0
	fi
}

install_ooo()
{

	wl_remove_file ${HOME}/.sversionrc
	wl_check_error $?

	CMD="cp $BLTK_WL_BIN/install_linux $OFFICE_SRC_TMP_DIR"
	$CMD
	wl_check_error $?

	wl_change_dir $OFFICE_SRC_TMP_DIR
	wl_check_error $?

	mkdir $OFFICE_TGT_DIR -m 0777 

	CMD="$OFFICE_SRC_TMP_DIR/install_linux -l RPMS $OFFICE_TGT_DIR"
	$CMD
	wl_check_error $?

	wl_change_dir $BLTK_WL_ROOT
	wl_check_error $?

	CMD="$BLTK_WL_BIN/bltk_wl_office_xse $BLTK_WL_BIN/scen_install"
	$CMD
	wl_check_error $? "$CMD failed"
}

install-loc()
{
	wl_remove_install
	wl_check_error $?

	wl_remove_file OOWRITER_FILE.odt
	wl_check_error $?
	wl_copy_file OOWRITER_FILE_SAMPLE.odt OOWRITER_FILE.odt
	wl_check_error $?

	ooo_bin=`locate soffice.bin`
	if [ "$ooo_bin" = "" ] 
	then 
		wl_error_msg "=== local install workload 'office' failed: no soffice.bin found "
		exit 1 
	fi
	CMD="rm -f $HOME/soffice"
	$CMD
	wl_check_error $? "$CMD failed"

	CMD="ln -s $ooo_bin $HOME/soffice"
	$CMD
	wl_check_error $? "$CMD failed"

	wl_create_install
	wl_check_error $?
}

install()
{
	wl_remove_install
	wl_check_error $?

	wl_remove_file OOWRITER_FILE.odt
	wl_check_error $?
	wl_copy_file OOWRITER_FILE_SAMPLE.odt OOWRITER_FILE.odt
	wl_check_error $?

	wl_check_file $OFFICE_SRC_FILE
	wl_check_error $?

	wl_remove_dir $OFFICE_SRC_TMP_DIR
	wl_check_error $?

	wl_remove_dir $OFFICE_TGT_DIR
	wl_check_error $?

	wl_make_dir $OFFICE_SRC_TMP_PARENT_DIR
	wl_check_error $?


	wl_change_dir $OFFICE_SRC_TMP_PARENT_DIR
	wl_check_error $?

	CMD="tar -zxf $OFFICE_SRC_FILE"
	$CMD
	wl_check_error $? "$CMD failed" "Cannot extract $OFFICE_SRC_FILE"

	wl_check_dir $OFFICE_SRC_TMP_DIR
	wl_check_error $?

	install_ooo
	wl_check_error $?

	wl_remove_dir $OFFICE_SRC_TMP_DIR
	wl_check_error $?

	wl_create_install
	wl_check_error $?
}

uninstall()
{
	wl_remove_install
	wl_check_error $?

	wl_remove_dir $OFFICE_SRC_TMP_DIR
	wl_check_error $?

	wl_remove_dir $OFFICE_TGT_DIR
	wl_check_error $?

}

if [[ $# = 0 || $1 = i || $1 = install ]]
then
	work=install
elif [[ $1 = install-loc ]]
then
	work=install-loc
elif [[ $1 = u || $1 = uninstall ]]
then
	work=uninstall
else
	echo "Invalid parameter"
	exit 1
fi

{
startup
$work
cleanup 0
}  2>&1 | tee -i $work.log

