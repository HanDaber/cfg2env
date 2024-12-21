package json

import (
	"strings"
	"testing"
)

func TestPlugin_Parse(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		want    map[string]string
		wantErr bool
	}{
		{
			name: "valid json",
			input: `{
				"database": {
					"host": "localhost",
					"port": 5432,
					"credentials": {
						"username": "admin",
						"password": "secret with spaces"
					}
				},
				"api": {
					"url": "https://api.example.com",
					"timeout": 30,
					"features": ["logging", "metrics", "tracing"]
				}
			}`,
			want: map[string]string{
				"DATABASE_HOST":                 "localhost",
				"DATABASE_PORT":                 "5432",
				"DATABASE_CREDENTIALS_USERNAME": "admin",
				"DATABASE_CREDENTIALS_PASSWORD": "secret with spaces",
				"API_URL":                       "https://api.example.com",
				"API_TIMEOUT":                   "30",
				"API_FEATURES_0":                "logging",
				"API_FEATURES_1":                "metrics",
				"API_FEATURES_2":                "tracing",
			},
		},
		{
			name:    "invalid json",
			input:   "{invalid}",
			wantErr: true,
		},
		{
			name:  "non-existent file",
			input: "",
			want:  map[string]string{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			p := New()
			got, err := p.Parse(strings.NewReader(tt.input))
			if (err != nil) != tt.wantErr {
				t.Errorf("Parse() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr {
				for k, v := range tt.want {
					if got[k] != v {
						t.Errorf("Parse() got[%s] = %v, want %v", k, got[k], v)
					}
				}
			}
		})
	}
}

func TestPlugin_Parse_EdgeCases(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		want    map[string]string
		wantErr bool
	}{
		{
			name: "edge cases",
			input: `{
				"boolean_values": {
					"true_val": true,
					"false_val": false
				},
				"numeric_values": {
					"integer": 42,
					"float": 3.14
				}
			}`,
			want: map[string]string{
				"BOOLEAN_VALUES_TRUE_VAL":  "true",
				"BOOLEAN_VALUES_FALSE_VAL": "false",
				"NUMERIC_VALUES_INTEGER":   "42",
				"NUMERIC_VALUES_FLOAT":     "3.14",
			},
		},
		{
			name:    "invalid structure",
			input:   `{"key": [1,2,3`,
			wantErr: true,
		},
		{
			name:  "empty input",
			input: "",
			want:  map[string]string{},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			p := New()
			got, err := p.Parse(strings.NewReader(tt.input))
			if (err != nil) != tt.wantErr {
				t.Errorf("Parse() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr {
				for k, v := range tt.want {
					if got[k] != v {
						t.Errorf("Parse() got[%s] = %v, want %v", k, got[k], v)
					}
				}
			}
		})
	}
}
