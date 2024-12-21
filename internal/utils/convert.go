package utils

import (
	"fmt"
	"strings"
)

// Flatten recursively flattens nested maps into dot-separated keys
func Flatten(prefix string, v interface{}, env map[string]string) {
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
			Flatten(newKey, v, env)
		}
	case map[interface{}]interface{}:
		if len(val) == 0 {
			env[strings.ToUpper(prefix)] = ""
			return
		}
		for k, v := range val {
			strKey := k.(string)
			newKey := strKey
			if prefix != "" {
				newKey = prefix + "_" + strKey
			}
			Flatten(newKey, v, env)
		}
	case []interface{}:
		for i, v := range val {
			newKey := prefix + "_" + fmt.Sprintf("%d", i)
			Flatten(newKey, v, env)
		}
	case string, int, float64, bool, nil:
		env[strings.ToUpper(prefix)] = ToString(val)
	}
}

// ToString converts various types to their string representation
func ToString(v interface{}) string {
	if v == nil {
		return ""
	}
	switch val := v.(type) {
	case string:
		return val
	case int:
		return fmt.Sprintf("%d", val)
	case float64:
		if float64(int(val)) == val {
			return fmt.Sprintf("%d", int(val))
		}
		return fmt.Sprintf("%g", val)
	case bool:
		if val {
			return "true"
		}
		return "false"
	default:
		return fmt.Sprintf("%v", val)
	}
}
