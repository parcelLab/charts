import parcellab from "@parcellab/danger-plugin";
import { Severity } from "@parcellab/danger-plugin/dist/types";

(async function dangerReport() {
	await parcellab({
		branchSize: {
			maxCommits: 10,
			maxLines: 1000,
			maxFiles: 100,
			severity: Severity.Warn,
		},
		conventional: {
			severity: Severity.Warn,
		},
		jira: {
			severity: Severity.Warn,
		},
		prLint: {
			minBodyLength: 10,
			severity: Severity.Warn,
			scoped: false,
		},
	});
})();
