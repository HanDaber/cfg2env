package yaml

import (
	"io"

	"github.com/handaber/cfg2env/lib/utils"
	"github.com/handaber/cfg2env/plugin"
	"gopkg.in/yaml.v3"
)

// Plugin implements the plugin.Plugin interface for YAML format
type Plugin struct {
	plugin.BasePlugin
}

// New creates a new YAML plugin
func New() *Plugin {
	return &Plugin{
		BasePlugin: plugin.NewBasePlugin("yaml", "yml", "yaml"),
	}
}

// Parse implements plugin.Plugin
func (p *Plugin) Parse(r io.Reader) (map[string]string, error) {
	var data interface{}
	decoder := yaml.NewDecoder(r)
	if err := decoder.Decode(&data); err != nil {
		if err == io.EOF {
			return make(map[string]string), nil
		}
		return nil, err
	}

	env := make(map[string]string)
	if data != nil {
		utils.Flatten("", data, env)
	}
	return env, nil
}
