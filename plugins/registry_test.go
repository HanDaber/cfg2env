package plugins

import (
	"io"
	"testing"

	"github.com/handaber/cfg2env/plugin"
	"github.com/handaber/cfg2env/plugins/json"
	"github.com/handaber/cfg2env/plugins/sqlite"
	"github.com/handaber/cfg2env/plugins/yaml"
)

// mockPlugin implements plugin.Plugin for testing
type mockPlugin struct {
	plugin.BasePlugin
}

func (p mockPlugin) Parse(r io.Reader) (map[string]string, error) {
	return make(map[string]string), nil
}

func TestRegistry(t *testing.T) {
	// Clear registry for testing
	registry = make(map[string]plugin.Plugin)
	defaultPlugin = nil

	// Create test plugins
	yamlPlugin := mockPlugin{plugin.NewBasePlugin("yaml", "yml", "yaml")}
	jsonPlugin := mockPlugin{plugin.NewBasePlugin("json", "json")}

	tests := []struct {
		name      string
		register  []plugin.Plugin
		format    string
		wantName  string
		wantError bool
	}{
		{
			name:      "empty registry",
			register:  nil,
			format:    "yaml",
			wantError: true,
		},
		{
			name:     "register yaml plugin",
			register: []plugin.Plugin{yamlPlugin},
			format:   "yaml",
			wantName: "yaml",
		},
		{
			name:     "register multiple plugins",
			register: []plugin.Plugin{yamlPlugin, jsonPlugin},
			format:   "json",
			wantName: "json",
		},
		{
			name:     "get by extension",
			register: []plugin.Plugin{yamlPlugin},
			format:   "yml",
			wantName: "yaml",
		},
		{
			name:     "default plugin",
			register: []plugin.Plugin{yamlPlugin, jsonPlugin},
			format:   "",
			wantName: "yaml",
		},
		{
			name:      "unsupported format",
			register:  []plugin.Plugin{yamlPlugin, jsonPlugin},
			format:    "unsupported",
			wantError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Reset registry
			registry = make(map[string]plugin.Plugin)
			defaultPlugin = nil

			// Register plugins
			for _, p := range tt.register {
				Register(p)
			}

			// Get plugin
			got, err := Get(tt.format)
			if (err != nil) != tt.wantError {
				t.Errorf("Get() error = %v, wantError %v", err, tt.wantError)
				return
			}

			if !tt.wantError {
				if got.Name() != tt.wantName {
					t.Errorf("Get() = %v, want %v", got.Name(), tt.wantName)
				}
			}
		})
	}
}

func TestBuiltinPlugins(t *testing.T) {
	// Reset registry to ensure clean state
	registry = make(map[string]plugin.Plugin)
	defaultPlugin = nil

	// Register built-in plugins
	Register(yaml.New())
	Register(json.New())
	Register(sqlite.New())

	// Test that all built-in plugins are registered
	tests := []struct {
		format string
		want   string
	}{
		{"yaml", "yaml"},
		{"yml", "yaml"},
		{"json", "json"},
		{"sqlite", "sqlite"},
		{"db", "sqlite"},
		{"sqlite3", "sqlite"},
		{"", "yaml"}, // default plugin
	}

	for _, tt := range tests {
		t.Run(tt.format, func(t *testing.T) {
			got, err := Get(tt.format)
			if err != nil {
				t.Errorf("Get(%q) error = %v", tt.format, err)
				return
			}
			if got.Name() != tt.want {
				t.Errorf("Get(%q) = %v, want %v", tt.format, got.Name(), tt.want)
			}
		})
	}
}
