// pty
// 
// based on pty-example.c from Allen Porter <allen@thebends.org>


#include <stdio.h>
#include <errno.h>
#ifdef __linux__
# include <pty.h>
#else
# include <util.h>
#endif
#ifdef __APPLE__
# include <mach/mach.h>
# include <mach/mach_time.h>
#endif
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <poll.h>
#include <termios.h>
#include <time.h>
#include <signal.h>
#include <sys/wait.h>


static volatile int sigint = 0;


static void usage(int code)
{
   fprintf(stderr, "usage: pty COMMAND ...\n");
   exit(code);
}


static void sighandler(int sig)
{
    sigint = 1;
}


static int exit_status(pid_t pid)
{
    int status;
    pid_t p = waitpid(pid, &status, 0);

    if(p == -1) perror("waitpid");

    if(p == 0) return 0;

    if(WIFEXITED(status)) 
        return WEXITSTATUS(status); 
    else if(WIFSIGNALED(status))
        return WTERMSIG(status);

    return 1;
}


int main(int argc, char* argv[]) 
{
  if(argc == 1) usage(1);

  setsid();
  int fd;
  pid_t pid = forkpty(&fd, NULL, NULL, NULL);

  if(pid == -1) {
    perror("forkpty");
    return 1;
  } 
  else if(pid == 0) {
    static char *args[ 256 ];
    memcpy(args, argv + 1, (argc + 1) * sizeof(char *));
 
    if(execvp(args[ 0 ], args) == -1)
      perror("execvp");

    return 1;
  }

  struct sigaction act;
  act.sa_handler = sighandler;
  act.sa_flags = 0;
  sigemptyset(&act.sa_mask);
  
  if(sigaction(SIGINT, &act, NULL) == -1)
    perror("sigaction");

  struct termios ti;
  tcgetattr(fd, &ti);
  ti.c_lflag &= ~(ECHO | ECHONL);
  ti.c_cc[ VMIN ] = 1;
  ti.c_cc[ VTIME ] = 0;
  tcsetattr(fd, TCSANOW, &ti);
  int flags;

  struct pollfd pfd[ 2 ];
  pfd[ 0 ].fd = STDIN_FILENO;
  pfd[ 0 ].events = POLLIN;
  pfd[ 1 ].fd = fd;
  pfd[ 1 ].events = POLLIN;
  char buf[ 1024 ];

  for(;;) {    
    pfd[ 0 ].revents = pfd[ 1 ].revents = 0;

    if(sigint) {
        pid_t tpgid = tcgetpgrp(fd);

        if(tpgid != -1) kill(-tpgid, SIGINT);

        sigint = 0;
    }

    int r = poll(pfd, 2, -1);

    if(r == -1) {
         if(errno != EINTR) {
               perror("poll");
               return 1;
         }
    }

    if(r > 0) {
      if((pfd[ 0 ].revents & POLLERR) != 0
         || (pfd [ 0 ].revents & POLLHUP) != 0
         || (pfd [ 1 ].revents & POLLHUP) != 0) {
        close(fd);
        return exit_status(pid);
      }

      if((pfd[ 0 ].revents & POLLIN) != 0) {
        int n = read(STDIN_FILENO, buf, 1023);

        if(n == -1) {
          perror("read from stdin");
          return 1;
        } 
        else if(n == 0) {
          close(fd);
          return exit_status(pid);
        }

        if(write(fd, buf, n) == -1) {
          perror("write to subprocess");
          return 1;
        }
      }

      if((pfd[ 1 ].revents & POLLIN) != 0) {
        int n = read(fd, buf, 1023);

        if(n == -1) {
          switch(errno) {
          case EIO:
            /* usually process finished */
            return exit_status(pid);

          default:
            perror("read from subprocess");
            return 1;
          }
        } 
        else if(n == 0) {
          close(fd);
          return exit_status(pid);
        } 
        else {
          if(write(STDOUT_FILENO, buf, n) == -1) {
            perror("write to stdout");
            return 1;
          }
        }
      }
    }
  }
}
