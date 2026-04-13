package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestLoadFrom_ReturnsEmptyConfigWhenFileMissing(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "missing.toml")

	cfg, err := LoadFrom(path)
	if err != nil {
		t.Fatalf("expected no error for missing file, got %v", err)
	}
	if cfg.URL != "" || cfg.Token != "" || cfg.DefaultOrg != "" {
		t.Fatalf("expected empty config, got %+v", cfg)
	}
}

func TestSaveAndLoadFrom_RoundTrip(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "config.toml")

	want := &Config{
		URL:        "https://hub.example.com",
		Token:      "abc123",
		DefaultOrg: "acme",
	}

	if err := SaveTo(path, want); err != nil {
		t.Fatalf("SaveTo: %v", err)
	}

	got, err := LoadFrom(path)
	if err != nil {
		t.Fatalf("LoadFrom: %v", err)
	}
	if *got != *want {
		t.Fatalf("round trip mismatch: got %+v, want %+v", got, want)
	}
}

func TestSaveTo_CreatesParentDirectory(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "nested", "dir", "config.toml")

	if err := SaveTo(path, &Config{URL: "u", Token: "t"}); err != nil {
		t.Fatalf("SaveTo: %v", err)
	}
	if _, err := os.Stat(path); err != nil {
		t.Fatalf("expected file to exist: %v", err)
	}
}

func TestSaveTo_FileIsUserReadableOnly(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "config.toml")

	if err := SaveTo(path, &Config{Token: "secret"}); err != nil {
		t.Fatalf("SaveTo: %v", err)
	}
	info, err := os.Stat(path)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode().Perm() != 0600 {
		t.Fatalf("expected 0600, got %o", info.Mode().Perm())
	}
}

func TestApplyEnv_OverridesConfigValues(t *testing.T) {
	cfg := &Config{URL: "file-url", Token: "file-token", DefaultOrg: "file-org"}

	t.Setenv("INSAIGHT_URL", "env-url")
	t.Setenv("INSAIGHT_TOKEN", "env-token")
	t.Setenv("INSAIGHT_ORG", "env-org")

	ApplyEnv(cfg)

	if cfg.URL != "env-url" {
		t.Errorf("URL: got %q, want env-url", cfg.URL)
	}
	if cfg.Token != "env-token" {
		t.Errorf("Token: got %q, want env-token", cfg.Token)
	}
	if cfg.DefaultOrg != "env-org" {
		t.Errorf("DefaultOrg: got %q, want env-org", cfg.DefaultOrg)
	}
}

func TestApplyEnv_LeavesFileValuesWhenUnset(t *testing.T) {
	cfg := &Config{URL: "file-url", Token: "file-token", DefaultOrg: "file-org"}

	t.Setenv("INSAIGHT_URL", "")
	t.Setenv("INSAIGHT_TOKEN", "")
	t.Setenv("INSAIGHT_ORG", "")

	ApplyEnv(cfg)

	if cfg.URL != "file-url" || cfg.Token != "file-token" || cfg.DefaultOrg != "file-org" {
		t.Errorf("expected file values preserved, got %+v", cfg)
	}
}

func TestDefaultPath_RespectsXDG(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", "/xdg/home")
	t.Setenv("HOME", "/home/user")

	if got, want := DefaultPath(), "/xdg/home/ih/config.toml"; got != want {
		t.Errorf("DefaultPath: got %q, want %q", got, want)
	}
}

func TestDefaultPath_FallsBackToHome(t *testing.T) {
	t.Setenv("XDG_CONFIG_HOME", "")
	t.Setenv("HOME", "/home/user")

	if got, want := DefaultPath(), "/home/user/.config/ih/config.toml"; got != want {
		t.Errorf("DefaultPath: got %q, want %q", got, want)
	}
}
