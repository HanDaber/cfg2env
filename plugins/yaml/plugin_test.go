package yaml

import (
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func getTestDataPath(file string) string {
	return filepath.Join("testdata", file)
}

func TestPlugin_Parse(t *testing.T) {
	tests := []struct {
		name    string
		file    string
		want    map[string]string
		wantErr bool
	}{
		{
			name: "valid yaml",
			file: getTestDataPath("config.yaml"),
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
			name:    "invalid yaml",
			file:    getTestDataPath("invalid.yaml"),
			wantErr: true,
		},
		{
			name:    "non-existent file",
			file:    getTestDataPath("nonexistent.yaml"),
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			p := New()

			// Open test file
			f, err := os.Open(tt.file)
			if os.IsNotExist(err) && tt.wantErr {
				return // Expected error for non-existent file
			}
			if err != nil {
				t.Fatalf("Failed to open test file: %v", err)
			}
			defer f.Close()

			// Parse the file
			got, err := p.Parse(f)
			if (err != nil) != tt.wantErr {
				t.Errorf("Parse() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if tt.wantErr {
				return
			}

			// Compare results
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("Parse() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestPlugin_Parse_EdgeCases(t *testing.T) {
	// Read edge cases file
	data, err := os.ReadFile(getTestDataPath("edge_cases.yaml"))
	if err != nil {
		t.Fatalf("Failed to read edge cases file: %v", err)
	}

	tests := []struct {
		name    string
		input   string
		want    map[string]string
		wantErr bool
	}{
		{
			name:  "empty document",
			input: "---\n",
			want:  make(map[string]string),
		},
		{
			name:  "null values",
			input: string(data),
			want: map[string]string{
				"KEY":       "",
				"OTHER":     "",
				"TRUE_VAL":  "true",
				"FALSE_VAL": "false",
				"INTEGER":   "42",
				"FLOAT":     "3.14",
			},
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
			if tt.wantErr {
				return
			}

			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("Parse() = %v, want %v", got, tt.want)
			}
		})
	}
}
