.PHONY: test

CAT := bat --paging=never

main:
	bake source/main.cpp

html:
	flex -o cdd_html.yy.cpp --prefix=cdd_html_ --debug source/cdd_html.l
	g++ -o cdd-html -DCDD_HTML_MAIN cdd_html.yy.cpp -ldictate

test:
	#./source/cddpp -r html -o out -O overview.txt -T table_of_contents.txt -i test/cdd.cdd
	./source/cddpp -r html -o out -O overview.txt -T table_of_contents.txt -i ../../pufka.cdd
	${CAT} overview.txt
	${CAT} table_of_contents.txt
	mv overview.txt table_of_contents.txt www/
