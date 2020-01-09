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

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <stdio.h>
#include <dirent.h>
#include <stdlib.h>

#include "bltk.h"

char foo_str[STR_LEN];

char proc_cpuinfo_path[STR_LEN];
char proc_meminfo_path[STR_LEN];
char proc_diskstats_path[STR_LEN];
char proc_interrupts_path[STR_LEN];

char hd_name[STR_LEN];
char hd_dev_name[STR_LEN];

char *bat_cap_states[] = BAT_CAP_STATES;
char *bat_charge_states[] = BAT_CHARGE_STATES;

int cpu_total = 0;

int verbose = 0;
int simul_laptop = 0;
char *simul_laptop_dir = "BLTK_SIMUL_LAPTOP_DIR_NULL";
char fail_fname[STR_LEN];
char pass_fname[STR_LEN];

char ac_adapter_state_path[STR_LEN];
char *state_name = DEF_STATE_NAME;
int ac_adapter_state_flg = 0;
char *on_state = DEF_ON_STATE;
char *off_state = DEF_OFF_STATE;
int ac_state = -1;

char *bat_alrm_file = DEF_ALARM_FILE;
char *bat_info_file = DEF_INFO_FILE;
char *bat_state_file = DEF_STATE_FILE;
int bat_num = 0;

bat_path_t **bat_path = NULL;
bat_state_t **bat = NULL;

int cpu_num = 0;

char cpu_stat_file[STR_LEN];

char *cur_freq_file = DEF_CPU_CUR_FREQ_FILE;
char *cur_freq_file2 = DEF_CPU_CUR_FREQ_FILE2;
int cpu_freq_num = 0;

cpu_load_path_t **cpu_load_path = NULL;
cpu_load_t **cpu_load = NULL;
cpu_freq_path_t **cpu_freq_path = NULL;
cpu_freq_t **cpu_freq = NULL;

char *cpu_cstate_file = DEF_CPU_C_FILE;
char *cpu_tstate_file = DEF_CPU_T_FILE;

cpu_cstate_path_t **cpu_cstate_path = NULL;
cpu_cstate_state_t **cpu_cstate_state = NULL;

int cpu_cstate_num = -1;

static int get_str_var_value(char *value, char *name);
static int parse_string(char *str, char *name, char *delim,
			char *value, size_t size, int val_no);

static int get_bat(void);
static int init_bat_path(int no, char *bat_path, bat_path_t * path);
static int init_bat(int bat_no, bat_state_t * bat);
static int get_load_cpus(void);
static int init_load_cpu_path(int cpu_no, cpu_load_path_t * path);
static int init_load_cpu(int cpu_no, cpu_load_t * cpu);

static int get_freq_cpus(void);
static int init_freq_cpu_path(int cpu_no, char *cpu_freq_dir,
			      cpu_freq_path_t * path, char *cur_freq_file);
static int init_freq_cpu(int cpu_no, cpu_freq_t * cpu);

static int get_cstate_cpus(void);
static int init_cstate_cpu_path(int cpu_no,
				char *cpu_cstate_dir, cpu_cstate_path_t * path);
static int init_cstate_cpu(int cpu_no, cpu_cstate_state_t * cpu);

