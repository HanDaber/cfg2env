package utils

import (
	"reflect"
	"testing"
)

func TestFlatten(t *testing.T) {
	tests := []struct {
		name   string
		prefix string
		input  interface{}
		want   map[string]string
	}{
		{
			name:   "flat map",
			prefix: "",
			input: map[string]interface{}{
				"key": "value",
			},
			want: map[string]string{
				"KEY": "value",
			},
		},
		{
			name:   "nested map",
			prefix: "",
			input: map[string]interface{}{
				"database": map[string]interface{}{
					"host": "localhost",
					"port": 5432,
				},
			},
			want: map[string]string{
				"DATABASE_HOST": "localhost",
				"DATABASE_PORT": "5432",
			},
		},
		{
			name:   "array values",
			prefix: "API",
			input: map[string]interface{}{
				"features": []interface{}{
					"logging",
					"metrics",
				},
			},
			want: map[string]string{
				"API_FEATURES_0": "logging",
				"API_FEATURES_1": "metrics",
			},
		},
		{
			name:   "mixed types",
			prefix: "",
			input: map[string]interface{}{
				"string": "text",
				"int":    42,
				"float":  3.14,
				"bool":   true,
				"null":   nil,
				"array":  []interface{}{1, "two"},
				"nested": map[string]interface{}{"key": "value"},
				"mixed":  map[interface{}]interface{}{"key": "value"},
			},
			want: map[string]string{
				"STRING":     "text",
				"INT":        "42",
				"FLOAT":      "3.14",
				"BOOL":       "true",
				"NULL":       "",
				"ARRAY_0":    "1",
				"ARRAY_1":    "two",
				"NESTED_KEY": "value",
				"MIXED_KEY":  "value",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := make(map[string]string)
			Flatten(tt.prefix, tt.input, got)
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("Flatten() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestToString(t *testing.T) {
	tests := []struct {
		name  string
		input interface{}
		want  string
	}{
		{
			name:  "string",
			input: "text",
			want:  "text",
		},
		{
			name:  "integer",
			input: 42,
			want:  "42",
		},
		{
			name:  "float with no decimal",
			input: 42.0,
			want:  "42",
		},
		{
			name:  "float with decimal",
			input: 3.14,
			want:  "3.14",
		},
		{
			name:  "true boolean",
			input: true,
			want:  "true",
		},
		{
			name:  "false boolean",
			input: false,
			want:  "false",
		},
		{
			name:  "nil value",
			input: nil,
			want:  "",
		},
		{
			name:  "custom type",
			input: struct{ name string }{"test"},
			want:  "{test}",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := ToString(tt.input); got != tt.want {
				t.Errorf("ToString() = %v, want %v", got, tt.want)
			}
		})
	}
}
