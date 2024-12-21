package plugins

import (
	"fmt"

	"github.com/handaber/cfg2env/plugin"
	"github.com/handaber/cfg2env/plugins/json"
	"github.com/handaber/cfg2env/plugins/sqlite"
	"github.com/handaber/cfg2env/plugins/yaml"
)

var (
	// registry holds all registered plugins
	registry = make(map[string]plugin.Plugin)

	// defaultPlugin is the plugin to use when no format is specified
	defaultPlugin plugin.Plugin
)

// Register adds a plugin to the registry
func Register(p plugin.Plugin) {
	// Register by name
	registry[p.Name()] = p

	// Register by extensions
	for _, ext := range p.Extensions() {
		registry[ext] = p
	}

	// Set as default if it's the first YAML plugin
	if defaultPlugin == nil && p.CanHandle("yaml") {
		defaultPlugin = p
	}
}

// Get returns a plugin for the specified format
func Get(format string) (plugin.Plugin, error) {
	// If no format specified, use default
	if format == "" {
		if defaultPlugin == nil {
			return nil, fmt.Errorf("no default plugin available")
		}
		return defaultPlugin, nil
	}

	// Look up plugin by format
	if p, ok := registry[format]; ok {
		return p, nil
	}

	return nil, fmt.Errorf("unsupported format: %s", format)
}

// init registers all built-in plugins
func init() {
	Register(yaml.New())
	Register(json.New())
	Register(sqlite.New())
}
