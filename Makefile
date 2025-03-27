.PHONY: test

CAT := bat --paging=never

ifeq (${DEBUG}, 1)
  #LFLAGS   += --debug --trace
  #CFLAGS   += -O0 -ggdb -fno-inline
  #CPPFLAGS += -DDEBUG
endif

SOURCE.d := source/
OBJECT.d := object/
CXXFLAGS := -I${SOURCE.d} -I${OBJECT.d}

#INPUT.cdd := test/cdd.cdd
INPUT.cdd := ../../pufka.cdd

main: html compile test
	for i in out/*.inc; do cdd-stripper "$$i" > "$$i.swp"; mv "$$i.swp" "$$i"; done
	for i in out/*.inc; do trail-fixer.pl "$$i" > "$$i.swp"; mv "$$i.swp" "$$i"; done
	for i in out/*.inc; do cp "$$i" "$$i.copy"; cdd-html "$$i.copy" > "$$i.swp"; mv "$$i.swp" "$$i"; done
	mv overview.txt table_of_contents.txt www/

html:
	flex ${LFLAGS} -o ${OBJECT.d}/cdd_html.yy.cpp ${SOURCE.d}/cdd_html.l
	g++ -o cdd-html -DCDD_HTML_MAIN ${OBJECT.d}/cdd_html.yy.cpp -ldictate -ldedent -ggdb

compile:
	flex ${LFLAGS} -o ${OBJECT.d}/cdd_stripper.yy.cpp ${SOURCE.d}/cdd_stripper.l
	g++ -o cdd-stripper ${OBJECT.d}/cdd_stripper.yy.cpp -ldictate
	flex ${LFLAGS} -o ${OBJECT.d}/cddpp.yy.cpp --header=${SOURCE.d}/cddpp.yy.hpp ${SOURCE.d}/cddpp.l
	g++ ${CXXFLAGS} -o cddpp ${SOURCE.d}/main.cpp ${SOURCE.d}/cli.cpp ${OBJECT.d}/cddpp.yy.cpp -ldictate -lqx -Wall -ggdb -fsanitize=address

test:
	cddpp -r html -o out -O overview.txt -T table_of_contents.txt -i ${INPUT.cdd}
	#${CAT} overview.txt
	#${CAT} table_of_contents.txt
