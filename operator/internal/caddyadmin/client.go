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
// replaced in place via PUT /id/<id>; only a route that does not exist
// yet is appended via POST to the server's routes path.
package caddyadmin

import (
	"context"
	"errors"
)

// ErrUnavailable marks transient admin API failures (connection refused,
// timeouts, 5xx). Callers should requeue with backoff and surface
// reason AdminAPIUnavailable in status.
var ErrUnavailable = errors.New("caddy admin API unavailable")

// ErrNotImplemented is the TDD stub error; it disappears with the implementation.
var ErrNotImplemented = errors.New("caddyadmin: not implemented")

// Route is a Caddy HTTP route addressed by its `@id` tag.
// Body is the full route object; the client injects the `@id`.
type Route struct {
	// ID is the stable `@id` under which the route is upserted.
	ID string
	// Body is the route object (match/handle) without the `@id` key.
	Body map[string]any
}

// Client drives one Caddy admin API endpoint.
type Client struct {
	base string
}

// New returns a client for the admin API at base, e.g. "http://10.0.0.1:2019".
func New(base string) *Client {
	return &Client{base: base}
}

// Ping verifies the admin API is reachable (GET /config/).
func (c *Client) Ping(ctx context.Context) error {
	return ErrNotImplemented
}

// UpsertRoute idempotently installs the route: PUT /id/<id> when the id
// already exists, otherwise a single POST to routesPath (e.g.
// "/config/apps/http/servers/srv0/routes").
func (c *Client) UpsertRoute(ctx context.Context, routesPath string, route Route) error {
	return ErrNotImplemented
}

// DeleteRoute removes the route with the given id; an unknown id is a no-op.
func (c *Client) DeleteRoute(ctx context.Context, id string) error {
	return ErrNotImplemented
}
