package converter

import (
	"fmt"
	"io"
	"sort"
	"strings"

	"github.com/handaber/cfg2env/plugin"
)

// Converter handles the conversion of configuration files to .env format
type Converter struct {
	plugin plugin.Plugin
}

// New creates a new Converter with the given plugin
func New(p plugin.Plugin) *Converter {
	return &Converter{
		plugin: p,
	}
}

// Convert reads from r and writes the converted output to w
func (c *Converter) Convert(r io.Reader, w io.Writer) error {
	// Handle nil input/output
	if r == nil {
		return fmt.Errorf("input reader is nil")
	}
	if w == nil {
		return fmt.Errorf("output writer is nil")
	}

	// Parse input using plugin
	env, err := c.plugin.Parse(r)
	if err != nil {
		return fmt.Errorf("parsing error: %w", err)
	}

	// Convert all keys to uppercase and merge duplicate keys
	normalized := make(map[string]string)
	for k, v := range env {
		upperKey := strings.ToUpper(k)
		normalized[upperKey] = v
	}

	// Get sorted keys for consistent output
	var keys []string
	for k := range normalized {
		keys = append(keys, k)
	}
	sort.Strings(keys)

	// Write output in .env format
	for _, k := range keys {
		if _, err := io.WriteString(w, k+"="+normalized[k]+"\n"); err != nil {
			return fmt.Errorf("writing error: %w", err)
		}
	}

	return nil
}
