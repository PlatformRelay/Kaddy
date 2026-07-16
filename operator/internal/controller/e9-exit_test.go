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

// REQ-E9-EXIT: operator envtest package is wired into the root task matrix
// (task test / task test:operator). This smoke keeps the Verify path live.

import "testing"

func TestE9Exit_ControllerPackageLoads(t *testing.T) {
	c := startPlainEnv(t)
	if c == nil {
		t.Fatal("envtest client must be non-nil")
	}
}
