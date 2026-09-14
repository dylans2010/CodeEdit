CC = clang
CFLAGS = -Wall -O2 -lsqlite3
TARGET = {{PROJECT_NAME}}

all: $(TARGET)
$(TARGET): main.c
	$(CC) $(CFLAGS) -o $@ $^
