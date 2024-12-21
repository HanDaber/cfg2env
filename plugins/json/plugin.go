package json

import (
	"encoding/json"
	"fmt"
	"io"
	"strconv"
	"strings"

	"github.com/handaber/cfg2env/plugin"
)

// Plugin implements the plugin.Plugin interface for JSON format
type Plugin struct {
	plugin.BasePlugin
}

// New creates a new JSON plugin
func New() *Plugin {
	return &Plugin{
		BasePlugin: plugin.NewBasePlugin("json", "json"),
	}
}

// Parse implements plugin.Plugin
func (p *Plugin) Parse(r io.Reader) (map[string]string, error) {
	// Handle empty input
	if r == nil {
		return make(map[string]string), nil
	}

	var data interface{}
	decoder := json.NewDecoder(r)
	if err := decoder.Decode(&data); err != nil {
		if err == io.EOF {
			return make(map[string]string), nil
		}
		return nil, err
	}

	env := make(map[string]string)
	if data != nil {
		flatten("", data, env)
	}
	return env, nil
}

// flatten recursively flattens nested maps into underscore-separated keys
func flatten(prefix string, v interface{}, env map[string]string) {
	switch val := v.(type) {
	case map[string]interface{}:
		if len(val) == 0 {
			env[strings.ToUpper(prefix)] = ""
			return
		}
		for k, v := range val {
			newKey := k
			if prefix != "" {
				newKey = prefix + "_" + k
			}
			flatten(strings.ToUpper(newKey), v, env)
		}
	case []interface{}:
		for i, v := range val {
			newKey := fmt.Sprintf("%s_%d", prefix, i)
			flatten(strings.ToUpper(newKey), v, env)
		}
	case string:
		env[strings.ToUpper(prefix)] = val
	case float64:
		if float64(int64(val)) == val {
			env[strings.ToUpper(prefix)] = strconv.FormatInt(int64(val), 10)
		} else {
			env[strings.ToUpper(prefix)] = strconv.FormatFloat(val, 'f', -1, 64)
		}
	case bool:
		env[strings.ToUpper(prefix)] = strconv.FormatBool(val)
	case nil:
		env[strings.ToUpper(prefix)] = ""
	default:
		env[strings.ToUpper(prefix)] = fmt.Sprintf("%v", val)
	}
}
