package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/handaber/cfg2env/internal/converter"
	"github.com/handaber/cfg2env/plugins"
)

var (
	version = "dev"
	format  = flag.String("format", "", "Input format (yaml, json, sqlite)")
	query   = flag.String("query", "", "Custom query for SQLite format")
	showVer = flag.Bool("version", false, "Show version information")
	help    = flag.Bool("help", false, "Show help information")
	dunder  = flag.Int("dunder", 0, "Number of underscores to remove from consecutive sequences (default: 0, negative values treated as 0)")
)

func printHelp() {
	fmt.Printf(`cfg2env - Convert config files to .env format

USAGE:
  cfg2env [OPTIONS] < input > output.env
  cat config.yaml | cfg2env > .env

OPTIONS:
  -format string
        Input format: yaml (default), json, sqlite
  -query string
        Custom SQL query for SQLite (default: "SELECT key, value FROM config")
  -dunder int
        Remove N underscores from consecutive sequences (default: 0)
  -version
        Show version information
  -help
        Show this help message

FORMATS:
  yaml     YAML configuration files (default if no format specified)
  json     JSON configuration files
  sqlite   SQLite database files

EXAMPLES:
  # Convert YAML to .env (default format)
  cat config.yaml | cfg2env > .env

  # Convert JSON to .env
  cat config.json | cfg2env --format json > .env

  # Convert SQLite database
  cat config.db | cfg2env --format sqlite > .env

  # Use custom SQLite query
  cat settings.db | cfg2env --format sqlite --query "SELECT name, val FROM settings" > .env

  # Remove single underscores from consecutive sequences
  cat config.yaml | cfg2env --dunder 1 > .env

OUTPUT:
  Nested keys are flattened with underscores and converted to uppercase:
    database.host       -> DATABASE_HOST
    api.features[0]     -> API_FEATURES_0
    nested.deep.value   -> NESTED_DEEP_VALUE

`)
}

func main() {
	flag.Usage = printHelp
	flag.Parse()

	if *help {
		printHelp()
		os.Exit(0)
	}

	if *showVer {
		fmt.Printf("cfg2env version %s\n", version)
		os.Exit(0)
	}

	// Get plugin for format
	p, err := plugins.Get(*format)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	// Set custom query if provided
	if *query != "" {
		if q, ok := p.(interface{ SetQuery(string) }); ok {
			q.SetQuery(*query)
		}
	}

	// Create converter with plugin
	c := converter.New(p)
	c.SetVersion(version)
	if *dunder > 0 {
		c.SetDunder(*dunder)
	}

	// Convert stdin to stdout
	if err := c.Convert(os.Stdin, os.Stdout); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
