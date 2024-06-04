## UID: 406034959

## Pipe Up

The pipe.c program facilitates the execution of a series of processes in a pipeline configuration, emulating the behavior commonly seen in Unix-like operating systems. Pipelining enables seamless data flow between processes, where the output of one process serves as the input to the next, fostering modular and efficient data processing.

Pipe.c ensures robust input and error handling to maintain the integrity and reliability of data processing pipelines. Prior to execution, the program validates the availability of specified processes and verifies the correctness of command-line arguments, preemptively detecting potential issues to prevent runtime errors. In the event of an error, informative error messages are emitted to the standard error stream (stderr).

## Building

Building is simple: run 'make' in the terminal.

## Running

Using pipe.c entails invoking the compiled executable with a list of desired processes as command-line arguments. Each process in the pipeline is separated by spaces, delineating the order of execution. Users can specify any executable accessible via the system's PATH environment variable, enabling seamless integration of custom scripts, system utilities, and third-party applications into the pipeline. 

Example usage:
./pipe PROCESS_A PROCESS_B PROCESS_C

## Cleaning up

Cleaning is simple: run 'make clean' in the terminal.


