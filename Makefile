TARGET=gds

CPPFLAGS=-I/usr/local/cuda/include 
CXXFLAGS=-pthread

LDFLAGS=-L/usr/local/cuda/lib64
LDLIBS=-lcufile -lpthread -ldl -lcudart

all: $(TARGET)

clean:
	rm -f $(TARGET)	

run: $(TARGET)
	./gds
