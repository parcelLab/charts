import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

const charts = process.env.WAF_TEST_CHART
	? [process.env.WAF_TEST_CHART]
	: ["microservice", "monolith"];

function render(chart, routes, enabled = true) {
	const directory = mkdtempSync(join(tmpdir(), "coraza-chart-"));
	const values = join(directory, "values.json");
	writeFileSync(
		values,
		JSON.stringify({
			envoy: { enabled, httpRoutes: routes },
		}),
	);
	try {
		return execFileSync(
			"helm",
			[
				"template",
				"trial",
				`parcellab/${chart}`,
				"--namespace",
				"trial",
				"--values",
				values,
				"--show-only",
				"templates/httproutes.yaml",
			],
			{ encoding: "utf8" },
		)
			.split(/^---\s*$/m)
			.filter((document) =>
				document.includes("kind: EnvoyExtensionPolicy"),
			);
	} finally {
		rmSync(directory, { recursive: true });
	}
}

for (const chart of charts) {
	test(`${chart}: WAF is opt-in and does not change policy-free output`, () => {
		const publicRoute = { name: "public", hosts: ["public.example.com"] };
		const staffRoute = { name: "staff", hosts: ["staff.example.com"] };
		assert.deepEqual(render(chart, [publicRoute, staffRoute]), []);
		assert.deepEqual(
			render(chart, [
				{ ...publicRoute, waf: { enabled: false } },
				staffRoute,
			]),
			[],
		);
	});

	test(`${chart}: each enabled route gets a scoped detection-only policy`, () => {
		const policies = render(chart, [
			{
				name: "PUBLIC_Route",
				hosts: ["public.example.com"],
				waf: { enabled: true },
			},
			{
				name: "api-route",
				hosts: ["api.example.com"],
				waf: { enabled: true, name: "existing-api-waf" },
			},
			{ name: "staff", hosts: ["staff.example.com"] },
		]);
		assert.equal(policies.length, 2);
		assert.match(policies[0], /name: public-route-waf\n/);
		assert.match(policies[0], /kind: HTTPRoute\n\s+name: public-route\n/);
		assert.match(policies[1], /name: existing-api-waf\n/);
		assert.match(policies[1], /kind: HTTPRoute\n\s+name: api-route\n/);
		for (const policy of policies) {
			assert.match(policy, /namespace: trial\n/);
			assert.match(policy, /labels:\n/);
			assert.match(policy, /failOpen: true/);
			assert.match(
				policy,
				/url: ghcr.io\/corazawaf\/coraza-proxy-wasm@sha256:[0-9a-f]{64}/,
			);
			assert.match(policy, /SecRuleEngine DetectionOnly/);
			assert.doesNotMatch(policy, /SecRuleEngine On/);
			assert.match(policy, /SecResponseBodyAccess Off/);
			assert.match(policy, /SecRequestBodyLimit 131072/);
			assert.match(policy, /SecRequestBodyLimitAction ProcessPartial/);
			assert.match(policy, /SecAuditEngine Off/);
			assert.match(policy, /SecDebugLogLevel 0/);
			assert.match(policy, /Include @recommended-conf/);
			assert.match(policy, /Include @crs-setup-conf/);
			assert.match(policy, /Include @owasp_crs\/REQUEST-\*\.conf/);
			assert.doesNotMatch(policy, /kind: Gateway\n/);
		}
	});

	test(`${chart}: disabled Envoy renders no WAF policies`, () => {
		// Render the complete chart: --show-only fails when httproutes renders empty.
		const output = execFileSync(
			"helm",
			[
				"template",
				"trial",
				`parcellab/${chart}`,
				"--set",
				"envoy.enabled=false,envoy.httpRoutes[0].waf.enabled=true",
			],
			{ encoding: "utf8" },
		);
		assert.doesNotMatch(output, /kind: EnvoyExtensionPolicy/);
	});
}
