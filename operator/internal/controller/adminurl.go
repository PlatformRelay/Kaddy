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

package controller

import (
	"fmt"
	"strconv"
	"strings"

	gatewayv1alpha1 "github.com/PlatformRelay/Kaddy/operator/api/v1alpha1"
)

// defaultAdminPort matches the CRD default admin.listen ":2019".
const defaultAdminPort = 2019

// DefaultAdminURL resolves the in-cluster admin API base URL for a Caddy
// dataplane: http://<name>-admin.<namespace>.svc:<port>, with the port
// taken from spec.admin.listen.
func DefaultAdminURL(caddy *gatewayv1alpha1.Caddy) string {
	port := defaultAdminPort
	if listen := caddy.Spec.Admin.Listen; listen != "" {
		if idx := strings.LastIndex(listen, ":"); idx >= 0 {
			if p, err := strconv.Atoi(listen[idx+1:]); err == nil && p > 0 && p <= 65535 {
				port = p
			}
		}
	}
	return fmt.Sprintf("http://%s-admin.%s.svc:%d", caddy.Name, caddy.Namespace, port)
}
