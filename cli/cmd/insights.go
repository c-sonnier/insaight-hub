package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/c-sonnier/insaight-hub/cli/internal/client"
	"github.com/c-sonnier/insaight-hub/cli/internal/fileinput"
	"github.com/c-sonnier/insaight-hub/cli/internal/org"
	"github.com/c-sonnier/insaight-hub/cli/internal/output"
	"github.com/spf13/cobra"
)

var insightsCmd = &cobra.Command{
	Use:   "insights",
	Short: "Manage insights",
}

var (
	insightsListStatus   string
	insightsListAudience string
	insightsListTag      string
	insightsListSearch   string
	insightsListPage     int
	insightsListPerPage  int
)

var insightsListCmd = &cobra.Command{
	Use:   "list",
	Short: "List insights in an organization",
	RunE: func(cmd *cobra.Command, _ []string) error {
		cfg, err := loadConfig()
		if err != nil {
			return err
		}
		c := client.New(cfg.URL, cfg.Token)
		orgID, err := org.Resolve(c, flagOrg, cfg.DefaultOrg)
		if err != nil {
			return err
		}

		items, pagination, err := c.ListInsights(orgID, client.ListInsightsOptions{
			Status:   insightsListStatus,
			Audience: insightsListAudience,
			Tag:      insightsListTag,
			Search:   insightsListSearch,
			Page:     insightsListPage,
			PerPage:  insightsListPerPage,
		})
		if err != nil {
			return err
		}

		return output.Render(map[string]any{
			"insight_items": items,
			"pagination":    pagination,
		}, outputMode())
	},
}

var insightsGetFormat string

var insightsGetCmd = &cobra.Command{
	Use:   "get <slug>",
	Short: "Fetch a single insight by slug (markdown by default)",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg, err := loadConfig()
		if err != nil {
			return err
		}
		c := client.New(cfg.URL, cfg.Token)
		orgID, err := org.Resolve(c, flagOrg, cfg.DefaultOrg)
		if err != nil {
			return err
		}

		detail, err := c.GetInsight(orgID, args[0], insightsGetFormat)
		if err != nil {
			return err
		}

		if flagJSON {
			return output.Render(detail, output.ModeJSON)
		}
		return printInsightContent(cmd, detail)
	},
}

func printInsightContent(cmd *cobra.Command, detail *client.InsightDetail) error {
	var parts []string
	for _, f := range detail.Files {
		parts = append(parts, f.Content)
	}
	fmt.Fprintln(cmd.OutOrStdout(), strings.Join(parts, "\n\n"))
	return nil
}

var (
	insightsCreateTitle       string
	insightsCreateAudience    string
	insightsCreateDescription string
	insightsCreateTags        []string
	insightsCreateEntryFile   string
	insightsCreateFiles       []string
	insightsCreateContent     string
	insightsCreateFilename    string
	insightsCreatePublish     bool
)

var insightsCreateCmd = &cobra.Command{
	Use:   "create",
	Short: "Create a new insight",
	RunE: func(cmd *cobra.Command, _ []string) error {
		cfg, err := loadConfig()
		if err != nil {
			return err
		}
		c := client.New(cfg.URL, cfg.Token)
		orgID, err := org.Resolve(c, flagOrg, cfg.DefaultOrg)
		if err != nil {
			return err
		}

		files, err := collectCreateFiles(cmd)
		if err != nil {
			return err
		}

		detail, err := c.CreateInsight(orgID, client.CreateInsightReq{
			Title:       insightsCreateTitle,
			Audience:    insightsCreateAudience,
			Description: insightsCreateDescription,
			Tags:        insightsCreateTags,
			EntryFile:   insightsCreateEntryFile,
			Files:       files,
			Publish:     insightsCreatePublish,
		})
		if err != nil {
			return err
		}
		return output.Render(detail, outputMode())
	},
}

func collectCreateFiles(cmd *cobra.Command) ([]fileinput.FileInput, error) {
	var files []fileinput.FileInput
	for _, spec := range insightsCreateFiles {
		fi, err := fileinput.Load(spec)
		if err != nil {
			return nil, err
		}
		files = append(files, fi)
	}
	if insightsCreateContent != "" {
		stdin := cmd.InOrStdin()
		if stdin == nil {
			stdin = os.Stdin
		}
		content, err := fileinput.ReadContent(insightsCreateContent, stdin)
		if err != nil {
			return nil, err
		}
		filename := insightsCreateFilename
		if filename == "" {
			filename = "index.html"
		}
		files = append(files, fileinput.FileInput{
			Filename:    filename,
			Content:     content,
			ContentType: fileinput.ContentTypeFor(filename),
		})
	}
	return files, nil
}

