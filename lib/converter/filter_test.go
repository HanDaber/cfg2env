package converter

import (
	"testing"
)

func TestGlobMatcher(t *testing.T) {
	matcher := GlobMatcher{}

	tests := []struct {
		pattern string
		key     string
		want    bool
	}{
		// Exact matches
		{"DATABASE_HOST", "DATABASE_HOST", true},
		{"DATABASE_HOST", "DATABASE_PORT", false},

		// Star wildcard - matches any sequence
		{"DATABASE_*", "DATABASE_HOST", true},
		{"DATABASE_*", "DATABASE_PORT", true},
		{"DATABASE_*", "DATABASE_CREDENTIALS_USERNAME", true},
		{"DATABASE_*", "API_HOST", false},
		{"*_PASSWORD", "DATABASE_PASSWORD", true},
		{"*_PASSWORD", "API_PASSWORD", true},
		{"*_PASSWORD", "DATABASE_HOST", false},
		{"DATABASE_*_USERNAME", "DATABASE_CREDENTIALS_USERNAME", true},
		{"DATABASE_*_USERNAME", "DATABASE_USERNAME", false}, // * requires at least one char
		{"DATABASE_*_USERNAME", "DATABASE_PASSWORD", false},

		// Question mark wildcard - matches single character
		{"DATABASE_HOS?", "DATABASE_HOST", true},
		{"DATABASE_HOS?", "DATABASE_HOSE", true},
		{"DATABASE_HOS?", "DATABASE_HOSTT", false},
		{"DATABASE_HOS?", "DATABASE_HOS", false},

		// Match everything
		{"*", "DATABASE_HOST", true},
		{"*", "ANYTHING", true},

		// No wildcards - exact match only
		{"EXACT", "EXACT", true},
		{"EXACT", "EXACTLY", false},
	}

	for _, tt := range tests {
		got := matcher.Match(tt.pattern, tt.key)
		if got != tt.want {
			t.Errorf("GlobMatcher.Match(%q, %q) = %v, want %v", tt.pattern, tt.key, got, tt.want)
		}
	}
}

func TestFilterShouldInclude(t *testing.T) {
	matcher := GlobMatcher{}

	tests := []struct {
		name    string
		include []string
		exclude []string
		key     string
		want    bool
	}{
		// No patterns - include everything
		{
			name: "no patterns",
			key:  "DATABASE_HOST",
			want: true,
		},

		// Include only
		{
			name:    "include match",
			include: []string{"DATABASE_*"},
			key:     "DATABASE_HOST",
			want:    true,
		},
		{
			name:    "include no match",
			include: []string{"DATABASE_*"},
			key:     "API_HOST",
			want:    false,
		},
		{
			name:    "include multiple patterns - first matches",
			include: []string{"DATABASE_*", "API_*"},
			key:     "DATABASE_HOST",
			want:    true,
		},
		{
			name:    "include multiple patterns - second matches",
			include: []string{"DATABASE_*", "API_*"},
			key:     "API_HOST",
			want:    true,
		},
		{
			name:    "include multiple patterns - none match",
			include: []string{"DATABASE_*", "API_*"},
			key:     "CACHE_HOST",
			want:    false,
		},

		// Exclude only
		{
			name:    "exclude match",
			exclude: []string{"*_PASSWORD"},
			key:     "DATABASE_PASSWORD",
			want:    false,
		},
		{
			name:    "exclude no match",
			exclude: []string{"*_PASSWORD"},
			key:     "DATABASE_HOST",
			want:    true,
		},
		{
			name:    "exclude multiple patterns",
			exclude: []string{"*_PASSWORD", "*_SECRET", "*_TOKEN"},
			key:     "API_TOKEN",
			want:    false,
		},

		// Include + Exclude (include first, then exclude)
		{
			name:    "include match, exclude no match",
			include: []string{"DATABASE_*"},
			exclude: []string{"*_PASSWORD"},
			key:     "DATABASE_HOST",
			want:    true,
		},
		{
			name:    "include match, exclude match - exclude wins",
			include: []string{"DATABASE_*"},
			exclude: []string{"*_PASSWORD"},
			key:     "DATABASE_PASSWORD",
			want:    false,
		},
		{
			name:    "include no match, exclude irrelevant",
			include: []string{"DATABASE_*"},
			exclude: []string{"*_PASSWORD"},
			key:     "API_HOST",
			want:    false,
		},
		{
			name:    "complex include/exclude",
			include: []string{"DATABASE_*", "API_*"},
			exclude: []string{"*_PASSWORD", "*_SECRET"},
			key:     "DATABASE_HOST",
			want:    true,
		},
		{
			name:    "complex include/exclude - excluded",
			include: []string{"DATABASE_*", "API_*"},
			exclude: []string{"*_PASSWORD", "*_SECRET"},
			key:     "DATABASE_PASSWORD",
			want:    false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			f := &filter{
				include: tt.include,
				exclude: tt.exclude,
				matcher: matcher,
			}
			got := f.shouldInclude(tt.key)
			if got != tt.want {
				t.Errorf("filter.shouldInclude(%q) = %v, want %v (include=%v, exclude=%v)",
					tt.key, got, tt.want, tt.include, tt.exclude)
			}
		})
	}
}

