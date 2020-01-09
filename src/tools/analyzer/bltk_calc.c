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

#define	MAX_ARG	256000
#define	STR_LEN	1024

#define	RES_NULL	0
#define	RES_INT		1
#define	RES_FLOAT	2
#define	RES_LOGIC	3
#define	RES_BIT		4
#define	RES_CONV	5

static char *pname = "bltk_calc";

typedef long long ll_t;
typedef unsigned long long ull_t;

static void prog_exit(int ret)
{
	if (ret) {
		(void)printf("BAD_BLTK_CALC_CMD_ARGS\n");
	}
	exit(ret);
}

static ull_t bit_num(ull_t val)
{
	int i, b, s = 0;

	for (i = 0; i < sizeof(ull_t) * 8; i++) {
		b = (val >> i & 0x1);
		s += b;
	}
	return (s);
}

#define	TIME_CONV	1
#define	ON_OFF_CONV	2
#define	HD_CONV		3

static int convert(int argc, char **argv)
{
	int i, res = -999;
	char *p, *hh, *mm, *ss, *uu;

	for (i = 0; i < argc; i++) {
		p = argv[i];
		if ((mm = strstr(p, ":")) != NULL) {
			hh = p;
			ss = strstr(mm + 1, ":");
			if (ss == NULL) {
				(void)fprintf(stderr,
					      "%s: convert: time: invalid value = %s\n",
					      pname, p);
				prog_exit(1);
			}
			uu = strstr(ss + 1, ".");
			mm[0] = 0;
			mm++;
			ss[0] = 0;
			ss++;
			if (uu != NULL) {
				uu[0] = 0;
				uu++;
				res =
				    atoi(hh) * 3600 + atoi(mm) * 60 + atoi(ss);
				if (i == argc - 1) {
					(void)printf("%i.%s\n", res, uu);
				} else {
					(void)printf("%i.%s ", res, uu);
				}
				continue;
			} else {
				res =
				    atoi(hh) * 3600 + atoi(mm) * 60 + atoi(ss);
			}
		} else if (strcmp(p, "-") == 0) {
			res = 0;
		} else if (strcmp(p, "?") == 0) {
			res = 0;
		} else if (strcmp(p, "on") == 0) {
			res = 1;
		} else if (strcmp(p, "off") == 0) {
			res = -1;
		} else if (strcmp(p, "a/i") == 0) {
			res = 1;
		} else if (strcmp(p, "st") == 0) {
			res = -2;
		} else if (strcmp(p, "sl") == 0) {
			res = -3;
		} else if (strcmp(p, "sus") == 0) {
			res = -3;
		} else {
			if (i == argc - 1) {
				(void)printf("%s\n", p);
			} else {
				(void)printf("%s ", p);
			}
			continue;
/*
			(void) fprintf(stderr,
				"%s: convert: invalid value = %s\n",
				pname, p);
			prog_exit(1);
*/
		}
		if (i == argc - 1) {
			(void)printf("%i\n", res);
		} else {
			(void)printf("%i ", res);
		}
	}
	return (0);
}

