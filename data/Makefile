all: generate
generate: generate.cpp
	g++ generate.cpp -g -Wall -I./bvh/include -I./happly -I. -fopenmp -o generate
clean:
	rm generate nbp.bin trig.bin ray.bin result.bin