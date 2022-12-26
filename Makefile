# @author      : HackOlympus (zeus@hackolympus)
######################################################################
# @file        : Makefile
# @created     : Monday Dec 26, 2022 03:50:45 MST
######################################################################

CC=gcc
CFLAGS=-nostdlib -static 

TARGET=$(wildcard *.s)

main: $(TARGET) 
	$(CC) -o $@ $^ $(CFLAGS) 

clean:
	rm ./main
