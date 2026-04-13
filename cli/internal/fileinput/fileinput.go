// Package fileinput parses `--file name=path` specs and reads file or stdin
// content for `ih insights create|update`.
package fileinput

import (
	"fmt"
	"io"
	"os"
	"strings"
)

// FileInput is the payload the API expects for a single insight file.
type FileInput struct {
	Filename    string `json:"filename"`
	Content     string `json:"content"`
	ContentType string `json:"content_type,omitempty"`
}

// ParseSpec splits "name=path" on the first "=" so paths containing "=" work.
func ParseSpec(arg string) (name, path string, err error) {
	idx := strings.Index(arg, "=")
	if idx < 0 {
		return "", "", fmt.Errorf("invalid --file %q: expected name=path", arg)
	}
	name = arg[:idx]
	path = arg[idx+1:]
	if name == "" {
		return "", "", fmt.Errorf("invalid --file %q: name is empty", arg)
	}
	if path == "" {
		return "", "", fmt.Errorf("invalid --file %q: path is empty", arg)
	}
	return name, path, nil
}

// ContentTypeFor returns the API content-type for a filename extension,
// falling back to "text/html" (the API's own default for single-file create).
func ContentTypeFor(filename string) string {
	lower := strings.ToLower(filename)
	switch {
	case strings.HasSuffix(lower, ".html"), strings.HasSuffix(lower, ".htm"):
		return "text/html"
	case strings.HasSuffix(lower, ".md"), strings.HasSuffix(lower, ".markdown"):
		return "text/markdown"
	case strings.HasSuffix(lower, ".json"):
		return "application/json"
	case strings.HasSuffix(lower, ".txt"):
		return "text/plain"
	case strings.HasSuffix(lower, ".css"):
		return "text/css"
	case strings.HasSuffix(lower, ".js"):
		return "application/javascript"
	default:
		return "text/html"
	}
}

// ReadContent returns the content at path, or reads from stdin when path == "-".
func ReadContent(path string, stdin io.Reader) (string, error) {
	if path == "-" {
		if stdin == nil {
			stdin = os.Stdin
		}
		data, err := io.ReadAll(stdin)
		if err != nil {
			return "", fmt.Errorf("read stdin: %w", err)
		}
		return string(data), nil
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

// Load parses a "name=path" spec, reads the file, and infers a content-type.
func Load(spec string) (FileInput, error) {
	name, path, err := ParseSpec(spec)
	if err != nil {
		return FileInput{}, err
	}
	content, err := ReadContent(path, nil)
	if err != nil {
		return FileInput{}, fmt.Errorf("read %s: %w", path, err)
	}
	return FileInput{
		Filename:    name,
		Content:     content,
		ContentType: ContentTypeFor(name),
	}, nil
}