var (
	insightsUpdateTitle       string
	insightsUpdateDescription string
	insightsUpdateAudience    string
	insightsUpdateEntryFile   string
	insightsUpdateTags        []string
)

var insightsUpdateCmd = &cobra.Command{
	Use:   "update <slug>",
	Short: "Update an existing insight",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg, err := loadConfig()
		if err != nil {
			return err
		}
		c := client.New(cfg.URL, cfg.Token)
		orgID, err := org.Resolve(c, flagOrg, cfg.DefaultOrg)
		if err != nil {
			return err
		}

		detail, err := c.UpdateInsight(orgID, args[0], client.UpdateInsightReq{
			Title:       insightsUpdateTitle,
			Description: insightsUpdateDescription,
			Audience:    insightsUpdateAudience,
			EntryFile:   insightsUpdateEntryFile,
			Tags:        insightsUpdateTags,
		})
		if err != nil {
			return err
		}
		return output.Render(detail, outputMode())
	},
}

var insightsDeleteCmd = &cobra.Command{
	Use:   "delete <slug>",
	Short: "Delete an insight",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg, err := loadConfig()
		if err != nil {
			return err
		}
		c := client.New(cfg.URL, cfg.Token)
		orgID, err := org.Resolve(c, flagOrg, cfg.DefaultOrg)
		if err != nil {
			return err
		}

		if err := c.DeleteInsight(orgID, args[0]); err != nil {
			return err
		}
		fmt.Fprintf(cmd.OutOrStdout(), "Deleted %s\n", args[0])
		return nil
	},
}

func init() {
	insightsListCmd.Flags().StringVar(&insightsListStatus, "status", "", "filter by status (draft|published)")
	insightsListCmd.Flags().StringVar(&insightsListAudience, "audience", "", "filter by audience")
	insightsListCmd.Flags().StringVar(&insightsListTag, "tag", "", "filter by tag")
	insightsListCmd.Flags().StringVar(&insightsListSearch, "search", "", "full-text search query")
	insightsListCmd.Flags().IntVar(&insightsListPage, "page", 0, "page number")
	insightsListCmd.Flags().IntVar(&insightsListPerPage, "per-page", 0, "results per page (default 20)")

	insightsGetCmd.Flags().StringVar(&insightsGetFormat, "format", "markdown", "content format: markdown|html")

	insightsCreateCmd.Flags().StringVar(&insightsCreateTitle, "title", "", "insight title (required)")
	insightsCreateCmd.Flags().StringVar(&insightsCreateAudience, "audience", "", "audience (e.g. developer, stakeholder) (required)")
	insightsCreateCmd.Flags().StringVar(&insightsCreateDescription, "description", "", "short description")
	insightsCreateCmd.Flags().StringSliceVar(&insightsCreateTags, "tag", nil, "tag (repeatable)")
	insightsCreateCmd.Flags().StringVar(&insightsCreateEntryFile, "entry-file", "", "entry filename among --file uploads")
	insightsCreateCmd.Flags().StringArrayVar(&insightsCreateFiles, "file", nil, "file upload as name=path (repeatable)")
	insightsCreateCmd.Flags().StringVar(&insightsCreateContent, "content", "", "single-file content path (or - for stdin)")
	insightsCreateCmd.Flags().StringVar(&insightsCreateFilename, "filename", "", "filename for --content (default index.html)")
	insightsCreateCmd.Flags().BoolVar(&insightsCreatePublish, "publish", false, "publish immediately after create")
	_ = insightsCreateCmd.MarkFlagRequired("title")
	_ = insightsCreateCmd.MarkFlagRequired("audience")

	insightsUpdateCmd.Flags().StringVar(&insightsUpdateTitle, "title", "", "new title")
	insightsUpdateCmd.Flags().StringVar(&insightsUpdateDescription, "description", "", "new description")
	insightsUpdateCmd.Flags().StringVar(&insightsUpdateAudience, "audience", "", "new audience")
	insightsUpdateCmd.Flags().StringVar(&insightsUpdateEntryFile, "entry-file", "", "new entry filename")
	insightsUpdateCmd.Flags().StringSliceVar(&insightsUpdateTags, "tag", nil, "replace tags (repeatable)")

	insightsCmd.AddCommand(insightsListCmd, insightsGetCmd, insightsCreateCmd, insightsUpdateCmd, insightsDeleteCmd)
}
