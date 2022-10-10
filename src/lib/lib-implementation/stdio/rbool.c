#include <stdio.h>

extern char readBoolean__0 (){
	char tmp;
	scanf(" %c", &tmp); // The space before %c "eats"
	return tmp; 		// whitespaces and special characters
}