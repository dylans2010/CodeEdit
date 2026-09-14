CC = clang
CFLAGS = -Wall -Wextra -std=c17 -O2
TARGET = {{PROJECT_NAME}}

all: $(TARGET)

$(TARGET): src/main.c
	$(CC) $(CFLAGS) -o $(TARGET) src/main.c

clean:
	rm -f $(TARGET)
