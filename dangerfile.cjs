const parcellab = require("@parcellab/danger-plugin").default;

(async () => {
	await parcellab({
		branchSize: {
			maxCommits: 10,
			maxLines: 1000,
			maxFiles: 100,
			severity: "error",
		},
		conventional: {
			severity: "error",
		},
		jira: {
			severity: "disable",
		},
		prLint: {
			minBodyLength: 10,
			severity: "error",
			scoped: false,
		},
	});
})();
