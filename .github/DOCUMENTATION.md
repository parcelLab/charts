# .github

This is a convention folder used to place specific configurations related to Github.

- `PULL_REQUEST_TEMPLATE/`: [Templates for PR bodies](#pull_request_template)
- `workflows/`: [Github Actions workflows](#workflows)
- `pull_request_template.md`: defines the default PR template to be loaded to the body of every PR that is created in this repo. You can copy it from one of the examples in `PULL_REQUEST_TEMPLATE/`

## `PULL_REQUEST_TEMPLATE`

Stores templates that define how to make a pull request to the project.

You can select the pull request template using the `template` parameter as described
in [Using query parameters to create a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/using-query-parameters-to-create-a-pull-request)

If you want to set up a pull request template by default to all PRs, move a
file from this folder into `.github/workflows` and name it `pull_request_template.md`.

## `workflows`

Contains yaml files for [Github Actions](https://docs.github.com/en/actions)
and its configuration.

You have workflow examples in [workflows/templates](workflows/templates/README.md).
