all:
	gfortran -c SOFALIB.f -o SOFALIB.o
	gfortran -c selcon.f -o selcon.o
	gfortran -c MOON_ECLIPSE.f95 -o MOON_ECLIPSE.o
	gfortran -o MOON.exe SOFALIB.o selcon.o MOON_ECLIPSE.o
clean:
	rm *.o *.exe
