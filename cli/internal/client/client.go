package client

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

type Client struct {
	URL   string
	Token string
	HTTP  *http.Client
}

func New(serverURL, token string) *Client {
	return &Client{
		URL:   strings.TrimRight(serverURL, "/"),
		Token: token,
		HTTP:  &http.Client{Timeout: 30 * time.Second},
	}
}

func (c *Client) Get(path string) ([]byte, error) {
	return c.do(http.MethodGet, path, nil)
}

func (c *Client) do(method, path string, body io.Reader) ([]byte, error) {
	if c.URL == "" {
		return nil, fmt.Errorf("no hub URL configured; run `ih login`")
	}
	if c.Token == "" {
		return nil, fmt.Errorf("no token configured; run `ih login`")
	}

	if !strings.HasPrefix(path, "/") {
		path = "/" + path
	}
	endpoint := c.URL + path

	req, err := http.NewRequest(method, endpoint, body)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+c.Token)
	req.Header.Set("Accept", "application/json")

	resp, err := c.HTTP.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode >= 400 {
		return nil, unwrapError(resp.StatusCode, data)
	}
	return data, nil
}

type APIError struct {
	Status  int
	Message string
}

func (e *APIError) Error() string {
	if e.Message == "" {
		return fmt.Sprintf("request failed: HTTP %d", e.Status)
	}
	return fmt.Sprintf("HTTP %d: %s", e.Status, e.Message)
}

func unwrapError(status int, body []byte) error {
	var parsed struct {
		Error    string   `json:"error"`
		Messages []string `json:"messages"`
		Errors   []string `json:"errors"`
	}
	if err := json.Unmarshal(body, &parsed); err == nil {
		msg := parsed.Error
		if len(parsed.Messages) > 0 {
			msg = strings.Join(parsed.Messages, "; ")
		} else if len(parsed.Errors) > 0 {
			msg = strings.Join(parsed.Errors, "; ")
		}
		if msg != "" {
			return &APIError{Status: status, Message: msg}
		}
	}
	return &APIError{Status: status, Message: strings.TrimSpace(string(body))}
}
