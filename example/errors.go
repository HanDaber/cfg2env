package main

import (
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/handaber/cfg2env/lib/converter"
	"github.com/handaber/cfg2env/plugin"
)

// demoPlugin returns a map with case-variant duplicate keys
type demoPlugin struct {
	plugin.BasePlugin
}

func (p *demoPlugin) Parse(r io.Reader) (map[string]string, error) {
	return map[string]string{
		"API_KEY":      "secret-from-uppercase",
		"api_key":      "secret-from-lowercase",
		"DATABASE_URL": "postgres://localhost/db",
		"Server_Port":  "8080",
	}, nil
}

func main() {
	fmt.Println("=== Demonstrating Duplicate Key Error Detection ===")
	fmt.Println()
	fmt.Println("Plugin returns map with case-variant keys:")
	fmt.Println("  API_KEY: secret-from-uppercase")
	fmt.Println("  api_key: secret-from-lowercase")
	fmt.Println("  DATABASE_URL: postgres://localhost/db")
	fmt.Println("  Server_Port: 8080")
	fmt.Println()
	fmt.Println("Attempting conversion...")
	fmt.Println()

	p := &demoPlugin{BasePlugin: plugin.NewBasePlugin("demo")}
	c := converter.New(p)

	err := c.Convert(strings.NewReader(""), os.Stdout)
	if err != nil {
		fmt.Fprintln(os.Stderr)
		fmt.Fprintf(os.Stderr, "❌ Error: %v\n", err)
		os.Exit(1)
	}

	fmt.Println()
	fmt.Println("✅ Conversion successful!")
}
