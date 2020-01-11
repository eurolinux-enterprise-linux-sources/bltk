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

extern void usleep(unsigned long usec);

#define	MSEC_IN_SEC	1000
#define	MCSEC_IN_MSEC	1000
#define	MCSEC_IN_SEC	1000000

#define	STR_LEN		1024

static void prog_exit(int ret)
{
	if (ret) {
		(void)printf("BAD_BLTK_TIME_CMD_ARGS\n");
	}
	exit(ret);
}

int main(int argc, char **argv)
{
	char str[STR_LEN];
	int ret;
	struct timeval tv;
	long double fres;

	if (argc == 1) {
		ret = gettimeofday(&tv, NULL);
		if (ret != 0) {
			(void)fprintf(stderr, str,
				      "gettimeofday() failed: errno %d (%s)\n",
				      errno, strerror(errno));
			return (1);
		}
		fres = (float)tv.tv_usec / (float)MCSEC_IN_SEC;
		fres += tv.tv_sec;
		(void)printf("%.2Lf\n", fres);
	} else {
		ret = sscanf(argv[1], "%Lf", &fres);
		if (ret != 1) {
			(void)fprintf(stderr,
				      "%s: invalid arg = %s\n",
				      argv[0], argv[1]);
			prog_exit(1);
		}
		fres = fres * 1000000;
		usleep(fres);
	}

	return (0);
}
