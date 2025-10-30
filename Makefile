all: src/wide.pdf src/thin.pdf dist/index.html

src/wide.pdf: src/main.typ src/wide.typ
	typst compile src/wide.typ src/wide.pdf

src/thin.pdf: src/main.typ src/thin.typ
	typst compile src/thin.typ src/thin.pdf

dist/index.html: src/*
	bun run build

clean:
	rm -f src/*.pdf
	rm -rf dist/

.PHONY: all clean