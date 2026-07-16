/*
Copyright 2026.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// Package caddyadmin is the port to the Caddy admin API
// (https://caddyserver.com/docs/api). Routes are addressed by their
// `@id` tag so that reconciliation is idempotent: an existing route is
// strictly replaced in place via PATCH /id/<id> (PUT would *insert* a
// duplicate — Caddy semantics); only a route that does not exist yet is
// appended via POST to the server's routes path.
package caddyadmin

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"maps"
	"net/http"
	"strings"
	"time"
)

// ErrUnavailable marks transient admin API failures (connection refused,
// timeouts, 5xx). Callers should requeue with backoff and surface
// reason AdminAPIUnavailable in status.
var ErrUnavailable = errors.New("caddy admin API unavailable")

// defaultTimeout bounds every admin API call even when the caller's
// context carries no deadline.
const defaultTimeout = 10 * time.Second

// Route is a Caddy HTTP route addressed by its `@id` tag.
// Body is the route object (match/handle); the client injects the `@id`.
type Route struct {
	// ID is the stable `@id` under which the route is upserted.
	ID string
	// Body is the route object (match/handle) without the `@id` key.
	Body map[string]any
}

// Client drives one Caddy admin API endpoint.
type Client struct {
	base string
	http *http.Client
}

// New returns a client for the admin API at base, e.g. "http://10.0.0.1:2019".
func New(base string) *Client {
	return &Client{
		base: strings.TrimRight(base, "/"),
		http: &http.Client{Timeout: defaultTimeout},
	}
}

// Ping verifies the admin API is reachable (GET /config/).
func (c *Client) Ping(ctx context.Context) error {
	status, err := c.do(ctx, http.MethodGet, "/config/", nil)
	if err != nil {
		return fmt.Errorf("ping admin API: %w", err)
	}
	if status != http.StatusOK {
		return fmt.Errorf("ping admin API: unexpected status %d", status)
	}
	return nil
}

// UpsertRoute idempotently installs the route. Caddy admin API verb
// semantics: POST appends to arrays and PUT *inserts* — both would pile up
// duplicate routes — while PATCH strictly replaces an existing value. So:
// PATCH /id/<id> replaces in place; only on 404 (unknown id) is the route
// created exactly once via POST to routesPath (e.g.
// "/config/apps/http/servers/srv0/routes").
func (c *Client) UpsertRoute(ctx context.Context, routesPath string, route Route) error {
	if route.ID == "" {
		return errors.New("upsert route: empty @id")
	}

	body := make(map[string]any, len(route.Body)+1)
	maps.Copy(body, route.Body)
	body["@id"] = route.ID

	payload, err := json.Marshal(body)
	if err != nil {
		return fmt.Errorf("upsert route %q: encode: %w", route.ID, err)
	}

	status, err := c.do(ctx, http.MethodPatch, "/id/"+route.ID, payload)
	if err != nil {
		return fmt.Errorf("upsert route %q: %w", route.ID, err)
	}
	switch {
	case status >= 200 && status < 300:
		return nil // replaced in place
	case status == http.StatusNotFound:
		// Route does not exist yet — create it exactly once.
	default:
		return fmt.Errorf("upsert route %q: PATCH /id/%s: unexpected status %d", route.ID, route.ID, status)
	}

	status, err = c.do(ctx, http.MethodPost, routesPath, payload)
	if err != nil {
		return fmt.Errorf("create route %q: %w", route.ID, err)
	}
	if status < 200 || status >= 300 {
		return fmt.Errorf("create route %q: POST %s: unexpected status %d", route.ID, routesPath, status)
	}
	return nil
}

// DeleteRoute removes the route with the given id; an unknown id is a no-op.
func (c *Client) DeleteRoute(ctx context.Context, id string) error {
	if id == "" {
		return errors.New("delete route: empty @id")
	}
	status, err := c.do(ctx, http.MethodDelete, "/id/"+id, nil)
	if err != nil {
		return fmt.Errorf("delete route %q: %w", id, err)
	}
	if status == http.StatusNotFound || (status >= 200 && status < 300) {
		return nil // already gone counts as deleted
	}
	return fmt.Errorf("delete route %q: unexpected status %d", id, status)
}

// do performs one admin API call and returns the HTTP status. Transport
// errors and 5xx answers are reported as ErrUnavailable (transient).
func (c *Client) do(ctx context.Context, method, path string, payload []byte) (int, error) {
	ctx, cancel := context.WithTimeout(ctx, defaultTimeout)
	defer cancel()

	var body io.Reader
	if payload != nil {
		body = bytes.NewReader(payload)
	}
	req, err := http.NewRequestWithContext(ctx, method, c.base+path, body)
	if err != nil {
		return 0, fmt.Errorf("build %s %s: %w", method, path, err)
	}
	if payload != nil {
		req.Header.Set("Content-Type", "application/json")
	}

	resp, err := c.http.Do(req)
	if err != nil {
		return 0, fmt.Errorf("%s %s: %w: %w", method, path, ErrUnavailable, err)
	}
	defer func() { _ = resp.Body.Close() }()
	// Drain so the connection can be reused; the admin API bodies are tiny.
	_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 64<<10))

	if resp.StatusCode >= 500 {
		return resp.StatusCode, fmt.Errorf("%s %s: status %d: %w", method, path, resp.StatusCode, ErrUnavailable)
	}
	return resp.StatusCode, nil
}
