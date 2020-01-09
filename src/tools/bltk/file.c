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
#include <stdlib.h>
#include <limits.h>
#include <ctype.h>

#include "bltk.h"

extern int errno;

static void sort_time_in_state(int cnt, ull_t * st, ull_t * tm);

/* Get the state of AC adapter */
int get_ac_state(void)
{
	int ret;
	char buf[BUFF_LEN];
	char str[STR_LEN];

	ret = get_value_pseudo_file(ac_adapter_state_path, state_name,
				    DEF_COLON, buf, BUFF_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_pseudo_file(%s) for %s file failed\n",
			      __FILE__, __LINE__,
			      state_name, ac_adapter_state_path);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	if (strcmp(buf, DEF_ON_STATE) == 0) {
		ac_state = ON_STATE;
	} else if (strcmp(buf, DEF_OFF_STATE) == 0) {
		ac_state = OFF_STATE;
	} else {
		(void)sprintf(str, "File %s, Line %d: "
			      "Cannot parse AC state\n", __FILE__, __LINE__);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	return (ac_state);
}

/* Wait for certain AC state, with every 1 second checks */
int wait_ac_state(int state)
{
	int ret = EMPTY_VALUE;

	while (1) {
		ret = get_ac_state();
		if (ret == state || ret == EMPTY_VALUE) {
			break;
		} else {
			(void)prog_sleep(1);
		}
	}
	return (ret);
}

/* Get current bat charge value, etc */
int get_bat_charge(int bat_no, bat_state_t * bat)
{
	int ret = 0, i;
	char full_buf[BUFF_LEN];
	char buf[BUFF_LEN];
	char str[STR_LEN];
	char *file_name;

	file_name = bat_path[bat_no]->stat_p;
	ret = get_buf_pseudo_file(file_name, full_buf);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_buf_pseudo_file(%s) failed\n",
			      __FILE__, __LINE__, file_name);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	ret = get_value_buf_pseudo_file(full_buf, DEF_CUR_CHARGE_NAME,
					DEF_COLON, buf, BUFF_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_buf_pseudo_file(%s, %s) failed\n",
			      __FILE__, __LINE__,
			      file_name, DEF_CUR_CHARGE_NAME);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	bat->cur_cap = atoi(buf);

	ret = get_value_buf_pseudo_file(full_buf, DEF_CUR_VOLTAGE_NAME,
					DEF_COLON, buf, BUFF_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_buf_pseudo_file(%s, %s) failed\n",
			      __FILE__, __LINE__,
			      file_name, DEF_CUR_VOLTAGE_NAME);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	bat->cur_vol = atoi(buf);

	ret = get_value_buf_pseudo_file(full_buf, DEF_CUR_RATE_NAME,
					DEF_COLON, buf, BUFF_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_buf_pseudo_file(%s, %s) failed\n",
			      __FILE__, __LINE__, file_name, DEF_CUR_RATE_NAME);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	bat->cur_rate = atoi(buf);

	ret = get_value_buf_pseudo_file(full_buf, DEF_CAPACITY_STATE_NAME,
					DEF_COLON, buf, BUFF_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_buf_pseudo_file(%s, %s) failed\n",
			      __FILE__, __LINE__, file_name,
			      DEF_CAPACITY_STATE_NAME);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	bat->cap_state = MAX_CAP_STATES;
	for (i = 0; i < MAX_CAP_STATES; i++) {
		if (strcmp(buf, bat_cap_states[i]) == 0) {
			bat->cap_state = i;
			break;
		}
	}

	ret = get_value_buf_pseudo_file(full_buf, DEF_CHARGING_STATE_NAME,
					DEF_COLON, buf, BUFF_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_buf_pseudo_file(%s, %s) failed\n",
			      __FILE__, __LINE__, file_name,
			      DEF_CHARGING_STATE_NAME);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	bat->charge_state = MAX_CHARGE_STATES;
	for (i = 0; i < MAX_CHARGE_STATES; i++) {
		if (strcmp(buf, bat_charge_states[i]) == 0) {
			bat->charge_state = i;
			break;
		}
	}

	return (bat->cur_cap);
}

int get_bat_charge_state(int bat_no)
{
	int ret = EMPTY_VALUE;
	int i;
	char buf[BUFF_LEN];
	char str[STR_LEN];

	ret = get_value_pseudo_file(bat_path[bat_no]->stat_p,
				    DEF_CHARGING_STATE_NAME, DEF_COLON, buf,
				    BUFF_LEN, 1);
	if (ret != 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "get_value_pseudo_file(%s) failed\n",
			      __FILE__, __LINE__, DEF_CHARGING_STATE_NAME);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	for (i = 0; i < MAX_CHARGE_STATES; i++) {
		if (strcmp(buf, bat_charge_states[i]) == 0) {
			return (i);
		}
	}
	(void)sprintf(str, "File %s, Line %d: "
		      "Unknown bat state (%s)\n", __FILE__, __LINE__, buf);
	(void)write_to_err_log(str);
	prog_exit(1);
	return (EMPTY_VALUE);
}

