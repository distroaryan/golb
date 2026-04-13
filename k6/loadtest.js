import http from "k6/http";
import { sleep, check } from "k6";

// Run with: k6 run benchmark.js
// For JSON output: k6 run --out json=results.json benchmark.js

export const options = {
  scenarios: {
    low_concurrency: {
      executor: "constant-vus",
      vus: 100,
      duration: "30s",
      startTime: "0s",
      tags: { scenario: "100vus" },
      gracefulStop: "5s",
    },
    mid_concurrency: {
      executor: "constant-vus",
      vus: 500,
      duration: "30s",
      startTime: "45s",       // starts after low finishes + buffer
      tags: { scenario: "500vus" },
      gracefulStop: "5s",
    },
    high_concurrency: {
      executor: "constant-vus",
      vus: 1000,
      duration: "30s",
      startTime: "90s",       // starts after mid finishes + buffer
      tags: { scenario: "1000vus" },
      gracefulStop: "5s",
    },
  },

  thresholds: {
    // Overall thresholds across all scenarios
    http_req_duration: ["p(95)<500", "p(99)<1000"],
    http_req_failed: ["rate<0.05"],

    // Per-scenario thresholds — useful for spotting which stage breaks
    "http_req_duration{scenario:100vus}":  ["p(95)<200"],
    "http_req_duration{scenario:500vus}":  ["p(95)<300"],
    "http_req_duration{scenario:1000vus}": ["p(95)<500"],
  },
};

const BASE_URL = "http://localhost:8080";

export default function () {
  const res = http.get(BASE_URL);

  check(res, {
    "status 200":             (r) => r.status === 200,
    "response time < 500ms":  (r) => r.timings.duration < 500,
  });

  // No sleep — we want max throughput numbers for the benchmark table.
  // Add sleep(0.1) here if you want more realistic user-think-time results.
}

export function handleSummary(data) {
  const scenarios = ["100vus", "500vus", "1000vus"];

  let output = "\n========================================\n";
  output +=    "        LOADEX BENCHMARK SUMMARY\n";
  output +=    "========================================\n\n";

  for (const tag of scenarios) {
    const dur  = data.metrics["http_req_duration"];
    const reqs = data.metrics["http_reqs"];
    const fail = data.metrics["http_req_failed"];

    // k6 doesn't split summary metrics by tag natively in handleSummary,
    // so we print the global summary clearly labeled per block.
    // For per-scenario numbers, check the stdout table printed by k6 above this.
    output += `--- Scenario: ${tag} ---\n`;
    output += `  P50:        ${dur?.values?.["p(50)"]?.toFixed(2) ?? "N/A"} ms\n`;
    output += `  P95:        ${dur?.values?.["p(95)"]?.toFixed(2) ?? "N/A"} ms\n`;
    output += `  P99:        ${dur?.values?.["p(99)"]?.toFixed(2) ?? "N/A"} ms\n`;
    output += `  Total RPS:  ${reqs?.values?.rate?.toFixed(0) ?? "N/A"} req/s\n`;
    output += `  Error Rate: ${((fail?.values?.rate ?? 0) * 100).toFixed(2)}%\n\n`;
  }

  output += "========================================\n";
  output += "Tip: for per-scenario P50/P95/P99, run each\n";
  output += "scenario separately with --tag scenario=Xvus\n";
  output += "========================================\n";

  return {
    stdout: output,
  };
}