func TestNormalizePatterns(t *testing.T) {
	c := New(nil)

	tests := []struct {
		name     string
		dunder   int
		patterns []string
		want     []string
	}{
		{
			name:     "uppercase lowercase patterns",
			dunder:   0,
			patterns: []string{"database_*", "api_*"},
			want:     []string{"DATABASE_*", "API_*"},
		},
		{
			name:     "already uppercase",
			dunder:   0,
			patterns: []string{"DATABASE_*", "API_*"},
			want:     []string{"DATABASE_*", "API_*"},
		},
		{
			name:     "mixed case",
			dunder:   0,
			patterns: []string{"Database_*", "Api_*"},
			want:     []string{"DATABASE_*", "API_*"},
		},
		{
			name:     "trim whitespace",
			dunder:   0,
			patterns: []string{" database_* ", "  api_*"},
			want:     []string{"DATABASE_*", "API_*"},
		},
		{
			name:     "empty strings removed",
			dunder:   0,
			patterns: []string{"database_*", "", "  ", "api_*"},
			want:     []string{"DATABASE_*", "API_*"},
		},
		{
			name:     "all empty",
			dunder:   0,
			patterns: []string{"", "  ", ""},
			want:     nil,
		},
		{
			name:     "with dunder processing",
			dunder:   1,
			patterns: []string{"database__*", "api___*"},
			want:     []string{"DATABASE_*", "API__*"},
		},
		{
			name:     "nil input",
			dunder:   0,
			patterns: nil,
			want:     nil,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c.SetDunder(tt.dunder)
			got := c.normalizePatterns(tt.patterns)
			if len(got) != len(tt.want) {
				t.Errorf("normalizePatterns() length = %d, want %d\ngot:  %v\nwant: %v",
					len(got), len(tt.want), got, tt.want)
				return
			}
			for i := range got {
				if got[i] != tt.want[i] {
					t.Errorf("normalizePatterns()[%d] = %q, want %q", i, got[i], tt.want[i])
				}
			}
		})
	}
}

func TestSetFilterPatterns(t *testing.T) {
	c := New(nil)
	matcher := GlobMatcher{}

	tests := []struct {
		name    string
		include []string
		exclude []string
		wantNil bool
	}{
		{
			name:    "both patterns provided",
			include: []string{"DATABASE_*"},
			exclude: []string{"*_PASSWORD"},
			wantNil: false,
		},
		{
			name:    "only include",
			include: []string{"DATABASE_*"},
			wantNil: false,
		},
		{
			name:    "only exclude",
			exclude: []string{"*_PASSWORD"},
			wantNil: false,
		},
		{
			name:    "empty patterns - filter should be nil",
			include: []string{},
			exclude: []string{},
			wantNil: true,
		},
		{
			name:    "whitespace only - filter should be nil",
			include: []string{"  ", ""},
			exclude: []string{"", "  "},
			wantNil: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			c.SetFilterPatterns(tt.include, tt.exclude, matcher)
			if tt.wantNil && c.filter != nil {
				t.Errorf("SetFilterPatterns() filter should be nil but isn't")
			}
			if !tt.wantNil && c.filter == nil {
				t.Errorf("SetFilterPatterns() filter should not be nil but is")
			}
		})
	}
}
