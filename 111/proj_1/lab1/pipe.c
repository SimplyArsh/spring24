#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <errno.h>
#include <string.h>

int main (int argc, char *argv[]) {
    
    enum PIPES {
        READ, WRITE
    };
    errno = 0;
    int NUM_PROCESSES = argc - 1;
    int fd[2*(NUM_PROCESSES-1)];
    int stderr_id;

    for (int i = 0; i < NUM_PROCESSES; i++) {
        if (pipe(fd + 2*i) == -1) {
            perror("error with pipe");
            exit(EXIT_FAILURE);
        }
    }

    pid_t pid = fork();
    if (pid == 0) {
        dup2(fd[WRITE], 1);
        dup2(stderr_id, 2);
        char *prog_name = argv[1];
        execlp(prog_name, prog_name, NULL);
        printf("error");
        exit(errno);
    } 
    else {
        close(fd[WRITE]);
        int status;
        waitpid(pid, &status, 0);
        if ( WIFEXITED(status) ) {
            errno = WEXITSTATUS(status);
            if (errno != 0) {
                exit(errno);
            }
        }
    }

    for (int i = 1; i < NUM_PROCESSES-1; i++) {
        pid = fork();
        if (pid == 0) {
            dup2(fd[2*(i-1) + READ], 0);
            dup2(fd[2*i + WRITE], 1);
            char *prog_name = argv[i+1];
            execlp(prog_name, prog_name, NULL);
            printf("error");
            exit(errno);    
        }
        else {
            close(fd[2*i + WRITE]);
            int status;
            waitpid(pid, &status, 0);
            if ( WIFEXITED(status) ) {
                errno = WEXITSTATUS(status);
                if (errno != 0) {
                    exit(errno);
                }
            }
        }
    }

    if (NUM_PROCESSES > 1) {
        pid = fork();
        if (pid == 0) {
            dup2(fd[2*(NUM_PROCESSES-2) + READ], 0);
            char *prog_name = argv[NUM_PROCESSES];
            execlp(prog_name, prog_name, NULL);
            exit(errno);
        }

        int status;
        waitpid(pid, &status, 0);
        if ( WIFEXITED(status) ) {
            errno = WEXITSTATUS(status);
            if (errno != 0) {
                exit(errno);
            }
        }
        exit(0);
    }
    
}