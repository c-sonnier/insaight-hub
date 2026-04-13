package cmd

import (
	"github.com/c-sonnier/insaight-hub/cli/internal/config"
	"github.com/c-sonnier/insaight-hub/cli/internal/output"
	"github.com/spf13/cobra"
)

var (
	flagJSON   bool
	flagPretty bool
	flagOrg    string
	flagURL    string
)

var rootCmd = &cobra.Command{
	Use:   "ih",
	Short: "Insaight Hub CLI",
	Long:  "ih is the command-line client for Insaight Hub. Run `ih login` to get started.",
	SilenceUsage: true,
}

func init() {
	rootCmd.PersistentFlags().BoolVar(&flagJSON, "json", false, "force JSON output (overrides TTY detection)")
	rootCmd.PersistentFlags().BoolVar(&flagPretty, "pretty", false, "force human-friendly table output")
	rootCmd.PersistentFlags().StringVar(&flagOrg, "org", "", "organization name or UUID (overrides config default)")
	rootCmd.PersistentFlags().StringVar(&flagURL, "url", "", "hub URL (overrides config)")

	rootCmd.AddCommand(loginCmd)
	rootCmd.AddCommand(logoutCmd)
	rootCmd.AddCommand(organizationsCmd)
}

func Execute() error {
	return rootCmd.Execute()
}

func outputMode() output.Mode {
	switch {
	case flagJSON:
		return output.ModeJSON
	case flagPretty:
		return output.ModeTable
	default:
		return output.ModeAuto
	}
}

func loadConfig() (*config.Config, error) {
	cfg, err := config.Load()
	if err != nil {
		return nil, err
	}
	if flagURL != "" {
		cfg.URL = flagURL
	}
	return cfg, nil
}
