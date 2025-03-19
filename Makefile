.PHONY: test

main:
	bake source/main.cpp

test:
	./source/cddpp test/cdd.cdd
	bat overview.txt
	bat table_of_contents.txt
