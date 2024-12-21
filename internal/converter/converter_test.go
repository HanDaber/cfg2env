package converter

import (
	"bytes"
	"io"
	"strings"
	"testing"

	"github.com/handaber/cfg2env/plugin"
)

// mockPlugin implements plugin.Plugin for testing
type mockPlugin struct {
	plugin.BasePlugin
	parseFunc func(io.Reader) (map[string]string, error)
}

func (p *mockPlugin) Parse(r io.Reader) (map[string]string, error) {
	return p.parseFunc(r)
}

func TestConverter_Convert(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		want    string
		wantErr bool
	}{
		{
			name:  "basic key-value pairs",
			input: "key=value",
			want:  "KEY=value\n",
		},
		{
			name:  "values with spaces",
			input: "key=value with spaces",
			want:  "KEY=value with spaces\n",
		},
		{
			name:  "empty values",
			input: "key=",
			want:  "KEY=\n",
		},
		{
			name:    "plugin error",
			input:   "error",
			wantErr: true,
		},
		{
			name:  "empty input",
			input: "",
			want:  "",
		},
		{
			name:  "single character values",
			input: "k=v",
			want:  "K=v\n",
		},
		{
			name:  "mixed value types",
			input: "str=text\nnum=123\nbool=true",
			want:  "BOOL=true\nNUM=123\nSTR=text\n",
		},
		{
			name:  "case sensitivity",
			input: "KEY=VALUE\nkey=value",
			want:  "KEY=value\n",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create mock plugin
			p := &mockPlugin{
				BasePlugin: plugin.NewBasePlugin("mock"),
				parseFunc: func(r io.Reader) (map[string]string, error) {
					if tt.input == "error" {
						return nil, io.ErrUnexpectedEOF
					}

					// Parse input into map
					env := make(map[string]string)
					for _, line := range strings.Split(tt.input, "\n") {
						if line == "" {
							continue
						}
						parts := strings.SplitN(line, "=", 2)
						if len(parts) == 2 {
							env[parts[0]] = parts[1]
						}
					}
					return env, nil
				},
			}

			// Create converter with mock plugin
			c := New(p)

			// Convert input
			var out bytes.Buffer
			err := c.Convert(strings.NewReader(tt.input), &out)

			// Check error
			if (err != nil) != tt.wantErr {
				t.Errorf("Convert() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if tt.wantErr {
				return
			}

			// Check output
			if got := out.String(); got != tt.want {
				t.Errorf("Convert() = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestConverter_Convert_OutputFormatting(t *testing.T) {
	tests := []struct {
		name  string
		input map[string]string
		want  string
	}{
		{
			name: "special characters",
			input: map[string]string{
				"key": "value with spaces",
			},
			want: "KEY=value with spaces\n",
		},
		{
			name: "quotes in values",
			input: map[string]string{
				"key": `value with "quotes"`,
			},
			want: `KEY=value with "quotes"` + "\n",
		},
		{
			name: "multiple special chars",
			input: map[string]string{
				"key": `value with "quotes" and spaces`,
			},
			want: `KEY=value with "quotes" and spaces` + "\n",
		},
		{
			name: "all special characters",
			input: map[string]string{
				"key": `!@#$%^&*()_+-=[]{}|;:'",.<>?/~` + "`",
			},
			want: `KEY=!@#$%^&*()_+-=[]{}|;:'",.<>?/~` + "`" + "\n",
		},
		{
			name: "unicode characters",
			input: map[string]string{
				"key": "value with 日本語",
			},
			want: "KEY=value with 日本語\n",
		},
		{
			name: "environment variable syntax",
			input: map[string]string{
				"key": "$HOME/path",
			},
			want: "KEY=$HOME/path\n",
		},
		{
			name: "shell special characters",
			input: map[string]string{
				"key": "$(command)",
			},
			want: "KEY=$(command)\n",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create mock plugin
			p := &mockPlugin{
				BasePlugin: plugin.NewBasePlugin("mock"),
				parseFunc: func(r io.Reader) (map[string]string, error) {
					return tt.input, nil
				},
			}

			// Create converter with mock plugin
			c := New(p)

			// Convert input
			var out bytes.Buffer
			err := c.Convert(strings.NewReader(""), &out)
			if err != nil {
				t.Fatalf("Convert() error = %v", err)
			}

			// Check output
			if got := out.String(); got != tt.want {
				t.Errorf("Convert() = %q, want %q", got, tt.want)
			}
		})
	}
}

func TestConverter_Convert_InputValidation(t *testing.T) {
	tests := []struct {
		name    string
		input   io.Reader
		output  io.Writer
		wantErr bool
	}{
		{
			name:    "nil input",
			input:   nil,
			output:  &bytes.Buffer{},
			wantErr: true,
		},
		{
			name:    "nil output",
			input:   strings.NewReader(""),
			output:  nil,
			wantErr: true,
		},
		{
			name:    "failing reader",
			input:   &failingReader{},
			output:  &bytes.Buffer{},
			wantErr: true,
		},
		{
			name:    "failing writer",
			input:   strings.NewReader("key=value"),
			output:  &failingWriter{},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create mock plugin
			p := &mockPlugin{
				BasePlugin: plugin.NewBasePlugin("mock"),
				parseFunc: func(r io.Reader) (map[string]string, error) {
					if _, ok := r.(*failingReader); ok {
						return nil, io.ErrUnexpectedEOF
					}
					return map[string]string{"key": "value"}, nil
				},
			}

			// Create converter with mock plugin
			c := New(p)

			// Convert input
			err := c.Convert(tt.input, tt.output)
			if (err != nil) != tt.wantErr {
				t.Errorf("Convert() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

// failingReader always returns an error on Read
type failingReader struct{}

func (r *failingReader) Read(p []byte) (n int, err error) {
	return 0, io.ErrUnexpectedEOF
}

// failingWriter always returns an error on Write
type failingWriter struct{}

func (w *failingWriter) Write(p []byte) (n int, err error) {
	return 0, io.ErrShortWrite
}
