/**
 * Moodiki — k6 Load Test
 *
 * Đo P95 latency của các Supabase REST API endpoint chính
 * với 100 virtual users đồng thời.
 *
 * Cách chạy:
 *   k6 run \
 *     -e SUPABASE_URL=https://xxx.supabase.co \
 *     -e SUPABASE_ANON_KEY=your_anon_key \
 *     load_test/k6_load_test.js
 *
 * Xem kết quả chi tiết (JSON):
 *   k6 run ... --out json=load_test/results.json load_test/k6_load_test.js
 */

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Trend, Rate, Counter } from 'k6/metrics';

// ─── Custom metrics ────────────────────────────────────────────────────────────
const newsFeedLatency     = new Trend('news_feed_p95',     true);
const meditationLatency   = new Trend('meditation_p95',    true);
const moodHistoryLatency  = new Trend('mood_history_p95',  true);
const errorRate           = new Rate('error_rate');
const totalRequests       = new Counter('total_requests');

// ─── Test config ───────────────────────────────────────────────────────────────
export const options = {
  scenarios: {
    // Ramp up → 100 CCU → ramp down
    load_test: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 50  },  // warm-up
        { duration: '60s', target: 100 },  // peak load
        { duration: '30s', target: 0   },  // cool-down
      ],
    },
  },

  thresholds: {
    // Ngưỡng pass/fail — điều chỉnh theo mục tiêu của bạn
    http_req_duration: ['p(95)<300'],   // P95 toàn bộ < 300ms
    news_feed_p95:    ['p(95)<350'],
    meditation_p95:   ['p(95)<250'],
    error_rate:       ['rate<0.01'],    // Tỉ lệ lỗi < 1%
  },
};

// ─── Helpers ───────────────────────────────────────────────────────────────────
const BASE_URL  = __ENV.SUPABASE_URL   || 'https://YOUR_PROJECT.supabase.co';
const ANON_KEY  = __ENV.SUPABASE_ANON_KEY || 'YOUR_ANON_KEY';

// Một test user JWT để test các endpoint cần auth.
// Tạo bằng: supabase.auth.signInWithPassword(...) và copy access_token
// Hoặc dùng service role key nếu chỉ test performance, không test RLS.
const USER_JWT   = __ENV.USER_JWT   || '';
const USER_ID    = __ENV.USER_ID    || '';      // UUID của test user

function headers(withAuth = false) {
  const h = {
    'apikey':       ANON_KEY,
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };
  if (withAuth && USER_JWT) {
    h['Authorization'] = `Bearer ${USER_JWT}`;
  } else {
    h['Authorization'] = `Bearer ${ANON_KEY}`;
  }
  return h;
}

function rest(table, params = '') {
  return `${BASE_URL}/rest/v1/${table}${params ? '?' + params : ''}`;
}

// ─── Main VU scenario ──────────────────────────────────────────────────────────
export default function () {

  // 1. News feed (public)
  group('GET /posts (news feed)', () => {
    const res = http.get(
      rest('posts', 'order=created_at.desc&limit=20'),
      { headers: headers() },
    );
    newsFeedLatency.add(res.timings.duration);
    totalRequests.add(1);
    const ok = check(res, {
      'posts: status 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  });

  sleep(0.3);

  // 2. Meditation list (public)
  group('GET /meditations', () => {
    const res = http.get(
      rest('meditations', 'order=created_at.desc&limit=20'),
      { headers: headers() },
    );
    meditationLatency.add(res.timings.duration);
    totalRequests.add(1);
    const ok = check(res, {
      'meditations: status 200': (r) => r.status === 200,
    });
    errorRate.add(!ok);
  });

  // 3. Mood history (requires auth)
  if (USER_ID && USER_JWT) {
    sleep(0.3);

    group('GET /mood_entries (user history)', () => {
      const res = http.get(
        rest('mood_entries', `user_id=eq.${USER_ID}&order=created_at.desc&limit=30`),
        { headers: headers(true) },
      );
      moodHistoryLatency.add(res.timings.duration);
      totalRequests.add(1);
      const ok = check(res, {
        'mood_entries: status 200': (r) => r.status === 200,
      });
      errorRate.add(!ok);
    });
  }

  sleep(0.5);
}

// ─── Summary report ────────────────────────────────────────────────────────────
export function handleSummary(data) {
  const p95 = (metricName) => {
    const m = data.metrics[metricName];
    return m ? Math.round(m.values['p(95)']) + 'ms' : 'N/A';
  };

  const totalReqs  = data.metrics['total_requests']?.values?.count ?? 0;
  const errRate    = ((data.metrics['error_rate']?.values?.rate ?? 0) * 100).toFixed(2);
  const p95All     = p95('http_req_duration');
  const rps        = data.metrics['http_reqs']?.values?.rate?.toFixed(1) ?? 'N/A';

  const report = `
╔══════════════════════════════════════════════════════════╗
║              MOODIKI — Load Test Report                  ║
╠══════════════════════════════════════════════════════════╣
║  Tổng requests  : ${String(totalReqs).padEnd(36)}║
║  Throughput     : ${String(rps + ' req/s').padEnd(36)}║
║  Error rate     : ${String(errRate + '%').padEnd(36)}║
╠══════════════════════════════════════════════════════════╣
║  P95 LATENCY BY ENDPOINT                                 ║
║  ─────────────────────────────────────────────────────  ║
║  Toàn bộ        : ${String(p95All).padEnd(36)}║
║  News feed      : ${String(p95('news_feed_p95')).padEnd(36)}║
║  Meditations    : ${String(p95('meditation_p95')).padEnd(36)}║
║  Mood history   : ${String(p95('mood_history_p95')).padEnd(36)}║
╚══════════════════════════════════════════════════════════╝
`;

  console.log(report);

  return {
    'load_test/summary.txt': report,
    stdout: report,
  };
}
