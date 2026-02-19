package utils

import "path/filepath"

// GetTestDataPath returns the path to a test data file relative to the project root
func GetTestDataPath(file string) string {
	return filepath.Join("..", "..", "testdata", file)
}
