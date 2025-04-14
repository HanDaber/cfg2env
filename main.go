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
	dunder  = flag.Int("dunder", 0, "Number of underscores to remove from consecutive sequences (default: 0, negative values treated as 0)")
)

func main() {
	flag.Parse()

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
