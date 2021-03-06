/* Based on setproctitle.c from openssh-5.6p1 */
/* Based on conf.c from UCB sendmail 8.8.8 */

/*
 * Copyright 2003 Damien Miller
 * Copyright (c) 1983, 1995-1997 Eric P. Allman
 * Copyright (c) 1988, 1993
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#ifndef _GNU_SOURCE
#define _GNU_SOURCE 1
#endif

#undef HAVE_SETPROCTITLE

#ifndef HAVE_SETPROCTITLE

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include <memory.h>
#include <errno.h>
#include <sched.h>
#include <sys/types.h>
#ifdef HAVE_SYS_PSTAT_H
#include <sys/pstat.h>
#endif

#if defined(CONFIG_DARWIN)
#include <crt_externs.h>
#undef environ
#define environ (*_NSGetEnviron())
#endif

#define SPT_NONE	0	/* don't use it at all */
#define SPT_PSTAT	1	/* use pstat(PSTAT_SETCMD, ...) */
#define SPT_REUSEARGV	2	/* cover argv with title information */

#ifndef SPT_TYPE
# define SPT_TYPE	SPT_REUSEARGV //SPT_NONE
#endif

#ifndef SPT_PADCHAR
# define SPT_PADCHAR	'\0'
#endif

#if SPT_TYPE == SPT_REUSEARGV
static char *argv_start = NULL;
static size_t argv_env_len = 0;
static size_t argv_len = 0;
#endif

#endif /* HAVE_SETPROCTITLE */

char **
setproctitle_init(int argc, char *argv[])
{
#if defined(SPT_TYPE) && SPT_TYPE == SPT_REUSEARGV
	extern char **environ;
	char *lastargv = NULL;
	char *lastenvp = NULL;
	char **envp = environ;
	int i;

	/*
	 * NB: This assumes that argv has already been copied out of the
	 * way. This is true for sshd, but may not be true for other
	 * programs. Beware.
	 */

	if (argc == 0 || argv[0] == NULL)
		return argv;

	/* Fail if we can't allocate room for the new environment */
	for (i = 0; envp[i] != NULL; i++)
		;
	if ((environ = calloc(i + 1, sizeof(*environ))) == NULL) {
		environ = envp;	/* put it back */
		return argv;
	}

	/*
	 * Find the last argv string or environment variable within
	 * our process memory area.
	 */
	for (i = 0; i < argc; i++) {
		if (lastargv == NULL || lastargv + 1 == argv[i])
			lastargv = argv[i] + strlen(argv[i]);
	}
	lastenvp = lastargv;
	for (i = 0; envp[i] != NULL; i++) {
		if (lastenvp + 1 == envp[i])
			lastenvp = envp[i] + strlen(envp[i]);
	}

	argv[1] = NULL;
	argv_start = argv[0];
	argv_len = lastargv - argv[0];
	argv_env_len = lastenvp - argv[0];

	for (i = 0; envp[i] != NULL; i++)
		environ[i] = strdup((const char *)envp[i]);
	environ[i] = NULL;
#endif /* SPT_REUSEARGV */
	return argv;
}

#ifndef HAVE_SETPROCTITLE
void
setproctitle(const char *fmt, ...)
{
#if SPT_TYPE != SPT_NONE
	va_list ap;
	char ptitle[1024] = { 0 };
	size_t len;
	size_t argvlen;
#if SPT_TYPE == SPT_PSTAT
	union pstun pst;
#endif

#if SPT_TYPE == SPT_REUSEARGV
	if (argv_env_len <= 0)
		return;
#endif

	va_start(ap, fmt);
	if (fmt != NULL) {
		vsnprintf(ptitle, sizeof(ptitle) - 1, fmt, ap);
	}
	va_end(ap);

#if SPT_TYPE == SPT_PSTAT
	pst.pst_command = ptitle;
	pstat(PSTAT_SETCMD, pst, strlen(ptitle), 0, 0);
#elif SPT_TYPE == SPT_REUSEARGV
	strncpy(argv_start, ptitle, argv_env_len);
	len = strlen(ptitle);
	argvlen = len > argv_len ? argv_env_len : argv_len;
	for(; len < argvlen; len++)
		argv_start[len] = SPT_PADCHAR;
#endif

#endif /* SPT_NONE */
}

#endif /* HAVE_SETPROCTITLE */
/*
int                                                                             
cpu_set_affinity(int id, int mode, int cpu)                                     
{                                                                               
	cpu_set_t mask;
	CPU_ZERO(&mask);
	CPU_SET(cpu, &mask);
				                                                                                
	if (sched_setaffinity(id, sizeof(mask), &mask) == -1)
		return -EINVAL;

	return 0;                                                               
}
*/
/* 
if (prctl(PR_SET_PDEATHSIG, SIGHUP) < 0)
die("prctl reason=%s", strerror(errno));
debug4("prctl type=PR_SET_PDEATHSIG sig=SIGHUP");
*/
	
