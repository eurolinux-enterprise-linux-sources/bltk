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

#include <xse.h>

#define	UT2004DEMO_LNX		"ut2004-lnx"
#define	_SETUP			".setup"
#define	LICENSE_WIN		"\\\"License Agreement\\\": (\\\".setup"
#define	SETUP_WIN		"\\\"Unreal Tournament 2004 Demo Setup\\\": (\\\".setup"

/* action		state	count	delay	string */

static xse_scen_t scen_start_setup[] = {
	{WAITSTARTCMD, 0, 300, 1000, UT2004DEMO_LNX},
	{DELAY, 0, 0, 3000, 0},

	{SETWINDOW, X, 600, 1000, SETUP_WIN},
	{DELAY, 0, 0, 3000, 0},
	{FOCUSIN, 0, 0, 3000, 0},
	{PRESSKEY, A, 0, 3000, "B"},

	{ENDSCEN, 0, 0, 0, 0}
};

static xse_scen_t scen_finish_setup[] = {
	{FOCUSIN, 0, 0, 1000, 0},
	{DELAY, 0, 0, 1000, 0},
	{PRESSKEY, A, 0, 1000, "E"},
	{DELAY, 0, 0, 1000, 0},
	{ENDSCEN, 0, 0, 0, 0}
};

int main(int argc, char **argv)
{
	int i, ret = 0;

	progname = argv[0];

	delay(3000);

	init_xse();

	if (argc != 1) {
		(void)fprintf(stderr,
			      "%s: INTERNAL ERROR: Invalid args number = %d\n",
			      progname, argc);
	}

	scen_file = NULL;
	run_scen(scen_start_setup);

	for (i = 1; i <= 300; i++) {
		run_scen(scen_finish_setup);
		ret = wait_finish_cmd(UT2004DEMO_LNX, 1000, 10, 0, 0);
		if (ret == 0) {
			break;
		}
	}

	fini_xse();
	return (ret);
}
