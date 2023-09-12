CXX=g++

all: csr_test

%:%.c
	$(CXX) -o $@ $^

clean:
	rm csr_test

run: csr_test
	sudo ./csr_test 0x40 0x40 0x12341234
