#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <errno.h>
#include <string.h>

int main(int argc, char *argv[])
{
	errno = 0;
	if (argc == 1) {
		errno = EINVAL;
		fprintf(stderr, "%s\n", strerror(errno));
	}
	return 0;
}
