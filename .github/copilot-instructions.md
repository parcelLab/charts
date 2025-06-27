In this repository we manage our custom charts (cronjob, microservice, monolith and worker-group).
It is structured as follows:

- the folder "common" contains all templates used by the charts
- the folder "cronjob" contains the chart for cronjob
- the folder "microservice" contains the chart for microservice
- the folder "monolith" contains the chart for monolith
- the folder "worker-group" contains the chart for worker-group

This is a public repository, our team uses Jira for tracking items of work you'll find references with the pattern INF-{number} for the ticket in commits and pull request titles.

The charts contain templates for easier setup with ArgoCD and Argo Rollouts as well as for datadog.
