package fileinput

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestParseSpec_SplitsNameAndPath(t *testing.T) {
	name, path, err := ParseSpec("index.html=./report.html")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if name != "index.html" {
		t.Errorf("name: got %q, want index.html", name)
	}
	if path != "./report.html" {
		t.Errorf("path: got %q, want ./report.html", path)
	}
}

func TestParseSpec_OnlySplitsOnFirstEquals(t *testing.T) {
	_, path, err := ParseSpec("foo.html=/tmp/a=b.html")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if path != "/tmp/a=b.html" {
		t.Errorf("path: got %q, want /tmp/a=b.html", path)
	}
}

func TestParseSpec_ErrorWhenNoEquals(t *testing.T) {
	if _, _, err := ParseSpec("not-a-spec"); err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestParseSpec_ErrorWhenNameEmpty(t *testing.T) {
	if _, _, err := ParseSpec("=path"); err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestParseSpec_ErrorWhenPathEmpty(t *testing.T) {
	if _, _, err := ParseSpec("name="); err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestContentTypeFor_HTML(t *testing.T) {
	if got := ContentTypeFor("report.html"); got != "text/html" {
		t.Errorf("got %q, want text/html", got)
	}
}

func TestContentTypeFor_Markdown(t *testing.T) {
	if got := ContentTypeFor("NOTES.md"); got != "text/markdown" {
		t.Errorf("got %q, want text/markdown", got)
	}
}

func TestContentTypeFor_JSON(t *testing.T) {
	if got := ContentTypeFor("data.json"); got != "application/json" {
		t.Errorf("got %q, want application/json", got)
	}
}

func TestContentTypeFor_Text(t *testing.T) {
	if got := ContentTypeFor("readme.txt"); got != "text/plain" {
		t.Errorf("got %q, want text/plain", got)
	}
}

func TestContentTypeFor_UnknownDefaultsToHTML(t *testing.T) {
	if got := ContentTypeFor("thing.xyz"); got != "text/html" {
		t.Errorf("got %q, want text/html fallback", got)
	}
}

func TestReadContent_FromStdinWhenDashPath(t *testing.T) {
	stdin := strings.NewReader("<h1>hello</h1>")
	got, err := ReadContent("-", stdin)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "<h1>hello</h1>" {
		t.Errorf("got %q, want <h1>hello</h1>", got)
	}
}

func TestReadContent_FromFile(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "x.html")
	if err := os.WriteFile(path, []byte("<p>from disk</p>"), 0o600); err != nil {
		t.Fatal(err)
	}

	got, err := ReadContent(path, nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "<p>from disk</p>" {
		t.Errorf("got %q, want <p>from disk</p>", got)
	}
}

func TestReadContent_ErrorWhenMissingFile(t *testing.T) {
	dir := t.TempDir()
	if _, err := ReadContent(filepath.Join(dir, "nope"), nil); err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestLoad_ParsesSpecAndReadsFile(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "report.html")
	if err := os.WriteFile(path, []byte("<h1>hi</h1>"), 0o600); err != nil {
		t.Fatal(err)
	}

	got, err := Load("index.html=" + path)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.Filename != "index.html" {
		t.Errorf("Filename: got %q, want index.html", got.Filename)
	}
	if got.Content != "<h1>hi</h1>" {
		t.Errorf("Content: got %q, want <h1>hi</h1>", got.Content)
	}
	if got.ContentType != "text/html" {
		t.Errorf("ContentType: got %q, want text/html", got.ContentType)
	}
}
