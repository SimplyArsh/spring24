#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void func (int* process) {
    printf("This should only be run once?\n");
    *process = 2;
}

int main (int argc, char *argv[]) {
    printf("hello (pid:%d)\n", (int) getpid());
    int parent_number;
    func(&parent_number);
    int rc = fork();
    printf("parent_number (should not be known by child process?):%d \n", parent_number);
    if (rc < 0) {
        fprintf(stderr, "fork failed\n");
        exit(1);
    } else if (rc == 0) {
        // child (new process)
        printf("child!! (pid:%d)\n", (int) getpid());
    } else {
        // parent goes down this path (main)
        printf("parent of %d (pid:%d)\n",
            rc, (int) getpid());
    }
return 0;
}