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

int main(int argc, char *argv[]) {

    if (argc < 2) {
        fprintf(stderr, "No pipe functions passed\n");
        return EXIT_FAILURE;
    }

    int NUM_PROCESSES = argc - 1;
    int fd[2 * NUM_PROCESSES];

    // Create pipes
    for (int i = 0; i < NUM_PROCESSES; i++) {
        if (pipe(fd + 2 * i) == -1) {
            perror("error with pipe");
            exit(EXIT_FAILURE);
        }
    }

    pid_t p = 0;

    while (argc > 1 && p == 0) {
        p = fork();
        if (p < 0) {
            perror("error iwth fork");
            exit(EXIT_FAILURE);
        }
        argc--;
    }

    if (argc == 1) {
        dup2(fd[1], STDOUT_FILENO);
    } else if (argc == NUM_PROCESSES) {
        dup2(fd[2 * (argc - 2)], STDIN_FILENO);
    } else {
        dup2(fd[2 * (argc - 2)], STDIN_FILENO);
        dup2(fd[2 * (argc - 1) + 1], STDOUT_FILENO);
    }

    char *prog_name = argv[argc];
    execlp(prog_name, prog_name, NULL);
    perror("execlp");
    exit(EXIT_FAILURE);
}