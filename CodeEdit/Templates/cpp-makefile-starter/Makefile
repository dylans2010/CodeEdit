CXX = clang++
CXXFLAGS = -std=c++20 -Wall -Wextra -Iinclude -O2
TARGET = {{PROJECT_NAME}}

SRCS = $(wildcard src/*.cpp)
OBJS = $(SRCS:.cpp=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^

clean:
	rm -f $(OBJS) $(TARGET)
