package sqlite

import (
	"database/sql"
	"io"
	"io/ioutil"
	"os"
	"strings"

	"github.com/handaber/cfg2env/plugin"
	_ "github.com/mattn/go-sqlite3"
)

// Plugin implements the plugin.Plugin interface for SQLite format
type Plugin struct {
	plugin.BasePlugin
	query string
}

// New creates a new SQLite plugin
func New() *Plugin {
	return &Plugin{
		BasePlugin: plugin.NewBasePlugin("sqlite", "db", "sqlite", "sqlite3"),
		query:      "SELECT key, value FROM config",
	}
}

// Parse implements plugin.Plugin
func (p *Plugin) Parse(r io.Reader) (map[string]string, error) {
	// Handle empty input
	if r == nil {
		return make(map[string]string), nil
	}

	// Create a temporary file to store the database
	tmpfile, err := ioutil.TempFile("", "cfg2env-*.db")
	if err != nil {
		return nil, err
	}
	defer os.Remove(tmpfile.Name())
	defer tmpfile.Close()

	// Copy the database to the temporary file
	if _, err := io.Copy(tmpfile, r); err != nil {
		return nil, err
	}

	// Get file size
	info, err := tmpfile.Stat()
	if err != nil {
		return nil, err
	}

	// If file is empty, return empty map
	if info.Size() == 0 {
		return make(map[string]string), nil
	}

	// Open the database
	db, err := sql.Open("sqlite3", tmpfile.Name())
	if err != nil {
		return nil, err
	}
	defer db.Close()

	// Query the database
	rows, err := db.Query(p.query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	// Read the results into a map
	env := make(map[string]string)
	for rows.Next() {
		var key, value string
		if err := rows.Scan(&key, &value); err != nil {
			return nil, err
		}
		env[strings.ToUpper(key)] = value
	}

	return env, rows.Err()
}

// SetQuery sets a custom query for the plugin
func (p *Plugin) SetQuery(query string) {
	if query != "" {
		p.query = query
	}
}
