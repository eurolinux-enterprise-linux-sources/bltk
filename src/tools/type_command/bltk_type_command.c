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

#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/wait.h>
#include <limits.h>
#include <stdlib.h>
#include <sys/file.h>
#include <libgen.h>
#include <getopt.h>

extern int gethostname(char *name, size_t len);
extern void usleep(unsigned long usec);

#define	DTIME	200

#define	PC_TYPE	0		/* prompt & command */
#define	P_TYPE	1		/* prompt omly */
#define	C_TYPE	2		/* command only */
#define	E_TYPE	3		/* enter only */

static void delay(int msecs)
{
	(void)fflush(stdout);
	if (msecs > 0) {
		usleep(msecs * 1000);
	}
}

int main(int argc, char **argv)
{
	int cmd, i, j, ret;
	int dtime = DTIME;
	char c;
	char hn[1024];
	char pr[1024];

	cmd = atoi(argv[1]);
	argc -= 2;
	argv += 2;

	if (cmd == E_TYPE) {
		(void)printf("\n");
		delay(0);
		return (0);
	}

	ret = gethostname(hn, 1024);
	if (ret != 0) {
		(void)sprintf(hn, "localhost");
	}
	(void)sprintf(pr, "%s:~ # ", hn);

	if (cmd == PC_TYPE || cmd == P_TYPE) {
		(void)printf("%s", pr);
		delay(0);
		if (cmd == P_TYPE) {
			return (0);
		}
	}
	delay(500);

	for (i = 0; i < argc; i++) {
		if (i > 0) {
			(void)printf("%c", ' ');
			delay(dtime);
		}
		for (j = 0;; j++) {
			c = argv[i][j];
			if (c == 0) {
				break;
			}
			(void)printf("%c", c);
			delay(dtime);
		}
	}
	delay(500);
	(void)printf("\n");
	delay(0);
	return (0);
}
