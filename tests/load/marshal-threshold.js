/**
 * marshal-threshold — L3 k6 load profile (REQ-E8-S01-01)
 *
 * Lab marshal threshold (EdgeRequestRateHigh / HighRequestRate scorecard name):
 *   edge request rate > 100 rps (5m), sustained 2m.
 *
 * This profile targets RATE=150 (above the 100 rps threshold) so a live run can
 * drive the alert. Offline CI validates script shape via `task test:load`
 * (SCORECARD_FIXTURES=1); live cluster smoke is deferred.
 *
 * Usage:
 *   RATE=150 BASE_URL=https://clubhouse.lab.platformrelay.dev k6 run tests/load/marshal-threshold.js
 *   SCORECARD_FIXTURES=1 task test:load   # structural / offline gate
 */

import http from 'k6/http';
import { check, sleep } from 'k6';

// Documented threshold: 100 rps. Default load RATE=150 (above threshold).
const RATE = Number(__ENV.RATE || 150);
const BASE_URL = __ENV.BASE_URL || 'http://127.0.0.1:8080';
const DURATION = __ENV.DURATION || '3m';

export const options = {
  scenarios: {
    marshal_threshold: {
      executor: 'constant-arrival-rate',
      rate: RATE,
      timeUnit: '1s',
      duration: DURATION,
      preAllocatedVUs: Math.min(RATE, 50),
      maxVUs: Math.max(RATE * 2, 100),
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.5'],
  },
  summaryTrendStats: ['avg', 'p(95)', 'p(99)', 'max'],
};

export default function () {
  const res = http.get(`${BASE_URL}/`);
  check(res, {
    'status is 2xx or 3xx': (r) => r.status >= 200 && r.status < 400,
  });
  sleep(0.01);
}
