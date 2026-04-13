package output

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
)

// Mode toggles rendering behavior.
type Mode int

const (
	ModeAuto Mode = iota
	ModeJSON
	ModeTable
)

// Render writes v to stdout honoring mode.
// Phase 1: always renders JSON. Tables arrive in Phase 5.
func Render(v any, mode Mode) error {
	return RenderTo(os.Stdout, v, mode)
}

func RenderTo(w io.Writer, v any, mode Mode) error {
	_ = mode
	enc := json.NewEncoder(w)
	enc.SetIndent("", "  ")
	return enc.Encode(v)
}

// PrintErr writes an error to stderr in a consistent format.
func PrintErr(err error) {
	fmt.Fprintln(os.Stderr, "Error:", err)
}
