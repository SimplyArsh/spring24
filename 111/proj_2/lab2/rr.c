#include <errno.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/queue.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

typedef uint32_t u32;
typedef int32_t i32;

struct process
{
  u32 pid;
  u32 arrival_time;
  u32 burst_time;

  TAILQ_ENTRY(process) pointers;

  /* Additional fields here */
  u32 started;
  u32 time_passed;
  /* End of "Additional fields here" */
};

TAILQ_HEAD(process_list, process);

u32 next_int(const char **data, const char *data_end)
{
  u32 current = 0;
  bool started = false;
  while (*data != data_end)
  {
    char c = **data;

    if (c < 0x30 || c > 0x39)
    {
      if (started)
      {
        return current;
      }
    }
    else
    {
      if (!started)
      {
        current = (c - 0x30);
        started = true;
      }
      else
      {
        current *= 10;
        current += (c - 0x30);
      }
    }

    ++(*data);
  }

  printf("Reached end of file while looking for another integer\n");
  exit(EINVAL);
}

u32 next_int_from_c_str(const char *data)
{
  char c;
  u32 i = 0;
  u32 current = 0;
  bool started = false;

  while ((c = data[i++]))
  {
    if (c < 0x30 || c > 0x39)
    {
      exit(EINVAL);
    }
    if (!started)
    {
      current = (c - 0x30);
      started = true;
    }
    else
    {
      current *= 10;
      current += (c - 0x30);
    }
  }
  return current;
}

void init_processes(const char *path,
                    struct process **process_data,
                    u32 *process_size)
{
  int fd = open(path, O_RDONLY);
  if (fd == -1)
  {
    int err = errno;
    perror("open");
    exit(err);
  }

  struct stat st;
  if (fstat(fd, &st) == -1)
  {
    int err = errno;
    perror("stat");
    exit(err);
  }

  u32 size = st.st_size;
  const char *data_start = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
  if (data_start == MAP_FAILED)
  {
    int err = errno;
    perror("mmap");
    exit(err);
  }

  const char *data_end = data_start + size;
  const char *data = data_start;

  *process_size = next_int(&data, data_end);

  *process_data = calloc(sizeof(struct process), *process_size);
  if (*process_data == NULL)
  {
    int err = errno;
    perror("calloc");
    exit(err);
  }

  for (u32 i = 0; i < *process_size; ++i)
  {
    (*process_data)[i].pid = next_int(&data, data_end);
    (*process_data)[i].arrival_time = next_int(&data, data_end);
    (*process_data)[i].burst_time = next_int(&data, data_end);
  }

  munmap((void *)data, size);
  close(fd);
}

void round_robin (struct process_list* head,
                  u32 quantum_length,
                  u32 size,
                  u32* total_waiting_time,
                  u32* total_response_time)
{
  struct process *temp, *head_ptr;
  head_ptr = TAILQ_FIRST(head);
  u32 current_time, prev_time;
  u32 time_forward_flag = 0;
  u32 finished_count = 0;
  u32 executed_count = 0;

  if (head_ptr != NULL) {
    current_time = head_ptr->arrival_time;
    prev_time = current_time;
  }
  
  printf("T  B  S?  R  W\n");
  while (finished_count != size) {

    printf("CYCLE\n");
    finished_count = 0;
    executed_count = 0;
    if (current_time == prev_time) {
      time_forward_flag = 1;
    }
    prev_time = current_time;
    
    // iterate through all the processes
    TAILQ_FOREACH(temp, head, pointers) {

      printf("%d, %d, %d, %d, %d.\n", current_time, 
        temp->burst_time, temp->started, *total_response_time, *total_waiting_time);
      // check if the process is already finished
      if (temp->burst_time == 0) {
        // printf("Process %d has finished.\n", temp->pid);
        finished_count++;
        continue;
      }

      // process hasn't started
      if (temp->started == 0) {

        // forward time if stuck
        if (time_forward_flag) {
          current_time = temp->arrival_time;
          time_forward_flag = 0;
        }

        if (executed_count != 0 && temp->arrival_time >= current_time) {
          break;
        }

        // the process has arrived
        if (temp->arrival_time <= current_time) {
          *total_response_time += current_time - temp->arrival_time;
          printf("Response_time_added %d.\n", current_time - temp->arrival_time);
          temp->started = 1;
        }

      } else {
        executed_count += 1;
        // waiting time
        if (temp->burst_time <= quantum_length) {
          *total_waiting_time = current_time + temp->burst_time - temp->arrival_time;
          current_time += temp->burst_time;
          temp->burst_time = 0;
        } else {
          temp->burst_time -= quantum_length;
          current_time += quantum_length;
        }
        
      }

    }

  }


}

int main(int argc, char *argv[])
{
  if (argc != 3)
  {
    return EINVAL;
  }
  struct process *data;
  u32 size;
  init_processes(argv[1], &data, &size);

  u32 quantum_length = next_int_from_c_str(argv[2]);

  struct process_list list;
  TAILQ_INIT(&list);

  u32 total_waiting_time = 0;
  u32 total_response_time = 0;

  /* Your code here */
  for (u32 i = 0; i < size; i++) {
    TAILQ_INSERT_TAIL(&list, &data[i], pointers);
    data[i].started = 0;
  }

  round_robin(&list, quantum_length, size, &total_waiting_time, &total_response_time);

  /* End of "Your code here" */

  printf("Average waiting time: %.2f\n", (float)total_waiting_time / (float)size);
  printf("Average response time: %.2f\n", (float)total_response_time / (float)size);

  free(data);
  return 0;
}