/* Initialize global variables */
int init_vars(void)
{
	int ret = 0;
	char str[STR_LEN];

	ret = prog_system("./bin/bltk_get_info");
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "./bin/bltk_get_info failed\n",
			      __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	/* Find out whether VAR file exists or not */
	if (access(info_log_fname, R_OK) != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "access(%s) failed\n",
			      __FILE__, __LINE__, info_log_fname);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	ret = get_str_var_value(proc_cpuinfo_path, "CPUINFO_PATH");
	if (ret != 0) {
		(void)sprintf(str, "ERROR: cannot get cpuinfo configuration\n");
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	ret = get_str_var_value(proc_interrupts_path, "INTERRUPTS_PATH");
	if (ret != 0) {
		(void)sprintf(str,
			      "ERROR: cannot get interrupts configuration\n");
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	ret = get_str_var_value(proc_meminfo_path, "MEMINFO_PATH");
	if (ret != 0) {
		(void)sprintf(str, "ERROR: cannot get meminfo configuration\n");
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	ret = get_str_var_value(proc_diskstats_path, "DISKSTATS_PATH");
	if (ret != 0) {
		(void)sprintf(str,
			      "ERROR: cannot get diskstats configuration\n");
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	ret = get_str_var_value(str, "CPU_TOTAL");
	if (ret != 0) {
		(void)sprintf(str,
			      "ERROR: cannot get CPU_TOTAL configuration\n");
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	cpu_total = atoi(str);

	/* Get the value of stat file */
	ret = get_str_var_value(cpu_stat_file, "CPUSTAT_PATH");

	if (ret != 0) {
		(void)sprintf(str,
			      "ERROR: cannot get CPUSTAT_PATH configuration\n");
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	if (access(cpu_stat_file, R_OK) != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "access(%s) failed\n",
			      __FILE__, __LINE__, cpu_stat_file);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	/* Get the value of ac_adapter_state_path */
	ret = get_str_var_value(ac_adapter_state_path, "AC_ADAPTER_STATE_PATH");

	if (ret != 0) {
		(void)sprintf(str, "Warning: cannot get AC configuration\n");
		(void)write_to_warning_log(str);
		ac_stat_ignore = 1;
		ac_adapter_state_flg = 0;
	} else {
		ac_adapter_state_flg = 1;
	}

	/* Get the path to bat directory */
	/* Init bat structures */
	ret = get_str_var_value(foo_str, "BAT_NUM");
	if (ret != 0) {
		(void)sprintf(str, "Warning: cannot get BAT configuration\n");
		(void)write_to_warning_log(str);
		bat_num = 0;
	} else {
		bat_num = get_bat();
		if (bat_num <= 0) {
			bat_num = 0;
			(void)sprintf(str,
				      "Warning: cannot get BAT "
				      "configuration\n");
			(void)write_to_warning_log(str);
		}
	}

	/* Get the path to CPU C-states directory */
	/* Init CPUs C states structures */
	ret = get_str_var_value(foo_str, "CPUSTATE_NUM");
	if (ret != 0) {
		cpu_cstate_num = 0;
		(void)sprintf(str,
			      "Warning: cannot get CPU C states configuration\n");
		(void)write_to_warning_log(str);
	} else {
		cpu_cstate_num = get_cstate_cpus();
		if (cpu_cstate_num <= 0) {
			cpu_cstate_num = 0;
			(void)sprintf(str,
				      "Warning: cannot get CPU C states "
				      "configuration\n");
			(void)write_to_warning_log(str);
		}
	}

	/* Get the path to CPU directory */
	ret = get_str_var_value(foo_str, "CPUFREQ_NUM");
	if (ret != 0) {
		cpu_freq_num = 0;
		(void)sprintf(str,
			      "Warning: cannot get CPU "
			      "frequencies configuration\n");
		(void)write_to_warning_log(str);
	} else {
		cpu_freq_num = get_freq_cpus();
		if (cpu_freq_num <= 0) {
			cpu_freq_num = 0;
			(void)sprintf(str,
				      "Warning: cannot get CPU "
				      "frequencies configuration\n");
			(void)write_to_warning_log(str);
		}
	}

	/* Init CPUs structures */
	cpu_num = get_load_cpus();

	if (cpu_num <= 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "cpu_num should be a positive value "
			      "(currently %d)\n", __FILE__, __LINE__, cpu_num);
		(void)write_to_warning_log(str);
		return (-1);
	}
	/* Init HD paramsCPUs structures */
	ret = get_str_var_value(hd_name, "HD_NAME");
	if (ret != 0) {
		(void)sprintf(str, "ERROR: cannot get HD configuration\n");
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	ret = get_str_var_value(hd_dev_name, "HD_DEV_NAME");
	if (ret != 0) {
		(void)sprintf(str, "ERROR: cannot get HD configuration\n");
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	return (0);
}

/* Parse VAR file for string variables in form NAME=VALUE */
int get_str_var_value(char *value, char *name)
{
	int ret = -1;

	ret =
	    get_value_file(info_log_fname, name, DEF_EQUAL, value, STR_LEN, 1);
	return (ret);
}

/* Get the number of bat and initialize their structures */
int get_bat(void)
{
	int ret = 0;
	int i;
	char name[STR_LEN];
	char bat_dir[STR_LEN];
	int bat_no;
	char buf[STR_LEN];
	char str[STR_LEN];

	bat_path = (bat_path_t **) malloc(sizeof(bat_path_t *) * MAX_BAT);
	if (bat_path == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	bat = (bat_state_t **) malloc(sizeof(bat_state_t *) * MAX_BAT);
	if (bat == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	bat_num = 0;
	bat_path[0] = NULL;
	bat[0] = NULL;

	for (i = 0; i < MAX_BAT; i++) {
		(void)sprintf(name, "BAT_%d_PATH", i);
		ret = get_str_var_value(bat_dir, name);
		if (ret != 0) {
			continue;
		}
		(void)sprintf(name, "BAT_%d_NO", i);
		ret = get_str_var_value(foo_str, name);
		if (ret != 0) {
			continue;
		}
		bat_no = atoi(foo_str);
		(void)sprintf(name, "%s/%s", bat_dir, bat_info_file);
		if (access(name, F_OK) != 0) {
			continue;
		}
		ret = get_value_pseudo_file(name, DEF_PRESENT_NAME,
					    DEF_COLON, buf, STR_LEN, 1);
		if (ret != 0) {
			(void)sprintf(str, "File %s, Line %d: "
				      "get_value_pseudo_file(%s) "
				      "for bat #%d failed\n",
				      __FILE__, __LINE__, DEF_PRESENT_NAME, i);
			(void)write_to_err_log(str);
			prog_exit(1);
		}

		if (strcmp(buf, DEF_PRESENT_YES) != 0) {
			continue;
		}

		bat_num++;
		bat_path[bat_num] = (bat_path_t *) malloc(sizeof(bat_path_t));
		if (bat_path[bat_num] == NULL) {
			(void)sprintf(str, "File %s, Line %d: "
				      "malloc() failed\n", __FILE__, __LINE__);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
		/* Get bat files paths */
		ret = init_bat_path(bat_no, bat_dir, bat_path[bat_num]);
		if (ret != 0) {
			(void)sprintf(str, "File %s, Line %d: "
				      "init_bat_path(%d, ...) failed\n",
				      __FILE__, __LINE__, i);
			(void)write_to_err_log(str);
			prog_exit(1);
		}

		bat[bat_num] = (bat_state_t *) malloc(sizeof(bat_state_t));
		if (bat[bat_num] == NULL) {
			(void)sprintf(str, "File %s, Line %d: "
				      "malloc() failed\n", __FILE__, __LINE__);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
		/* Get initial bat info */
		ret = init_bat(bat_num, bat[bat_num]);
		if (ret != 0) {
			(void)sprintf(str, "File %s, Line %d: "
				      "init_bat(%d, ...) failed\n",
				      __FILE__, __LINE__, bat_num);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
	}
	return (bat_num);
}

int init_bat_path(int no, char *bat_path, bat_path_t * path)
{
	int ret = 0;
	char buf[STR_LEN];
	char str[STR_LEN];

	path->no = no;

	path->alrm_p = (char *)malloc(STR_LEN);
	if (path->alrm_p == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	path->info_p = (char *)malloc(STR_LEN);
	if (path->info_p == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	path->stat_p = (char *)malloc(STR_LEN);
	if (path->stat_p == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	(void)sprintf(path->alrm_p, "%s/%s", bat_path, bat_alrm_file);
	(void)sprintf(path->info_p, "%s/%s", bat_path, bat_info_file);
	(void)sprintf(path->stat_p, "%s/%s", bat_path, bat_state_file);

	ret = get_value_pseudo_file(path->info_p,
				    DEF_MAX_CHARGE_NAME, DEF_COLON, buf,
				    STR_LEN, 2);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_pseudo_file(%s) for bat #%d failed\n",
			      __FILE__, __LINE__, DEF_MAX_CHARGE_NAME, bat_num);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	if (strcmp(buf, DEF_AMPER_NAME) == 0) {
		path->is_mah = 1;
	} else {
		path->is_mah = 0;
	}

	ret = get_value_pseudo_file(path->info_p,
				    DEF_DES_CHARGE_NAME, DEF_COLON, buf,
				    STR_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_pseudo_file(%s) for bat #%d failed\n",
			      __FILE__, __LINE__, DEF_DES_CHARGE_NAME, bat_num);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	path->des_cap = atoi(buf);

	ret = get_value_pseudo_file(path->info_p,
				    DEF_DES_VOLTAGE_NAME, DEF_COLON, buf,
				    STR_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_pseudo_file(%s) for bat #%d failed\n",
			      __FILE__, __LINE__,
			      DEF_DES_VOLTAGE_NAME, bat_num);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	path->des_vol = atoi(buf);

	return (ret);
}

int init_bat(int bat_no, bat_state_t * bat)
{
	int ret = 0;
	char str[STR_LEN];

	bat->last_full_cap = -1;
	bat->cur_cap = -1;
	bat->cur_vol = -1;
	bat->cur_rate = -1;
	bat->alrm = -1;

	ret = get_bat_state(bat_no, bat);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_bat_state(%d, ...) failed\n",
			      __FILE__, __LINE__, bat_no);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	ret = get_bat_info(bat_no, bat);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_bat_info(%d, ...) failed\n",
			      __FILE__, __LINE__, bat_no);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	return (ret);
}

/* Get bat information from 'state' file */
int get_bat_state(int bat_no, bat_state_t * bat)
{
	int ret = 0;
	char buf[STR_LEN];
	char str[STR_LEN];

	ret = get_value_pseudo_file(bat_path[bat_no]->stat_p,
				    DEF_CUR_VOLTAGE_NAME, DEF_COLON, buf,
				    STR_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_pseudo_file(%s) for bat #%d failed\n",
			      __FILE__, __LINE__, DEF_CUR_VOLTAGE_NAME, bat_no);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	bat->cur_vol = atoi(buf);

	ret = get_value_pseudo_file(bat_path[bat_no]->stat_p,
				    DEF_CUR_RATE_NAME, DEF_COLON, buf,
				    STR_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_pseudo_file(%s) for bat #%d failed\n",
			      __FILE__, __LINE__, DEF_CUR_RATE_NAME, bat_no);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	bat->cur_rate = atoi(buf);

	ret = get_value_pseudo_file(bat_path[bat_no]->stat_p,
				    DEF_CUR_CHARGE_NAME, DEF_COLON, buf,
				    STR_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_pseudo_file(%s) for bat #%d failed\n",
			      __FILE__, __LINE__, DEF_CUR_CHARGE_NAME, bat_no);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	bat->cur_cap = atoi(buf);

	return (ret);
}

/* Get bat information from 'info' file */
int get_bat_info(int bat_no, bat_state_t * bat)
{
	int ret = 0;
	char buf[STR_LEN];
	char str[STR_LEN];

	ret = get_value_pseudo_file(bat_path[bat_no]->info_p,
				    DEF_MAX_CHARGE_NAME, DEF_COLON, buf,
				    STR_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_pseudo_file(%s) for bat #%d failed\n",
			      __FILE__, __LINE__, DEF_MAX_CHARGE_NAME, bat_no);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	bat->last_full_cap = atoi(buf);

	return (ret);
}

/* Get bat information from 'alarm' file */
int get_bat_alarm(int bat_no, bat_state_t * bat)
{
	int ret = 0;
	char buf[STR_LEN];
	char str[STR_LEN];

	ret = get_value_pseudo_file(bat_path[bat_no]->alrm_p,
				    DEF_ALRM_CHARGE_NAME, DEF_COLON, buf,
				    STR_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_pseudo_file(%s) for bat #%d failed\n",
			      __FILE__, __LINE__, DEF_ALRM_CHARGE_NAME, bat_no);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	bat->alrm = atoi(buf);

	return (ret);
}

/* Get the number of CPUs (C-states) and initialize their structures */
int get_cstate_cpus(void)
{
	int ret = 0;
	int i, cpu_no;
	char name[STR_LEN];
	char str[STR_LEN];
	char cpu_cstate_dir[STR_LEN];

	cpu_cstate_path =
	    (cpu_cstate_path_t **) malloc(sizeof(cpu_cstate_path_t *) *
					  MAX_CPU);
	if (cpu_cstate_path == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	cpu_cstate_state =
	    (cpu_cstate_state_t **) malloc(sizeof(cpu_cstate_state_t *) *
					   MAX_CPU);
	if (cpu_cstate_state == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	cpu_cstate_num = 0;
	cpu_cstate_path[0] = NULL;
	cpu_cstate_state[0] = NULL;
	for (i = 0; i < MAX_CPU; i++) {
		(void)sprintf(name, "CPUSTATE_%d_PATH", i);
		ret = get_str_var_value(cpu_cstate_dir, name);
		if (ret != 0) {
			continue;
		}
		(void)sprintf(name, "CPUSTATE_%d_NO", i);
		ret = get_str_var_value(foo_str, name);
		if (ret != 0) {
			continue;
		}
		cpu_no = atoi(foo_str);
		(void)sprintf(name, "%s/%s", cpu_cstate_dir, cpu_cstate_file);
		if (access(name, F_OK) != 0) {
			continue;
		}

		cpu_cstate_num++;

		cpu_cstate_path[cpu_cstate_num] =
		    (cpu_cstate_path_t *) malloc(sizeof(cpu_cstate_path_t));
		if (cpu_cstate_path[cpu_cstate_num] == NULL) {
			(void)sprintf(str, "File %s, Line %d: "
				      "malloc() failed\n", __FILE__, __LINE__);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
		/* Get CPU (C-states) files paths */
		ret = init_cstate_cpu_path(cpu_no, cpu_cstate_dir,
					   cpu_cstate_path[cpu_cstate_num]);
		if (ret != 0) {
			(void)sprintf(str, "File %s, Line %d: "
				      "init_cstate_cpu_path(%d, ...) failed\n",
				      __FILE__, __LINE__, i);
			(void)write_to_err_log(str);
			prog_exit(1);
		}

		cpu_cstate_state[cpu_cstate_num] =
		    (cpu_cstate_state_t *) malloc(sizeof(cpu_cstate_state_t));
		if (cpu_cstate_state[cpu_cstate_num] == NULL) {
			(void)sprintf(str, "File %s, Line %d: "
				      "malloc() failed\n", __FILE__, __LINE__);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
		/* Get initial CPU (C-states) info */
		ret = init_cstate_cpu(cpu_cstate_num,
				      cpu_cstate_state[cpu_cstate_num]);
		if (ret != 0) {
			(void)sprintf(str, "File %s, Line %d: "
				      "init_cstate_cpu(%d, ...) failed\n",
				      __FILE__, __LINE__, cpu_cstate_num);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
	}
	return (cpu_cstate_num);
}

int
init_cstate_cpu_path(int cpu_no, char *cpu_cstate_dir, cpu_cstate_path_t * path)
{
	char str[STR_LEN];

	path->no = cpu_no;

	path->c_state_file = (char *)malloc(STR_LEN);
	if (path->c_state_file == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	(void)sprintf(path->c_state_file, "%s/%s",
		      cpu_cstate_dir, cpu_cstate_file);

	path->t_state_file = (char *)malloc(STR_LEN);
	if (path->t_state_file == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	(void)sprintf(path->t_state_file, "%s/%s",
		      cpu_cstate_dir, cpu_tstate_file);

	return (0);
}

int init_cstate_cpu(int cpu_no, cpu_cstate_state_t * cpu)
{
	int ret = 0;
	int i;
	char str[STR_LEN];

	cpu->num_cstate_states = 0;
	for (i = 0; i < MAX_C_STATES; i++) {
		cpu->c_present[i] = 0;
	}

	ret = get_cpu_cstate_states(cpu_no, cpu);
	if (ret < 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_cpu_cstate_states() failed for CPU #%d\n",
			      __FILE__, __LINE__, cpu_cstate_path[cpu_no]->no);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	return (0);
}

int get_load_cpus(void)
{
	int ret = 0;
	int err = 0;
	int fd = -1;
	int i;
	ssize_t r_ret;
	char cpu_name[STR_LEN];
	char buf[BUFF_LEN];
	char str[STR_LEN];
	char *ptr = NULL;

	cpu_load_path =
	    (cpu_load_path_t **) malloc(sizeof(cpu_load_path_t *) * MAX_CPU);
	if (cpu_load_path == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	cpu_load = (cpu_load_t **) malloc(sizeof(cpu_load_t *) * MAX_CPU);
	if (cpu_load == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	fd = open(cpu_stat_file, O_RDONLY);
	if (fd < 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "open(%s, O_RDONLY) failed\n",
			      __FILE__, __LINE__, cpu_stat_file);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	(void)memset(buf, 0, BUFF_LEN);
	r_ret = read(fd, buf, BUFF_LEN);
	if (r_ret <= 0) {
		err = errno;
		(void)sprintf(str, "File %s, Line %d: "
			      "read(%s) failed with %d (%s)\n",
			      __FILE__, __LINE__,
			      cpu_stat_file, err, strerror(err));
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	(void)close(fd);
	fd = -1;

	cpu_num = 0;
	cpu_load_path[0] = NULL;
	cpu_load[0] = NULL;

	for (i = 0; i < MAX_CPU; i++) {
		(void)sprintf(cpu_name, "cpu%d ", i);
		ptr = strstr(buf, cpu_name);
		if (ptr == NULL) {
			continue;
		}
		cpu_num++;
		cpu_load_path[cpu_num] =
		    (cpu_load_path_t *) malloc(sizeof(cpu_load_path_t));
		if (cpu_load_path[cpu_num] == NULL) {
			(void)sprintf(str, "File %s, Line %d: "
				      "malloc() failed\n", __FILE__, __LINE__);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
		/* Get CPU files paths */
		ret = init_load_cpu_path(i, cpu_load_path[cpu_num]);
		if (ret != 0) {
			(void)sprintf(str, "File %s, Line %d: "
				      "init_load_cpu_path(%d, ...) failed\n",
				      __FILE__, __LINE__, i);
			(void)write_to_err_log(str);
			prog_exit(1);
		}

		cpu_load[cpu_num] = (cpu_load_t *) malloc(sizeof(cpu_load_t));
		if (cpu_load[cpu_num] == NULL) {
			(void)sprintf(str, "File %s, Line %d: "
				      "malloc() failed\n", __FILE__, __LINE__);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
		/* Get initial CPU info */
		ret = init_load_cpu(cpu_num, cpu_load[cpu_num]);
		if (ret != 0) {
			(void)sprintf(str, "File %s, Line %d: "
				      "init_load_cpu(%d, ...) failed\n",
				      __FILE__, __LINE__, cpu_num);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
	}

	return (cpu_num);
}
int init_load_cpu_path(int cpu_no, cpu_load_path_t * path)
{
	int ret = 0;

	path->no = cpu_no;

	return (ret);
}

int init_load_cpu(int cpu_no, cpu_load_t * cpu)
{
	int ret = 0;
	char str[STR_LEN];

	cpu->cpu_sys = -1;
	cpu->cpu_usr = -1;
	cpu->cpu_iow = -1;
	cpu->cpu_idl = -1;

	ret = get_cpu_load(cpu_no, cpu);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_cpu_load() failed for CPU #%d\n",
			      __FILE__, __LINE__, cpu_load_path[cpu_no]->no);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	return (ret);
}

/* Get the number of CPUs and initialize their frequency structures */
int get_freq_cpus(void)
{
	int ret = 0;
	int i, cpu_no;
	char name[STR_LEN];
	char str[STR_LEN];
	char cpu_freq_dir[STR_LEN];

	cpu_freq_path =
	    (cpu_freq_path_t **) malloc(sizeof(cpu_freq_path_t *) * MAX_CPU);
	if (cpu_freq_path == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	cpu_freq = (cpu_freq_t **) malloc(sizeof(cpu_freq_t *) * MAX_CPU);
	if (cpu_freq == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	cpu_freq_num = 0;
	cpu_freq_path[0] = NULL;
	cpu_freq[0] = NULL;

	for (i = 0; i < MAX_CPU; i++) {
		(void)sprintf(name, "CPUFREQ_%d_PATH", i);
		ret = get_str_var_value(cpu_freq_dir, name);
		if (ret != 0) {
			continue;
		}
		(void)sprintf(name, "CPUFREQ_%d_NO", i);
		ret = get_str_var_value(foo_str, name);
		if (ret != 0) {
			continue;
		}
		cpu_no = atoi(foo_str);
		(void)sprintf(name, "%s/%s", cpu_freq_dir, cur_freq_file);
		if (access(name, R_OK) != 0) {
			cur_freq_file = cur_freq_file2;
			(void)sprintf(name, "%s/%s",
				      cpu_freq_dir, cur_freq_file);
			if (access(name, R_OK) != 0) {
				continue;
			}
		}
		cpu_freq_num++;

		cpu_freq_path[cpu_freq_num] =
		    (cpu_freq_path_t *) malloc(sizeof(cpu_freq_path_t));
		if (cpu_freq_path[cpu_freq_num] == NULL) {
			(void)sprintf(str, "File %s, Line %d: "
				      "malloc() failed\n", __FILE__, __LINE__);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
		/* Get CPU files paths */
		ret = init_freq_cpu_path(cpu_no, cpu_freq_dir,
					 cpu_freq_path[cpu_freq_num],
					 cur_freq_file);
		if (ret != 0) {
			(void)sprintf(str, "File %s, Line %d: "
				      "init_freq_cpu_path(%d, ...) failed\n",
				      __FILE__, __LINE__, i);
			(void)write_to_err_log(str);
			prog_exit(1);
		}

		cpu_freq[cpu_freq_num] =
		    (cpu_freq_t *) malloc(sizeof(cpu_freq_t));
		if (cpu_freq[cpu_freq_num] == NULL) {
			(void)sprintf(str, "File %s, Line %d: "
				      "malloc() failed\n", __FILE__, __LINE__);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
		/* Get initial CPU info */
		ret = init_freq_cpu(cpu_freq_num, cpu_freq[cpu_freq_num]);
		if (ret != 0) {
			(void)sprintf(str, "File %s, Line %d: "
				      "init_freq_cpu(%d, ...) failed\n",
				      __FILE__, __LINE__, cpu_freq_num);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
	}

	return (cpu_freq_num);
}

int
init_freq_cpu_path(int cpu_no, char *cpu_freq_dir,
		   cpu_freq_path_t * path, char *cur_freq_file)
{
	int ret = 0;
	char str[STR_LEN];

	path->no = cpu_no;

	path->cur_freq_file = (char *)malloc(STR_LEN);
	if (path->cur_freq_file == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "malloc() failed\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	(void)sprintf(path->cur_freq_file,
		      "%s/%s", cpu_freq_dir, cur_freq_file);

	(void)sprintf(str, "%s/stats/time_in_state", cpu_freq_dir);

	if (access(str, R_OK) == 0) {
		path->time_in_state_file = strdup(str);
	} else {
		(void)sprintf(str,
			      "Warning: cannot get CPU P states "
			      "configuration\n");
		(void)write_to_warning_log(str);
		path->time_in_state_file = NULL;
	}

	return (ret);
}

int init_freq_cpu(int cpu_no, cpu_freq_t * cpu)
{
	int ret = 0;
	char str[STR_LEN];

	cpu->cur_freq = -1;
	cpu->freq_num = 0;

	cpu->cur_freq = get_cur_freq(cpu_no, cpu);
	if (cpu->cur_freq < 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_cur_freq() failed for CPU #%d\n",
			      __FILE__, __LINE__, cpu_freq_path[cpu_no]->no);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	if (cpu_freq_path[cpu_no]->time_in_state_file != NULL) {
		cpu->freq_num =
		    get_time_in_state(cpu_freq_path[cpu_no]->time_in_state_file,
				      cpu->freq_value_array,
				      cpu->freq_time_array);
	}
	return (ret);
}

int
get_value_file(char *file_name, char *name, char *delim,
	       char *value, size_t size, int val_no)
{
	int ret = 0;
	int err = 0;
	int found = 0;
	FILE *file = NULL;
	char buf[STR_LEN];
	char str[STR_LEN];
	char *ptr;

	value[0] = 0;

	file = fopen(file_name, "r");
	if (file == NULL) {
		err = errno;
		(void)sprintf(str, "File %s, Line %d: "
			      "fopen(%s, r) failed with %d (%s)\n",
			      __FILE__, __LINE__,
			      file_name, err, strerror(err));
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	while ((ptr = fgets(buf, STR_LEN, file)) != NULL) {
		buf[strlen(buf) - 1] = '\0';
		ret = parse_string(buf, name, delim, value, size, val_no);
		if (ret == 0) {
			found = 1;
			break;
		}
	}
	if (err) {
		(void)sprintf(str, "File %s, Line %d: "
			      "fgets(%s) failed with %d (%s)\n",
			      __FILE__, __LINE__,
			      file_name, err, strerror(err));
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	if (!found) {
		ret = -1;
		goto end;
	}
      end:
	if (file != NULL) {
		(void)fclose(file);
		file = NULL;
	}
	return (ret);
}

int
get_value_pseudo_file(char *file_name, char *name,
		      char *delim, char *value, size_t size, int val_no)
{
	int ret = 0;
	int err = 0;
	int fd = -1;
	char buf[BUFF_LEN];
	char str[STR_LEN];
	ssize_t r_ret;
	size_t offset;
	char *ptr;
	int attempt = 0;

	while (attempt <= 10) {
		attempt++;
		fd = open(file_name, O_RDONLY);
		if (fd < 0) {
			err = errno;
			(void)sprintf(str, "File %s, Line %d: "
				      "open(%s, O_RDONLY) failed with %d (%s)\n",
				      __FILE__, __LINE__,
				      file_name, err, strerror(err));
			(void)write_to_err_log(str);
			prog_exit(1);
		}
		(void)memset(buf, 0, BUFF_LEN);
		errno = 0;
		r_ret = read(fd, buf, BUFF_LEN);
		err = errno;
		(void)close(fd);
		fd = -1;
		if (r_ret <= 0) {
			(void)sprintf(str, "File %s, Line %d: "
				      "read(%s, %d) failed, ret %ld, "
				      "errno %d (%s)\n",
				      __FILE__, __LINE__,
				      file_name, BUFF_LEN,
				      (long)r_ret, err, strerror(err));
			(void)write_to_work_out_log(str);
			if (attempt == 10) {
				prog_exit(1);
			}
			continue;
		}
		ptr = strstr(buf, "ERROR");
		if (ptr != NULL) {
			err = errno;
			(void)sprintf(str, "File %s, Line %d: "
				      "read(%s, %d) failed: "
				      "file contains ERROR message\n",
				      __FILE__, __LINE__, file_name, BUFF_LEN);
			(void)write_to_work_out_log(str);
			(void)write_to_work_out_log(buf);
			if (attempt == 10) {
				prog_exit(1);
			}
			continue;
		}
		if (attempt > 1) {
			(void)sprintf(str, "File %s, Line %d: "
				      "read(%s, %d) passed, attempt %d\n",
				      __FILE__, __LINE__,
				      file_name, BUFF_LEN, attempt);
			(void)write_to_work_out_log(str);
			(void)write_to_work_out_log("BUFF\n");
			(void)write_to_work_out_log(buf);
			(void)write_to_work_out_log("BUFF end\n");
		}
		break;
	}

	offset = 0;
	while (offset < strlen(buf)) {
		ptr = strchr(&buf[offset], '\n');
		(void)memset(str, 0, STR_LEN);
		(void)memcpy((char *)&str[0], (char *)&buf[offset],
			     (size_t) (ptr - &buf[offset]));
		ret = parse_string(str, name, delim, value, size, val_no);
		if (ret == 0) {
			break;
		}
		offset = ptr - &buf[0] + 1;
	}
	if (fd >= 0) {
		(void)close(fd);
		fd = -1;
	}

	return (ret);
}

int get_buf_pseudo_file(char *file_name, char *buf)
{
	int ret = 0;
	int err;
	int fd = -1;
	char str[STR_LEN];
	ssize_t r_ret;
	char *ptr;
	int attempt = 0;

	while (attempt <= 10) {
		attempt++;
		fd = open(file_name, O_RDONLY);
		if (fd < 0) {
			err = errno;
			(void)sprintf(str, "File %s, Line %d: "
				      "open(%s, O_RDONLY) failed with %d (%s)\n",
				      __FILE__, __LINE__,
				      file_name, err, strerror(err));
			(void)write_to_err_log(str);
			prog_exit(1);
		}
		(void)memset(buf, 0, BUFF_LEN);
		errno = 0;
		r_ret = read(fd, buf, BUFF_LEN);
		err = errno;
		(void)close(fd);
		fd = -1;
		if (r_ret <= 0) {
			(void)sprintf(str, "File %s, Line %d: "
				      "read(%s, %d) failed, ret %ld, "
				      "errno %d (%s)\n",
				      __FILE__, __LINE__,
				      file_name, BUFF_LEN,
				      (long)r_ret, err, strerror(err));
			(void)write_to_work_out_log(str);
			if (attempt == 10) {
				prog_exit(1);
			}
			continue;
		}
		ptr = strstr(buf, "ERROR");
		if (ptr != NULL) {
			err = errno;
			(void)sprintf(str, "File %s, Line %d: "
				      "read(%s, %d) failed: "
				      "file contains ERROR message\n",
				      __FILE__, __LINE__, file_name, BUFF_LEN);
			(void)write_to_work_out_log(str);
			(void)write_to_work_out_log(buf);
			if (attempt == 10) {
				prog_exit(1);
			}
			continue;
		}
		if (attempt > 1) {
			(void)sprintf(str, "File %s, Line %d: "
				      "read(%s, %d) passed, attempt %d\n",
				      __FILE__, __LINE__,
				      file_name, BUFF_LEN, attempt);
			(void)write_to_work_out_log(str);
			(void)write_to_work_out_log("BUFF\n");
			(void)write_to_work_out_log(buf);
			(void)write_to_work_out_log("BUFF end\n");
		}
		break;
	}

	if (fd >= 0) {
		(void)close(fd);
		fd = -1;
	}

	return (ret);
}

int
get_value_buf_pseudo_file(char *buf, char *name,
			  char *delim, char *value, size_t size, int val_no)
{
	int ret = 0;
	char str[STR_LEN];
	size_t offset;
	char *ptr;

	offset = 0;
	while (offset < strlen(buf)) {
		ptr = strchr(&buf[offset], '\n');
		(void)memset(str, 0, STR_LEN);
		(void)memcpy((char *)&str[0], (char *)&buf[offset],
			     (size_t) (ptr - &buf[offset]));
		ret = parse_string(str, name, delim, value, size, val_no);
		if (ret == 0) {
			break;
		}
		offset = ptr - &buf[0] + 1;
	}

	return (ret);
}

/* Parse string NAME DELIM VALUE */
int
parse_string(char *str, char *name, char *delim, char *value,
	     size_t size, int val_no)
{
	int i;
	int is_name = 0;
	int is_delim = 0;
	int off = -1;
	int ws = 0;
	int cnt = 0;
	int var_found = 0;
	int parse_ok = 0;

	(void)memset(value, 0, size);
	if (delim == NULL)
		is_delim = 1;
	for (i = 0; i <= strlen(str); i++) {
		if ((str[i] == ' ' || str[i] == '	') && !parse_ok) {
			if (!ws) {
				ws = 1;
				if (is_name && is_delim) {
					cnt++;
				}
			}
			if (!var_found || val_no) {
				off = -1;
				continue;
			}
		} else {
			ws = 0;
		}
		if (off == -1) {
			off = i;
		}
		if (!is_name) {
			if ((i - off + 1) > strlen(name)) {
				break;
			}
			if (str[i] != name[i - off]) {
				break;
			} else {
				parse_ok = 1;
			}
			if ((i - off + 1) == strlen(name)) {
				off = -1;
				is_name = 1;
				parse_ok = 0;
			}
			continue;
		}
		if (!is_delim) {
			if ((i - off + 1) > strlen(delim)) {
				break;
			}
			if (str[i] != delim[i - off]) {
				break;
			}
			if ((i - off + 1) == strlen(delim)) {
				off = -1;
				is_delim = 1;
			}
			continue;
		}
		if (cnt > val_no && val_no > 0)
			break;
		if (is_name && is_delim && (cnt == val_no || val_no == 0)) {
			var_found = 1;
			value[i - off] = str[i];
		}
	}

	if (!var_found)
		return (1);
	return (0);
}

int get_simple_pseudo_file(char *file_name, char *value)
{
	int ret = 0;
	int err = 0;
	int fd = -1;
	ssize_t r_ret;
	char str[STR_LEN];

	fd = open(file_name, O_RDONLY);
	if (fd < 0) {
		err = errno;
		(void)sprintf(str, "File %s, Line %d: "
			      "open(%s, O_RDONLY) failed with %d (%s)\n",
			      __FILE__, __LINE__,
			      file_name, err, strerror(err));
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	r_ret = read(fd, value, STR_LEN);
	if (r_ret < 0) {
		err = errno;
		(void)sprintf(str, "File %s, Line %d: "
			      "read(%s, %d) failed with %d (%s)\n",
			      __FILE__, __LINE__,
			      file_name, STR_LEN, err, strerror(err));
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	if (fd >= 0) {
		(void)close(fd);
		fd = -1;
	}
	return (ret);
}

int set_simple_pseudo_file(char *file_name, char *value)
{
	int ret = 0;
	int err = 0;
	int fd = -1;
	ssize_t w_ret;
	char str[STR_LEN];

	fd = open(file_name, O_RDWR | O_TRUNC);
	if (fd < 0) {
		err = errno;
		(void)sprintf(str, "File %s, Line %d: "
			      "open(%s, O_RDWR | O_TRUNC) failed with %d (%s)\n",
			      __FILE__, __LINE__,
			      file_name, err, strerror(err));
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	w_ret = write(fd, value, strlen(value));
	if (w_ret != strlen(value)) {
		err = errno;
		(void)sprintf(str, "File %s, Line %d: "
			      "write(%s, %lu) failed (%ld) with %d (%s)\n",
			      __FILE__, __LINE__,
			      file_name, (unsigned long)strlen(value),
			      (long)w_ret, err, strerror(err));
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	if (fd >= 0) {
		(void)close(fd);
		fd = -1;
	}
	return (ret);
}
