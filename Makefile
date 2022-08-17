all:
	gfortran -ffree-form -ffixed-line-length-none -c plot.f test.f
	gfortran plot.o test.o

fan:
	gfortran -ffree-form -c plot.f examples/fan.f
	gfortran plot.o fan.o

grav:
	gfortran -ffree-form -c plot.f examples/grav.f
	gfortran plot.o grav.o

test:
	./a.out > code/f_test.sc
	rm -f frames/*png
	python sc4020.py code/f_test.sc
	convert -delay 1 -loop 0 frames/*png frames/out.gif