VERS=1.4

all: clean
	mpicc -o mpiGraph mpiGraph.c

debug:
	mpicc -g -O0 -o mpiGraph mpiGraph.c

clean:
	rm -rf mpiGraph.o mpiGraph mpiGraph.out mpiGraph.tgz

tar: tgz
tarball: tgz
tgz:
	rm -rf temptgz mpiGraph.tgz; \
	mkdir -p temptgz/mpiGraph; \
	cp makefile README mpiGraph.c crunch_mpiGraph temptgz/mpiGraph/.; \
	cd temptgz; \
	tar -zcf ../mpiGraph-$(VERS).tgz mpiGraph; \
	cd ..; \
	rm -rf temptgz;
