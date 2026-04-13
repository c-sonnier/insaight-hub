package config

import (
	"errors"
	"os"
	"path/filepath"

	"github.com/BurntSushi/toml"
)

type Config struct {
	URL        string `toml:"url"`
	Token      string `toml:"token"`
	DefaultOrg string `toml:"default_org"`
}

func DefaultPath() string {
	if xdg := os.Getenv("XDG_CONFIG_HOME"); xdg != "" {
		return filepath.Join(xdg, "ih", "config.toml")
	}
	return filepath.Join(os.Getenv("HOME"), ".config", "ih", "config.toml")
}

func Load() (*Config, error) {
	cfg, err := LoadFrom(DefaultPath())
	if err != nil {
		return nil, err
	}
	ApplyEnv(cfg)
	return cfg, nil
}

func LoadFrom(path string) (*Config, error) {
	cfg := &Config{}
	data, err := os.ReadFile(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return cfg, nil
		}
		return nil, err
	}
	if _, err := toml.Decode(string(data), cfg); err != nil {
		return nil, err
	}
	return cfg, nil
}

func Save(cfg *Config) error {
	return SaveTo(DefaultPath(), cfg)
}

func SaveTo(path string, cfg *Config) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return err
	}
	f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, 0o600)
	if err != nil {
		return err
	}
	defer f.Close()
	return toml.NewEncoder(f).Encode(cfg)
}

func ApplyEnv(cfg *Config) {
	if v := os.Getenv("INSAIGHT_URL"); v != "" {
		cfg.URL = v
	}
	if v := os.Getenv("INSAIGHT_TOKEN"); v != "" {
		cfg.Token = v
	}
	if v := os.Getenv("INSAIGHT_ORG"); v != "" {
		cfg.DefaultOrg = v
	}
}
