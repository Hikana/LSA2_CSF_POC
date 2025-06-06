#!/bin/bash

bpftrace -e '
tracepoint:syscalls:sys_enter_execve
/ str(args->filename) == "/bin/bash" ||
  str(args->filename) == "/bin/sh"   ||
  str(args->filename) == "/usr/bin/zsh" ||
  str(args->filename) == "/usr/bin/python" ||
  str(args->filename) == "/usr/bin/perl" ||
  str(args->filename) == "/usr/bin/nc" ||
  str(args->filename) == "/usr/bin/netcat" ||
  str(args->filename) == "/usr/bin/socat" ||
  str(args->filename) == "/usr/bin/telnet" /
{
  printf("Time: %s\n", strftime("%H:%M:%S", nsecs));
  printf("UID=%d PID=%d CMD=%s FILE=%s\n", uid, pid, comm, str(args->filename));
  printf("  ARGV[0]: %s\n", str(args->argv[0]));
  printf("  ARGV[1]: %s\n", str(args->argv[1]));
  printf("  ARGV[2]: %s\n", str(args->argv[2]));
  printf("  ARGV[3]: %s\n", str(args->argv[3]));
  printf("  ARGV[4]: %s\n", str(args->argv[4]));
  printf("  ARGV[5]: %s\n", str(args->argv[5]));
  printf("  ARGV[6]: %s\n", str(args->argv[6]));
  printf("  ARGV[7]: %s\n", str(args->argv[7]));
  printf("  ARGV[8]: %s\n", str(args->argv[8]));
  printf("  ARGV[9]: %s\n", str(args->argv[9]));
}
' >> ./php_ctf/ebpf.txt
