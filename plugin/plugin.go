package plugin

import "io"

// Plugin defines the interface for configuration format plugins
type Plugin interface {
	// Name returns the name of the plugin
	Name() string

	// Extensions returns the file extensions this plugin can handle
	Extensions() []string

	// CanHandle checks if this plugin can handle the given format
	CanHandle(format string) bool

	// Parse reads configuration data and returns a map of flattened key-value pairs
	Parse(r io.Reader) (map[string]string, error)
}

// BasePlugin provides common functionality for plugins
type BasePlugin struct {
	name       string
	extensions []string
}

// NewBasePlugin creates a new BasePlugin with the given name and extensions
func NewBasePlugin(name string, extensions ...string) BasePlugin {
	return BasePlugin{
		name:       name,
		extensions: extensions,
	}
}

// Name returns the name of the plugin
func (p BasePlugin) Name() string {
	return p.name
}

// Extensions returns the file extensions this plugin can handle
func (p BasePlugin) Extensions() []string {
	return p.extensions
}

// CanHandle checks if this plugin can handle the given format
func (p BasePlugin) CanHandle(format string) bool {
	if format == p.name {
		return true
	}
	for _, ext := range p.extensions {
		if format == ext {
			return true
		}
	}
	return false
}
