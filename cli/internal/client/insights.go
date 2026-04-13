package client

import (
	"encoding/json"
	"fmt"
	"net/url"

	"github.com/c-sonnier/insaight-hub/cli/internal/fileinput"
)

type Insight struct {
	ID           int64    `json:"id"`
	Slug         string   `json:"slug"`
	Title        string   `json:"title"`
	Description  string   `json:"description"`
	Audience     string   `json:"audience"`
	Status       string   `json:"status"`
	Tags         []string `json:"tags"`
	EntryFile    string   `json:"entry_file"`
	PublishedAt  string   `json:"published_at"`
	CreatedAt    string   `json:"created_at"`
	UpdatedAt    string   `json:"updated_at"`
	FilesCount   int      `json:"files_count,omitempty"`
}

type InsightFile struct {
	ID          int64  `json:"id"`
	Filename    string `json:"filename"`
	Content     string `json:"content"`
	ContentType string `json:"content_type"`
}

type InsightDetail struct {
	Insight
	Files []InsightFile `json:"files"`
}

type Pagination struct {
	CurrentPage int `json:"current_page"`
	TotalPages  int `json:"total_pages"`
	TotalCount  int `json:"total_count"`
	PerPage     int `json:"per_page"`
}

type ListInsightsOptions struct {
	Status   string
	Audience string
	Tag      string
	Search   string
	Page     int
	PerPage  int
}

func (c *Client) ListInsights(orgID string, opts ListInsightsOptions) ([]Insight, Pagination, error) {
	q := url.Values{}
	if opts.Status != "" {
		q.Set("status", opts.Status)
	}
	if opts.Audience != "" {
		q.Set("audience", opts.Audience)
	}
	if opts.Tag != "" {
		q.Set("tag", opts.Tag)
	}
	if opts.Search != "" {
		q.Set("q", opts.Search)
	}
	if opts.Page > 0 {
		q.Set("page", fmt.Sprintf("%d", opts.Page))
	}
	if opts.PerPage > 0 {
		q.Set("per_page", fmt.Sprintf("%d", opts.PerPage))
	}

	path := fmt.Sprintf("/%s/api/v1/insight_items", orgID)
	if encoded := q.Encode(); encoded != "" {
		path += "?" + encoded
	}

	body, err := c.Get(path)
	if err != nil {
		return nil, Pagination{}, err
	}

	var resp struct {
		InsightItems []Insight  `json:"insight_items"`
		Pagination   Pagination `json:"pagination"`
	}
	if err := json.Unmarshal(body, &resp); err != nil {
		return nil, Pagination{}, err
	}
	return resp.InsightItems, resp.Pagination, nil
}

func (c *Client) GetInsight(orgID, slug, format string) (*InsightDetail, error) {
	if format == "" {
		format = "markdown"
	}
	q := url.Values{}
	q.Set("content_format", format)

	path := fmt.Sprintf("/%s/api/v1/insight_items/%s?%s", orgID, slug, q.Encode())

	body, err := c.Get(path)
	if err != nil {
		return nil, err
	}

	var detail InsightDetail
	if err := json.Unmarshal(body, &detail); err != nil {
		return nil, err
	}
	return &detail, nil
}

type CreateInsightReq struct {
	Title       string               `json:"title"`
	Audience    string               `json:"audience"`
	Description string               `json:"description,omitempty"`
	Tags        []string             `json:"tags,omitempty"`
	EntryFile   string               `json:"entry_file,omitempty"`
	Files       []fileinput.FileInput `json:"files,omitempty"`
	// Publish is a CLI-level concern: when true, CreateInsight calls the
	// publish endpoint after the create succeeds. Not serialized.
	Publish bool `json:"-"`
}

type UpdateInsightReq struct {
	Title       string                `json:"title,omitempty"`
	Description string                `json:"description,omitempty"`
	Audience    string                `json:"audience,omitempty"`
	EntryFile   string                `json:"entry_file,omitempty"`
	Tags        []string              `json:"tags,omitempty"`
	Files       []fileinput.FileInput `json:"files,omitempty"`
}

func (c *Client) CreateInsight(orgID string, req CreateInsightReq) (*InsightDetail, error) {
	path := fmt.Sprintf("/%s/api/v1/insight_items", orgID)
	body, err := c.PostJSON(path, req)
	if err != nil {
		return nil, err
	}

	var detail InsightDetail
	if err := json.Unmarshal(body, &detail); err != nil {
		return nil, err
	}

	if req.Publish {
		pubPath := fmt.Sprintf("/%s/api/v1/insight_items/%s/publish", orgID, detail.Slug)
		pubBody, err := c.PostJSON(pubPath, nil)
		if err != nil {
			return &detail, err
		}
		if err := json.Unmarshal(pubBody, &detail); err != nil {
			return &detail, err
		}
	}

	return &detail, nil
}

func (c *Client) UpdateInsight(orgID, slug string, req UpdateInsightReq) (*InsightDetail, error) {
	path := fmt.Sprintf("/%s/api/v1/insight_items/%s", orgID, slug)
	body, err := c.PatchJSON(path, req)
	if err != nil {
		return nil, err
	}

	var detail InsightDetail
	if err := json.Unmarshal(body, &detail); err != nil {
		return nil, err
	}
	return &detail, nil
}

func (c *Client) DeleteInsight(orgID, slug string) error {
	path := fmt.Sprintf("/%s/api/v1/insight_items/%s", orgID, slug)
	_, err := c.Delete(path)
	return err
}
