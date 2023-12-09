CXX=g++

all: ethernet_test 

%:%.c
	$(CXX) -o $@ $^

clean:
	rm ethernet_test

run: ethernet_test
	sudo ./ethernet_test 
