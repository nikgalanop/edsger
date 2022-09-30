#include <stdio.h>
#include <string.h> 
#include <stdint.h>
#include <inttypes.h>

extern void writeInteger_i_0 (int n){
	printf("%hd", n);
}

extern void writeBoolean_b_0 (char b){
	printf((b==0)?"false":"true");
}

extern void writeChar_c_0 (char c){
	printf("%c", c);
}

extern void writeReal_d_0 (double d){
	printf("%lf", d);
}

extern void writeString_c1_0 (char * s){
	printf("%s",s);	
}

extern int16_t readInteger__0 (){
	int16_t tmp;
	scanf("%hd", &tmp);
	return tmp;
}

extern char readChar__0 (){
	char tmp;
	scanf(" %c", &tmp); // The space before %c "eats"
	return tmp; 		// whitespaces and special characters
};

extern char readBoolean__0 (){
	return readChar__0();
}

extern double readReal__0 (){
	double tmp;
	scanf ("%lf", &tmp);
	return (double) tmp;
}

extern void readString_ic1_0 (int16_t size, char * s){
	fgets(s, size, stdin);
	s[strcspn(s, "\n")] = 0;
}
