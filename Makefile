.PHONY: test

main:
	bake source/main.cpp

test:
	./source/cddpp -O overview.txt -T table_of_contents.txt -i test/cdd.cdd
	bat overview.txt
	bat table_of_contents.txt
	mv overview.txt table_of_contents.txt www/
