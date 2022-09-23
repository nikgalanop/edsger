#include <stdio.h>
#include <string.h> 

extern void writeInteger (int n){
	printf("%d", n);
}

extern void writeBoolean (char b){
	printf((b==0)?"false":"true");
}

extern void writeChar (char c){
	printf("%c", c);
}

extern void writeReal (double d){
	printf("%lf", d);
}

extern void writeString (char * s){
	printf("%s",s);	
}

extern int readInteger (){
	int tmp;
	scanf("%d", &tmp);
	return tmp;
}

extern char readChar (){
	char tmp;
	scanf("%c", &tmp);
	return tmp;
};

extern char readBoolean (){
	return readChar();
}

extern double readReal (){
	double tmp;
	scanf ("%lf", &tmp);
	return (double) tmp;
}

extern void readString (int size, char * s){
	fgets(s, size, stdin);
	s[strcspn(s, "\n")] = 0;
}
