package cmd

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/c-sonnier/insaight-hub/cli/internal/client"
	"github.com/c-sonnier/insaight-hub/cli/internal/config"
	"github.com/spf13/cobra"
	"golang.org/x/term"
)

var (
	loginURL        string
	loginToken      string
	loginDefaultOrg string
	loginSkipVerify bool
)

var loginCmd = &cobra.Command{
	Use:   "login",
	Short: "Save hub URL and API token to the config file",
	RunE:  runLogin,
}

func init() {
	loginCmd.Flags().StringVar(&loginURL, "url", "", "hub URL (prompted if not provided)")
	loginCmd.Flags().StringVar(&loginToken, "token", "", "API token (prompted if not provided)")
	loginCmd.Flags().StringVar(&loginDefaultOrg, "default-org", "", "optional default organization")
	loginCmd.Flags().BoolVar(&loginSkipVerify, "skip-verify", false, "skip calling /api/v1/me to verify the token")
}

func runLogin(cmd *cobra.Command, _ []string) error {
	reader := bufio.NewReader(os.Stdin)

	url := loginURL
	if url == "" {
		fmt.Fprint(cmd.OutOrStdout(), "Hub URL: ")
		line, err := reader.ReadString('\n')
		if err != nil {
			return err
		}
		url = strings.TrimSpace(line)
	}
	if url == "" {
		return fmt.Errorf("hub URL is required")
	}

	token := loginToken
	if token == "" {
		fmt.Fprint(cmd.OutOrStdout(), "API token: ")
		if term.IsTerminal(int(os.Stdin.Fd())) {
			raw, err := term.ReadPassword(int(os.Stdin.Fd()))
			fmt.Fprintln(cmd.OutOrStdout())
			if err != nil {
				return err
			}
			token = strings.TrimSpace(string(raw))
		} else {
			line, err := reader.ReadString('\n')
			if err != nil {
				return err
			}
			token = strings.TrimSpace(line)
		}
	}
	if token == "" {
		return fmt.Errorf("API token is required")
	}

	cfg := &config.Config{
		URL:        strings.TrimRight(url, "/"),
		Token:      token,
		DefaultOrg: loginDefaultOrg,
	}

	if !loginSkipVerify {
		c := client.New(cfg.URL, cfg.Token)
		if _, err := c.Get("/api/v1/organizations"); err != nil {
			return fmt.Errorf("could not verify credentials: %w", err)
		}
	}

	if err := config.Save(cfg); err != nil {
		return err
	}

	fmt.Fprintf(cmd.OutOrStdout(), "Saved credentials to %s\n", config.DefaultPath())
	return nil
}
