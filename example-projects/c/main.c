#include <stdio.h>
#include <stdlib.h>

// Simple method to greet someone with a name
static void greet(const char* const name) {
    printf("Hello %s\n", name);
}

int main(int ac, char **av) {
  if (ac > 2) {
      greet(av[1]);
  } else {
      greet("World");
  }

  return EXIT_SUCCESS;
}
