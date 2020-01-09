/*
 *  Copyright (c) 2006 Intel Corp.
 *  Copyright (c) 2006 Konstantin Karasyov <konstantin.a.karasyov@intel.com>
 *  Copyright (c) 2006 Vladimir Lebedev <vladimir.p.lebedev@intel.com>
 *  All rights reserved.
 *
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *    Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 *
 *    Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 *    Neither the name of Intel Corporation nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 *  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 *  AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 *  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 *  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 *  DAMAGE.
 *
 * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/types.h>
#include <signal.h>
#include <errno.h>
#include <limits.h>

#include <xse.h>

#define	text0 "ACPI_BATTERY_VALUE_UNKNOWN"

#define	text1 \
	"/*\n" \
	"    This is the first attempt to make\n" \
	"    developer workload more realistic.\n" \
	"    To be or not to be, that is the question !!!\n" \
	"    To be continued.\n" \
	"*/\n" \

/* 	action		state	count	delay	string */

static xse_scen_t scen[] = {
	{SETWINDOWID, E, 0, 0, WINDOWID},
	{WAITSTARTCMD, 0, 0, 0, CSCOPE_CMD},
	{DELAY, 0, 0, 10000, 0},
	{FOCUSIN, 0, 0, 150, 0},
	{TYPETEXT, 0, 0, 150, text0},
	{DELAY, 0, 0, 3000, 0},
	{PRESSKEY, 0, 0, 10000, Return},
	{PRESSKEY, 0, 0, 1000, Return},
	{WAITSTARTCMD, 0, 0, 0, VI_CMD},
	{DELAY, 0, 0, 10000, 0},
	{PRESSKEY, 0, 2, 1000, Next},
	{PRESSKEY, 0, 4, 1000, Prior},
	{PRESSKEY, S, 0, 150, "H"},
	{PRESSKEY, 0, 5, 150, Up},
	{PRESSKEY, 0, 5, 150, Left},
	{DELAY, 0, 0, 3000, 0},
	{PRESSKEY, 0, 0, 1000, "i"},
	{PRESSKEY, 0, 0, 1000, Return},
	{PRESSKEY, 0, 2, 150, Up},
	{PRESSKEY, 0, 0, 1000, Return},
	{TYPETEXT, 0, 0, 150, text1},
	{DELAY, 0, 0, 5000, 0},
	{PRESSKEY, 0, 0, 5000, Escape},
	{PRESSKEY, S, 0, 1000, "colon"},
	{PRESSKEY, 0, 0, 150, "w"},
	{PRESSKEY, 0, 0, 1000, "q"},
	{PRESSKEY, 0, 0, 1000, Return},
	{WAITFINISHCMD, 0, 0, 0, VI_CMD},
	{DELAY, 0, 0, 5000, 0},
	{PRESSKEY, C, 0, 1000, "d"},
	{WAITFINISHCMD, 0, 0, 0, CSCOPE_CMD},
	{FOCUSIN, 0, 0, 150, 0},
	{DELAY, 0, 0, 1000, 0},
	{ENDSCEN, 0, 0, 0, 0}
};

int main(int argc, char **argv)
{
	progname = argv[0];

	if (argc != 1) {
		(void)fprintf(stderr,
			      "%s: INTERNAL ERROR: Invalid args number = %d\n",
			      progname, argc);
		exit(1);
	}

	init_xse();

	run_scen(scen);

	fini_xse();

	write_delay(0);

	exit(0);
}
