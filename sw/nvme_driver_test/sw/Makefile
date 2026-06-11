CXX=g++
CXXFLAGS=-std=c++17 -O2 -Wall $(shell pkg-config --cflags spdlog 2>/dev/null)
LDLIBS=$(shell pkg-config --libs spdlog 2>/dev/null || echo -lspdlog -pthread)

all: driver_test

driver_test: driver_test.c
	$(CXX) $(CXXFLAGS) -o $@ $< $(LDLIBS)

clean:
	rm -f driver_test

run: driver_test
	sudo ./driver_test
