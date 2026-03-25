import http from "k6/http";
import { sleep, check } from "k6";

export const options = {
  stages: [
    { duration: "30s", target: 20 },  // ramp up to 20 users
    { duration: "1m",  target: 50 },  // sustain 50 users — peak load
    { duration: "30s", target: 20 },  // ramp down
    { duration: "20s", target: 0  },  // cool down
  ],
  thresholds: {
    http_req_duration: ["p(95)<500", "p(99)<1000"],
    http_req_failed:   ["rate<0.01"],
  },
};

const BASE_URL = "http://localhost:8080";

export default function () {
  const res = http.get(BASE_URL);

  check(res, {
    "status 200": (r) => r.status === 200,
    "response time < 500ms": (r) => r.timings.duration < 500,
  });

  sleep(Math.random() * 0.5); // small random delay between requests
}
