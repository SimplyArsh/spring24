#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <errno.h>
#include <string.h>

// int main(int argc, char *argv[])
// {
// 	errno = 0;
// 	print("here\n");
// 	if (argc == 1) {
// 		errno = EINVAL;
// 		fprintf(stderr, "%s\n", strerror(errno));
// 		exit(EXIT_FAILURE);
// 	}

// 	pid_t p = 0;
// 	int NUM_PROCESSES = argc-2;
// 	int fd[2*NUM_PROCESSES];

// 	for (int i = 0; i < NUM_PROCESSES; i++) {
//         if (pipe(fd + 2 * i) == -1) {
//             perror("pipe");
//             exit(EXIT_FAILURE);
//         }
//     }

// 	while (argc && p==0) {
// 		p = fork();
// 		if (p < 0) {
// 			fprintf(stderr, "%s\n", strerror(errno));
// 		}
// 		argc--;
// 	}

// 	if (argc == 1) {
// 		dup2(fd[1], 1);
// 	}
// 	else if (argc == NUM_PROCESSES) {
// 		dup2(fd[2*(argc-2)], 0);
// 	}
// 	else {
// 		dup2(fd[2*(argc-2)], 0);
// 		dup2(fd[2*(argc-1)+1], 1);
// 		close(fd[2*(argc-2)+1]);
// 	}

// 	char* prog_name = argv[argc];
// 	execlp(prog_name, prog_name);
	
// 	int status;
//     if (waitpid(p, &status, 0) == -1) {
//             perror("waitpid");
//             return EXIT_FAILURE;
// 	}

// 	return EXIT_SUCCESS;
// }

// int main(int argc, char *argv[]) {

//     if (argc < 2) {
//         fprintf(stderr, "No pipe functions passed\n");
//         return EXIT_FAILURE;
//     }

//     int NUM_PROCESSES = argc - 1;
//     int fd[2 * NUM_PROCESSES];

//     // Create pipes
//     for (int i = 0; i < NUM_PROCESSES; i++) {
//         if (pipe(fd + 2 * i) == -1) {
//             perror("error with pipe");
//             exit(EXIT_FAILURE);
//         }
//     }

//     pid_t p = 0;


//     while (argc > 1 && p == 0) {
//         p = fork();
//         if (p < 0) {
//             perror("error iwth fork");
//             exit(EXIT_FAILURE);
//         }
//         argc--;
//     }

//     if (argc == 1) {
//         dup2(fd[1], STDOUT_FILENO);
//     } else if (argc == NUM_PROCESSES) {
//         dup2(fd[2 * (argc - 2)], STDIN_FILENO);
//     } else {
//         dup2(fd[2 * (argc - 2)], STDIN_FILENO);
//         dup2(fd[2 * (argc - 1) + 1], STDOUT_FILENO);
//     }

//     char *prog_name = argv[argc];
//     printf("Here\n%s", prog_name);
//     execlp(prog_name, prog_name, NULL);
//     perror("execlp");
//     exit(EXIT_FAILURE);
// }

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
        exit(errno);
    } 
    else {
        close(fd[WRITE]);
        int status;
        waitpid(pid, &status, 0);
        if ( WIFEXITED(status) ) {
            errno = WEXITSTATUS(status);
            if (errno != 1) {
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
        exit(errno);    
        }
        else {
            close(fd[2*i + WRITE]);
            int status;
            waitpid(pid, &status, 0);
            if ( WIFEXITED(status) ) {
                errno = WEXITSTATUS(status);
                if (errno != 1) {
                    exit(errno);
                }
            }
        }
    }

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
        if (errno != 1) {
            exit(errno);
        }
    }
    exit(0);
}