/* Get current CPU frequency */
int get_time_in_state(char *fname, ull_t * st, ull_t * tm)
{
	int fd = EMPTY_VALUE;
	char str[STR_LEN];
	char buf[BUFF_LEN];
	char *ptr, *ptr1;
	int i, rw, cnt, ret;

	fd = open(fname, O_RDONLY);
	if (fd < 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "open(%s) failed\n", __FILE__, __LINE__, fname);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	(void)memset(buf, 0, BUFF_LEN);
	rw = read(fd, buf, BUFF_LEN);
	if (rw < 0 || rw > BUFF_LEN - 1) {
		(void)sprintf(str, "File %s, Line %d: "
			      "read from %s failed\n",
			      __FILE__, __LINE__, fname);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	ptr = buf;
	ptr1 = ptr;
	cnt = 0;
	for (i = 0; i < rw; i++) {
		if (ptr[i] == '\n') {
			ptr[i] = 0;
			ret = sscanf(ptr1, "%llu %llu", &st[cnt], &tm[cnt]);
			if (ret != 2) {
				(void)sprintf(str,
					      "time_in_state: sscanf() failed, "
					      "str - %s\n", ptr1);
				(void)write_to_err_log(str);
				prog_exit(1);
			}
			ptr1 = ptr + i + 1;
			cnt++;
		}
	}
	(void)close(fd);

	sort_time_in_state(cnt, st, tm);

	return (cnt);
}

static void sort_time_in_state(int cnt, ull_t * st, ull_t * tm)
{
	int i, j;
	ull_t st_saved, tm_saved;

	for (j = 0; j < cnt - 1; j++) {
		for (i = 0; i < cnt - 1 - j; i++) {
			if (st[i] < st[i + 1]) {
				st_saved = st[i];
				tm_saved = tm[i];
				st[i] = st[i + 1];
				tm[i] = tm[i + 1];
				st[i + 1] = st_saved;
				tm[i + 1] = tm_saved;
			}
		}
	}
}

static char *get_field(char *line, int field_no, char *res_field)
{
	int i, cur_field_no = 0, v, in_field = 0;
	int sz = strlen(line);
	char *field = NULL;

	res_field[0] = 0;
	for (i = 0; i < sz; i++) {
		v = line[i];
		if (in_field) {
			if (isspace(v)) {
				in_field = 0;
				if (cur_field_no == field_no) {
					line[i] = 0;
					(void)strcpy(res_field, field);
					line[i] = v;
					return (res_field);
				}
			}
			continue;
		}
		if (isspace(v)) {
			continue;
		}
		in_field = 1;
		field = line + i;
		cur_field_no++;
	}
	if (in_field && cur_field_no == field_no) {
		(void)strcpy(res_field, field);
		return (res_field);
	}
	return (NULL);
}

/* Get current CPU intrrupts */
int get_cpu_intr(cpu_intr_t * cpu_intr)
{
	int fd = EMPTY_VALUE;
	char str[STR_LEN];
	char buf[BUFF_LEN];
	char field[STR_LEN];
	char *ptr, *ptr1, *fieldp;
	int i, j, rw, no_cnt;
	char *fname = proc_interrupts_path;

	cpu_intr->cpu_num = 0;

	fd = open(fname, O_RDONLY);
	if (fd < 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "open(%s) failed\n", __FILE__, __LINE__, fname);
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	(void)memset(buf, 0, BUFF_LEN);
	rw = read(fd, buf, BUFF_LEN);
	(void)close(fd);
	fd = EMPTY_VALUE;
	if (rw < 0 || rw > BUFF_LEN - 1) {
		(void)sprintf(str, "File %s, Line %d: "
			      "read from %s failed\n",
			      __FILE__, __LINE__, fname);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	ptr = buf;
	ptr1 = ptr;
	no_cnt = 0;
	for (i = 0; i < rw; i++) {
		if (ptr[i] == '\n') {
			ptr[i] = 0;
			if (strstr(ptr1, " CPU") != NULL) {
				for (j = 1; j <= MAX_CPU; j++) {
					cpu_intr->timer[j] = 0;
					cpu_intr->others[j] = 0;
					fieldp = get_field(ptr1, j, field);
					if (fieldp == NULL) {
						break;
					}
					if (strncmp(fieldp, "CPU", 3) != 0) {
						break;
					}
					cpu_intr->cpu_no[j] = atoi(fieldp + 3);
					no_cnt++;
				}
			} else if (strstr(ptr1, " timer") != NULL) {
				for (j = 1; j <= no_cnt; j++) {
					fieldp = get_field(ptr1, j + 1, field);
					if (fieldp == NULL) {
						break;
					}
					cpu_intr->timer[j] += atoi(fieldp);
				}
			} else if (strstr(ptr1, "MMI:") != NULL) {
				continue;
			} else if (strstr(ptr1, "LOC:") != NULL) {
				continue;
			} else if (strstr(ptr1, "ERR:") != NULL) {
				continue;
			} else if (strstr(ptr1, "MIS:") != NULL) {
				continue;
			} else if (strstr(ptr1, ":") != NULL) {
				for (j = 1; j <= no_cnt; j++) {
					fieldp = get_field(ptr1, j + 1, field);
					if (fieldp == NULL) {
						break;
					}
					cpu_intr->others[j] += atoi(fieldp);
				}
			}
			ptr1 = ptr + i + 1;
		}
	}
	cpu_intr->cpu_num = no_cnt;
	return (0);
}

ull_t
get_average_time_in_state(int cnt, ull_t * st, ull_t * prev_tm, ull_t * cur_tm)
{
	int i;
	ull_t st_tm_sum = 0;
	ull_t tm_sum = 0;
	ull_t res = 0;

	for (i = 0; i < cnt; i++) {
		st_tm_sum += st[i] * (cur_tm[i] - prev_tm[i]);
		tm_sum += (cur_tm[i] - prev_tm[i]);
	}

	if (tm_sum != 0) {
		res = st_tm_sum / tm_sum;
	} else {
		res = 0;
	}

	return (res);
}

int cp_time_in_state(int cnt, ull_t * src_tm, ull_t * dst_tm)
{
	int i;

	for (i = 0; i < cnt; i++) {
		dst_tm[i] = src_tm[i];
	}

	return (0);
}

int get_cur_freq(int cpu_no, cpu_freq_t * cpu)
{
	int ret = 0;
	char buf[BUFF_LEN];
	char str[STR_LEN];

	cpu->freq_num = 0;

	if (cpu_freq_path[cpu_no]->time_in_state_file != NULL) {
		cpu->freq_num =
		    get_time_in_state(cpu_freq_path[cpu_no]->time_in_state_file,
				      cpu->freq_value_array,
				      cpu->freq_time_array);
	} else {
		(void)memset(buf, 0, BUFF_LEN);
		ret =
		    get_simple_pseudo_file(cpu_freq_path[cpu_no]->cur_freq_file,
					   buf);
		if (ret != 0) {
			(void)sprintf(str, "File %s, Line %d: "
				      "get_simple_pseudo_file(%s) failed\n",
				      __FILE__, __LINE__,
				      cpu_freq_path[cpu_no]->cur_freq_file);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
	}
	cpu->cur_freq = atoi(buf);

	return (cpu->cur_freq);
}

/* Get current CPU load */
int get_cpu_load(int cpu_no, cpu_load_t * cpu)
{
	int ret = 0;
	int err = 0;
	int fd = EMPTY_VALUE;
	ssize_t r_ret;
	char buf[BUFF_LEN];
	char cpu_name[STR_LEN];
	char str[STR_LEN];
	char *ptr = NULL;
	ull_t dummy;

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

	(void)sprintf(cpu_name, "cpu%d ", cpu_load_path[cpu_no]->no);
	ptr = strstr(buf, cpu_name);
	if (ptr == NULL) {
		(void)sprintf(str, "File %s, Line %d: "
			      "strstr(%s, %s) failed.\n",
			      __FILE__, __LINE__, buf, cpu_name);
		(void)write_to_err_log(str);
		prog_exit(1);
	}

	ptr += strlen(cpu_name);
	ret = sscanf(ptr, " %llu %llu %llu %llu %llu",
		     &cpu->cpu_usr, &dummy,
		     &cpu->cpu_sys, &cpu->cpu_idl, &cpu->cpu_iow);
	if (ret != 5) {
		cpu->cpu_iow = 0;
		ret = sscanf(ptr, " %llu %llu %llu %llu",
			     &cpu->cpu_usr, &dummy,
			     &cpu->cpu_sys, &cpu->cpu_idl);
		if (ret != 4) {
			(void)sprintf(str, "File %s, Line %d: "
				      "sscanf(%s) returned %d instead of 5.\n",
				      __FILE__, __LINE__, ptr, ret);
			(void)write_to_err_log(str);
			prog_exit(1);
		}
	}
	ret = 0;

	if (fd >= 0) {
		(void)close(fd);
		fd = EMPTY_VALUE;
	}
	return (ret);
}
static void get_cpu_tstate_state(int cpu_no, cpu_cstate_state_t * cpu)
{
	int err = 0, sz;
	int fd = EMPTY_VALUE;
	ssize_t r_ret;
	char buf[BUFF_LEN];
	char str[STR_LEN];
	char *ptr = NULL;
	char field[STR_LEN];
	char *fieldp;

	cpu->t_state = 0;
	cpu->t_state_present = 0;
	fd = open(cpu_cstate_path[cpu_no]->t_state_file, O_RDONLY);
	if (fd < 0) {
		return;
	}
	(void)memset(buf, 0, BUFF_LEN);
	r_ret = read(fd, buf, BUFF_LEN);
	if (r_ret <= 0) {
		err = errno;
		(void)sprintf(str, "File %s, Line %d: "
			      "read(%s) failed with %d (%s)\n",
			      __FILE__, __LINE__,
			      cpu_cstate_path[cpu_no]->t_state_file,
			      err, strerror(err));
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	ptr = strstr(buf, "*T");
	if (ptr != NULL) {
		fieldp = get_field(ptr, 2, field);
		if (fieldp) {
			sz = strlen(fieldp);
			if (sz) {
				fieldp[sz - 1] = 0;
				cpu->t_state = atoi(fieldp);
			}
			cpu->t_state_present = 1;
		}
	}

	if (fd >= 0) {
		(void)close(fd);
		fd = EMPTY_VALUE;
	}
	return;
}

/* Get current CPU C-states usage (returns number of asquired C-states) */
int get_cpu_cstate_states(int cpu_no, cpu_cstate_state_t * cpu)
{
	int ret = 0;
	int err = 0;
	int fd = EMPTY_VALUE;
	int i;
	ssize_t r_ret;
	char buf[BUFF_LEN];
	char cpu_name[STR_LEN];
	char str[STR_LEN];
	char *ptr = NULL;
	char *ptr2 = NULL;

	get_cpu_tstate_state(cpu_no, cpu);

	fd = open(cpu_cstate_path[cpu_no]->c_state_file, O_RDONLY);
	if (fd < 0) {
		(void)sprintf(str, "File %s, Line %d: "
			      "open(%s) failed\n",
			      __FILE__, __LINE__,
			      cpu_cstate_path[cpu_no]->c_state_file);
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
			      cpu_cstate_path[cpu_no]->c_state_file,
			      err, strerror(err));
		(void)write_to_err_log(str);
		prog_exit(1);
	}
	cpu->bus_master_present = 0;
	ptr = strstr(buf, "bus master activity:");
	if (ptr != NULL) {
		ptr += strlen("bus master activity:");
		ret = sscanf(ptr, "%s", cpu->bus_master_string);
		if (ret == 1) {
			cpu->bus_master_present = 1;
		} else {
			(void)strcpy(cpu->bus_master_string, "0");
		}
	}else strcpy(cpu->bus_master_string, "0");

	cpu->num_cstate_states = 0;
	ptr2 = NULL;
	for (i = 0; i < MAX_C_STATES; i++) {
		if (ptr2 != NULL) {
			ptr2[0] = '\n';
			ptr2 = NULL;
		}
		cpu->c_present[i] = 0;
		cpu->c_usage[i] = 0;
		cpu->cd_present[i] = 0;
		cpu->c_duration[i] = 0;
		(void)sprintf(cpu_name, "C%d:", i);
		ptr = strstr(buf, cpu_name);
		if (ptr == NULL) {
			continue;
		}
		ret = cpu->num_cstate_states = i + 1;
		ptr2 = strstr(ptr, "\n");
		if (ptr2 != NULL) {
			ptr2[0] = 0;
		}
		(void)sprintf(cpu_name, "usage[");
		ptr = strstr(ptr, cpu_name);
		if (ptr == NULL) {
			cpu->c_present[i] = 2;
			cpu->cd_present[i] = 2;
			continue;
		}
		ret = sscanf(ptr, "usage[%llu]", &cpu->c_usage[i]);
		if (ret == 1) {
			cpu->c_present[i] = 1;
		} else {
			cpu->c_usage[i] = 0;
			cpu->c_present[i] = 2;
		}
		(void)sprintf(cpu_name, "duration[");
		ptr = strstr(ptr, cpu_name);
		if (ptr == NULL) {
			continue;
		}
		ret = sscanf(ptr, "duration[%llu]", &cpu->c_duration[i]);
		if (ret == 1) {
			cpu->cd_present[i] = 1;
		} else {
			cpu->c_duration[i] = 0;
			cpu->cd_present[i] = 2;
		}
	}

	if (fd >= 0) {
		(void)close(fd);
		fd = EMPTY_VALUE;
	}
	return (ret);
}
