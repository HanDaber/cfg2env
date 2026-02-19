package converter

import (
	"path/filepath"
	"strings"
)

// Matcher defines the interface for pattern matching strategies
type Matcher interface {
	Match(pattern, key string) bool
}

// GlobMatcher implements glob-style pattern matching using stdlib
type GlobMatcher struct{}

// Match returns true if key matches the glob pattern
func (g GlobMatcher) Match(pattern, key string) bool {
	matched, _ := filepath.Match(pattern, key)
	return matched
}

// filter holds normalized patterns and applies include/exclude logic
type filter struct {
	include []string
	exclude []string
	matcher Matcher
}

// shouldInclude determines if a key should be included based on filter rules
// Precedence: include patterns first (whitelist), then exclude patterns (blacklist)
func (f *filter) shouldInclude(key string) bool {
	// If include patterns specified, key must match at least one
	if len(f.include) > 0 {
		matched := false
		for _, pattern := range f.include {
			if f.matcher.Match(pattern, key) {
				matched = true
				break
			}
		}
		if !matched {
			return false
		}
	}

	// Check exclude patterns - if any match, exclude the key
	for _, pattern := range f.exclude {
		if f.matcher.Match(pattern, key) {
			return false
		}
	}

	return true
}

// normalizePatterns applies the same normalization as keys (uppercase + dunder + trim)
func (c *Converter) normalizePatterns(patterns []string) []string {
	if len(patterns) == 0 {
		return nil
	}

	normalized := make([]string, 0, len(patterns))
	for _, p := range patterns {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		normalized = append(normalized, c.processKey(strings.ToUpper(p)))
	}
	return normalized
}

// SetFilterPatterns configures the converter to filter keys by include/exclude patterns
// Patterns are normalized through the same pipeline as keys (uppercase + dunder processing)
func (c *Converter) SetFilterPatterns(include, exclude []string, matcher Matcher) {
	normalizedInclude := c.normalizePatterns(include)
	normalizedExclude := c.normalizePatterns(exclude)

	// If no patterns remain after normalization, disable filtering
	if len(normalizedInclude) == 0 && len(normalizedExclude) == 0 {
		c.filter = nil
		return
	}

	c.filter = &filter{
		include: normalizedInclude,
		exclude: normalizedExclude,
		matcher: matcher,
	}
}
