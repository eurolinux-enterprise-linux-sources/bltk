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

/* Check it, if scen is changed */
#define	LINE_FOCUSIN	1
#define	LINE_FSCREEN	ERR
#define	LINE_NEXT	2
#define	LINE_DELAY	3
#define	LINE_QUIT	4
#define	LINE_END	5

/* action	state	count	delay		string */

static xse_scen_t scen[] = {
	{SETWINDOWID, 0, 0, 0, WINDOWID},
	{FOCUSIN, 0, 0, DELAY_2_MIN, 0},	/* LINE_FOCUSIN */
	{PRESSKEY, 0, -1, DELAY_2_MIN, Next},	/* LINE_NEXT */
	{DELAY, 0, 0, 1000, 0},
	{PRESSKEY, C, 0, 1000, "W"},	/* LINE_QUIT */
	{ENDWINDOW, 0, 0, 0, "title_not_set"},	/* LINE_END */
	{ENDSCEN, 0, 0, 0, 0}
};

int main(int argc, char **argv)
{
	char *env;
	int show_demo = 0;
	int show_demo_cnt = 5;
	int show_demo_time = 1;

	progname = argv[0];

	if (argc != 1) {
		(void)fprintf(stderr, "%s: Arguments aren't needed\n",
			      progname);
		exit(1);
	}

	env = getenv("BLTK_SHOW_DEMO");
	if (env != NULL) {
		show_demo = (strcmp(env, "TRUE") == 0);
	}

	if (show_demo) {
		env = getenv("BLTK_SHOW_DEMO_CNT");
		if (env != NULL) {
			show_demo_cnt = atoi(env);
		}
		env = getenv("BLTK_SHOW_DEMO_TIME");
		if (env != NULL) {
			show_demo_time = atoi(env) * MSEC_IN_SEC;
		}
		scen[LINE_NEXT].count = show_demo_cnt;
		scen[LINE_FOCUSIN].delay = show_demo_time;
		scen[LINE_NEXT].delay = show_demo_time;

		if (show_demo_time < 1000) {
			scen[LINE_DELAY].delay = show_demo_time;
			scen[LINE_QUIT].delay = show_demo_time;
			scen[LINE_END].delay = show_demo_time;
		}
	}

	env = getenv("BLTK_WL_PROG");
	if (env && strcmp(env, "konqueror") == 0) {
		scen[LINE_QUIT].string = "Q";
	}

	env = getenv("BLTK_WL_TITLE");
	if (env != NULL) {
		scen[LINE_END].string = env;
	}

	init_xse();
	run_scen(scen);
	fini_xse();
	write_delay(0);
	return (0);
}
