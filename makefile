all: clean
	mpicc -o mpiGraph mpiGraph.c

debug:
	mpicc -g -O0 -o mpiGraph mpiGraph.c

clean:
	rm -rf mpiGraph.o mpiGraph
