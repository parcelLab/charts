#!/usr/bin/env bash
# Publish parcelLab Helm charts to ECR as OCI artifacts:
#   oci://<account>.dkr.ecr.<region>.amazonaws.com/charts/<chart>:<version>
#
# Usage:
#   publish-ecr.sh local     package every chart under parcellab/ at its current version
#   publish-ecr.sh backfill  copy every version listed in https://charts.parcellab.dev/index.yaml
#
# Versions already in ECR are skipped (repositories use immutable tags), so both
# modes are safe to re-run. Expects AWS credentials and AWS_REGION in the environment.
set -euo pipefail

MODE="${1:?usage: publish-ecr.sh local|backfill}"
PREFIX="charts"
INDEX_URL="https://charts.parcellab.dev/index.yaml"
: "${AWS_REGION:?AWS_REGION must be set}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

aws ecr get-login-password | helm registry login --username AWS --password-stdin "$REGISTRY"

# Create charts/<name> if missing and cache its existing tags in $WORKDIR/tags-<name>.
prepare_repo() {
  local name="$1" tags="$WORKDIR/tags-$1"
  [[ -f "$tags" ]] && return 0
  if ! aws ecr describe-repositories --repository-names "$PREFIX/$name" >/dev/null 2>&1; then
    echo "Creating ECR repository $PREFIX/$name"
    aws ecr create-repository --repository-name "$PREFIX/$name" \
      --image-tag-mutability IMMUTABLE >/dev/null
  fi
  aws ecr list-images --repository-name "$PREFIX/$name" --filter tagStatus=TAGGED \
    --query 'imageIds[].imageTag' --output text | tr '\t' '\n' >"$tags"
}

# OCI tags can't contain "+", Helm stores SemVer build metadata as "_".
already_published() {
  grep -qxF "${2//+/_}" "$WORKDIR/tags-$1"
}

push() {
  local name="$1" version="$2" tgz="$3"
  helm push "$tgz" "oci://$REGISTRY/$PREFIX"
  echo "${version//+/_}" >>"$WORKDIR/tags-$name"
}

published=0
skipped=0

case "$MODE" in
  local)
    for dir in parcellab/*/; do
      name="$(yq '.name' "$dir/Chart.yaml")"
      version="$(yq '.version' "$dir/Chart.yaml")"
      prepare_repo "$name"
      if already_published "$name" "$version"; then
        skipped=$((skipped + 1))
        continue
      fi
      echo "Publishing $name $version"
      helm dependency update "$dir" >/dev/null
      helm package "$dir" --destination "$WORKDIR" >/dev/null
      push "$name" "$version" "$WORKDIR/$name-$version.tgz"
      published=$((published + 1))
    done
    ;;
  backfill)
    curl -fsSL "$INDEX_URL" -o "$WORKDIR/index.yaml"
    while read -r name version url; do
      prepare_repo "$name"
      if already_published "$name" "$version"; then
        skipped=$((skipped + 1))
        continue
      fi
      echo "Backfilling $name $version"
      curl -fsSL "$url" -o "$WORKDIR/chart.tgz"
      push "$name" "$version" "$WORKDIR/chart.tgz"
      published=$((published + 1))
    done < <(yq '.entries[][] | .name + " " + .version + " " + .urls[0]' "$WORKDIR/index.yaml")
    ;;
  *)
    echo "unknown mode: $MODE" >&2
    exit 1
    ;;
esac

echo "Published $published chart version(s), skipped $skipped already in ECR."
