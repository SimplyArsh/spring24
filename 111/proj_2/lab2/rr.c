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
  u32 time_left;
  u32 untouched;
  /* End of "Additional fields here" */
};

TAILQ_HEAD(process_list, process);
TAILQ_HEAD(q_list, process);

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

void round_robin (
  struct process *data,
  struct process_list* q_head,
  u32 quantum_length,
  u32 size,
  u32* total_waiting_time,
  u32* total_response_time
) {

  // book-keeping variables
  struct process *curr, *temp;
  u32 curr_time, ps_done = 0;
  u32 p_idx = 0, p_fin = 0; 

  while (ps_done < size) {

    // forward time if Q is empty
    if (TAILQ_EMPTY(q_head)) {
        if (p_idx < size) {
          curr_time = data[p_idx].arrival_time;
        }
    }

    // get a process? from Q
    curr = TAILQ_FIRST(q_head);

    // if there is process and its not been executed yet, calculate response time
    if (curr != NULL && curr->untouched) {
      curr->untouched = 0;
      *total_response_time += curr_time - curr->arrival_time;
    }

    // if there is a process, execute it. If it finihes, calculate waiting time.
    if (curr != NULL && curr->time_left <= quantum_length) {
      ps_done++; p_fin = 1;
      curr_time += curr->time_left;
      *total_waiting_time += curr_time - curr->arrival_time - curr->burst_time;
      TAILQ_REMOVE(q_head, curr, pointers);
    } else if (curr != NULL) {
      p_fin = 0;
      curr_time += quantum_length;
      curr->time_left -= quantum_length;
      TAILQ_REMOVE(q_head, curr, pointers);
    }

    // if new processes come in during this time, add them to EOQ
    while (p_idx < size && data[p_idx].arrival_time <= curr_time) {
      data[p_idx].untouched = 1;
      data[p_idx].time_left = data[p_idx].burst_time;
      TAILQ_INSERT_TAIL(q_head, &data[p_idx], pointers);
      p_idx++;
    }

    // if we executed a process and it didn't finish, add it back to the EOQ
    if (curr != NULL && !p_fin) TAILQ_INSERT_TAIL(q_head, curr, pointers);

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

  if (quantum_length != 0) {
      round_robin(data, &list, quantum_length, size, 
    &total_waiting_time, &total_response_time);
  }

  /* End of "Your code here" */

  printf("Average waiting time: %.2f\n", (float)total_waiting_time / (float)size);
  printf("Average response time: %.2f\n", (float)total_response_time / (float)size);

  free(data);
  return 0;
}

