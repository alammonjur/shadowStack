#include "stdio.h"

#define RANGE 2000

int main (int argc, char* argv[])
{
	int i;
	int count = 0;
	int num = 1;

	while (num <= RANGE) {
		i = 2;

		while (i <= num) {
			if (num % i == 0)
				break;
			i++;
		}

		if (i == num) {
			printf("%d is a prime number\n", i);
			count++;
		}

		num++;
	}

	printf("Number of prime numbers between 1 and %d: %d\n", RANGE, count);
	return 0;
}
