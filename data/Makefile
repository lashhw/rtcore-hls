all: generate
generate: generate.cpp
	g++ generate.cpp -g -Wall -I./bvh/include -I./happly -I. -fopenmp -o generate
clean:
	rm -f generate generate_nbp.bin trig.bin ray.bin generate_result.bin