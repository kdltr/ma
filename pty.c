// pty
// 
// based on pty-example.c from Allen Porter <allen@thebends.org>


#include <stdio.h>
#include <errno.h>
#ifdef __APPLE__
# include <util.h>
# include <mach/mach.h>
# include <mach/mach_time.h>
#else
# include <pty.h>
#endif
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <poll.h>
#include <termios.h>
#include <time.h>


#define DELAY               250

#ifdef __APPLE__
// http://stackoverflow.com/questions/5167269/clock-gettime-alternative-in-mac-os-x
#define ORWL_NANO (+1.0E-9)
#define ORWL_GIGA UINT64_C(1000000000)

static double orwl_timebase = 0.0;
static uint64_t orwl_timestart = 0;


void orwl_gettime(struct timespec *t) {
  // be more careful in a multithreaded environment
  if (!orwl_timestart) {
    mach_timebase_info_data_t tb = { 0 };
    mach_timebase_info(&tb);
    orwl_timebase = tb.numer;
    orwl_timebase /= tb.denom;
    orwl_timestart = mach_absolute_time();
  }

  double diff = (mach_absolute_time() - orwl_timestart) * orwl_timebase;
  t->tv_sec = diff * ORWL_NANO;
  t->tv_nsec = diff - (t->tv_sec * ORWL_GIGA);
}

#define clock_gettime(x, y)  orwl_gettime(y)
#endif


void usage(int code)
{
   fprintf(stderr, "usage: pty COMMAND ...\n");
   exit(code);
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

    fprintf(stderr, "program exited.\n");
    return 1;
  }

  struct termios ti;
  tcgetattr(fd, &ti);
  ti.c_lflag &= ~(ECHO | ECHONL);
  ti.c_cc[ VMIN ] = 1;
  ti.c_cc[ VTIME ] = 0;
  tcsetattr(fd, TCSANOW, &ti);
  int flags;

  if((flags = fcntl(fd, F_GETFL, 0)) == -1)
    flags = 0;

  if (fcntl(fd, F_SETFL, flags | O_NONBLOCK) == -1) {
    perror("fcntl");
    return 1;
  }

  struct pollfd pfd[ 2 ];
  pfd[ 0 ].fd = STDIN_FILENO;
  pfd[ 0 ].events = POLLIN;
  pfd[ 1 ].fd = fd;
  pfd[ 1 ].events = POLLOUT;
  char buf[ 1024 ];
  int hup = 0;
  struct timespec tm0;

  for(;;) {    
    pfd[ 0 ].revents = pfd[ 1 ].revents = 0;
    int r = poll(pfd, 2, 100);

    if(r == -1) {
      perror("poll");
      return 1;
    }

    if(r > 0) {
      if((pfd[ 0 ].revents & POLLERR) != 0) {
        close(fd);
        return 0;
      }

      if((pfd[ 0 ].revents & POLLHUP) != 0 && !hup) {
        hup = 1;
        clock_gettime(CLOCK_MONOTONIC, &tm0);
      }

      if((pfd[ 0 ].revents & POLLIN) != 0) {
        int n = read(STDIN_FILENO, buf, 1023);

        if(n == -1) {
          perror("read from stdin");
          return 1;
        } 
        else if(n == 0) {
          close(fd);
          return 0;
        }

        if(write(fd, buf, n) == -1) {
          perror("write to subprocess");
          return 1;
        }
      }

      if((pfd[ 1 ].revents & POLLOUT) != 0) {
        int n = read(fd, buf, 1023);

        if(n == -1) {
          switch(errno) {
          case EAGAIN:
            if(hup) {
              struct timespec tm;
              clock_gettime(CLOCK_MONOTONIC, &tm);
              double td = (tm.tv_sec * 1000.0 + tm.tv_nsec / 1000000.0) -
                          (tm0.tv_sec * 1000.0 + tm0.tv_nsec / 1000000.0);

              // stop when stdin is done and DELAY ms have passed
              if(td > DELAY) {
                close(fd);
                return 0;
              }
            }

            usleep(10000);
            break;
          
          case EIO:
            // usually process finished
            return 0;

          default:
            perror("read from subprocess");
            return 1;
          }
        } 
        else if(n == 0) {
          close(fd);
          return 0;
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
