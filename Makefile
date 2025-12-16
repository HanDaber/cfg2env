.PHONY: all build test clean example example-yaml example-json example-sqlite

all: build test example

build:
	go build -o bin/cfg2env

test:
	go test -v -race -shuffle=on -count=5 ./...

install:
	./install.sh --local

test-cover:
	go test -v -cover ./...

test-race:
	go test -v -race ./...

clean:
	rm -f bin/cfg2env plugins/sqlite/testdata/config.db

example: example-yaml example-json example-sqlite

example-yaml:
	@echo "YAML Example:"
	@echo "Input (plugins/yaml/testdata/config.yaml):"
	@cat plugins/yaml/testdata/config.yaml
	@echo "\nOutput (.env):"
	@cat plugins/yaml/testdata/config.yaml | ./bin/cfg2env

example-json:
	@echo "\nJSON Example:"
	@echo "Input (plugins/json/testdata/config.json):"
	@cat plugins/json/testdata/config.json
	@echo "\nOutput (.env):"
	@cat plugins/json/testdata/config.json | ./bin/cfg2env --format json

example-sqlite:
	@echo "\nSQLite Example:"
	@echo "Input (plugins/sqlite/testdata/config.sql):"
	@cat plugins/sqlite/testdata/config.sql
	@echo "\nCreating temporary database..."
	@sqlite3 plugins/sqlite/testdata/config.db < plugins/sqlite/testdata/config.sql
	@echo "\nOutput (.env):"
	@cat plugins/sqlite/testdata/config.db | ./bin/cfg2env --format sqlite
	@rm -f plugins/sqlite/testdata/config.db