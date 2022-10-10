#include <stdio.h>

extern char readChar__0 (){
	char tmp;
	scanf(" %c", &tmp); // The space before %c "eats"
	return tmp; 		// whitespaces and special characters
};