int main(int argc, char **argv)
{
	long double fres = 0, farg[MAX_ARG];
	ull_t ires = 0, iarg[MAX_ARG];
	int len, var, ret, i;
	int plus_flg = 0;
	int minus_flg = 0;
	int multi_flg = 0;
	int div_flg = 0;
	int rem_flg = 0;
	int less_flg = 0;
	int less_eq_flg = 0;
	int eq_flg = 0;
	int res_type_flg = RES_NULL;
	char *lres = "NULL";
	char *oarg;
	char *scale = NULL;
	char format[STR_LEN];

	pname = argv[0];

	argc--;
	argv++;

	if (argc == 0) {
		(void)fprintf(stderr,
			      "%s: invalid args number = %d, "
			      "should be atleast 1\n", pname, argc);
		prog_exit(1);
	}

	oarg = argv[0];
	len = strlen(argv[0]);
	if (len < 2) {
		(void)fprintf(stderr,
			      "%s: invalid argv[0] (%s) lenght = %d, "
			      "should be 2\n", pname, oarg, len);
		prog_exit(1);
	}

	var = oarg[0];
	if (var == '+') {
		plus_flg = 1;
	} else if (var == '-') {
		minus_flg = 1;
	} else if (var == '*') {
		multi_flg = 1;
	} else if (var == '/') {
		div_flg = 1;
	} else if (var == '%') {
		rem_flg = 1;
	} else if (var == 'l') {
		less_flg = 1;
	} else if (var == 'L') {
		less_eq_flg = 1;
	} else if (var == '=') {
		eq_flg = 1;
	} else {
		(void)fprintf(stderr,
			      "%s: invalid argv[1][0] value = %c, "
			      "should be +,-,*,/,%%\n", pname, var);
		prog_exit(1);
	}
	var = oarg[1];
	if (var == 'i') {
		res_type_flg = RES_INT;
	} else if (var == 'f') {
		res_type_flg = RES_FLOAT;
	} else if (var == 'l') {
		res_type_flg = RES_LOGIC;
	} else if (var == 'b') {
		res_type_flg = RES_BIT;
	} else if (var == 'c') {
		res_type_flg = RES_CONV;
	} else {
		(void)fprintf(stderr,
			      "%s: invalid argv[1][1] value = %c, "
			      "should be 'i', 'f', or 's'\n", pname, var);
		prog_exit(1);
	}

	if (len > 2) {
		scale = oarg + 2;
	}

	if ((minus_flg || div_flg || rem_flg) && argc != 3) {
		(void)fprintf(stderr,
			      "%s: invalid args number = %d, "
			      "should be 3, oarg = %s\n", pname, argc, oarg);
		prog_exit(1);
	}
	if ((less_flg || less_eq_flg || eq_flg) && argc != 3) {
		(void)fprintf(stderr,
			      "%s: invalid args number = %d, "
			      "should be 3, oarg = %s\n", pname, argc, oarg);
		prog_exit(1);
	}

	argc--;
	argv++;

	if (res_type_flg == RES_CONV) {
		ret = convert(argc, argv);
		prog_exit(ret);
	}

	for (i = 0; i < argc; i++) {
		if (res_type_flg == RES_BIT) {
			ret = sscanf(argv[i], "%llx", &iarg[i]);
		} else {
			ret = sscanf(argv[i], "%Lf", &farg[i]);
		}
		if (ret != 1) {
			(void)fprintf(stderr,
				      "%s: sscanf() failed, arg = %s\n",
				      pname, argv[i]);
			prog_exit(1);
		}
	}
	if (res_type_flg == RES_BIT) {
		ires = 0;
		for (i = 0; i < argc; i++) {
			ires += bit_num(iarg[i]);
		}
		(void)printf("%llu\n", ires);
		prog_exit(0);
	}

	if (div_flg || rem_flg) {
		if (farg[1] == 0) {
			(void)fprintf(stderr,
				      "%s: arg 2 is zero, arg 2 = %s, "
				      "oarg = %s\n", pname, argv[1], oarg);
			prog_exit(1);
		}
	}

	if (plus_flg) {
		fres = 0;
		for (i = 0; i < argc; i++) {
			fres += farg[i];
		}
	} else if (minus_flg) {
		fres = farg[0] - farg[1];
	} else if (multi_flg) {
		fres = 1;
		for (i = 0; i < argc; i++) {
			fres *= farg[i];
		}
	} else if (div_flg) {
		if (farg[1] == 0) {
			(void)fprintf(stderr,
				      "%s: arg 2 is zero, arg 2 = %s\n",
				      pname, argv[1]);
			prog_exit(1);
		}
		fres = farg[0] / farg[1];
	} else if (rem_flg) {
		if (farg[1] == 0) {
			(void)fprintf(stderr,
				      "%s: arg 2 is zero, arg 2 = %s\n",
				      pname, argv[1]);
			prog_exit(1);
		}
		fres = farg[0] - farg[1] * (long long)(farg[0] / farg[1]);
	} else if (less_flg) {
		if (farg[0] < farg[1]) {
			lres = "TRUE";
		} else {
			lres = "FALSE";
		}
	} else if (less_eq_flg) {
		if (farg[0] <= farg[1]) {
			lres = "TRUE";
		} else {
			lres = "FALSE";
		}
	} else if (eq_flg) {
		if (farg[0] == farg[1]) {
			lres = "TRUE";
		} else {
			lres = "FALSE";
		}
	}

	if (res_type_flg == RES_FLOAT) {
		if (scale == NULL) {
			(void)printf("%.2Lf\n", fres);
		} else {
			(void)sprintf(format, "%%.%sLf\n", scale);
			(void)printf(format, fres);
		}
	} else if (res_type_flg == RES_INT) {
		(void)printf("%lli\n", (long long)fres);
	} else if (res_type_flg == RES_LOGIC) {
		(void)printf("%s\n", lres);
	} else {
		prog_exit(1);
	}

	prog_exit(0);
}
