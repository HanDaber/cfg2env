package sqlite

import (
	"database/sql"
	"os"
	"strings"
	"testing"

	_ "github.com/mattn/go-sqlite3"
)

func setupTestDB(t *testing.T) string {
	// Create a temporary database file
	tmpfile, err := os.CreateTemp("", "cfg2env-test-*.db")
	if err != nil {
		t.Fatalf("Failed to create temp file: %v", err)
	}
	tmpfile.Close()

	// Open the database
	db, err := sql.Open("sqlite3", tmpfile.Name())
	if err != nil {
		os.Remove(tmpfile.Name())
		t.Fatalf("Failed to open database: %v", err)
	}
	defer db.Close()

	// Read and execute SQL script
	sqlScript, err := os.ReadFile("testdata/config.sql")
	if err != nil {
		os.Remove(tmpfile.Name())
		t.Fatalf("Failed to read SQL script: %v", err)
	}

	// Execute the script
	_, err = db.Exec(string(sqlScript))
	if err != nil {
		os.Remove(tmpfile.Name())
		t.Fatalf("Failed to set up test data: %v", err)
	}

	return tmpfile.Name()
}

func TestPlugin_Parse(t *testing.T) {
	dbPath := setupTestDB(t)
	defer os.Remove(dbPath)

	// Read database file
	dbContent, err := os.ReadFile(dbPath)
	if err != nil {
		t.Fatalf("Failed to read database file: %v", err)
	}

	// Create plugin
	p := New()

	// Test parsing
	result, err := p.Parse(strings.NewReader(string(dbContent)))
	if err != nil {
		t.Errorf("Parse() error = %v", err)
		return
	}

	// Verify results
	expected := map[string]string{
		"DATABASE_HOST":     "localhost",
		"DATABASE_PORT":     "5432",
		"DATABASE_USER":     "admin",
		"DATABASE_PASSWORD": "secret with spaces",
		"API_URL":           "https://api.example.com",
		"API_TIMEOUT":       "30",
	}

	for k, v := range expected {
		if result[k] != v {
			t.Errorf("Parse() got[%s] = %v, want %v", k, result[k], v)
		}
	}
}

func TestPlugin_Parse_EdgeCases(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		query   string
		want    map[string]string
		wantErr bool
	}{
		{
			name:    "empty_input",
			input:   "",
			want:    make(map[string]string),
			wantErr: false,
		},
		{
			name:    "invalid_sqlite_file",
			input:   "not a sqlite database",
			want:    nil,
			wantErr: true,
		},
		{
			name:    "empty_query",
			input:   "",
			query:   "",
			want:    make(map[string]string),
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			p := New()
			if tt.query != "" {
				p.SetQuery(tt.query)
			}

			got, err := p.Parse(strings.NewReader(tt.input))
			if (err != nil) != tt.wantErr {
				t.Errorf("Parse() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr && len(got) != len(tt.want) {
				t.Errorf("Parse() got = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestPlugin_Parse_InvalidDatabase(t *testing.T) {
	p := New()
	p.SetQuery("SELECT invalid_column FROM non_existent_table")

	_, err := p.Parse(strings.NewReader("not a sqlite database"))
	if err == nil {
		t.Error("Parse() error = nil, want error for invalid database")
	}
}
