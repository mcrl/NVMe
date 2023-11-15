CXX=g++

all: driver_test 

%:%.c
	$(CXX) -o $@ $^

clean:
	rm driver_test

run: driver_test
	sudo ./driver_test 
