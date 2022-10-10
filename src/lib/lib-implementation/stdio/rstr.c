#include <stdio.h>
#include <string.h> 
#include <stdint.h>

extern void readString_ic1_0 (int16_t size, char * s){
	fgets(s, size, stdin);
	s[strcspn(s, "\n")] = 0;
}